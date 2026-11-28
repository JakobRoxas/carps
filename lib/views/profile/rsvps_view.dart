import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/carps_icons.dart';

import '../../controllers/app_controller.dart';
import '../../core/format.dart';
import '../../core/theme/carps_colors.dart';
import '../../core/widgets/carps_widgets.dart';
import '../../models/carps_models.dart';

class _Item {
  _Item(this.event, this.reg, {this.invited = false});
  final CarpsEvent event;
  final Registration? reg;
  final bool invited;
}

/// Figma 17 · My RSVPs: requests and invitations for upcoming sessions,
/// read from the same registration records the host manages.
class RsvpsView extends StatefulWidget {
  const RsvpsView({super.key});
  @override
  State<RsvpsView> createState() => _RsvpsViewState();
}

class _RsvpsViewState extends State<RsvpsView> {
  DateTime? _day;

  @override
  Widget build(BuildContext context) {
    final app = context.app;
    final svc = app.registrations;
    final me = app.me!;
    final c = context.carps;
    final now = svc.now;

    final items = <_Item>[];
    for (final r in app.data.registrations.where((r) => r.userId == me.id)) {
      final e = app.data.eventById(r.eventId);
      if (e == null || e.isEnded(now)) continue;
      items.add(_Item(e, r));
    }
    for (final i in app.data.invitations.where(
      (i) => i.inviteeId == me.id && i.kind == InvitationKind.guest,
    )) {
      final e = app.data.eventById(i.eventId);
      if (e == null || e.isEnded(now) || items.any((x) => x.event.id == e.id)) {
        continue;
      }
      items.add(_Item(e, null, invited: true));
    }
    items.sort((a, b) => a.event.start.compareTo(b.event.start));
    final shown = _day == null
        ? items
        : items.where((i) => _sameDay(i.event.start, _day!)).toList();
    final upNext = shown
        .where(
          (i) =>
              i.reg?.status == RegistrationStatus.approved &&
              !i.event.isCancelled,
        )
        .firstOrNull;
    final today = DateTime(now.year, now.month, now.day);
    final days = [for (var i = -1; i < 6; i++) today.add(Duration(days: i))];

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            BackHeader(title: 'My RSVPs'),
            Expanded(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 720),
                  child: SizedBox.expand(
                    child: CustomScrollView(
                      slivers: [
                        SliverToBoxAdapter(
                          child: Container(
                            decoration: BoxDecoration(
                              color: c.canvas,
                              borderRadius: const BorderRadius.vertical(
                                bottom: Radius.elliptical(400, 40),
                              ),
                            ),
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Wrap(
                                  alignment: WrapAlignment.spaceBetween,
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  spacing: 8,
                                  runSpacing: 4,
                                  children: [
                                    Text(
                                      'My RSVPs',
                                      style: Theme.of(context)
                                          .textTheme
                                          .headlineLarge,
                                    ),
                                    TintPill('${items.length} upcoming'),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                _MonthStrip(now: now),
                                const SizedBox(height: 16),
                                Row(
                                  children: [
                                    for (final d in days)
                                      Expanded(
                                        child: _DayCapsule(
                                          day: d,
                                          selected:
                                              _day != null &&
                                              _sameDay(_day!, d),
                                          isToday: _sameDay(d, now),
                                          hasRsvp: items.any(
                                            (i) => _sameDay(i.event.start, d),
                                          ),
                                          onTap: () => setState(
                                            () => _day =
                                                _day != null &&
                                                    _sameDay(_day!, d)
                                                ? null
                                                : d,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        SliverToBoxAdapter(
                          child: DarkSheet(
                            padding: EdgeInsets.fromLTRB(
                              16,
                              28,
                              16,
                              32 + MediaQuery.paddingOf(context).bottom,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                if (_day != null)
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 12),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            'Showing ${shortDate(_day!)}',
                                            style: TextStyle(
                                              color: c.onInverseSecondary,
                                            ),
                                          ),
                                        ),
                                        TextButton(
                                          onPressed: () =>
                                              setState(() => _day = null),
                                          child: const Text('Show all'),
                                        ),
                                      ],
                                    ),
                                  ),
                                if (shown.isEmpty)
                                  if (_day == null)
                                    EmptyState(
                                      title: 'No upcoming RSVPs',
                                      message: 'Requests you send and private invitations you receive show up here.',
                                      actionLabel: 'Find an event',
                                      onAction: () => context.go('/home'),
                                    )
                                  else
                                    const EmptyState(
                                      title: 'No RSVPs on this day',
                                      message: 'Choose another date or show all RSVPs.',
                                    ),
                                for (final item in shown)
                                  _TimelineRow(
                                    time: item.event.start,
                                    highlight: item == upNext,
                                    child: item == upNext
                                        ? _UpNextCard(item: item)
                                        : _RsvpCard(item: item),
                                  ),
                              ],
                            ),
                          ),
                        ),
                        // Extend the sheet color without adding scrollable
                        // space. This also paints behind a bottom-edge bounce.
                        SliverFillRemaining(
                          hasScrollBody: false,
                          fillOverscroll: true,
                          child: ColoredBox(
                            color: CarpsColors.light.inverse,
                            child: const Align(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}

class _MonthStrip extends StatelessWidget {
  const _MonthStrip({required this.now});

  final DateTime now;

  @override
  Widget build(BuildContext context) {
    const monthStyle = TextStyle(fontSize: 22, fontWeight: FontWeight.w600);
    final adjacentStyle = monthStyle.copyWith(
      color: context.carps.textDisabled,
    );
    final previous = DateTime(now.year, now.month - 1);
    final next = DateTime(now.year, now.month + 1);

    return LayoutBuilder(
      builder: (context, constraints) {
        // Leave room for the current month on narrow screens or with larger text.
        final compact =
            constraints.maxWidth <
            336 * MediaQuery.textScalerOf(context).scale(22) / 22;
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: Text(
                compact ? monthShort(previous) : monthLong(previous),
                semanticsLabel: monthLong(previous),
                style: adjacentStyle,
              ),
            ),
            Flexible(
              flex: compact ? 2 : 1,
              child: Text(
                monthLong(now),
                textAlign: TextAlign.center,
                style: monthStyle,
              ),
            ),
            Flexible(
              child: Text(
                compact ? monthShort(next) : monthLong(next),
                textAlign: TextAlign.end,
                semanticsLabel: monthLong(next),
                style: adjacentStyle,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _DayCapsule extends StatelessWidget {
  const _DayCapsule({
    required this.day,
    required this.selected,
    required this.isToday,
    required this.hasRsvp,
    required this.onTap,
  });
  final DateTime day;
  final bool selected;
  final bool isToday;
  final bool hasRsvp;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.carps;
    return Semantics(
      selected: selected,
      button: true,
      label: '${shortDate(day)}${hasRsvp ? ', has RSVPs' : ''}',
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 3),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected ? c.selectFill : c.muted,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Column(
            children: [
              Text(
                weekdayShort(day),
                style: TextStyle(
                  fontSize: 12,
                  color: selected ? c.onSelect : c.textSecondary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${day.day}',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: selected ? c.onSelect : c.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                width: 5,
                height: 5,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isToday
                      ? c.accentFill
                      : (hasRsvp
                            ? (selected ? c.onSelect : c.textSecondary)
                            : Colors.transparent),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TimelineRow extends StatelessWidget {
  const _TimelineRow({
    required this.time,
    required this.child,
    this.highlight = false,
  });
  final DateTime time;
  final Widget child;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final d = context.carps;
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 58,
            child: Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    timeOfDay(time).split(' ').first,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    timeOfDay(time).split(' ').last,
                    style: TextStyle(fontSize: 11, color: d.textSecondary),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(
            width: 28,
            child: Column(
              children: [
                const SizedBox(height: 20),
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: highlight ? d.accentFill : d.textSecondary,
                    border: highlight
                        ? Border.all(color: d.accentTint, width: 3)
                        : null,
                  ),
                ),
                Expanded(child: Container(width: 2, color: d.borderSubtle)),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: child,
            ),
          ),
        ],
      ),
    );
  }
}

class _UpNextCard extends StatelessWidget {
  const _UpNextCard({required this.item});
  final _Item item;
  @override
  Widget build(BuildContext context) {
    final e = item.event;
    return InkWell(
      onTap: () => context.push('/event/${e.id}'),
      child: HighlightCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const CaptionLabel('Up next', color: Color(0xFFE8590C)),
                const Spacer(),
                const StatusChip(StatusKind.approved),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              e.title,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
            ),
            Text(
              '${dateTime(e.start)} · ${e.venue}',
              style: TextStyle(
                fontSize: 12,
                color: CarpsColors.light.textSecondary,
              ),
            ),
            const SizedBox(height: 12),
            CarpsButton(
              label: 'Show my pass',
              icon: CarpsIcons.qrCode,
              kind: CarpsButtonKind.inverse,
              height: 48,
              onPressed: () => context.push('/pass/${e.id}'),
            ),
          ],
        ),
      ),
    );
  }
}

class _RsvpCard extends StatelessWidget {
  const _RsvpCard({required this.item});
  final _Item item;
  @override
  Widget build(BuildContext context) {
    final d = context.carps;
    final e = item.event;
    final StatusChip chip;
    if (e.isCancelled) {
      chip = const StatusChip(StatusKind.cancelled);
    } else if (item.invited) {
      chip = const StatusChip(StatusKind.invited);
    } else {
      chip = StatusChip(statusFor(item.reg!.status));
    }
    return Material(
      color: d.inverseRaised,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => context.push('/event/${e.id}'),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      dateTime(e.start),
                      style: TextStyle(fontSize: 12, color: d.textSecondary),
                    ),
                  ),
                  chip,
                ],
              ),
              const SizedBox(height: 6),
              Text(
                e.title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(CarpsIcons.mapPin, size: 14, color: d.textSecondary),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      e.venue,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 12, color: d.textSecondary),
                    ),
                  ),
                ],
              ),
              if (item.reg?.status == RegistrationStatus.approved &&
                  !e.isCancelled) ...[
                const SizedBox(height: 10),
                CarpsButton(
                  label: 'Show my pass',
                  icon: CarpsIcons.qrCode,
                  kind: CarpsButtonKind.inverse,
                  height: 40,
                  onPressed: () => context.push('/pass/${e.id}'),
                ),
              ],
              if (item.invited) ...[
                const SizedBox(height: 6),
                Text(
                  'Invitation only lets you request. Open to request to join.',
                  style: TextStyle(fontSize: 12, color: d.textSecondary),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
