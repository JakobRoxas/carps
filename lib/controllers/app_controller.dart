import 'package:flutter/widgets.dart';

import '../models/carps_models.dart';
import 'auth_controller.dart';
import 'data_controller.dart';
import 'event_controller.dart';
import 'feed_controller.dart';
import 'notification_controller.dart';
import 'profile_controller.dart';
import 'registration_controller.dart';
import 'support_controller.dart';
import '../repositories/carps_repository.dart';
import '../services/carps_service.dart';
import '../services/carps_domain_operations.dart' show Clock;
import '../services/event_service.dart';
import '../services/registration_service.dart';
import '../services/social_service.dart';
import '../services/profile_service.dart';
import '../services/notification_service.dart';
import '../services/account_service.dart';
import '../services/support_service.dart';
import '../services/firebase_auth_gateway.dart';

/// UI-facing application state: who is signed in, plus demo switches.
///
/// It forwards repository changes so any widget that watches it rebuilds when
/// shared state (registrations, passes, posts…) changes.
class AppController extends ChangeNotifier {
  AppController(this.repo,
      {Clock? clock, FirebaseAuthGateway? authGateway, String? initialUserId})
      : _clock = clock ?? DateTime.now,
        _currentUserId = initialUserId {
    data = DataController(repo);

    // Each feature gets a focused domain service backed by the same repository
    // and clock. This keeps the controllers independent of the aggregate test
    // facade and prevents Views from reaching into unrelated feature logic.
    final eventService = EventService(repo, clock: _clock);
    final registrationService = RegistrationService(repo, clock: _clock);
    final socialService = SocialService(repo, clock: _clock);
    final profileService = ProfileService(repo, clock: _clock);
    final notificationService = NotificationService(repo, clock: _clock);
    final accountService = AccountService(repo, clock: _clock);
    final supportService = SupportService(repo, clock: _clock);

    events = EventController(
      eventService,
      registrationService,
      socialService,
      data,
    );
    registrations = RegistrationController(registrationService);
    feed = FeedController(socialService, data);
    profiles = ProfileController(profileService, data);
    notifications = NotificationController(notificationService);
    support = SupportController(supportService, data);
    auth = AuthController(service: accountService, gateway: authGateway);
    repo.addListener(notifyListeners);
  }

  final CarpsRepository repo;
  final Clock _clock;
  late final DataController data;

  /// Lazily-created aggregate facade for existing domain tests only.
  /// Production controllers use the focused services constructed above.
  late final CarpsService service = CarpsService(repo, clock: _clock);
  /// Feature controllers are the UI-facing API. Views should depend on these
  /// controllers rather than calling domain services or repositories.
  late final EventController events;
  late final RegistrationController registrations;
  late final FeedController feed;
  late final ProfileController profiles;
  late final NotificationController notifications;
  late final SupportController support;
  late final AuthController auth;

  String? _currentUserId;
  String? get currentUserId => _currentUserId;
  UserProfile? get me =>
      _currentUserId == null ? null : data.userById(_currentUserId!);
  bool get signedIn => me != null;

  String? get persistenceError => repo.persistenceError;

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

  Future<void> signOut() async {
    await auth.signOut();
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
}
