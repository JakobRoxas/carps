import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/carps_icons.dart';

import '../../controllers/app_controller.dart';
import '../../core/theme/carps_colors.dart';
import '../../core/widgets/carps_widgets.dart';
import '../../models/carps_models.dart';

/// Figma 12 · Followed Builders.
class FollowedView extends StatelessWidget {
  const FollowedView({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.app;
    final svc = app.profiles;
    final me = app.me!;
    final c = context.carps;
    final builders = me.followingIds
        .map(app.data.userById)
        .whereType<UserProfile>()
        .where((u) => u.hostingEnabled)
        .toList();
    return CarpsPage(
      title: 'Followed builders',
      children: [
        Text('Community hosts and organizers you follow. Following never reserves a spot.',
            style: TextStyle(color: c.textSecondary)),
        const SizedBox(height: 16),
        if (builders.isEmpty)
          EmptyState(
            title: 'Not following anyone yet',
            message: 'Follow builders to keep up with their next sessions.',
            actionLabel: 'Find people',
            onAction: () => context.push('/search'),
          ),
        for (final b in builders) ...[
          Builder(builder: (context) {
            final rating = svc.builderRating(me.id, b.id);
            return SurfaceCard(
              onTap: () => context.push('/user/${b.id}'),
              child: Row(children: [
                CarpsAvatar(user: b, size: 64),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Flexible(
                          child: Text(b.displayName,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.w600)),
                        ),
                        const SizedBox(width: 4),
                        Icon(CarpsIcons.sealCheckFill,
                            size: 16, color: c.accentFill),
                      ]),
                      Text('${b.builderName} · ${b.area ?? ''}',
                          style: TextStyle(fontSize: 12, color: c.textSecondary)),
                      const SizedBox(height: 4),
                      Row(children: [
                        Icon(CarpsIcons.starFill, size: 12, color: c.accentFill),
                        const SizedBox(width: 4),
                        Text(
                            '${rating.average?.toStringAsFixed(1) ?? 'No reviews yet'} · ${svc.hostedCount(b.id)} hosted',
                            style: Theme.of(context).textTheme.bodySmall),
                      ]),
                    ],
                  ),
                ),
                CarpsButton(
                  label: 'Following',
                  icon: CarpsIcons.check,
                  kind: CarpsButtonKind.muted,
                  height: 38,
                  expand: false,
                  onPressed: () => runAction(
                      context, () => svc.toggleFollow(me.id, b.id),
                      success: 'Unfollowed ${b.displayName}'),
                ),
              ]),
            );
          }),
          const SizedBox(height: 10),
        ],
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
              color: const Color(0xFF0A0A0A),
              borderRadius: BorderRadius.circular(24)),
          child: Row(children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const TintPill('Host community'),
                  const SizedBox(height: 8),
                  const Text('Looking for new squads?',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w700)),
                  const SizedBox(height: 12),
                  CarpsButton(
                      label: 'Explore events',
                      trailingArrow: true,
                      height: 44,
                      expand: false,
                      onPressed: () => context.push('/search')),
                ],
              ),
            ),
            Image.asset('assets/images/carp_orange.png', width: 80),
          ]),
        ),
      ],
    );
  }
}
