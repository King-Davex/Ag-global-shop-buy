import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_coffee_app/model/user_model.dart';
import 'package:flutter_coffee_app/screen/loading.dart';
import 'package:flutter_coffee_app/services/database.dart';
import 'package:flutter_coffee_app/utils/custom_text_field.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:provider/provider.dart';

class SettingsForm extends StatefulWidget {
  const SettingsForm({super.key});

  @override
  State<SettingsForm> createState() => _SettingsFormState();
}

class _SettingsFormState extends State<SettingsForm> {
  
  final  TextEditingController _nameController =TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  File? _imageFile;
  String? _photoUrl;
  bool _isBuying = false;
  // Guard to prevent multiple concurrent image picker calls
  bool _isPickingImage = false;

  // Upload UI state
  bool _isUploading = false;
  double _uploadProgress = 0.0;
  String? _lastUploadError;
  @override
void dispose() {
  _nameController.dispose();
  _descriptionController.dispose();
  super.dispose();
}

  // Shows a modal dialog that reflects the current upload state (progress/failure)
  void _showUploadDialog() {
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: Text(_lastUploadError == null ? 'Uploading image' : 'Upload failed'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  LinearProgressIndicator(value: _isUploading ? _uploadProgress.clamp(0.0, 1.0) : null),
                  SizedBox(height: 12),
                  Text(_isUploading ? '${(_uploadProgress * 100).toStringAsFixed(0)}%' : (_lastUploadError ?? '')),
                ],
              ),
              actions: [
                if (!_isUploading && _lastUploadError != null)
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      // Retry the upload if the image file is still set
                      if (_imageFile != null) {
                        final user = Provider.of<UserModel>(context, listen: false);
                        _startUpload(_imageFile!, user.uid);
                      }
                    },
                    child: Text('Retry'),
                  ),
                if (!_isUploading)
                  TextButton(onPressed: () => Navigator.of(context).pop(), child: Text('Close')),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _startUpload(File file, String uid) async {
    setState(() {
      _isUploading = true;
      _uploadProgress = 0.0;
      _lastUploadError = null;
    });

    // Open the progress dialog
    _showUploadDialog();

    try {
      final url = await DatabaseService(uid: uid).uploadProfileImage(
        file,
        onProgress: (bytesTransferred, totalBytes) {
          if (totalBytes > 0 && mounted) setState(() => _uploadProgress = bytesTransferred / totalBytes);
        },
        maxRetries: 3,
      );

      if (url != null && mounted) {
        setState(() {
          _photoUrl = url;
          // Clear the local file since the uploaded image is now the source of truth
          _imageFile = null;
        });
        // Note: uploadProfileImage already saves the URL to Firestore, so no need to write it again.
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Profile image uploaded')));
      }
    } on PlatformException catch (e) {
      print('Upload failed: code=${e.code}, message=${e.message}');
      if (mounted) setState(() => _lastUploadError = e.message ?? 'Upload failed');
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Image upload failed: ${e.message}')));
    } catch (e) {
      print('Unexpected upload error: $e');
      if (mounted) setState(() => _lastUploadError = e.toString());
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Image upload failed')));
    } finally {
      if (mounted) setState(() => _isUploading = false);
      // Close the dialog if it's still open
      try {
        Navigator.of(context, rootNavigator: true).pop();
      } catch (_) {}
    }
  }

  bool _isInit = false;
  // Debug mode: when true, disables Firestore writes. Set false to persist updates to Firestore.
  bool _debugMode = false;

  @override
  Widget build(BuildContext context) {
    // Debug print to observe build frequency
    // Remove or set `_debugMode = false` when finished debugging
    print('SettingsForm build - mounted=${mounted}');
   final user = Provider.of<UserModel>(context);
    return StreamBuilder<UserData>(
      stream: DatabaseService(uid:user.uid).userdatas,
      builder: (context, asyncSnapshot) {
        print('SettingsForm StreamBuilder rebuild: hasData=${asyncSnapshot.hasData}');
        if(!asyncSnapshot.hasData){
          return Center(child: Loading(),);
        }
        UserData userData= asyncSnapshot.data!;
           if (!_isInit) {
          _nameController.text = userData.name ?? '';
          _descriptionController.text = userData.description ?? '';
          _isBuying = userData.isBuying ?? false;
          _isInit = true;
        }
        // Keep the photo URL in sync with Firestore unless the user has a local picked image.
        if (_imageFile == null) {
          _photoUrl = userData.photoUrl;
        }
        // Compute display URL directly from Firestore snapshot (userData) so updates from other clients
        // appear immediately. If a local image file is selected, prefer it while uploading.
        final _displayPhotoLocal = (_imageFile != null)
            ? null
            : (userData.photoUrl != null && userData.photoUrl!.isNotEmpty
                ? (userData.photoUrl!.contains('?') ? '${userData.photoUrl!}&ts=${DateTime.now().millisecondsSinceEpoch}' : '${userData.photoUrl!}?ts=${DateTime.now().millisecondsSinceEpoch}')
                : null);

        // Debug log to help diagnose why an updated image might not appear
        print('SettingsForm snapshot: userPhotoUrl=${userData.photoUrl}, displayPhoto=$_displayPhotoLocal, hasLocalImage=${_imageFile != null}');

        return Column(
          children: [
              Text('UPDATE YOUR BREW SETTINGS ',style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),),
              SizedBox(height: 16),
              // Profile picture
              GestureDetector(
                onTap: () async {
                  if (_isPickingImage) return; // already picking
                  _isPickingImage = true;
                  try {
                    final picker = ImagePicker();
                    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 75);
                    if (picked == null) return;
                    final file = File(picked.path);
                    if (!mounted) return;
                    setState(() { _imageFile = file; });
                    // upload (skip actual Firestore/Storage writes when debugging)
                    if (!_debugMode) {
                      // start upload with UI feedback and retry logic
                      _startUpload(file, user.uid);
                    } else {
                      // simulate a short delay as if uploading
                      await Future.delayed(Duration(milliseconds: 200));
                      if (!mounted) return;
                      setState(() { _photoUrl = null; });
                      print('Debug: skipped upload (debugMode=true)');
                    }
                  } on PlatformException catch (e) {
                    // Handle common permission and picker errors with clearer guidance
                    final code = (e.code ?? '').toLowerCase();
                    final msg = code.contains('permission') || code.contains('denied')
                        ? 'Permission denied. Please enable gallery access in system settings.'
                        : (e.message ?? 'Image picker error');
                    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
                  } catch (e) {
                    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Unexpected error picking image')));
                  } finally {
                    _isPickingImage = false;
                  }
                },
                child: CircleAvatar(
                  radius: 40,
                  backgroundColor: Colors.grey[200],
                  backgroundImage: _imageFile != null
                      ? FileImage(_imageFile!)
                      : (_displayPhotoLocal != null ? NetworkImage(_displayPhotoLocal) as ImageProvider : null),
                  child: (_imageFile == null && _photoUrl == null) ? Icon(Icons.person, size: 40, color: Colors.grey[700]) : null,
                ),
              ),
              SizedBox(height: 12),
              CustomTextField(hintText: 'Enter your name', controller: _nameController),
               SizedBox(height: 20,),
              // Description field
              TextField(
                controller: _descriptionController,
                maxLines: null,
                minLines: 3,
                decoration: InputDecoration(
                  labelText: 'Description',
                  hintText: 'Describe what you want to buy',
                  border: OutlineInputBorder(),
                ),
                onChanged: (val) {
                  // local update only; will save on Update
                },
              ),
              SizedBox(height: 12),
              // Buying toggle
              SwitchListTile(
                title: Text(_isBuying ? 'Buying' : 'Not Buying'),
                value: _isBuying,
                onChanged: (val) async {
                  setState(() => _isBuying = val);
                  if (!_debugMode) await DatabaseService(uid: user.uid).updateProfileFields(isBuying: val);
                  else print('Debug: skipped updateProfileFields(isBuying:$val)');
                },
              ),
              SizedBox(height: 16),
              // (Dropdown and Slider removed per request)

             ElevatedButton(onPressed: () async {
              // Save all fields
              if (!_debugMode) {
                // Preserve existing strength value from userData
                await DatabaseService(uid: user.uid).updatingUserData(
                  _nameController.text,
                  userData.strenght ?? 400,
                );
                await DatabaseService(uid: user.uid).updateProfileFields(
                  description: _descriptionController.text,
                  isBuying: _isBuying,
                  photoUrl: _photoUrl,
                );
                // Notify user on successful save and close sheet
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Profile updated')));
                  Navigator.pop(context);
                }
              } else {
                print('Debug: skipped saving updates (debugMode=true)');
              }
             },
             style: ElevatedButton.styleFrom(
              backgroundColor: Colors.pink,
              foregroundColor: Colors.white,
             ),
              child: Text('Update'))
          ],
        );
      }
    );
  }
}

