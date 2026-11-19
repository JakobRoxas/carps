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

class MockEventRepository implements EventRepository {
  final List<CarpsEvent> _events = [
    CarpsEvent(
      id: 'evt_1',
      groupId: 'grp_1',
      title: 'Manila Indie Dev & Flutter Jam',
      description: 'Live coding, architecture clinics, and demos.',
      location: 'Manila',
      dateTime: DateTime.now().add(const Duration(days: 3)),
      tags: ['tech', 'flutter', 'coding'],
      attendeeIds: ['user_2', 'user_3'],
    ),
    CarpsEvent(
      id: 'evt_2',
      groupId: 'grp_2',
      title: 'UST Math Rock & Midwest Emo Gig',
      description: 'Local underground bands night near España.',
      location: 'Manila',
      dateTime: DateTime.now().add(const Duration(days: 5)),
      tags: ['music', 'indie', 'gig'],
      attendeeIds: ['user_2'],
    ),
    CarpsEvent(
      id: 'evt_3',
      groupId: 'grp_1',
      title: 'Intro to Backend Architecture Workshop',
      description: 'Completed workshop on APIs and databases.',
      location: 'Quezon City',
      dateTime: DateTime.now().subtract(const Duration(days: 2)),
      tags: ['tech', 'backend'],
      attendeeIds: ['user_1', 'user_2'],
    ),
  ];

  final Map<String, List<ForumPost>> _posts = {};
  final Map<String, List<EventReview>> _reviews = {};

  @override
  Future<List<CarpsEvent>> fetchAllEvents() async {
    await Future.delayed(const Duration(milliseconds: 200));
    return List.unmodifiable(_events);
  }

  @override
  Future<CarpsEvent> createEvent(CarpsEvent event) async {
    await Future.delayed(const Duration(milliseconds: 200));
    _events.insert(0, event);
    return event;
  }

  @override
  Future<void> toggleRsvp(String eventId, String userId) async {
    final idx = _events.indexWhere((e) => e.id == eventId);
    if (idx == -1) return;

    final current = _events[idx];
    final updatedAttendees = List<String>.from(current.attendeeIds);
    if (updatedAttendees.contains(userId)) {
      updatedAttendees.remove(userId);
    } else {
      updatedAttendees.add(userId);
    }
    _events[idx] = current.copyWith(attendeeIds: updatedAttendees);
  }

  @override
  Future<List<ForumPost>> fetchForumPosts(String eventId) async {
    return List.unmodifiable(_posts[eventId] ?? []);
  }

  @override
  Future<ForumPost> addForumPost(ForumPost post) async {
    _posts.putIfAbsent(post.eventId, () => []).insert(0, post);
    return post;
  }

  @override
  Future<void> addReply(String eventId, String postId, ForumReply reply) async {
    final eventPosts = _posts[eventId];
    if (eventPosts == null) return;
    final idx = eventPosts.indexWhere((p) => p.id == postId);
    if (idx == -1) return;

    final old = eventPosts[idx];
    eventPosts[idx] = ForumPost(
      id: old.id,
      eventId: old.eventId,
      authorId: old.authorId,
      authorName: old.authorName,
      content: old.content,
      mediaUrl: old.mediaUrl,
      createdAt: old.createdAt,
      replies: [...old.replies, reply],
    );
  }

  @override
  Future<List<EventReview>> fetchReviews(String eventId) async {
    return List.unmodifiable(_reviews[eventId] ?? []);
  }

  @override
  Future<EventReview> submitReview(EventReview review) async {
    _reviews.putIfAbsent(review.eventId, () => []).add(review);
    return review;
  }
}