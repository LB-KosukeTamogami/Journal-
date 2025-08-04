import 'package:uuid/uuid.dart';

class DiaryEntry {
  final String id;
  final String title;
  final String content;
  final String? translatedTitle;
  final String? translatedContent;
  final String? correctedContent;
  final String originalLanguage;
  final String mood;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int wordCount;
  final bool isCompleted;
  final List<String> learnedWords;
  final List<String>? learnedPhrases;
  final String? userId;

  DiaryEntry({
    String? id,
    required this.title,
    required this.content,
    this.translatedTitle,
    this.translatedContent,
    this.correctedContent,
    this.originalLanguage = 'ja',
    this.mood = 'neutral',
    DateTime? createdAt,
    DateTime? updatedAt,
    int? wordCount,
    this.isCompleted = false,
    List<String>? learnedWords,
    this.learnedPhrases,
    this.userId,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now(),
        wordCount = wordCount ?? content.split(' ').length,
        learnedWords = learnedWords ?? [];

  DiaryEntry copyWith({
    String? id,
    String? title,
    String? content,
    String? translatedTitle,
    String? translatedContent,
    String? correctedContent,
    String? originalLanguage,
    String? mood,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? wordCount,
    bool? isCompleted,
    List<String>? learnedWords,
    List<String>? learnedPhrases,
    String? userId,
  }) {
    return DiaryEntry(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      translatedTitle: translatedTitle ?? this.translatedTitle,
      translatedContent: translatedContent ?? this.translatedContent,
      correctedContent: correctedContent ?? this.correctedContent,
      originalLanguage: originalLanguage ?? this.originalLanguage,
      mood: mood ?? this.mood,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      wordCount: wordCount ?? this.wordCount,
      isCompleted: isCompleted ?? this.isCompleted,
      learnedWords: learnedWords ?? this.learnedWords,
      learnedPhrases: learnedPhrases ?? this.learnedPhrases,
      userId: userId ?? this.userId,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'translatedTitle': translatedTitle,
      'translatedContent': translatedContent,
      'correctedContent': correctedContent,
      'originalLanguage': originalLanguage,
      'mood': mood,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'wordCount': wordCount,
      'isCompleted': isCompleted,
      'learnedWords': learnedWords,
      'learnedPhrases': learnedPhrases,
      'userId': userId,
    };
  }

  factory DiaryEntry.fromJson(Map<String, dynamic> json) {
    return DiaryEntry(
      id: json['id'],
      title: json['title'] ?? '',
      content: json['content'] ?? '',
      translatedTitle: json['translatedTitle'],
      translatedContent: json['translatedContent'],
      correctedContent: json['correctedContent'],
      originalLanguage: json['originalLanguage'] ?? 'ja',
      mood: json['mood'] ?? 'neutral',
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt']) 
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null 
          ? DateTime.parse(json['updatedAt']) 
          : DateTime.now(),
      wordCount: json['wordCount'] ?? 0,
      isCompleted: json['isCompleted'] ?? false,
      learnedWords: json['learnedWords'] != null 
          ? List<String>.from(json['learnedWords']) 
          : [],
      learnedPhrases: json['learnedPhrases'] != null 
          ? List<String>.from(json['learnedPhrases']) 
          : null,
      userId: json['userId'],
    );
  }

  // Supabase用のマップ変換
  Map<String, dynamic> toSupabase() {
    return {
      'id': id,
      'user_id': userId ?? 'anonymous',
      'title': title,
      'content': content,
      'translated_content': translatedContent,
      'mood': mood,
      'word_count': wordCount,
      'learned_words': learnedWords,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory DiaryEntry.fromSupabase(Map<String, dynamic> json) {
    return DiaryEntry(
      id: json['id'],
      title: json['title'] ?? '',
      content: json['content'] ?? '',
      translatedContent: json['translated_content'],
      mood: json['mood'] ?? 'neutral',
      userId: json['user_id'],
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at']) 
          : DateTime.now(),
      updatedAt: json['updated_at'] != null 
          ? DateTime.parse(json['updated_at']) 
          : DateTime.now(),
      wordCount: json['word_count'] ?? 0,
      learnedWords: json['learned_words'] != null 
          ? List<String>.from(json['learned_words']) 
          : [],
    );
  }
}