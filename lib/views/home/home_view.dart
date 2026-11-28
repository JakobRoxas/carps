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
  final _search = TextEditingController();
  final _topics = <String>{};
  final _areas = <String>{};

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  List<CarpsEvent> _filteredForYou(List<CarpsEvent> events) {
    final q = _search.text.trim().toLowerCase();
    return events.where((event) {
      final text = '${event.title} ${event.topic} ${event.area} ${event.venue}'
          .toLowerCase();
      if (q.isNotEmpty && !text.contains(q)) return false;
      if (_topics.isNotEmpty && !_topics.contains(event.topic)) return false;
      if (_areas.isNotEmpty && !_areas.contains(event.area)) return false;
      return true;
    }).toList();
  }

  Future<void> _openFilters() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) => SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Filter For You',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  const CaptionLabel('Topic'),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final topic in kTopics)
                        SelectChip(
                          label: topic,
                          selected: _topics.contains(topic),
                          onTap: () => setSheetState(() {
                            _topics.contains(topic)
                                ? _topics.remove(topic)
                                : _topics.add(topic);
                          }),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const CaptionLabel('Area'),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final area in kAreas)
                        SelectChip(
                          label: area,
                          selected: _areas.contains(area),
                          onTap: () => setSheetState(() {
                            _areas.contains(area)
                                ? _areas.remove(area)
                                : _areas.add(area);
                          }),
                        ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: CarpsButton(
                          label: 'Clear',
                          kind: CarpsButtonKind.secondary,
                          onPressed: () => setSheetState(() {
                            _topics.clear();
                            _areas.clear();
                          }),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: CarpsButton(
                          label: 'Apply',
                          onPressed: () => Navigator.pop(sheetContext),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final app = context.app;
    final me = app.me!;
    final svc = app.events;
    final c = context.carps;
    final hosting = svc.hostingEvents(me.id);
    final forYou = _filteredForYou(svc.forYou(me.id));
    final filterCount = _topics.length + _areas.length;
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
                          Container(
                            height: 52,
                            decoration: BoxDecoration(
                              color: c.muted,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: TextField(
                              controller: _search,
                              onChanged: (_) => setState(() {}),
                              decoration: InputDecoration(
                                hintText:
                                    'Search event, topic, area or builder',
                                hintStyle: TextStyle(
                                  color: c.textSecondary,
                                  fontSize: 14,
                                ),
                                border: InputBorder.none,
                                prefixIcon: Icon(
                                  CarpsIcons.magnifyingGlass,
                                  color: c.textSecondary,
                                ),
                                suffixIcon: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (filterCount > 0)
                                      CircleAvatar(
                                        radius: 10,
                                        backgroundColor: c.accentFill,
                                        child: Text(
                                          '$filterCount',
                                          style: TextStyle(
                                            color: c.onAccent,
                                            fontSize: 10,
                                          ),
                                        ),
                                      ),
                                    IconButton(
                                      tooltip: 'Filter For You',
                                      onPressed: _openFilters,
                                      icon: Icon(
                                        CarpsIcons.slidersHorizontal,
                                        color: c.textSecondary,
                                      ),
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
    final svc = app.events;
    final coHostInvites = app.data.invitations
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
    final svc = app.events;
    final event = app.data.eventById(invitation.eventId);
    final from = app.data.userById(invitation.invitedById);
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
