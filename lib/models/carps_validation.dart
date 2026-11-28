/// Shared validation rules used by the domain and authentication layers.
abstract final class CarpsValidation {
  static final RegExp usernamePattern = RegExp(r'^[a-z0-9_]{3,20}$');

  static bool isValidEmail(String email) =>
      RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email.trim());
}
