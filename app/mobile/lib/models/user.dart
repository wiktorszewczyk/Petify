import 'achievement.dart';

class User {
  final String id;
  final String username;
  final String role;
  final String? firstName;
  final String? lastName;
  final DateTime? birthDate;
  final String? gender;
  final String? phoneNumber;
  final String? email;
  final String volunteerStatus;
  final bool active;
  final DateTime createdAt;
  final int xpPoints;
  final int level;
  final int xpToNextLevel;
  final int likesCount;
  final int supportCount;
  final int badgesCount;
  final List<Achievement> achievements;

  User.fromJson(Map<String, dynamic> j)
      : id = j['userId'].toString(),
        username = j['username'].toString(),
        role = (j['authorities'] as List).first['authority'],
        firstName = j['firstName'],
        lastName = j['lastName'],
        birthDate = j['birthDate'] != null ? DateTime.parse(j['birthDate']) : null,
        gender = j['gender'],
        phoneNumber = j['phoneNumber']?.toString(),
        email = j['email'],
        volunteerStatus = j['volunteerStatus'],
        active = j['active'] as bool,
        createdAt = DateTime.parse(j['createdAt']),
        xpPoints = j['xpPoints'] as int,
        level = j['level'] as int,
        xpToNextLevel = j['xpToNextLevel'] as int,
        likesCount = j['likesCount'] as int,
        supportCount = j['supportCount'] as int,
        badgesCount = j['badgesCount'] as int,
        achievements = (j['achievements'] as List)
            .map((a) => Achievement.fromJson(a as Map<String, dynamic>))
            .toList();
}