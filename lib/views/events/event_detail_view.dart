import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/carps_icons.dart';

import '../../controllers/app_controller.dart';
import '../../core/format.dart';
import '../../core/theme/carps_colors.dart';
import '../../core/widgets/carps_widgets.dart';
import '../../core/widgets/event_widgets.dart';
import '../../core/widgets/post_card.dart';
import '../../models/carps_models.dart';
import '../../services/carps_service.dart';

/// Figma 08 · Event Details. One status-driven screen for every viewer:
/// signed out, outsider, invited, pending, approved, declined, withdrawn,
/// checked in, no-show, cancelled, ended, hosting team, access denied.
class EventDetailView extends StatefulWidget {
  const EventDetailView({super.key, required this.eventId});
  final String eventId;
  @override
  State<EventDetailView> createState() => _EventDetailViewState();
}

class _EventDetailViewState extends State<EventDetailView> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final app = context.app;
    final svc = app.service;
    final me = app.me;
    final event = svc.repo.event(widget.eventId);

    if (event == null) {
      return CarpsPage(title: 'Event', children: [
        EmptyState(
            title: 'Event not found',
            message: 'This link may be wrong or the event was removed.',
            actionLabel: 'Go home',
            onAction: () => context.go('/home')),
      ]);
    }
    if (!svc.canViewEvent(me?.id, event)) {
      // Access denied: no name, host or counts leak to unauthorized viewers.
      return CarpsPage(title: 'Private event', children: [
        const SizedBox(height: 32),
        Icon(CarpsIcons.lockSimple,
            size: 56, color: context.carps.textSecondary),
        const SizedBox(height: 16),
        Text('This event is private',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        Text(
            me == null
                ? 'Log in with the account that received the invitation.'
                : 'Only invited members can see private listings. Following a builder doesn\'t grant access.',
            textAlign: TextAlign.center,
            style: TextStyle(color: context.carps.textSecondary)),
        const SizedBox(height: 24),
        if (me == null)
          CarpsButton(label: 'Log in', onPressed: () => context.go('/login')),
      ]);
    }

    final host = svc.repo.user(event.hostId);
    final isTeam = me != null && event.isHostingTeam(me.id);
    final c = context.carps;
    final wide = MediaQuery.sizeOf(context).width >= 840;
    final rating = svc.ratingSummary(me?.id, event.id);

    final info = <Widget>[
      ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: AspectRatio(
          aspectRatio: 16 / 9,
          child: Stack(fit: StackFit.expand, children: [
            EventCover(event: event),
            Positioned(
              left: 12,
              bottom: 12,
              child: Row(children: [
                if (event.capacity != null && !event.isEnded(svc.now))
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(999)),
                    child: Text(
                        '${(event.capacity! - svc.goingCount(event.id)).clamp(0, 999)} spots left',
                        style: TextStyle(
                            color: c.accentFill,
                            fontSize: 12,
                            fontWeight: FontWeight.w700)),
                  ),
              ]),
            ),
          ]),
        ),
      ),
      const SizedBox(height: 16),
      Wrap(spacing: 6, runSpacing: 6, children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
              color: c.muted, borderRadius: BorderRadius.circular(999)),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(topicIcon(event.topic), size: 13, color: c.textSecondary),
            const SizedBox(width: 5),
            Text(event.topic.toUpperCase(),
                style: TextStyle(
                    fontSize: 11,
                    letterSpacing: 0.4,
                    fontWeight: FontWeight.w600,
                    color: c.textSecondary)),
          ]),
        ),
        StatusChip(event.isPrivate ? StatusKind.private : StatusKind.public),
        if (event.isCancelled)
          const StatusChip(StatusKind.cancelled)
        else if (event.isEnded(svc.now))
          const StatusChip(StatusKind.ended)
        else if (event.isLive(svc.now))
          const StatusChip(StatusKind.live),
        if (event.seriesLabel != null)
          StatusChip(StatusKind.booked, label: event.seriesLabel),
      ]),
      const SizedBox(height: 10),
      Text(event.title, style: Theme.of(context).textTheme.headlineMedium),
      const SizedBox(height: 16),
      if (host != null) _BuilderRow(builder: host),
      const SizedBox(height: 10),
      _InfoRow(
          icon: CarpsIcons.calendarBlank,
          title: timeRange(event.start, event.end),
          subtitle: event.isEnded(svc.now)
              ? 'Ended'
              : relative(event.start, svc.now),
          accent: true),
      const SizedBox(height: 10),
      _InfoRow(
          icon: CarpsIcons.mapPin,
          title: event.venue,
          subtitle: event.area),
      const SizedBox(height: 16),
      if (me != null && !isTeam) _MyStatusCard(event: event),
      if (isTeam) _HostToolsCard(event: event),
      if (event.notices.isNotEmpty) ...[
        const SizedBox(height: 16),
        Text('Updates from the host',
            style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        for (final n in event.notices)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: SurfaceCard(
              color: c.accentTint,
              padding: const EdgeInsets.all(12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                      n.isVenueChange
                          ? CarpsIcons.mapPin
                          : CarpsIcons.megaphone,
                      size: 18,
                      color: c.accentText),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(n.text),
                        Text(relative(n.createdAt, svc.now),
                            style: Theme.of(context).textTheme.bodySmall),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    ];

    final tabs = <Widget>[
      SegmentedTabs(
        labels: [
          'Details',
          'Experiences',
          rating.average == null
              ? 'Reviews'
              : 'Reviews ★ ${rating.average!.toStringAsFixed(1)}',
        ],
        selected: _tab,
        onChanged: (i) => setState(() => _tab = i),
      ),
      const SizedBox(height: 16),
      ...switch (_tab) {
        0 => _details(context, event, svc),
        1 => _experiences(context, event, svc, me?.id),
        _ => _reviews(context, event, svc, me?.id),
      },
    ];

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            BackHeader(
              title: 'Event',
              trailing: IconButton(
                tooltip: 'Copy share link (simulated)',
                icon: const Icon(CarpsIcons.shareNetwork),
                onPressed: () => showCarpsSnack(context,
                    'Link: carps.ph/event/${event.id} (sharing is simulated)'),
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                children: [
                  Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: wide ? 1200 : 720),
                      child: wide
                          ? Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                    child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.stretch,
                                        children: info)),
                                const SizedBox(width: 32),
                                Expanded(
                                    child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.stretch,
                                        children: tabs)),
                              ],
                            )
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                ...info,
                                const SizedBox(height: 20),
                                ...tabs
                              ],
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _BottomAction(event: event),
    );
  }

  List<Widget> _details(BuildContext context, CarpsEvent event, CarpsService svc) {
    final c = context.carps;
    final going = svc.goingCount(event.id);
    return [
      SurfaceCard(
        color: c.muted,
        padding: const EdgeInsets.all(14),
        child: Row(children: [
          Icon(CarpsIcons.usersThree, color: c.textSecondary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
                '$going ${going == 1 ? 'guest' : 'guests'} approved${event.capacity == null ? '' : ' of ${event.capacity}'}',
                style: const TextStyle(fontWeight: FontWeight.w600)),
          ),
          Text('Roster is private',
              style: Theme.of(context).textTheme.bodySmall),
        ]),
      ),
      const SizedBox(height: 20),
      Text('About this event', style: Theme.of(context).textTheme.titleLarge),
      const SizedBox(height: 8),
      Text(event.description.isEmpty ? 'No description yet.' : event.description,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.5)),
      const SizedBox(height: 20),
      SurfaceCard(
        color: c.muted,
        child: Row(children: [
          Icon(CarpsIcons.info, color: c.textSecondary),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
                'Requests are reviewed by the host. Approval issues a QR pass; attendance is recorded only when the host scans it on site.',
                style: TextStyle(fontSize: 13)),
          ),
        ]),
      ),
    ];
  }

  List<Widget> _experiences(
      BuildContext context, CarpsEvent event, CarpsService svc, String? viewerId) {
    if (!svc.canViewPrivateSocial(viewerId, event)) {
      return const [
        EmptyState(
            title: 'Private experiences',
            message:
                'Posts from this private session are visible only to the hosting team and verified attendees.'),
      ];
    }
    final posts = svc.eventPosts(viewerId, event.id);
    if (posts.isEmpty) {
      return [
        EmptyState(
          title: 'No experiences yet',
          message: event.isEnded(svc.now)
              ? 'Checked-in attendees can share what this session was like.'
              : 'Experiences appear after the session ends, from people who checked in.',
        ),
      ];
    }
    return [
      for (final p in posts) ...[
        PostCard(post: p, compact: true),
        const SizedBox(height: 12),
      ],
    ];
  }

  List<Widget> _reviews(
      BuildContext context, CarpsEvent event, CarpsService svc, String? viewerId) {
    if (!svc.canViewPrivateSocial(viewerId, event)) {
      return const [
        EmptyState(
            title: 'Private reviews',
            message:
                'Reviews of private sessions stay within the hosting team and verified attendees.'),
      ];
    }
    final reviews = svc.visibleReviews(viewerId, event.id);
    final canReview = viewerId != null && svc.canReview(viewerId, event);
    return [
      if (canReview)
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: CarpsButton(
              label: 'Rate this session',
              icon: CarpsIcons.star,
              kind: CarpsButtonKind.inverse,
              onPressed: () => context.push('/event/${event.id}/reviews')),
        ),
      if (reviews.isEmpty)
        const EmptyState(
            title: 'No reviews yet',
            message: 'Verified attendees can rate a session after it ends.')
      else
        for (final r in reviews.take(3)) ReviewTile(review: r),
      if (reviews.length > 3)
        TextButton(
            onPressed: () => context.push('/event/${event.id}/reviews'),
            child: Text('See all ${reviews.length} reviews')),
    ];
  }
}

