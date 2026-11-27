import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/carps_models.dart';
import 'carps_firestore_codec.dart';
import 'carps_repository.dart';

/// Firestore-backed cache for the synchronous CARPS service API.
class FirebaseCarpsRepository extends CarpsRepository {
  FirebaseCarpsRepository({required this._firestore});

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

  @override
  String? get persistenceError => _persistenceError;

  @override
  void clearPersistenceError() {
    if (_persistenceError == null) return;
    _persistenceError = null;
    notifyListeners();
  }

  /// Loads public data and the signed-in user's private or event-scoped data.
  Future<void> load({required String userId, required String email}) async {
    _clearCache(notify: false);
    final registrationNotes = <String, String>{};

    try {
      await _load(
        _firestore.collection('profiles'),
        (data) =>
            _codec.decodeUser(data, email: data['id'] == userId ? email : ''),
        (value) => _users[value.id] = value,
      );
      await _load(
        _firestore
            .collection('events')
            .where('visibility', isEqualTo: EventVisibility.public.name),
        _codec.decodeEvent,
        (value) => _events[value.id] = value,
      );
      await _load(
        _firestore.collection('events').where('hostId', isEqualTo: userId),
        _codec.decodeEvent,
        (value) => _events[value.id] = value,
      );
      await _load(
        _firestore
            .collection('events')
            .where('coHostIds', arrayContains: userId),
        _codec.decodeEvent,
        (value) => _events[value.id] = value,
      );

      await _load(
        _firestore
            .collection('invitations')
            .where('inviteeId', isEqualTo: userId),
        _codec.decodeInvitation,
        (value) => _invitations[value.id] = value,
      );
      await _load(
        _firestore
            .collection('invitations')
            .where('invitedById', isEqualTo: userId),
        _codec.decodeInvitation,
        (value) => _invitations[value.id] = value,
      );
      await _load(
        _firestore
            .collection('registrations')
            .where('userId', isEqualTo: userId),
        _codec.decodeRegistration,
        (value) => _registrations[value.id] = value,
      );
      await _load(
        _firestore.collection('attendance').where('userId', isEqualTo: userId),
        _codec.decodeAttendance,
        (value) =>
            _attendance[_attendanceId(value.eventId, value.userId)] = value,
      );
      await _load(
        _firestore
            .collection('registrationNotes')
            .where('userId', isEqualTo: userId),
        (data) =>
            MapEntry(data['registrationId'] as String, data['note'] as String),
        (value) => registrationNotes[value.key] = value.value,
      );

      final accessSnapshot = await _firestore
          .collection('eventAccess')
          .where('userId', isEqualTo: userId)
          .get();
      final linkedEventIds = <String>{
        for (final document in accessSnapshot.docs)
          if (document.data()['eventId'] case final String eventId) eventId,
        ..._invitations.values.map((value) => value.eventId),
        ..._registrations.values.map((value) => value.eventId),
      };
      for (final eventId in linkedEventIds) {
        if (_events.containsKey(eventId)) continue;
        final snapshot = await _firestore
            .collection('events')
            .doc(eventId)
            .get();
        final data = snapshot.data();
        if (snapshot.exists && data != null) {
          final event = _codec.decodeEvent(data);
          _events[event.id] = event;
        }
      }

      final eventIds = _events.values.toList(growable: false);
      for (final event in eventIds) {
        final isTeam = event.isHostingTeam(userId);
        final canReadSocial =
            !event.isPrivate || isTeam || _hasAttendance(event.id, userId);

        if (isTeam) {
          await _load(
            _firestore
                .collection('invitations')
                .where('eventId', isEqualTo: event.id),
            _codec.decodeInvitation,
            (value) => _invitations[value.id] = value,
          );
        }
        if (isTeam || !event.isPrivate) {
          await _load(
            _firestore
                .collection('registrations')
                .where('eventId', isEqualTo: event.id),
            _codec.decodeRegistration,
            (value) => _registrations[value.id] = value,
          );
        }
        if (isTeam) {
          await _load(
            _firestore
                .collection('registrationNotes')
                .where('eventId', isEqualTo: event.id),
            (data) => MapEntry(
              data['registrationId'] as String,
              data['note'] as String,
            ),
            (value) => registrationNotes[value.key] = value.value,
          );
        }
        if (isTeam) {
          await _load(
            _firestore
                .collection('passes')
                .where('eventId', isEqualTo: event.id),
            _codec.decodePass,
            (value) => _passes[value.id] = value,
          );
        }
        if (isTeam || !event.isPrivate) {
          await _load(
            _firestore
                .collection('attendance')
                .where('eventId', isEqualTo: event.id),
            _codec.decodeAttendance,
            (value) =>
                _attendance[_attendanceId(value.eventId, value.userId)] = value,
          );
        }
        if (canReadSocial) {
          await _load(
            _firestore
                .collection('posts')
                .where('eventId', isEqualTo: event.id),
            _codec.decodePost,
            (value) => _posts[value.id] = value,
          );
          await _load(
            _firestore
                .collection('reviews')
                .where('eventId', isEqualTo: event.id),
            _codec.decodeReview,
            (value) => _reviews[value.id] = value,
          );
        }
      }

      await _load(
        _firestore.collection('passes').where('userId', isEqualTo: userId),
        _codec.decodePass,
        (value) => _passes[value.id] = value,
      );
      await _load(
        _firestore
            .collection('notifications')
            .where('userId', isEqualTo: userId),
        _codec.decodeNotification,
        (value) => _notifications[value.id] = value,
      );
      await _load(
        _firestore.collection('cases').where('reporterId', isEqualTo: userId),
        _codec.decodeCase,
        (value) => _cases[value.id] = value,
      );
      if (_users[userId]?.isAdmin ?? false) {
        await _load(
          _firestore
              .collection('cases')
              .where('assignedAdminId', isEqualTo: userId),
          _codec.decodeCase,
          (value) => _cases[value.id] = value,
        );
      }
      for (final registration in _registrations.values.toList()) {
        final note = registrationNotes[registration.id];
        if (note != null) {
          _registrations[registration.id] = registration.copyWith(note: note);
        }
      }
      clearPersistenceError();
      notifyListeners();
    } on FirebaseException catch (error) {
      _recordPersistenceError(error.message ?? error.code);
      rethrow;
    }
  }

