import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError(
        'Web platformu için DefaultFirebaseOptions.currentPlatform desteklenmiyor.',
      );
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        throw UnsupportedError(
          'iOS platformu için DefaultFirebaseOptions.currentPlatform desteklenmiyor.',
        );
      case TargetPlatform.macOS:
        throw UnsupportedError(
          'macOS platformu için DefaultFirebaseOptions.currentPlatform desteklenmiyor.',
        );
      case TargetPlatform.windows:
        throw UnsupportedError(
          'Windows platformu için DefaultFirebaseOptions.currentPlatform desteklenmiyor.',
        );
      case TargetPlatform.linux:
        throw UnsupportedError(
          'Linux platformu için DefaultFirebaseOptions.currentPlatform desteklenmiyor.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions desteklenmeyen platform için yapılandırılmamış.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyB93wyQDeTEGcI8B23A9UAwG0ul_4inHho',
    appId: '1:680797746281:android:154b685b466ea9b22c5ef8',
    messagingSenderId: '680797746281',
    projectId: 'dailyetu',
    storageBucket: 'dailyetu.appspot.com',
    databaseURL: 'https://dailyetu.europe-west1.firebasedatabase.app',
  );
} 