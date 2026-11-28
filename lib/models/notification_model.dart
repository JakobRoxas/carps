import 'carps_enums.dart';

class AppNotification {
  const AppNotification({
    required this.id,
    required this.userId,
    required this.kind,
    required this.title,
    required this.body,
    required this.createdAt,
    this.eventId,
    this.postId,
    this.caseId,
    this.read = false,
    this.emailSimulated = false,
  });

  final String id;
  final String userId;
  final NotificationKind kind;
  final String title;
  final String body;
  final DateTime createdAt;
  final String? eventId;
  final String? postId;
  final String? caseId;
  final bool read;

  /// True when an opted-in email copy WOULD have been sent. Nothing is sent.
  final bool emailSimulated;

  AppNotification markRead() => AppNotification(
    id: id,
    userId: userId,
    kind: kind,
    title: title,
    body: body,
    createdAt: createdAt,
    eventId: eventId,
    postId: postId,
    caseId: caseId,
    read: true,
    emailSimulated: emailSimulated,
  );
}
