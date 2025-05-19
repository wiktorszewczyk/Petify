import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/user.dart';
import '../../widgets/cards/pet_mini_card.dart';
import '../../services/pet_service.dart';

class SupportedPetsTab extends StatefulWidget {
  final User user;
  const SupportedPetsTab({super.key, required this.user});

  @override
  State<SupportedPetsTab> createState() => _SupportedPetsTabState();
}

class _SupportedPetsTabState extends State<SupportedPetsTab> {
  final _petService = PetService();
  late Future _future;

  @override
  void initState() {
    super.initState();
    _future = _petService.getLikedPets(); // tymczasowo
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _future,
      builder: (_, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final pets = snapshot.data as List;
        if (pets.isEmpty) {
          return const Center(child: Text('Nie wspierasz jeszcze żadnego zwierzaka'));
        }
        return GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: .75),
          itemCount: pets.length,
          itemBuilder: (_, i) => PetMiniCard(pet: pets[i]),
        );
      },
    );
  }
}