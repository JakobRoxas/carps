import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/carps_icons.dart';

import '../../controllers/app_controller.dart';
import '../../core/theme/carps_colors.dart';
import '../../core/widgets/carps_widgets.dart';
import '../../core/widgets/post_card.dart';

/// Feed (derived; no Figma frame 23): experience posts from attended events.
/// Never shows upcoming listings: those live on Home.
class FeedView extends StatelessWidget {
  const FeedView({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.app;
    final me = app.me!;
    final posts = app.feed.feed(me.id);
    final c = context.carps;
    return Column(children: [
      const CarpsTopBar(),
      Expanded(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          children: [
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 640),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('Feed', style: Theme.of(context).textTheme.headlineLarge),
                    Text('What past sessions were like, from people who were there.',
                        style: TextStyle(color: c.textSecondary)),
                    const SizedBox(height: 16),
                    SurfaceCard(
                      onTap: () => context.push('/compose'),
                      child: Row(children: [
                        CarpsAvatar(user: me, size: 40),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text('Write a post about an event you attended…',
                              style: TextStyle(color: c.textSecondary)),
                        ),
                        Icon(CarpsIcons.pencilSimpleLine,
                            color: c.accentFill),
                      ]),
                    ),
                    const SizedBox(height: 16),
                    if (posts.isEmpty)
                      const EmptyState(
                          title: 'No experiences yet',
                          message:
                              'After you attend sessions, posts from fellow attendees and builders show up here.'),
                    for (final p in posts) ...[
                      PostCard(post: p, compact: true),
                      const SizedBox(height: 12),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    ]);
  }
}
