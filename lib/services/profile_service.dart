import 'carps_domain_operations.dart';

/// Focused domain service for profile use cases.
class ProfileService extends CarpsServiceBase
    with
        EventQueryOperations,
        NotificationOperations,
        EventManagementOperations,
        RegistrationOperations,
        SocialOperations,
        ProfileOperations,
        AccountOperations {
  ProfileService(super.repo, {super.clock});
}
