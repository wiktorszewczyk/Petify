enum DonationType {
  monetary,
  material,
}

class MaterialDonationItem {
  final String name;
  final double price;
  final String iconPath;
  final String apiName;

  const MaterialDonationItem({
    required this.name,
    required this.price,
    required this.iconPath,
    required this.apiName,
  });

  /// Lista aktualnie "dostępnych" przedmiotów – jeśli w przyszłości
  /// będziemy pobierać je z backendu, wystarczy podmienić tę metodę.
  static List<MaterialDonationItem> getAvailableItems() {
    return [
      MaterialDonationItem(
        name: 'Smakołyk',
        price: 5.0,
        iconPath: 'assets/icons/pet_snack.png',
        apiName: 'Pet Snack',
      ),
      MaterialDonationItem(
        name: 'Pełna miska',
        price: 10.0,
        iconPath: 'assets/icons/pet_bowl.png',
        apiName: 'Pet Bowl',
      ),
      MaterialDonationItem(
        name: 'Zabawka',
        price: 15.0,
        iconPath: 'assets/icons/pet_toy.png',
        apiName: 'Pet Toy',
      ),
      MaterialDonationItem(
        name: 'Zapas karmy',
        price: 25.0,
        iconPath: 'assets/icons/pet_food.png',
        apiName: 'Pet Food',
      ),
      MaterialDonationItem(
        name: 'Legowisko',
        price: 50.0,
        iconPath: 'assets/icons/pet_bed.png',
        apiName: 'Pet Bed',
      ),
    ];
  }
}

class Donation {
  final String id;
  final double amount;
  final DateTime date;
  final String shelterName;
  final String? message;
  final DonationType type;
  final String? petId; // ID zwierzaka (tylko gdy type == material)
  final MaterialDonationItem? materialItem; // Przedmiot (tylko gdy type == material)
  final int? quantity; // Ilość (tylko gdy type == material)
  final String? status;
  final int? shelterId;
  final int? fundraiserId;
  final double? serviceFee;
  final double? netAmount;

  const Donation({
    required this.id,
    required this.amount,
    required this.date,
    required this.shelterName,
    required this.type,
    this.message,
    this.petId,
    this.materialItem,
    this.quantity = 1,
    this.status,
    this.shelterId,
    this.fundraiserId,
    this.serviceFee,
    this.netAmount,
  });

  factory Donation.fromBackendJson(Map<String, dynamic> json) {
    final donationType = json['donationType'] == 'MATERIAL'
        ? DonationType.material
        : DonationType.monetary;

    MaterialDonationItem? materialItem;
    if (donationType == DonationType.material && json['itemName'] != null) {
      final availableItems = MaterialDonationItem.getAvailableItems();
      materialItem = availableItems.firstWhere(
              (item) => item.apiName == json['itemName'],
        orElse: () => MaterialDonationItem(
          name: json['itemName'] ?? 'Nieznany przedmiot',
          price: (json['unitPrice'] ?? 0.0).toDouble(),
          iconPath: 'assets/icons/pet_food.png',
          apiName: json['itemName'] ?? 'Unknown',
        ),
      );
    }

    return Donation(
      id: json['id'].toString(),
      amount: (json['amount'] ?? 0.0).toDouble(),
      date: json['donatedAt'] != null
          ? DateTime.parse(json['donatedAt'])
          : (json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now()),
      shelterName: 'Schronisko ${json['shelterId'] ?? 'Nieznane'}',
      message: json['message'],
      type: donationType,
      petId: json['petId']?.toString(),
      materialItem: materialItem,
      quantity: json['quantity'],
      status: json['status'],
      shelterId: json['shelterId'],
      fundraiserId: json['fundraiserId'],
      serviceFee: (json['totalFeeAmount'] ?? 0.0).toDouble(),
      netAmount: (json['netAmount'] ?? 0.0).toDouble(),
    );
  }

  factory Donation.material({
    required String shelterName,
    required String petId,
    required MaterialDonationItem item,
    required int quantity,
    String? message,
  }) {
    return Donation(
      id: 'don_${DateTime.now().millisecondsSinceEpoch}',
      amount: item.price * quantity,
      date: DateTime.now(),
      shelterName: shelterName,
      type: DonationType.material,
      message: message,
      petId: petId,
      materialItem: item,
      quantity: quantity,
    );
  }

  factory Donation.monetary({
    required String shelterName,
    required double amount,
    String? message,
  }) {
    return Donation(
      id: 'don_${DateTime.now().millisecondsSinceEpoch}',
      amount: amount,
      date: DateTime.now(),
      shelterName: shelterName,
      type: DonationType.monetary,
      message: message,
    );
  }
}

