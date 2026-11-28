import 'carps_domain_operations.dart';

/// Focused domain service for event use cases.
class EventService extends CarpsServiceBase
    with
        EventQueryOperations,
        NotificationOperations,
        EventManagementOperations {
  EventService(super.repo, {super.clock});
}
