class Event {
  final String id;
  final String title;
  final String organizerName;
  final String description;
  final String imageUrl;
  final DateTime date;
  final DateTime? endDate;
  final String location;
  final int? participantsCount;
  final String? eventType; // "Warsztaty", "Spacer", "Dzień otwarty", etc.
  final bool requiresRegistration;

  Event({
    required this.id,
    required this.title,
    required this.organizerName,
    required this.description,
    required this.imageUrl,
    required this.date,
    this.endDate,
    required this.location,
    this.participantsCount,
    this.eventType,
    this.requiresRegistration = false,
  });

  factory Event.fromJson(Map<String, dynamic> json) {
    return Event(
      id: json['id'],
      title: json['title'],
      organizerName: json['organizerName'],
      description: json['description'],
      imageUrl: json['imageUrl'],
      date: DateTime.parse(json['date']),
      endDate: json['endDate'] != null ? DateTime.parse(json['endDate']) : null,
      location: json['location'],
      participantsCount: json['participantsCount'],
      eventType: json['eventType'],
      requiresRegistration: json['requiresRegistration'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'organizerName': organizerName,
      'description': description,
      'imageUrl': imageUrl,
      'date': date.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
      'location': location,
      'participantsCount': participantsCount,
      'eventType': eventType,
      'requiresRegistration': requiresRegistration,
    };
  }
}