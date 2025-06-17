import '../models/filter_preferences.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class FilterPreferencesService {
  static const String _prefsKey = 'filter_preferences';
  static FilterPreferencesService? _instance;

  factory FilterPreferencesService() => _instance ??= FilterPreferencesService._();
  FilterPreferencesService._();

  Future<void> saveFilterPreferences(FilterPreferences preferences) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = jsonEncode(preferences.toJson());
    await prefs.setString(_prefsKey, jsonString);
  }

  Future<FilterPreferences> getFilterPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_prefsKey);

    if (jsonString != null) {
      try {
        final json = jsonDecode(jsonString) as Map<String, dynamic>;
        return FilterPreferences.fromJson(json);
      } catch (e) {
        // Jeśli błąd parsowania, zwróć domyślne ustawienia
        return FilterPreferences();
      }
    }

    return FilterPreferences();
  }

  Future<void> resetToDefaults() async {
    await saveFilterPreferences(FilterPreferences());
  }
}