  Future<void> _load<T>(
    Query<Map<String, dynamic>> query,
    T Function(Map<String, dynamic>) decode,
    void Function(T) cache,
  ) async {
    final snapshot = await query.get();
    for (final document in snapshot.docs) {
      cache(decode(document.data()));
    }
  }

  @override
  void clear() {
    _clearCache(notify: true);
  }

  void _clearCache({required bool notify}) {
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
    _persistenceError = null;
    if (notify) notifyListeners();
  }

  bool _hasAttendance(String eventId, String userId) => _attendance.values.any(
    (record) => record.eventId == eventId && record.userId == userId,
  );

  @override
  String nextId(String prefix) =>
      '${prefix}_${_firestore.collection('_ids').doc().id}';

  @override
  List<UserProfile> get users => List.unmodifiable(_users.values);
  @override
  UserProfile? user(String id) => _users[id];
  @override
  void saveUser(UserProfile value) {
    final previous = _users[value.id];
    _users[value.id] = value;
    notifyListeners();
    _enqueue(() async {
      final batch = _firestore.batch();
      batch.set(
        _firestore.collection('profiles').doc(value.id),
        _codec.encodeUser(value),
      );
      if (previous != null && previous.username != value.username) {
        batch.delete(_firestore.collection('usernames').doc(previous.username));
      }
      batch.set(_firestore.collection('usernames').doc(value.username), {
        'userId': value.id,
      });
      await batch.commit();
    });
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
    _enqueue(() async {
      final batch = _firestore.batch();
      batch.set(
        _firestore.collection('invitations').doc(value.id),
        _codec.encodeInvitation(value),
      );
      batch.set(
        _firestore
            .collection('eventAccess')
            .doc(_eventAccessId(value.eventId, value.inviteeId)),
        {
          'eventId': value.eventId,
          'userId': value.inviteeId,
          'invitationId': value.id,
        },
        SetOptions(merge: true),
      );
      await batch.commit();
    });
  }

