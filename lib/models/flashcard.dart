class Flashcard {
  final String id;
  final String word;
  final String meaning;
  final String pronunciation;
  final String exampleSentence;
  final String translation;
  final DateTime createdAt;
  final DateTime lastReviewed;
  final int reviewCount;
  final double easinessFactor;
  final int intervalDays;
  final DateTime nextReviewDate;
  final bool isLearned;

  Flashcard({
    required this.id,
    required this.word,
    required this.meaning,
    this.pronunciation = '',
    this.exampleSentence = '',
    this.translation = '',
    required this.createdAt,
    required this.lastReviewed,
    this.reviewCount = 0,
    this.easinessFactor = 2.5,
    this.intervalDays = 1,
    required this.nextReviewDate,
    this.isLearned = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'word': word,
      'meaning': meaning,
      'pronunciation': pronunciation,
      'exampleSentence': exampleSentence,
      'translation': translation,
      'createdAt': createdAt.toIso8601String(),
      'lastReviewed': lastReviewed.toIso8601String(),
      'reviewCount': reviewCount,
      'easinessFactor': easinessFactor,
      'intervalDays': intervalDays,
      'nextReviewDate': nextReviewDate.toIso8601String(),
      'isLearned': isLearned,
    };
  }

  factory Flashcard.fromJson(Map<String, dynamic> json) {
    return Flashcard(
      id: json['id'],
      word: json['word'],
      meaning: json['meaning'],
      pronunciation: json['pronunciation'] ?? '',
      exampleSentence: json['exampleSentence'] ?? '',
      translation: json['translation'] ?? '',
      createdAt: DateTime.parse(json['createdAt']),
      lastReviewed: DateTime.parse(json['lastReviewed']),
      reviewCount: json['reviewCount'] ?? 0,
      easinessFactor: json['easinessFactor']?.toDouble() ?? 2.5,
      intervalDays: json['intervalDays'] ?? 1,
      nextReviewDate: DateTime.parse(json['nextReviewDate']),
      isLearned: json['isLearned'] ?? false,
    );
  }

  Flashcard copyWith({
    String? meaning,
    String? pronunciation,
    String? exampleSentence,
    String? translation,
    DateTime? lastReviewed,
    int? reviewCount,
    double? easinessFactor,
    int? intervalDays,
    DateTime? nextReviewDate,
    bool? isLearned,
  }) {
    return Flashcard(
      id: id,
      word: word,
      meaning: meaning ?? this.meaning,
      pronunciation: pronunciation ?? this.pronunciation,
      exampleSentence: exampleSentence ?? this.exampleSentence,
      translation: translation ?? this.translation,
      createdAt: createdAt,
      lastReviewed: lastReviewed ?? this.lastReviewed,
      reviewCount: reviewCount ?? this.reviewCount,
      easinessFactor: easinessFactor ?? this.easinessFactor,
      intervalDays: intervalDays ?? this.intervalDays,
      nextReviewDate: nextReviewDate ?? this.nextReviewDate,
      isLearned: isLearned ?? this.isLearned,
    );
  }
}