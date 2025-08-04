import 'package:uuid/uuid.dart';

class ConversationMessage {
  final String id;
  final String text;
  final bool isUser;
  final DateTime createdAt;
  final bool isError;
  final List<String>? corrections;
  final List<String>? suggestions;

  ConversationMessage({
    String? id,
    required this.text,
    required this.isUser,
    DateTime? createdAt,
    this.isError = false,
    this.corrections,
    this.suggestions,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now();

  ConversationMessage copyWith({
    String? id,
    String? text,
    bool? isUser,
    DateTime? createdAt,
    bool? isError,
    List<String>? corrections,
    List<String>? suggestions,
  }) {
    return ConversationMessage(
      id: id ?? this.id,
      text: text ?? this.text,
      isUser: isUser ?? this.isUser,
      createdAt: createdAt ?? this.createdAt,
      isError: isError ?? this.isError,
      corrections: corrections ?? this.corrections,
      suggestions: suggestions ?? this.suggestions,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'text': text,
      'isUser': isUser,
      'createdAt': createdAt.toIso8601String(),
      'isError': isError,
      'corrections': corrections,
      'suggestions': suggestions,
    };
  }

  factory ConversationMessage.fromJson(Map<String, dynamic> json) {
    return ConversationMessage(
      id: json['id'],
      text: json['text'] ?? '',
      isUser: json['isUser'] ?? true,
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt']) 
          : DateTime.now(),
      isError: json['isError'] ?? false,
      corrections: json['corrections'] != null 
          ? List<String>.from(json['corrections']) 
          : null,
      suggestions: json['suggestions'] != null 
          ? List<String>.from(json['suggestions']) 
          : null,
    );
  }
}