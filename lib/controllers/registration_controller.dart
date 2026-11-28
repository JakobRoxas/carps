import '../models/carps_models.dart';
import '../services/registration_service.dart';

/// Controller for RSVPs, invitations, passes and attendance workflows.
class RegistrationController {
  RegistrationController(this._service);

  final RegistrationService _service;

  DateTime get now => _service.now;
  Registration? registrationFor(String eventId, String userId) =>
      _service.registrationFor(eventId, userId);
  List<Registration> registrationsForEvent(String eventId) =>
      _service.registrationsForEvent(eventId);
  Attendance? attendanceFor(String eventId, String userId) =>
      _service.attendanceFor(eventId, userId);
  List<Attendance> attendanceForEvent(String eventId) =>
      _service.attendanceForEvent(eventId);
  bool hasAttended(String eventId, String userId) =>
      _service.hasAttended(eventId, userId);
  GuestPass? passFor(String eventId, String userId) =>
      _service.passFor(eventId, userId);
  Invitation? guestInvitation(String eventId, String userId) =>
      _service.guestInvitation(eventId, userId);
  Invitation? coHostInvitation(String eventId, String userId) =>
      _service.coHostInvitation(eventId, userId);
  int goingCount(String eventId) => _service.goingCount(eventId);
  String? requestBlocker(String userId, CarpsEvent event) =>
      _service.requestBlocker(userId, event);

  Registration requestToJoin(String userId, String eventId,
          {String note = ''}) =>
      _service.requestToJoin(userId, eventId, note: note);
  void decide(String actorId, String registrationId,
          {required bool approve}) =>
      _service.decide(actorId, registrationId, approve: approve);
  void withdraw(String userId, String registrationId) =>
      _service.withdraw(userId, registrationId);
  bool scannerOpen(CarpsEvent event) => _service.scannerOpen(event);
  ScanResult scan(String actorId, String eventId, String token) =>
      _service.scan(actorId, eventId, token);
  void endEventNow(String eventId) => _service.endEventNow(eventId);
}
