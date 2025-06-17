class Shelter {
  final int id;
  final String ownerUsername;
  final String name;
  final String? description;
  final String? address;
  final String? phoneNumber;
  final double? latitude;
  final double? longitude;
  final bool isActive;
  final String? imageName;
  final String? imageType;
  final String? imageData; // Base64
  final String? imageUrl; // Direct URL

  final int? petsCount;
  final int? volunteersCount;
  final List<String>? needs;
  final String? email;
  final String? website;
  final bool? isUrgent;
  final double? donationGoal;
  final double? donationCurrent;
  final String? city;

  Shelter({
    required this.id,
    required this.ownerUsername,
    required this.name,
    this.description,
    this.address,
    this.phoneNumber,
    this.latitude,
    this.longitude,
    required this.isActive,
    this.imageName,
    this.imageType,
    this.imageData,
    this.imageUrl,
    this.petsCount,
    this.volunteersCount,
    this.needs,
    this.email,
    this.website,
    this.isUrgent,
    this.donationGoal,
    this.donationCurrent,
    this.city,
  });

  factory Shelter.fromJson(Map<String, dynamic> json) {
    return Shelter(
      id: json['id'] is String ? int.parse(json['id']) : json['id'],
      ownerUsername: json['ownerUsername'] ?? '',
      name: json['name'] ?? '',
      description: json['description'],
      address: json['address'],
      phoneNumber: json['phoneNumber'],
      latitude: json['latitude']?.toDouble(),
      longitude: json['longitude']?.toDouble(),
      isActive: json['isActive'] ?? false,
      imageName: json['imageName'],
      imageType: json['imageType'],
      imageData: json['imageData'],
      imageUrl: json['imageUrl'],
      petsCount: json['petsCount'],
      volunteersCount: json['volunteersCount'],
      needs: json['needs'] != null ? List<String>.from(json['needs']) : null,
      email: json['email'],
      website: json['website'],
      isUrgent: json['isUrgent'],
      donationGoal: json['donationGoal']?.toDouble(),
      donationCurrent: json['donationCurrent']?.toDouble(),
      city: json['city'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'ownerUsername': ownerUsername,
      'name': name,
      'description': description,
      'address': address,
      'phoneNumber': phoneNumber,
      'latitude': latitude,
      'longitude': longitude,
      'isActive': isActive,
      'imageName': imageName,
      'imageType': imageType,
      'imageData': imageData,
      'imageUrl': imageUrl,
      'petsCount': petsCount,
      'volunteersCount': volunteersCount,
      'needs': needs,
      'email': email,
      'website': website,
      'isUrgent': isUrgent,
      'donationGoal': donationGoal,
      'donationCurrent': donationCurrent,
      'city': city,
    };
  }

  String get finalImageUrl {
    if (imageUrl != null && imageUrl!.isNotEmpty) {
      return imageUrl!;
    }

    if (imageData != null && imageData!.isNotEmpty) {
      if (imageData!.startsWith('data:image')) {
        return imageData!;
      }
      final mimeType = imageType ?? 'image/jpeg';
      return 'data:$mimeType;base64,$imageData';
    }

    return 'assets/images/default_shelter.jpg';
  }

  double get donationPercentage {
    if (donationGoal == null || donationGoal! <= 0) return 0;
    if (donationCurrent == null) return 0;
    return ((donationCurrent! / donationGoal!) * 100).clamp(0, 100);
  }

  Shelter copyWith({
    int? id,
    String? ownerUsername,
    String? name,
    String? description,
    String? address,
    String? phoneNumber,
    double? latitude,
    double? longitude,
    bool? isActive,
    String? imageName,
    String? imageType,
    String? imageData,
    String? imageUrl,
    int? petsCount,
    int? volunteersCount,
    List<String>? needs,
    String? email,
    String? website,
    bool? isUrgent,
    double? donationGoal,
    double? donationCurrent,
    String? city,
  }) {
    return Shelter(
      id: id ?? this.id,
      ownerUsername: ownerUsername ?? this.ownerUsername,
      name: name ?? this.name,
      description: description ?? this.description,
      address: address ?? this.address,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      isActive: isActive ?? this.isActive,
      imageName: imageName ?? this.imageName,
      imageType: imageType ?? this.imageType,
      imageData: imageData ?? this.imageData,
      imageUrl: imageUrl ?? this.imageUrl,
      petsCount: petsCount ?? this.petsCount,
      volunteersCount: volunteersCount ?? this.volunteersCount,
      needs: needs ?? this.needs,
      email: email ?? this.email,
      website: website ?? this.website,
      isUrgent: isUrgent ?? this.isUrgent,
      donationGoal: donationGoal ?? this.donationGoal,
      donationCurrent: donationCurrent ?? this.donationCurrent,
      city: city ?? this.city,
    );
  }
}