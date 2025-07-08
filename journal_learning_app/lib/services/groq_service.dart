import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/diary_entry.dart';
import '../config/api_config.dart';

class GroqService {
  static const String _baseUrl = 'https://api.groq.com/openai/v1/chat/completions';
  static const String _model = 'llama-3.1-70b-versatile';

  static Future<Map<String, dynamic>> correctAndTranslate(
    String content, {
    String sourceLanguage = 'auto',
    String targetLanguage = 'en',
  }) async {
    try {
      final prompt = '''
あなたは言語学習を支援するAIアシスタントです。
以下のテキストについて、次の処理を行ってください：

1. 言語を自動検出してください
2. 文法的な誤りがあれば修正してください
3. より自然な表現に改善してください
4. 指定された言語に翻訳してください（既に指定言語の場合は他の言語に翻訳）
5. 文法的な改善点を簡潔に説明してください

テキスト: "$content"
ターゲット言語: $targetLanguage

以下のJSON形式で回答してください：
{
  "detected_language": "検出された言語コード",
  "original": "元のテキスト",
  "corrected": "修正されたテキスト",
  "translation": "翻訳されたテキスト",
  "improvements": ["改善点1", "改善点2"],
  "learned_phrases": ["重要なフレーズ1", "重要なフレーズ2"]
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
              'role': 'system',
              'content': 'You are a helpful language learning assistant that always responds in valid JSON format.',
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
        return jsonDecode(content);
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
}