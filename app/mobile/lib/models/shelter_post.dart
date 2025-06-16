class ShelterPost {
  final String id;
  final String title;
  final String shelterName;
  final String description;
  final String imageUrl;
  final DateTime date;
  final String? location;
  final Map<String, dynamic>? supportOptions;
  final int? shelterId;
  final int? mainImageId;
  final int? fundraisingId;
  final List<int>? imageIds;

  ShelterPost({
    required this.id,
    required this.title,
    required this.shelterName,
    required this.description,
    required this.imageUrl,
    required this.date,
    this.location,
    this.supportOptions,
    this.shelterId,
    this.mainImageId,
    this.fundraisingId,
    this.imageIds,
  });

  factory ShelterPost.fromJson(Map<String, dynamic> json) {
    return ShelterPost(
      id: json['id'],
      title: json['title'],
      shelterName: json['shelterName'],
      description: json['description'],
      imageUrl: json['imageUrl'],
      date: DateTime.parse(json['date']),
      location: json['location'],
      supportOptions: json['supportOptions'],
    );
  }

  factory ShelterPost.fromBackendJson(Map<String, dynamic> json) {
    return ShelterPost(
      id: json['id'].toString(),
      title: json['title'] ?? '',
      shelterName: 'Schronisko', // Will be filled by shelter info if needed
      description: json['longDescription'] ?? json['shortDescription'] ?? '',
      imageUrl: json['mainImageId'] != null
          ? 'http://localhost:8222/images/${json['mainImageId']}'
          : 'https://images.pexels.com/photos/406014/pexels-photo-406014.jpeg',
      date: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      shelterId: json['shelterId'],
      mainImageId: json['mainImageId'],
      fundraisingId: json['fundraisingId'],
      imageIds: json['imageIds'] != null
          ? List<int>.from(json['imageIds'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'shelterName': shelterName,
      'description': description,
      'imageUrl': imageUrl,
      'date': date.toIso8601String(),
      'location': location,
      'supportOptions': supportOptions,
    };
  }
}