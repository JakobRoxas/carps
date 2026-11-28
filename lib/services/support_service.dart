import 'carps_domain_operations.dart';

/// Focused domain service for support use cases.
class SupportService extends CarpsServiceBase
    with
        EventQueryOperations,
        NotificationOperations,
        SupportOperations {
  SupportService(super.repo, {super.clock});
}
