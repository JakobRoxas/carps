import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/carps_icons.dart';

import '../../controllers/app_controller.dart';
import '../../core/format.dart';
import '../../core/theme/carps_colors.dart';
import '../../core/widgets/carps_widgets.dart';
import '../../core/widgets/event_widgets.dart';
import '../../core/widgets/post_card.dart';
import '../../models/carps_models.dart';

/// Figma 09 · Profile (person or builder): stats, Events, Posts, Tagged.
/// Owners can preview their profile as a signed-out visitor to check privacy.
class ProfileView extends StatefulWidget {
  const ProfileView({super.key, this.userId});
  final String? userId;
  @override
  State<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<ProfileView> {
  int _tab = 0;
  bool _visitorPreview = false;

  @override
  Widget build(BuildContext context) {
    final app = context.app;
    final svc = app.profiles;
    final me = app.me!;
    final profileId = widget.userId ?? me.id;
    final user = app.data.userById(profileId);
    final c = context.carps;
    if (user == null) {
      return const CarpsPage(
        title: 'Profile',
        children: [
          EmptyState(
            title: 'Profile not found',
            message: 'This account may have been removed.',
          ),
        ],
      );
    }
    final isOwner = profileId == me.id;
    // Visitor preview = what a signed-out member of the public sees.
    final viewerId = isOwner && _visitorPreview ? null : me.id;
    final isBuilder = user.hostingEnabled;
    final events = svc.profileEvents(viewerId, profileId);
    final posts = svc.authoredPosts(viewerId, profileId);
    final tagged = svc.taggedPosts(viewerId, profileId);
    final rating = svc.builderRating(viewerId, profileId);
    final rsvpCount = app.data.registrations
        .where(
          (r) =>
              r.userId == me.id &&
              r.isActive &&
              !(app.data.eventById(r.eventId)?.isEnded(svc.now) ?? true),
        )
        .length;

    final tabLabels = [if (isBuilder) 'Events', 'Posts', 'Tagged'];
    final tab = _tab.clamp(0, tabLabels.length - 1);
    final tabName = tabLabels[tab];
    final standalone = widget.userId != null;

    final content = ListView(
      padding: EdgeInsets.zero,
      children: [
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Stack(
                            clipBehavior: Clip.none,
                            children: [
                              CarpsAvatar(
                                user: user,
                                size: 92,
                                borderRadius: BorderRadius.circular(24),
                              ),
                            ],
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Flexible(
                                      child: Text(
                                        user.displayName,
                                        overflow: TextOverflow.ellipsis,
                                        style: Theme.of(context)
                                            .textTheme
                                            .headlineMedium,
                                      ),
                                    ),
                                    if (isBuilder) ...[
                                      const SizedBox(width: 4),
                                      Icon(
                                        CarpsIcons.sealCheckFill,
                                        color: c.accentFill,
                                        size: 20,
                                      ),
                                    ],
                                  ],
                                ),
                                if (isBuilder)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 2),
                                    child: TintPill(
                                      rating.average == null
                                          ? 'Community Builder'
                                          : '${rating.average!.toStringAsFixed(1)} ★ Community Builder',
                                      icon: CarpsIcons.starFill,
                                    ),
                                  ),
                                const SizedBox(height: 4),
                                Text(
                                  '${user.handle}${isBuilder ? ' · ${user.builderName}' : ''}',
                                  style: TextStyle(
                                    color: c.textSecondary,
                                    fontSize: 13,
                                  ),
                                ),
                                if (user.area != null && user.area!.isNotEmpty)
                                  Row(
                                    children: [
                                      Icon(
                                        CarpsIcons.mapPin,
                                        size: 13,
                                        color: c.accentFill,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        user.area!,
                                        style: TextStyle(
                                          color: c.textSecondary,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      if (user.bio.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Text(
                          user.bio,
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                      ],
                      const SizedBox(height: 16),
                      SurfaceCard(
                        color: c.muted,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        child: Row(
                          children: [
                            _stat(
                              context,
                              '${svc.attendedCount(user.id)}',
                              'Attended',
                            ),
                            _stat(
                              context,
                              '${svc.hostedCount(user.id)}',
                              'Hosted',
                              accent: true,
                            ),
                            _stat(
                              context,
                              '${svc.followerCount(user.id)}',
                              'Followers',
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (isOwner)
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              _pill(
                                context,
                                CarpsIcons.pencilSimple,
                                'Edit profile',
                                () => context.push('/edit-profile'),
                              ),
                              _pill(
                                context,
                                CarpsIcons.calendarCheck,
                                'My RSVPs',
                                () => context.push('/rsvps'),
                                badge: rsvpCount > 0 ? '$rsvpCount' : null,
                              ),
                              _pill(
                                context,
                                CarpsIcons.clockCounterClockwise,
                                'Attendance history',
                                () => context.push('/history'),
                              ),
                              _pill(
                                context,
                                CarpsIcons.usersThree,
                                'Followed builders',
                                () => context.push('/followed'),
                              ),
                              if (!isBuilder)
                                _pill(
                                  context,
                                  CarpsIcons.lightning,
                                  'Enable hosting',
                                  () => context.push('/builder-setup'),
                                ),
                            ],
                          ),
                        )
                      else if (isBuilder)
                        Row(
                          children: [
                            Expanded(
                              child: CarpsButton(
                                label: me.followingIds.contains(user.id)
                                    ? 'Following'
                                    : 'Follow',
                                icon: me.followingIds.contains(user.id)
                                    ? CarpsIcons.check
                                    : CarpsIcons.userPlus,
                                kind: me.followingIds.contains(user.id)
                                    ? CarpsButtonKind.muted
                                    : CarpsButtonKind.inverse,
                                height: 44,
                                onPressed: () => runAction(
                                  context,
                                  () => svc.toggleFollow(me.id, user.id),
                                ),
                              ),
                            ),
                          ],
                        ),
                      if (!isOwner && isBuilder)
                        Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            'Following keeps you updated on new sessions. It never reserves a spot.',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                      if (isOwner) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: c.accentTint,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                CarpsIcons.eye,
                                size: 18,
                                color: c.accentText,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text.rich(
                                  TextSpan(
                                    children: [
                                      const TextSpan(text: 'Viewing as '),
                                      TextSpan(
                                        text: _visitorPreview
                                            ? 'Signed-out visitor'
                                            : 'Owner',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              TextButton(
                                onPressed: () => setState(
                                  () => _visitorPreview = !_visitorPreview,
                                ),
                                child: Text(
                                  _visitorPreview
                                      ? 'Back to owner'
                                      : 'Switch to visitor',
                                  style: TextStyle(
                                    color: c.accentText,
                                    decoration: TextDecoration.underline,
                                    decorationColor: c.accentText,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                DarkSheet(
                  fill: true,
                  child: Builder(
                    builder: (context) {
                      final d = context.carps;
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          SegmentedTabs(
                            labels: tabLabels,
                            selected: tab,
                            onChanged: (i) => setState(() => _tab = i),
                          ),
                          const SizedBox(height: 20),
                          if (tabName == 'Events')
                            ..._eventsTab(
                              context,
                              events,
                              isOwner && !_visitorPreview,
                            )
                          else if (tabName == 'Posts')
                            ..._postList(
                              context,
                              posts,
                              isOwner
                                  ? 'No posts yet. After a host checks you in and the session ends, share what it was like.'
                                  : 'No posts to show.',
                            )
                          else
                            ..._postList(
                              context,
                              tagged,
                              'No tagged posts to show. Posts from private sessions only appear for people who attended them.',
                            ),
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: d.inverseRaised,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 18,
                                  backgroundColor: d.accentTint,
                                  child: Icon(
                                    CarpsIcons.eye,
                                    size: 18,
                                    color: d.accentOnInverse,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      CaptionLabel(
                                        isOwner
                                            ? 'Profile visibility'
                                            : 'Visitor view',
                                        color: d.accentOnInverse,
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        isOwner
                                            ? (_visitorPreview
                                                  ? 'Showing only what a public visitor can see. Private events and posts stay hidden.'
                                                  : 'Switch to visitor view to check what other people can see.')
                                            : 'Private events and posts are hidden unless you have access.',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: d.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );

    if (standalone) {
      return Scaffold(
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              BackHeader(title: user.displayName),
              Expanded(child: content),
            ],
          ),
        ),
      );
    }
    return Column(
      children: [
        const CarpsTopBar(),
        Expanded(child: content),
      ],
    );
  }

  Widget _stat(
    BuildContext context,
    String value,
    String label, {
    bool accent = false,
  }) {
    final c = context.carps;
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w600,
              color: accent ? c.accentFill : c.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          CaptionLabel(label),
        ],
      ),
    );
  }

  Widget _pill(
    BuildContext context,
    IconData icon,
    String label,
    VoidCallback onTap, {
    String? badge,
  }) {
    final c = context.carps;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Material(
        color: c.canvas,
        shape: StadiumBorder(side: BorderSide(color: c.borderSubtle)),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              children: [
                Icon(icon, size: 18),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                if (badge != null) ...[
                  const SizedBox(width: 6),
                  CircleAvatar(
                    radius: 9,
                    backgroundColor: c.accentFill,
                    child: Text(
                      badge,
                      style: TextStyle(fontSize: 10, color: c.onAccent),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _eventsTab(
    BuildContext context,
    List<CarpsEvent> events,
    bool owner,
  ) {
    final svc = context.app.profiles;
    final d = context.carps;
    if (events.isEmpty) {
      return [
        EmptyState(
          title: owner ? 'No hosted events yet' : 'No featured events',
          message: owner
              ? 'Tap ＋ to publish one. Featured listings appear here for visitors.'
              : 'This builder hasn\'t featured upcoming listings.',
        ),
      ];
    }
    final upcoming =
        events.where((e) => !e.isEnded(svc.now) && !e.isCancelled).toList()
          ..sort((a, b) => a.start.compareTo(b.start));
    final next = upcoming.isEmpty ? null : upcoming.first;
    final rest = events.where((e) => e.id != next?.id).toList();
    return [
      Row(
        children: [
          Text(
            owner ? 'Hosted & upcoming' : 'Upcoming from this builder',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(width: 8),
          if (upcoming.isNotEmpty) TintPill('${upcoming.length} live'),
        ],
      ),
      const SizedBox(height: 12),
      if (next != null) ...[
        HighlightCard(
          padding: 16,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const CaptionLabel(
                    'Next hosted session',
                    color: Color(0xFFE8590C),
                  ),
                  const Spacer(),
                  StatusChip(
                    next.isPrivate ? StatusKind.private : StatusKind.public,
                  ),
                ],
              ),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: AspectRatio(
                  aspectRatio: 16 / 8,
                  child: EventCover(event: next),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                next.title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                '${dateTime(next.start)} · ${next.venue}',
                style: TextStyle(
                  fontSize: 12,
                  color: context.carps.textSecondary,
                ),
              ),
              const SizedBox(height: 12),
              if (owner)
                CarpsButton(
                  label:
                      'Manage guest roster (${svc.registrationsForEvent(next.id).where((r) => r.status == RegistrationStatus.pending).length} pending)',
                  icon: CarpsIcons.usersThree,
                  kind: CarpsButtonKind.inverse,
                  height: 46,
                  onPressed: () => context.push('/event/${next.id}/roster'),
                )
              else
                CarpsButton(
                  label: 'View event',
                  kind: CarpsButtonKind.inverse,
                  height: 46,
                  onPressed: () => context.push('/event/${next.id}'),
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),
      ],
      for (final e in rest) ...[
        EventRowTile(
          event: e,
          trailing: owner
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (e.featuredOnProfile)
                      const StatusChip(StatusKind.approved, label: 'Featured'),
                    if (e.isPrivate) ...[
                      const SizedBox(height: 4),
                      const StatusChip(StatusKind.private),
                    ],
                  ],
                )
              : (e.isEnded(svc.now)
                    ? const StatusChip(StatusKind.ended)
                    : null),
        ),
        const SizedBox(height: 10),
      ],
      Text(
        'Event listings are not posts and never appear in Posts or Tagged.',
        style: TextStyle(fontSize: 12, color: d.textSecondary),
      ),
    ];
  }

  List<Widget> _postList(
    BuildContext context,
    List<ExperiencePost> posts,
    String empty,
  ) {
    if (posts.isEmpty) {
      return [EmptyState(title: 'Nothing here yet', message: empty)];
    }
    return [
      for (final p in posts) ...[
        PostCard(post: p, compact: true),
        const SizedBox(height: 12),
      ],
    ];
  }
}
