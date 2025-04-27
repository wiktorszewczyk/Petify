class Donation {
  final String id;
  final double amount;
  final DateTime date;
  final String shelterName;
  final String? message;

  Donation({
    required this.id,
    required this.amount,
    required this.date,
    required this.shelterName,
    this.message,
  });

  factory Donation.fake(int i) => Donation(
    id: 'don_$i',
    amount: 10.0 * (1 + (i % 5)),
    date: DateTime.now().subtract(Duration(days: i * 3)),
    shelterName: ['Azyl', 'Szczęśliwy Ogon', 'Miejskie Schronisko'][i % 3],
    message: i.isEven ? 'Dla futrzaków 🐾' : null,
  );
}