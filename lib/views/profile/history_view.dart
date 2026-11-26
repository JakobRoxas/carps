import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/carps_icons.dart';

import '../../controllers/app_controller.dart';
import '../../core/format.dart';
import '../../core/theme/carps_colors.dart';
import '../../core/widgets/carps_widgets.dart';
import '../../models/carps_models.dart';

/// Figma 18 · Attendance History: verified check-ins vs bookings vs no-shows.
/// Loading, empty ("No attended events yet") and failed-lookup states differ.
class HistoryView extends StatefulWidget {
  const HistoryView({super.key});
  @override
  State<HistoryView> createState() => _HistoryViewState();
}

class _HistoryViewState extends State<HistoryView> {
  late Future<List<HistoryEntry>> _future;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    final app = context.appRead;
    _future = app.lookup(() => app.service.historyFor(app.me!.id));
  }

  @override
  Widget build(BuildContext context) {
    final app = context.app; // rebuild on changes
    final c = context.carps;
    // Re-read when shared state changes (e.g. after a review is submitted).
    final entries = app.simulateLookupFailure
        ? null
        : app.service.historyFor(app.me!.id);
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(children: [
          BackHeader(title: 'Attendance history'),
          Expanded(
            child: SheetScroll(children: [
                Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 720),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Attendance History',
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineLarge),
                              Text('Your verified check-ins and past sessions',
                                  style: TextStyle(color: c.textSecondary)),
                              const SizedBox(height: 12),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                    color: c.muted,
                                    borderRadius: BorderRadius.circular(999)),
                                child: Row(mainAxisSize: MainAxisSize.min, children: [
                                  Container(
                                      width: 6,
                                      height: 6,
                                      decoration: BoxDecoration(
                                          color: c.accentFill,
                                          shape: BoxShape.circle)),
                                  const SizedBox(width: 8),
                                  Text(
                                      '${app.service.attendedCount(app.me!.id)} events attended',
                                      style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500)),
                                ]),
                              ),
                            ],
                          ),
                        ),
                        DarkSheet(
                          fill: true,
                          child: FutureBuilder<List<HistoryEntry>>(
                            future: _future,
                            builder: (context, snap) {
                              if (snap.connectionState != ConnectionState.done) {
                                return const LoadingBlock();
                              }
                              if (snap.hasError) {
                                return ErrorState(
                                  message:
                                      'We couldn\'t load your attendance history. This is not the same as having no history.',
                                  onRetry: () => setState(_load),
                                );
                              }
                              final list = entries ?? snap.data!;
                              if (list.isEmpty) {
                                return const EmptyState(
                                  title: 'No attended events yet',
                                  message:
                                      'Once a host checks you in, the event shows up here.',
                                );
                              }
                              return Column(children: [
                                for (final e in list) _HistoryRow(entry: e),
                              ]);
                            },
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
}

class _HistoryRow extends StatelessWidget {
  const _HistoryRow({required this.entry});
  final HistoryEntry entry;

  @override
  Widget build(BuildContext context) {
    final d = context.carps;
    final svc = context.app.service;
    final e = entry.event;
    final active = entry.state == HistoryState.checkedIn;
    final chip = switch (entry.state) {
      HistoryState.checkedIn => StatusChip(StatusKind.checkedIn,
          label: 'Checked in · ${timeOfDay(entry.arrivedAt!)}'),
      HistoryState.noShow => const StatusChip(StatusKind.noShow),
      HistoryState.booked => const StatusChip(StatusKind.booked,
          label: 'Booked · not attended yet'),
      HistoryState.cancelled => const StatusChip(StatusKind.cancelled),
    };
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 28,
            child: Column(children: [
              const SizedBox(height: 4),
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: active ? d.accentFill : d.inverseRaised,
                ),
                child: Center(
                  child: Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                        color: active ? const Color(0xFF0A0A0A) : d.textSecondary,
                        shape: BoxShape.circle),
                  ),
                ),
              ),
              Expanded(child: Container(width: 2, color: d.borderSubtle)),
            ]),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${monthShort(e.start)} ${e.start.day} · ${timeOfDay(e.start)}',
                      style: TextStyle(fontSize: 12, color: d.textSecondary)),
                  const SizedBox(height: 8),
                  Material(
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
                            Row(children: [
                              Expanded(
                                child: Text(e.title,
                                    style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w600,
                                        color: active
                                            ? Colors.white
                                            : d.textSecondary)),
                              ),
                              if (e.isPrivate)
                                const StatusChip(StatusKind.private),
                            ]),
                            const SizedBox(height: 10),
                            chip,
                            if (entry.state == HistoryState.noShow)
                              Padding(
                                padding: const EdgeInsets.only(top: 6),
                                child: Text(
                                    'Approved but not checked in. No-shows can\'t post about a session.',
                                    style: TextStyle(
                                        fontSize: 12, color: d.textSecondary)),
                              ),
                            if (entry.state == HistoryState.checkedIn &&
                                !e.isEnded(svc.now))
                              Padding(
                                padding: const EdgeInsets.only(top: 6),
                                child: Text(
                                    'You can share your experience after the session ends.',
                                    style: TextStyle(
                                        fontSize: 12, color: d.textSecondary)),
                              ),
                            if (entry.canPost ||
                                entry.canReview ||
                                entry.hasReviewed) ...[
                              const SizedBox(height: 12),
                              Wrap(spacing: 8, runSpacing: 8, children: [
                                if (entry.canPost)
                                  CarpsButton(
                                    label: 'Share experience',
                                    icon: CarpsIcons.shareFat,
                                    kind: CarpsButtonKind.secondary,
                                    height: 40,
                                    expand: false,
                                    onPressed: () => context
                                        .push('/compose?event=${e.id}'),
                                  ),
                                if (entry.canReview)
                                  CarpsButton(
                                    label: 'Rate event',
                                    icon: CarpsIcons.star,
                                    kind: CarpsButtonKind.inverse,
                                    height: 40,
                                    expand: false,
                                    onPressed: () => context
                                        .push('/event/${e.id}/reviews'),
                                  ),
                                if (entry.hasReviewed)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 14, vertical: 10),
                                    decoration: BoxDecoration(
                                        color: d.canvas,
                                        borderRadius:
                                            BorderRadius.circular(999)),
                                    child: Text(
                                        'Rated ${svc.repo.reviews.firstWhere((r) => r.eventId == e.id && r.authorId == context.app.me!.id).rating}.0 ★',
                                        style: TextStyle(
                                            color: d.accentOnInverse,
                                            fontSize: 13)),
                                  ),
                              ]),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
