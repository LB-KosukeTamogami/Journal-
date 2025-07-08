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
You are a language learning assistant. Please process the following text:

1. Detect the language of the input text
2. If there are grammatical errors, correct them
3. Improve the text to make it more natural
4. Translate the text to the target language (if already in target language, translate to the other language)
5. Provide brief explanations of grammatical improvements

Input text: "$content"
Target language: $targetLanguage

Please respond in the following JSON format:
{
  "detected_language": "detected language code (en for English, ja for Japanese)",
  "original": "original text",
  "corrected": "corrected text",
  "translation": "translated text in target language",
  "improvements": ["improvement point 1 in Japanese", "improvement point 2 in Japanese"],
  "learned_phrases": ["phrase 1 (with Japanese explanation)", "phrase 2 (with Japanese explanation)"]
}

Important guidelines:
- If input is in English, translate to Japanese completely
- If input is in Japanese, translate to English completely
- Do not mix languages in the translation
- Keep the translation pure and natural
- Write ALL improvements in proper Japanese. Examples:
  - "過去形の使い方に注意しましょう" (Be careful with past tense usage)
  - "冠詞の使用法に注意が必要です" (Need to pay attention to article usage)
  - "時制の一致に気をつけましょう" (Be careful with tense agreement)
- For learned_phrases, show the English phrase followed by Japanese explanation
  Example: "go to school (学校に行く)"
- IMPORTANT: Use proper Japanese characters, not corrupted text
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
              'role': 'system',
              'content': 'You are a helpful language learning assistant that always responds in valid JSON format with proper UTF-8 encoding. Ensure all Japanese text is correctly formed.',
            },
            {
              'role': 'user',
              'content': prompt,
            },
          ],
          'temperature': 0.7,
          'max_tokens': 1000,
          'response_format': {'type': 'json_object'},
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final content = data['choices'][0]['message']['content'];
        final result = jsonDecode(content);
        
        // 日本語テキストの検証と修正
        if (result['improvements'] != null) {
          final List<String> cleanedImprovements = [];
          for (final item in result['improvements'] as List) {
            final text = item.toString();
            // 文字化けチェック
            if (_isCorruptedJapanese(text)) {
              // デフォルトの改善点リストから選択
              final defaults = [
                '過去形と現在形の使い分けに注意しましょう',
                '冠詞（a/an/the）の使い方を確認しましょう',
                '前置詞の選択を見直しましょう',
                '動詞の時制を統一しましょう',
                '語順に注意して文を構成しましょう',
              ];
              cleanedImprovements.add(defaults[cleanedImprovements.length % defaults.length]);
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
}