import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';

import '../models/carps_models.dart';
import 'carps_firestore_codec.dart';
import 'carps_repository.dart';

/// Firebase-backed cache. Callable Functions own reads, validation and writes.
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

  Future<void> load() async {
    final response = await _loadData();
    final root = _asMap(response.data, 'backend response');
    _replace(
      _users,
      _decodeList(root, 'users', _codec.decodeUser),
      (value) => value.id,
    );
    _replace(
      _events,
      _decodeList(root, 'events', _codec.decodeEvent),
      (value) => value.id,
    );
    _replace(
      _invitations,
      _decodeList(root, 'invitations', _codec.decodeInvitation),
      (value) => value.id,
    );
    _replace(
      _registrations,
      _decodeList(root, 'registrations', _codec.decodeRegistration),
      (value) => value.id,
    );
    _replace(
      _passes,
      _decodeList(root, 'passes', _codec.decodePass),
      (value) => value.id,
    );
    _replace(
      _attendance,
      _decodeList(root, 'attendance', _codec.decodeAttendance),
      (value) => _attendanceId(value.eventId, value.userId),
    );
    _replace(
      _posts,
      _decodeList(root, 'posts', _codec.decodePost),
      (value) => value.id,
    );
    _replace(
      _reviews,
      _decodeList(root, 'reviews', _codec.decodeReview),
      (value) => value.id,
    );
    _replace(
      _notifications,
      _decodeList(root, 'notifications', _codec.decodeNotification),
      (value) => value.id,
    );
    _replace(
      _cases,
      _decodeList(root, 'cases', _codec.decodeCase),
      (value) => value.id,
    );
    clearPersistenceError();
    notifyListeners();
  }

  Future<HttpsCallableResult<Object?>> _loadData() async {
    try {
      return await functions.httpsCallable('getCarpsData').call<Object?>();
    } on FirebaseFunctionsException catch (error) {
      _recordPersistenceError(error.message ?? error.code);
      rethrow;
    } on FirebaseException catch (error) {
      _recordPersistenceError(error.message ?? error.code);
      rethrow;
    }
  }

  static Map<String, dynamic> _asMap(Object? value, String label) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    throw FormatException('Expected $label to be an object.');
  }

  static List<T> _decodeList<T>(
    Map<String, dynamic> root,
    String key,
    T Function(Map<String, dynamic>) decode,
  ) {
    final values = root[key];
    if (values == null) return const [];
    if (values is! List) {
      throw FormatException(
        'Expected "$key" in backend response to be a list.',
      );
    }
    return values.map((value) => decode(_asMap(value, key))).toList();
  }

  static void _replace<T>(
    Map<String, T> target,
    Iterable<T> values,
    String Function(T) keyOf,
  ) {
    target
      ..clear()
      ..addEntries(values.map((value) => MapEntry(keyOf(value), value)));
  }

  @override
  String nextId(String prefix) {
    _idCounter++;
    return '${prefix}_${_firestore.collection('_ids').doc().id}_$_idCounter';
  }

  @override
  List<UserProfile> get users => List.unmodifiable(_users.values);
  @override
  UserProfile? user(String id) => _users[id];
  @override
  void saveUser(UserProfile value) {
    _users[value.id] = value;
    notifyListeners();
    _write('users', value.id, _codec.encodeUser(value));
  }

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

  @override
  List<Invitation> get invitations => List.unmodifiable(_invitations.values);
  @override
  void saveInvitation(Invitation value) {
    _invitations[value.id] = value;
    notifyListeners();
    _write('invitations', value.id, _codec.encodeInvitation(value));
  }

  @override
  List<Registration> get registrations =>
      List.unmodifiable(_registrations.values);
  @override
  void saveRegistration(Registration value) {
    _registrations[value.id] = value;
    notifyListeners();
    _write('registrations', value.id, _codec.encodeRegistration(value));
  }

  @override
  List<GuestPass> get passes => List.unmodifiable(_passes.values);
  @override
  GuestPass? passByToken(String token) {
    for (final value in _passes.values) {
      if (value.token == token) return value;
    }
    return null;
  }

  @override
  void savePass(GuestPass value) {
    _passes[value.id] = value;
    notifyListeners();
    _write('passes', value.id, _codec.encodePass(value));
  }

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
      SupportCase supportCase, Attendance? record) {
    if (record != null) {
      _attendance[_attendanceId(record.eventId, record.userId)] = record;
    }
    _cases[supportCase.id] = supportCase;
    notifyListeners();
    _enqueue(
      () => functions.httpsCallable('resolveCarpsAttendanceCase').call<void>({
        'caseData': _codec.encodeCase(supportCase),
        'attendanceData':
            record == null ? null : _codec.encodeAttendance(record),
      }),
    );
  }

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

  @override
  List<EventReview> get reviews => List.unmodifiable(_reviews.values);
  @override
  void saveReview(EventReview value) {
    _reviews[value.id] = value;
    notifyListeners();
    _write('reviews', value.id, _codec.encodeReview(value));
  }

  @override
  List<AppNotification> get notifications =>
      List.unmodifiable(_notifications.values);
  @override
  void saveNotification(AppNotification value) {
    _notifications[value.id] = value;
    notifyListeners();
    _write('notifications', value.id, _codec.encodeNotification(value));
  }

  @override
  List<SupportCase> get cases => List.unmodifiable(_cases.values);
  @override
  void saveCase(SupportCase value) {
    _cases[value.id] = value;
    notifyListeners();
    _write('cases', value.id, _codec.encodeCase(value));
  }

  void _write(String collection, String id, Map<String, Object?> data) {
    if (collection == 'notifications') {
      _enqueue(
        () => functions
            .httpsCallable('createCarpsNotification')
            .call<void>({'data': data}),
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

  void _recordPersistenceError(String message) {
    _persistenceError = message;
    notifyListeners();
  }

  static String _attendanceId(String eventId, String userId) =>
      '${eventId}_$userId';
}
