class ConversationMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final List<String>? corrections;
  final List<String>? suggestions;
  final bool isError;

  ConversationMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.corrections,
    this.suggestions,
    this.isError = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'text': text,
      'isUser': isUser,
      'timestamp': timestamp.toIso8601String(),
      'corrections': corrections,
      'suggestions': suggestions,
      'isError': isError,
    };
  }

  factory ConversationMessage.fromJson(Map<String, dynamic> json) {
    return ConversationMessage(
      text: json['text'],
      isUser: json['isUser'],
      timestamp: DateTime.parse(json['timestamp']),
      corrections: json['corrections'] != null
          ? List<String>.from(json['corrections'])
          : null,
      suggestions: json['suggestions'] != null
          ? List<String>.from(json['suggestions'])
          : null,
      isError: json['isError'] ?? false,
    );
  }
}