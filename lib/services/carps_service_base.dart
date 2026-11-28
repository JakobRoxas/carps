part of 'carps_domain_operations.dart';

/// Shared dependencies used by all feature-focused domain operations.
abstract class CarpsServiceBase {
  CarpsServiceBase(this.repo, {Clock? clock})
      : _clock = clock ?? DateTime.now;

  final CarpsRepository repo;
  final Clock _clock;

  DateTime get now => _clock();

  Duration get scanOpensBefore => const Duration(hours: 6);
}
