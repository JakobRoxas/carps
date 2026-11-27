import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/carps_models.dart';
import 'carps_firestore_codec.dart';
import 'carps_repository.dart';
import 'mock_carps_repository.dart';

/// Firebase-backed cache. User profiles use direct Firestore access.
/// Other CARPS features still use callable Functions.
class FirebaseCarpsRepository extends CarpsRepository {
  FirebaseCarpsRepository({required this.functions, required this._firestore});

  final FirebaseFunctions functions;
  final FirebaseFirestore _firestore;
  final CarpsFirestoreCodec _codec = const CarpsFirestoreCodec();

  final Map<String, UserProfile> _users = {};
  final Map<String, CarpsEvent> _events = {};
  final Map<String, Invitation> _invitations = {};
  final Map<String, Registration> _registrations = {};
  final Map<String, GuestPass> _passes = {};
  final Map<String, Attendance> _attendance = {};
  final Map<String, ExperiencePost> _posts = {};
  final Map<String, EventReview> _reviews = {};
  final Map<String, AppNotification> _notifications = {};
  final Map<String, SupportCase> _cases = {};

  Future<void> _writeTail = Future<void>.value();
  String? _persistenceError;
  int _idCounter = 0;

  @override
  String? get persistenceError => _persistenceError;

  @override
  void clearPersistenceError() {
    if (_persistenceError == null) return;
    _persistenceError = null;
    notifyListeners();
  }

