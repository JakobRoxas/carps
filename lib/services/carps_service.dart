import '../models/carps_models.dart';
import '../repositories/carps_repository.dart';

typedef Clock = DateTime Function();

class ScanResult {
  const ScanResult(this.outcome, {this.guest, this.arrivedAt, this.event});
  final ScanOutcome outcome;
  final UserProfile? guest;
  final DateTime? arrivedAt;

  /// For wrong-event results: the event the pass actually belongs to.
  final CarpsEvent? event;
}

/// Business rules for CARPS.
///
/// Every UI action and every demo control goes through these methods, so a
/// demo shortcut can never skip an eligibility check. Each method takes the
/// acting user's id explicitly; nothing here trusts the caller's role claims.
class CarpsService {
  CarpsService(this.repo, {Clock? clock}) : _clock = clock ?? DateTime.now;

  final CarpsRepository repo;
  final Clock _clock;

  DateTime get now => _clock();

  /// Hosts may open the scanner this long before the start time.
  static const scanOpensBefore = Duration(hours: 6);

  // ---------------------------------------------------------------------------
  // Lookups
  // ---------------------------------------------------------------------------

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
      .where((r) =>
          r.eventId == eventId && r.status == RegistrationStatus.approved)
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
        .where((e) =>
            !e.isPrivate && !e.isCancelled && !e.isEnded(now))
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
  List<CarpsEvent> hostingEvents(String userId) => repo.events
      .where((e) => e.isHostingTeam(userId))
      .toList()
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

  // ---------------------------------------------------------------------------
  // Profiles and following
  // ---------------------------------------------------------------------------

  /// Following is independent of registration: it never creates, changes or
  /// removes a join request, and never grants private access.
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

  int attendedCount(String userId) =>
      repo.attendance.where((a) => a.userId == userId).length;

  int hostedCount(String userId) =>
      hostingEvents(userId).where((e) => !e.isCancelled).length;

  // ---------------------------------------------------------------------------
  // Hosting: create, edit, publish, co-hosts, invitations, notices
  // ---------------------------------------------------------------------------

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

  // ---------------------------------------------------------------------------
  // Registration: request → pending → approved/declined → pass → scan
  // ---------------------------------------------------------------------------

  /// Why the user cannot request right now, or null if they can.
  String? requestBlocker(String userId, CarpsEvent event) {
    if (event.isHostingTeam(userId)) return 'You are on the hosting team.';
    if (event.isCancelled) return 'This event was cancelled.';
    if (!now.isBefore(event.start)) return 'Requests close when the event starts.';
    if (event.isPrivate && guestInvitation(event.id, userId) == null) {
      return 'This private event is invitation only.';
    }
    final existing = registrationFor(event.id, userId);
    if (existing != null) {
      switch (existing.status) {
        case RegistrationStatus.pending:
          return 'Your request is pending.';
        case RegistrationStatus.approved:
          return 'You are approved.';
        case RegistrationStatus.declined:
          return 'The host declined this request.';
        case RegistrationStatus.withdrawn:
          break; // may request again
      }
    }
    return null;
  }

  /// Public AND private requests both start Pending.
  Registration requestToJoin(String userId, String eventId, {String note = ''}) {
    final event = requireEvent(eventId);
    final blocker = requestBlocker(userId, event);
    if (blocker != null) throw RuleViolation(blocker);
    final existing = registrationFor(eventId, userId);
    final reg = Registration(
      id: existing?.id ?? 'reg_${eventId}_$userId',
      eventId: eventId,
      userId: userId,
      status: RegistrationStatus.pending,
      requestedAt: now,
      note: note.trim(),
    );
    repo.saveRegistration(reg);
    for (final hostId in [event.hostId, ...event.coHostIds]) {
      _notify(hostId, NotificationKind.joinRequest,
          '${requireUser(userId).displayName} requested to join',
          '${event.title} · review in Guest roster',
          eventId: eventId);
    }
    return reg;
  }

