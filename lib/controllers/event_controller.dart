import '../models/carps_models.dart';
import '../services/event_service.dart';
import '../services/registration_service.dart';
import '../services/social_service.dart';
import 'data_controller.dart';

/// Controller for event browsing, event management, invitations and event views.
/// Views call this controller; domain rules remain in focused feature services.
class EventController {
  EventController(this._events, this._registrations, this._social, this._data);

  final EventService _events;
  final RegistrationService _registrations;
  final SocialService _social;
  final DataController _data;

  DateTime get now => _events.now;
  CarpsEvent? eventById(String id) => _data.eventById(id);
  UserProfile? userById(String id) => _data.userById(id);

  List<CarpsEvent> discoverableEvents(String? viewerId) =>
      _events.discoverableEvents(viewerId);
  List<CarpsEvent> forYou(String userId) => _events.forYou(userId);
  List<CarpsEvent> hostingEvents(String userId) =>
      _events.hostingEvents(userId);
  List<CarpsEvent> search({
    required String? viewerId,
    String query = '',
    Set<String> topics = const {},
    Set<String> areas = const {},
    DateTime? from,
    DateTime? to,
    String builderQuery = '',
  }) =>
      _events.search(
        viewerId: viewerId,
        query: query,
        topics: topics,
        areas: areas,
        from: from,
        to: to,
        builderQuery: builderQuery,
      );

  bool canViewEvent(String? viewerId, CarpsEvent event) =>
      _events.canViewEvent(viewerId, event);
  bool canViewPrivateSocial(String? viewerId, CarpsEvent event) =>
      _events.canViewPrivateSocial(viewerId, event);
  String? socialProof(String viewerId, CarpsEvent event) =>
      _events.socialProof(viewerId, event);
  int goingCount(String eventId) => _events.goingCount(eventId);

  Invitation? guestInvitation(String eventId, String userId) =>
      _events.guestInvitation(eventId, userId);
  Invitation? coHostInvitation(String eventId, String userId) =>
      _events.coHostInvitation(eventId, userId);
  Registration? registrationFor(String eventId, String userId) =>
      _registrations.registrationFor(eventId, userId);
  Attendance? attendanceFor(String eventId, String userId) =>
      _registrations.attendanceFor(eventId, userId);
  List<Registration> registrationsForEvent(String eventId) =>
      _registrations.registrationsForEvent(eventId);
  List<ExperiencePost> eventPosts(String? viewerId, String eventId) =>
      _social.eventPosts(viewerId, eventId);
  List<EventReview> visibleReviews(String? viewerId, String eventId) =>
      _social.visibleReviews(viewerId, eventId);
  bool canReview(String userId, CarpsEvent event) =>
      _social.canReview(userId, event);
  bool canPostAbout(String userId, CarpsEvent event) =>
      _social.canPostAbout(userId, event);
  String? postBlocker(String userId, CarpsEvent event) =>
      _social.postBlocker(userId, event);
  ({double? average, int count}) ratingSummary(
          String? viewerId, String eventId) =>
      _social.ratingSummary(viewerId, eventId);
  EventReview submitReview(
          String userId, String eventId, int rating, String text) =>
      _social.submitReview(userId, eventId, rating, text);
  void decide(String actorId, String registrationId,
          {required bool approve}) =>
      _registrations.decide(actorId, registrationId, approve: approve);
  bool hasAttended(String eventId, String userId) =>
      _registrations.hasAttended(eventId, userId);
  String? requestBlocker(String userId, CarpsEvent event) =>
      _registrations.requestBlocker(userId, event);
  Registration requestToJoin(String userId, String eventId,
          {String note = ''}) =>
      _registrations.requestToJoin(userId, eventId, note: note);
  void withdraw(String userId, String registrationId) =>
      _registrations.withdraw(userId, registrationId);

  String? validateEventDraft({
    required String title,
    required String venue,
    required DateTime start,
    required DateTime end,
    bool isNew = true,
  }) =>
      _events.validateEventDraft(
        title: title,
        venue: venue,
        start: start,
        end: end,
        isNew: isNew,
      );

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
  }) =>
      _events.createEvent(
        actorId: actorId,
        title: title,
        description: description,
        topic: topic,
        venue: venue,
        area: area,
        start: start,
        end: end,
        visibility: visibility,
        coverAsset: coverAsset,
        capacity: capacity,
        featuredOnProfile: featuredOnProfile,
      );

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
  }) =>
      _events.updateEvent(
        actorId: actorId,
        eventId: eventId,
        title: title,
        description: description,
        topic: topic,
        venue: venue,
        area: area,
        start: start,
        end: end,
        visibility: visibility,
        coverAsset: coverAsset,
        capacity: capacity,
        featuredOnProfile: featuredOnProfile,
      );

  void setFeatured(String actorId, String eventId, bool featured) =>
      _events.setFeatured(actorId, eventId, featured);
  void cancelEvent(String actorId, String eventId) =>
      _events.cancelEvent(actorId, eventId);
  void postNotice(String actorId, String eventId, String text,
          {bool isVenueChange = false}) =>
      _events.postNotice(actorId, eventId, text,
          isVenueChange: isVenueChange);
  int sendReminder(String actorId, String eventId, String text,
          {bool alsoEmail = false}) =>
      _events.sendReminder(actorId, eventId, text,
          alsoEmail: alsoEmail);
  void inviteCoHost(String actorId, String eventId, String inviteeId) =>
      _events.inviteCoHost(actorId, eventId, inviteeId);
  void respondToCoHost(String userId, String invitationId, bool accept) =>
      _events.respondToCoHost(userId, invitationId, accept);
  void inviteGuest(String actorId, String eventId, String inviteeId) =>
      _events.inviteGuest(actorId, eventId, inviteeId);
  HostAnalytics analyticsFor(String actorId, String eventId) =>
      _events.analyticsFor(actorId, eventId);
}
