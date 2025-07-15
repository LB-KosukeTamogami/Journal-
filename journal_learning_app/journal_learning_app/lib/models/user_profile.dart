class UserProfile {
  final String id;
  final String name;
  final String email;
  final String profileImageUrl;
  final int totalDays;
  final int currentStreak;
  final int longestStreak;
  final int totalWords;
  final int experiencePoints;
  final int level;
  final DateTime createdAt;
  final DateTime lastActiveAt;
  final Map<String, dynamic> preferences;
  final List<String> achievements;

  UserProfile({
    required this.id,
    required this.name,
    required this.email,
    this.profileImageUrl = '',
    this.totalDays = 0,
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.totalWords = 0,
    this.experiencePoints = 0,
    this.level = 1,
    required this.createdAt,
    required this.lastActiveAt,
    this.preferences = const {},
    this.achievements = const [],
  });

  int get experienceToNextLevel => (level * 100) - (experiencePoints % (level * 100));

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'profileImageUrl': profileImageUrl,
      'totalDays': totalDays,
      'currentStreak': currentStreak,
      'longestStreak': longestStreak,
      'totalWords': totalWords,
      'experiencePoints': experiencePoints,
      'level': level,
      'createdAt': createdAt.toIso8601String(),
      'lastActiveAt': lastActiveAt.toIso8601String(),
      'preferences': preferences,
      'achievements': achievements,
    };
  }

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      profileImageUrl: json['profileImageUrl'] ?? '',
      totalDays: json['totalDays'] ?? 0,
      currentStreak: json['currentStreak'] ?? 0,
      longestStreak: json['longestStreak'] ?? 0,
      totalWords: json['totalWords'] ?? 0,
      experiencePoints: json['experiencePoints'] ?? 0,
      level: json['level'] ?? 1,
      createdAt: DateTime.parse(json['createdAt']),
      lastActiveAt: DateTime.parse(json['lastActiveAt']),
      preferences: Map<String, dynamic>.from(json['preferences'] ?? {}),
      achievements: List<String>.from(json['achievements'] ?? []),
    );
  }

  UserProfile copyWith({
    String? name,
    String? email,
    String? profileImageUrl,
    int? totalDays,
    int? currentStreak,
    int? longestStreak,
    int? totalWords,
    int? experiencePoints,
    int? level,
    DateTime? lastActiveAt,
    Map<String, dynamic>? preferences,
    List<String>? achievements,
  }) {
    return UserProfile(
      id: id,
      name: name ?? this.name,
      email: email ?? this.email,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      totalDays: totalDays ?? this.totalDays,
      currentStreak: currentStreak ?? this.currentStreak,
      longestStreak: longestStreak ?? this.longestStreak,
      totalWords: totalWords ?? this.totalWords,
      experiencePoints: experiencePoints ?? this.experiencePoints,
      level: level ?? this.level,
      createdAt: createdAt,
      lastActiveAt: lastActiveAt ?? this.lastActiveAt,
      preferences: preferences ?? this.preferences,
      achievements: achievements ?? this.achievements,
    );
  }
}