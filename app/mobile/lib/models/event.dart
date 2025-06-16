import '../settings.dart';

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
  final String? eventType;
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
    final baseUrl = Settings.getServerUrl();

    return Event(
      id: json['id'].toString(),
      title: json['title'] ?? '',
      organizerName: 'Schronisko',
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

  Event copyWith({
    String? id,
    String? title,
    String? organizerName,
    String? description,
    String? imageUrl,
    DateTime? date,
    DateTime? endDate,
    String? location,
    int? participantsCount,
    String? eventType,
    bool? requiresRegistration,
    int? capacity,
    int? shelterId,
    int? mainImageId,
    int? fundraisingId,
  }) {
    return Event(
      id: id ?? this.id,
      title: title ?? this.title,
      organizerName: organizerName ?? this.organizerName,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      date: date ?? this.date,
      endDate: endDate ?? this.endDate,
      location: location ?? this.location,
      participantsCount: participantsCount ?? this.participantsCount,
      eventType: eventType ?? this.eventType,
      requiresRegistration: requiresRegistration ?? this.requiresRegistration,
      capacity: capacity ?? this.capacity,
      shelterId: shelterId ?? this.shelterId,
      mainImageId: mainImageId ?? this.mainImageId,
      fundraisingId: fundraisingId ?? this.fundraisingId,
    );
  }
}