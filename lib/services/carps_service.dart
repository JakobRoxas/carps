import 'carps_domain_operations.dart';

/// Aggregate domain-service facade retained for domain tests and migration.
/// Production UI code uses the focused services and feature controllers.
class CarpsService extends CarpsServiceBase
    with
        EventQueryOperations,
        NotificationOperations,
        EventManagementOperations,
        RegistrationOperations,
        SocialOperations,
        ProfileOperations,
        AccountOperations,
        SupportOperations {
  CarpsService(super.repo, {super.clock});
}
