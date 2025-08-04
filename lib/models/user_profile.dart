class UserProfile {
  final String id;
  final String name;
  final String email;
  final String? avatarUrl;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String targetLevel;
  final int currentStreak;
  final int longestStreak;
  final int totalDiaryEntries;
  final int totalWordsLearned;
  final Map<String, dynamic>? preferences;

  UserProfile({
    required this.id,
    required this.name,
    required this.email,
    this.avatarUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.targetLevel = 'intermediate',
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.totalDiaryEntries = 0,
    this.totalWordsLearned = 0,
    this.preferences,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  UserProfile copyWith({
    String? id,
    String? name,
    String? email,
    String? avatarUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? targetLevel,
    int? currentStreak,
    int? longestStreak,
    int? totalDiaryEntries,
    int? totalWordsLearned,
    Map<String, dynamic>? preferences,
  }) {
    return UserProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      targetLevel: targetLevel ?? this.targetLevel,
      currentStreak: currentStreak ?? this.currentStreak,
      longestStreak: longestStreak ?? this.longestStreak,
      totalDiaryEntries: totalDiaryEntries ?? this.totalDiaryEntries,
      totalWordsLearned: totalWordsLearned ?? this.totalWordsLearned,
      preferences: preferences ?? this.preferences,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'avatarUrl': avatarUrl,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'targetLevel': targetLevel,
      'currentStreak': currentStreak,
      'longestStreak': longestStreak,
      'totalDiaryEntries': totalDiaryEntries,
      'totalWordsLearned': totalWordsLearned,
      'preferences': preferences,
    };
  }

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      avatarUrl: json['avatarUrl'],
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt']) 
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null 
          ? DateTime.parse(json['updatedAt']) 
          : DateTime.now(),
      targetLevel: json['targetLevel'] ?? 'intermediate',
      currentStreak: json['currentStreak'] ?? 0,
      longestStreak: json['longestStreak'] ?? 0,
      totalDiaryEntries: json['totalDiaryEntries'] ?? 0,
      totalWordsLearned: json['totalWordsLearned'] ?? 0,
      preferences: json['preferences'],
    );
  }

  // デフォルトプロファイル（未ログインユーザー用）
  static UserProfile get defaultProfile {
    return UserProfile(
      id: 'anonymous',
      name: 'ゲストユーザー',
      email: 'guest@example.com',
      targetLevel: 'beginner',
    );
  }
}