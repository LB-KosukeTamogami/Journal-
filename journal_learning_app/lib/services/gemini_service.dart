import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/diary_entry.dart';
import '../config/api_config.dart';

class GeminiService {
  static const String _baseUrl = 'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash-exp:generateContent';
  
  static Future<Map<String, dynamic>> correctAndTranslate(
    String content, {
    String sourceLanguage = 'auto',
    String targetLanguage = 'en',
  }) async {
    try {
      final apiKey = ApiConfig.getGeminiApiKey();
      if (apiKey == null || apiKey.isEmpty) {
        print('Gemini API key not configured, using offline mode');
        return _getOfflineResponse(content);
      }

      final prompt = '''
You are an expert language translator and teacher specializing in natural, conversational translations between English and Japanese.

Input text: "$content"

TASK:
1. Detect the language (English or Japanese)
2. If English → Translate to natural, conversational Japanese
3. If Japanese → Translate to natural English
4. For English input, also provide grammar corrections

翻訳の重要なルール:
- 直訳ではなく、自然な表現を使用してください
- 文脈を考慮して適切な敬語レベルを選んでください
- 日常会話で実際に使われる表現を優先してください

翻訳例:
- "I went to school yesterday. It was very fun!" → "昨日学校に行きました。とても楽しかったです！"
- "I had breakfast" → "朝ごはんを食べました"
- "It was delicious" → "美味しかったです" or "おいしかった"
- "I like music" → "音楽が好きです"

Respond in JSON format:
{
  "detected_language": "en" or "ja",
  "original": "original text",
  "corrected": "corrected version (for English only, same as original for Japanese)",
  "translation": "natural translation in target language",
  "improvements": ["improvement in Japanese"],
  "learned_phrases": ["useful phrase (translation)"]
}

IMPORTANT:
- Provide NATURAL, CONVERSATIONAL translations, NOT word-for-word translations
- Use appropriate casual/polite forms based on context
- For "very fun" → "とても楽しい" NOT "とても楽しみ"
- Ensure all Japanese text uses proper characters (no corrupted text)''';

      final response = await http.post(
        Uri.parse('$_baseUrl?key=$apiKey'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'contents': [{
            'parts': [{
              'text': prompt
            }]
          }],
          'generationConfig': {
            'temperature': 0.3,
            'topK': 40,
            'topP': 0.95,
            'maxOutputTokens': 1024,
            'responseMimeType': 'application/json',
          },
          'safetySettings': [
            {
              'category': 'HARM_CATEGORY_HARASSMENT',
              'threshold': 'BLOCK_MEDIUM_AND_ABOVE'
            },
            {
              'category': 'HARM_CATEGORY_HATE_SPEECH',
              'threshold': 'BLOCK_MEDIUM_AND_ABOVE'
            },
            {
              'category': 'HARM_CATEGORY_SEXUALLY_EXPLICIT',
              'threshold': 'BLOCK_MEDIUM_AND_ABOVE'
            },
            {
              'category': 'HARM_CATEGORY_DANGEROUS_CONTENT',
              'threshold': 'BLOCK_MEDIUM_AND_ABOVE'
            }
          ]
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        // Gemini APIのレスポンス構造を解析
        if (data['candidates'] != null && 
            data['candidates'].isNotEmpty &&
            data['candidates'][0]['content'] != null &&
            data['candidates'][0]['content']['parts'] != null &&
            data['candidates'][0]['content']['parts'].isNotEmpty) {
          
          final textContent = data['candidates'][0]['content']['parts'][0]['text'];
          final result = jsonDecode(textContent);
          
          // 翻訳結果の後処理
          if (result['translation'] != null) {
            result['translation'] = _postProcessTranslation(result['translation'], result['detected_language']);
          }
          
          // 日本語テキストの検証と修正
          if (result['improvements'] != null && result['improvements'] is List) {
            result['improvements'] = _validateImprovements(result['improvements'] as List);
          }
          
          return result;
        } else {
          print('Unexpected Gemini API response structure');
          return _getOfflineResponse(content);
        }
      } else {
        print('Gemini API Error: ${response.statusCode} - ${response.body}');
        return _getOfflineResponse(content);
      }
    } catch (e) {
      print('Gemini Service Error: $e');
      return _getOfflineResponse(content);
    }
  }

  static Future<List<Map<String, String>>> generateExampleSentences(
    String word,
    String language,
  ) async {
    try {
      final apiKey = ApiConfig.getGeminiApiKey();
      if (apiKey == null || apiKey.isEmpty) {
        return _getOfflineExamples(word, language);
      }

      final prompt = '''
"$word"という単語/フレーズを使った例文を3つ生成してください。
言語: $language
レベル: 初級〜中級

以下のJSON形式で回答してください：
{
  "examples": [
    {"sentence": "例文1", "translation": "翻訳1"},
    {"sentence": "例文2", "translation": "翻訳2"},
    {"sentence": "例文3", "translation": "翻訳3"}
  ]
}''';

      final response = await http.post(
        Uri.parse('$_baseUrl?key=$apiKey'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'contents': [{
            'parts': [{
              'text': prompt
            }]
          }],
          'generationConfig': {
            'temperature': 0.8,
            'topK': 40,
            'topP': 0.95,
            'maxOutputTokens': 512,
            'responseMimeType': 'application/json',
          }
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['candidates'] != null && 
            data['candidates'].isNotEmpty &&
            data['candidates'][0]['content'] != null &&
            data['candidates'][0]['content']['parts'] != null &&
            data['candidates'][0]['content']['parts'].isNotEmpty) {
          
          final textContent = data['candidates'][0]['content']['parts'][0]['text'];
          final content = jsonDecode(textContent);
          return List<Map<String, String>>.from(content['examples']);
        }
      }
    } catch (e) {
      print('Example generation error: $e');
    }
    
    return _getOfflineExamples(word, language);
  }
  
  // オフラインレスポンス
  static Map<String, dynamic> _getOfflineResponse(String content) {
    return {
      'detected_language': _detectLanguage(content),
      'original': content,
      'corrected': content,
      'translation': content,
      'improvements': [],
      'learned_phrases': [],
    };
  }
  
  // オフライン例文生成
  static List<Map<String, String>> _getOfflineExamples(String word, String language) {
    if (language == 'en') {
      return [
        {'sentence': 'I learned a new word: $word.', 'translation': '新しい単語を学びました: $word'},
        {'sentence': 'Can you explain what $word means?', 'translation': '$wordの意味を説明してもらえますか？'},
        {'sentence': 'The word $word is very useful.', 'translation': '$wordという単語はとても便利です。'},
      ];
    } else {
      return [
        {'sentence': '「$word」という言葉を覚えました。', 'translation': 'I learned the word "$word".'},
        {'sentence': '$wordの使い方を教えてください。', 'translation': 'Please teach me how to use $word.'},
        {'sentence': '$wordはよく使う表現です。', 'translation': '$word is a commonly used expression.'},
      ];
    }
  }
  
  // 言語検出
  static String _detectLanguage(String text) {
    final japanesePattern = RegExp(r'[\u3040-\u309F\u30A0-\u30FF\u4E00-\u9FAF]');
    return japanesePattern.hasMatch(text) ? 'ja' : 'en';
  }
  
  // 改善点の検証
  static List<String> _validateImprovements(List improvements) {
    final defaultImprovements = [
      '過去形の使い方に注意',
      '冠詞の使用を確認',
      '前置詞の選択を見直す',
      '動詞の時制を統一',
      '語順に注意',
    ];
    
    final List<String> cleanedImprovements = [];
    
    for (int i = 0; i < improvements.length; i++) {
      final text = improvements[i]?.toString() ?? '';
      if (text.isEmpty || _isCorruptedJapanese(text) || !_containsJapanese(text)) {
        cleanedImprovements.add(defaultImprovements[i % defaultImprovements.length]);
      } else {
        cleanedImprovements.add(text);
      }
    }
    
    return cleanedImprovements;
  }
  
  static bool _isCorruptedJapanese(String text) {
    final corruptedPatterns = [
      '過当形', '幸相', '注昔', '必裂', '琀科', '朝形',
      RegExp(r'[\u0000-\u001F]'),
    ];
    
    for (final pattern in corruptedPatterns) {
      if (pattern is String && text.contains(pattern)) {
        return true;
      } else if (pattern is RegExp && pattern.hasMatch(text)) {
        return true;
      }
    }
    
    return false;
  }
  
  static bool _containsJapanese(String text) {
    return RegExp(r'[\u3040-\u309F\u30A0-\u30FF\u4E00-\u9FAF]').hasMatch(text);
  }
  
  static String _postProcessTranslation(String translation, String sourceLanguage) {
    if (sourceLanguage != 'en') return translation;
    
    final corrections = {
      'とても楽しみ': 'とても楽しい',
      'とてもおもしろ': 'とても面白い',
      'とてもおいし': 'とても美味しい',
      '非常に楽しい': 'とても楽しい',
      '非常に面白い': 'とても面白い',
      'は楽しいでした': 'は楽しかったです',
      '楽しいでした': '楽しかったです',
      '面白いでした': '面白かったです',
      '美味しいでした': '美味しかったです',
    };
    
    String result = translation;
    corrections.forEach((wrong, correct) {
      result = result.replaceAll(wrong, correct);
    });
    
    result = result.replaceAll(RegExp(r'\s+(?=[\u3002\u3001\uff01\uff1f])'), '');
    
    return result;
  }
}