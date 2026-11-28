import 'package:firebase_auth/firebase_auth.dart';

import '../models/carps_models.dart';
import '../models/carps_validation.dart';
import '../repositories/firebase_carps_repository.dart';

class FirebaseAuthGateway {
  FirebaseAuthGateway({required this.auth, required this.repository});

  final FirebaseAuth auth;
  final FirebaseCarpsRepository repository;

  Future<UserProfile> signInWithEmail(String email, String password) async {
    final credential = await auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    await _loadAccount(credential.user!);
    return _loadOrCreateProfile(credential.user!);
  }

  Future<UserProfile> signUpWithEmail(String email, String password) async {
    if (!CarpsValidation.isValidEmail(email)) {
      throw const RuleViolation('Enter a valid email.');
    }
    if (password.length < 8) {
      throw const RuleViolation('Use at least 8 characters for your password.');
    }
    final credential = await auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    await _loadAccount(credential.user!);
    return _loadOrCreateProfile(credential.user!);
  }

  Future<UserProfile> signInWithGoogle() async {
    final credential = await auth.signInWithProvider(GoogleAuthProvider());
    final user = credential.user;
    if (user == null) {
      throw const RuleViolation('Google sign-in did not return an account.');
    }
    await _loadAccount(user);
    return _loadOrCreateProfile(user);
  }

  Future<void> sendPasswordResetEmail(String email) async {
    if (!CarpsValidation.isValidEmail(email)) {
      throw const RuleViolation('Enter a valid email address.');
    }
    await auth.sendPasswordResetEmail(email: email.trim());
  }

  Future<void> signOut() async {
    StateError? writeError;
    try {
      await repository.flushPendingWrites();
    } on StateError catch (error) {
      writeError = error;
    }
    await auth.signOut();
    repository.clear();
    if (writeError != null) throw writeError;
  }

  Future<UserProfile?> restoreSession() async {
    final user = await auth.authStateChanges().first;
    if (user == null) return null;
    await _loadAccount(user);
    return _loadOrCreateProfile(user);
  }

  Future<void> _loadAccount(User user) =>
      repository.load(userId: user.uid, email: user.email ?? '');

  Future<UserProfile> _loadOrCreateProfile(User user) async {
    final existing = repository.user(user.uid);
    if (existing != null) return existing;

    final email = user.email;
    if (email == null || email.isEmpty) {
      throw const RuleViolation(
        'This Firebase account does not have an email address.',
      );
    }
    final usernameBase = email
        .split('@')
        .first
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9_]'), '');
    final usernamePrefix = usernameBase.isEmpty ? 'member' : usernameBase;
    final username =
        '${usernamePrefix.substring(0, usernamePrefix.length > 13 ? 13 : usernamePrefix.length)}_'
        '${user.uid.substring(0, user.uid.length > 6 ? 6 : user.uid.length).toLowerCase()}';
    final profile = UserProfile(
      id: user.uid,
      displayName: user.displayName ?? '',
      username: username,
      email: email,
      avatarAsset: user.photoURL,
    );
    repository.saveUser(profile);
    await repository.flushPendingWrites();
    return profile;
  }
}

String firebaseAuthErrorMessage(FirebaseAuthException error) {
  return switch (error.code) {
    'email-already-in-use' => 'An account with this email already exists.',
    'invalid-email' => 'Enter a valid email address.',
    'invalid-credential' ||
    'wrong-password' ||
    'user-not-found' => 'Email or password is incorrect.',
    'weak-password' => 'Use at least 8 characters for your password.',
    'network-request-failed' =>
      'We could not reach Firebase. Check your connection and try again.',
    _ => error.message ?? 'Authentication failed. Please try again.',
  };
}
