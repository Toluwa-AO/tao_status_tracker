// File generated by FlutterFire CLI.
// ignore_for_file: type=lint
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
    apiKey: 'AIzaSyDgWs3oIetPtmINcgoTOY4x8rsYP0zNMwQ',
    appId: '1:473100021446:web:55bab519c887287b7131c7',
    messagingSenderId: '473100021446',
    projectId: 'status-tracker-7d6bf',
    authDomain: 'status-tracker-7d6bf.firebaseapp.com',
    storageBucket: 'status-tracker-7d6bf.firebasestorage.app',
    measurementId: 'G-BE40J0GSRF',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAKy01HmA4YHKXuzWotmt2-0sGTenSkhZ0',
    appId: '1:473100021446:android:10faeb97a4e18c8e7131c7',
    messagingSenderId: '473100021446',
    projectId: 'status-tracker-7d6bf',
    storageBucket: 'status-tracker-7d6bf.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyATewUKEjRzueXpi-1bJ_cng-nRcwq-Eyg',
    appId: '1:473100021446:ios:926013489e93eefc7131c7',
    messagingSenderId: '473100021446',
    projectId: 'status-tracker-7d6bf',
    storageBucket: 'status-tracker-7d6bf.firebasestorage.app',
    iosBundleId: 'com.example.taoStatusTracker',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyATewUKEjRzueXpi-1bJ_cng-nRcwq-Eyg',
    appId: '1:473100021446:ios:926013489e93eefc7131c7',
    messagingSenderId: '473100021446',
    projectId: 'status-tracker-7d6bf',
    storageBucket: 'status-tracker-7d6bf.firebasestorage.app',
    iosBundleId: 'com.example.taoStatusTracker',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyDgWs3oIetPtmINcgoTOY4x8rsYP0zNMwQ',
    appId: '1:473100021446:web:f2bbe0529d31cd477131c7',
    messagingSenderId: '473100021446',
    projectId: 'status-tracker-7d6bf',
    authDomain: 'status-tracker-7d6bf.firebaseapp.com',
    storageBucket: 'status-tracker-7d6bf.firebasestorage.app',
    measurementId: 'G-433YQYZC60',
  );
}
