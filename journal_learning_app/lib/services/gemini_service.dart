import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/diary_entry.dart';
import '../models/conversation_message.dart';
import '../config/api_config.dart';

// 会話レスポンスクラス
class ConversationResponse {
  final String reply;
  final List<String> corrections;
  final List<String> suggestions;

  ConversationResponse({
    required this.reply,
    required this.corrections,
    required this.suggestions,
  });
}

class GeminiService {
  static const String _baseUrl = 'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash-exp:generateContent';
  static DateTime? _lastApiCall;
  static const Duration _rateLimitDelay = Duration(seconds: 2); // レート制限対策
  
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
      
      // レート制限対策: 前回のAPI呼び出しから一定時間待機
      if (_lastApiCall != null) {
        final timeSinceLastCall = DateTime.now().difference(_lastApiCall!);
        if (timeSinceLastCall < _rateLimitDelay) {
          final waitTime = _rateLimitDelay - timeSinceLastCall;
          print('GeminiService: Waiting ${waitTime.inMilliseconds}ms for rate limit');
          await Future.delayed(waitTime);
        }
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

      // API呼び出し時刻を記録
      _lastApiCall = DateTime.now();
      
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
      } else if (response.statusCode == 429) {
        // レート制限エラー
        print('Gemini API: Rate limit reached (429). Using enhanced offline translation.');
        return _getOfflineResponse(content);
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
  
  // 会話ジャーナル用の応答生成
  static Future<ConversationResponse> generateConversationResponse({
    required String userMessage,
    required List<ConversationMessage> conversationHistory,
    String? topic,
  }) async {
    try {
      final apiKey = ApiConfig.getGeminiApiKey();
      if (apiKey == null || apiKey.isEmpty) {
        return _getOfflineConversationResponse(userMessage);
      }

      // 会話履歴を構築
      String history = '';
      for (final message in conversationHistory.take(10)) { // 最新10件のみ
        if (!message.isError) {
          history += '${message.isUser ? "User" : "AI"}: ${message.text}\n';
        }
      }

      // 会話の進行度を計算（ユーザーメッセージの数）
      int userMessageCount = conversationHistory.where((m) => m.isUser).length + 1;
      
      final prompt = '''
You are Aco, a friendly squirrel who helps Japanese learners practice English conversation.
Your personality: Warm, encouraging, curious, and conversational like a real friend.

Current conversation round: $userMessageCount out of 5 (this is a 5-exchange practice session)

CRITICAL: READ AND UNDERSTAND THE USER'S MESSAGE FIRST!
User said: "$userMessage"

LANGUAGE DETECTION:
- If the user wrote in Japanese, first show them how to say it in English
- Then respond naturally to their message content

ANALYZE CAREFULLY:
1. Language used: Japanese or English?
2. Main topic/event: What are they talking about?
3. Key details: What specific information did they share?
4. Emotion/tone: How do they feel about it?
5. Natural follow-up: What would a friend naturally ask next?

Conversation History:
$history

RESPONSE REQUIREMENTS:
${_detectLanguage(userMessage) == 'ja' ? '''
1. START with: "In English, you could say: '[natural English translation]'"
2. Then acknowledge what they said and respond naturally
''' : '''
1. START by acknowledging what they said (show you understood)
'''}
2. React genuinely (express emotion, relate to their experience)
3. Ask ONE specific follow-up question about their topic
4. Keep it conversational and natural
5. AVOID generic responses - be specific to their message

Round $userMessageCount/5 Strategy:
${userMessageCount <= 2 ? 'Build connection, show interest in their life' : 
  userMessageCount <= 4 ? 'Share your perspective, deepen the topic' :
  'Start wrapping up, express enjoyment'}

FORMAT YOUR RESPONSE:
- First: Complete English response (simple, natural, A2-B1 level)
- Then: COMPLETE Japanese translation (not summary) after double line break
- The Japanese translation must convey the EXACT same meaning as the English

IMPORTANT:
- ALWAYS relate your response to what they JUST said
- Use natural conversational English (contractions, casual phrases)
- Provide COMPLETE Japanese translation, not a summary
- Make each response unique and specific to their message

Respond in JSON format:
{
  "reply": "Your natural response with complete Japanese translation",
  "corrections": ["Only major grammar corrections with explanations in Japanese"],
  "suggestions": ["Natural follow-up 1", "Natural follow-up 2", "Natural follow-up 3"]
}
''';

      final response = await http.post(
        Uri.parse('$_baseUrl?key=$apiKey'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'contents': [{
            'parts': [{'text': prompt}]
          }],
          'generationConfig': {
            'temperature': 0.8,
            'maxOutputTokens': 1000,
          },
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
          
          return ConversationResponse(
            reply: content['reply'] ?? 'I understand. Could you tell me more?',
            corrections: content['corrections'] != null 
                ? List<String>.from(content['corrections'])
                : [],
            suggestions: content['suggestions'] != null
                ? List<String>.from(content['suggestions'])
                : [],
          );
        }
      }
    } catch (e) {
      print('Conversation generation error: $e');
      if (e.toString().contains('XMLHttpRequest')) {
        print('Note: CORS error detected. This is expected in web development mode.');
      }
    }
    
    return _getOfflineConversationResponse(userMessage);
  }
  
  // オフライン会話レスポンス
  static ConversationResponse _getOfflineConversationResponse(String userMessage) {
    // シンプルなフォールバックレスポンス
    return ConversationResponse(
      reply: "I understand what you're saying! That's really interesting. Could you tell me more about it?\n\nあなたの言っていることがわかります！それは本当に興味深いですね。もっと詳しく教えていただけますか？",
      corrections: [],
      suggestions: [
        "Actually, what I meant was...",
        "Let me explain more...",
        "The interesting part is...",
      ],
    );
  }
  
  // オフラインレスポンス（AI利用制限時）
  static Map<String, dynamic> _getOfflineResponse(String content) {
    final detectedLang = _detectLanguage(content);
    
    return {
      'detected_language': detectedLang,
      'original': content,
      'corrected': content,
      'translation': '',
      'improvements': ['本日のAI利用枠を使い切りました。明日また利用可能になります。'],
      'learned_phrases': [],
      'rate_limited': true,
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
  
  static Future<Map<String, dynamic>> analyzeConversation({
    required String conversationText,
    required List<ConversationMessage> messages,
  }) async {
    try {
      final apiKey = ApiConfig.getGeminiApiKey();
      if (apiKey == null || apiKey.isEmpty) {
        return _getOfflineAnalysis(messages);
      }

      final prompt = '''
Analyze the conversation and provide a summary in ENGLISH (not Japanese):

Conversation content:
$conversationText

Please respond in the following JSON format:
{
  "summary": "A 2-3 sentence summary IN ENGLISH describing what was discussed and what the learner practiced",
  "keyPhrases": ["Up to 5 important phrases or expressions used in the conversation"],
  "newWords": ["Up to 5 new or difficult words the learner used"],
  "corrections": ["Up to 3 constructive grammar corrections or language improvement suggestions IN JAPANESE"]
}

Note:
- Write the summary from the learner's perspective in English
- Extract actual English phrases used in the conversation
- Write corrections and learning points in Japanese for better understanding
- Make corrections specific and constructive''';

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
            'temperature': 0.7,
            'topK': 40,
            'topP': 0.95,
            'maxOutputTokens': 1024,
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
          
          final text = data['candidates'][0]['content']['parts'][0]['text'];
          final analysis = jsonDecode(text);
          
          return {
            'summary': analysis['summary'] ?? '',
            'keyPhrases': List<String>.from(analysis['keyPhrases'] ?? []),
            'newWords': List<String>.from(analysis['newWords'] ?? []),
            'corrections': List<String>.from(analysis['corrections'] ?? []),
          };
        }
      }
      
      return _getOfflineAnalysis(messages);
    } catch (e) {
      print('Error analyzing conversation: $e');
      return _getOfflineAnalysis(messages);
    }
  }
  
  static Map<String, dynamic> _getOfflineAnalysis(List<ConversationMessage> messages) {
    // オフライン時の簡単な分析
    final userMessages = messages.where((m) => m.isUser).toList();
    final totalWords = userMessages.fold(0, (sum, msg) => sum + msg.text.split(' ').length);
    
    // Extract simple key phrases from user messages
    final keyPhrases = <String>[];
    for (final msg in userMessages.take(3)) {
      final sentences = msg.text.split(RegExp(r'[.!?]'));
      if (sentences.isNotEmpty && sentences.first.trim().isNotEmpty) {
        keyPhrases.add(sentences.first.trim());
      }
    }
    
    return {
      'summary': 'In this conversation, we exchanged ${messages.length} messages and practiced English using approximately $totalWords words. The conversation covered various topics and helped improve English communication skills.',
      'keyPhrases': keyPhrases,
      'newWords': [],
      'corrections': ['Detailed analysis is not available in offline mode.'],
    };
  }
}