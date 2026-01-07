import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/services.dart';
import 'package:flutter_coffee_app/model/brew_model.dart';
import 'package:flutter_coffee_app/model/user_model.dart';

class DatabaseService{


  final String? uid;
  DatabaseService({this.uid});

   final CollectionReference brewCollection =
    FirebaseFirestore.instance.collection('brew');

  


Future updatingUserData (String name, int strenght)async{
  return await brewCollection.doc(uid).set({
      'name': name,
      'strenght': strenght,
  }, SetOptions(merge: true));
}

Future<String?> uploadProfileImage(File file, {Function(int, int)? onProgress, int maxRetries = 1, Duration retryDelay = const Duration(milliseconds: 500)}) async {
  if (uid == null) return null;
  final ref = FirebaseStorage.instance.ref().child('users/$uid/profile.jpg');

  int attempt = 0;
  while (true) {
    try {
      final metadata = SettableMetadata(contentType: 'image/jpeg');
      final uploadTask = ref.putFile(file, metadata);

      // Listen to snapshot events to report progress and verbose info
      final sub = uploadTask.snapshotEvents.listen((snapshot) {
        final bytes = snapshot.bytesTransferred;
        final total = snapshot.totalBytes ?? 0;
        print('Storage upload snapshot: state=${snapshot.state}, bytes=$bytes, total=$total');
        if (onProgress != null && total > 0) onProgress(bytes, total);
      }, onError: (e) {
        print('Error listening to snapshotEvents: $e');
      });

      try {
        // Await completion and get the final snapshot so we can assert success
        final taskSnapshot = await uploadTask;
        print('Upload Task finished: state=${taskSnapshot.state}, bytesTransferred=${taskSnapshot.bytesTransferred}');
        if (taskSnapshot.state != TaskState.success) {
          throw FirebaseException(plugin: 'firebase_storage', message: 'Upload did not complete successfully (state=${taskSnapshot.state})', code: 'upload-not-successful');
        }

        // Get download URL, with explicit error handling for object-not-found
        String url;
        try {
          url = await ref.getDownloadURL();
        } on FirebaseException catch (e) {
          print('getDownloadURL failed: code=${e.code}, message=${e.message}');
          // If the object truly doesn't exist, this often means the upload did not complete
          throw PlatformException(code: e.code ?? 'get-download-url-failed', message: e.message ?? 'Failed to get download URL; check Storage rules and network');
        }

        // save url to firestore
        await brewCollection.doc(uid).set({'photoUrl': url}, SetOptions(merge: true));

        // Read back the document to verify the write made it to Firestore
        try {
          final doc = await brewCollection.doc(uid).get();
          final saved = (doc.data() as Map<String, dynamic>? ?? {})['photoUrl'];
          print('uploadProfileImage: wrote photoUrl=$url, readback photoUrl=$saved');
        } catch (e, st) {
          print('uploadProfileImage: error reading back Firestore doc: $e\n$st');
        }

        print('uploadProfileImage successful (attempt ${attempt + 1}): $url');
        return url;
      } finally {
        await sub.cancel();
      }
    } on FirebaseException catch (e, st) {
      // Verbose logging
      print('FirebaseException during upload attempt ${attempt + 1}: code=${e.code}, message=${e.message}, stack=$st');
      attempt++;
      if (attempt >= maxRetries) {
        throw PlatformException(code: e.code, message: e.message ?? e.toString());
      }
      await Future.delayed(retryDelay);
      print('Retrying upload (attempt ${attempt + 1})...');
    } catch (e, st) {
      print('Unexpected error during upload attempt ${attempt + 1}: $e\n$st');
      attempt++;
      if (attempt >= maxRetries) {
        throw PlatformException(code: 'upload-failed', message: e.toString());
      }
      await Future.delayed(retryDelay);
      print('Retrying upload after unexpected error (attempt ${attempt + 1})...');
    }
  }
}

Future updateProfileFields({String? name, String? photoUrl, String? description, bool? isBuying}) async {
  final data = <String, dynamic>{};
  if (name != null) data['name'] = name;
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
      strenght: data['strenght'] ?? 0,
      photoUrl: data['photoUrl'] as String?,
      description: data['description'] as String?,
      isBuying: data['isBuying'] as bool?,
      uid: doc.id,
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
    photoUrl: data['photoUrl'] as String?,
    description: data['description'] as String?,
    isBuying: data['isBuying'] as bool?,
  );
}

Stream <UserData> get userdatas{
  return brewCollection.doc(uid).snapshots().map(_userDataFromSnapshot);
}

} 