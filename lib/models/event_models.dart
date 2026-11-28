import 'carps_enums.dart';

class EventNotice {
  const EventNotice({
    required this.id,
    required this.text,
    required this.createdAt,
    this.isVenueChange = false,
  });

  final String id;
  final String text;
  final DateTime createdAt;
  final bool isVenueChange;
}

/// A registered CARPS event. An upcoming listing is NOT a social post.
class CarpsEvent {
  const CarpsEvent({
    required this.id,
    required this.hostId,
    required this.title,
    required this.description,
    required this.topic,
    required this.venue,
    required this.area,
    required this.start,
    required this.end,
    required this.visibility,
    this.coverAsset,
    this.coHostIds = const [],
    this.capacity,
    this.featuredOnProfile = false,
    this.status = EventStatus.published,
    this.notices = const [],
    this.seriesLabel,
  });

  final String id;
  final String hostId;

  /// Co-hosts who ACCEPTED. Pending co-host invitations live in invitations.
  final List<String> coHostIds;
  final String title;
  final String description;
  final String topic;
  final String venue;
  final String area;
  final DateTime start;
  final DateTime end;
  final EventVisibility visibility;
  final String? coverAsset;
  final int? capacity;
  final bool featuredOnProfile;
  final EventStatus status;
  final List<EventNotice> notices;

  /// e.g. "Sunday open play" so recurring sessions stay distinguishable.
  final String? seriesLabel;

  bool get isPrivate => visibility == EventVisibility.private;
  bool get isCancelled => status == EventStatus.cancelled;
  bool isEnded(DateTime now) => !now.isBefore(end);
  bool isUpcoming(DateTime now) => now.isBefore(start);
  bool isLive(DateTime now) => !now.isBefore(start) && now.isBefore(end);

  bool isHostingTeam(String userId) =>
      hostId == userId || coHostIds.contains(userId);

  CarpsEvent copyWith({
    List<String>? coHostIds,
    String? title,
    String? description,
    String? topic,
    String? venue,
    String? area,
    DateTime? start,
    DateTime? end,
    EventVisibility? visibility,
    String? coverAsset,
    int? capacity,
    bool? featuredOnProfile,
    EventStatus? status,
    List<EventNotice>? notices,
  }) {
    return CarpsEvent(
      id: id,
      hostId: hostId,
      coHostIds: coHostIds ?? this.coHostIds,
      title: title ?? this.title,
      description: description ?? this.description,
      topic: topic ?? this.topic,
      venue: venue ?? this.venue,
      area: area ?? this.area,
      start: start ?? this.start,
      end: end ?? this.end,
      visibility: visibility ?? this.visibility,
      coverAsset: coverAsset ?? this.coverAsset,
      capacity: capacity ?? this.capacity,
      featuredOnProfile: featuredOnProfile ?? this.featuredOnProfile,
      status: status ?? this.status,
      notices: notices ?? this.notices,
      seriesLabel: seriesLabel,
    );
  }
}
