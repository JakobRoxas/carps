import 'package:flutter/material.dart';
import '../../core/carps_icons.dart';

import '../../controllers/app_controller.dart';
import '../../core/format.dart';
import '../../core/theme/carps_colors.dart';
import '../../core/widgets/carps_widgets.dart';

/// Figma 16 · Host Analytics: turnout vs confirmed RSVPs, posts, comments,
/// reviews. Shows "Not available" / "No reviews yet" instead of zeros.
class AnalyticsView extends StatefulWidget {
  const AnalyticsView({super.key, required this.eventId});
  final String eventId;
  @override
  State<AnalyticsView> createState() => _AnalyticsViewState();
}

class _AnalyticsViewState extends State<AnalyticsView> {
  late String _eventId = widget.eventId;

  @override
  Widget build(BuildContext context) {
    final app = context.app;
    final svc = app.service;
    final me = app.me!;
    final event = svc.repo.event(_eventId);
    if (event == null || !event.isHostingTeam(me.id)) {
      return const CarpsPage(title: 'Host analytics', children: [
        EmptyState(
            title: 'Hosting team only',
            message: 'Analytics are visible to the builder and co-hosts.'),
      ]);
    }
    final a = svc.analyticsFor(me.id, event.id);
    final hosted = svc.hostingEvents(me.id);
    final turnout = a.turnout;
    final avg = a.averageRating;

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(children: [
          BackHeader(title: 'Host analytics'),
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
                                Text('Host Analytics',
                                    style: Theme.of(context)
                                        .textTheme
                                        .headlineLarge),
                                const Spacer(),
                                TintPill(event.isEnded(svc.now)
                                    ? 'Recap'
                                    : 'Live'),
                              ]),
                              const SizedBox(height: 12),
                              DropdownButtonFormField<String>(
                                initialValue: _eventId,
                                isExpanded: true,
                                decoration: const InputDecoration(
                                  prefixIcon: Icon(
                                      CarpsIcons.calendarBlank,
                                      size: 20),
                                ),
                                items: [
                                  for (final e in hosted)
                                    DropdownMenuItem(
                                        value: e.id,
                                        child: Text(
                                            '${e.title} · ${shortDate(e.start)}',
                                            overflow: TextOverflow.ellipsis)),
                                ],
                                onChanged: (v) => setState(() => _eventId = v!),
                              ),
                            ],
                          ),
                        ),
                        DarkSheet(
                          fill: true,
                          child: Builder(builder: (context) {
                            final d = context.carps;
                            Widget stat(String label, String value,
                                    {bool accent = false, String? hint}) =>
                                Expanded(
                                  child: Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                        color: d.inverseRaised,
                                        borderRadius:
                                            BorderRadius.circular(20)),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        CaptionLabel(label),
                                        const SizedBox(height: 8),
                                        Text(value,
                                            style: TextStyle(
                                                fontSize:
                                                    value.length > 6 ? 16 : 28,
                                                fontWeight: FontWeight.w600,
                                                color: accent
                                                    ? d.accentOnInverse
                                                    : Colors.white)),
                                        if (hint != null)
                                          Text(hint,
                                              style: TextStyle(
                                                  fontSize: 11,
                                                  color: d.textSecondary)),
                                      ],
                                    ),
                                  ),
                                );
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Row(children: [
                                  stat(
                                      'Turnout',
                                      turnout == null
                                          ? 'Not available'
                                          : '${(turnout * 100).round()}%',
                                      hint: turnout == null
                                          ? 'No confirmed RSVPs'
                                          : null),
                                  const SizedBox(width: 10),
                                  stat(
                                      'Avg rating',
                                      avg == null
                                          ? 'No reviews yet'
                                          : '${avg.toStringAsFixed(1)}/5',
                                      accent: true),
                                  const SizedBox(width: 10),
                                  stat('Posts', '${a.postCount}',
                                      hint: '${a.commentCount} comments'),
                                ]),
                                const SizedBox(height: 12),
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                      color: d.inverseRaised,
                                      borderRadius: BorderRadius.circular(20)),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(children: [
                                        Text('RSVPs vs Arrivals',
                                            style: Theme.of(context)
                                                .textTheme
                                                .titleLarge),
                                        const Spacer(),
                                        if (a.pendingCount > 0)
                                          Text('${a.pendingCount} pending',
                                              style: TextStyle(
                                                  fontSize: 12,
                                                  color: d.textSecondary)),
                                      ]),
                                      const SizedBox(height: 12),
                                      Row(children: [
                                        Text(
                                            '${a.confirmedAtStart} confirmed RSVPs',
                                            style: TextStyle(
                                                color: d.textSecondary)),
                                        const Spacer(),
                                        Text('${a.arrivals} checked in',
                                            style: const TextStyle(
                                                fontWeight: FontWeight.w600)),
                                      ]),
                                      const SizedBox(height: 10),
                                      ClipRRect(
                                        borderRadius:
                                            BorderRadius.circular(999),
                                        child: LinearProgressIndicator(
                                          value: turnout ?? 0,
                                          minHeight: 10,
                                          backgroundColor: d.canvas,
                                          color: d.success,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                          'Turnout counts checked-in registrants against approved RSVPs. A participating host is not counted unless registered.',
                                          style: TextStyle(
                                              fontSize: 11,
                                              color: d.textSecondary)),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                      color: d.inverseRaised,
                                      borderRadius: BorderRadius.circular(20)),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(children: [
                                        Text('Rating breakdown',
                                            style: Theme.of(context)
                                                .textTheme
                                                .titleLarge),
                                        const Spacer(),
                                        Text(
                                            avg == null
                                                ? 'No reviews yet'
                                                : '${avg.toStringAsFixed(1)} · ${a.reviewCount} ${a.reviewCount == 1 ? 'review' : 'reviews'}',
                                            style: TextStyle(
                                                color: d.accentOnInverse,
                                                fontSize: 12)),
                                      ]),
                                      const SizedBox(height: 12),
                                      for (var s = 5; s >= 1; s--)
                                        Padding(
                                          padding:
                                              const EdgeInsets.only(bottom: 8),
                                          child: Row(children: [
                                            SizedBox(
                                                width: 28,
                                                child: Text('$s★',
                                                    style: const TextStyle(
                                                        fontSize: 12))),
                                            Expanded(
                                              child: ClipRRect(
                                                borderRadius:
                                                    BorderRadius.circular(999),
                                                child: LinearProgressIndicator(
                                                  value: a.reviewCount == 0
                                                      ? 0
                                                      : a.ratingBreakdown[s - 1] /
                                                          a.reviewCount,
                                                  minHeight: 8,
                                                  backgroundColor: d.canvas,
                                                  color: d.accentOnInverse,
                                                ),
                                              ),
                                            ),
                                            SizedBox(
                                                width: 28,
                                                child: Text(
                                                    '${a.ratingBreakdown[s - 1]}',
                                                    textAlign: TextAlign.right,
                                                    style: TextStyle(
                                                        fontSize: 12,
                                                        color: d
                                                            .textSecondary))),
                                          ]),
                                        ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 16),
                                CarpsButton(
                                  label: 'Export attendance CSV',
                                  icon: CarpsIcons.downloadSimple,
                                  kind: CarpsButtonKind.inverse,
                                  onPressed: () => showCarpsSnack(context,
                                      'Export is simulated in this build.'),
                                ),
                                const SizedBox(height: 6),
                                const Center(child: SimulatedTag()),
                              ],
                            );
                          }),
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

