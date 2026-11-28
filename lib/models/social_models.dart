class PostComment {
  const PostComment({
    required this.id,
    required this.authorId,
    required this.body,
    required this.createdAt,
    this.parentId,
  });

  final String id;
  final String authorId;
  final String body;
  final DateTime createdAt;

  /// Set for threaded replies.
  final String? parentId;
}

/// One experience post. The SAME record backs the event's Experiences tab,
/// the author's Posts tab and each tagged person's Tagged tab.
class ExperiencePost {
  const ExperiencePost({
    required this.id,
    required this.eventId,
    required this.authorId,
    required this.body,
    required this.createdAt,
    this.photoAsset,
    this.taggedIds = const [],
    this.likedByIds = const [],
    this.comments = const [],
  });

  final String id;
  final String eventId;
  final String authorId;

  /// Text, or the caption when a photo is attached.
  final String body;
  final String? photoAsset;
  final List<String> taggedIds;
  final List<String> likedByIds;
  final List<PostComment> comments;
  final DateTime createdAt;

  ExperiencePost copyWith({
    List<String>? taggedIds,
    List<String>? likedByIds,
    List<PostComment>? comments,
  }) => ExperiencePost(
    id: id,
    eventId: eventId,
    authorId: authorId,
    body: body,
    photoAsset: photoAsset,
    createdAt: createdAt,
    taggedIds: taggedIds ?? this.taggedIds,
    likedByIds: likedByIds ?? this.likedByIds,
    comments: comments ?? this.comments,
  );
}

/// Post-event rating/review. Separate from posts on purpose.
class EventReview {
  const EventReview({
    required this.id,
    required this.eventId,
    required this.authorId,
    required this.rating,
    required this.text,
    required this.createdAt,
  });

  final String id;
  final String eventId;
  final String authorId;
  final int rating;
  final String text;
  final DateTime createdAt;
}