class ReviewTile extends StatelessWidget {
  const ReviewTile({super.key, required this.review});
  final EventReview review;

  @override
  Widget build(BuildContext context) {
    final svc = context.app.service;
    final author = svc.repo.user(review.authorId);
    final c = context.carps;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: SurfaceCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              CarpsAvatar(user: author, size: 36),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(author?.displayName ?? 'Member',
                        style: Theme.of(context).textTheme.titleSmall),
                    Row(children: [
                      Icon(CarpsIcons.sealCheckFill,
                          size: 12, color: c.accentFill),
                      const SizedBox(width: 4),
                      Text('Verified attendee · ${relative(review.createdAt, svc.now)}',
                          style: Theme.of(context).textTheme.bodySmall),
                    ]),
                  ],
                ),
              ),
              Semantics(
                label: '${review.rating} out of 5 stars',
                child: Row(children: [
                  for (var i = 0; i < 5; i++)
                    Icon(
                        i < review.rating
                            ? CarpsIcons.starFill
                            : CarpsIcons.star,
                        size: 14,
                        color: i < review.rating ? c.accentFill : c.borderStrong),
                ]),
              ),
            ]),
            if (review.text.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(review.text),
            ],
          ],
        ),
      ),
    );
  }
}

class _BuilderRow extends StatelessWidget {
  const _BuilderRow({required this.builder});
  final UserProfile builder;

