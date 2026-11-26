import 'package:flutter/widgets.dart';

import '../models/carps_models.dart';
import '../repositories/carps_repository.dart';
import '../services/carps_service.dart';

/// UI-facing application state: who is signed in, plus demo switches.
///
/// It forwards repository changes so any widget that watches it rebuilds when
/// shared state (registrations, passes, posts…) changes.
class AppController extends ChangeNotifier {
  AppController(this.repo, {Clock? clock})
      : service = CarpsService(repo, clock: clock) {
    repo.addListener(notifyListeners);
  }

  final CarpsRepository repo;
  final CarpsService service;

  String? _currentUserId;
  String? get currentUserId => _currentUserId;
  UserProfile? get me =>
      _currentUserId == null ? null : repo.user(_currentUserId!);
  bool get signedIn => me != null;

  /// Demo switch: makes "lookup" calls (attendance history, event picker)
  /// fail so the failure state can be reviewed. Never changes the rules.
  bool simulateLookupFailure = false;

  void setSimulateFailure(bool value) {
    simulateLookupFailure = value;
    notifyListeners();
  }

  void signIn(String userId) {
    _currentUserId = userId;
    notifyListeners();
  }

  void signOut() {
    _currentUserId = null;
    notifyListeners();
  }

  /// Simulated network lookup used by screens that need a loading and a
  /// failure state distinct from "empty".
  Future<T> lookup<T>(T Function() read) async {
    await Future<void>.delayed(const Duration(milliseconds: 350));
    if (simulateLookupFailure) {
      throw const RuleViolation('We could not reach CARPS. Check your connection.');
    }
    return read();
  }

  @override
  void dispose() {
    repo.removeListener(notifyListeners);
    super.dispose();
  }
}

/// Provides the [AppController] to the widget tree.
class AppScope extends InheritedNotifier<AppController> {
  const AppScope({super.key, required AppController controller, required super.child})
      : super(notifier: controller);

  static AppController watch(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AppScope>()!.notifier!;

  static AppController read(BuildContext context) =>
      context.getInheritedWidgetOfExactType<AppScope>()!.notifier!;
}

extension AppScopeX on BuildContext {
  AppController get app => AppScope.watch(this);
  AppController get appRead => AppScope.read(this);
  CarpsService get svc => AppScope.read(this).service;
}
