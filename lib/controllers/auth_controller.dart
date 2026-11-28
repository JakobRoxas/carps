import 'package:firebase_auth/firebase_auth.dart';

import '../models/carps_models.dart';
import '../services/account_service.dart';
import '../services/firebase_auth_gateway.dart';

/// Coordinates authentication use cases for the presentation layer.
/// Firebase-specific exceptions are translated into application RuleViolations
/// so Views do not need to depend on Firebase SDK types.
class AuthController {
  AuthController({
    required this._service,
    required this._gateway,
  });

  final AccountService _service;
  final FirebaseAuthGateway? _gateway;

  bool get firebaseEnabled => _gateway != null;

  static bool isValidEmail(String email) =>
      CarpsValidation.isValidEmail(email);

  Future<UserProfile> signIn(
    String email,
    String password, {
    bool keepSignedIn = true,
  }) async {
    final gateway = _gateway;
    if (gateway == null) return _service.logIn(email, password);
    try {
      return await gateway.signInWithEmail(
        email,
        password,
        keepSignedIn: keepSignedIn,
      );
    } on FirebaseException catch (error) {
      throw RuleViolation(_firebaseMessage(error));
    }
  }

  Future<UserProfile> signUp(
    String email,
    String password, {
    bool keepSignedIn = true,
  }) async {
    final gateway = _gateway;
    if (gateway == null) return _service.signUp(email, password);
    try {
      return await gateway.signUpWithEmail(
        email,
        password,
        keepSignedIn: keepSignedIn,
      );
    } on FirebaseException catch (error) {
      throw RuleViolation(_firebaseMessage(error));
    }
  }

  Future<UserProfile> signInWithGoogle({bool keepSignedIn = true}) async {
    final gateway = _gateway;
    if (gateway == null) {
      throw const RuleViolation('Google sign-in is not configured.');
    }
    try {
      return await gateway.signInWithGoogle(keepSignedIn: keepSignedIn);
    } on FirebaseException catch (error) {
      throw RuleViolation(_firebaseMessage(error));
    }
  }

  /// Returns false when the app is using its local/mock authentication flow.
  Future<bool> sendPasswordResetEmail(String email) async {
    final gateway = _gateway;
    if (gateway == null) return false;
    try {
      await gateway.sendPasswordResetEmail(email);
      return true;
    } on FirebaseException catch (error) {
      throw RuleViolation(_firebaseMessage(error));
    }
  }

  Future<void> signOut() async {
    final gateway = _gateway;
    if (gateway == null) return;
    try {
      await gateway.signOut();
    } on FirebaseException catch (error) {
      throw RuleViolation(_firebaseMessage(error));
    } on StateError catch (error) {
      throw RuleViolation(error.message.toString());
    }
  }

  String _firebaseMessage(FirebaseException error) =>
      error is FirebaseAuthException
          ? firebaseAuthErrorMessage(error)
          : (error.message ?? 'A Firebase request could not be completed.');
}
