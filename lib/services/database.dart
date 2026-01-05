import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_coffee_app/model/brew_model.dart';
import 'package:flutter_coffee_app/model/user_model.dart';

class DatabaseService{


  final String? uid;
  DatabaseService({this.uid});

   final CollectionReference brewCollection =
    FirebaseFirestore.instance.collection('brew');

  


Future updatingUserData (String name, String sugar, int strenght)async{
  return await brewCollection.doc(uid).set({
      'sugar':sugar,
      'name':name,
      'strenght':strenght,
  });
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
  final data = snapshot.data() as Map<String, dynamic>;

  return UserData(
    uid: uid, // or uid if it's a class variable
    name: data['name'],
    strenght: data['strenght'],
    sugar: data['sugar']
  );
}

Stream <UserData> get userdatas{
  return brewCollection.doc(uid).snapshots().map(_userDataFromSnapshot);
}

} 