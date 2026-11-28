part of 'carps_domain_operations.dart';

mixin EventManagementOperations on CarpsServiceBase, EventQueryOperations, NotificationOperations {

  void _requireHostingTeam(String actorId, CarpsEvent event) {
    if (!event.isHostingTeam(actorId)) {
      throw const RuleViolation('Only the hosting team can do that.');
    }
  }

  String? validateEventDraft({
    required String title,
    required String venue,
    required DateTime start,
    required DateTime end,
    bool isNew = true,
  }) {
    if (title.trim().length < 4) return 'Give the event a title (4+ characters).';
    if (venue.trim().isEmpty) return 'Add a venue so guests know where to go.';
    if (!end.isAfter(start)) return 'End time must be after the start time.';
    if (isNew && start.isBefore(now)) return 'Start time must be in the future.';
    return null;
  }

  CarpsEvent createEvent({
    required String actorId,
    required String title,
    required String description,
    required String topic,
    required String venue,
    required String area,
    required DateTime start,
    required DateTime end,
    required EventVisibility visibility,
    String? coverAsset,
    int? capacity,
    bool featuredOnProfile = false,
  }) {
    final actor = requireUser(actorId);
    if (!actor.hostingEnabled) {
      throw const RuleViolation('Enable hosting tools to publish events.');
    }
    final error = validateEventDraft(
        title: title, venue: venue, start: start, end: end);
    if (error != null) throw RuleViolation(error);
    final event = CarpsEvent(
      id: repo.nextId('ev'),
      hostId: actorId,
      title: title.trim(),
      description: description.trim(),
      topic: topic,
      venue: venue.trim(),
      area: area,
      start: start,
      end: end,
      visibility: visibility,
      coverAsset: coverAsset,
      capacity: capacity,
      featuredOnProfile: featuredOnProfile,
    );
    repo.saveEvent(event);
    return event;
  }

  CarpsEvent updateEvent({
    required String actorId,
    required String eventId,
    required String title,
    required String description,
    required String topic,
    required String venue,
    required String area,
    required DateTime start,
    required DateTime end,
    required EventVisibility visibility,
    String? coverAsset,
    int? capacity,
    required bool featuredOnProfile,
  }) {
    final event = requireEvent(eventId);
    _requireHostingTeam(actorId, event);
    final error = validateEventDraft(
        title: title, venue: venue, start: start, end: end, isNew: false);
    if (error != null) throw RuleViolation(error);
    final venueChanged = venue.trim() != event.venue;
    var updated = event.copyWith(
      title: title.trim(),
      description: description.trim(),
      topic: topic,
      venue: venue.trim(),
      area: area,
      start: start,
      end: end,
      visibility: visibility,
      coverAsset: coverAsset,
      capacity: capacity,
      featuredOnProfile: featuredOnProfile,
    );
    repo.saveEvent(updated);
    if (venueChanged) {
      // A venue change is an event-management notice, never a social post.
      postNotice(actorId, eventId, 'Venue changed to ${venue.trim()}.',
          isVenueChange: true);
    }
    return repo.event(eventId)!;
  }

  void setFeatured(String actorId, String eventId, bool featured) {
    final event = requireEvent(eventId);
    if (event.hostId != actorId) {
      throw const RuleViolation('Only the builder can feature this listing.');
    }
    repo.saveEvent(event.copyWith(featuredOnProfile: featured));
  }

  void cancelEvent(String actorId, String eventId) {
    final event = requireEvent(eventId);
    _requireHostingTeam(actorId, event);
    if (event.isEnded(now)) {
      throw const RuleViolation('This event has already ended.');
    }
    repo.saveEvent(event.copyWith(status: EventStatus.cancelled));
    for (final r in registrationsForEvent(eventId).where((r) => r.isActive)) {
      _notify(r.userId, NotificationKind.cancelled,
          '${event.title} was cancelled',
          'The listing stays available so your link still works.',
          eventId: eventId);
    }
  }

  /// Event notice / venue change. Updates the listing; creates NO post.
  void postNotice(String actorId, String eventId, String text,
      {bool isVenueChange = false}) {
    final event = requireEvent(eventId);
    _requireHostingTeam(actorId, event);
    if (text.trim().isEmpty) throw const RuleViolation('Write the notice first.');
    final notice = EventNotice(
      id: repo.nextId('notice'),
      text: text.trim(),
      createdAt: now,
      isVenueChange: isVenueChange,
    );
    repo.saveEvent(event.copyWith(notices: [notice, ...event.notices]));
    for (final r in registrationsForEvent(eventId).where((r) => r.isActive)) {
      _notify(r.userId, NotificationKind.notice, 'Update: ${event.title}',
          text.trim(),
          eventId: eventId);
    }
  }

  /// Pre-event shoutout to APPROVED guests. Email is simulated only.
  int sendReminder(String actorId, String eventId, String text,
      {bool alsoEmail = false}) {
    final event = requireEvent(eventId);
    _requireHostingTeam(actorId, event);
    if (text.trim().isEmpty) throw const RuleViolation('Write the reminder first.');
    final approved = registrationsForEvent(eventId)
        .where((r) => r.status == RegistrationStatus.approved)
        .toList();
    for (final r in approved) {
      _notify(r.userId, NotificationKind.reminder, 'Reminder: ${event.title}',
          text.trim(),
          eventId: eventId, emailSimulated: alsoEmail);
    }
    return approved.length;
  }

  /// Co-host invitation. Only builders can co-host; tools unlock on accept.
  void inviteCoHost(String actorId, String eventId, String inviteeId) {
    final event = requireEvent(eventId);
    if (event.hostId != actorId) {
      throw const RuleViolation('Only the builder can invite co-hosts.');
    }
    final invitee = requireUser(inviteeId);
    if (!invitee.hostingEnabled) {
      throw const RuleViolation('Co-hosts need hosting tools enabled.');
    }
    if (event.isHostingTeam(inviteeId) ||
        coHostInvitation(eventId, inviteeId) != null) {
      throw const RuleViolation('Already invited as co-host.');
    }
    repo.saveInvitation(Invitation(
      id: repo.nextId('inv'),
      eventId: eventId,
      inviteeId: inviteeId,
      invitedById: actorId,
      kind: InvitationKind.coHost,
      createdAt: now,
    ));
    _notify(inviteeId, NotificationKind.coHostInvite,
        '${requireUser(actorId).displayName} invited you to co-host',
        '${event.title}. You get hosting tools only after you accept.',
        eventId: eventId);
  }

  void respondToCoHost(String userId, String invitationId, bool accept) {
    final inv = repo.invitations.firstWhere((i) => i.id == invitationId,
        orElse: () => throw const RuleViolation('Invitation not found.'));
    if (inv.inviteeId != userId || inv.kind != InvitationKind.coHost) {
      throw const RuleViolation('This invitation is not yours.');
    }
    if (inv.status != InvitationStatus.sent) return;
    repo.saveInvitation(inv.copyWith(
        status: accept ? InvitationStatus.accepted : InvitationStatus.declined));
    if (accept) {
      final event = requireEvent(inv.eventId);
      repo.saveEvent(
          event.copyWith(coHostIds: [...event.coHostIds, userId]));
      _notify(inv.invitedById, NotificationKind.coHostAccepted,
          '${requireUser(userId).displayName} is now co-hosting',
          event.title,
          eventId: event.id);
    }
  }

  /// Private guest invitation. Grants the right to REQUEST to join only.
  /// Inviting another builder as a guest never grants hosting privileges.
  void inviteGuest(String actorId, String eventId, String inviteeId) {
    final event = requireEvent(eventId);
    _requireHostingTeam(actorId, event);
    if (event.isHostingTeam(inviteeId)) {
      throw const RuleViolation('Hosts do not need a guest invitation.');
    }
    if (guestInvitation(eventId, inviteeId) != null) {
      throw const RuleViolation('Already invited.');
    }
    repo.saveInvitation(Invitation(
      id: repo.nextId('inv'),
      eventId: eventId,
      inviteeId: inviteeId,
      invitedById: actorId,
      kind: InvitationKind.guest,
      createdAt: now,
    ));
    _notify(
        inviteeId,
        NotificationKind.guestInvite,
        '${requireUser(actorId).displayName} invited you to '
            '${event.isPrivate ? 'a private event' : 'an event'}',
        '${event.title}. You can request to join; the host still decides.',
        eventId: eventId);
  }

  HostAnalytics analyticsFor(String actorId, String eventId) {
    final event = requireEvent(eventId);
    _requireHostingTeam(actorId, event);
    final regs = registrationsForEvent(eventId);
    // Withdrawal is only possible before start, so every still-approved
    // registration was a confirmed RSVP at start.
    final confirmed =
        regs.where((r) => r.status == RegistrationStatus.approved);
    final confirmedIds = confirmed.map((r) => r.userId).toSet();
    // Participating hosts are not counted unless registered.
    final arrivals = attendanceForEvent(eventId)
        .where((a) => confirmedIds.contains(a.userId))
        .length;
    final posts = repo.posts.where((p) => p.eventId == eventId).toList();
    final reviews = repo.reviews.where((r) => r.eventId == eventId).toList();
    final breakdown = List<int>.filled(5, 0);
    for (final r in reviews) {
      breakdown[r.rating - 1]++;
    }
    return HostAnalytics(
      confirmedAtStart: confirmed.length,
      arrivals: arrivals,
      postCount: posts.length,
      commentCount: posts.fold(0, (s, p) => s + p.comments.length),
      reviewCount: reviews.length,
      ratingBreakdown: breakdown,
      pendingCount:
          regs.where((r) => r.status == RegistrationStatus.pending).length,
    );
  }
}
