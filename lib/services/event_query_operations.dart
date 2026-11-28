part of 'carps_domain_operations.dart';

mixin EventQueryOperations on CarpsServiceBase {
  UserProfile requireUser(String id) =>
      repo.user(id) ?? (throw const RuleViolation('Account not found.'));

  CarpsEvent requireEvent(String id) =>
      repo.event(id) ?? (throw const RuleViolation('Event not found.'));

  Registration? registrationFor(String eventId, String userId) {
    for (final r in repo.registrations) {
      if (r.eventId == eventId && r.userId == userId) return r;
    }
    return null;
  }

  Attendance? attendanceFor(String eventId, String userId) {
    for (final a in repo.attendance) {
      if (a.eventId == eventId && a.userId == userId) return a;
    }
    return null;
  }

  bool hasAttended(String eventId, String userId) =>
      attendanceFor(eventId, userId) != null;

  Invitation? guestInvitation(String eventId, String userId) {
    for (final i in repo.invitations) {
      if (i.eventId == eventId &&
          i.inviteeId == userId &&
          i.kind == InvitationKind.guest) {
        return i;
      }
    }
    return null;
  }

  Invitation? coHostInvitation(String eventId, String userId) {
    for (final i in repo.invitations) {
      if (i.eventId == eventId &&
          i.inviteeId == userId &&
          i.kind == InvitationKind.coHost) {
        return i;
      }
    }
    return null;
  }

  List<Registration> registrationsForEvent(String eventId) =>
      repo.registrations.where((r) => r.eventId == eventId).toList()
        ..sort((a, b) => a.requestedAt.compareTo(b.requestedAt));

  List<Attendance> attendanceForEvent(String eventId) =>
      repo.attendance.where((a) => a.eventId == eventId).toList()
        ..sort((a, b) => a.arrivedAt.compareTo(b.arrivedAt));

  int goingCount(String eventId) => repo.registrations
      .where(
        (r) => r.eventId == eventId && r.status == RegistrationStatus.approved,
      )
      .length;

  /// The valid pass for this guest and event, or null (pending, declined,
  /// withdrawn and cancelled-event guests have no pass).
  GuestPass? passFor(String eventId, String userId) {
    final reg = registrationFor(eventId, userId);
    if (reg == null ||
        reg.status != RegistrationStatus.approved ||
        reg.passId == null) {
      return null;
    }
    final event = repo.event(eventId);
    if (event == null || event.isCancelled) return null;
    for (final p in repo.passes) {
      if (p.id == reg.passId && !p.revoked) return p;
    }
    return null;
  }

  // ---------------------------------------------------------------------------
  // Visibility
  // ---------------------------------------------------------------------------

  /// Whether [viewerId] (null = signed out) may see this listing at all.
  bool canViewEvent(String? viewerId, CarpsEvent event) {
    if (!event.isPrivate) return true;
    if (viewerId == null) return false;
    if (event.isHostingTeam(viewerId)) return true;
    if (guestInvitation(event.id, viewerId) != null) return true;
    if (coHostInvitation(event.id, viewerId) != null) return true;
    if (registrationFor(event.id, viewerId) != null) return true;
    return false;
  }

  /// Private social content (posts, reviews, comments) is limited to the
  /// hosting team and VERIFIED attendees. Invitations, tags and follows never
  /// widen access.
  bool canViewPrivateSocial(String? viewerId, CarpsEvent event) {
    if (!event.isPrivate) return true;
    if (viewerId == null) return false;
    return event.isHostingTeam(viewerId) || hasAttended(event.id, viewerId);
  }

  bool canViewPost(String? viewerId, ExperiencePost post) {
    final event = repo.event(post.eventId);
    if (event == null) return false;
    return canViewPrivateSocial(viewerId, event);
  }

  List<CarpsEvent> discoverableEvents(String? viewerId) {
    return repo.events
        .where((e) => !e.isPrivate && !e.isCancelled && !e.isEnded(now))
        .toList()
      ..sort((a, b) => a.start.compareTo(b.start));
  }

  /// "For You": public upcoming events ranked by interests, followed builders,
  /// area and previous RSVPs. With no signals, falls back to date order.
  List<CarpsEvent> forYou(String viewerId) {
    final viewer = repo.user(viewerId);
    final list = discoverableEvents(viewerId);
    if (viewer == null) return list;
    final pastBuilderIds = repo.registrations
        .where((r) => r.userId == viewerId)
        .map((r) => repo.event(r.eventId)?.hostId)
        .whereType<String>()
        .toSet();
    int score(CarpsEvent e) {
      var s = 0;
      if (viewer.interests.contains(e.topic)) s += 30;
      if (viewer.followingIds.contains(e.hostId)) s += 40;
      if (viewer.area != null && e.area == viewer.area) s += 15;
      if (pastBuilderIds.contains(e.hostId)) s += 10;
      return s;
    }

    final hasSignals = list.any((e) => score(e) > 0);
    if (!hasSignals) return list;
    list.sort((a, b) {
      final d = score(b).compareTo(score(a));
      return d != 0 ? d : a.start.compareTo(b.start);
    });
    return list;
  }

  /// Events the user hosts or co-hosts, including private ones (Hosting filter).
  List<CarpsEvent> hostingEvents(String userId) =>
      repo.events.where((e) => e.isHostingTeam(userId)).toList()
        ..sort((a, b) => b.start.compareTo(a.start));

  /// Social proof: only with ≥3 OTHER matching active RSVPs; never names.
  String? socialProof(String viewerId, CarpsEvent event) {
    final viewer = repo.user(viewerId);
    if (viewer == null) return null;
    final matching = repo.registrations.where((r) {
      if (r.eventId != event.id || r.userId == viewerId || !r.isActive) {
        return false;
      }
      final other = repo.user(r.userId);
      return other != null && other.interests.contains(event.topic);
    }).length;
    if (matching < 3) return null;
    return '3+ people who like ${event.topic.toLowerCase()} are going';
  }

  List<CarpsEvent> search({
    required String? viewerId,
    String query = '',
    Set<String> topics = const {},
    Set<String> areas = const {},
    DateTime? from,
    DateTime? to,
    String builderQuery = '',
  }) {
    final q = query.trim().toLowerCase();
    final bq = builderQuery.trim().toLowerCase();
    return discoverableEvents(viewerId).where((e) {
      final host = repo.user(e.hostId);
      final hostText =
          '${host?.displayName} ${host?.username} ${host?.builderName}'
              .toLowerCase();
      if (q.isNotEmpty &&
          !'${e.title} ${e.topic} ${e.area} ${e.venue} $hostText'
              .toLowerCase()
              .contains(q)) {
        return false;
      }
      if (topics.isNotEmpty && !topics.contains(e.topic)) return false;
      if (areas.isNotEmpty && !areas.contains(e.area)) return false;
      if (from != null && e.start.isBefore(from)) return false;
      if (to != null && !e.start.isBefore(to)) return false;
      if (bq.isNotEmpty && !hostText.contains(bq)) return false;
      return true;
    }).toList();
  }
}
