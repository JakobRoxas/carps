import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/carps_icons.dart';

import '../../controllers/app_controller.dart';
import '../../models/carps_models.dart';
import '../format.dart';
import '../theme/carps_colors.dart';
import 'carps_widgets.dart';

/// One experience post. The same widget renders the same record on the
/// event, the author's Posts tab, Tagged tabs, Feed and Post detail.
/// There is deliberately no repost control.
class PostCard extends StatelessWidget {
  const PostCard({super.key, required this.post, this.compact = false});
  final ExperiencePost post;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final app = context.app;
    final svc = app.feed;
    final me = app.me;
    final c = context.carps;
    final author = app.data.userById(post.authorId);
    final event = app.data.eventById(post.eventId);
    if (event == null || !svc.canViewPost(me?.id, post)) {
      return const SizedBox.shrink();
    }
    final tagged =
        post.taggedIds.map(app.data.userById).whereType<UserProfile>().toList();
    final liked = me != null && post.likedByIds.contains(me.id);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: isDark ? c.inverseRaised : c.canvas,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: compact ? () => context.push('/post/${post.id}') : null,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  InkWell(
                    customBorder: const CircleBorder(),
                    onTap: () => context.push('/user/${post.authorId}'),
                    child: CarpsAvatar(user: author, size: 40),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(author?.displayName ?? 'Member',
                            style: Theme.of(context).textTheme.titleSmall),
                        Text(relative(post.createdAt, svc.now),
                            style: Theme.of(context).textTheme.bodySmall),
                      ],
                    ),
                  ),
                  if (event.isPrivate) const StatusChip(StatusKind.private),
                  _PostMenu(post: post),
                ],
              ),
              const SizedBox(height: 10),
              // Mandatory linked-event chip (the publishing rule).
              Semantics(
                button: true,
                label: 'Posted about ${event.title}, ${shortDate(event.start)}',
                child: InkWell(
                  borderRadius: BorderRadius.circular(999),
                  onTap: () => context.push('/event/${event.id}'),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                        color: c.muted,
                        borderRadius: BorderRadius.circular(999)),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(CarpsIcons.calendarBlank,
                          size: 14, color: c.textSecondary),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                            'at ${event.title} · ${shortDate(event.start)}',
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: c.textPrimary)),
                      ),
                    ]),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Text(post.body,
                  maxLines: compact ? 4 : null,
                  overflow: compact ? TextOverflow.ellipsis : null,
                  style: Theme.of(context).textTheme.bodyLarge),
              if (post.photoAsset != null) ...[
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: AspectRatio(
                    aspectRatio: 16 / 9,
                    child: Image.asset(post.photoAsset!,
                        fit: BoxFit.cover,
                        semanticLabel: 'Photo shared by ${author?.displayName}'),
                  ),
                ),
              ],
              if (tagged.isNotEmpty) ...[
                const SizedBox(height: 10),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text('Tagged:',
                        style: Theme.of(context).textTheme.bodySmall),
                    for (final t in tagged)
                      InkWell(
                        onTap: () => context.push('/user/${t.id}'),
                        child: Text(t.handle,
                            style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: c.accentText)),
                      ),
                  ],
                ),
              ],
              const SizedBox(height: 8),
              Row(
                children: [
                  Semantics(
                    button: true,
                    toggled: liked,
                    label: liked ? 'Unlike' : 'Like',
                    child: TextButton.icon(
                      onPressed: me == null
                          ? null
                          : () => runAction(
                              context, () => svc.toggleLike(me.id, post.id)),
                      icon: Icon(
                          liked
                              ? CarpsIcons.heartFill
                              : CarpsIcons.heart,
                          size: 20,
                          color: liked ? c.accentFill : c.textSecondary),
                      label: Text('${post.likedByIds.length}',
                          style: TextStyle(color: c.textSecondary)),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () => context.push('/post/${post.id}'),
                    icon: Icon(CarpsIcons.chatCircle,
                        size: 20, color: c.textSecondary),
                    label: Text('${post.comments.length}',
                        style: TextStyle(color: c.textSecondary)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PostMenu extends StatelessWidget {
  const _PostMenu({required this.post});
  final ExperiencePost post;

  @override
  Widget build(BuildContext context) {
    final app = context.app;
    final me = app.me;
    if (me == null) return const SizedBox.shrink();
    final isAuthor = post.authorId == me.id;
    final isTagged = post.taggedIds.contains(me.id);
    if (!isAuthor && !isTagged) return const SizedBox(width: 8);
    return PopupMenuButton<String>(
      tooltip: 'Post options',
      icon: const Icon(CarpsIcons.dotsThree),
      onSelected: (v) async {
        if (v == 'delete') {
          final ok = await confirmDialog(context,
              title: 'Delete post?',
              message:
                  'It disappears from the event, your Posts and every Tagged tab.',
              confirmLabel: 'Delete',
              destructive: true);
          if (ok && context.mounted) {
            runAction(context, () => app.feed.deletePost(me.id, post.id),
                success: 'Post deleted everywhere');
            if (GoRouterState.of(context).uri.path.startsWith('/post/')) {
              context.pop();
            }
          }
        } else if (v == 'untag') {
          runAction(context, () => app.feed.removeTag(me.id, post.id),
              success: 'Tag removed. The post stays on the author\'s profile.');
        }
      },
      itemBuilder: (_) => [
        if (isAuthor)
          const PopupMenuItem(value: 'delete', child: Text('Delete post')),
        if (isTagged)
          const PopupMenuItem(value: 'untag', child: Text('Remove my tag')),
      ],
    );
  }
}
