class ForumPost {
  final String id;
  final String eventId;
  final String authorId;
  final String authorName;
  final String content;
  final String? mediaUrl;
  final DateTime createdAt;
  final List<ForumReply> replies;

  const ForumPost({
    required this.id,
    required this.eventId,
    required this.authorId,
    required this.authorName,
    required this.content,
    this.mediaUrl,
    required this.createdAt,
    this.replies = const [],
  });
}

class ForumReply {
  final String id;
  final String authorName;
  final String content;
  final DateTime createdAt;

  const ForumReply({
    required this.id,
    required this.authorName,
    required this.content,
    required this.createdAt,
  });
}

class EventReview {
  final String id;
  final String eventId;
  final String reviewerId;
  final String reviewerName;
  final int rating; // 1 to 5
  final String comment;

  const EventReview({
    required this.id,
    required this.eventId,
    required this.reviewerId,
    required this.reviewerName,
    required this.rating,
    required this.comment,
  });
}