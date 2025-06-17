import 'pet.dart';

class SwipeResponse {
  final List<Pet> pets;
  final int? nextCursor;

  SwipeResponse({
    required this.pets,
    this.nextCursor,
  });

  factory SwipeResponse.fromJson(Map<String, dynamic> json) {
    return SwipeResponse(
      pets: json['pets'] != null
          ? (json['pets'] as List).map((petJson) => Pet.fromJson(petJson)).toList()
          : [],
      nextCursor: json['nextCursor'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'pets': pets.map((pet) => pet.toJson()).toList(),
      'nextCursor': nextCursor,
    };
  }
}