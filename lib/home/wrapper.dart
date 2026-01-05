import 'package:flutter/material.dart';
import 'package:flutter_coffee_app/authenticate/authenticate.dart';


//import 'package:flutter_coffee_app/authenticate/sign_in.dart';
//import 'package:flutter_coffee_app/authenticate/sign_in_with_email.dart';

import 'package:flutter_coffee_app/home/home.dart';
import 'package:flutter_coffee_app/model/user_model.dart';
import 'package:provider/provider.dart';

class Wrapper extends StatelessWidget {
  const Wrapper({super.key});

  @override
  Widget build(BuildContext context) {
    // Use UserModel? (nullable) instead of UserModel
    final user = Provider.of<UserModel?>(context);
    
    if (user == null || user.uid.isEmpty) {
      return Authenticate();
    } else {
      return Home();
    }
  }
}