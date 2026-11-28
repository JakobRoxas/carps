import '../models/carps_models.dart';
import '../services/profile_service.dart';
import 'data_controller.dart';

/// Controller for user profiles, onboarding preferences and following.
class ProfileController {
  ProfileController(this._service, this._data);

  final ProfileService _service;
  final DataController _data;

  DateTime get now => _service.now;
  UserProfile? userById(String id) => _data.userById(id);
  List<CarpsEvent> profileEvents(String? viewerId, String profileId) =>
      _service.profileEvents(viewerId, profileId);
  int followerCount(String builderId) => _service.followerCount(builderId);
  int attendedCount(String userId) => _service.attendedCount(userId);
  int hostedCount(String userId) => _service.hostedCount(userId);
  int activeRegistrationCount(String userId) => _data.registrations
      .where((r) => r.userId == userId && r.isActive)
      .where((r) => !(_data.eventById(r.eventId)?.isEnded(_service.now) ?? true))
      .length;
  EventReview? reviewFor(String eventId, String authorId) =>
      _data.reviewByAuthor(eventId, authorId);
  ({double? average, int count}) builderRating(
          String? viewerId, String builderId) =>
      _service.builderRating(viewerId, builderId);
  List<Registration> registrationsForEvent(String eventId) =>
      _service.registrationsForEvent(eventId);
  List<ExperiencePost> authoredPosts(String? viewerId, String profileId) =>
      _service.authoredPosts(viewerId, profileId);
  List<ExperiencePost> taggedPosts(String? viewerId, String profileId) =>
      _service.taggedPosts(viewerId, profileId);

  void toggleFollow(String userId, String builderId) =>
      _service.toggleFollow(userId, builderId);
  void updateUser(UserProfile user) => _service.updateUser(user);
  void enableHosting(String userId,
          {required String builderName, required String about}) =>
      _service.enableHosting(userId, builderName: builderName, about: about);
  String? usernameProblem(String username, {String? ownerId}) =>
      _service.usernameProblem(username, ownerId: ownerId);
  List<UserProfile> searchPeople(String query, {String? excludeId}) =>
      _service.searchPeople(query, excludeId: excludeId);
  List<HistoryEntry> historyFor(String userId) => _service.historyFor(userId);
}
