import 'package:flutter/material.dart';
import '../../core/carps_icons.dart';

import '../../controllers/app_controller.dart';
import '../../core/theme/carps_colors.dart';
import '../../core/widgets/carps_widgets.dart';
import 'event_detail_view.dart' show ReviewTile;

/// Figma 21 · Event Reviews. One rating + review per verified attendee after
/// the session ends. Separate from experience posts.
class ReviewsView extends StatefulWidget {
  const ReviewsView({super.key, required this.eventId});
  final String eventId;
  @override
  State<ReviewsView> createState() => _ReviewsViewState();
}

class _ReviewsViewState extends State<ReviewsView> {
  int _rating = 0;
  final _text = TextEditingController();

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final app = context.app;
    final svc = app.events;
    final me = app.me!;
    final event = app.data.eventById(widget.eventId);
    if (event == null || !svc.canViewPrivateSocial(me.id, event)) {
      return const CarpsPage(title: 'Event reviews', children: [
        EmptyState(
            title: 'Reviews not available',
            message:
                'Reviews of private sessions are visible only to the hosting team and verified attendees.'),
      ]);
    }
    final summary = svc.ratingSummary(me.id, event.id);
    final reviews = svc.visibleReviews(me.id, event.id);
    final host = app.data.userById(event.hostId);
    final canReview = svc.canReview(me.id, event);
    final blocker = svc.postBlocker(me.id, event);
    final c = context.carps;

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(children: [
          BackHeader(title: 'Event reviews'),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
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
                              Text('Event Reviews',
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineLarge),
                              Text(
                                  '${event.title} · ${host?.builderName ?? host?.displayName}',
                                  style: TextStyle(color: c.textSecondary)),
                              const SizedBox(height: 12),
                              if (summary.average == null)
                                Text('No reviews yet',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleLarge)
                              else
                                Row(children: [
                                  Text(summary.average!.toStringAsFixed(1),
                                      style: Theme.of(context)
                                          .textTheme
                                          .displayLarge),
                                  const SizedBox(width: 12),
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(children: [
                                        for (var i = 1; i <= 5; i++)
                                          Icon(
                                              i <= summary.average!.round()
                                                  ? CarpsIcons.starFill
                                                  : CarpsIcons.star,
                                              color: c.accentFill,
                                              size: 18),
                                      ]),
                                      Text(
                                          '${summary.count} verified ${summary.count == 1 ? 'review' : 'reviews'}',
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodySmall),
                                    ],
                                  ),
                                ]),
                            ],
                          ),
                        ),
                        DarkSheet(
                          fill: true,
                          child: Builder(builder: (context) {
                            final d = context.carps;
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                if (canReview)
                                  Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                        color: d.inverseRaised,
                                        borderRadius:
                                            BorderRadius.circular(24)),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.stretch,
                                      children: [
                                        Row(children: [
                                          Text('Write a review',
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .titleLarge),
                                          const Spacer(),
                                          Text(
                                              _rating == 0
                                                  ? 'Tap a star'
                                                  : '$_rating / 5',
                                              style: TextStyle(
                                                  color: d.accentOnInverse)),
                                        ]),
                                        const SizedBox(height: 12),
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceEvenly,
                                          children: [
                                            for (var i = 1; i <= 5; i++)
                                              IconButton(
                                                tooltip:
                                                    '$i star${i == 1 ? '' : 's'}',
                                                iconSize: 32,
                                                onPressed: () => setState(
                                                    () => _rating = i),
                                                icon: Icon(
                                                    i <= _rating
                                                        ? CarpsIcons.starFill
                                                        : CarpsIcons.star,
                                                    color: i <= _rating
                                                        ? d.accentOnInverse
                                                        : d.borderStrong),
                                              ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        TextField(
                                          controller: _text,
                                          maxLines: 3,
                                          decoration: const InputDecoration(
                                              hintText:
                                                  'Share your honest feedback…',
                                              fillColor: Color(0xFF0A0A0A)),
                                        ),
                                        const SizedBox(height: 8),
                                        Row(children: [
                                          Icon(
                                              event.isPrivate
                                                  ? CarpsIcons.lockSimple
                                                  : CarpsIcons.globeSimple,
                                              size: 14,
                                              color: d.textSecondary),
                                          const SizedBox(width: 6),
                                          Expanded(
                                            child: Text(
                                                event.isPrivate
                                                    ? 'Audience: hosting team and verified attendees only'
                                                    : 'Audience: anyone viewing this public event',
                                                style: TextStyle(
                                                    fontSize: 12,
                                                    color: d.textSecondary)),
                                          ),
                                        ]),
                                        const SizedBox(height: 12),
                                        CarpsButton(
                                          label: 'Submit review',
                                          trailingArrow: true,
                                          onPressed: _rating == 0
                                              ? null
                                              : () {
                                                  if (runAction(
                                                      context,
                                                      () => svc.submitReview(
                                                          me.id,
                                                          event.id,
                                                          _rating,
                                                          _text.text),
                                                      success:
                                                          'Thanks! Your review is posted. It doesn\'t create a profile post.')) {
                                                    _text.clear();
                                                    setState(() => _rating = 0);
                                                  }
                                                },
                                        ),
                                      ],
                                    ),
                                  )
                                else
                                  Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                        color: d.inverseRaised,
                                        borderRadius:
                                            BorderRadius.circular(20)),
                                    child: Row(children: [
                                      Icon(CarpsIcons.info,
                                          color: d.textSecondary),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                            reviews.any((r) => r.authorId == me.id)
                                                ? 'You already reviewed this session.'
                                                : (blocker ??
                                                        'Only verified attendees can review.')
                                                    .replaceAll('post', 'review'),
                                            style: TextStyle(
                                                color: d.textSecondary)),
                                      ),
                                    ]),
                                  ),
                                const SizedBox(height: 24),
                                Row(children: [
                                  Text('Attendee reviews',
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleLarge),
                                  const Spacer(),
                                  Text('Most recent',
                                      style: TextStyle(
                                          color: d.textSecondary,
                                          fontSize: 12)),
                                ]),
                                const SizedBox(height: 12),
                                if (reviews.isEmpty)
                                  const EmptyState(
                                      title: 'No reviews yet',
                                      message:
                                          'Verified attendees can rate this session after it ends.'),
                                for (final r in reviews) ReviewTile(review: r),
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
