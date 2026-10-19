import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      throw UnsupportedError('Push is configured for Android.');
    }
    return android;
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyB43pPd94WFELzc-OGsV9405XUlpkf79AM',
    appId: '1:349254917417:android:3190919e85bb2830352b38',
    messagingSenderId: '349254917417',
    projectId: 'movex-c49cb',
    storageBucket: 'movex-c49cb.firebasestorage.app',
  );
}
