import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../styles/colors.dart';
import '../../services/filter_preferences_service.dart';
import '../../services/location_service.dart';
import '../../services/cache/cache_manager.dart';
import '../models/filter_preferences.dart';

class DiscoverySettingsSheet extends StatefulWidget {
  final FilterPreferences? initialPreferences;

  const DiscoverySettingsSheet({super.key, this.initialPreferences});

  static Future<FilterPreferences?> show<T>(BuildContext context,
      {FilterPreferences? currentPreferences}) {
    return showModalBottomSheet<FilterPreferences>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DiscoverySettingsSheet(initialPreferences: currentPreferences),
    );
  }

  @override
  State<DiscoverySettingsSheet> createState() => _DiscoverySettingsSheetState();
}

class _DiscoverySettingsSheetState extends State<DiscoverySettingsSheet> {
  late FilterPreferences _preferences;
  final TextEditingController _cityController = TextEditingController();
  bool _isLoadingLocation = false;

  @override
  void initState() {
    super.initState();
    _preferences = widget.initialPreferences ?? FilterPreferences();
    if (!_preferences.useCurrentLocation && _preferences.selectedCity != null) {
      _cityController.text = _preferences.selectedCity!;
    }
  }

  @override
  void dispose() {
    _cityController.dispose();
    super.dispose();
  }

