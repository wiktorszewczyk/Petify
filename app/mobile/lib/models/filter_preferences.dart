class FilterPreferences {
  final double? maxDistance;
  final Set<String> animalTypes;
  final int? minAge;
  final int? maxAge;
  final bool onlyUrgent;
  final bool onlyVaccinated;
  final bool onlySterilized;
  final bool kidFriendly;
  final bool useCurrentLocation;
  final String? selectedCity;

  FilterPreferences({
    this.maxDistance = 50.0,
    this.animalTypes = const {'Psy', 'Koty'},
    this.minAge = 0,
    this.maxAge = 15,
    this.onlyUrgent = false,
    this.onlyVaccinated = false,
    this.onlySterilized = false,
    this.kidFriendly = false,
    this.useCurrentLocation = true,
    this.selectedCity,
  });

  Map<String, dynamic> toJson() {
    return {
      'maxDistance': maxDistance,
      'animalTypes': animalTypes.toList(),
      'minAge': minAge,
      'maxAge': maxAge,
      'onlyUrgent': onlyUrgent,
      'onlyVaccinated': onlyVaccinated,
      'onlySterilized': onlySterilized,
      'kidFriendly': kidFriendly,
      'useCurrentLocation': useCurrentLocation,
      'selectedCity': selectedCity,
    };
  }

  factory FilterPreferences.fromJson(Map<String, dynamic> json) {
    return FilterPreferences(
      maxDistance: json['maxDistance']?.toDouble(),
      animalTypes: Set<String>.from(json['animalTypes'] ?? ['Psy', 'Koty']),
      minAge: json['minAge'],
      maxAge: json['maxAge'],
      onlyUrgent: json['onlyUrgent'] ?? false,
      onlyVaccinated: json['onlyVaccinated'] ?? false,
      onlySterilized: json['onlySterilized'] ?? false,
      kidFriendly: json['kidFriendly'] ?? false,
      useCurrentLocation: json['useCurrentLocation'] ?? true,
      selectedCity: json['selectedCity'],
    );
  }

  FilterPreferences copyWith({
    double? maxDistance,
    bool clearMaxDistance = false,
    Set<String>? animalTypes,
    int? minAge,
    bool clearMinAge = false,
    int? maxAge,
    bool clearMaxAge = false,
    bool? onlyUrgent,
    bool? onlyVaccinated,
    bool? onlySterilized,
    bool? kidFriendly,
    bool? useCurrentLocation,
    String? selectedCity,
    bool clearSelectedCity = false,
  }) {
    return FilterPreferences(
      maxDistance: clearMaxDistance ? null : (maxDistance ?? this.maxDistance),
      animalTypes: animalTypes ?? this.animalTypes,
      minAge: clearMinAge ? null : (minAge ?? this.minAge),
      maxAge: clearMaxAge ? null : (maxAge ?? this.maxAge),
      onlyUrgent: onlyUrgent ?? this.onlyUrgent,
      onlyVaccinated: onlyVaccinated ?? this.onlyVaccinated,
      onlySterilized: onlySterilized ?? this.onlySterilized,
      kidFriendly: kidFriendly ?? this.kidFriendly,
      useCurrentLocation: useCurrentLocation ?? this.useCurrentLocation,
      selectedCity: clearSelectedCity ? null : (selectedCity ?? this.selectedCity),
    );
  }
}