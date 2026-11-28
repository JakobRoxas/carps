import 'carps_enums.dart';
import 'event_models.dart';
import 'user_profile.dart';

/// Result returned when a host scans a guest pass.
class ScanResult {
  const ScanResult(this.outcome, {this.guest, this.arrivedAt, this.event});

  final ScanOutcome outcome;
  final UserProfile? guest;
  final DateTime? arrivedAt;
  final CarpsEvent? event;
}
