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
You are a language learning assistant. Process the following text:

Input text: "$content"
Target language: $targetLanguage

Analyze the text and provide:
1. If input is Japanese: translate to English
2. If input is English: correct grammar errors and translate to Japanese

Respond in JSON format:
{
  "detected_language": "en" or "ja",
  "original": "original text",
  "corrected": "corrected version of original text (same language)",
  "translation": "translated text to target language",
  "improvements": ["improvement 1", "improvement 2"],
  "learned_phrases": ["phrase 1", "phrase 2"]
}

Important rules:
- If detected_language is "ja", then translation should be in English
- If detected_language is "en", then translation should be in Japanese
- corrected should always be in the same language as original

For improvements (only for English input), provide simple Japanese explanations:
- Use basic Japanese only
- Example: "past tense error" → "過去形の誤り"
- Example: "article missing" → "冠詞が必要"
- Example: "word order issue" → "語順の問題"

For learned_phrases, format as "English phrase (Japanese meaning)":
- Example: "go to school (学校に行く)"
- Example: "have fun (楽しむ)"
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
}