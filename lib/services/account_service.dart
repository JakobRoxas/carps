import 'carps_domain_operations.dart';

/// Focused domain service for account use cases.
class AccountService extends CarpsServiceBase
    with
        EventQueryOperations,
        AccountOperations {
  AccountService(super.repo, {super.clock});
}
