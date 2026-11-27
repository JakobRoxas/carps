import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/carps_models.dart';

class CarpsFirestoreCodec {
  const CarpsFirestoreCodec();

  Map<String, Object?> encodeUser(UserProfile value) => {
    'id': value.id,
    'displayName': value.displayName,
    'username': value.username,
    'avatarAsset': value.avatarAsset,
    'bio': value.bio,
    'area': value.area,
    'interests': value.interests,
    'followingIds': value.followingIds,
    'hostingEnabled': value.hostingEnabled,
    'builderName': value.builderName,
    'builderAbout': value.builderAbout,
    'isAdmin': value.isAdmin,
    'termsAccepted': value.termsAccepted,
    'primaryRole': value.primaryRole?.name,
    'profileComplete': value.profileComplete,
    'discoveryDone': value.discoveryDone,
    'contactDiscoveryOptIn': value.contactDiscoveryOptIn,
  };

  UserProfile decodeUser(Map<String, dynamic> data, {String email = ''}) =>
      UserProfile(
        id: _string(data, 'id'),
        displayName: _string(data, 'displayName'),
        username: _string(data, 'username'),
        email: email,
        avatarAsset: _nullableString(data, 'avatarAsset'),
        bio: _string(data, 'bio'),
        area: _nullableString(data, 'area'),
        interests: _strings(data, 'interests'),
        followingIds: _strings(data, 'followingIds'),
        hostingEnabled: _bool(data, 'hostingEnabled'),
        builderName: _nullableString(data, 'builderName'),
        builderAbout: _nullableString(data, 'builderAbout'),
        isAdmin: _bool(data, 'isAdmin'),
        termsAccepted: _bool(data, 'termsAccepted'),
        primaryRole: _enumOrNull(PrimaryRole.values, data['primaryRole']),
        profileComplete: _bool(data, 'profileComplete'),
        discoveryDone: _bool(data, 'discoveryDone'),
        contactDiscoveryOptIn: _bool(data, 'contactDiscoveryOptIn'),
      );

  Map<String, Object?> encodeEvent(CarpsEvent value) => {
    'id': value.id,
    'hostId': value.hostId,
    'coHostIds': value.coHostIds,
    'title': value.title,
    'description': value.description,
    'topic': value.topic,
    'venue': value.venue,
    'area': value.area,
    'start': Timestamp.fromDate(value.start),
    'end': Timestamp.fromDate(value.end),
    'visibility': value.visibility.name,
    'coverAsset': value.coverAsset,
    'capacity': value.capacity,
    'featuredOnProfile': value.featuredOnProfile,
    'status': value.status.name,
    'notices': value.notices.map(encodeNotice).toList(),
    'seriesLabel': value.seriesLabel,
  };

  CarpsEvent decodeEvent(Map<String, dynamic> data) => CarpsEvent(
    id: _string(data, 'id'),
    hostId: _string(data, 'hostId'),
    coHostIds: _strings(data, 'coHostIds'),
    title: _string(data, 'title'),
    description: _string(data, 'description'),
    topic: _string(data, 'topic'),
    venue: _string(data, 'venue'),
    area: _string(data, 'area'),
    start: _date(data['start']),
    end: _date(data['end']),
    visibility: _enum(EventVisibility.values, data['visibility']),
    coverAsset: _nullableString(data, 'coverAsset'),
    capacity: _nullableInt(data, 'capacity'),
    featuredOnProfile: _bool(data, 'featuredOnProfile'),
    status: _enum(EventStatus.values, data['status']),
    notices: _maps(data, 'notices').map(decodeNotice).toList(),
    seriesLabel: _nullableString(data, 'seriesLabel'),
  );

  Map<String, Object?> encodeInvitation(Invitation value) => {
    'id': value.id,
    'eventId': value.eventId,
    'inviteeId': value.inviteeId,
    'invitedById': value.invitedById,
    'kind': value.kind.name,
    'status': value.status.name,
    'createdAt': Timestamp.fromDate(value.createdAt),
  };

  Invitation decodeInvitation(Map<String, dynamic> data) => Invitation(
    id: _string(data, 'id'),
    eventId: _string(data, 'eventId'),
    inviteeId: _string(data, 'inviteeId'),
    invitedById: _string(data, 'invitedById'),
    kind: _enum(InvitationKind.values, data['kind']),
    status: _enum(InvitationStatus.values, data['status']),
    createdAt: _date(data['createdAt']),
  );

