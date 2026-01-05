import 'package:flutter/material.dart';
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
  final List<String> sugars=['0','1', '2', '3', '4','5','6','7'];
    String _curentSuger='0';
  int _currentStrength=100;
  File? _imageFile;
  String? _photoUrl;
  bool _isBuying = false;
  @override
void dispose() {
  _nameController.dispose();
  _descriptionController.dispose();
  super.dispose();
}
  bool _isInit = false;

  @override
  Widget build(BuildContext context) {
   final user = Provider.of<UserModel>(context);
    return StreamBuilder<UserData>(
      stream: DatabaseService(uid:user.uid).userdatas,
      builder: (context, asyncSnapshot) {
        if(!asyncSnapshot.hasData){
          return Center(child: Loading(),);
        }
        UserData userData= asyncSnapshot.data!;
           if (!_isInit) {
          _nameController.text = userData.name ?? '';
          _curentSuger = userData.sugar ?? '0';
          _currentStrength = userData.strenght ?? 100;
          _photoUrl = userData.photoUrl;
          _descriptionController.text = userData.description ?? '';
          _isBuying = userData.isBuying ?? false;
          _isInit = true;
        }
        return Column(
          children: [
              Text('UPDATE YOUR BREW SETTINGS ',style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),),
              SizedBox(height: 16),
              // Profile picture
              GestureDetector(
                onTap: () async {
                  final picker = ImagePicker();
                  final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 75);
                  if (picked == null) return;
                  final file = File(picked.path);
                  setState(() {
                    _imageFile = file;
                  });
                  // upload
                  final url = await DatabaseService(uid: user.uid).uploadProfileImage(file);
                  if (!mounted) return;
                  if (url != null) {
                    setState(() {
                      _photoUrl = url;
                    });
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Profile image uploaded')));
                  }
                },
                child: CircleAvatar(
                  radius: 40,
                  backgroundColor: Colors.grey[200],
                  backgroundImage: _imageFile != null ? FileImage(_imageFile!) : (_photoUrl != null ? NetworkImage(_photoUrl!) as ImageProvider : null),
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
                  await DatabaseService(uid: user.uid).updateProfileFields(isBuying: val);
                },
              ),
              DropdownButtonFormField(
                initialValue: _curentSuger,
                
                items: sugars.map((sugar){
                return DropdownMenuItem<String>(
                  value: sugar,
                  child: Text('$sugar  sugars'));
              }).toList(), onChanged: (value){
                setState(() {
                  _curentSuger =value!;
                });
              }),
              SizedBox(height: 20,),
        
              
        
              Slider(
                value: _currentStrength.toDouble(),
                activeColor: Colors.brown[_currentStrength],
                inactiveColor: Colors.brown[_currentStrength],
                min: 100,
                max: 900,
                divisions: 8,
                label: _currentStrength.round().toString(),
                onChanged: (value) {
                  setState(() {
                    _currentStrength = value.round();
                  });
                },
              ),
        
             ElevatedButton(onPressed: (){
              // Save all fields
              DatabaseService(uid: user.uid).updatingUserData(
                _nameController.text,
                _curentSuger,
                _currentStrength,
              );
              DatabaseService(uid: user.uid).updateProfileFields(
                description: _descriptionController.text,
                isBuying: _isBuying,
                photoUrl: _photoUrl,
              );
              Navigator.pop(context);
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

