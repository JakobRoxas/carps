import '../models/event_model.dart';
import '../models/social_model.dart';

abstract class EventRepository {
  Future<List<CarpsEvent>> fetchAllEvents();
  Future<CarpsEvent> createEvent(CarpsEvent event);
  Future<void> toggleRsvp(String eventId, String userId);

  // Mini-forum & post-event reviews
  Future<List<ForumPost>> fetchForumPosts(String eventId);
  Future<ForumPost> addForumPost(ForumPost post);
  Future<void> addReply(String eventId, String postId, ForumReply reply);
  Future<List<EventReview>> fetchReviews(String eventId);
  Future<EventReview> submitReview(EventReview review);
}
