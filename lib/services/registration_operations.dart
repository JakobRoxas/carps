part of 'carps_domain_operations.dart';

mixin RegistrationOperations on CarpsServiceBase, EventQueryOperations, NotificationOperations, EventManagementOperations {

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
}
