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
  final int? capacity;
  final int? shelterId;
  final int? mainImageId;
  final int? fundraisingId;

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
    this.capacity,
    this.shelterId,
    this.mainImageId,
    this.fundraisingId,
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

  factory Event.fromBackendJson(Map<String, dynamic> json) {
    final baseUrl = 'http://192.168.1.12:8222';

    return Event(
      id: json['id'].toString(),
      title: json['title'] ?? '',
      organizerName: 'Schronisko', // Will be filled by shelter info if needed
      description: json['longDescription'] ?? json['shortDescription'] ?? '',
      imageUrl: json['mainImageId'] != null
          ? '$baseUrl/images/${json['mainImageId']}'
          : 'https://images.pexels.com/photos/1633522/pexels-photo-1633522.jpeg',
      date: DateTime.parse(json['startDate']),
      endDate: json['endDate'] != null ? DateTime.parse(json['endDate']) : null,
      location: json['address'] ?? '',
      capacity: json['capacity'],
      requiresRegistration: json['capacity'] != null,
      shelterId: json['shelterId'],
      mainImageId: json['mainImageId'],
      fundraisingId: json['fundraisingId'],
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