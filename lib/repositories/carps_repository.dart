import 'package:flutter/foundation.dart';

import '../models/carps_models.dart';

/// Storage boundary for CARPS.
///
/// Views read through DataController and invoke feature Controllers. The
/// Controllers coordinate use cases with domain services, which enforce
/// product rules before writes reach this repository. Implementations keep a local cache for the
/// synchronous reads below and persist writes to their backing store.
///
/// The repository notifies listeners after every write so the UI rebuilds.
abstract class CarpsRepository extends ChangeNotifier {
  /// Clears the local cache without deleting records from a remote store.
  void clear();

  /// Last remote persistence failure, if any. Mock repositories have none.
  String? get persistenceError => null;

  void clearPersistenceError() {}

  // Users
  List<UserProfile> get users;
  UserProfile? user(String id);
  void saveUser(UserProfile user);

  // Events
  List<CarpsEvent> get events;
  CarpsEvent? event(String id);
  void saveEvent(CarpsEvent event);

  // Invitations (co-host and private guest invitations are distinct kinds)
  List<Invitation> get invitations;
  void saveInvitation(Invitation invitation);

  // Registrations: one record per guest per event, shared by guest and host.
  List<Registration> get registrations;
  void saveRegistration(Registration registration);
  void saveApprovedRegistration(Registration registration, GuestPass pass) {
    savePass(pass);
    saveRegistration(registration);
  }

  // Passes
  List<GuestPass> get passes;
  GuestPass? passByToken(String token);
  void savePass(GuestPass pass);

  // Attendance (created only by a valid first scan)
  List<Attendance> get attendance;
  void saveAttendance(Attendance record);
  void resolveAttendanceCorrection(
    SupportCase supportCase,
    Attendance? record,
  ) {
    if (record != null) saveAttendance(record);
    saveCase(supportCase);
  }

  // Posts
  List<ExperiencePost> get posts;
  ExperiencePost? post(String id);
  void savePost(ExperiencePost post);
  void deletePost(String id);

  // Reviews
  List<EventReview> get reviews;
  void saveReview(EventReview review);

  // Notifications
  List<AppNotification> get notifications;
  void saveNotification(AppNotification notification);

  // Support cases
  List<SupportCase> get cases;
  void saveCase(SupportCase supportCase);

  /// Monotonic id helper so the mock and tests produce stable ids.
  String nextId(String prefix);
}
