import 'package:flutter/material.dart';
import 'package:flutter_coffee_app/screen/loading.dart';
import 'package:flutter_coffee_app/services/auth.dart';
import 'package:flutter_coffee_app/utils/custom_text_field.dart';

class LoginWithEmail extends StatefulWidget {
  final Function? toggleView;
  const LoginWithEmail({super.key, this.toggleView});

  @override
  State<LoginWithEmail> createState() => _LoginWithEmailState();
}

class _LoginWithEmailState extends State<LoginWithEmail> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final AuthServices _authServices = AuthServices();
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
    return loading
        ? Loading()
        : Scaffold(
            backgroundColor: Colors.brown.shade100,
            appBar: AppBar(
              backgroundColor: Colors.brown.shade400,
              centerTitle: true,
              elevation: 0,
              title: Text('Login to Coffee App'),
              actions: [
                TextButton.icon(
                  onPressed: () {
                    widget.toggleView!();
                  },
                  label: Text(
                    'signUp',
                    style: TextStyle(fontSize: 14, color: Colors.white),
                  ),
                  icon: Icon(Icons.person, color: Colors.white),
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
                    onPressed: () async {
                      setState(() {
                        loading = true;
                      });
                      try {
                        dynamic res = await _authServices
                            .signInwithEmailandPassword(
                              context,
                              _emailController.text,
                              _passwordController.text,
                            );
                        if (res == null) {
                          // login failed, SnackBar already shown by AuthServices
                
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Login failed! Please check credentials.',
                              ),
                            ),
                          );
                        }
                      } finally {
                        if (mounted) {
                          setState(() {
                            loading = false;
                          });
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.brown.shade400,
                    ),
                    child: Text(
                      'LOG IN ',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          );
  }
}
