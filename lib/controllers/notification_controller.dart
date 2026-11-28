import '../models/carps_models.dart';
import '../services/notification_service.dart';

/// Controller for notification inbox state and read actions.
class NotificationController {
  NotificationController(this._service);

  final NotificationService _service;

  DateTime get now => _service.now;
  List<AppNotification> notificationsFor(String userId) =>
      _service.notificationsFor(userId);
  int unreadCount(String userId) => _service.unreadCount(userId);
  void markAllRead(String userId) => _service.markAllRead(userId);
}