  Map<String, Object?> encodeRegistration(Registration value) => {
    'id': value.id,
    'eventId': value.eventId,
    'userId': value.userId,
    'status': value.status.name,
    'requestedAt': Timestamp.fromDate(value.requestedAt),
    'decidedAt': value.decidedAt == null
        ? null
        : Timestamp.fromDate(value.decidedAt!),
    'passId': value.passId,
  };

  Registration decodeRegistration(Map<String, dynamic> data) => Registration(
    id: _string(data, 'id'),
    eventId: _string(data, 'eventId'),
    userId: _string(data, 'userId'),
    status: _enum(RegistrationStatus.values, data['status']),
    requestedAt: _date(data['requestedAt']),
    note: data['note'] is String ? data['note'] as String : '',
    decidedAt: _nullableDate(data['decidedAt']),
    passId: _nullableString(data, 'passId'),
  );

  Map<String, Object?> encodePass(GuestPass value) => {
    'id': value.id,
    'token': value.token,
    'eventId': value.eventId,
    'userId': value.userId,
    'registrationId': value.registrationId,
    'issuedAt': Timestamp.fromDate(value.issuedAt),
    'revoked': value.revoked,
  };

  GuestPass decodePass(Map<String, dynamic> data) => GuestPass(
    id: _string(data, 'id'),
    token: _string(data, 'token'),
    eventId: _string(data, 'eventId'),
    userId: _string(data, 'userId'),
    registrationId: _string(data, 'registrationId'),
    issuedAt: _date(data['issuedAt']),
    revoked: _bool(data, 'revoked'),
  );

  Map<String, Object?> encodeAttendance(Attendance value) => {
    'eventId': value.eventId,
    'userId': value.userId,
    'arrivedAt': Timestamp.fromDate(value.arrivedAt),
    'scannedById': value.scannedById,
    'passId': value.passId,
  };

  Attendance decodeAttendance(Map<String, dynamic> data) => Attendance(
    eventId: _string(data, 'eventId'),
    userId: _string(data, 'userId'),
    arrivedAt: _date(data['arrivedAt']),
    scannedById: _string(data, 'scannedById'),
    passId: _nullableString(data, 'passId'),
  );

  Map<String, Object?> encodePost(ExperiencePost value) => {
    'id': value.id,
    'eventId': value.eventId,
    'authorId': value.authorId,
    'body': value.body,
    'photoAsset': value.photoAsset,
    'taggedIds': value.taggedIds,
    'likedByIds': value.likedByIds,
    'comments': value.comments.map(encodeComment).toList(),
    'createdAt': Timestamp.fromDate(value.createdAt),
  };

  ExperiencePost decodePost(Map<String, dynamic> data) => ExperiencePost(
    id: _string(data, 'id'),
    eventId: _string(data, 'eventId'),
    authorId: _string(data, 'authorId'),
    body: _string(data, 'body'),
    photoAsset: _nullableString(data, 'photoAsset'),
    taggedIds: _strings(data, 'taggedIds'),
    likedByIds: _strings(data, 'likedByIds'),
    comments: _maps(data, 'comments').map(decodeComment).toList(),
    createdAt: _date(data['createdAt']),
  );

  Map<String, Object?> encodeReview(EventReview value) => {
    'id': value.id,
    'eventId': value.eventId,
    'authorId': value.authorId,
    'rating': value.rating,
    'text': value.text,
    'createdAt': Timestamp.fromDate(value.createdAt),
  };

  EventReview decodeReview(Map<String, dynamic> data) => EventReview(
    id: _string(data, 'id'),
    eventId: _string(data, 'eventId'),
    authorId: _string(data, 'authorId'),
    rating: _int(data, 'rating'),
    text: _string(data, 'text'),
    createdAt: _date(data['createdAt']),
  );

  Map<String, Object?> encodeNotification(AppNotification value) => {
    'id': value.id,
    'userId': value.userId,
    'kind': value.kind.name,
    'title': value.title,
    'body': value.body,
    'createdAt': Timestamp.fromDate(value.createdAt),
    'eventId': value.eventId,
    'postId': value.postId,
    'caseId': value.caseId,
    'read': value.read,
    'emailSimulated': value.emailSimulated,
  };

  AppNotification decodeNotification(Map<String, dynamic> data) =>
      AppNotification(
        id: _string(data, 'id'),
        userId: _string(data, 'userId'),
        kind: _enum(NotificationKind.values, data['kind']),
        title: _string(data, 'title'),
        body: _string(data, 'body'),
        createdAt: _date(data['createdAt']),
        eventId: _nullableString(data, 'eventId'),
        postId: _nullableString(data, 'postId'),
        caseId: _nullableString(data, 'caseId'),
        read: _bool(data, 'read'),
        emailSimulated: _bool(data, 'emailSimulated'),
      );

