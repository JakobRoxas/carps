part of 'carps_domain_operations.dart';

mixin ProfileOperations on CarpsServiceBase, EventQueryOperations, RegistrationOperations, SocialOperations {

  void toggleFollow(String userId, String builderId) {
    if (userId == builderId) {
      throw const RuleViolation('You cannot follow yourself.');
    }
    final user = requireUser(userId);
    final following = [...user.followingIds];
    following.contains(builderId)
        ? following.remove(builderId)
        : following.add(builderId);
    repo.saveUser(user.copyWith(followingIds: following));
  }

  int followerCount(String builderId) =>
      repo.users.where((u) => u.followingIds.contains(builderId)).length;

  /// Profile → Events. Visitors see featured listings they may view; the
  /// owner sees everything they host.
  List<CarpsEvent> profileEvents(String? viewerId, String profileId) {
    final owner = viewerId == profileId;
    return hostingEvents(profileId).where((e) {
      if (owner) return true;
      return e.featuredOnProfile && !e.isCancelled && canViewEvent(viewerId, e);
    }).toList();
  }

  int attendedCount(String userId) =>
      repo.attendance.where((a) => a.userId == userId).length;

  int hostedCount(String userId) =>
      hostingEvents(userId).where((e) => !e.isCancelled).length;

  List<HistoryEntry> historyFor(String userId) {
    final entries = <HistoryEntry>[];
    for (final reg in repo.registrations.where((r) =>
        r.userId == userId && r.status == RegistrationStatus.approved)) {
      final event = repo.event(reg.eventId);
      if (event == null) continue;
      final att = attendanceFor(event.id, userId);
      HistoryState state;
      if (event.isCancelled) {
        state = HistoryState.cancelled;
      } else if (att != null) {
        state = HistoryState.checkedIn;
      } else if (event.isEnded(now)) {
        state = HistoryState.noShow;
      } else {
        state = HistoryState.booked;
      }
      final reviewed = repo.reviews
          .any((r) => r.eventId == event.id && r.authorId == userId);
      entries.add(HistoryEntry(
        event: event,
        state: state,
        arrivedAt: att?.arrivedAt,
        canPost: canPostAbout(userId, event),
        canReview: canReview(userId, event),
        hasReviewed: reviewed,
      ));
    }
    // A participating host's own presence counts only if recorded.
    for (final a in repo.attendance.where((a) => a.userId == userId)) {
      if (entries.any((e) => e.event.id == a.eventId)) continue;
      final event = repo.event(a.eventId);
      if (event == null) continue;
      entries.add(HistoryEntry(
        event: event,
        state: event.isCancelled ? HistoryState.cancelled : HistoryState.checkedIn,
        arrivedAt: a.arrivedAt,
        canPost: canPostAbout(userId, event),
        canReview: canReview(userId, event),
      ));
    }
    entries.sort((a, b) => b.event.start.compareTo(a.event.start));
    return entries;
  }
}
