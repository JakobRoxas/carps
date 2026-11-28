import '../models/carps_models.dart';
import '../services/social_service.dart';
import 'data_controller.dart';

/// Controller for feed, post, comment, tag and review interactions.
class FeedController {
  FeedController(this._service, this._data);

  final SocialService _service;
  final DataController _data;

  DateTime get now => _service.now;
  ExperiencePost? postById(String id) => _data.postById(id);
  CarpsEvent? eventById(String id) => _data.eventById(id);
  UserProfile? userById(String id) => _data.userById(id);
  bool canViewPost(String? viewerId, ExperiencePost post) =>
      _service.canViewPost(viewerId, post);

  List<ExperiencePost> feed(String viewerId) => _service.feed(viewerId);
  List<ExperiencePost> eventPosts(String? viewerId, String eventId) =>
      _service.eventPosts(viewerId, eventId);
  List<ExperiencePost> authoredPosts(String? viewerId, String profileId) =>
      _service.authoredPosts(viewerId, profileId);
  List<ExperiencePost> taggedPosts(String? viewerId, String profileId) =>
      _service.taggedPosts(viewerId, profileId);
  List<CarpsEvent> eligiblePostEvents(String userId) =>
      _service.eligiblePostEvents(userId);
  List<UserProfile> tagCandidates(String eventId, String authorId) =>
      _service.tagCandidates(eventId, authorId);
  String? postBlocker(String userId, CarpsEvent event) =>
      _service.postBlocker(userId, event);
  bool canPostAbout(String userId, CarpsEvent event) =>
      _service.canPostAbout(userId, event);
  String audienceLabel(CarpsEvent event) => _service.audienceLabel(event);

  ExperiencePost publishPost({
    required String authorId,
    required String? eventId,
    required String body,
    String? photoAsset,
    List<String> taggedIds = const [],
  }) =>
      _service.publishPost(
        authorId: authorId,
        eventId: eventId,
        body: body,
        photoAsset: photoAsset,
        taggedIds: taggedIds,
      );
  void deletePost(String actorId, String postId) =>
      _service.deletePost(actorId, postId);
  void removeTag(String actorId, String postId) =>
      _service.removeTag(actorId, postId);
  void toggleLike(String viewerId, String postId) =>
      _service.toggleLike(viewerId, postId);
  void addComment(String viewerId, String postId, String body,
          {String? parentId}) =>
      _service.addComment(viewerId, postId, body, parentId: parentId);

  bool canReview(String userId, CarpsEvent event) =>
      _service.canReview(userId, event);
  List<EventReview> visibleReviews(String? viewerId, String eventId) =>
      _service.visibleReviews(viewerId, eventId);
  EventReview submitReview(
          String userId, String eventId, int rating, String text) =>
      _service.submitReview(userId, eventId, rating, text);
  ({double? average, int count}) ratingSummary(
          String? viewerId, String eventId) =>
      _service.ratingSummary(viewerId, eventId);
  ({double? average, int count}) builderRating(
          String? viewerId, String builderId) =>
      _service.builderRating(viewerId, builderId);
}
