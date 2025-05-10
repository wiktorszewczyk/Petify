class User {
  final String id;
  final String username;
  final String role;

  // profil
  final String? firstName;
  final String? lastName;
  final String? profileImageUrl;
  final String? location;

  // gamifikacja
  final int level;
  final int experiencePoints;
  final int nextLevelPoints;

  // statystyki
  final int likedPetsCount;
  final int supportedPetsCount;
  final int achievementsCount;

  // aktywność - ostatnie 24h
  final List<Map<String, dynamic>> recentActivities;

  const User({
    required this.id,
    required this.username,
    required this.role,
    this.firstName,
    this.lastName,
    this.profileImageUrl,
    this.location,
    this.level = 1,
    this.experiencePoints = 0,
    this.nextLevelPoints = 100,
    this.likedPetsCount = 0,
    this.supportedPetsCount = 0,
    this.achievementsCount = 0,
    this.recentActivities = const [],
  });

  factory User.fromJson(Map<String, dynamic> j) => User(
    id: j['id'].toString(),
    username: j['username'],
    role: j['role'],
    firstName: j['firstName'],
    lastName: j['lastName'],
    profileImageUrl: j['profileImageUrl'],
    location: j['location'],
    level: j['level'] ?? 1,
    experiencePoints: j['xp'] ?? 0,
    nextLevelPoints: j['nextXp'] ?? 100,
    likedPetsCount: j['liked'] ?? 0,
    supportedPetsCount: j['supported'] ?? 0,
    achievementsCount: j['achievements'] ?? 0,
    recentActivities:
    (j['recentActivities'] as List?)?.cast<Map<String, dynamic>>() ??
        const [],
  );
}