  /// Loads the currently authenticated user's profile from Firestore.
  ///
  /// Other CARPS collections are not loaded yet because their migration
  /// to direct Firestore access is still pending.
  Future<void> load() async {
    final firebaseUser = FirebaseAuth.instance.currentUser;

    // Clear previous cached data.
    _users.clear();
    _events.clear();
    _invitations.clear();
    _registrations.clear();
    _passes.clear();
    _attendance.clear();
    _posts.clear();
    _reviews.clear();
    _notifications.clear();
    _cases.clear();

    // Temporarily restore the demo world for existing UI screens.
    final demo = MockCarpsRepository.seeded(DateTime.now());

    _users.addEntries(demo.users.map((value) => MapEntry(value.id, value)));
    _events.addEntries(demo.events.map((value) => MapEntry(value.id, value)));
    _invitations.addEntries(
      demo.invitations.map((value) => MapEntry(value.id, value)),
    );
    _registrations.addEntries(
      demo.registrations.map((value) => MapEntry(value.id, value)),
    );
    _passes.addEntries(demo.passes.map((value) => MapEntry(value.id, value)));
    _attendance.addEntries(
      demo.attendance.map(
        (value) => MapEntry(_attendanceId(value.eventId, value.userId), value),
      ),
    );
    _posts.addEntries(demo.posts.map((value) => MapEntry(value.id, value)));
    _reviews.addEntries(demo.reviews.map((value) => MapEntry(value.id, value)));
    _notifications.addEntries(
      demo.notifications.map((value) => MapEntry(value.id, value)),
    );
    _cases.addEntries(demo.cases.map((value) => MapEntry(value.id, value)));

    // If no Firebase account is signed in, display the demo world only.
    if (firebaseUser == null) {
      clearPersistenceError();
      notifyListeners();
      return;
    }

    // Load the actual Firebase user's profile.
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(firebaseUser.uid)
          .get();

      if (snapshot.exists) {
        final data = snapshot.data();

        if (data != null) {
          final profile = _codec.decodeUser(data);
          _users[profile.id] = profile;
        }
      }

      clearPersistenceError();
      notifyListeners();
    } on FirebaseException catch (error) {
      _recordPersistenceError(error.message ?? error.code);
      rethrow;
    }
  }

  @override
  String nextId(String prefix) {
    _idCounter++;

    return '${prefix}_${_firestore.collection('_ids').doc().id}_$_idCounter';
  }

  // ------------------------------------------------------------
  // USERS
  // ------------------------------------------------------------

  @override
  List<UserProfile> get users => List.unmodifiable(_users.values);

  @override
  UserProfile? user(String id) => _users[id];

  @override
  void saveUser(UserProfile value) {
    _users[value.id] = value;
    notifyListeners();

    _enqueue(
      () => _firestore
          .collection('users')
          .doc(value.id)
          .set(_codec.encodeUser(value)),
    );
  }

  // ------------------------------------------------------------
  // EVENTS
  // ------------------------------------------------------------

  @override
  List<CarpsEvent> get events => List.unmodifiable(_events.values);

  @override
  CarpsEvent? event(String id) => _events[id];

  @override
  void saveEvent(CarpsEvent value) {
    _events[value.id] = value;
    notifyListeners();

    _write('events', value.id, _codec.encodeEvent(value));
  }

  // ------------------------------------------------------------
  // INVITATIONS
  // ------------------------------------------------------------

  @override
  List<Invitation> get invitations => List.unmodifiable(_invitations.values);

  @override
  void saveInvitation(Invitation value) {
    _invitations[value.id] = value;
    notifyListeners();

    _write('invitations', value.id, _codec.encodeInvitation(value));
  }

  // ------------------------------------------------------------
  // REGISTRATIONS
  // ------------------------------------------------------------

  @override
  List<Registration> get registrations =>
      List.unmodifiable(_registrations.values);

  @override
  void saveRegistration(Registration value) {
    _registrations[value.id] = value;
    notifyListeners();

    _write('registrations', value.id, _codec.encodeRegistration(value));
  }

  // ------------------------------------------------------------
  // GUEST PASSES
  // ------------------------------------------------------------

  @override
  List<GuestPass> get passes => List.unmodifiable(_passes.values);

  @override
  GuestPass? passByToken(String token) {
    for (final value in _passes.values) {
      if (value.token == token) {
        return value;
      }
    }

    return null;
  }

  @override
  void savePass(GuestPass value) {
    _passes[value.id] = value;
    notifyListeners();

    _write('passes', value.id, _codec.encodePass(value));
  }

  // ------------------------------------------------------------
  // ATTENDANCE
  // ------------------------------------------------------------

  @override
  List<Attendance> get attendance => List.unmodifiable(_attendance.values);

  @override
  void saveAttendance(Attendance value) {
    final id = _attendanceId(value.eventId, value.userId);

    _attendance[id] = value;
    notifyListeners();

    _write('attendance', id, _codec.encodeAttendance(value));
  }

  @override
  void resolveAttendanceCorrection(
    SupportCase supportCase,
    Attendance? record,
  ) {
    if (record != null) {
      _attendance[_attendanceId(record.eventId, record.userId)] = record;
    }

    _cases[supportCase.id] = supportCase;
    notifyListeners();

    _enqueue(
      () => functions.httpsCallable('resolveCarpsAttendanceCase').call<void>({
        'caseData': _codec.encodeCase(supportCase),
        'attendanceData': record == null
            ? null
            : _codec.encodeAttendance(record),
      }),
    );
  }

  // ------------------------------------------------------------
  // POSTS
  // ------------------------------------------------------------

  @override
  List<ExperiencePost> get posts => List.unmodifiable(_posts.values);

  @override
  ExperiencePost? post(String id) => _posts[id];

  @override
  void savePost(ExperiencePost value) {
    _posts[value.id] = value;
    notifyListeners();

    _write('posts', value.id, _codec.encodePost(value));
  }

  @override
  void deletePost(String id) {
    _posts.remove(id);
    notifyListeners();

    _enqueue(
      () => functions.httpsCallable('deleteCarpsPost').call<void>({'id': id}),
    );
  }

  // ------------------------------------------------------------
  // REVIEWS
  // ------------------------------------------------------------

  @override
  List<EventReview> get reviews => List.unmodifiable(_reviews.values);

  @override
  void saveReview(EventReview value) {
    _reviews[value.id] = value;
    notifyListeners();

    _write('reviews', value.id, _codec.encodeReview(value));
  }

  // ------------------------------------------------------------
  // NOTIFICATIONS
  // ------------------------------------------------------------

  @override
  List<AppNotification> get notifications =>
      List.unmodifiable(_notifications.values);

  @override
  void saveNotification(AppNotification value) {
    _notifications[value.id] = value;
    notifyListeners();

    _write('notifications', value.id, _codec.encodeNotification(value));
  }

  // ------------------------------------------------------------
  // SUPPORT CASES
  // ------------------------------------------------------------

  @override
  List<SupportCase> get cases => List.unmodifiable(_cases.values);

  @override
  void saveCase(SupportCase value) {
    _cases[value.id] = value;
    notifyListeners();

    _write('cases', value.id, _codec.encodeCase(value));
  }

  // ------------------------------------------------------------
  // LEGACY CLOUD FUNCTION WRITES
  // ------------------------------------------------------------

  void _write(String collection, String id, Map<String, Object?> data) {
    if (collection == 'notifications') {
      _enqueue(
        () => functions.httpsCallable('createCarpsNotification').call<void>({
          'data': data,
        }),
      );
      return;
    }

    _enqueue(
      () => functions.httpsCallable('saveCarpsDocument').call<void>({
        'collection': collection,
        'id': id,
        'data': data,
      }),
    );
  }

  // ------------------------------------------------------------
  // WRITE QUEUE
  // ------------------------------------------------------------

  void _enqueue(Future<void> Function() write) {
    _writeTail = _writeTail.then((_) async {
      try {
        await write();
        clearPersistenceError();
      } on FirebaseFunctionsException catch (error) {
        _recordPersistenceError(error.message ?? error.code);
      } on FirebaseException catch (error) {
        _recordPersistenceError(error.message ?? error.code);
      }
    });
  }

  Future<void> flushPendingWrites() async {
    await _writeTail;

    if (_persistenceError case final error?) {
      throw StateError('Firebase write failed: $error');
    }
  }

  // ------------------------------------------------------------
  // ERROR HANDLING
  // ------------------------------------------------------------

  void _recordPersistenceError(String message) {
    _persistenceError = message;
    notifyListeners();
  }

  // ------------------------------------------------------------
  // HELPERS
  // ------------------------------------------------------------

  static String _attendanceId(String eventId, String userId) =>
      '${eventId}_$userId';
}
