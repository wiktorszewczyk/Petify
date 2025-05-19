import 'dart:async';
import '../models/donation.dart';

class DonationService {
  // Pobranie wszystkich donacji użytkownika
  Future<List<Donation>> getUserDonations() async {
    // Symulacja pobierania danych z API
    return List.generate(6, Donation.fake);
  }

  // Dodanie nowej donacji materialnej (dla konkretnego zwierzaka)
  Future<Donation> addMaterialDonation({
    required String shelterName,
    required String petId,
    required MaterialDonationItem item,
    required int quantity,
    String? message,
  }) async {
    // Tutaj w przyszłości będzie integracja z API
    final donation = Donation.material(
      shelterName: shelterName,
      petId: petId,
      item: item,
      quantity: quantity,
      message: message,
    );

    // Symulacja odpowiedzi z API
    await Future.delayed(Duration(milliseconds: 800));

    return donation;
  }

  // Dodanie donacji pieniężnej (dla schroniska)
  Future<Donation> addMonetaryDonation({
    required String shelterName,
    required double amount,
    String? message,
  }) async {
    // Tutaj w przyszłości będzie integracja z API
    final donation = Donation.monetary(
      shelterName: shelterName,
      amount: amount,
      message: message,
    );

    // Symulacja odpowiedzi z API
    await Future.delayed(Duration(milliseconds: 800));

    return donation;
  }

  // Pobranie dostępnych przedmiotów do donacji materialnej
  Future<List<MaterialDonationItem>> getAvailableMaterialItems() async {
    // Symulacja pobierania danych z API
    await Future.delayed(Duration(milliseconds: 500));

    return MaterialDonationItem.getAvailableItems();
  }
}