  @override
  Widget build(BuildContext context) {
    final app = context.app;
    final me = app.me;
    final c = context.carps;
    final following = me?.followingIds.contains(builder.id) ?? false;
    final rating = app.service.builderRating(me?.id, builder.id);
    return SurfaceCard(
      padding: const EdgeInsets.all(12),
      onTap: () => context.push('/user/${builder.id}'),
      child: Row(children: [
        CarpsAvatar(user: builder, size: 48),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Flexible(
                  child: Text(builder.displayName,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleSmall),
                ),
                const SizedBox(width: 4),
                Icon(CarpsIcons.sealCheckFill, size: 14, color: c.accentFill),
              ]),
              Text(
                  '${builder.builderName ?? builder.handle} · Community Builder${rating.average == null ? '' : ' · ★ ${rating.average!.toStringAsFixed(1)}'}',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
        if (me != null && me.id != builder.id)
          Tooltip(
            message: 'Following keeps you updated. It does not reserve a spot.',
            child: CarpsButton(
              label: following ? 'Following' : 'Follow',
              kind: following ? CarpsButtonKind.muted : CarpsButtonKind.secondary,
              height: 38,
              expand: false,
              onPressed: () => runAction(
                  context, () => app.service.toggleFollow(me.id, builder.id),
                  success: following
                      ? 'Unfollowed'
                      : 'Following. This doesn\'t reserve a spot. Use Request to join for that.'),
            ),
          ),
      ]),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow(
      {required this.icon,
      required this.title,
      required this.subtitle,
      this.accent = false});
  final IconData icon;
  final String title;
  final String subtitle;
  final bool accent;

  @override
  Widget build(BuildContext context) {
    final c = context.carps;
    return SurfaceCard(
      padding: const EdgeInsets.all(12),
      child: Row(children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
              color: accent ? c.accentTint : c.muted,
              borderRadius: BorderRadius.circular(12)),
          child: Icon(icon, color: accent ? c.accentFill : c.textPrimary),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.titleSmall),
              Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
      ]),
    );
  }
}

