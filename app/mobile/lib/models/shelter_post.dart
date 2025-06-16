import '../settings.dart';

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
    final baseUrl = Settings.getServerUrl();

    print('🔍 ShelterPost fromBackendJson: $json');

    String postTitle = 'Bez tytułu';
    if (json['title'] != null && json['title'].toString().isNotEmpty) {
      postTitle = json['title'].toString();
    } else if (json['name'] != null && json['name'].toString().isNotEmpty) {
      postTitle = json['name'].toString();
    }

    String postDescription = '';
    if (json['longDescription'] != null && json['longDescription'].toString().isNotEmpty) {
      postDescription = json['longDescription'].toString();
    } else if (json['shortDescription'] != null && json['shortDescription'].toString().isNotEmpty) {
      postDescription = json['shortDescription'].toString();
    } else if (json['description'] != null && json['description'].toString().isNotEmpty) {
      postDescription = json['description'].toString();
    }

    String postImageUrl = 'https://images.pexels.com/photos/406014/pexels-photo-406014.jpeg';
    if (json['mainImageId'] != null) {
      postImageUrl = '$baseUrl/images/${json['mainImageId']}';
      print('📸 Using mainImageId for URL: $postImageUrl');
    } else if (json['imageUrl'] != null && json['imageUrl'].toString().isNotEmpty) {
      String directUrl = json['imageUrl'].toString();
      if (directUrl.contains('localhost')) {
        final host = Uri.parse(Settings.getServerUrl()).host;
        directUrl = directUrl.replaceAll('localhost', host);
      }
      postImageUrl = directUrl;
      print('📸 Using direct imageUrl: $postImageUrl');
    }

    return ShelterPost(
      id: json['id'].toString(),
      title: postTitle,
      shelterName: 'Schronisko',
      description: postDescription,
      imageUrl: postImageUrl,
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

  ShelterPost copyWith({String? imageUrl}) {
    return ShelterPost(
      id: id,
      title: title,
      shelterName: shelterName,
      description: description,
      imageUrl: imageUrl ?? this.imageUrl,
      date: date,
      location: location,
      supportOptions: supportOptions,
      shelterId: shelterId,
      mainImageId: mainImageId,
      fundraisingId: fundraisingId,
      imageIds: imageIds,
    );
  }
}