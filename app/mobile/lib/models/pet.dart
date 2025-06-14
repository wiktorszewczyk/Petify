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
  final String? imageUrl; // Główne zdjęcie z backend
  final List<String>? images; // Dodatkowe zdjęcia z backend

  // Dodatkowe pola dla kompatybilności z frontendem
  final String? shelterName;
  final String? shelterAddress;
  final double? distance; // obliczane po stronie frontu, w kilometrach

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
    this.imageUrl,
    this.images,
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
      imageUrl: json['imageUrl'],
      images: json['images'] != null
          ? (json['images'] as List).map((img) => img['imageUrl'] as String).toList()
          : null,
      shelterName: json['shelterName'],
      shelterAddress: json['shelterAddress'],
      distance: json['distance']?.toDouble(),
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
      'imageUrl': imageUrl,
      'images': images,
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

  // Getter dla URL zdjęcia z kontrolą błędów
  String get imageUrlSafe {
    if (imageUrl != null && imageUrl!.isNotEmpty) {
      return imageUrl!;
    }
    // Fallback do placeholder
    return 'assets/images/empty_pets.png';
  }

  List<String> get galleryImages {
    return images ?? [];
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

  // Getter dla sformatowanej odległości
  String get formattedDistance {
    if (distance == null) return 'Nieznana odległość';

    if (distance! < 1) {
      return '${(distance! * 1000).round()} m';
    } else if (distance! < 10) {
      return '${distance!.toStringAsFixed(1)} km';
    } else {
      return '${distance!.round()} km';
    }
  }
}