

import 'package:flutter/material.dart';
import 'package:flutter_coffee_app/screen/loading.dart';
import 'package:flutter_coffee_app/services/auth.dart';

import 'package:flutter_coffee_app/utils/custom_text_field.dart';

class SignInWithEmail extends StatefulWidget {
  final Function? toggleView;
 

  const SignInWithEmail({super.key,  this.toggleView});

  @override
  State<SignInWithEmail> createState() => _SignInWithEmailState();
}

class _SignInWithEmailState extends State<SignInWithEmail> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
 final AuthServices _authServices =AuthServices();
 bool loading = false;
  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  bool hidetext = true;
  @override
  Widget build(BuildContext context) {
    return loading? Loading(): Scaffold(
      backgroundColor: Colors.brown.shade100,
      appBar: AppBar(
        backgroundColor: Colors.brown.shade400,
        centerTitle: true,
        elevation: 0,
        title: Text('Sign in to Coffee App'),
        actions: [
          TextButton.icon(
            onPressed: (){
             
                widget.toggleView!();
      
              
             
            },
            label: Text('LOGIN',style: TextStyle(fontSize: 14, color: Colors.white),),
            icon: Icon(Icons.person, color: Colors.white,),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CustomTextField(
              hintText: 'Enter your Email',
              controller: _emailController,
              prefixIcon: Icon(Icons.email),
            ),
            SizedBox(height: 10),
            CustomTextField(
              hintText: 'Enter your Password',
              controller: _passwordController,
              prefixIcon: Icon(Icons.lock),
              obscureText: hidetext,
              suffixIcon: IconButton(
                onPressed: () {
                  setState(() {
                    hidetext = !hidetext;
                  });
                },
                icon: hidetext == true
                    ? Icon(Icons.remove_moderator_outlined)
                    : Icon(Icons.remove_red_eye),
              ),
            ),
            SizedBox(height: 10),

            ElevatedButton(
              onPressed: () async{
                setState(() {
                  loading=true;
                });
              dynamic result = await _authServices.registerWithEmailandPassword(context, _emailController.text, _passwordController.text);
              print(result);
              if(mounted){
                 setState(() {
                  loading=false;
                });
              }
             
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.brown.shade400,
              ),
              child: Text('REGISTER', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}
