import 'carps_domain_operations.dart';

/// Focused domain service for social use cases.
class SocialService extends CarpsServiceBase
    with
        EventQueryOperations,
        NotificationOperations,
        EventManagementOperations,
        RegistrationOperations,
        SocialOperations {
  SocialService(super.repo, {super.clock});
}
