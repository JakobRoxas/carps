import 'package:flutter/foundation.dart';
import '../models/event_model.dart';
import '../models/group_model.dart';
import '../models/user_model.dart';
import '../repositories/event_repository.dart';
import '../repositories/group_repository.dart';

class GroupController extends ChangeNotifier {
  final GroupRepository _groupRepo;
  final EventRepository _eventRepo;
  AppUser currentUser;

  List<OrgGroup> groups = [];

  GroupController({
    required GroupRepository groupRepository,
    required EventRepository eventRepository,
    required this.currentUser,
  })  : _groupRepo = groupRepository,
        _eventRepo = eventRepository;

  Future<void> loadGroups() async {
    groups = await _groupRepo.fetchGroups();
    notifyListeners();
  }

  Future<void> toggleFollowGroup(String groupId) async {
    await _groupRepo.toggleFollow(groupId, currentUser.id);
    final updated = List<String>.from(currentUser.followedGroupIds);
    updated.contains(groupId) ? updated.remove(groupId) : updated.add(groupId);
    currentUser = currentUser.copyWith(followedGroupIds: updated);
    await loadGroups();
  }

  Future<void> publishEvent({
    required String groupId,
    required String title,
    required String description,
    required String location,
    required DateTime dateTime,
    required List<String> tags,
  }) async {
    final event = CarpsEvent(
      id: 'evt_${DateTime.now().millisecondsSinceEpoch}',
      groupId: groupId,
      title: title,
      description: description,
      location: location,
      dateTime: dateTime,
      tags: tags,
    );
    await _eventRepo.createEvent(event);
    notifyListeners();
  }
}