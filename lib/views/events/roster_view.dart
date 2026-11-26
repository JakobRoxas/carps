import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/carps_icons.dart';

import '../../controllers/app_controller.dart';
import '../../core/format.dart';
import '../../core/theme/carps_colors.dart';
import '../../core/widgets/carps_widgets.dart';
import '../../models/carps_models.dart';

/// Figma 15 · Join Requests & QR Scanner (guest roster).
/// The host sees the SAME registration records the guests see.
class RosterView extends StatefulWidget {
  const RosterView({super.key, required this.eventId});
  final String eventId;
  @override
  State<RosterView> createState() => _RosterViewState();
}

class _RosterViewState extends State<RosterView> {
  int _tab = 0; // requests · approved · other

  @override
  Widget build(BuildContext context) {
    final app = context.app;
    final svc = app.service;
    final me = app.me!;
    final event = svc.repo.event(widget.eventId);
    if (event == null || !event.isHostingTeam(me.id)) {
      return const CarpsPage(title: 'Guest roster', children: [
        EmptyState(
            title: 'Hosting team only',
            message:
                'Rosters are private. Only the builder and accepted co-hosts can see them. Admins do not approve guests.'),
      ]);
    }
    final regs = svc.registrationsForEvent(event.id);
    final pending =
        regs.where((r) => r.status == RegistrationStatus.pending).toList();
    final approved =
        regs.where((r) => r.status == RegistrationStatus.approved).toList();
    final other = regs
        .where((r) =>
            r.status == RegistrationStatus.declined ||
            r.status == RegistrationStatus.withdrawn)
        .toList();
    final checkedIn =
        approved.where((r) => svc.hasAttended(event.id, r.userId)).length;
    final ended = event.isEnded(svc.now);

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(children: [
          BackHeader(title: 'Guest roster'),
          Expanded(
            child: SheetScroll(children: [
                Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 720),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(children: [
                                Expanded(
                                  child: Text(event.title,
                                      style: Theme.of(context)
                                          .textTheme
                                          .headlineMedium),
                                ),
                                if (event.capacity != null)
                                  TintPill(
                                      '${approved.length} / ${event.capacity} spots'),
                              ]),
                              Text(dateTime(event.start),
                                  style: Theme.of(context).textTheme.bodySmall),
                              const SizedBox(height: 16),
                              SegmentedTabs(
                                labels: [
                                  'Requests',
                                  'Approved (${approved.length})',
                                  'Other (${other.length})',
                                ],
                                badges: {
                                  if (pending.isNotEmpty) 0: '${pending.length}'
                                },
                                selected: _tab,
                                onChanged: (i) => setState(() => _tab = i),
                              ),
                            ],
                          ),
                        ),
                        DarkSheet(
                          fill: true,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              HighlightCard(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(children: [
                                      CircleAvatar(
                                        backgroundColor:
                                            CarpsColors.light.accentTint,
                                        child: Icon(CarpsIcons.scan,
                                            color:
                                                CarpsColors.light.accentFill),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            const Text('Live check-in scanner',
                                                style: TextStyle(
                                                    fontSize: 17,
                                                    fontWeight:
                                                        FontWeight.w600)),
                                            Text(
                                                '$checkedIn of ${approved.length} approved guests checked in',
                                                style: TextStyle(
                                                    fontSize: 12,
                                                    color: CarpsColors
                                                        .light.textSecondary)),
                                          ],
                                        ),
                                      ),
                                    ]),
                                    const SizedBox(height: 14),
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(999),
                                      child: LinearProgressIndicator(
                                        value: approved.isEmpty
                                            ? 0
                                            : checkedIn / approved.length,
                                        minHeight: 8,
                                        backgroundColor:
                                            CarpsColors.light.borderSubtle,
                                        color: CarpsColors.light.accentFill,
                                      ),
                                    ),
                                    const SizedBox(height: 14),
                                    CarpsButton(
                                      label: ended
                                          ? 'Event ended'
                                          : 'Open QR scanner',
                                      icon: CarpsIcons.qrCode,
                                      kind: CarpsButtonKind.inverse,
                                      onPressed: ended || event.isCancelled
                                          ? null
                                          : () => context.push(
                                              '/event/${event.id}/scan'),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 24),
                              // Builder: use the sheet's (dark) theme context.
                              Builder(
                                builder: (context) => Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: switch (_tab) {
                                    0 => _pending(context, pending),
                                    1 => _approved(context, approved, ended),
                                    _ => _other(context, other),
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ]),
      ),
    );
  }

  List<Widget> _pending(BuildContext context, List<Registration> pending) {
    final app = context.app;
    final svc = app.service;
    final d = context.carps;
    return [
      Row(children: [
        Text('Pending requests', style: Theme.of(context).textTheme.titleLarge),
        const Spacer(),
        Text('Manual review', style: TextStyle(color: d.textSecondary, fontSize: 12)),
      ]),
      const SizedBox(height: 12),
      if (pending.isEmpty)
        const EmptyState(
            title: 'All caught up',
            message: 'New join requests show up here for your decision.'),
      for (final r in pending)
        Padding(
          key: ValueKey('request-${r.userId}'),
          padding: const EdgeInsets.only(bottom: 12),
          child: _RequestCard(registration: r, onDecide: (approve) {
            final guest = svc.repo.user(r.userId)?.displayName ?? 'Guest';
            runAction(
                context,
                () => svc.decide(app.me!.id, r.id, approve: approve),
                success: approve
                    ? '$guest approved. Their unique pass was issued.'
                    : '$guest declined. No pass issued.');
          }),
        ),
    ];
  }

  List<Widget> _approved(
      BuildContext context, List<Registration> approved, bool ended) {
    final svc = context.app.service;
    final d = context.carps;
    return [
      Text('Approved guests', style: Theme.of(context).textTheme.titleLarge),
      const SizedBox(height: 4),
      Text('Approval is not attendance. Only a valid scan records arrival.',
          style: TextStyle(fontSize: 12, color: d.textSecondary)),
      const SizedBox(height: 12),
      if (approved.isEmpty)
        const EmptyState(
            title: 'No approved guests yet',
            message: 'Approve requests to issue passes.'),
      for (final r in approved)
        Builder(builder: (context) {
          final u = svc.repo.user(r.userId);
          final att = svc.attendanceFor(r.eventId, r.userId);
          return ListTile(
            contentPadding: EdgeInsets.zero,
            leading: CarpsAvatar(user: u, size: 40),
            title: Text(u?.displayName ?? ''),
            subtitle: Text(att != null
                ? 'Arrived ${timeOfDay(att.arrivedAt)}'
                : (ended ? 'Not scanned' : 'Pass issued')),
            trailing: att != null
                ? const StatusChip(StatusKind.checkedIn)
                : (ended
                    ? const StatusChip(StatusKind.noShow)
                    : const StatusChip(StatusKind.approved)),
          );
        }),
    ];
  }

  List<Widget> _other(BuildContext context, List<Registration> other) {
    final svc = context.app.service;
    return [
      Text('Declined & withdrawn', style: Theme.of(context).textTheme.titleLarge),
      const SizedBox(height: 12),
      if (other.isEmpty)
        const EmptyState(title: 'Nothing here', message: 'No declined or withdrawn requests.'),
      for (final r in other)
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: CarpsAvatar(user: svc.repo.user(r.userId), size: 40),
          title: Text(svc.repo.user(r.userId)?.displayName ?? ''),
          trailing: StatusChip(statusFor(r.status)),
        ),
    ];
  }
}

