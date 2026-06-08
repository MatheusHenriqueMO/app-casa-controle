// Arquivo gerado pelo FlutterFire CLI.
// Rode: flutterfire configure
// e substitua este arquivo pelo gerado.

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions não configurado para esta plataforma. '
          'Execute: flutterfire configure',
        );
    }
  }

  // ⚠️  Substitua pelos valores reais após rodar `flutterfire configure`
  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'SEU_API_KEY',
    appId: 'SEU_APP_ID',
    messagingSenderId: 'SEU_SENDER_ID',
    projectId: 'SEU_PROJECT_ID',
    authDomain: 'SEU_PROJECT_ID.firebaseapp.com',
    storageBucket: 'SEU_PROJECT_ID.appspot.com',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyArMQM1xCDZqVWRNVv_U9ZuoWefY5jec7M',
    appId: '1:953162567615:android:7982c60f7e5008204a1b0a',
    messagingSenderId: '953162567615',
    projectId: 'casa-controle-c740a',
    storageBucket: 'casa-controle-c740a.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'SEU_API_KEY',
    appId: 'SEU_APP_ID',
    messagingSenderId: 'SEU_SENDER_ID',
    projectId: 'SEU_PROJECT_ID',
    storageBucket: 'SEU_PROJECT_ID.appspot.com',
    iosClientId: 'SEU_IOS_CLIENT_ID',
    iosBundleId: 'com.casacontrole.app',
  );
}
