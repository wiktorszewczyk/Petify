class PetModel {
  final String id;
  final String name;
  final int age;
  final String gender;
  final String breed;
  final String size;
  final String description;
  final String imageUrl;
  final List<String> galleryImages;
  final int distance;
  final bool isVaccinated;
  final bool isNeutered;
  final bool isChildFriendly;
  final bool isUrgent;
  final String shelterName;
  final String shelterAddress;

  PetModel({
    required this.id,
    required this.name,
    required this.age,
    required this.gender,
    required this.breed,
    required this.size,
    required this.description,
    required this.imageUrl,
    required this.galleryImages,
    required this.distance,
    required this.isVaccinated,
    required this.isNeutered,
    required this.isChildFriendly,
    required this.isUrgent,
    required this.shelterName,
    required this.shelterAddress,
  });

  factory PetModel.fromJson(Map<String, dynamic> json) {
    return PetModel(
      id: json['id'] as String,
      name: json['name'] as String,
      age: json['age'] as int,
      gender: json['gender'] as String,
      breed: json['breed'] as String,
      size: json['size'] as String,
      description: json['description'] as String,
      imageUrl: json['imageUrl'] as String,
      galleryImages: (json['galleryImages'] as List).map((e) => e as String).toList(),
      distance: json['distance'] as int,
      isVaccinated: json['isVaccinated'] as bool,
      isNeutered: json['isNeutered'] as bool,
      isChildFriendly: json['isChildFriendly'] as bool,
      isUrgent: json['isUrgent'] as bool,
      shelterName: json['shelterName'] as String,
      shelterAddress: json['shelterAddress'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'age': age,
      'gender': gender,
      'breed': breed,
      'size': size,
      'description': description,
      'imageUrl': imageUrl,
      'galleryImages': galleryImages,
      'distance': distance,
      'isVaccinated': isVaccinated,
      'isNeutered': isNeutered,
      'isChildFriendly': isChildFriendly,
      'isUrgent': isUrgent,
      'shelterName': shelterName,
      'shelterAddress': shelterAddress,
    };
  }
}