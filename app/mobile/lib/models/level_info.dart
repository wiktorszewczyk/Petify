class LevelInfo {
  final int level;
  final int xpPoints;
  final int xpToNextLevel;
  final int likesCount;
  final int supportCount;
  final int badgesCount;

  LevelInfo({
    required this.level,
    required this.xpPoints,
    required this.xpToNextLevel,
    required this.likesCount,
    required this.supportCount,
    required this.badgesCount,
  });

  factory LevelInfo.fromJson(Map<String, dynamic> j) => LevelInfo(
    level: j['level'] as int,
    xpPoints: j['xpPoints'] as int,
    xpToNextLevel: j['xpToNextLevel'] as int,
    likesCount: j['likesCount'] as int,
    supportCount: j['supportCount'] as int,
    badgesCount: j['badgesCount'] as int,
  );
}