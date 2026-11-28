import 'package:firebase_core/firebase_core.dart';

import '../firebase_options.dart';

class FirebaseRuntime {
  const FirebaseRuntime._();

  static FirebaseOptions get options => DefaultFirebaseOptions.currentPlatform;
  static const useEmulators = bool.fromEnvironment(
    'USE_FIREBASE_EMULATORS',
    defaultValue: false,
  );
  static const useMockData = bool.fromEnvironment(
    'USE_MOCK_DATA',
    defaultValue: false,
  );
}
