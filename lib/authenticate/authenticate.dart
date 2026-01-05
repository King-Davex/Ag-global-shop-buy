import 'package:flutter/material.dart';
import 'package:flutter_coffee_app/authenticate/login_with_email.dart';
import 'package:flutter_coffee_app/authenticate/sign_in_with_email.dart';
class Authenticate extends StatefulWidget {
  const Authenticate({super.key});

  @override
  State<Authenticate> createState() => _AuthenticateState();
}

class _AuthenticateState extends State<Authenticate> {
  bool showSignIn = true;
   toggleView(){
    setState(() =>showSignIn =!showSignIn
    );
   }
   
  @override
  Widget build(BuildContext context) {
    

    if(showSignIn){
       return LoginWithEmail(toggleView: toggleView);
    }else{
      return SignInWithEmail(toggleView: toggleView);
    }
  
  }
} 