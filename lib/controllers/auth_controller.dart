import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

import '../models/carps_models.dart';
import '../models/carps_validation.dart';
import '../services/account_service.dart';
import '../services/firebase_auth_gateway.dart';

/// Coordinates authentication use cases for the presentation layer.
/// Firebase-specific exceptions are translated into application RuleViolations
/// so Views do not need to depend on Firebase SDK types.
class AuthController {
  AuthController({
    required AccountService service,
    required FirebaseAuthGateway? gateway,
  })  : _service = service,
        _gateway = gateway;

  final AccountService _service;
  final FirebaseAuthGateway? _gateway;

  bool get firebaseEnabled => _gateway != null;

  static bool isValidEmail(String email) =>
      CarpsValidation.isValidEmail(email);

  Future<UserProfile> signIn(String email, String password) async {
    final gateway = _gateway;
    if (gateway == null) return _service.logIn(email, password);
    try {
      return await gateway.signInWithEmail(email, password);
    } on FirebaseException catch (error) {
      throw RuleViolation(_firebaseMessage(error));
    }
  }

  Future<UserProfile> signUp(String email, String password) async {
    final gateway = _gateway;
    if (gateway == null) return _service.signUp(email, password);
    try {
      return await gateway.signUpWithEmail(email, password);
    } on FirebaseException catch (error) {
      throw RuleViolation(_firebaseMessage(error));
    }
  }

  Future<UserProfile> signInWithGoogle() async {
    final gateway = _gateway;
    if (gateway == null) {
      throw const RuleViolation('Google sign-in is not configured.');
    }
    try {
      return await gateway.signInWithGoogle();
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