class _RequestCard extends StatelessWidget {
  const _RequestCard({required this.registration, required this.onDecide});
  final Registration registration;
  final ValueChanged<bool> onDecide;

  @override
  Widget build(BuildContext context) {
    final svc = context.app.service;
    final d = context.carps;
    final u = svc.repo.user(registration.userId);
    final attended = u == null ? 0 : svc.attendedCount(u.id);
    final invited =
        svc.guestInvitation(registration.eventId, registration.userId) != null;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: d.inverseRaised, borderRadius: BorderRadius.circular(24)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            CarpsAvatar(user: u, size: 48),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(u?.displayName ?? 'Guest',
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.w600)),
                  Text(
                      '${u?.handle} · ${attended == 0 ? 'New member' : '$attended attended'}',
                      style: TextStyle(fontSize: 12, color: d.textSecondary)),
                ],
              ),
            ),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text(relative(registration.requestedAt, svc.now),
                  style: TextStyle(fontSize: 11, color: d.textSecondary)),
              if (invited) ...[
                const SizedBox(height: 4),
                const StatusChip(StatusKind.invited),
              ],
            ]),
          ]),
          if (registration.note.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                  color: d.canvas, borderRadius: BorderRadius.circular(14)),
              child: Text('“${registration.note}”'),
            ),
          ],
          const SizedBox(height: 12),
          Row(children: [
            Expanded(
              child: CarpsButton(
                  label: 'Decline',
                  kind: CarpsButtonKind.muted,
                  height: 46,
                  onPressed: () => onDecide(false)),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: CarpsButton(
                  label: 'Approve', height: 46, onPressed: () => onDecide(true)),
            ),
          ]),
        ],
      ),
    );
  }
}