class DonationResponse {
  final int id;
  final int shelterId;
  final int? petId;
  final int? fundraiserId;
  final String donationType;
  final double amount;
  final String? message;
  final bool anonymous;
  final String? itemName;
  final double? unitPrice;
  final int? quantity;
  final String status;
  final DateTime createdAt;
  final DateTime? donatedAt;
  final double? totalFeeAmount;
  final double? netAmount;

  DonationResponse({
    required this.id,
    required this.shelterId,
    this.petId,
    this.fundraiserId,
    required this.donationType,
    required this.amount,
    this.message,
    required this.anonymous,
    this.itemName,
    this.unitPrice,
    this.quantity,
    required this.status,
    required this.createdAt,
    this.donatedAt,
    this.totalFeeAmount,
    this.netAmount,
  });

  factory DonationResponse.fromJson(Map<String, dynamic> json) {
    return DonationResponse(
      id: json['id'],
      shelterId: json['shelterId'],
      petId: json['petId'],
      fundraiserId: json['fundraiserId'],
      donationType: json['donationType'],
      amount: (json['amount'] ?? 0.0).toDouble(),
      message: json['message'],
      anonymous: json['anonymous'] ?? false,
      itemName: json['itemName'],
      unitPrice: json['unitPrice']?.toDouble(),
      quantity: json['quantity'],
      status: json['status'],
      createdAt: DateTime.parse(json['createdAt']),
      donatedAt: json['donatedAt'] != null ? DateTime.parse(json['donatedAt']) : null,
      totalFeeAmount: json['totalFeeAmount']?.toDouble(),
      netAmount: json['netAmount']?.toDouble(),
    );
  }
}

class PaymentFeeCalculation {
  final double grossAmount;
  final double feeAmount;
  final double netAmount;
  final double feePercentage;

  PaymentFeeCalculation({
    required this.grossAmount,
    required this.feeAmount,
    required this.netAmount,
    required this.feePercentage,
  });

  factory PaymentFeeCalculation.fromJson(Map<String, dynamic> json) {
    return PaymentFeeCalculation(
      grossAmount: (json['grossAmount'] ?? 0.0).toDouble(),
      feeAmount: (json['feeAmount'] ?? 0.0).toDouble(),
      netAmount: (json['netAmount'] ?? 0.0).toDouble(),
      feePercentage: (json['feePercentage'] ?? 0.0).toDouble(),
    );
  }
}

class PaymentMethodOption {
  final String method;
  final String displayName;
  final bool requiresAdditionalInfo;

  PaymentMethodOption({
    required this.method,
    required this.displayName,
    required this.requiresAdditionalInfo,
  });

  factory PaymentMethodOption.fromJson(Map<String, dynamic> json) {
    return PaymentMethodOption(
      method: json['method'],
      displayName: json['displayName'],
      requiresAdditionalInfo: json['requiresAdditionalInfo'] ?? false,
    );
  }
}

class PaymentProviderOption {
  final String provider;
  final String displayName;
  final bool recommended;
  final PaymentFeeCalculation fees;
  final List<PaymentMethodOption> supportedMethods;

  PaymentProviderOption({
    required this.provider,
    required this.displayName,
    required this.recommended,
    required this.fees,
    required this.supportedMethods,
  });

  factory PaymentProviderOption.fromJson(Map<String, dynamic> json) {
    return PaymentProviderOption(
      provider: json['provider'],
      displayName: json['displayName'],
      recommended: json['recommended'] ?? false,
      fees: PaymentFeeCalculation.fromJson(json['fees']),
      supportedMethods: (json['supportedMethods'] as List)
          .map((method) => PaymentMethodOption.fromJson(method))
          .toList(),
    );
  }
}

class PaymentOptionsResponse {
  final int donationId;
  final DonationResponse donation;
  final List<PaymentProviderOption> availableProviders;
  final String sessionToken;

  PaymentOptionsResponse({
    required this.donationId,
    required this.donation,
    required this.availableProviders,
    required this.sessionToken,
  });

  factory PaymentOptionsResponse.fromJson(Map<String, dynamic> json) {
    return PaymentOptionsResponse(
      donationId: json['donationId'],
      donation: DonationResponse.fromJson(json['donation']),
      availableProviders: (json['availableProviders'] as List)
          .map((provider) => PaymentProviderOption.fromJson(provider))
          .toList(),
      sessionToken: json['sessionToken'],
    );
  }
}

typedef DonationIntentResponse = PaymentOptionsResponse;

class PaymentInitializationResponse {
  final PaymentInfo payment;
  final PaymentUiConfig uiConfig;

  PaymentInitializationResponse({
    required this.payment,
    required this.uiConfig,
  });

  factory PaymentInitializationResponse.fromJson(Map<String, dynamic> json) {
    return PaymentInitializationResponse(
      payment: PaymentInfo.fromJson(json['payment']),
      uiConfig: PaymentUiConfig.fromJson(json['uiConfig']),
    );
  }
}

class PaymentInfo {
  final int id;
  final String status;
  final String? checkoutUrl;
  final String? externalId;

