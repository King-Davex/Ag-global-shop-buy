import 'package:flutter/material.dart';
import 'package:flutter_coffee_app/model/user_model.dart';
import 'package:flutter_coffee_app/screen/loading.dart';
import 'package:flutter_coffee_app/services/database.dart';
import 'package:flutter_coffee_app/utils/custom_text_field.dart';
import 'package:provider/provider.dart';

class SettingsForm extends StatefulWidget {
  const SettingsForm({super.key});

  @override
  State<SettingsForm> createState() => _SettingsFormState();
}

class _SettingsFormState extends State<SettingsForm> {
  
 final  TextEditingController _nameController =TextEditingController();
  final List<String> sugars=['0','1', '2', '3', '4','5','6','7'];
    String _curentSuger='0';
  int _currentStrength=100;
  @override
void dispose() {
  _nameController.dispose();
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
        _isInit = true;
      }
        return Column(
          children: [
            Text('UPDATE YOUR BREW SETTINGS ',style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),),
            SizedBox(height: 20,),
            CustomTextField(hintText: 'Enter your name', controller: _nameController),
             SizedBox(height: 20,),
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
              DatabaseService(uid: user.uid).updatingUserData(
                _nameController.text,
                _curentSuger,
                _currentStrength
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

