enum WordCategory {
  noun('名詞'),
  verb('動詞'),
  adjective('形容詞'),
  adverb('副詞'),
  pronoun('代名詞'),
  preposition('前置詞'),
  conjunction('接続詞'),
  interjection('感動詞'),
  phrase('熟語・フレーズ'),
  other('その他');

  final String displayName;
  const WordCategory(this.displayName);
}

class Word {
  final String id;
  final String english;
  final String japanese;
  final String? example;
  final String? diaryEntryId;
  final DateTime createdAt;
  final int reviewCount;
  final DateTime? lastReviewedAt;
  final bool isMastered;
  final int masteryLevel; // 0 = unknown, 1 = partial, 2 = mastered
  final WordCategory category;

  Word({
    required this.id,
    required this.english,
    required this.japanese,
    this.example,
    this.diaryEntryId,
    required this.createdAt,
    this.reviewCount = 0,
    this.lastReviewedAt,
    this.isMastered = false,
    this.masteryLevel = 0,
    this.category = WordCategory.other,
  });

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
      'category': category.name,
    };
  }

  factory Word.fromJson(Map<String, dynamic> json) {
    return Word(
      id: json['id'],
      english: json['english'],
      japanese: json['japanese'],
      example: json['example'],
      // Supabaseからのデータはスネークケース、ローカルはキャメルケース
      diaryEntryId: json['diaryEntryId'] ?? json['diary_entry_id'],
      createdAt: DateTime.parse(json['createdAt'] ?? json['created_at']),
      reviewCount: json['reviewCount'] ?? json['review_count'] ?? 0,
      lastReviewedAt: (json['lastReviewedAt'] ?? json['last_reviewed_at']) != null 
          ? DateTime.parse(json['lastReviewedAt'] ?? json['last_reviewed_at']) 
          : null,
      isMastered: json['isMastered'] ?? json['is_mastered'] ?? false,
      masteryLevel: json['masteryLevel'] ?? json['mastery_level'] ?? 0,
      category: json['category'] != null
          ? WordCategory.values.firstWhere(
              (e) => e.name == json['category'],
              orElse: () => WordCategory.other,
            )
          : WordCategory.other,
    );
  }

  Word copyWith({
    String? english,
    String? japanese,
    String? example,
    String? diaryEntryId,
    int? reviewCount,
    DateTime? lastReviewedAt,
    bool? isMastered,
    int? masteryLevel,
    WordCategory? category,
  }) {
    return Word(
      id: id,
      english: english ?? this.english,
      japanese: japanese ?? this.japanese,
      example: example ?? this.example,
      diaryEntryId: diaryEntryId ?? this.diaryEntryId,
      createdAt: createdAt,
      reviewCount: reviewCount ?? this.reviewCount,
      lastReviewedAt: lastReviewedAt ?? this.lastReviewedAt,
      isMastered: isMastered ?? this.isMastered,
      masteryLevel: masteryLevel ?? this.masteryLevel,
      category: category ?? this.category,
    );
  }
}