  @override
  List<Registration> get registrations =>
      List.unmodifiable(_registrations.values);
  @override
  void saveRegistration(Registration value) {
    _registrations[value.id] = value;
    notifyListeners();
    _enqueue(() async {
      final batch = _firestore.batch();
      batch.set(
        _firestore.collection('registrations').doc(value.id),
        _codec.encodeRegistration(value),
      );
      batch.set(
        _firestore.collection('registrationNotes').doc(value.id),
        _registrationNoteData(value),
      );
      batch.set(
        _firestore
            .collection('eventAccess')
            .doc(_eventAccessId(value.eventId, value.userId)),
        {
          'eventId': value.eventId,
          'userId': value.userId,
          'registrationId': value.id,
        },
        SetOptions(merge: true),
      );
      await batch.commit();
    });
  }

  @override
  void saveApprovedRegistration(Registration registration, GuestPass pass) {
    _registrations[registration.id] = registration;
    _passes[pass.id] = pass;
    notifyListeners();
    _enqueue(() async {
      final batch = _firestore.batch();
      batch.set(
        _firestore.collection('passes').doc(pass.id),
        _codec.encodePass(pass),
      );
      batch.set(
        _firestore.collection('registrations').doc(registration.id),
        _codec.encodeRegistration(registration),
      );
      batch.set(
        _firestore.collection('registrationNotes').doc(registration.id),
        _registrationNoteData(registration),
      );
      batch.set(
        _firestore
            .collection('eventAccess')
            .doc(_eventAccessId(registration.eventId, registration.userId)),
        {
          'eventId': registration.eventId,
          'userId': registration.userId,
          'registrationId': registration.id,
        },
        SetOptions(merge: true),
      );
      await batch.commit();
    });
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
    SupportCase supportCase,
    Attendance? record,
  ) {
    if (record != null) {
      _attendance[_attendanceId(record.eventId, record.userId)] = record;
    }
    _cases[supportCase.id] = supportCase;
    notifyListeners();
    _enqueue(() async {
      final batch = _firestore.batch();
      batch.set(
        _firestore.collection('cases').doc(supportCase.id),
        _codec.encodeCase(supportCase),
      );
      if (record != null) {
        batch.set(
          _firestore
              .collection('attendance')
              .doc(_attendanceId(record.eventId, record.userId)),
          _codec.encodeAttendance(record),
        );
      }
      await batch.commit();
    });
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
    _enqueue(() async {
      await _firestore.collection('posts').doc(id).delete();
    });
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
    _enqueue(() async {
      await _firestore.collection(collection).doc(id).set(data);
    });
  }

  void _enqueue(Future<void> Function() write) {
    _writeTail = _writeTail.then((_) async {
      try {
        await write();
        clearPersistenceError();
      } on FirebaseException catch (error) {
        _recordPersistenceError(error.message ?? error.code);
      }
    });
  }

  Future<void> flushPendingWrites() async {
    await _writeTail;
    if (_persistenceError case final error?) {
      throw StateError('Firestore write failed: $error');
    }
  }

  void _recordPersistenceError(String message) {
    _persistenceError = message;
    notifyListeners();
  }

  static String _attendanceId(String eventId, String userId) =>
      '${eventId}_$userId';

  static String _eventAccessId(String eventId, String userId) =>
      '${eventId}_$userId';

  static Map<String, Object?> _registrationNoteData(Registration value) => {
    'registrationId': value.id,
    'eventId': value.eventId,
    'userId': value.userId,
    'note': value.note,
  };
}
