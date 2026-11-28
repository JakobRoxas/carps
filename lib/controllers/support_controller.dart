import '../models/carps_models.dart';
import '../services/support_service.dart';
import 'data_controller.dart';

/// Controller for support reports and admin review actions.
class SupportController {
  SupportController(this._service, this._data);

  final SupportService _service;
  final DataController _data;

  DateTime get now => _service.now;
  UserProfile? userById(String id) => _data.userById(id);
  CarpsEvent? eventById(String id) => _data.eventById(id);
  ExperiencePost? postById(String id) => _data.postById(id);
  Registration? registrationFor(String eventId, String userId) =>
      _service.registrationFor(eventId, userId);
  Attendance? attendanceFor(String eventId, String userId) =>
      _service.attendanceFor(eventId, userId);
  List<SupportCase> casesFor(String adminId) => _service.casesFor(adminId);
  List<SupportCase> casesReportedBy(String userId) =>
      _service.casesReportedBy(userId);
  ({String? eventId, String? postId}) parseLink(String? link) =>
      _service.parseLink(link);
  SupportCase reportIssue(String reporterId, String category, String details,
          {String? link}) =>
      _service.reportIssue(reporterId, category, details, link: link);
  void resolveCase({
    required String adminId,
    required String caseId,
    required CaseOutcome outcome,
    required String note,
    bool hostConfirmed = false,
  }) =>
      _service.resolveCase(
        adminId: adminId,
        caseId: caseId,
        outcome: outcome,
        note: note,
        hostConfirmed: hostConfirmed,
      );
}