  /// Manual decision by the builder or an accepted co-host. Admins cannot
  /// approve guests unless they are on the event's hosting team.
  void decide(String actorId, String registrationId, {required bool approve}) {
    final reg = repo.registrations.firstWhere((r) => r.id == registrationId,
        orElse: () => throw const RuleViolation('Request not found.'));
    final event = requireEvent(reg.eventId);
    _requireHostingTeam(actorId, event);
    if (reg.status != RegistrationStatus.pending) {
      throw const RuleViolation('This request was already decided.');
    }
    if (event.isCancelled) throw const RuleViolation('This event was cancelled.');
    if (!approve) {
      repo.saveRegistration(
          reg.copyWith(status: RegistrationStatus.declined, decidedAt: now));
      _notify(reg.userId, NotificationKind.declined,
          'Request not approved', '${event.title}. No pass was issued.',
          eventId: event.id);
      return;
    }
    final pass = GuestPass(
      id: repo.nextId('pass'),
      token: _newToken(event.id, reg.userId),
      eventId: event.id,
      userId: reg.userId,
      registrationId: reg.id,
      issuedAt: now,
    );
    repo.saveApprovedRegistration(
      reg.copyWith(
        status: RegistrationStatus.approved,
        decidedAt: now,
        passId: pass.id,
      ),
      pass,
    );
    _notify(reg.userId, NotificationKind.approved, 'You\'re in! Pass ready',
        '${event.title}. Open My RSVPs to show your QR pass at the venue.',
        eventId: event.id);
  }

  String _newToken(String eventId, String userId) {
    // Unique per guest + event; includes a counter so re-approval after a
    // withdrawal never reuses an old token.
    final n = repo.nextId('token').split('_').last;
    final e = eventId.hashCode.abs().toRadixString(36).toUpperCase();
    final u = userId.hashCode.abs().toRadixString(36).toUpperCase();
    return 'CARP-$e-$u-$n';
  }

  /// Guest withdraws before start. Any pass is revoked.
  void withdraw(String userId, String registrationId) {
    final reg = repo.registrations.firstWhere((r) => r.id == registrationId,
        orElse: () => throw const RuleViolation('Request not found.'));
    if (reg.userId != userId) throw const RuleViolation('Not your request.');
    final event = requireEvent(reg.eventId);
    if (!now.isBefore(event.start)) {
      throw const RuleViolation('You can only withdraw before the event starts.');
    }
    if (!reg.isActive) throw const RuleViolation('Nothing to withdraw.');
    if (reg.passId != null) {
      final pass = repo.passes.where((p) => p.id == reg.passId).firstOrNull;
      if (pass != null) repo.savePass(pass.revoke());
    }
    repo.saveRegistration(
        reg.copyWith(status: RegistrationStatus.withdrawn, decidedAt: now));
  }

  bool scannerOpen(CarpsEvent event) =>
      !event.isCancelled &&
      !now.isBefore(event.start.subtract(scanOpensBefore)) &&
      now.isBefore(event.end);

  /// Event-specific scan. Only a valid FIRST scan records attendance.
  ScanResult scan(String actorId, String eventId, String token) {
    final event = requireEvent(eventId);
    if (!event.isHostingTeam(actorId)) {
      return const ScanResult(ScanOutcome.notAuthorized);
    }
    if (!scannerOpen(event)) return const ScanResult(ScanOutcome.outsideWindow);
    final pass = repo.passByToken(token.trim());
    if (pass == null) return const ScanResult(ScanOutcome.invalid);
    final guest = repo.user(pass.userId);
    if (pass.eventId != eventId) {
      return ScanResult(ScanOutcome.wrongEvent,
          guest: guest, event: repo.event(pass.eventId));
    }
    final reg = registrationFor(eventId, pass.userId);
    if (pass.revoked || reg?.status == RegistrationStatus.withdrawn) {
      return ScanResult(ScanOutcome.withdrawn, guest: guest);
    }
    if (reg == null ||
        reg.status != RegistrationStatus.approved ||
        reg.passId != pass.id) {
      return ScanResult(ScanOutcome.invalid, guest: guest);
    }
    final existing = attendanceFor(eventId, pass.userId);
    if (existing != null) {
      return ScanResult(ScanOutcome.alreadyCheckedIn,
          guest: guest, arrivedAt: existing.arrivedAt);
    }
    final record = Attendance(
      eventId: eventId,
      userId: pass.userId,
      arrivedAt: now,
      scannedById: actorId,
      passId: pass.id,
    );
    repo.saveAttendance(record);
    _notify(pass.userId, NotificationKind.checkedIn, 'Checked in',
        'Welcome to ${event.title}! After it ends you can share your experience.',
        eventId: eventId);
    return ScanResult(ScanOutcome.checkedIn,
        guest: guest, arrivedAt: record.arrivedAt);
  }

