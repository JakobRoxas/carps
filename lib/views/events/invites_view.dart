import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/carps_icons.dart';

import '../../controllers/app_controller.dart';
import '../../core/format.dart';
import '../../core/theme/carps_colors.dart';
import '../../core/widgets/carps_widgets.dart';
import '../../models/carps_models.dart';

/// Figma 14 · Invites & Event Notices, plus the pre-event shoutout composer.
class InvitesView extends StatefulWidget {
  const InvitesView({super.key, required this.eventId});
  final String eventId;
  @override
  State<InvitesView> createState() => _InvitesViewState();
}

class _InvitesViewState extends State<InvitesView> {
  int _tab = 0; // 0 invite guests · 1 notice · 2 reminder
  String _query = '';
  final _notice = TextEditingController();
  final _reminder = TextEditingController(
    text: 'See you soon! Bring non-marking shoes and your QR pass.',
  );
  bool _venueChange = false;
  bool _email = true;

  @override
  void dispose() {
    _notice.dispose();
    _reminder.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final app = context.app;
    final svc = app.events;
    final me = app.me!;
    final c = context.carps;
    final event = app.data.eventById(widget.eventId);
    if (event == null || !event.isHostingTeam(me.id)) {
      return const CarpsPage(
        title: 'Invites & notices',
        children: [
          EmptyState(
            title: 'Hosting team only',
            message: 'Only the builder and accepted co-hosts can manage this.',
          ),
        ],
      );
    }
    final approved = svc
        .registrationsForEvent(event.id)
        .where((r) => r.status == RegistrationStatus.approved)
        .toList();
    final active = svc
        .registrationsForEvent(event.id)
        .where((r) => r.isActive)
        .length;
    final candidates = app.profiles
        .searchPeople(_query, excludeId: me.id)
        .where((u) => !event.isHostingTeam(u.id) && !u.isAdmin)
        .toList();

    return CarpsPage(
      title: 'Invites & notices',
      children: [
        SurfaceCard(
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Event context',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    Text(
                      event.title,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    Text(
                      dateTime(event.start),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              TintPill('${approved.length} going', icon: CarpsIcons.users),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SegmentedTabs(
          labels: const ['Invite guests', 'Notice', 'Reminder'],
          selected: _tab,
          onChanged: (i) => setState(() => _tab = i),
        ),
        const SizedBox(height: 16),
        if (_tab == 0) ...[
          Text(
            event.isPrivate
                ? 'Private guest invitations let people see this listing and request to join. They never grant hosting privileges, even for builders.'
                : 'This event is public. Invitations are a nudge; guests still request to join.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 12),
          TextField(
            onChanged: (v) => setState(() => _query = v),
            decoration: const InputDecoration(
              hintText: 'Search followers or @username to invite…',
              prefixIcon: Icon(CarpsIcons.magnifyingGlass, size: 20),
            ),
          ),
          const SizedBox(height: 12),
          SurfaceCard(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: Column(
              children: [
                for (final u in candidates)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CarpsAvatar(user: u, size: 40),
                    title: Text(u.displayName),
                    subtitle: Text(
                      u.hostingEnabled ? '${u.handle} · Builder' : u.handle,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    onTap: () => context.push('/user/${u.id}'),
                    trailing: svc.guestInvitation(event.id, u.id) != null
                        ? const StatusChip(StatusKind.invited)
                        : CarpsButton(
                            label: 'Invite',
                            kind: CarpsButtonKind.inverse,
                            height: 36,
                            expand: false,
                            onPressed: () => runAction(
                              context,
                              () => svc.inviteGuest(me.id, event.id, u.id),
                              success:
                                  '${u.displayName} invited as a guest. They can request to join.',
                            ),
                          ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SurfaceCard(
            color: c.muted,
            child: Row(
              children: [
                const Icon(CarpsIcons.link),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const CaptionLabel('Shareable link'),
                      Text(
                        'carps.ph/event/${event.id}',
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      if (event.isPrivate)
                        Text(
                          'Only opens for invited accounts.',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                    ],
                  ),
                ),
                CarpsButton(
                  label: 'Copy',
                  icon: CarpsIcons.copy,
                  kind: CarpsButtonKind.secondary,
                  height: 36,
                  expand: false,
                  onPressed: () =>
                      showCarpsSnack(context, 'Link copied (simulated)'),
                ),
              ],
            ),
          ),
        ] else if (_tab == 1) ...[
          Text(
            'Notices update the listing and notify everyone with an active request. They are event management, not social posts.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _notice,
            maxLines: 3,
            decoration: const InputDecoration(
              hintText: 'Court 3 & 4 confirmed! Bring non-marking shoes.',
            ),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('This is a venue change'),
            subtitle: const Text(
              'Use Edit event to change the venue itself. That posts a notice automatically.',
            ),
            value: _venueChange,
            onChanged: (v) => setState(() => _venueChange = v),
          ),
          const SizedBox(height: 8),
          CarpsButton(
            label: 'Post notice to $active ${active == 1 ? 'guest' : 'guests'}',
            icon: CarpsIcons.paperPlaneTilt,
            onPressed: () {
              if (runAction(
                context,
                () => svc.postNotice(
                  me.id,
                  event.id,
                  _notice.text,
                  isVenueChange: _venueChange,
                ),
                success: 'Notice added to the listing',
              )) {
                _notice.clear();
              }
            },
          ),
          if (event.notices.isNotEmpty) ...[
            const SizedBox(height: 20),
            Text(
              'Posted notices',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            for (final n in event.notices)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(
                  n.isVenueChange ? CarpsIcons.mapPin : CarpsIcons.megaphone,
                ),
                title: Text(n.text),
                subtitle: Text(relative(n.createdAt, svc.now)),
              ),
          ],
        ] else ...[
          Row(
            children: [
              CircleAvatar(
                backgroundColor: c.accentTint,
                child: Icon(CarpsIcons.megaphone, color: c.accentFill),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Shoutout to approved guests (${approved.length})',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text('Recipients:', style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 6),
          if (approved.isEmpty)
            Text(
              'No approved guests yet.',
              style: Theme.of(context).textTheme.bodySmall,
            )
          else
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final r in approved)
                  Chip(
                    avatar: CarpsAvatar(
                      user: app.data.userById(r.userId),
                      size: 22,
                    ),
                    label: Text(app.data.userById(r.userId)?.displayName ?? ''),
                    visualDensity: VisualDensity.compact,
                  ),
              ],
            ),
          const SizedBox(height: 12),
          TextField(controller: _reminder, maxLines: 3),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Row(
              children: const [
                Text('Also email opted-in guests'),
                SizedBox(width: 8),
                SimulatedTag(text: 'Simulated'),
              ],
            ),
            subtitle: const Text('No real email is sent in this build.'),
            value: _email,
            onChanged: (v) => setState(() => _email = v),
          ),
          const SizedBox(height: 8),
          CarpsButton(
            label: 'Send reminder',
            icon: CarpsIcons.bellRinging,
            onPressed: approved.isEmpty
                ? null
                : () => runAction(context, () {
                    final n = svc.sendReminder(
                      me.id,
                      event.id,
                      _reminder.text,
                      alsoEmail: _email,
                    );
                    showCarpsSnack(
                      context,
                      'In-app reminder sent to $n ${n == 1 ? 'guest' : 'guests'}${_email ? ' (email simulated)' : ''}',
                    );
                  }),
          ),
        ],
      ],
    );
  }
}
