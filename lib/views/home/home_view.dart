import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/carps_icons.dart';

import '../../controllers/app_controller.dart';
import '../../core/format.dart';
import '../../core/theme/carps_colors.dart';
import '../../core/widgets/carps_widgets.dart';
import '../../core/widgets/event_widgets.dart';
import '../../models/carps_models.dart';

/// Figma 06 · Home / For You. Home is EVENTS to attend (never posts).
class HomeView extends StatefulWidget {
  const HomeView({super.key});
  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  int _tab = 0; // 0 For You · 1 Hosting

  @override
  Widget build(BuildContext context) {
    final app = context.app;
    final me = app.me!;
    final svc = app.service;
    final c = context.carps;
    final hosting = svc.hostingEvents(me.id);
    final forYou = svc.forYou(me.id);
    final width = MediaQuery.sizeOf(context).width;
    final columns = width >= 1100 ? 3 : (width >= 700 ? 2 : 1);

    return Column(
      children: [
        const CarpsTopBar(),
        Expanded(
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1200),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Flexible(
                                          child: Text(
                                            '${greeting(svc.now)}, ${me.displayName.split(' ').first}',
                                            overflow: TextOverflow.ellipsis,
                                            style: Theme.of(context)
                                                .textTheme
                                                .headlineMedium,
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        Icon(
                                          CarpsIcons.lightningFill,
                                          color: c.accentFill,
                                          size: 20,
                                        ),
                                        const SizedBox(width: 6),
                                        CircleAvatar(
                                          radius: 16,
                                          backgroundColor: c.accentTint,
                                          child: Image.asset(
                                            'assets/images/carp_mascot_small.png',
                                            width: 20,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Wrap(
                                      spacing: 16,
                                      runSpacing: 4,
                                      crossAxisAlignment:
                                          WrapCrossAlignment.center,
                                      children: [
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              CarpsIcons.mapPinFill,
                                              size: 14,
                                              color: c.accentFill,
                                            ),
                                            const SizedBox(width: 4),
                                            Flexible(
                                              child: Text(
                                                me.area ?? 'Anywhere',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: c.textSecondary,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        Text(
                                          'Are you Game?',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                            color: c.accentText,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              CircleIconButton(
                                icon: CarpsIcons.mapTrifold,
                                tooltip: 'Map view (simulated)',
                                size: 48,
                                onPressed: () => showCarpsSnack(
                                  context,
                                  'Map view is simulated in this build.',
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Semantics(
                            button: true,
                            label: 'Search events',
                            child: InkWell(
                              borderRadius: BorderRadius.circular(999),
                              onTap: () => context.push('/search'),
                              child: Container(
                                height: 52,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                ),
                                decoration: BoxDecoration(
                                  color: c.muted,
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      CarpsIcons.magnifyingGlass,
                                      color: c.textSecondary,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        'event/topic/date/area/builder',
                                        style: TextStyle(
                                          color: c.textSecondary,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                    Icon(
                                      CarpsIcons.slidersHorizontal,
                                      color: c.textSecondary,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          SegmentedTabs(
                            labels: const ['For You', 'Hosting'],
                            selected: _tab,
                            badges: {
                              if (hosting.isNotEmpty) 1: '${hosting.length}',
                            },
                            onChanged: (i) => setState(() => _tab = i),
                          ),
                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              if (_tab == 0)
                _EventGrid(
                  events: forYou,
                  columns: columns,
                  empty: EmptyState(
                    title: 'No upcoming public events',
                    message: 'Check back soon, or follow builders to hear when they host next.',
                    actionLabel: 'Search events',
                    onAction: () => context.push('/search'),
                  ),
                )
              else
                SliverToBoxAdapter(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1200),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: _HostingList(events: hosting),
                      ),
                    ),
                  ),
                ),
              const SliverToBoxAdapter(child: SizedBox(height: 32)),
            ],
          ),
        ),
      ],
    );
  }
}

class _EventGrid extends StatelessWidget {
  const _EventGrid({
    required this.events,
    required this.columns,
    required this.empty,
  });
  final List<CarpsEvent> events;
  final int columns;
  final Widget empty;

  @override
  Widget build(BuildContext context) {
    if (events.isEmpty) return SliverToBoxAdapter(child: empty);
    return SliverLayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.crossAxisExtent;
        final side = w > 1200 ? (w - 1200) / 2 + 16 : 16.0;
        final cols = w >= 1100 ? 3 : (w >= 700 ? 2 : 1);
        return SliverPadding(
          padding: EdgeInsets.symmetric(horizontal: side),
          sliver: SliverGrid(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: cols,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              mainAxisExtent: 224,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, i) => EventPhotoCard(event: events[i]),
              childCount: events.length,
            ),
          ),
        );
      },
    );
  }
}

/// Hosting filter: events this user hosts or co-hosts, including private.
class _HostingList extends StatelessWidget {
  const _HostingList({required this.events});
  final List<CarpsEvent> events;

  @override
  Widget build(BuildContext context) {
    final app = context.app;
    final me = app.me!;
    final svc = app.service;
    final coHostInvites = svc.repo.invitations
        .where(
          (i) =>
              i.inviteeId == me.id &&
              i.kind == InvitationKind.coHost &&
              i.status == InvitationStatus.sent,
        )
        .toList();
    if (!me.hostingEnabled && coHostInvites.isEmpty) {
      return EmptyState(
        title: 'Hosting tools are off',
        message: 'Turn on hosting on this same account to publish events and review join requests.',
        actionLabel: 'Enable hosting',
        onAction: () => context.push('/builder-setup'),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final inv in coHostInvites)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _CoHostInviteCard(invitation: inv),
          ),
        if (events.isEmpty)
          EmptyState(
            title: 'Nothing hosted yet',
            message: 'Tap ＋ to create your first event.',
            actionLabel: 'Create event',
            onAction: () => context.push('/create'),
          ),
        for (final e in events) ...[
          EventRowTile(
            event: e,
            subtitle:
                '${dateTime(e.start)} · ${svc.goingCount(e.id)} approved · ${svc.registrationsForEvent(e.id).where((r) => r.status == RegistrationStatus.pending).length} pending',
            trailing: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (e.isCancelled)
                  const StatusChip(StatusKind.cancelled)
                else if (e.isEnded(svc.now))
                  const StatusChip(StatusKind.ended)
                else if (e.isLive(svc.now))
                  const StatusChip(StatusKind.live)
                else
                  StatusChip(
                    e.isPrivate ? StatusKind.private : StatusKind.public,
                  ),
                if (e.hostId != me.id) ...[
                  const SizedBox(height: 4),
                  Text('Co-host', style: Theme.of(context).textTheme.bodySmall),
                ],
              ],
            ),
          ),
          const SizedBox(height: 10),
        ],
      ],
    );
  }
}

class _CoHostInviteCard extends StatelessWidget {
  const _CoHostInviteCard({required this.invitation});
  final Invitation invitation;

  @override
  Widget build(BuildContext context) {
    final app = context.app;
    final svc = app.service;
    final event = svc.repo.event(invitation.eventId);
    final from = svc.repo.user(invitation.invitedById);
    if (event == null) return const SizedBox.shrink();
    return SurfaceCard(
      color: context.carps.accentTint,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${from?.displayName} invited you to co-host',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          Text(
            '${event.title} · ${dateTime(event.start)}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 4),
          Text(
            'Hosting tools for this event unlock only after you accept.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: CarpsButton(
                  label: 'Decline',
                  kind: CarpsButtonKind.secondary,
                  height: 44,
                  onPressed: () => runAction(
                    context,
                    () => svc.respondToCoHost(app.me!.id, invitation.id, false),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: CarpsButton(
                  label: 'Accept',
                  height: 44,
                  onPressed: () => runAction(
                    context,
                    () => svc.respondToCoHost(app.me!.id, invitation.id, true),
                    success: 'You are now co-hosting ${event.title}',
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
