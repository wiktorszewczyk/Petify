import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../styles/colors.dart';

class DiscoverySettingsSheet extends StatefulWidget {
  const DiscoverySettingsSheet({super.key});

  static Future<T?> show<T>(BuildContext context) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const DiscoverySettingsSheet(),
    );
  }

  @override
  State<DiscoverySettingsSheet> createState() => _DiscoverySettingsSheetState();
}

class _DiscoverySettingsSheetState extends State<DiscoverySettingsSheet> {
  // ----------- local state -----------
  double _maxDistance = 50;
  final Set<String> _animalTypes = {'Psy'};
  RangeValues _age = const RangeValues(1, 10);
  final Map<String, bool> _switches = {
    'Tylko pilne przypadki': false,
    'Tylko zaszczepione': true,
    'Tylko sterylizowane/kastrowane': false,
    'Przyjazne dzieciom': true,
  };
  // -----------------------------------

  // region – UI helpers
  Widget _section({
    required String title,
    required String subtitle,
    required Widget child,
    Widget? trailing,
  }) =>
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(subtitle,
                  style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[600])),
              if (trailing != null) trailing,
            ],
          ),
          const SizedBox(height: 12),
          child,
          const SizedBox(height: 24),
        ],
      );

  FilterChip _chip(String label) => FilterChip(
    label: Text(label),
    selected: _animalTypes.contains(label),
    selectedColor: AppColors.primaryColor.withOpacity(.25),
    checkmarkColor: AppColors.primaryColor,
    onSelected: (_) => setState(() {
      _animalTypes.contains(label) ? _animalTypes.remove(label) : _animalTypes.add(label);
    }),
  );

  // endregion

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);

    return DraggableScrollableSheet(
      initialChildSize: .85,
      maxChildSize: .95,
      minChildSize: .6,
      builder: (_, controller) => Container(
        padding: EdgeInsets.only(
          top: 16,
          left: 20,
          right: 20,
          // podnieś całość nad klawiaturę jeśli się pokaże
          bottom: mq.viewInsets.bottom + 24,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: ListView(
          controller: controller,
          children: [
            // header
            Row(
              children: [
                Text('Ustawienia odkrywania',
                    style: GoogleFonts.poppins(
                        fontSize: 22, fontWeight: FontWeight.bold)),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const Divider(height: 30),

            // distance
            _section(
              title: 'Maksymalna odległość',
              subtitle: 'Pokaż zwierzęta w odległości do:',
              trailing: Text('${_maxDistance.round()} km',
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              child: Slider.adaptive(
                value: _maxDistance,
                min: 5,
                max: 100,
                divisions: 19,
                label: '${_maxDistance.round()} km',
                activeColor: AppColors.primaryColor,
                onChanged: (v) => setState(() => _maxDistance = v),
              ),
            ),

            // animal types
            _section(
              title: 'Typ zwierzęcia',
              subtitle: 'Wybierz jakie zwierzęta chcesz zobaczyć:',
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: ['Psy', 'Koty', 'Ptaki', 'Inne'].map(_chip).toList(),
              ),
            ),

            // age
            _section(
              title: 'Wiek',
              subtitle: 'Wybierz przedział wiekowy:',
              trailing: Text('${_age.start.round()}‑${_age.end.round()} lat',
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              child: RangeSlider(
                values: _age,
                min: 0,
                max: 20,
                divisions: 20,
                labels: RangeLabels('${_age.start.round()} r', '${_age.end.round()} l'),
                activeColor: AppColors.primaryColor,
                onChanged: (val) => setState(() => _age = val),
              ),
            ),

            // switches
            _section(
              title: 'Dodatkowe filtry',
              subtitle: 'Dostosuj wyszukiwanie:',
              child: Column(
                children: _switches.entries
                    .map(
                      (e) => SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    title: Text(e.key),
                    value: e.value,
                    activeColor: AppColors.primaryColor,
                    onChanged: (v) => setState(() => _switches[e.key] = v),
                  ),
                )
                    .toList(),
              ),
            ),

            const SizedBox(height: 12),
            // buttons
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryColor,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () {
                // build filter payload
                final filters = {
                  'distance': _maxDistance.round(),
                  'types': _animalTypes,
                  'age': {'min': _age.start.round(), 'max': _age.end.round()},
                  ..._switches,
                };
                Navigator.pop(context, filters); // -> zwróć do wywołującego
              },
              child: Text('Zastosuj filtry',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 8),
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () => Navigator.pop(context, 'reset'),
              child: const Text('Zresetuj wszystkie filtry'),
            ),
          ],
        ),
      ),
    );
  }
}
