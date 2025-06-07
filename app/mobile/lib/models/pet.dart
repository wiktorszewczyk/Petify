import 'dart:convert';

class Pet {
  final int id;
  final String name;
  final String type; // CAT, DOG, OTHER
  final String? breed;
  final int age;
  final bool archived;
  final String? description;
  final int shelterId;
  final String gender; // MALE, FEMALE, UNKNOWN
  final String size; // SMALL, MEDIUM, BIG, VERY_BIG
  final bool vaccinated;
  final bool urgent;
  final bool sterilized;
  final bool kidFriendly;
  final String? imageName;
  final String? imageType;
  final String? imageData; // Base64

  // Dodatkowe pola dla kompatybilności z frontendem
  final String? shelterName;
  final String? shelterAddress;
  final int? distance; // obliczane po stronie frontu

  Pet({
    required this.id,
    required this.name,
    required this.type,
    this.breed,
    required this.age,
    this.archived = false,
    this.description,
    required this.shelterId,
    required this.gender,
    required this.size,
    required this.vaccinated,
    required this.urgent,
    required this.sterilized,
    required this.kidFriendly,
    this.imageName,
    this.imageType,
    this.imageData,
    this.shelterName,
    this.shelterAddress,
    this.distance,
  });

  factory Pet.fromJson(Map<String, dynamic> json) {
    return Pet(
      id: json['id'] is String ? int.parse(json['id']) : json['id'],
      name: json['name'] ?? '',
      type: json['type'] ?? 'OTHER',
      breed: json['breed'],
      age: json['age'] ?? 0,
      archived: json['archived'] ?? false,
      description: json['description'],
      shelterId: json['shelterId'] is String ? int.parse(json['shelterId']) : json['shelterId'],
      gender: _mapGender(json['gender']),
      size: _mapSize(json['size']),
      vaccinated: json['vaccinated'] ?? false,
      urgent: json['urgent'] ?? false,
      sterilized: json['sterilized'] ?? false,
      kidFriendly: json['kidFriendly'] ?? false,
      imageName: json['imageName'],
      imageType: json['imageType'],
      imageData: json['imageData'],
      shelterName: json['shelterName'],
      shelterAddress: json['shelterAddress'],
      distance: json['distance'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'breed': breed,
      'age': age,
      'archived': archived,
      'description': description,
      'shelterId': shelterId,
      'gender': gender,
      'size': size,
      'vaccinated': vaccinated,
      'urgent': urgent,
      'sterilized': sterilized,
      'kidFriendly': kidFriendly,
      'imageName': imageName,
      'imageType': imageType,
      'imageData': imageData,
      'shelterName': shelterName,
      'shelterAddress': shelterAddress,
      'distance': distance,
    };
  }

  static String _mapGender(String? gender) {
    switch (gender?.toUpperCase()) {
      case 'MALE':
        return 'male';
      case 'FEMALE':
        return 'female';
      case 'UNKNOWN':
      default:
        return 'unknown';
    }
  }

  static String _mapSize(String? size) {
    switch (size?.toUpperCase()) {
      case 'SMALL':
        return 'small';
      case 'MEDIUM':
        return 'medium';
      case 'BIG':
        return 'large';
      case 'VERY_BIG':
        return 'xlarge';
      default:
        return 'medium';
    }
  }

  // Gettery dla kompatybilności z istniejącym kodem
  String get imageUrl {
    if (imageData != null && imageData!.isNotEmpty) {
      // Sprawdź czy to już jest data URL
      if (imageData!.startsWith('data:image')) {
        return imageData!;
      }
      // Jeśli nie, dodaj prefix
      final mimeType = imageType ?? 'image/jpeg';
      return 'data:$mimeType;base64,$imageData';
    }
    // Fallback do placeholder
    return 'assets/images/pet_placeholder.png';
  }

  List<String> get galleryImages {
    // Na razie zwracamy pustą listę, bo backend nie ma galerii w tej wersji
    // Można to rozszerzyć jeśli backend będzie obsługiwał wiele zdjęć
    return [];
  }

  // Getter dla typu zwierzęcia po polsku
  String get typeDisplayName {
    switch (type.toUpperCase()) {
      case 'CAT':
        return 'Kot';
      case 'DOG':
        return 'Pies';
      case 'OTHER':
      default:
        return 'Inne';
    }
  }

  // Getter dla rozmiaru po polsku
  String get sizeDisplayName {
    switch (size) {
      case 'small':
        return 'Mały';
      case 'medium':
        return 'Średni';
      case 'large':
        return 'Duży';
      case 'xlarge':
        return 'Bardzo duży';
      default:
        return 'Średni';
    }
  }

  // Getter dla płci po polsku
  String get genderDisplayName {
    switch (gender) {
      case 'male':
        return 'Samiec';
      case 'female':
        return 'Samica';
      default:
        return 'Nieznana';
    }
  }

  // Gettery dla kompatybilności z istniejącym kodem
  bool get isVaccinated => vaccinated;
  bool get isNeutered => sterilized;
  bool get isChildFriendly => kidFriendly;
  bool get isUrgent => urgent;
}