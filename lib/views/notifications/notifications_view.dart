import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/carps_icons.dart';

import '../../controllers/app_controller.dart';
import '../../core/format.dart';
import '../../core/theme/carps_colors.dart';
import '../../core/widgets/carps_widgets.dart';
import '../../models/carps_models.dart';

/// Notifications (derived; no Figma frame 24). In-app only; any email copy
/// is marked as simulated.
class NotificationsView extends StatefulWidget {
  const NotificationsView({super.key});
  @override
  State<NotificationsView> createState() => _NotificationsViewState();
}

class _NotificationsViewState extends State<NotificationsView> {
  late final Set<String> _unreadOnOpen;

  @override
  void initState() {
    super.initState();
    final app = context.appRead;
    _unreadOnOpen = app.notifications
        .notificationsFor(app.me!.id)
        .where((n) => !n.read)
        .map((n) => n.id)
        .toSet();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) app.notifications.markAllRead(app.me!.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    final app = context.app;
    final list = app.notifications.notificationsFor(app.me!.id);
    final c = context.carps;
    return CarpsPage(
      title: 'Notifications',
      children: [
        if (list.isEmpty)
          const EmptyState(
              title: 'All quiet',
              message: 'Approvals, invitations, reminders and tags show up here.'),
        for (final n in list)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: SurfaceCard(
              color: _unreadOnOpen.contains(n.id) ? c.accentTint : null,
              onTap: () => _open(context, n),
              padding: const EdgeInsets.all(14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    backgroundColor: c.muted,
                    child: Icon(_icon(n.kind), color: c.textPrimary, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(n.title, style: Theme.of(context).textTheme.titleSmall),
                        const SizedBox(height: 2),
                        Text(n.body, style: const TextStyle(fontSize: 13)),
                        const SizedBox(height: 4),
                        Row(children: [
                          Text(relative(n.createdAt, app.notifications.now),
                              style: Theme.of(context).textTheme.bodySmall),
                          if (n.emailSimulated) ...[
                            const SizedBox(width: 8),
                            const SimulatedTag(text: 'Email simulated'),
                          ],
                        ]),
                      ],
                    ),
                  ),
                  if (_unreadOnOpen.contains(n.id))
                    Container(
                      width: 8,
                      height: 8,
                      margin: const EdgeInsets.only(top: 6),
                      decoration: BoxDecoration(
                          color: c.accentFill, shape: BoxShape.circle),
                    ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  IconData _icon(NotificationKind k) => switch (k) {
        NotificationKind.joinRequest => CarpsIcons.userPlus,
        NotificationKind.approved => CarpsIcons.ticket,
        NotificationKind.declined => CarpsIcons.xCircle,
        NotificationKind.guestInvite => CarpsIcons.envelopeSimple,
        NotificationKind.coHostInvite => CarpsIcons.crown,
        NotificationKind.coHostAccepted => CarpsIcons.handshake,
        NotificationKind.notice => CarpsIcons.megaphone,
        NotificationKind.reminder => CarpsIcons.bellRinging,
        NotificationKind.checkedIn => CarpsIcons.sealCheck,
        NotificationKind.tagged => CarpsIcons.tag,
        NotificationKind.comment => CarpsIcons.chatCircle,
        NotificationKind.cancelled => CarpsIcons.prohibit,
        NotificationKind.supportUpdate => CarpsIcons.lifebuoy,
        NotificationKind.supportAssigned => CarpsIcons.shieldStar,
      };

  void _open(BuildContext context, AppNotification n) {
    final e = n.eventId;
    switch (n.kind) {
      case NotificationKind.approved:
        context.push('/pass/$e');
      case NotificationKind.joinRequest:
        context.push('/event/$e/roster');
      case NotificationKind.tagged:
      case NotificationKind.comment:
        context.push('/post/${n.postId}');
      case NotificationKind.supportAssigned:
        context.push('/admin');
      case NotificationKind.supportUpdate:
        context.go('/settings');
      case NotificationKind.coHostInvite:
        context.go('/home');
      default:
        if (e != null) context.push('/event/$e');
    }
  }
}
