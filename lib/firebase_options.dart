import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show defaultTargetPlatform, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      default:
        throw UnsupportedError('Firebase is only configured for Android.');
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyC4CHRqP8yJwTTyMWc25MoERQ4NizKCGn0',
    appId: '1:943889886105:android:9924baaca4e895738a4108',
    messagingSenderId: '943889886105',
    projectId: 'smart-task-manager-9a794',
    storageBucket: 'smart-task-manager-9a794.firebasestorage.app',
  );
}
