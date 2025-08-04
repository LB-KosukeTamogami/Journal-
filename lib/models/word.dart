import 'package:uuid/uuid.dart';

enum WordCategory {
  noun,
  verb,
  adjective,
  adverb,
  pronoun,
  preposition,
  conjunction,
  interjection,
  other,
}

enum MasteryLevel {
  notStarted, // 未学習 (0)
  learning,   // 学習中 △ (1)
  mastered,   // 習得済み ○ (2)
}

class Word {
  final String id;
  final String english;
  final String? japanese;
  final String? example;
  final String? diaryEntryId;
  final DateTime createdAt;
  final int reviewCount;
  final DateTime? lastReviewedAt;
  final bool isMastered;
  final int masteryLevel;
  final WordCategory category;
  final String? userId;

  Word({
    String? id,
    required this.english,
    this.japanese,
    this.example,
    this.diaryEntryId,
    DateTime? createdAt,
    this.reviewCount = 0,
    this.lastReviewedAt,
    this.isMastered = false,
    int? masteryLevel,
    WordCategory? category,
    this.userId,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now(),
        masteryLevel = masteryLevel ?? (isMastered ? 2 : 0),
        category = category ?? WordCategory.other;

  Word copyWith({
    String? id,
    String? english,
    String? japanese,
    String? example,
    String? diaryEntryId,
    DateTime? createdAt,
    int? reviewCount,
    DateTime? lastReviewedAt,
    bool? isMastered,
    int? masteryLevel,
    WordCategory? category,
    String? userId,
  }) {
    return Word(
      id: id ?? this.id,
      english: english ?? this.english,
      japanese: japanese ?? this.japanese,
      example: example ?? this.example,
      diaryEntryId: diaryEntryId ?? this.diaryEntryId,
      createdAt: createdAt ?? this.createdAt,
      reviewCount: reviewCount ?? this.reviewCount,
      lastReviewedAt: lastReviewedAt ?? this.lastReviewedAt,
      isMastered: isMastered ?? this.isMastered,
      masteryLevel: masteryLevel ?? this.masteryLevel,
      category: category ?? this.category,
      userId: userId ?? this.userId,
    );
  }

  MasteryLevel get masteryLevelEnum {
    switch (masteryLevel) {
      case 0:
        return MasteryLevel.notStarted;
      case 1:
        return MasteryLevel.learning;
      case 2:
        return MasteryLevel.mastered;
      default:
        return MasteryLevel.notStarted;
    }
  }

  String get masteryLevelSymbol {
    switch (masteryLevelEnum) {
      case MasteryLevel.notStarted:
        return '−';
      case MasteryLevel.learning:
        return '△';
      case MasteryLevel.mastered:
        return '○';
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'english': english,
      'japanese': japanese,
      'example': example,
      'diaryEntryId': diaryEntryId,
      'createdAt': createdAt.toIso8601String(),
      'reviewCount': reviewCount,
      'lastReviewedAt': lastReviewedAt?.toIso8601String(),
      'isMastered': isMastered,
      'masteryLevel': masteryLevel,
      'category': category.toString().split('.').last,
      'userId': userId,
    };
  }

  factory Word.fromJson(Map<String, dynamic> json) {
    return Word(
      id: json['id'],
      english: json['english'] ?? '',
      japanese: json['japanese'],
      example: json['example'],
      diaryEntryId: json['diaryEntryId'],
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt']) 
          : DateTime.now(),
      reviewCount: json['reviewCount'] ?? 0,
      lastReviewedAt: json['lastReviewedAt'] != null 
          ? DateTime.parse(json['lastReviewedAt']) 
          : null,
      isMastered: json['isMastered'] ?? false,
      masteryLevel: json['masteryLevel'] ?? 0,
      category: _parseWordCategory(json['category']),
      userId: json['userId'],
    );
  }

  // Supabase用のマップ変換
  Map<String, dynamic> toSupabase() {
    return {
      'id': id,
      'user_id': userId ?? 'anonymous',
      'english': english,
      'japanese': japanese,
      'example': example,
      'diary_entry_id': diaryEntryId,
      'review_count': reviewCount,
      'last_reviewed_at': lastReviewedAt?.toIso8601String(),
      'is_mastered': isMastered,
      'mastery_level': masteryLevel,
      'category': category.toString().split('.').last,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory Word.fromSupabase(Map<String, dynamic> json) {
    return Word(
      id: json['id'],
      english: json['english'] ?? '',
      japanese: json['japanese'],
      example: json['example'],
      diaryEntryId: json['diary_entry_id'],
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at']) 
          : DateTime.now(),
      reviewCount: json['review_count'] ?? 0,
      lastReviewedAt: json['last_reviewed_at'] != null 
          ? DateTime.parse(json['last_reviewed_at']) 
          : null,
      isMastered: json['is_mastered'] ?? false,
      masteryLevel: json['mastery_level'] ?? 0,
      category: _parseWordCategory(json['category']),
      userId: json['user_id'],
    );
  }

  static WordCategory _parseWordCategory(String? category) {
    if (category == null) return WordCategory.other;
    
    switch (category.toLowerCase()) {
      case 'noun':
        return WordCategory.noun;
      case 'verb':
        return WordCategory.verb;
      case 'adjective':
        return WordCategory.adjective;
      case 'adverb':
        return WordCategory.adverb;
      default:
        return WordCategory.other;
    }
  }
}