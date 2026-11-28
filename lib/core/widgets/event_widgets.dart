import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/carps_icons.dart';

import '../../controllers/app_controller.dart';
import '../../models/carps_models.dart';
import '../format.dart';
import '../theme/carps_colors.dart';

IconData topicIcon(String topic) => switch (topic) {
      'Tech & AI' => CarpsIcons.cpu,
      'Pickleball' => CarpsIcons.pingPong,
      'Food & Drinks' => CarpsIcons.forkKnife,
      'Chess & Board Games' => CarpsIcons.puzzlePiece,
      'Running & Fitness' => CarpsIcons.personSimpleRun,
      'Music & Gigs' => CarpsIcons.musicNotes,
      'Badminton' => CarpsIcons.racquet,
      'Design & Creative' => CarpsIcons.palette,
      'Coffee Crawls' => CarpsIcons.coffee,
      _ => CarpsIcons.usersThree,
    };

/// Cover image, or the DESIGN.md §7.2 placeholder when there is no photo.
class EventCover extends StatelessWidget {
  const EventCover({super.key, required this.event, this.height});
  final CarpsEvent event;
  final double? height;

  @override
  Widget build(BuildContext context) {
    if (event.coverAsset != null) {
      return Image.asset(event.coverAsset!,
          height: height, width: double.infinity, fit: BoxFit.cover);
    }
    return Container(
      height: height,
      width: double.infinity,
      color: const Color(0xFF1F1F1F),
      alignment: Alignment.center,
      child: Icon(topicIcon(event.topic),
          size: 40, color: const Color(0xFFA3A3A3)),
    );
  }
}

class _GlassPill extends StatelessWidget {
  const _GlassPill({required this.child, this.solid = false});
  final Widget child;
  final bool solid;
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: solid
              ? Colors.white
              : const Color(0xFF0A0A0A).withValues(alpha: 0.55),
          borderRadius: BorderRadius.circular(999),
        ),
        child: child,
      );
}

/// Photo event card from Figma 06 Home / 07 Search.
class EventPhotoCard extends StatelessWidget {
  const EventPhotoCard({super.key, required this.event, this.height = 224});
  final CarpsEvent event;
  final double height;

  @override
  Widget build(BuildContext context) {
    final app = context.app;
    final svc = app.events;
    final me = app.me;
    final going = svc.goingCount(event.id);
    final proof = me == null ? null : svc.socialProof(me.id, event);
    final left = event.capacity == null ? null : event.capacity! - going;
    final reg = me == null ? null : svc.registrationFor(event.id, me.id);
    const white = Colors.white;
    return Semantics(
      button: true,
      label:
          '${event.title}, ${dateTime(event.start)}, ${event.venue}, ${event.isPrivate ? 'private' : 'public'}, $going going',
      child: Material(
        borderRadius: BorderRadius.circular(24),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => context.push('/event/${event.id}'),
          child: SizedBox(
            height: height,
            child: Stack(
              fit: StackFit.expand,
              children: [
                EventCover(event: event),
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      stops: [0.25, 1],
                      colors: [Color(0x000A0A0A), Color(0xD90A0A0A)],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Align(
                              alignment: AlignmentDirectional.centerStart,
                              child: _GlassPill(
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(CarpsIcons.calendarBlankFill,
                                        size: 13, color: context.carps.accentOnInverse),
                                    const SizedBox(width: 6),
                                    Flexible(
                                      child: Text(tileDate(event.start),
                                          style: const TextStyle(
                                              color: white,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600)),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          if (reg != null && reg.status != RegistrationStatus.withdrawn) ...[
                            _GlassPill(
                              solid: true,
                              child: Text(
                                  switch (reg.status) {
                                    RegistrationStatus.pending => 'PENDING',
                                    RegistrationStatus.approved => 'APPROVED',
                                    RegistrationStatus.declined => 'DECLINED',
                                    RegistrationStatus.withdrawn => '',
                                  },
                                  style: TextStyle(
                                      color: context.carps.accentFill,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700)),
                            ),
                            const SizedBox(width: 6),
                          ] else if (left != null && left > 0 && left <= 5) ...[
                            _GlassPill(
                              solid: true,
                              child: Text('$left SPOTS LEFT',
                                  style: TextStyle(
                                      color: context.carps.accentFill,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700)),
                            ),
                            const SizedBox(width: 6),
                          ],
                          _GlassPill(
                            child: Row(mainAxisSize: MainAxisSize.min, children: [
                              Icon(
                                  event.isPrivate
                                      ? CarpsIcons.lockSimple
                                      : CarpsIcons.globeSimple,
                                  size: 12,
                                  color: white),
                              const SizedBox(width: 4),
                              Text(event.isPrivate ? 'Private' : 'Public',
                                  style: const TextStyle(
                                      color: white, fontSize: 12)),
                            ]),
                          ),
                        ],
                      ),
                      const Spacer(),
                      if (proof != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Row(children: [
                            const _AnonStack(),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(proof,
                                  style: const TextStyle(
                                      color: white, fontSize: 12)),
                            ),
                          ]),
                        ),
                      Text(event.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              color: white,
                              fontSize: 19,
                              height: 1.25,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.3)),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(CarpsIcons.mapPinFill,
                              size: 14, color: context.carps.accentOnInverse),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(event.venue,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    color: Color(0xFFE5E5E5), fontSize: 13)),
                          ),
                          const Icon(CarpsIcons.users,
                              size: 14, color: white),
                          const SizedBox(width: 4),
                          Text('$going going',
                              style: const TextStyle(
                                  color: white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Anonymous silhouettes: social proof never reveals names or faces.
class _AnonStack extends StatelessWidget {
  const _AnonStack();
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 52,
      height: 22,
      child: Stack(children: [
        for (var i = 0; i < 3; i++)
          Positioned(
            left: i * 15.0,
            child: Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: [
                  const Color(0xFFE8590C),
                  const Color(0xFFF5F5F5),
                  const Color(0xFFFFF1E8),
                ][i],
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 1.5),
              ),
              child: Icon(CarpsIcons.userFill,
                  size: 12,
                  color: i == 0 ? Colors.white : const Color(0xFF6B6B6B)),
            ),
          ),
      ]),
    );
  }
}

/// Compact row used in lists (profile events, history pickers, analytics).
class EventRowTile extends StatelessWidget {
  const EventRowTile({
    super.key,
    required this.event,
    this.trailing,
    this.subtitle,
    this.onTap,
    this.selected = false,
  });
  final CarpsEvent event;
  final Widget? trailing;
  final String? subtitle;
  final VoidCallback? onTap;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final c = context.carps;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: selected
          ? c.accentTint
          : (isDark ? c.inverseRaised : c.canvas),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap ?? () => context.push('/event/${event.id}'),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                    width: 56, height: 56, child: EventCover(event: event)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(event.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleSmall),
                    const SizedBox(height: 2),
                    Text(
                        subtitle ?? dateTime(event.start),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
              ),
              if (trailing != null) ...[const SizedBox(width: 8), trailing!],
            ],
          ),
        ),
      ),
    );
  }
}
