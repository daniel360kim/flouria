// File generated by FlutterFire CLI.
// ignore_for_file: lines_longer_than_80_chars, avoid_classes_with_only_static_members
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
///
/// Example:
/// ```dart
/// import 'firebase_options.dart';
/// // ...
/// await Firebase.initializeApp(
///   options: DefaultFirebaseOptions.currentPlatform,
/// );
/// ```
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        return windows;
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyBqYpHBPdtF0zhx9FozmsjDB9B_yGbUSGM',
    appId: '1:704503689517:web:e53a33bd90fc880013e3a4',
    messagingSenderId: '704503689517',
    projectId: 'flourish-web-fa343',
    authDomain: 'flourish-web-fa343.firebaseapp.com',
    storageBucket: 'flourish-web-fa343.appspot.com',
    measurementId: 'G-7NRYNEC6P6',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAdoqQttmVEYzlof2VedwJfzQYhWiRtltw',
    appId: '1:704503689517:android:0d8c03d23aaf6b6713e3a4',
    messagingSenderId: '704503689517',
    projectId: 'flourish-web-fa343',
    storageBucket: 'flourish-web-fa343.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyBwoVEO-J9qBx-0ZoKKUosir4ItkMaDorw',
    appId: '1:704503689517:ios:1e37df82324fcf9e13e3a4',
    messagingSenderId: '704503689517',
    projectId: 'flourish-web-fa343',
    storageBucket: 'flourish-web-fa343.appspot.com',
    iosBundleId: 'com.example.flourishWeb',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyBwoVEO-J9qBx-0ZoKKUosir4ItkMaDorw',
    appId: '1:704503689517:ios:1e37df82324fcf9e13e3a4',
    messagingSenderId: '704503689517',
    projectId: 'flourish-web-fa343',
    storageBucket: 'flourish-web-fa343.appspot.com',
    iosBundleId: 'com.example.flourishWeb',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyBqYpHBPdtF0zhx9FozmsjDB9B_yGbUSGM',
    appId: '1:704503689517:web:fb8c2578d17858e713e3a4',
    messagingSenderId: '704503689517',
    projectId: 'flourish-web-fa343',
    authDomain: 'flourish-web-fa343.firebaseapp.com',
    storageBucket: 'flourish-web-fa343.appspot.com',
    measurementId: 'G-FT7BB3MG1B',
  );

}