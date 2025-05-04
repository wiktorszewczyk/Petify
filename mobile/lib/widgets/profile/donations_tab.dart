import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/user.dart';
import '../../models/donation.dart';
import '../../services/donation_service.dart';
import '../../styles/colors.dart';

class DonationsTab extends StatefulWidget {
  final User user;
  const DonationsTab({super.key, required this.user});

  @override
  State<DonationsTab> createState() => _DonationsTabState();
}

class _DonationsTabState extends State<DonationsTab> {
  final _service = DonationService();
  late Future<List<Donation>> _future;

  @override
  void initState() {
    super.initState();
    _future = _service.getUserDonations();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _future,
      builder: (_, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final dons = snapshot.data!;
        if (dons.isEmpty) return const Center(child: Text('Brak wpłat'));
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: dons.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (_, i) => _tile(dons[i]),
        );
      },
    );
  }

  Widget _tile(Donation d) => ListTile(
    leading: const Icon(Icons.volunteer_activism, color: Colors.blue),
    title: Text('${d.amount.toStringAsFixed(2)} zł',
        style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
    subtitle: Text(d.shelterName),
    trailing: Text('${d.date.day}.${d.date.month}.${d.date.year}'),
  );
}