/// The guest's view of THE shared registration record.
class _MyStatusCard extends StatelessWidget {
  const _MyStatusCard({required this.event});
  final CarpsEvent event;

  @override
  Widget build(BuildContext context) {
    final app = context.app;
    final svc = app.service;
    final me = app.me!;
    final c = context.carps;
    final reg = svc.registrationFor(event.id, me.id);
    final invite = svc.guestInvitation(event.id, me.id);
    final att = svc.attendanceFor(event.id, me.id);
    final ended = event.isEnded(svc.now);

    Widget card(
        {required Widget chip,
        required String text,
        List<Widget> actions = const [],
        bool dark = false}) {
      final body = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [chip, const Spacer()]),
          const SizedBox(height: 8),
          Text(text,
              style: TextStyle(
                  fontSize: 13,
                  color: dark ? const Color(0xFFA3A3A3) : c.textSecondary)),
          if (actions.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(spacing: 8, runSpacing: 8, children: actions),
          ],
        ],
      );
      return dark
          ? Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                  color: c.inverse, borderRadius: BorderRadius.circular(20)),
              child: Theme(
                  data: Theme.of(context).copyWith(
                      extensions: [CarpsColors.dark]),
                  child: body))
          : SurfaceCard(child: body);
    }

    if (event.isCancelled) {
      return card(
          chip: const StatusChip(StatusKind.cancelled),
          text:
              'The host cancelled this session. Passes are no longer valid and it never qualifies for posts.');
    }
    if (att != null) {
      return card(
        chip: StatusChip(StatusKind.checkedIn,
            label: 'Checked in · ${timeOfDay(att.arrivedAt)}'),
        text: ended
            ? 'Your attendance is verified. Share what it was like, or rate the session.'
            : 'You\'re here! After the session ends you can share your experience.',
        actions: [
          if (ended && svc.canPostAbout(me.id, event))
            CarpsButton(
                label: 'Share experience',
                icon: CarpsIcons.pencilSimpleLine,
                height: 40,
                expand: false,
                onPressed: () => context.push('/compose?event=${event.id}')),
          if (ended && svc.canReview(me.id, event))
            CarpsButton(
                label: 'Rate event',
                icon: CarpsIcons.star,
                kind: CarpsButtonKind.secondary,
                height: 40,
                expand: false,
                onPressed: () => context.push('/event/${event.id}/reviews')),
        ],
      );
    }
    if (reg == null) {
      if (invite != null) {
        return card(
          chip: const StatusChip(StatusKind.invited),
          text:
              '${svc.repo.user(invite.invitedById)?.displayName} invited you. An invitation lets you request to join; the host still decides.',
        );
      }
      return const SizedBox.shrink();
    }
    switch (reg.status) {
      case RegistrationStatus.pending:
        return card(
          chip: const StatusChip(StatusKind.pending, label: 'Pending approval'),
          text:
              'Request sent ${relative(reg.requestedAt, svc.now)}. You\'ll get a notification when the host decides. No pass until then.',
          actions: [
            CarpsButton(
              label: 'Withdraw request',
              kind: CarpsButtonKind.secondary,
              height: 40,
              expand: false,
              onPressed: () => _withdraw(context, reg),
            ),
          ],
        );
      case RegistrationStatus.approved:
        if (ended) {
          return card(
              chip: const StatusChip(StatusKind.noShow),
              text:
                  'You were approved but not checked in, so this session doesn\'t count as attended and can\'t be posted about.');
        }
        return card(
          dark: true,
          chip: const StatusChip(StatusKind.approved, label: 'Approved · Spot confirmed'),
          text: 'Show your unique QR pass at the venue. Approval alone is not attendance.',
          actions: [
            CarpsButton(
                label: 'Show pass',
                icon: CarpsIcons.qrCode,
                kind: CarpsButtonKind.inverse,
                height: 40,
                expand: false,
                onPressed: () => context.push('/pass/${event.id}')),
            if (!svc.now.isAfter(event.start))
              CarpsButton(
                  label: 'Withdraw',
                  kind: CarpsButtonKind.secondary,
                  height: 40,
                  expand: false,
                  onPressed: () => _withdraw(context, reg)),
          ],
        );
      case RegistrationStatus.declined:
        return card(
            chip: const StatusChip(StatusKind.declined, label: 'Not approved'),
            text: 'The host declined this request. No pass was issued.');
      case RegistrationStatus.withdrawn:
        return card(
            chip: const StatusChip(StatusKind.withdrawn),
            text: 'You withdrew. Any pass you had is no longer valid. You can request again before the start.');
    }
  }

  Future<void> _withdraw(BuildContext context, Registration reg) async {
    final ok = await confirmDialog(context,
        title: 'Withdraw request?',
        message: 'Your spot is released and any pass stops working.',
        confirmLabel: 'Withdraw',
        destructive: true);
    if (ok && context.mounted) {
      final app = context.appRead;
      runAction(context, () => app.service.withdraw(app.me!.id, reg.id),
          success: 'Withdrawn. Your pass is no longer valid.');
    }
  }
}

