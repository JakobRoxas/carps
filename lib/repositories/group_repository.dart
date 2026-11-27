import '../models/group_model.dart';

abstract class GroupRepository {
  Future<List<OrgGroup>> fetchGroups();
  Future<OrgGroup> createGroup(OrgGroup group);
  Future<void> toggleFollow(String groupId, String userId);
  Future<void> postStatusUpdate(String groupId, String status);
}
