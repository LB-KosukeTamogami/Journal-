import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

class TranslationService {
  // Google Translate APIを使用した翻訳（将来実装）
  static Future<String> translate({
    required String text,
    required String targetLanguage,
    String? sourceLanguage,
  }) async {
    final apiKey = ApiConfig.getGoogleTranslateApiKey();
    
    if (apiKey == null || apiKey.isEmpty) {
      // APIキーがない場合はオフライン翻訳を返す
      return _getOfflineTranslation(text, targetLanguage);
    }

    try {
      // TODO: Google Translate APIの実装
      // 現在はオフライン翻訳を返す
      return _getOfflineTranslation(text, targetLanguage);
    } catch (e) {
      print('[TranslationService] Translation error: $e');
      return _getOfflineTranslation(text, targetLanguage);
    }
  }

  // 言語検出
  static String detectLanguage(String text) {
    // 簡易的な言語検出
    final japanesePattern = RegExp(r'[\u3040-\u309F\u30A0-\u30FF\u4E00-\u9FAF]');
    final hasJapanese = japanesePattern.hasMatch(text);
    
    if (hasJapanese) {
      // 日本語の割合を計算
      final japaneseCharCount = japanesePattern.allMatches(text).length;
      final totalCharCount = text.replaceAll(RegExp(r'\s'), '').length;
      
      if (totalCharCount > 0 && japaneseCharCount / totalCharCount > 0.3) {
        return 'ja';
      }
    }
    
    return 'en';
  }

  // オフライン翻訳（フォールバック）
  static String _getOfflineTranslation(String text, String targetLanguage) {
    final sourceLanguage = detectLanguage(text);
    
    if (sourceLanguage == targetLanguage) {
      return text;
    }
    
    // 簡単な定型文の翻訳
    final translations = {
      'en->ja': {
        'Hello': 'こんにちは',
        'Good morning': 'おはようございます',
        'Good evening': 'こんばんは',
        'Thank you': 'ありがとうございます',
        'Yes': 'はい',
        'No': 'いいえ',
      },
      'ja->en': {
        'こんにちは': 'Hello',
        'おはようございます': 'Good morning',
        'こんばんは': 'Good evening',
        'ありがとうございます': 'Thank you',
        'はい': 'Yes',
        'いいえ': 'No',
      },
    };
    
    final key = '$sourceLanguage->$targetLanguage';
    final dict = translations[key];
    
    if (dict != null && dict.containsKey(text)) {
      return dict[text]!;
    }
    
    // 翻訳できない場合はメッセージを返す
    if (targetLanguage == 'ja') {
      return '※オフラインのため翻訳できません';
    } else {
      return '※Translation not available offline';
    }
  }

  // 翻訳品質スコア計算（仮実装）
  static double calculateTranslationQuality(String original, String translated) {
    if (original.isEmpty || translated.isEmpty) return 0.0;
    
    // 言語が異なることを確認
    final originalLang = detectLanguage(original);
    final translatedLang = detectLanguage(translated);
    
    if (originalLang == translatedLang) return 0.3;
    
    // 長さの比率をチェック（日英で文字数は大きく異なる）
    final lengthRatio = translated.length / original.length;
    double lengthScore = 1.0;
    
    if (originalLang == 'ja' && translatedLang == 'en') {
      // 日本語→英語の場合、英語の方が長くなることが多い
      lengthScore = lengthRatio > 0.5 && lengthRatio < 3.0 ? 1.0 : 0.7;
    } else if (originalLang == 'en' && translatedLang == 'ja') {
      // 英語→日本語の場合、日本語の方が短くなることが多い
      lengthScore = lengthRatio > 0.3 && lengthRatio < 2.0 ? 1.0 : 0.7;
    }
    
    return lengthScore;
  }

  // バッチ翻訳（複数テキストの一括翻訳）
  static Future<List<String>> batchTranslate({
    required List<String> texts,
    required String targetLanguage,
    String? sourceLanguage,
  }) async {
    final translations = <String>[];
    
    for (final text in texts) {
      final translated = await translate(
        text: text,
        targetLanguage: targetLanguage,
        sourceLanguage: sourceLanguage,
      );
      translations.add(translated);
    }
    
    return translations;
  }
  
  // 単語の翻訳候補を提案
  static Map<String, String> suggestTranslations(String word) {
    final suggestions = <String, String>{};
    final lowerWord = word.toLowerCase();
    
    // 基本的な英単語の翻訳
    final commonWords = {
      'hello': 'こんにちは',
      'world': '世界',
      'love': '愛',
      'heart': '心',
      'time': '時間',
      'day': '日',
      'night': '夜',
      'morning': '朝',
      'evening': '夕方',
      'afternoon': '午後',
      'today': '今日',
      'tomorrow': '明日',
      'yesterday': '昨日',
      'friend': '友達',
      'family': '家族',
      'work': '仕事',
      'study': '勉強',
      'school': '学校',
      'home': '家',
      'food': '食べ物',
      'water': '水',
      'happy': '幸せ',
      'sad': '悲しい',
      'good': '良い',
      'bad': '悪い',
      'beautiful': '美しい',
      'big': '大きい',
      'small': '小さい',
      'new': '新しい',
      'old': '古い',
      'easy': '簡単',
      'difficult': '難しい',
      'important': '重要',
      'interesting': '興味深い',
      'delicious': 'おいしい',
      'wonderful': '素晴らしい',
    };
    
    if (commonWords.containsKey(lowerWord)) {
      suggestions[lowerWord] = commonWords[lowerWord]!;
    } else {
      // 翻訳が見つからない場合
      suggestions[lowerWord] = '※要翻訳';
    }
    
    return suggestions;
  }
}