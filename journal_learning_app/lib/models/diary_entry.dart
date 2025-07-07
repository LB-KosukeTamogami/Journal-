class DiaryEntry {
  final String id;
  final String title;
  final String content;
  final String? translatedTitle;
  final String? translatedContent;
  final String? originalLanguage;
  final List<String> learnedWords;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isCompleted;
  final int wordCount;

  DiaryEntry({
    required this.id,
    required this.title,
    required this.content,
    this.translatedTitle,
    this.translatedContent,
    this.originalLanguage,
    this.learnedWords = const [],
    required this.createdAt,
    required this.updatedAt,
    this.isCompleted = false,
    this.wordCount = 0,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'translatedTitle': translatedTitle,
      'translatedContent': translatedContent,
      'originalLanguage': originalLanguage,
      'learnedWords': learnedWords,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'isCompleted': isCompleted,
      'wordCount': wordCount,
    };
  }

  factory DiaryEntry.fromJson(Map<String, dynamic> json) {
    return DiaryEntry(
      id: json['id'],
      title: json['title'],
      content: json['content'],
      translatedTitle: json['translatedTitle'],
      translatedContent: json['translatedContent'],
      originalLanguage: json['originalLanguage'],
      learnedWords: List<String>.from(json['learnedWords'] ?? []),
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      isCompleted: json['isCompleted'] ?? false,
      wordCount: json['wordCount'] ?? 0,
    );
  }

  DiaryEntry copyWith({
    String? title,
    String? content,
    String? translatedTitle,
    String? translatedContent,
    String? originalLanguage,
    List<String>? learnedWords,
    DateTime? updatedAt,
    bool? isCompleted,
    int? wordCount,
  }) {
    return DiaryEntry(
      id: id,
      title: title ?? this.title,
      content: content ?? this.content,
      translatedTitle: translatedTitle ?? this.translatedTitle,
      translatedContent: translatedContent ?? this.translatedContent,
      originalLanguage: originalLanguage ?? this.originalLanguage,
      learnedWords: learnedWords ?? this.learnedWords,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isCompleted: isCompleted ?? this.isCompleted,
      wordCount: wordCount ?? this.wordCount,
    );
  }
}