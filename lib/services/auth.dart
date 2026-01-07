import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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
      
      // Ensure user document exists in Firestore (initialize if missing)
      if (user != null) {
        final dbService = DatabaseService(uid: user.uid);
        // Check if document exists, if not create it with default values
        final doc = await FirebaseFirestore.instance.collection('brew').doc(user.uid).get();
        if (!doc.exists) {
          await dbService.updateProfileFields(
            name: 'Anonymous User',
            description: '',
            isBuying: false,
          );
        }
      }
      
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
       // Initialize user document without adding sugar/strength fields; set a default name and empty profile fields
       await DatabaseService(uid: user?.uid).updateProfileFields(name: 'New User', description: '', isBuying: false);
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
        
        // Ensure user document exists in Firestore (initialize if missing)
        if (user != null) {
          final dbService = DatabaseService(uid: user.uid);
          // Check if document exists, if not create it with default values
          final doc = await FirebaseFirestore.instance.collection('brew').doc(user.uid).get();
          if (!doc.exists) {
            await dbService.updateProfileFields(
              name: email.split('@')[0], // Use email username as default name
              description: '',
              isBuying: false,
            );
          }
        }
    
        return _userFromFirebase(user);
      } on FirebaseAuthException catch (e) {
        print(e);
   
       return null;
      }
    }
  }
}
