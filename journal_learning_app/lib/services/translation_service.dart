import 'dart:convert';
import 'package:http/http.dart' as http;

class TranslationService {
  // 簡易的な翻訳マッピング（オフライン用）
  static const Map<String, String> _simpleTranslations = {
    // 基本的な単語
    'hello': 'こんにちは',
    'goodbye': 'さようなら',
    'thank you': 'ありがとう',
    'please': 'お願いします',
    'yes': 'はい',
    'no': 'いいえ',
    'good morning': 'おはようございます',
    'good evening': 'こんばんは',
    'how are you': '元気ですか',
    'i am fine': '元気です',
    'what is your name': 'お名前は何ですか',
    'my name is': '私の名前は',
    'nice to meet you': 'はじめまして',
    'excuse me': 'すみません',
    'sorry': 'ごめんなさい',
    
    // 日常会話
    'today': '今日',
    'yesterday': '昨日',
    'tomorrow': '明日',
    'morning': '朝',
    'afternoon': '午後',
    'evening': '夕方',
    'night': '夜',
    'breakfast': '朝食',
    'lunch': '昼食',
    'dinner': '夕食',
    'work': '仕事',
    'school': '学校',
    'home': '家',
    'family': '家族',
    'friend': '友達',
    'happy': '嬉しい',
    'sad': '悲しい',
    'tired': '疲れた',
    'busy': '忙しい',
    'free': '暇',
    'fun': '楽しい',
    'interesting': '面白い',
    'boring': 'つまらない',
    'difficult': '難しい',
    'easy': '簡単',
    'good': '良い',
    'bad': '悪い',
    'beautiful': '美しい',
    'delicious': '美味しい',
    
    // 日本語から英語
    'こんにちは': 'hello',
    'さようなら': 'goodbye',
    'ありがとう': 'thank you',
    'お願いします': 'please',
    'はい': 'yes',
    'いいえ': 'no',
    'おはようございます': 'good morning',
    'こんばんは': 'good evening',
    '元気ですか': 'how are you',
    '元気です': 'i am fine',
    'お名前は何ですか': 'what is your name',
    '私の名前は': 'my name is',
    'はじめまして': 'nice to meet you',
    'すみません': 'excuse me',
    'ごめんなさい': 'sorry',
    '今日': 'today',
    '昨日': 'yesterday',
    '明日': 'tomorrow',
    '朝': 'morning',
    '午後': 'afternoon',
    '夕方': 'evening',
    '夜': 'night',
    '朝食': 'breakfast',
    '昼食': 'lunch',
    '夕食': 'dinner',
    '仕事': 'work',
    '学校': 'school',
    '家': 'home',
    '家族': 'family',
    '友達': 'friend',
    '嬉しい': 'happy',
    '悲しい': 'sad',
    '疲れた': 'tired',
    '忙しい': 'busy',
    '暇': 'free',
    '楽しい': 'fun',
    '面白い': 'interesting',
    'つまらない': 'boring',
    '難しい': 'difficult',
    '簡単': 'easy',
    '良い': 'good',
    '悪い': 'bad',
    '美しい': 'beautiful',
    '美味しい': 'delicious',
  };

  /// テキストを翻訳する
  /// [text] 翻訳するテキスト
  /// [targetLanguage] 翻訳先言語 ('ja' または 'en')
  /// [useOnlineService] オンライン翻訳サービスを使用するか
  static Future<TranslationResult> translate(
    String text, {
    required String targetLanguage,
    bool useOnlineService = false,
  }) async {
    if (text.trim().isEmpty) {
      return TranslationResult(
        originalText: text,
        translatedText: text,
        targetLanguage: targetLanguage,
        success: false,
        error: 'テキストが空です',
      );
    }

    try {
      if (useOnlineService) {
        // 将来的にGoogle Translate APIなどを使用
        return await _translateOnline(text, targetLanguage);
      } else {
        // オフライン翻訳（簡易的）
        return _translateOffline(text, targetLanguage);
      }
    } catch (e) {
      return TranslationResult(
        originalText: text,
        translatedText: text,
        targetLanguage: targetLanguage,
        success: false,
        error: e.toString(),
      );
    }
  }

