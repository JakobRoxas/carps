import 'package:flutter/foundation.dart';
import '../models/event_model.dart';
import '../models/user_model.dart';
import '../repositories/event_repository.dart';

class FeedController extends ChangeNotifier {
  final EventRepository _eventRepo;
  AppUser currentUser;

  List<CarpsEvent> _allEvents = [];
  String _searchQuery = '';
  String? _selectedTag;
  bool isLoading = false;

  FeedController({
    required EventRepository eventRepository,
    required this.currentUser,
  }) : _eventRepo = eventRepository;

  /// Personalized "For You" ranking based on followed groups, matching tags, and location.
  List<CarpsEvent> get personalizedFeed {
    final filtered = _allEvents.where((event) {
      final matchesQuery = _searchQuery.isEmpty ||
          event.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          event.description.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesTag =
          _selectedTag == null || event.tags.contains(_selectedTag);
      return matchesQuery && matchesTag;
    }).toList();

    filtered.sort((a, b) => _scoreEvent(b).compareTo(_scoreEvent(a)));
    return filtered;
  }

  int _scoreEvent(CarpsEvent event) {
    int score = 0;
    if (currentUser.followedGroupIds.contains(event.groupId)) score += 50;
    if (event.location.toLowerCase() == currentUser.location.toLowerCase()) {
      score += 20;
    }
    final tagMatches = event.tags
        .where((tag) => currentUser.interestTags.contains(tag))
        .length;
    score += tagMatches * 15;
    return score;
  }

  /// Social proof helper: e.g., "2 people with similar interests are going"
  String socialProofLabel(CarpsEvent event) {
    final othersCount =
        event.attendeeIds.where((id) => id != currentUser.id).length;
    if (othersCount == 0) return 'Be the first to RSVP';
    return '$othersCount ${othersCount == 1 ? 'person' : 'people'} with similar interests going';
  }

  Future<void> loadFeed() async {
    isLoading = true;
    notifyListeners();
    _allEvents = await _eventRepo.fetchAllEvents();
    isLoading = false;
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setTagFilter(String? tag) {
    _selectedTag = tag;
    notifyListeners();
  }

  Future<void> toggleRsvp(String eventId) async {
    await _eventRepo.toggleRsvp(eventId, currentUser.id);
    final updatedRsvps = List<String>.from(currentUser.rsvpedEventIds);
    updatedRsvps.contains(eventId)
        ? updatedRsvps.remove(eventId)
        : updatedRsvps.add(eventId);
    currentUser = currentUser.copyWith(rsvpedEventIds: updatedRsvps);
    await loadFeed();
  }
}