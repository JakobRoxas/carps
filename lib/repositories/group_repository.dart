import '../models/group_model.dart';

abstract class GroupRepository {
  Future<List<OrgGroup>> fetchGroups();
  Future<OrgGroup> createGroup(OrgGroup group);
  Future<void> toggleFollow(String groupId, String userId);
  Future<void> postStatusUpdate(String groupId, String status);
}

class MockGroupRepository implements GroupRepository {
  final List<OrgGroup> _groups = [
    const OrgGroup(
      id: 'grp_1',
      name: 'CICS Dev Society',
      description: 'Student builders shipping mobile and web apps.',
      ownerId: 'user_1',
      followerIds: ['user_1', 'user_2'],
      statusUpdates: ['Applications for Hackathon Committee are open!'],
    ),
    const OrgGroup(
      id: 'grp_2',
      name: 'España Sound Collective',
      description: 'DIY gigs and local music showcases.',
      ownerId: 'user_3',
      followerIds: ['user_2'],
    ),
  ];

  @override
  Future<List<OrgGroup>> fetchGroups() async => List.unmodifiable(_groups);

  @override
  Future<OrgGroup> createGroup(OrgGroup group) async {
    _groups.add(group);
    return group;
  }

  @override
  Future<void> toggleFollow(String groupId, String userId) async {
    final idx = _groups.indexWhere((g) => g.id == groupId);
    if (idx == -1) return;
    final followers = List<String>.from(_groups[idx].followerIds);
    followers.contains(userId) ? followers.remove(userId) : followers.add(userId);
    _groups[idx] = _groups[idx].copyWith(followerIds: followers);
  }

  @override
  Future<void> postStatusUpdate(String groupId, String status) async {
    final idx = _groups.indexWhere((g) => g.id == groupId);
    if (idx == -1) return;
    _groups[idx] = _groups[idx].copyWith(
      statusUpdates: [status, ..._groups[idx].statusUpdates],
    );
  }
}