  Future<void> _saveAndClose([FilterPreferences? customPrefs]) async {
    final prefsToSave = customPrefs ?? _preferences;

    CacheManager.invalidatePattern('pets_');
    CacheManager.invalidatePattern('filter_preferences');
    print('🗑️ DiscoverySettings: Cache invalidated due to filter changes');

    await FilterPreferencesService().saveFilterPreferences(prefsToSave);
    if (mounted) {
      Navigator.pop(context, prefsToSave);
    }
  }

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
              Expanded(
                child: Text(
                  subtitle,
                  style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[600]),
                ),
              ),
              if (trailing != null) trailing,
            ],
          ),
          const SizedBox(height: 12),
          child,
          const SizedBox(height: 24),
        ],
      );

  FilterChip _chip(String label, Set<String> currentTypes) => FilterChip(
    label: Text(label),
    selected: currentTypes.contains(label),
    selectedColor: AppColors.primaryColor.withOpacity(.25),
    checkmarkColor: AppColors.primaryColor,
    onSelected: (selected) => setState(() {
      final newTypes = Set<String>.from(currentTypes);
      selected ? newTypes.add(label) : newTypes.remove(label);
      _preferences = _preferences.copyWith(animalTypes: newTypes);
    }),
  );

  Future<void> _getCurrentLocation() async {
    setState(() => _isLoadingLocation = true);

    try {
      final position = await LocationService().getCurrentLocation();
      if (position != null) {
        setState(() {
          _preferences = _preferences.copyWith(
            useCurrentLocation: true,
            clearSelectedCity: true,
          );
          _cityController.clear();
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Lokalizacja została pobrana pomyślnie'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Nie udało się pobrać lokalizacji. Sprawdź uprawnienia.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Błąd: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isLoadingLocation = false);
    }
  }

  Future<void> _validateAndSetCity() async {
    final cityName = _cityController.text.trim();
    if (cityName.isEmpty) return;

    setState(() => _isLoadingLocation = true);

    try {
      final position = await LocationService().getCityCoordinates(cityName);
      if (position != null) {
        setState(() {
          _preferences = _preferences.copyWith(
            useCurrentLocation: false,
            selectedCity: cityName,
          );
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Ustawiono lokalizację: $cityName'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Nie znaleziono podanego miasta'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Błąd podczas wyszukiwania miasta: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isLoadingLocation = false);
    }
  }

  void _switchToCityMode() {
    setState(() {
      _preferences = _preferences.copyWith(
        useCurrentLocation: false,
      );
    });
  }

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
          bottom: mq.viewInsets.bottom + 24,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: ListView(
          controller: controller,
          children: [
            Row(
              children: [
                Text('Ustawienia odkrywania',
                    style: GoogleFonts.poppins(
                        fontSize: 22, fontWeight: FontWeight.bold)),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => _saveAndClose(),
                ),
              ],
            ),
            const Divider(height: 30),

            _section(
              title: 'Lokalizacja',
              subtitle: 'Wybierz sposób określania lokalizacji:',
              child: Column(
                children: [
                  InkWell(
                    onTap: _getCurrentLocation,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: _preferences.useCurrentLocation
                              ? AppColors.primaryColor
                              : Colors.grey[300]!,
                          width: 2,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        leading: Icon(
                          Icons.my_location,
                          color: _preferences.useCurrentLocation
                              ? AppColors.primaryColor
                              : Colors.grey[600],
                        ),
                        title: const Text('Moja aktualna lokalizacja'),
                        subtitle: const Text('Używaj GPS do określenia lokalizacji'),
                        trailing: _isLoadingLocation && _preferences.useCurrentLocation
                            ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                            : _preferences.useCurrentLocation
                            ? Icon(Icons.check_circle, color: AppColors.primaryColor)
                            : null,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  InkWell(
                    onTap: _switchToCityMode,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: !_preferences.useCurrentLocation
                              ? AppColors.primaryColor
                              : Colors.grey[300]!,
                          width: 2,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          ListTile(
                            leading: Icon(
                              Icons.location_city,
                              color: !_preferences.useCurrentLocation
                                  ? AppColors.primaryColor
                                  : Colors.grey[600],
                            ),
                            title: const Text('Wybrane miasto'),
                            subtitle: const Text('Wpisz nazwę miasta w Polsce'),
                            trailing: _isLoadingLocation && !_preferences.useCurrentLocation
                                ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                                : !_preferences.useCurrentLocation && _preferences.selectedCity != null
                                ? Icon(Icons.check_circle, color: AppColors.primaryColor)
                                : null,
                          ),
                          if (!_preferences.useCurrentLocation) ...[
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: TextField(
                                      controller: _cityController,
                                      decoration: InputDecoration(
                                        hintText: 'np. Warszawa, Kraków',
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        contentPadding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 8,
                                        ),
                                      ),
                                      onSubmitted: (_) => _validateAndSetCity(),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  IconButton(
                                    onPressed: _validateAndSetCity,
                                    icon: const Icon(Icons.search),
                                    style: IconButton.styleFrom(
                                      backgroundColor: AppColors.primaryColor,
                                      foregroundColor: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (_preferences.selectedCity != null)
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: AppColors.primaryColor.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    'Wybrane: ${_preferences.selectedCity}',
                                    style: GoogleFonts.poppins(
                                      color: AppColors.primaryColor,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            _section(
              title: 'Maksymalna odległość',
              subtitle: _preferences.maxDistance != null
                  ? 'Pokaż zwierzęta w odległości do:'
                  : 'Bez ograniczeń odległości',
              trailing: _preferences.maxDistance != null
                  ? Text('${_preferences.maxDistance!.round()} km',
                  style: const TextStyle(fontWeight: FontWeight.bold))
                  : const Text('∞', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              child: Column(
                children: [
                  CheckboxListTile(
                    value: _preferences.maxDistance == null,
                    activeColor: AppColors.primaryColor,
                    title: const Text('Bez ograniczeń odległości'),
                    contentPadding: EdgeInsets.zero,
                    onChanged: (value) {
                      setState(() {
                        if (value == true) {
                          _preferences = _preferences.copyWith(clearMaxDistance: true);
                        } else {
                          _preferences = _preferences.copyWith(maxDistance: 50.0);
                        }
                      });
                    },
                  ),
                  if (_preferences.maxDistance != null) ...[
                    const SizedBox(height: 8),
                    Slider.adaptive(
                      value: _preferences.maxDistance!,
                      min: 5,
                      max: 200,
                      divisions: 39,
                      label: '${_preferences.maxDistance!.round()} km',
                      activeColor: AppColors.primaryColor,
                      onChanged: (v) => setState(() =>
                      _preferences = _preferences.copyWith(maxDistance: v)),
                    ),
                  ],
                ],
              ),
            ),

            _section(
              title: 'Typ zwierzęcia',
              subtitle: 'Wybierz jakie zwierzęta chcesz zobaczyć:',
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: ['Psy', 'Koty', 'Inne']
                    .map((label) => _chip(label, _preferences.animalTypes))
                    .toList(),
              ),
            ),

            _section(
              title: 'Wiek',
              subtitle: _preferences.minAge != null && _preferences.maxAge != null
                  ? 'Wybierz przedział wiekowy:'
                  : 'Bez ograniczeń wieku',
              trailing: _preferences.minAge != null && _preferences.maxAge != null
                  ? Text('${_preferences.minAge}‑${_preferences.maxAge} lat',
                  style: const TextStyle(fontWeight: FontWeight.bold))
                  : const Text('∞', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              child: Column(
                children: [
                  CheckboxListTile(
                    value: _preferences.minAge == null || _preferences.maxAge == null,
                    activeColor: AppColors.primaryColor,
                    title: const Text('Bez ograniczeń wieku'),
                    contentPadding: EdgeInsets.zero,
                    onChanged: (value) {
                      setState(() {
                        if (value == true) {
                          _preferences = _preferences.copyWith(
                            clearMinAge: true,
                            clearMaxAge: true,
                          );
                        } else {
                          _preferences = _preferences.copyWith(
                            minAge: 0,
                            maxAge: 15,
                          );
                        }
                      });
                    },
                  ),
                  if (_preferences.minAge != null && _preferences.maxAge != null) ...[
                    const SizedBox(height: 8),
                    RangeSlider(
                      values: RangeValues(
                          _preferences.minAge!.toDouble(),
                          _preferences.maxAge!.toDouble()
                      ),
                      min: 0,
                      max: 20,
                      divisions: 20,
                      labels: RangeLabels('${_preferences.minAge} r', '${_preferences.maxAge} l'),
                      activeColor: AppColors.primaryColor,
                      onChanged: (val) => setState(() => _preferences = _preferences.copyWith(
                        minAge: val.start.round(),
                        maxAge: val.end.round(),
                      )),
                    ),
                  ],
                ],
              ),
            ),

            _section(
              title: 'Dodatkowe filtry',
              subtitle: 'Dostosuj wyszukiwanie:',
              child: Column(
                children: [
                  SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Tylko pilne przypadki'),
                    value: _preferences.onlyUrgent,
                    activeColor: AppColors.primaryColor,
                    onChanged: (v) => setState(() =>
                    _preferences = _preferences.copyWith(onlyUrgent: v)),
                  ),
                  SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Tylko zaszczepione'),
                    value: _preferences.onlyVaccinated,
                    activeColor: AppColors.primaryColor,
                    onChanged: (v) => setState(() =>
                    _preferences = _preferences.copyWith(onlyVaccinated: v)),
                  ),
                  SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Tylko sterylizowane/kastrowane'),
                    value: _preferences.onlySterilized,
                    activeColor: AppColors.primaryColor,
                    onChanged: (v) => setState(() =>
                    _preferences = _preferences.copyWith(onlySterilized: v)),
                  ),
                  SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Przyjazne dzieciom'),
                    value: _preferences.kidFriendly,
                    activeColor: AppColors.primaryColor,
                    onChanged: (v) => setState(() =>
                    _preferences = _preferences.copyWith(kidFriendly: v)),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryColor,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () => _saveAndClose(),
              child: Text('Zastosuj filtry',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 8),
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () {
                final defaultPrefs = FilterPreferences();
                _saveAndClose(defaultPrefs);
              },
              child: const Text('Zresetuj wszystkie filtry'),
            ),
          ],
        ),
      ),
    );
  }
}