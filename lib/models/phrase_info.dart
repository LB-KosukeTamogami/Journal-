class PhraseInfo {
  final String phrase;
  final String meaning;
  final String? example;
  final String? category;

  PhraseInfo({
    required this.phrase,
    required this.meaning,
    this.example,
    this.category,
  });

  Map<String, dynamic> toJson() {
    return {
      'phrase': phrase,
      'meaning': meaning,
      'example': example,
      'category': category,
    };
  }

  factory PhraseInfo.fromJson(Map<String, dynamic> json) {
    return PhraseInfo(
      phrase: json['phrase'] ?? '',
      meaning: json['meaning'] ?? '',
      example: json['example'],
      category: json['category'],
    );
  }
}