  /// Demo control: moves the event's end to "now" so it becomes Ended, exactly
  /// as if time had passed. Does not touch attendance or eligibility.
  void endEventNow(String eventId) {
    final event = requireEvent(eventId);
    final t = now;
    final start = event.start.isAfter(t)
        ? t.subtract(const Duration(minutes: 1))
        : event.start;
    repo.saveEvent(event.copyWith(start: start, end: t));
  }

  // ---------------------------------------------------------------------------
  // Attendance history and posting eligibility
  // ---------------------------------------------------------------------------

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

  /// The publishing rule. Applies to builders too: hosting is not attendance.
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

  // ---------------------------------------------------------------------------
  // Analytics
  // ---------------------------------------------------------------------------

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

  // ---------------------------------------------------------------------------
  // Notifications
  // ---------------------------------------------------------------------------

  void _notify(String userId, NotificationKind kind, String title, String body,
      {String? eventId,
      String? postId,
      String? caseId,
      bool emailSimulated = false}) {
    repo.saveNotification(AppNotification(
      id: repo.nextId('ntf'),
      userId: userId,
      kind: kind,
      title: title,
      body: body,
      createdAt: now,
      eventId: eventId,
      postId: postId,
      caseId: caseId,
      emailSimulated: emailSimulated,
    ));
  }

  List<AppNotification> notificationsFor(String userId) =>
      repo.notifications.where((n) => n.userId == userId).toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

  int unreadCount(String userId) =>
      notificationsFor(userId).where((n) => !n.read).length;

  void markAllRead(String userId) {
    for (final n in notificationsFor(userId).where((n) => !n.read)) {
      repo.saveNotification(n.markRead());
    }
  }

  // ---------------------------------------------------------------------------
  // Accounts and onboarding (mock auth)
  // ---------------------------------------------------------------------------

  UserProfile? findByEmail(String email) {
    final e = email.trim().toLowerCase();
    for (final u in repo.users) {
      if (u.email.toLowerCase() == e) return u;
    }
    return null;
  }

  UserProfile logIn(String email, String password) {
    final user = findByEmail(email);
    if (user == null || user.password != password) {
      throw const RuleViolation('Email or password is incorrect.');
    }
    return user;
  }

  UserProfile signUp(String email, String password) {
    if (!isValidEmail(email)) throw const RuleViolation('Enter a valid email.');
    if (password.length < 8) {
      throw const RuleViolation('Use at least 8 characters for your password.');
    }
    if (findByEmail(email) != null) {
      throw const RuleViolation('An account with this email already exists.');
    }
    final local = email.split('@').first.toLowerCase().replaceAll(
        RegExp(r'[^a-z0-9_]'), '');
    final user = UserProfile(
      id: repo.nextId('u'),
      displayName: '',
      username: local.isEmpty ? 'newmember' : local,
      email: email.trim(),
      password: password,
    );
    repo.saveUser(user);
    return user;
  }