  PaymentInfo({
    required this.id,
    required this.status,
    this.checkoutUrl,
    this.externalId,
  });

  factory PaymentInfo.fromJson(Map<String, dynamic> json) {
    return PaymentInfo(
      id: json['id'],
      status: json['status'],
      checkoutUrl: json['checkoutUrl'],
      externalId: json['externalId'],
    );
  }
}

class PaymentUiConfig {
  final String provider;
  final bool hasNativeSDK;
  final String? sdkConfiguration;

  PaymentUiConfig({
    required this.provider,
    required this.hasNativeSDK,
    this.sdkConfiguration,
  });

  factory PaymentUiConfig.fromJson(Map<String, dynamic> json) {
    return PaymentUiConfig(
      provider: json['provider'],
      hasNativeSDK: json['hasNativeSDK'] ?? false,
      sdkConfiguration: json['sdkConfiguration'],
    );
  }
}

class DonationWithPaymentStatusResponse {
  final DonationResponse donation;
  final PaymentResponse? latestPayment;
  final bool isCompleted;
  final String? message;

  DonationWithPaymentStatusResponse({
    required this.donation,
    this.latestPayment,
    required this.isCompleted,
    this.message,
  });

  factory DonationWithPaymentStatusResponse.fromJson(Map<String, dynamic> json) {
    return DonationWithPaymentStatusResponse(
      donation: DonationResponse.fromJson(json['donation']),
      latestPayment: json['latestPayment'] != null
          ? PaymentResponse.fromJson(json['latestPayment'])
          : null,
      isCompleted: json['isCompleted'] ?? false,
      message: json['message'] ?? json['statusMessage'],
    );
  }

  String get statusMessage {
    if (isCompleted) {
      return "Płatność została zakończona pomyślnie. Dziękujemy za dotację!";
    } else if (latestPayment != null) {
      switch (latestPayment!.status) {
        case 'PENDING':
          return "Płatność oczekuje na realizację";
        case 'PROCESSING':
          return "Płatność jest przetwarzana";
        case 'FAILED':
          return "Płatność nie powiodła się";
        case 'CANCELLED':
          return "Płatność została anulowana";
        default:
          return "Status płatności: ${latestPayment!.status}";
      }
    }
    return "Brak informacji o płatności";
  }
}

class PaymentResponse {
  final int id;
  final String status;
  final double amount;
  final String provider;
  final String method;
  final DateTime createdAt;
  final DateTime? completedAt;
  final String? failureReason;
  final String? externalId;

  PaymentResponse({
    required this.id,
    required this.status,
    required this.amount,
    required this.provider,
    required this.method,
    required this.createdAt,
    this.completedAt,
    this.failureReason,
    this.externalId,
  });

  factory PaymentResponse.fromJson(Map<String, dynamic> json) {
    return PaymentResponse(
      id: json['id'],
      status: json['status'] ?? 'UNKNOWN',
      amount: (json['amount'] ?? 0.0).toDouble(),
      provider: json['provider'] ?? 'UNKNOWN',
      method: json['paymentMethod'] ?? 'UNKNOWN',
      createdAt: DateTime.parse(json['createdAt']),
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'])
          : null,
      failureReason: json['failureReason'],
      externalId: json['externalId'],
    );
  }
}

class PaymentStatusResponse {
  final String status;
  final String? failureReason;
  final DateTime? completedAt;

  PaymentStatusResponse({
    required this.status,
    this.failureReason,
    this.completedAt,
  });

  factory PaymentStatusResponse.fromJson(Map<String, dynamic> json) {
    return PaymentStatusResponse(
      status: json['status'],
      failureReason: json['failureReason'],
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'])
          : null,
    );
  }
}

class FundraiserResponse {
  final int id;
  final int shelterId;
  final String title;
  final String description;
  final double goalAmount;
  final double currentAmount;
  final double progressPercentage;
  final bool isMain;
  final String status;
  final bool canAcceptDonations;

  FundraiserResponse({
    required this.id,
    required this.shelterId,
    required this.title,
    required this.description,
    required this.goalAmount,
    required this.currentAmount,
    required this.progressPercentage,
    required this.isMain,
    required this.status,
    required this.canAcceptDonations,
  });

  factory FundraiserResponse.fromJson(Map<String, dynamic> json) {
    return FundraiserResponse(
      id: json['id'],
      shelterId: json['shelterId'],
      title: json['title'],
      description: json['description'],
      goalAmount: (json['goalAmount'] ?? 0.0).toDouble(),
      currentAmount: (json['currentAmount'] ?? 0.0).toDouble(),
      progressPercentage: (json['progressPercentage'] ?? 0.0).toDouble(),
      isMain: json['isMain'] ?? false,
      status: json['status'],
      canAcceptDonations: json['canAcceptDonations'] ?? false,
    );
  }
}