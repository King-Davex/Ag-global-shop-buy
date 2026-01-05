import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_coffee_app/model/user_model.dart';
import 'package:flutter_coffee_app/services/database.dart';

class AuthServices {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  UserModel? _userFromFirebase(User? user) {
    return user != null ? UserModel(uid: user.uid) : null;
  }

  // auth change user stream
  Stream<UserModel?> get user {
    return _auth.authStateChanges().map((User? user) {
      return _userFromFirebase(user);
    });
  }

  Future logout() async {
    try {
      await _auth.signOut();
    } catch (e) {
      print(e.toString());
    }
  }

  //sign in anon

  Future anonSignIn() async {
    try {
      UserCredential result = await _auth.signInAnonymously();
      User? user = result.user;
      return _userFromFirebase(user);
    } on FirebaseAuthException catch (e) {
      print('Error siging in anonymously ${e.message}');
      return null;
    }
  }

  Future registerWithEmailandPassword(
    BuildContext context,
    String email,
    String password,
  ) async {
    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('the Email or Password canot be empty')),
      );
      return null;
    } else {
      try {
        UserCredential result = await _auth.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );

        

        User? user = result.user;
       await DatabaseService(uid: user?.uid).updatingUserData('New User', '0', 100);
       
        return _userFromFirebase(user);
      } on FirebaseAuthException catch (e) {

        
   
        ScaffoldMessenger.of(
        
          context,
        ).showSnackBar(SnackBar(content: Text(e.message as String)));
      }
    }
  }
  // log in with email and password 
  Future signInwithEmailandPassword(
    BuildContext context,
    String email,
    String password,
  ) async {
    if (email.isEmpty || password.isEmpty) {
      return null;
      
    } else {
      try {
        UserCredential result = await _auth.signInWithEmailAndPassword(
          email: email,
          password: password,
        );
        User? user = result.user;
    
        return _userFromFirebase(user);
      } on FirebaseAuthException catch (e) {
        print(e);
   
       return null;
      }
    }
  }
}
