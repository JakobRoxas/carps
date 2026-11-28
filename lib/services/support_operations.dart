part of 'carps_domain_operations.dart';

mixin SupportOperations on CarpsServiceBase, EventQueryOperations, NotificationOperations {

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
