import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_coffee_app/model/brew_model.dart';
import 'package:flutter_coffee_app/model/user_model.dart';

class DatabaseService{


  final String? uid;
  DatabaseService({this.uid});

   final CollectionReference brewCollection =
    FirebaseFirestore.instance.collection('brew');

  


Future updatingUserData (String name, String sugar, int strenght)async{
  return await brewCollection.doc(uid).set({
      'sugar': sugar,
      'name': name,
      'strenght': strenght,
  }, SetOptions(merge: true));
}

Future<String?> uploadProfileImage(File file) async {
  if (uid == null) return null;
  final ref = FirebaseStorage.instance.ref().child('users/$uid/profile.jpg');
  await ref.putFile(file);
  final url = await ref.getDownloadURL();
  // save url to firestore
  await brewCollection.doc(uid).set({'photoUrl': url}, SetOptions(merge: true));
  return url;
}

Future updateProfileFields({String? photoUrl, String? description, bool? isBuying}) async {
  final data = <String, dynamic>{};
  if (photoUrl != null) data['photoUrl'] = photoUrl;
  if (description != null) data['description'] = description;
  if (isBuying != null) data['isBuying'] = isBuying;
  if (data.isEmpty) return null;
  return await brewCollection.doc(uid).set(data, SetOptions(merge: true));
}

List<Brew> _brewListFromSnapshot(QuerySnapshot snapshot) {
  return snapshot.docs.map((doc) {
    final data = doc.data() as Map<String, dynamic>;

    return Brew(
      name: data['name'] ?? '',
      sugar: data['sugar'] ?? '0',
      strenght: data['strenght'] ?? 0,
    );
  }).toList();
}

Stream<List<Brew>> get brews {
  return brewCollection.snapshots().map(_brewListFromSnapshot);
}

UserData _userDataFromSnapshot(DocumentSnapshot snapshot) {
  final data = snapshot.data() as Map<String, dynamic>? ?? {};

  return UserData(
    uid: uid,
    name: data['name'] as String?,
    strenght: (data['strenght'] is int) ? data['strenght'] as int : (data['strenght'] != null ? int.tryParse(data['strenght'].toString()) : null),
    sugar: data['sugar'] as String?,
    photoUrl: data['photoUrl'] as String?,
    description: data['description'] as String?,
    isBuying: data['isBuying'] as bool?,
  );
}

Stream <UserData> get userdatas{
  return brewCollection.doc(uid).snapshots().map(_userDataFromSnapshot);
}

} 