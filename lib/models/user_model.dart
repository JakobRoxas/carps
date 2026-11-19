class AppUser {
  final String id;
  final String name;
  final String email;
  final String location;
  final List<String> interestTags;
  final List<String> followedGroupIds;
  final List<String> rsvpedEventIds;

  const AppUser({
    required this.id,
    required this.name,
    required this.email,
    required this.location,
    this.interestTags = const [],
    this.followedGroupIds = const [],
    this.rsvpedEventIds = const [],
  });

  AppUser copyWith({
    String? location,
    List<String>? interestTags,
    List<String>? followedGroupIds,
    List<String>? rsvpedEventIds,
  }) {
    return AppUser(
      id: id,
      name: name,
      email: email,
      location: location ?? this.location,
      interestTags: interestTags ?? this.interestTags,
      followedGroupIds: followedGroupIds ?? this.followedGroupIds,
      rsvpedEventIds: rsvpedEventIds ?? this.rsvpedEventIds,
    );
  }

  Map<String, dynamic> toMap() => {
        'name': name,
        'email': email,
        'location': location,
        'interestTags': interestTags,
        'followedGroupIds': followedGroupIds,
        'rsvpedEventIds': rsvpedEventIds,
      };

  factory AppUser.fromMap(String id, Map<String, dynamic> map) => AppUser(
        id: id,
        name: map['name'] ?? '',
        email: map['email'] ?? '',
        location: map['location'] ?? '',
        interestTags: List<String>.from(map['interestTags'] ?? []),
        followedGroupIds: List<String>.from(map['followedGroupIds'] ?? []),
        rsvpedEventIds: List<String>.from(map['rsvpedEventIds'] ?? []),
      );
}