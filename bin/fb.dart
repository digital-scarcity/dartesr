import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:firebase/firebase.dart';
import 'package:firebase/firestore.dart' as fs;

void main(List<String> arguments) async {
  initializeApp(
      apiKey: 'AIzaSyAikxTENa83Eqlvk5EEmvASxUFBlEC_7E8',
      authDomain: 'esr-dart.firebaseapp.com',
      databaseURL: 'https://esr-dart.firebaseio.com',
      projectId: 'esr-dart',
      storageBucket: 'esr-dart.appspot.com',
      messagingSenderId: '993234506659',
      appId: '1:993234506659:web:0b4acefdba41a399ce0016',
      measurementId: 'G-K65BHLS9VM');

  fs.Firestore store = firestore();
  fs.CollectionReference ref = store.collection('messages');

  ref.onSnapshot.listen((querySnapshot) {
    querySnapshot.docChanges().forEach((change) {
      if (change.type == "added") {
        // Do something with change.doc
      }
    });
  });
}
