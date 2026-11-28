part of 'carps_domain_operations.dart';

mixin SocialOperations on CarpsServiceBase, EventQueryOperations, RegistrationOperations, NotificationOperations {

  List<ExperiencePost> authoredPosts(String? viewerId, String profileId) =>
      _sorted(repo.posts.where(
          (p) => p.authorId == profileId && canViewPost(viewerId, p)));

  List<ExperiencePost> taggedPosts(String? viewerId, String profileId) =>
      _sorted(repo.posts.where((p) =>
          p.taggedIds.contains(profileId) && canViewPost(viewerId, p)));

  List<ExperiencePost> eventPosts(String? viewerId, String eventId) =>
      _sorted(repo.posts
          .where((p) => p.eventId == eventId && canViewPost(viewerId, p)));

  /// Feed: experience posts only (never upcoming listings), from builders the
  /// viewer follows, people they share sessions with, and public posts.
  List<ExperiencePost> feed(String viewerId) =>
      _sorted(repo.posts.where((p) => canViewPost(viewerId, p)));

  List<ExperiencePost> _sorted(Iterable<ExperiencePost> posts) =>
      posts.toList()..sort((a, b) => b.createdAt.compareTo(a.createdAt));

  bool canPostAbout(String userId, CarpsEvent event) =>
      !event.isCancelled &&
      event.isEnded(now) &&
      hasAttended(event.id, userId);

  /// Why [userId] cannot post about [event], for UI messages.
  String? postBlocker(String userId, CarpsEvent event) {
    if (event.isCancelled) return 'Cancelled sessions never qualify for posting.';
    if (!hasAttended(event.id, userId)) {
      return event.isHostingTeam(userId)
          ? 'Hosting alone does not count. Your presence must be recorded at check-in.'
          : 'Only checked-in attendees can post about this session.';
    }
    if (!event.isEnded(now)) return 'You can post once the session ends.';
    return null;
  }

  List<CarpsEvent> eligiblePostEvents(String userId) =>
      repo.events.where((e) => canPostAbout(userId, e)).toList()
        ..sort((a, b) => b.start.compareTo(a.start));

  /// Builder + accepted co-hosts + checked-in peers from that same session.
  List<UserProfile> tagCandidates(String eventId, String authorId) {
    final event = requireEvent(eventId);
    final ids = <String>{
      event.hostId,
      ...event.coHostIds,
      ...attendanceForEvent(eventId).map((a) => a.userId),
    }..remove(authorId);
    return ids.map(repo.user).whereType<UserProfile>().toList();
  }

  ExperiencePost publishPost({
    required String authorId,
    required String? eventId,
    required String body,
    String? photoAsset,
    List<String> taggedIds = const [],
  }) {
    if (eventId == null) {
      throw const RuleViolation('Choose the attended event this post is about.');
    }
    final event = requireEvent(eventId);
    final blocker = postBlocker(authorId, event);
    if (blocker != null) throw RuleViolation(blocker);
    if (body.trim().isEmpty) {
      throw RuleViolation(photoAsset == null
          ? 'Write about your experience.'
          : 'Add a caption to your photo.');
    }
    if (body.trim().length > 280) {
      throw const RuleViolation('Keep it under 280 characters.');
    }
    final allowed = tagCandidates(eventId, authorId).map((u) => u.id).toSet();
    final bad = taggedIds.where((id) => !allowed.contains(id));
    if (bad.isNotEmpty) {
      throw const RuleViolation(
          'You can only tag the builder and checked-in attendees of this session.');
    }
    final post = ExperiencePost(
      id: repo.nextId('post'),
      eventId: eventId,
      authorId: authorId,
      body: body.trim(),
      photoAsset: photoAsset,
      taggedIds: taggedIds.toSet().toList(),
      createdAt: now,
    );
    repo.savePost(post);
    for (final id in post.taggedIds) {
      _notify(id, NotificationKind.tagged,
          '${requireUser(authorId).displayName} tagged you',
          'In a post about ${event.title}',
          eventId: eventId, postId: post.id);
    }
    return post;
  }

  /// Who will be able to read a post about [event].
  String audienceLabel(CarpsEvent event) => event.isPrivate
      ? 'Only the hosting team and verified attendees of this private session. Tags never widen access.'
      : 'Everyone on CARPS. Appears on the event, your Posts and tagged profiles.';

  void deletePost(String actorId, String postId) {
    final post = repo.post(postId) ??
        (throw const RuleViolation('Post not found.'));
    if (post.authorId != actorId) {
      throw const RuleViolation('Only the author can delete this post.');
    }
    repo.deletePost(postId);
  }

  /// A tagged person removes their own tag; the post itself stays.
  void removeTag(String actorId, String postId) {
    final post = repo.post(postId) ??
        (throw const RuleViolation('Post not found.'));
    if (!post.taggedIds.contains(actorId)) {
      throw const RuleViolation('You are not tagged in this post.');
    }
    repo.savePost(post.copyWith(
        taggedIds: post.taggedIds.where((id) => id != actorId).toList()));
  }

  void toggleLike(String viewerId, String postId) {
    final post = repo.post(postId) ??
        (throw const RuleViolation('Post not found.'));
    if (!canViewPost(viewerId, post)) {
      throw const RuleViolation('You do not have access to this post.');
    }
    final likes = [...post.likedByIds];
    likes.contains(viewerId) ? likes.remove(viewerId) : likes.add(viewerId);
    repo.savePost(post.copyWith(likedByIds: likes));
  }

  void addComment(String viewerId, String postId, String body,
      {String? parentId}) {
    final post = repo.post(postId) ??
        (throw const RuleViolation('Post not found.'));
    if (!canViewPost(viewerId, post)) {
      throw const RuleViolation('You do not have access to this post.');
    }
    if (body.trim().isEmpty) throw const RuleViolation('Write a comment first.');
    repo.savePost(post.copyWith(comments: [
      ...post.comments,
      PostComment(
        id: repo.nextId('cmt'),
        authorId: viewerId,
        body: body.trim(),
        createdAt: now,
        parentId: parentId,
      ),
    ]));
    if (post.authorId != viewerId) {
      _notify(post.authorId, NotificationKind.comment,
          '${requireUser(viewerId).displayName} commented', body.trim(),
          postId: postId, eventId: post.eventId);
    }
  }

  // ---------------------------------------------------------------------------
  // Reviews (separate from posts)
  // ---------------------------------------------------------------------------

  bool canReview(String userId, CarpsEvent event) =>
      canPostAbout(userId, event) &&
      !repo.reviews
          .any((r) => r.eventId == event.id && r.authorId == userId);

  List<EventReview> visibleReviews(String? viewerId, String eventId) {
    final event = repo.event(eventId);
    if (event == null || !canViewPrivateSocial(viewerId, event)) return [];
    return repo.reviews.where((r) => r.eventId == eventId).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  EventReview submitReview(
      String userId, String eventId, int rating, String text) {
    final event = requireEvent(eventId);
    if (rating < 1 || rating > 5) {
      throw const RuleViolation('Choose a rating from 1 to 5 stars.');
    }
    if (repo.reviews.any((r) => r.eventId == eventId && r.authorId == userId)) {
      throw const RuleViolation('You already reviewed this session.');
    }
    final blocker = postBlocker(userId, event);
    if (blocker != null) {
      throw RuleViolation(blocker.replaceAll('post', 'review'));
    }
    final review = EventReview(
      id: 'review_${eventId}_$userId',
      eventId: eventId,
      authorId: userId,
      rating: rating,
      text: text.trim(),
      createdAt: now,
    );
    repo.saveReview(review);
    return review;
  }

  ({double? average, int count}) ratingSummary(String? viewerId, String eventId) {
    final list = visibleReviews(viewerId, eventId);
    if (list.isEmpty) return (average: null, count: 0);
    final avg = list.fold<int>(0, (s, r) => s + r.rating) / list.length;
    return (average: avg, count: list.length);
  }

  /// Aggregate rating across a builder's public sessions, for profiles.
  ({double? average, int count}) builderRating(String? viewerId, String builderId) {
    final list = repo.reviews.where((r) {
      final e = repo.event(r.eventId);
      return e != null &&
          e.hostId == builderId &&
          canViewPrivateSocial(viewerId, e);
    }).toList();
    if (list.isEmpty) return (average: null, count: 0);
    return (
      average: list.fold<int>(0, (s, r) => s + r.rating) / list.length,
      count: list.length
    );
  }
}