  Map<String, Object?> encodeCase(SupportCase value) => {
    'id': value.id,
    'reporterId': value.reporterId,
    'category': value.category,
    'details': value.details,
    'link': value.link,
    'createdAt': Timestamp.fromDate(value.createdAt),
    'assignedAdminId': value.assignedAdminId,
    'status': value.status.name,
    'outcome': value.outcome?.name,
    'decisionNote': value.decisionNote,
    'closedAt': value.closedAt == null
        ? null
        : Timestamp.fromDate(value.closedAt!),
    'hostConfirmed': value.hostConfirmed,
  };

  SupportCase decodeCase(Map<String, dynamic> data) => SupportCase(
    id: _string(data, 'id'),
    reporterId: _string(data, 'reporterId'),
    category: _string(data, 'category'),
    details: _string(data, 'details'),
    link: _nullableString(data, 'link'),
    createdAt: _date(data['createdAt']),
    assignedAdminId: _string(data, 'assignedAdminId'),
    status: _enum(CaseStatus.values, data['status']),
    outcome: _enumOrNull(CaseOutcome.values, data['outcome']),
    decisionNote: _nullableString(data, 'decisionNote'),
    closedAt: _nullableDate(data['closedAt']),
    hostConfirmed: _bool(data, 'hostConfirmed'),
  );

  Map<String, Object?> encodeNotice(EventNotice value) => {
    'id': value.id,
    'text': value.text,
    'createdAt': Timestamp.fromDate(value.createdAt),
    'isVenueChange': value.isVenueChange,
  };

  EventNotice decodeNotice(Map<String, dynamic> data) => EventNotice(
    id: _string(data, 'id'),
    text: _string(data, 'text'),
    createdAt: _date(data['createdAt']),
    isVenueChange: _bool(data, 'isVenueChange'),
  );

  Map<String, Object?> encodeComment(PostComment value) => {
    'id': value.id,
    'authorId': value.authorId,
    'body': value.body,
    'createdAt': Timestamp.fromDate(value.createdAt),
    'parentId': value.parentId,
  };

  PostComment decodeComment(Map<String, dynamic> data) => PostComment(
    id: _string(data, 'id'),
    authorId: _string(data, 'authorId'),
    body: _string(data, 'body'),
    createdAt: _date(data['createdAt']),
    parentId: _nullableString(data, 'parentId'),
  );

  static String _string(Map<String, dynamic> data, String key) {
    final value = data[key];
    if (value is String) return value;
    throw FormatException('Expected "$key" to be a string.');
  }

  static String? _nullableString(Map<String, dynamic> data, String key) {
    final value = data[key];
    if (value == null || value is String) return value as String?;
    throw FormatException('Expected "$key" to be a string or null.');
  }

  static bool _bool(Map<String, dynamic> data, String key) {
    final value = data[key];
    if (value is bool) return value;
    throw FormatException('Expected "$key" to be a boolean.');
  }

  static int _int(Map<String, dynamic> data, String key) {
    final value = data[key];
    if (value is int) return value;
    throw FormatException('Expected "$key" to be an integer.');
  }

  static int? _nullableInt(Map<String, dynamic> data, String key) {
    final value = data[key];
    if (value == null || value is int) return value as int?;
    throw FormatException('Expected "$key" to be an integer or null.');
  }

  static List<String> _strings(Map<String, dynamic> data, String key) {
    final value = data[key];
    if (value == null) return const [];
    if (value is List && value.every((item) => item is String)) {
      return List<String>.from(value);
    }
    throw FormatException('Expected "$key" to be a list of strings.');
  }

  static List<Map<String, dynamic>> _maps(
    Map<String, dynamic> data,
    String key,
  ) {
    final value = data[key];
    if (value == null) return const [];
    if (value is List && value.every((item) => item is Map<String, dynamic>)) {
      return List<Map<String, dynamic>>.from(value);
    }
    throw FormatException('Expected "$key" to be a list of objects.');
  }

  static DateTime _date(Object? value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.parse(value);
    throw const FormatException('Expected a valid date/time value.');
  }

  static DateTime? _nullableDate(Object? value) =>
      value == null ? null : _date(value);

  static T _enum<T extends Enum>(List<T> values, Object? value) {
    for (final item in values) {
      if (item.name == value) return item;
    }
    throw FormatException('Unknown ${T.toString()} value: $value');
  }

  static T? _enumOrNull<T extends Enum>(List<T> values, Object? value) =>
      value == null ? null : _enum(values, value);
}
