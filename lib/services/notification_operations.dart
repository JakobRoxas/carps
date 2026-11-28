part of 'carps_domain_operations.dart';

mixin NotificationOperations on CarpsServiceBase {

  void _notify(String userId, NotificationKind kind, String title, String body,
      {String? eventId,
      String? postId,
      String? caseId,
      bool emailSimulated = false}) {
    repo.saveNotification(AppNotification(
      id: repo.nextId('ntf'),
      userId: userId,
      kind: kind,
      title: title,
      body: body,
      createdAt: now,
      eventId: eventId,
      postId: postId,
      caseId: caseId,
      emailSimulated: emailSimulated,
    ));
  }

  List<AppNotification> notificationsFor(String userId) =>
      repo.notifications.where((n) => n.userId == userId).toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

  int unreadCount(String userId) =>
      notificationsFor(userId).where((n) => !n.read).length;

  void markAllRead(String userId) {
    for (final n in notificationsFor(userId).where((n) => !n.read)) {
      repo.saveNotification(n.markRead());
    }
  }
}
