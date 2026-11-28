import 'carps_enums.dart';

/// Settings → Help issue report, routed to an assigned admin.
class SupportCase {
  const SupportCase({
    required this.id,
    required this.reporterId,
    required this.category,
    required this.details,
    required this.createdAt,
    required this.assignedAdminId,
    this.link,
    this.status = CaseStatus.open,
    this.outcome,
    this.decisionNote,
    this.closedAt,
    this.hostConfirmed = false,
  });

  final String id;
  final String reporterId;
  final String category;
  final String details;
  final String? link;
  final DateTime createdAt;
  final String assignedAdminId;
  final CaseStatus status;
  final CaseOutcome? outcome;
  final String? decisionNote;
  final DateTime? closedAt;

  /// For attendance discrepancies: confirmed with the host before acting.
  final bool hostConfirmed;

  SupportCase close({
    required CaseOutcome outcome,
    required String note,
    required DateTime at,
    bool hostConfirmed = false,
  }) => SupportCase(
    id: id,
    reporterId: reporterId,
    category: category,
    details: details,
    link: link,
    createdAt: createdAt,
    assignedAdminId: assignedAdminId,
    status: CaseStatus.closed,
    outcome: outcome,
    decisionNote: note,
    closedAt: at,
    hostConfirmed: hostConfirmed,
  );
}