class _HostToolsCard extends StatelessWidget {
  const _HostToolsCard({required this.event});
  final CarpsEvent event;

  @override
  Widget build(BuildContext context) {
    final app = context.app;
    final svc = app.service;
    final me = app.me!;
    final c = context.carps;
    final pending = svc
        .registrationsForEvent(event.id)
        .where((r) => r.status == RegistrationStatus.pending)
        .length;
    final ended = event.isEnded(svc.now);
    Widget tool(IconData icon, String label, String path, {String? badge}) =>
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Icon(icon, color: c.textPrimary),
          title: Text(label),
          trailing: Row(mainAxisSize: MainAxisSize.min, children: [
            if (badge != null) TintPill(badge),
            Icon(CarpsIcons.caretRight, color: c.textSecondary),
          ]),
          onTap: () => context.push(path),
        );
    return SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(CarpsIcons.crownFill, color: c.accentFill, size: 18),
            const SizedBox(width: 8),
            Text(event.hostId == me.id ? 'You\'re hosting' : 'You\'re co-hosting',
                style: Theme.of(context).textTheme.titleMedium),
          ]),
          const SizedBox(height: 4),
          tool(CarpsIcons.usersThree, 'Guest roster & requests',
              '/event/${event.id}/roster',
              badge: pending > 0 ? '$pending pending' : null),
          if (!event.isCancelled && !ended)
            tool(CarpsIcons.scan, 'Check-in scanner',
                '/event/${event.id}/scan'),
          if (!event.isCancelled)
            tool(CarpsIcons.megaphone, 'Invites, notices & reminders',
                '/event/${event.id}/invites'),
          tool(CarpsIcons.chartBar, 'Turnout & feedback',
              '/event/${event.id}/analytics'),
          if (!event.isCancelled && !ended)
            tool(CarpsIcons.pencilSimple, 'Edit event',
                '/event/${event.id}/edit'),
          if (event.hostId == me.id)
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Feature on my profile'),
              subtitle: Text(event.isPrivate
                  ? 'Private listings stay hidden from people without access.'
                  : 'Shows under Profile → Events. Not a post.'),
              value: event.featuredOnProfile,
              onChanged: (v) => runAction(
                  context, () => svc.setFeatured(me.id, event.id, v)),
            ),
          if (!event.isCancelled && !ended)
            TextButton.icon(
              style: TextButton.styleFrom(foregroundColor: c.error),
              onPressed: () async {
                final ok = await confirmDialog(context,
                    title: 'Cancel this event?',
                    message:
                        'Guests are notified and passes stop working. The link keeps working and shows Cancelled.',
                    confirmLabel: 'Cancel event',
                    destructive: true);
                if (ok && context.mounted) {
                  runAction(context, () => svc.cancelEvent(me.id, event.id),
                      success: 'Event cancelled');
                }
              },
              icon: const Icon(CarpsIcons.prohibit),
              label: const Text('Cancel event'),
            ),
          if (ended && !svc.hasAttended(event.id, me.id))
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                  'Hosting alone doesn\'t qualify you to post a recap. Your presence must be recorded at check-in.',
                  style: Theme.of(context).textTheme.bodySmall),
            ),
        ],
      ),
    );
  }
}

