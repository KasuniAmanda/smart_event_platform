import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: "AIzaSyBRdbSkPjKIy7Mxms4ZirNZa4o-GUuQ6IQ",
    authDomain: "smart-event-platform-3dcc0.firebaseapp.com",
    projectId: "smart-event-platform-3dcc0",
    storageBucket: "smart-event-platform-3dcc0.firebasestorage.app",
    messagingSenderId: "782750101423",
    appId: "1:782750101423:web:423c66793e02cdcb43095a",
    measurementId: "G-Q940LY301B",
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: "AIzaSyBRdbSkPjKIy7Mxms4ZirNZa4o-GUuQ6IQ",
    appId: "1:782750101423:android:f6d2ea5262df3d8343095a",
    messagingSenderId: "782750101423",
    projectId: "smart-event-platform-3dcc0",
    storageBucket: "smart-event-platform-3dcc0.firebasestorage.app",
  );
}