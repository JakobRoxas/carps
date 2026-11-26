import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

class FirebaseRuntime {
  const FirebaseRuntime._();

  static const enabled = bool.fromEnvironment(
    'CARPS_USE_FIREBASE',
    defaultValue: false,
  );
  static const useEmulators = bool.fromEnvironment(
    'CARPS_USE_FIREBASE_EMULATORS',
    defaultValue: false,
  );

  static String get emulatorHost {
    if (kIsWeb) return 'localhost';
    return defaultTargetPlatform == TargetPlatform.android
        ? '10.0.2.2'
        : 'localhost';
  }

  static FirebaseOptions get options {
    if (useEmulators) {
      return const FirebaseOptions(
        apiKey: 'demo-api-key',
        appId: '1:1234567890:web:carpsdemo',
        messagingSenderId: '1234567890',
        projectId: 'demo-carps',
        authDomain: 'demo-carps.firebaseapp.com',
      );
    }

    const apiKey = String.fromEnvironment('FIREBASE_API_KEY');
    const sharedAppId = String.fromEnvironment('FIREBASE_APP_ID');
    const webAppId = String.fromEnvironment('FIREBASE_WEB_APP_ID');
    const androidAppId = String.fromEnvironment('FIREBASE_ANDROID_APP_ID');
    const iosAppId = String.fromEnvironment('FIREBASE_IOS_APP_ID');
    const messagingSenderId = String.fromEnvironment(
      'FIREBASE_MESSAGING_SENDER_ID',
    );
    const projectId = String.fromEnvironment('FIREBASE_PROJECT_ID');
    final appId = kIsWeb
        ? (webAppId.isEmpty ? sharedAppId : webAppId)
        : switch (defaultTargetPlatform) {
            TargetPlatform.android =>
              androidAppId.isEmpty ? sharedAppId : androidAppId,
            TargetPlatform.iOS => iosAppId.isEmpty ? sharedAppId : iosAppId,
            _ => sharedAppId,
          };
    if (apiKey.isEmpty ||
        appId.isEmpty ||
        messagingSenderId.isEmpty ||
        projectId.isEmpty) {
      throw StateError(
        'Firebase is enabled but project settings are missing. Run '
        '`flutterfire configure` and provide the Firebase app settings as '
        'FIREBASE_* dart-defines, or use the Firebase emulators.',
      );
    }
    return FirebaseOptions(
      apiKey: apiKey,
      appId: appId,
      messagingSenderId: messagingSenderId,
      projectId: projectId,
      authDomain: String.fromEnvironment('FIREBASE_AUTH_DOMAIN'),
      storageBucket: String.fromEnvironment('FIREBASE_STORAGE_BUCKET'),
      iosBundleId: String.fromEnvironment('FIREBASE_IOS_BUNDLE_ID'),
      androidClientId: String.fromEnvironment('FIREBASE_ANDROID_CLIENT_ID'),
      iosClientId: String.fromEnvironment('FIREBASE_IOS_CLIENT_ID'),
    );
  }
}