class _BottomAction extends StatelessWidget {
  const _BottomAction({required this.event});
  final CarpsEvent event;

  @override
  Widget build(BuildContext context) {
    final app = context.app;
    final svc = app.service;
    final me = app.me;
    final c = context.carps;
    if (!svc.canViewEvent(me?.id, event)) return const SizedBox.shrink();
    if (me == null) {
      return BottomActionBar(
        child: CarpsButton(
            label: 'Log in to request to join',
            onPressed: () => context.go('/login')),
      );
    }
    if (event.isHostingTeam(me.id)) {
      final pending = svc
          .registrationsForEvent(event.id)
          .where((r) => r.status == RegistrationStatus.pending)
          .length;
      return BottomActionBar(
        child: CarpsButton(
          label: pending > 0
              ? 'Review $pending pending ${pending == 1 ? 'request' : 'requests'}'
              : 'Manage guest roster',
          kind: CarpsButtonKind.inverse,
          icon: CarpsIcons.usersThree,
          onPressed: () => context.push('/event/${event.id}/roster'),
        ),
      );
    }
    final blocker = svc.requestBlocker(me.id, event);
    final reg = svc.registrationFor(event.id, me.id);
    if (reg != null && reg.isActive) return const SizedBox.shrink();
    if (blocker != null && svc.attendanceFor(event.id, me.id) == null) {
      return BottomActionBar(
        child: Row(children: [
          Icon(CarpsIcons.info, color: c.textSecondary, size: 18),
          const SizedBox(width: 8),
          Expanded(
              child: Text(blocker, style: TextStyle(color: c.textSecondary))),
        ]),
      );
    }
    if (blocker != null) return const SizedBox.shrink();
    return BottomActionBar(
      child: Row(children: [
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const CaptionLabel('Admission'),
              Text('Host approval',
                  style: Theme.of(context).textTheme.titleSmall),
            ],
          ),
        ),
        SizedBox(
          width: 220,
          child: CarpsButton(
            label: 'Request to join',
            trailingArrow: true,
            onPressed: () => _request(context),
          ),
        ),
      ]),
    );
  }

  Future<void> _request(BuildContext context) async {
    final note = TextEditingController();
    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(
            20, 0, 20, 24 + MediaQuery.viewInsetsOf(ctx).bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Request to join', style: Theme.of(ctx).textTheme.titleLarge),
            const SizedBox(height: 4),
            Text(
                '${event.title} · ${dateTime(event.start)}\nYour request starts as Pending until the host decides.',
                style: Theme.of(ctx).textTheme.bodySmall),
            const SizedBox(height: 16),
            const FieldLabel('Note to host (optional)'),
            TextField(
              controller: note,
              maxLength: 140,
              maxLines: 2,
              decoration: const InputDecoration(
                  hintText: 'First time playing here, excited to join!'),
            ),
            const SizedBox(height: 8),
            CarpsButton(
                label: 'Send request',
                onPressed: () => Navigator.pop(ctx, true)),
          ],
        ),
      ),
    );
    if (ok == true && context.mounted) {
      final app = context.appRead;
      runAction(context,
          () => app.service.requestToJoin(app.me!.id, event.id, note: note.text),
          success: 'Request sent. It\'s Pending in My RSVPs.');
    }
  }
}
