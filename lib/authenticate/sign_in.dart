import 'package:flutter/material.dart';
import 'package:flutter_coffee_app/screen/show_snack_bar.dart';
import 'package:flutter_coffee_app/services/auth.dart';

class SignIn extends StatefulWidget {
  const SignIn({super.key});

  @override
  State<SignIn> createState() => _SignInState();
}

class _SignInState extends State<SignIn> {
  final AuthServices _authServices =AuthServices();
  @override
  Widget build(BuildContext context) {
   return Scaffold(
      backgroundColor: Colors.brown.shade100,
      appBar: AppBar(
        backgroundColor: Colors.brown.shade400,
         centerTitle: true,
         elevation: 0,
         title: Text('Sign in to Coffee App'),
      ),
      body: Center(
        child: ElevatedButton(onPressed: () async{
       dynamic res = await _authServices.anonSignIn();
       if(res == null){
        showSnackBar(context, 'Error signing in');
       }else{
        showSnackBar(context, 'Signed in');
        print(res.uid);
       }
        }, child: Text('Sign in Anon')),
      ),
    );
  }
}