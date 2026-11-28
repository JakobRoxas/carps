import 'carps_domain_operations.dart';

/// Focused domain service for notification use cases.
class NotificationService extends CarpsServiceBase
    with
        NotificationOperations {
  NotificationService(super.repo, {super.clock});
}