  /// オフライン翻訳（簡易的な実装）
  static TranslationResult _translateOffline(String text, String targetLanguage) {
    final lowerText = text.toLowerCase().trim();
    
    // 完全一致を最初に試す
    String? directTranslation = _simpleTranslations[lowerText];
    if (directTranslation != null) {
      return TranslationResult(
        originalText: text,
        translatedText: directTranslation,
        targetLanguage: targetLanguage,
        success: true,
      );
    }

    // 部分一致を試す
    final words = lowerText.split(' ');
    final translatedWords = <String>[];
    bool hasTranslation = false;

    for (final word in words) {
      final cleanWord = word.replaceAll(RegExp(r'[^\w\s]'), '');
      final translation = _simpleTranslations[cleanWord];
      if (translation != null) {
        translatedWords.add(translation);
        hasTranslation = true;
      } else {
        translatedWords.add(word);
      }
    }

    if (hasTranslation) {
      return TranslationResult(
        originalText: text,
        translatedText: translatedWords.join(' '),
        targetLanguage: targetLanguage,
        success: true,
        isPartialTranslation: true,
      );
    }

    // 翻訳できない場合
    return TranslationResult(
      originalText: text,
      translatedText: text,
      targetLanguage: targetLanguage,
      success: false,
      error: '翻訳できませんでした',
    );
  }

  /// オンライン翻訳（将来実装）
  static Future<TranslationResult> _translateOnline(String text, String targetLanguage) async {
    // TODO: 実際のAPI実装
    // Google Translate API、DeepL API、または他の翻訳サービスを使用
    
    // 現在はオフライン翻訳にフォールバック
    return _translateOffline(text, targetLanguage);
  }

  /// 文章内の英単語を検出して翻訳候補を提供
  static Map<String, String> suggestTranslations(String text) {
    final suggestions = <String, String>{};
    final words = text.toLowerCase().split(RegExp(r'\W+'));
    
    for (final word in words) {
      if (word.isEmpty) continue;
      
      final translation = _simpleTranslations[word];
      if (translation != null && !suggestions.containsKey(word)) {
        suggestions[word] = translation;
      }
    }
    
    return suggestions;
  }

  /// 言語を自動検出（簡易的）
  static String detectLanguage(String text) {
    // 日本語文字（ひらがな、カタカナ、漢字）が含まれているかチェック
    final japanesePattern = RegExp(r'[\u3040-\u309F\u30A0-\u30FF\u4E00-\u9FAF]');
    
    if (japanesePattern.hasMatch(text)) {
      return 'ja';
    } else {
      return 'en';
    }
  }

  /// 自動翻訳（言語を自動検出して反対の言語に翻訳）
  static Future<TranslationResult> autoTranslate(String text) async {
    if (text.trim().isEmpty) {
      return TranslationResult(
        originalText: text,
        translatedText: '',
        targetLanguage: 'en',
        success: false,
        error: 'テキストが空です',
      );
    }

    // 言語を自動検出
    final detectedLanguage = detectLanguage(text);
    final targetLanguage = detectedLanguage == 'ja' ? 'en' : 'ja';
    
    // 翻訳実行
    return await translate(
      text,
      targetLanguage: targetLanguage,
      useOnlineService: false, // 現在はオフラインのみ
    );
  }

  /// 翻訳履歴を保存（将来実装）
  static Future<void> saveTranslationHistory(TranslationResult result) async {
    // TODO: 翻訳履歴をローカルストレージに保存
  }

  /// 翻訳履歴を取得（将来実装）
  static Future<List<TranslationResult>> getTranslationHistory() async {
    // TODO: 翻訳履歴をローカルストレージから取得
    return [];
  }
}

class TranslationResult {
  final String originalText;
  final String translatedText;
  final String targetLanguage;
  final bool success;
  final String? error;
  final bool isPartialTranslation;
  final DateTime timestamp;

  TranslationResult({
    required this.originalText,
    required this.translatedText,
    required this.targetLanguage,
    required this.success,
    this.error,
    this.isPartialTranslation = false,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toJson() {
    return {
      'originalText': originalText,
      'translatedText': translatedText,
      'targetLanguage': targetLanguage,
      'success': success,
      'error': error,
      'isPartialTranslation': isPartialTranslation,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory TranslationResult.fromJson(Map<String, dynamic> json) {
    return TranslationResult(
      originalText: json['originalText'],
      translatedText: json['translatedText'],
      targetLanguage: json['targetLanguage'],
      success: json['success'],
      error: json['error'],
      isPartialTranslation: json['isPartialTranslation'] ?? false,
      timestamp: DateTime.parse(json['timestamp']),
    );
  }
}