import 'carps_domain_operations.dart';

/// Focused domain service for registration use cases.
class RegistrationService extends CarpsServiceBase
    with
        EventQueryOperations,
        NotificationOperations,
        EventManagementOperations,
        RegistrationOperations {
  RegistrationService(super.repo, {super.clock});
}
