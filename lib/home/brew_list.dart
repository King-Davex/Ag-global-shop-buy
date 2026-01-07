import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_coffee_app/model/brew_model.dart';
import 'package:flutter_coffee_app/services/database.dart';
import 'package:flutter_coffee_app/model/user_model.dart';
import 'package:flutter_coffee_app/screen/loading.dart';
import 'package:provider/provider.dart';
class BrewList extends StatefulWidget {
  const BrewList({super.key});

  @override
  State<BrewList> createState() => _BrewListState();
}

class _BrewListState extends State<BrewList> {
  final ImagePicker _picker = ImagePicker();
  bool _uploading = false;
  int _bytesTransferred = 0;
  int _totalBytes = 0;
  @override
  Widget build(BuildContext context) {
    final brew = Provider.of<List<Brew>>(context);
    final user = Provider.of<UserModel?>(context);

    // If there's no authenticated user, show a simple message
    if (user == null) {
      return Center(child: Text('Please sign in'));
    }

    return Column(
      children: [
        // Real-time user profile container
        StreamBuilder<UserData>(
          stream: DatabaseService(uid: user.uid).userdatas,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Container(height: 150, margin: EdgeInsets.all(12), child: Center(child: Loading()));
            }
            if (snapshot.hasError) {
              return Container(
                height: 150,
                margin: EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.brown.shade200, borderRadius: BorderRadius.circular(12)),
                child: Center(child: Text('Error loading profile', style: TextStyle(color: Colors.black54))),
              );
            }
            final userData = snapshot.data;
            if (userData == null) {
              // Empty state: show a compact avatar + text without card decoration
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
                child: Row(
                  children: [
                    CircleAvatar(radius: 30, backgroundColor: Colors.brown[400], child: Icon(Icons.person, color: Colors.white)),
                    SizedBox(width: 12),
                    Text('No profile yet', style: TextStyle(color: Colors.black87)),
                  ],
                ),
              );
            }

            // Build the profile container with real-time data
            final photo = userData.photoUrl;
            // Append a timestamp to the displayed URL to bust the client cache so
            // updated images appear immediately after upload. Use '&' if the URL
            // already contains query parameters (common for Firebase download URLs).
            final displayPhoto = (photo != null && photo.isNotEmpty)
                ? (photo.contains('?') ? '$photo&ts=${DateTime.now().millisecondsSinceEpoch}' : '$photo?ts=${DateTime.now().millisecondsSinceEpoch}')
                : null;
            final desc = userData.description ?? '';
            final name = userData.name ?? ''; 

            // Simple, transparent profile row: show avatar and text without a card background
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 12.0),
              child: Row(
                children: [
                  // Avatar (tap to change picture)
                  GestureDetector(
                    onTap: () async {
                      // pick image and upload
                      final pick = await _picker.pickImage(source: ImageSource.gallery, maxWidth: 1200, imageQuality: 85);
                      if (pick == null) return;
                      final file = File(pick.path);
                      setState(() {
                        _uploading = true;
                        _bytesTransferred = 0;
                        _totalBytes = 0;
                      });
                      try {
                        await DatabaseService(uid: user.uid).uploadProfileImage(file, onProgress: (bytes, total) {
                          setState(() {
                            _bytesTransferred = bytes;
                            _totalBytes = total;
                          });
                        }, maxRetries: 3);
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Upload failed: $e')));
                      } finally {
                        setState(() {
                          _uploading = false;
                        });
                      }
                    },
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        photo != null && photo.isNotEmpty
                            ? CircleAvatar(radius: 36, backgroundImage: NetworkImage(displayPhoto!))
                            : CircleAvatar(radius: 36, backgroundColor: Colors.brown[400], child: Icon(Icons.person, color: Colors.white)),
                        if (_uploading)
                          Container(
                            width: 72,
                            height: 72,
                            decoration: BoxDecoration(color: Colors.black45, shape: BoxShape.circle),
                            child: Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: _totalBytes > 0
                                  ? CircularProgressIndicator(value: _bytesTransferred / _totalBytes, color: Colors.white)
                                  : CircularProgressIndicator(color: Colors.white),
                            ),
                          ),
                      ],
                    ),
                  ),
                  SizedBox(width: 12),
                  // Texts with a light, semi-transparent container for readability
                  Expanded(
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.75),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(name, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
                          SizedBox(height: 6),
                          Text(
                            desc.isNotEmpty ? desc : 'No description',
                            style: TextStyle(color: Colors.black54),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),

        // Remaining list of brews (other users/items)
        // Filter out the current user from the list
        Builder(
          builder: (context) {
            // Filter out current user's brew from the list
            final otherBrews = brew.where((b) => b.uid != null && b.uid != user.uid).toList();
            
            if (otherBrews.isEmpty) {
              return Padding(
                padding: const EdgeInsets.all(16.0),
                child: Center(
                  child: Text(
                    'No other users found',
                    style: TextStyle(color: Colors.black54, fontSize: 16),
                  ),
                ),
              );
            }
            
            return Expanded(
              child: ListView.builder(
                itemCount: otherBrews.length,
                itemBuilder: (context, index) {
                  final item = otherBrews[index];
                  final strength = item.strenght ?? 400;
                  final name = item.name ?? 'Unknown User';
                  final description = item.description ?? '';
                  
                  return Container(
                    height: 110,
                    margin: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: Colors.brown.shade200,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 4,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Row(
                          children: [
                            // Avatar — ensure the circle shows the image when present
                            item.photoUrl != null && (item.photoUrl ?? '').isNotEmpty
                                ? CircleAvatar(radius: 30, backgroundImage: NetworkImage(item.photoUrl!))
                                : CircleAvatar(radius: 30, backgroundColor: Colors.brown[strength], child: Icon(Icons.person, color: Colors.white)),
                            SizedBox(width: 12),
                            // Display name and description
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    name,
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    description.isNotEmpty ? description : 'No description',
                                    style: TextStyle(
                                      color: Colors.black54,
                                      fontSize: 14,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            );
          },
        ),
      ],
    );
  }
}