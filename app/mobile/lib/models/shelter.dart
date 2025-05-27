class Shelter {
  final String id;
  final String name;
  final String address;
  final String description;
  final String imageUrl;
  final int petsCount;
  final int volunteersCount;
  final List<String> needs;
  final String phoneNumber;
  final String email;
  final String? website;
  final bool isUrgent;
  final double donationGoal;
  final double donationCurrent;
  final String city;

  Shelter({
    required this.id,
    required this.name,
    required this.address,
    required this.description,
    required this.imageUrl,
    required this.petsCount,
    required this.volunteersCount,
    required this.needs,
    required this.phoneNumber,
    required this.email,
    this.website,
    required this.isUrgent,
    required this.donationGoal,
    required this.donationCurrent,
    required this.city,
  });

  double get donationPercentage =>
      donationGoal > 0 ? (donationCurrent / donationGoal * 100).clamp(0, 100) : 0;

  factory Shelter.fromMap(Map<String, dynamic> map) {
    return Shelter(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      address: map['address'] ?? '',
      description: map['description'] ?? '',
      imageUrl: map['imageUrl'] ?? '',
      petsCount: map['petsCount'] ?? 0,
      volunteersCount: map['volunteersCount'] ?? 0,
      needs: List<String>.from(map['needs'] ?? []),
      phoneNumber: map['phoneNumber'] ?? '',
      email: map['email'] ?? '',
      website: map['website'],
      isUrgent: map['isUrgent'] ?? false,
      donationGoal: map['donationGoal']?.toDouble() ?? 0.0,
      donationCurrent: map['donationCurrent']?.toDouble() ?? 0.0,
      city: map['city'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'address': address,
      'description': description,
      'imageUrl': imageUrl,
      'petsCount': petsCount,
      'volunteersCount': volunteersCount,
      'needs': needs,
      'phoneNumber': phoneNumber,
      'email': email,
      'website': website,
      'isUrgent': isUrgent,
      'donationGoal': donationGoal,
      'donationCurrent': donationCurrent,
      'city': city,
    };
  }
}