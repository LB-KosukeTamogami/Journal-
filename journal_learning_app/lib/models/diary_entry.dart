class DiaryEntry {
  final String id;
  final String title;
  final String content;
  final String englishContent;
  final List<String> newWords;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isCompleted;
  final int wordCount;

  DiaryEntry({
    required this.id,
    required this.title,
    required this.content,
    this.englishContent = '',
    this.newWords = const [],
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
      'englishContent': englishContent,
      'newWords': newWords,
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
      englishContent: json['englishContent'] ?? '',
      newWords: List<String>.from(json['newWords'] ?? []),
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      isCompleted: json['isCompleted'] ?? false,
      wordCount: json['wordCount'] ?? 0,
    );
  }

  DiaryEntry copyWith({
    String? title,
    String? content,
    String? englishContent,
    List<String>? newWords,
    DateTime? updatedAt,
    bool? isCompleted,
    int? wordCount,
  }) {
    return DiaryEntry(
      id: id,
      title: title ?? this.title,
      content: content ?? this.content,
      englishContent: englishContent ?? this.englishContent,
      newWords: newWords ?? this.newWords,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isCompleted: isCompleted ?? this.isCompleted,
      wordCount: wordCount ?? this.wordCount,
    );
  }
}