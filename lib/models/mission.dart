import 'package:uuid/uuid.dart';

enum MissionType {
  dailyDiary,
  wordLearning,
  streak,
  review,
  conversation,
}

enum MissionDifficulty {
  easy,
  medium,
  hard,
}

class Mission {
  final String id;
  final String title;
  final String description;
  final MissionType type;
  final MissionDifficulty difficulty;
  final int targetValue;
  final int currentValue;
  final int experiencePoints;
  final bool isCompleted;
  final DateTime? completedAt;
  final DateTime createdAt;
  final DateTime expiresAt;
  final String? userId;

  Mission({
    String? id,
    required this.title,
    required this.description,
    required this.type,
    this.difficulty = MissionDifficulty.medium,
    required this.targetValue,
    this.currentValue = 0,
    required this.experiencePoints,
    this.isCompleted = false,
    this.completedAt,
    DateTime? createdAt,
    DateTime? expiresAt,
    this.userId,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now(),
        expiresAt = expiresAt ?? DateTime.now().add(const Duration(days: 1));

  Mission copyWith({
    String? id,
    String? title,
    String? description,
    MissionType? type,
    MissionDifficulty? difficulty,
    int? targetValue,
    int? currentValue,
    int? experiencePoints,
    bool? isCompleted,
    DateTime? completedAt,
    DateTime? createdAt,
    DateTime? expiresAt,
    String? userId,
  }) {
    return Mission(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      type: type ?? this.type,
      difficulty: difficulty ?? this.difficulty,
      targetValue: targetValue ?? this.targetValue,
      currentValue: currentValue ?? this.currentValue,
      experiencePoints: experiencePoints ?? this.experiencePoints,
      isCompleted: isCompleted ?? this.isCompleted,
      completedAt: completedAt ?? this.completedAt,
      createdAt: createdAt ?? this.createdAt,
      expiresAt: expiresAt ?? this.expiresAt,
      userId: userId ?? this.userId,
    );
  }

  double get progress {
    if (targetValue == 0) return 0;
    return (currentValue / targetValue).clamp(0.0, 1.0);
  }

  bool get isExpired {
    return DateTime.now().isAfter(expiresAt);
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'type': type.toString().split('.').last,
      'difficulty': difficulty.toString().split('.').last,
      'targetValue': targetValue,
      'currentValue': currentValue,
      'experiencePoints': experiencePoints,
      'isCompleted': isCompleted,
      'completedAt': completedAt?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'expiresAt': expiresAt.toIso8601String(),
      'userId': userId,
    };
  }

  factory Mission.fromJson(Map<String, dynamic> json) {
    return Mission(
      id: json['id'],
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      type: _parseMissionType(json['type']),
      difficulty: _parseMissionDifficulty(json['difficulty']),
      targetValue: json['targetValue'] ?? 1,
      currentValue: json['currentValue'] ?? 0,
      experiencePoints: json['experiencePoints'] ?? 10,
      isCompleted: json['isCompleted'] ?? false,
      completedAt: json['completedAt'] != null 
          ? DateTime.parse(json['completedAt']) 
          : null,
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt']) 
          : DateTime.now(),
      expiresAt: json['expiresAt'] != null 
          ? DateTime.parse(json['expiresAt']) 
          : DateTime.now().add(const Duration(days: 1)),
      userId: json['userId'],
    );
  }

  static MissionType _parseMissionType(String? type) {
    if (type == null) return MissionType.dailyDiary;
    
    switch (type) {
      case 'dailyDiary':
        return MissionType.dailyDiary;
      case 'wordLearning':
        return MissionType.wordLearning;
      case 'streak':
        return MissionType.streak;
      case 'review':
        return MissionType.review;
      case 'conversation':
        return MissionType.conversation;
      default:
        return MissionType.dailyDiary;
    }
  }

  static MissionDifficulty _parseMissionDifficulty(String? difficulty) {
    if (difficulty == null) return MissionDifficulty.medium;
    
    switch (difficulty) {
      case 'easy':
        return MissionDifficulty.easy;
      case 'medium':
        return MissionDifficulty.medium;
      case 'hard':
        return MissionDifficulty.hard;
      default:
        return MissionDifficulty.medium;
    }
  }
}