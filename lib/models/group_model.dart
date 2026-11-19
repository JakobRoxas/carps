class OrgGroup {
  final String id;
  final String name;
  final String description;
  final String ownerId;
  final List<String> followerIds;
  final List<String> statusUpdates;

  const OrgGroup({
    required this.id,
    required this.name,
    required this.description,
    required this.ownerId,
    this.followerIds = const [],
    this.statusUpdates = const [],
  });

  OrgGroup copyWith({
    List<String>? followerIds,
    List<String>? statusUpdates,
  }) {
    return OrgGroup(
      id: id,
      name: name,
      description: description,
      ownerId: ownerId,
      followerIds: followerIds ?? this.followerIds,
      statusUpdates: statusUpdates ?? this.statusUpdates,
    );
  }
}