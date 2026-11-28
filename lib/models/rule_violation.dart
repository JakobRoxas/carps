/// Thrown when a rule blocks an action. The message is user-facing.
class RuleViolation implements Exception {
  const RuleViolation(this.message);
  final String message;
  @override
  String toString() => message;
}
