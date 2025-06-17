class EventParticipant {
  final int id;
  final int eventId;
  final String username;
  final DateTime createdAt;

  EventParticipant({
    required this.id,
    required this.eventId,
    required this.username,
    required this.createdAt,
  });

  factory EventParticipant.fromJson(Map<String, dynamic> json) {
    int _parse(dynamic v) => v is int ? v : int.parse(v.toString());
    return EventParticipant(
      id: _parse(json['id']),
      eventId: _parse(json['eventId']),
      username: json['username'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}