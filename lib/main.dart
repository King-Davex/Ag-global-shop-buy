import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_coffee_app/home/wrapper.dart';
import 'package:flutter_coffee_app/model/user_model.dart';
import 'package:flutter_coffee_app/services/auth.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';

void main()async {
WidgetsFlutterBinding.ensureInitialized();
await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});


  @override
  Widget build(BuildContext context) {
    return StreamProvider<UserModel?>.value(
      initialData: null,
      value: AuthServices().user,

      child: MaterialApp(
        debugShowCheckedModeBanner:false,
        title: 'Flutter Demo',
        theme: ThemeData(
          
          useMaterial3: true
        ),
        home: Wrapper()
      ),
    );
  }
}

