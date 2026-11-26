import 'package:firebase_core/firebase_core.dart';

import '../firebase_options.dart';

class FirebaseRuntime {
  const FirebaseRuntime._();

  static const enabled = true;
  static const useEmulators = false;

  static FirebaseOptions get options => DefaultFirebaseOptions.currentPlatform;
}
