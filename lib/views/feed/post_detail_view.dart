import 'package:flutter/material.dart';
import '../../core/carps_icons.dart';

import '../../controllers/app_controller.dart';
import '../../core/format.dart';
import '../../core/theme/carps_colors.dart';
import '../../core/widgets/carps_widgets.dart';
import '../../core/widgets/post_card.dart';
import '../../models/carps_models.dart';

/// Post detail, likes and threaded comments (derived; no Figma frame 20).
/// Unauthorized viewers of a private post see no content, event or counts.
class PostDetailView extends StatefulWidget {
  const PostDetailView({super.key, required this.postId});
  final String postId;
  @override
  State<PostDetailView> createState() => _PostDetailViewState();
}

class _PostDetailViewState extends State<PostDetailView> {
  final _comment = TextEditingController();
  String? _replyTo;

  @override
  void dispose() {
    _comment.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final app = context.app;
    final svc = app.feed;
    final me = app.me!;
    final post = app.data.postById(widget.postId);
    final c = context.carps;
    if (post == null || !svc.canViewPost(me.id, post)) {
      // Same message whether it was deleted or is private: no leak.
      return const CarpsPage(title: 'Post', children: [
        SizedBox(height: 24),
        EmptyState(
            title: 'Post unavailable',
            message:
                'This post was deleted or you don\'t have access to it. Posts from private sessions are visible only to the hosting team and verified attendees.'),
      ]);
    }
    final top = post.comments.where((x) => x.parentId == null).toList();
    List<PostComment> replies(String id) =>
        post.comments.where((x) => x.parentId == id).toList();

    Widget commentTile(PostComment cm, {bool reply = false}) {
      final author = app.data.userById(cm.authorId);
      return Padding(
        padding: EdgeInsets.only(left: reply ? 44 : 0, bottom: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CarpsAvatar(user: author, size: reply ? 28 : 34),
            const SizedBox(width: 10),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                    color: c.canvas, borderRadius: BorderRadius.circular(16)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Text(author?.displayName ?? 'Member',
                          style: Theme.of(context).textTheme.titleSmall),
                      const SizedBox(width: 6),
                      Text(relative(cm.createdAt, svc.now),
                          style: Theme.of(context).textTheme.bodySmall),
                    ]),
                    const SizedBox(height: 2),
                    Text(cm.body),
                    if (!reply)
                      TextButton(
                        style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            minimumSize: const Size(0, 32)),
                        onPressed: () => setState(() => _replyTo = cm.id),
                        child: const Text('Reply'),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    final replyingTo = _replyTo == null
        ? null
        : post.comments.where((x) => x.id == _replyTo).firstOrNull;

    return CarpsPage(
      title: 'Post',
      bottomBar: Column(mainAxisSize: MainAxisSize.min, children: [
        if (replyingTo != null)
          Row(children: [
            Text(
                'Replying to ${app.data.userById(replyingTo.authorId)?.displayName}',
                style: Theme.of(context).textTheme.bodySmall),
            const Spacer(),
            TextButton(
                onPressed: () => setState(() => _replyTo = null),
                child: const Text('Cancel')),
          ]),
        Row(children: [
          CarpsAvatar(user: me, size: 36),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: _comment,
              decoration: InputDecoration(
                hintText: app.data.eventById(post.eventId)!.isPrivate
                    ? 'Comment (visible to this private session only)'
                    : 'Add a comment…',
              ),
              onSubmitted: (_) => _send(post),
            ),
          ),
          const SizedBox(width: 8),
          CircleIconButton(
            icon: CarpsIcons.paperPlaneRightFill,
            tooltip: 'Send comment',
            background: c.accentFill,
            foreground: c.onAccent,
            onPressed: () => _send(post),
          ),
        ]),
      ]),
      children: [
        PostCard(post: post),
        const SizedBox(height: 8),
        Row(children: [
          Icon(CarpsIcons.info, size: 14, color: c.textSecondary),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
                'Likes and comments never create posts on your profile. Reposting isn\'t available.',
                style: Theme.of(context).textTheme.bodySmall),
          ),
        ]),
        const SizedBox(height: 20),
        Text('Comments (${post.comments.length})',
            style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 12),
        if (top.isEmpty)
          Text('Be the first to comment.',
              style: Theme.of(context).textTheme.bodySmall),
        for (final cm in top) ...[
          commentTile(cm),
          for (final r in replies(cm.id)) commentTile(r, reply: true),
        ],
      ],
    );
  }

  void _send(ExperiencePost post) {
    final app = context.appRead;
    if (runAction(
        context,
        () => app.feed
            .addComment(app.me!.id, post.id, _comment.text, parentId: _replyTo))) {
      _comment.clear();
      setState(() => _replyTo = null);
    }
  }
}
