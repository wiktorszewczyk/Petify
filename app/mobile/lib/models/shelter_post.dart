class ShelterPost {
  final String id;
  final String title;
  final String shelterName;
  final String description;
  final String imageUrl;
  final DateTime date;
  final String? location;
  final Map<String, dynamic>? supportOptions;

  ShelterPost({
    required this.id,
    required this.title,
    required this.shelterName,
    required this.description,
    required this.imageUrl,
    required this.date,
    this.location,
    this.supportOptions,
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