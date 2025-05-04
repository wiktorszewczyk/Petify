enum DonationType {
  monetary,
  material,
  tax
}

enum MaterialDonationCategory {
  food,
  accessories,
  care,
  hygiene
}

class MaterialDonationItem {
  final String name;
  final double price;
  final String iconPath;
  final MaterialDonationCategory category;

  MaterialDonationItem({
    required this.name,
    required this.price,
    required this.iconPath,
    required this.category,
  });

  static List<MaterialDonationItem> getAvailableItems() {
    return [
      MaterialDonationItem(
        name: 'Smakołyk',
        price: 5.0,
        iconPath: 'assets/icons/pet_snack.png',
        category: MaterialDonationCategory.food,
      ),
      MaterialDonationItem(
        name: 'Pełna miska',
        price: 10.0,
        iconPath: 'assets/icons/pet_bowl.png',
        category: MaterialDonationCategory.food,
      ),
      MaterialDonationItem(
        name: 'Zabawka',
        price: 15.0,
        iconPath: 'assets/icons/pet_toy.png',
        category: MaterialDonationCategory.accessories,
      ),
      MaterialDonationItem(
        name: 'Zapas karmy',
        price: 25.0,
        iconPath: 'assets/icons/pet_food.png',
        category: MaterialDonationCategory.food,
      ),
      MaterialDonationItem(
        name: 'Legowisko',
        price: 50.0,
        iconPath: 'assets/icons/pet_bed.png',
        category: MaterialDonationCategory.accessories,
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
  final String? petId; // ID zwierzaka (tylko dla type == material)
  final MaterialDonationItem? materialItem; // Przedmiot (tylko dla type == material)
  final int? quantity; // Ilość (tylko dla type == material)

  Donation({
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

  factory Donation.fake(int i) => Donation(
    id: 'don_$i',
    amount: 10.0 * (1 + (i % 5)),
    date: DateTime.now().subtract(Duration(days: i * 3)),
    shelterName: ['Azyl', 'Szczęśliwy Ogon', 'Miejskie Schronisko'][i % 3],
    message: i.isEven ? 'Dla futrzaków 🐾' : null,
    type: DonationType.values[i % 3],
    petId: i % 3 == 1 ? 'pet_${i * 2}' : null,
    materialItem: i % 3 == 1 ? MaterialDonationItem.getAvailableItems()[i % 8] : null,
    quantity: i % 3 == 1 ? (i % 3) + 1 : null,
  );

  // Factory constructor for material donation
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

  // Factory constructor for monetary donation
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

  // Factory constructor for tax donation
  factory Donation.tax({
    required String shelterName,
    required double amount,
    String? message,
  }) {
    return Donation(
      id: 'don_${DateTime.now().millisecondsSinceEpoch}',
      amount: amount,
      date: DateTime.now(),
      shelterName: shelterName,
      type: DonationType.tax,
      message: message,
    );
  }
}