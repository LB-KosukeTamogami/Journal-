import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/diary_entry.dart';
import '../config/api_config.dart';

class GroqService {
  static const String _baseUrl = 'https://api.groq.com/openai/v1/chat/completions';
  static const String _model = 'llama-3.3-70b-versatile';

  static Future<Map<String, dynamic>> correctAndTranslate(
    String content, {
    String sourceLanguage = 'auto',
    String targetLanguage = 'en',
  }) async {
    try {
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
        Uri.parse(_baseUrl),
        headers: {
          'Authorization': 'Bearer ${ApiConfig.getGroqApiKey()}',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'model': _model,
          'messages': [
            {
              'role': 'system',
              'content': 'You are a native bilingual speaker of both English and Japanese who specializes in natural, conversational translations. You understand cultural nuances and always provide translations that sound natural to native speakers. Always respond in valid JSON format with proper UTF-8 encoding. Never use corrupted or incorrect Japanese characters.',
            },
            {
              'role': 'user',
              'content': prompt,
            },
          ],
          'temperature': 0.3,
          'max_tokens': 1000,
          'response_format': {'type': 'json_object'},
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final content = data['choices'][0]['message']['content'];
        final result = jsonDecode(content);
        
        // 翻訳結果の後処理
        if (result['translation'] != null) {
          result['translation'] = _postProcessTranslation(result['translation'], result['detected_language']);
        }
        
        // 日本語テキストの検証と修正
        if (result['improvements'] != null && result['improvements'] is List) {
          final defaultImprovements = [
            '過去形の使い方に注意',
            '冠詞の使用を確認',
            '前置詞の選択を見直す',
            '動詞の時制を統一',
            '語順に注意',
          ];
          
          final List<String> cleanedImprovements = [];
          final improvements = result['improvements'] as List;
          
          for (int i = 0; i < improvements.length; i++) {
            final text = improvements[i]?.toString() ?? '';
            // 空文字列、文字化け、英語のみの場合はデフォルトを使用
            if (text.isEmpty || _isCorruptedJapanese(text) || !_containsJapanese(text)) {
              cleanedImprovements.add(defaultImprovements[i % defaultImprovements.length]);
            } else {
              cleanedImprovements.add(text);
            }
          }
          result['improvements'] = cleanedImprovements;
        }
        
        return result;
      } else {
        print('Groq API Error: ${response.statusCode} - ${response.body}');
        throw Exception('Failed to process with Groq API');
      }
    } catch (e) {
      print('Groq Service Error: $e');
      return {
        'detected_language': sourceLanguage,
        'original': content,
        'corrected': content,
        'translation': content,
        'improvements': [],
        'learned_phrases': [],
      };
    }
  }

  static Future<List<Map<String, String>>> generateExampleSentences(
    String word,
    String language,
  ) async {
    try {
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
}
''';

      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Authorization': 'Bearer ${ApiConfig.getGroqApiKey()}',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'model': _model,
          'messages': [
            {
              'role': 'user',
              'content': prompt,
            },
          ],
          'temperature': 0.8,
          'max_tokens': 500,
          'response_format': {'type': 'json_object'},
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final content = jsonDecode(data['choices'][0]['message']['content']);
        return List<Map<String, String>>.from(content['examples']);
      }
    } catch (e) {
      print('Example generation error: $e');
    }
    
    return [];
  }
  
  static bool _isCorruptedJapanese(String text) {
    // 一般的な文字化けパターンをチェック
    final corruptedPatterns = [
      '過当形', '幸相', '注昔', '必裂', '琀科', '朝形',
      RegExp(r'[\u0000-\u001F]'), // 制御文字
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
  
  static String _getDefaultImprovement() {
    // 固定のデフォルト改善点を返す
    return '文法の基本を確認しましょう';
  }
  
  static bool _containsJapanese(String text) {
    // 日本語文字が含まれているかチェック
    return RegExp(r'[\u3040-\u309F\u30A0-\u30FF\u4E00-\u9FAF]').hasMatch(text);
  }
  
  static String _postProcessTranslation(String translation, String sourceLanguage) {
    // 英語から日本語への翻訳の場合のみ後処理
    if (sourceLanguage != 'en') return translation;
    
    // 一般的な誤訳を修正
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
    
    // 不自然なスペースを削除
    result = result.replaceAll(RegExp(r'\s+(?=[\u3002\u3001\uff01\uff1f])'), '');
    
    return result;
  }
}