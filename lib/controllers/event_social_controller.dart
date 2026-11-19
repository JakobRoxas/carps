import 'package:flutter/foundation.dart';
import '../models/social_model.dart';
import '../models/user_model.dart';
import '../repositories/event_repository.dart';

class EventSocialController extends ChangeNotifier {
  final EventRepository _eventRepo;
  final AppUser currentUser;

  List<ForumPost> posts = [];
  List<EventReview> reviews = [];

  EventSocialController({
    required EventRepository eventRepository,
    required this.currentUser,
  }) : _eventRepo = eventRepository;

  double get averageRating {
    if (reviews.isEmpty) return 0.0;
    final total = reviews.fold<int>(0, (sum, r) => sum + r.rating);
    return total / reviews.length;
  }

  Future<void> loadEventSocial(String eventId) async {
    posts = await _eventRepo.fetchForumPosts(eventId);
    reviews = await _eventRepo.fetchReviews(eventId);
    notifyListeners();
  }

  Future<void> createPost(String eventId, String content, {String? mediaUrl}) async {
    final post = ForumPost(
      id: 'post_${DateTime.now().millisecondsSinceEpoch}',
      eventId: eventId,
      authorId: currentUser.id,
      authorName: currentUser.name,
      content: content,
      mediaUrl: mediaUrl,
      createdAt: DateTime.now(),
    );
    await _eventRepo.addForumPost(post);
    await loadEventSocial(eventId);
  }

  Future<void> replyToPost(String eventId, String postId, String content) async {
    final reply = ForumReply(
      id: 'rep_${DateTime.now().millisecondsSinceEpoch}',
      authorName: currentUser.name,
      content: content,
      createdAt: DateTime.now(),
    );
    await _eventRepo.addReply(eventId, postId, reply);
    await loadEventSocial(eventId);
  }

  Future<void> submitReview(String eventId, int rating, String comment) async {
    final review = EventReview(
      id: 'rev_${DateTime.now().millisecondsSinceEpoch}',
      eventId: eventId,
      reviewerId: currentUser.id,
      reviewerName: currentUser.name,
      rating: rating.clamp(1, 5),
      comment: comment,
    );
    await _eventRepo.submitReview(review);
    await loadEventSocial(eventId);
  }
}