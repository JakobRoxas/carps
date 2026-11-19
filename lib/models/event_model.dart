class CarpsEvent {
  final String id;
  final String groupId;
  final String title;
  final String description;
  final String location;
  final DateTime dateTime;
  final List<String> tags;
  final List<String> attendeeIds;

  const CarpsEvent({
    required this.id,
    required this.groupId,
    required this.title,
    required this.description,
    required this.location,
    required this.dateTime,
    this.tags = const [],
    this.attendeeIds = const [],
  });

  bool get isCompleted => DateTime.now().isAfter(dateTime);

  CarpsEvent copyWith({List<String>? attendeeIds}) {
    return CarpsEvent(
      id: id,
      groupId: groupId,
      title: title,
      description: description,
      location: location,
      dateTime: dateTime,
      tags: tags,
      attendeeIds: attendeeIds ?? this.attendeeIds,
    );
  }

  Map<String, dynamic> toMap() => {
        'groupId': groupId,
        'title': title,
        'description': description,
        'location': location,
        'dateTime': dateTime.toIso8601String(),
        'tags': tags,
        'attendeeIds': attendeeIds,
      };

  factory CarpsEvent.fromMap(String id, Map<String, dynamic> map) => CarpsEvent(
        id: id,
        groupId: map['groupId'] ?? '',
        title: map['title'] ?? '',
        description: map['description'] ?? '',
        location: map['location'] ?? '',
        dateTime: DateTime.parse(map['dateTime']),
        tags: List<String>.from(map['tags'] ?? []),
        attendeeIds: List<String>.from(map['attendeeIds'] ?? []),
      );
}