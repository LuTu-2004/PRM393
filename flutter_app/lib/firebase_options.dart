import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Cau hinh Firebase tao tu google-services.json
/// Du an: exe-team-matching-70774
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      default:
        return android;
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyB4PfawQsPfXgbVNpQecajWIM4pna8_nwE',
    appId: '1:959409386646:android:c391fab6788676b2807eb7',
    messagingSenderId: '959409386646',
    projectId: 'exe-team-matching-70774',
    authDomain: 'exe-team-matching-70774.firebaseapp.com',
    storageBucket: 'exe-team-matching-70774.firebasestorage.app',
  );

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyB4PfawQsPfXgbVNpQecajWIM4pna8_nwE',
    appId: '1:959409386646:web:c391fab6788676b2807eb7',
    messagingSenderId: '959409386646',
    projectId: 'exe-team-matching-70774',
    authDomain: 'exe-team-matching-70774.firebaseapp.com',
    storageBucket: 'exe-team-matching-70774.firebasestorage.app',
  );
}
