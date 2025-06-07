class AdoptionRequest {
  final String motivationText;
  final String fullName;
  final String phoneNumber;
  final String address;
  final String housingType;
  final bool isHouseOwner;
  final bool hasYard;
  final bool hasOtherPets;
  final String? description;

  AdoptionRequest({
    required this.motivationText,
    required this.fullName,
    required this.phoneNumber,
    required this.address,
    required this.housingType,
    required this.isHouseOwner,
    required this.hasYard,
    required this.hasOtherPets,
    this.description,
  });

  Map<String, dynamic> toJson() {
    return {
      'motivationText': motivationText,
      'fullName': fullName,
      'phoneNumber': phoneNumber,
      'address': address,
      'housingType': housingType,
      'isHouseOwner': isHouseOwner,
      'hasYard': hasYard,
      'hasOtherPets': hasOtherPets,
      'description': description,
    };
  }
}

class AdoptionResponse {
  final int id;
  final String username;
  final int petId;
  final String adoptionStatus; // PENDING, ACCEPTED, REJECTED, CANCELLED
  final String motivationText;
  final String fullName;
  final String phoneNumber;
  final String address;
  final String housingType;
  final bool isHouseOwner;
  final bool hasYard;
  final bool hasOtherPets;
  final String? description;

  AdoptionResponse({
    required this.id,
    required this.username,
    required this.petId,
    required this.adoptionStatus,
    required this.motivationText,
    required this.fullName,
    required this.phoneNumber,
    required this.address,
    required this.housingType,
    required this.isHouseOwner,
    required this.hasYard,
    required this.hasOtherPets,
    this.description,
  });

  factory AdoptionResponse.fromJson(Map<String, dynamic> json) {
    return AdoptionResponse(
      id: json['id'] is String ? int.parse(json['id']) : json['id'],
      username: json['username'] ?? '',
      petId: json['petId'] is String ? int.parse(json['petId']) : json['petId'],
      adoptionStatus: json['adoptionStatus'] ?? 'PENDING',
      motivationText: json['motivationText'] ?? '',
      fullName: json['fullName'] ?? '',
      phoneNumber: json['phoneNumber'] ?? '',
      address: json['address'] ?? '',
      housingType: json['housingType'] ?? '',
      isHouseOwner: json['isHouseOwner'] ?? false,
      hasYard: json['hasYard'] ?? false,
      hasOtherPets: json['hasOtherPets'] ?? false,
      description: json['description'],
    );
  }

  String get statusDisplayName {
    switch (adoptionStatus.toUpperCase()) {
      case 'PENDING':
        return 'Oczekuje';
      case 'ACCEPTED':
        return 'Zaakceptowany';
      case 'REJECTED':
        return 'Odrzucony';
      case 'CANCELLED':
        return 'Anulowany';
      default:
        return 'Nieznany';
    }
  }
}