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
    try {
      // Helper function to safely parse integers
      int _parseId(dynamic value) {
        if (value is int) return value;
        if (value is String) return int.parse(value);
        if (value is num) return value.toInt();
        throw FormatException('Cannot parse ID from: $value');
      }

      // Helper function to safely parse boolean
      bool _parseBool(dynamic value) {
        if (value is bool) return value;
        if (value is String) return value.toLowerCase() == 'true';
        if (value is num) return value != 0;
        return false;
      }

      return AdoptionResponse(
        id: _parseId(json['id']),
        username: json['username']?.toString() ?? '',
        petId: _parseId(json['petId']),
        adoptionStatus: json['adoptionStatus']?.toString() ?? 'PENDING',
        motivationText: json['motivationText']?.toString() ?? '',
        fullName: json['fullName']?.toString() ?? '',
        phoneNumber: json['phoneNumber']?.toString() ?? '',
        address: json['address']?.toString() ?? '',
        housingType: json['housingType']?.toString() ?? '',
        isHouseOwner: _parseBool(json['isHouseOwner']),
        hasYard: _parseBool(json['hasYard']),
        hasOtherPets: _parseBool(json['hasOtherPets']),
        description: json['description']?.toString(),
      );
    } catch (e) {
      throw FormatException('Error parsing AdoptionResponse from JSON: $e\nJSON: $json');
    }
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