  static bool isValidEmail(String email) =>
      RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email.trim());

  static final usernamePattern = RegExp(r'^[a-z0-9_]{3,20}$');

  String? usernameProblem(String username, {String? ownerId}) {
    final u = username.trim().replaceFirst('@', '');
    if (!usernamePattern.hasMatch(u)) {
      return 'Use 3–20 lowercase letters, numbers or underscores.';
    }
    final taken = repo.users.any((x) => x.username == u && x.id != ownerId);
    return taken ? 'That username is taken.' : null;
  }

  void updateUser(UserProfile user) => repo.saveUser(user);

  void enableHosting(String userId,
      {required String builderName, required String about}) {
    if (builderName.trim().length < 3) {
      throw const RuleViolation('Give your builder profile a name.');
    }
    final user = requireUser(userId);
    repo.saveUser(user.copyWith(
        hostingEnabled: true,
        builderName: builderName.trim(),
        builderAbout: about.trim()));
  }

  List<UserProfile> searchPeople(String query, {String? excludeId}) {
    final q = query.trim().toLowerCase().replaceFirst('@', '');
    return repo.users.where((u) {
      if (u.id == excludeId || u.displayName.isEmpty) return false;
      if (q.isEmpty) return true;
      return u.displayName.toLowerCase().contains(q) ||
          u.username.contains(q) ||
          (u.builderName?.toLowerCase().contains(q) ?? false);
    }).toList();
  }

  // ---------------------------------------------------------------------------
  // Support: Settings → Help → assigned admin
  // ---------------------------------------------------------------------------

  SupportCase reportIssue(String reporterId, String category, String details,
      {String? link}) {
    if (details.trim().length < 10) {
      throw const RuleViolation('Tell us a bit more (10+ characters).');
    }
    final admins = repo.users.where((u) => u.isAdmin).toList();
    if (admins.isEmpty) throw const RuleViolation('No admin is assigned yet.');
    final c = SupportCase(
      id: repo.nextId('case'),
      reporterId: reporterId,
      category: category,
      details: details.trim(),
      link: (link?.trim().isEmpty ?? true) ? null : link!.trim(),
      createdAt: now,
      assignedAdminId: admins.first.id,
    );
    repo.saveCase(c);
    _notify(admins.first.id, NotificationKind.supportAssigned,
        'New issue assigned to you', '$category · reported by a member',
        caseId: c.id);
    return c;
  }

  List<SupportCase> casesFor(String adminId) {
    if (!(repo.user(adminId)?.isAdmin ?? false)) return [];
    return repo.cases.where((c) => c.assignedAdminId == adminId).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  List<SupportCase> casesReportedBy(String userId) =>
      repo.cases.where((c) => c.reporterId == userId).toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

  /// Parses an `/event/<id>` or `/post/<id>` link from a report.
  ({String? eventId, String? postId}) parseLink(String? link) {
    if (link == null) return (eventId: null, postId: null);
    final e = RegExp(r'event/([A-Za-z0-9_]+)').firstMatch(link)?.group(1);
    final p = RegExp(r'post/([A-Za-z0-9_]+)').firstMatch(link)?.group(1);
    return (eventId: e, postId: p);
  }

  /// Records the admin's decision and notifies the reporter without private
  /// details. Admins never decide event admission.
  void resolveCase({
    required String adminId,
    required String caseId,
    required CaseOutcome outcome,
    required String note,
    bool hostConfirmed = false,
  }) {
    final admin = requireUser(adminId);
    if (!admin.isAdmin) throw const RuleViolation('Admin permission required.');
    final c = repo.cases.firstWhere((x) => x.id == caseId,
        orElse: () => throw const RuleViolation('Case not found.'));
    if (c.assignedAdminId != adminId) {
      throw const RuleViolation('This case is assigned to another admin.');
    }
    if (c.status == CaseStatus.closed) {
      throw const RuleViolation('This case is already closed.');
    }
    if (note.trim().isEmpty) {
      throw const RuleViolation('Record the reason for your decision.');
    }
    final link = parseLink(c.link);
    Attendance? correctedAttendance;
    switch (outcome) {
      case CaseOutcome.noAction:
      case CaseOutcome.warnedUser:
        break;
      case CaseOutcome.removedPost:
        final post = link.postId == null ? null : repo.post(link.postId!);
        if (post == null) {
          throw const RuleViolation('The report does not link to a post.');
        }
        repo.deletePost(post.id);
      case CaseOutcome.attendanceCorrected:
        if (!hostConfirmed) {
          throw const RuleViolation(
              'Confirm the discrepancy with the host first. A request or approval is not proof of presence.');
        }
        final event = link.eventId == null ? null : repo.event(link.eventId!);
        if (event == null) {
          throw const RuleViolation('The report does not link to an event.');
        }
        final reg = registrationFor(event.id, c.reporterId);
        if (reg?.status != RegistrationStatus.approved) {
          throw const RuleViolation(
              'Only an approved guest\'s attendance can be corrected.');
        }
        if (!hasAttended(event.id, c.reporterId)) {
          correctedAttendance = Attendance(
            eventId: event.id,
            userId: c.reporterId,
            arrivedAt: event.start,
            scannedById: event.hostId,
            passId: reg!.passId,
          );
        }
    }
    final resolved = c.close(
        outcome: outcome,
        note: note.trim(),
        at: now,
        hostConfirmed: hostConfirmed);
    if (outcome == CaseOutcome.attendanceCorrected) {
      repo.resolveAttendanceCorrection(resolved, correctedAttendance);
    } else {
      repo.saveCase(resolved);
    }
    _notify(c.reporterId, NotificationKind.supportUpdate,
        'Your report was reviewed',
        outcome == CaseOutcome.noAction
            ? 'We reviewed your report and closed it without changes.'
            : 'We reviewed your report and took action. Thanks for helping keep CARPS safe.',
        caseId: c.id);
  }
}
