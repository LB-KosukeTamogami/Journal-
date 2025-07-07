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
    };
  }

  factory Word.fromJson(Map<String, dynamic> json) {
    return Word(
      id: json['id'],
      english: json['english'],
      japanese: json['japanese'],
      example: json['example'],
      diaryEntryId: json['diaryEntryId'],
      createdAt: DateTime.parse(json['createdAt']),
      reviewCount: json['reviewCount'] ?? 0,
      lastReviewedAt: json['lastReviewedAt'] != null 
          ? DateTime.parse(json['lastReviewedAt']) 
          : null,
      isMastered: json['isMastered'] ?? false,
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
    );
  }
}