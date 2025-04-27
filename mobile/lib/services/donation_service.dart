import 'dart:async';
import '../models/donation.dart';

class DonationService {
  Future<List<Donation>> getUserDonations() async {
    return List.generate(6, Donation.fake);
  }
}