enum DonationType {
  monetary,
  material,
}

class MaterialDonationItem {
  final String name;
  final double price;
  final String iconPath;

  const MaterialDonationItem({
    required this.name,
    required this.price,
    required this.iconPath,
  });

  /// Lista aktualnie "dostępnych" przedmiotów – jeśli w przyszłości
  /// będziemy pobierać je z backendu, wystarczy podmienić tę metodę.
  static List<MaterialDonationItem> getAvailableItems() {
    return [
      MaterialDonationItem(
        name: 'Smakołyk',
        price: 5.0,
        iconPath: 'assets/icons/pet_snack.png',
      ),
      MaterialDonationItem(
        name: 'Pełna miska',
        price: 10.0,
        iconPath: 'assets/icons/pet_bowl.png',
      ),
      MaterialDonationItem(
        name: 'Zabawka',
        price: 15.0,
        iconPath: 'assets/icons/pet_toy.png',
      ),
      MaterialDonationItem(
        name: 'Zapas karmy',
        price: 25.0,
        iconPath: 'assets/icons/pet_food.png',
      ),
      MaterialDonationItem(
        name: 'Legowisko',
        price: 50.0,
        iconPath: 'assets/icons/pet_bed.png',
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
  });

  /// Prosta metoda generująca dane mockowe do widoków list / historii.
  factory Donation.fake(int i) {
    final isMaterial = i.isOdd;
    final item = MaterialDonationItem.getAvailableItems()[i % 5];
    final qty = (i % 3) + 1;
    return Donation(
      id: 'don_$i',
      amount: isMaterial ? item.price * qty : 10.0 * (1 + (i % 5)),
      date: DateTime.now().subtract(Duration(days: i * 3)),
      shelterName: ['Azyl', 'Szczęśliwy Ogon', 'Miejskie Schronisko'][i % 3],
      message: i.isEven ? 'Dla futrzaków 🐾' : null,
      type: isMaterial ? DonationType.material : DonationType.monetary,
      petId: isMaterial ? 'pet_${i * 2}' : null,
      materialItem: isMaterial ? item : null,
      quantity: isMaterial ? qty : null,
    );
  }

  // Factory constructor for a material donation (przekazanie "paczek" dla konkretnego zwierzaka)
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

  // Factory constructor for a monetary donation (klasyczne wsparcie schroniska)
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