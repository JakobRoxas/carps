import 'carps_enums.dart';

class Invitation {
  const Invitation({
    required this.id,
    required this.eventId,
    required this.inviteeId,
    required this.invitedById,
    required this.kind,
    required this.createdAt,
    this.status = InvitationStatus.sent,
  });

  final String id;
  final String eventId;
  final String inviteeId;
  final String invitedById;
  final InvitationKind kind;
  final InvitationStatus status;
  final DateTime createdAt;

  Invitation copyWith({InvitationStatus? status}) => Invitation(
    id: id,
    eventId: eventId,
    inviteeId: inviteeId,
    invitedById: invitedById,
    kind: kind,
    createdAt: createdAt,
    status: status ?? this.status,
  );
}

class Registration {
  const Registration({
    required this.id,
    required this.eventId,
    required this.userId,
    required this.status,
    required this.requestedAt,
    this.note = '',
    this.decidedAt,
    this.passId,
  });

  final String id;
  final String eventId;
  final String userId;
  final RegistrationStatus status;
  final DateTime requestedAt;
  final String note;
  final DateTime? decidedAt;

  /// Only set once a hosting-team member approves the request.
  final String? passId;

  bool get isActive =>
      status == RegistrationStatus.pending ||
      status == RegistrationStatus.approved;

  Registration copyWith({
    RegistrationStatus? status,
    String? note,
    DateTime? decidedAt,
    String? passId,
  }) => Registration(
    id: id,
    eventId: eventId,
    userId: userId,
    status: status ?? this.status,
    requestedAt: requestedAt,
    note: note ?? this.note,
    decidedAt: decidedAt ?? this.decidedAt,
    passId: passId ?? this.passId,
  );
}

/// A unique QR pass for one guest at one event.
class GuestPass {
  const GuestPass({
    required this.id,
    required this.token,
    required this.eventId,
    required this.userId,
    required this.registrationId,
    required this.issuedAt,
    this.revoked = false,
  });

  final String id;

  /// What the QR code encodes. Unique per guest and event.
  final String token;
  final String eventId;
  final String userId;
  final String registrationId;
  final DateTime issuedAt;
  final bool revoked;

  GuestPass revoke() => GuestPass(
    id: id,
    token: token,
    eventId: eventId,
    userId: userId,
    registrationId: registrationId,
    issuedAt: issuedAt,
    revoked: true,
  );
}

/// Proof of presence, created only by a valid first scan.
class Attendance {
  const Attendance({
    required this.eventId,
    required this.userId,
    required this.arrivedAt,
    required this.scannedById,
    this.passId,
  });

  final String eventId;
  final String userId;
  final DateTime arrivedAt;
  final String scannedById;
  final String? passId;
}
