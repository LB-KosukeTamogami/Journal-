import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/diary_entry.dart';
import '../models/conversation_message.dart';
import '../config/api_config.dart';
import 'word_cache_service.dart';

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
  
  // 日本語WordNet APIから単語の意味と品詞を取得（キャッシュ機能付き）
  static Future<Map<String, dynamic>?> getWordDefinition(String word) async {
    try {
      // まずキャッシュを確認
      final cached = await _getCachedWordDefinition(word);
      if (cached != null) {
        return cached;
      }

      // キャッシュになければAPIから取得
      final url = Uri.parse('https://juman-drc.org/wordnet/jp/api/1.1/definitions');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {'word': word.toLowerCase()},
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is List && data.isNotEmpty) {
          // 最初の定義を取得
          final definition = data[0];
          if (definition['definitions'] != null && definition['definitions'].isNotEmpty) {
            final firstDef = definition['definitions'][0];
            final result = {
              'meaning': firstDef['definition'] ?? '',
              'partOfSpeech': firstDef['pos'] ?? firstDef['part_of_speech'] ?? 'unknown',
              'word': definition['word'] ?? word,
            };
            
            // キャッシュに保存
            await _cacheWordDefinition(word, result);
            
            return result;
          }
        }
      }
      
      return null;
    } catch (e) {
      print('Error fetching word definition: $e');
      return null;
    }
  }

  // キャッシュから単語定義を取得
  static Future<Map<String, dynamic>?> _getCachedWordDefinition(String word) async {
    final cached = await WordCacheService.fetchCachedWord(word);
    if (cached != null) {
      return {
        'meaning': cached['definition'] ?? '',
        'partOfSpeech': 'unknown', // キャッシュには品詞情報がない
        'word': cached['ja_word'] ?? word,
      };
    }
    return null;
  }

  // 単語定義をキャッシュに保存
  static Future<void> _cacheWordDefinition(String word, Map<String, dynamic> definition) async {
    await WordCacheService.cacheWordTranslation(
      jaWord: word,
      enWord: definition['word'] ?? word, // 英訳がない場合は元の単語を使用
      definition: definition['meaning'],
      source: 'wordnet',
    );
  }

  // 後方互換性のため既存メソッドを保持
  static Future<String?> getWordMeaning(String word) async {
    final definition = await getWordDefinition(word);
    return definition?['meaning'];
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

ANALYZE THE USER'S MESSAGE:
1. Language used: Japanese or English?
2. Main topic/event: What are they talking about?
3. Key details: What specific information did they share?
4. Emotion/tone: How do they feel about it?
5. Natural follow-up: What would a friend naturally ask next?

Conversation History:
$history

RESPONSE REQUIREMENTS:
- Keep responses SHORT and concise (about half the usual length)
- Be conversational and natural - talk like a real friend would
- Show genuine interest in what they're sharing
- Use varied expressions and reactions
- Ask meaningful follow-up questions (except for round 5)
- Round 5: Only give a brief acknowledgment/reaction, NO questions

RESPONSE FORMAT (ALWAYS follow this structure):
If the user wrote in Japanese:
1. Brief reaction in English (e.g., "Oh, that's interesting!" / "Wow, really?" / "That sounds fun!")
2. "In English, you could say: '[natural English translation of their Japanese]'"
3. SHORT English response addressing their topic + follow-up question (unless round 5)
4. COMPLETE Japanese translation of your entire English response (REQUIRED for all responses)

If the user wrote in English:
1. Natural reaction and acknowledgment of what they said (SHORT)
2. SHORT English response + follow-up question (unless round 5)
3. COMPLETE Japanese translation of your entire English response (REQUIRED for all responses)

CRITICAL RULES:
- ALWAYS include complete Japanese translation separated by \n\n
- Keep English responses brief and to the point
- Round 5: Just acknowledge what they said, NO additional questions
- React specifically to what they shared (not generic responses)
- Ensure Japanese translation is COMPLETE and natural

Round $userMessageCount/5 Strategy:
${userMessageCount == 1 ? 'Start friendly, ask about their day or interests' : 
  userMessageCount == 2 ? 'Build on their response, show genuine interest' :
  userMessageCount == 3 ? 'Deepen the conversation, maybe share your own experience' :
  userMessageCount == 4 ? 'Keep the momentum going, explore details' :
  'Give brief acknowledgment only, NO questions, prepare for conversation wrap-up'}

VARIED REACTION EXAMPLES:
- "Oh wow, that's amazing!"
- "Really? Tell me more!"
- "That sounds challenging..."
- "I've always wanted to try that!"
- "How interesting!"
- "That must have been exciting!"

EXAMPLE RESPONSES:

If user says "昨日、友達と映画を見ました" (Yesterday, I watched a movie with friends):
"Oh, that sounds fun! In English, you could say: 'I watched a movie with my friends yesterday.'

Movie nights with friends are great! What movie did you watch?

友達との映画鑑賞は素晴らしいですね！何の映画を見ましたか？"

If user says "I like cooking Italian food":
"That's wonderful! What's your favorite Italian dish to make?

素晴らしいですね！作るのが好きなイタリア料理は何ですか？"

Round 5 example - user says "It was really delicious!":
"That sounds amazing! I'm so glad you enjoyed it. Thanks for sharing your experience with me!

本当に美味しそうですね！楽しんでいただけて嬉しいです。体験を共有してくれてありがとう！"

Respond in JSON format:
{
  "reply": "Your complete response following the format above",
  "corrections": ["英文作成のアドバイス（もしあれば）"],
  "suggestions": ["Natural follow-up response 1", "Natural follow-up response 2", "Natural follow-up response 3"]
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
            'temperature': 0.9,
            'topK': 40,
            'topP': 0.95,
            'maxOutputTokens': 1200,
            'responseMimeType': 'application/json',
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
  "keyPhrases": [],
  "newWords": ["Up to 5 new or difficult ENGLISH single words only (no phrases, exclude Japanese)"],
  "corrections": ["Up to 3 specific ENGLISH WRITING TIPS in Japanese (focus on grammar, word choice, sentence structure)"]
}

Note:
- Write the summary from the learner's perspective in English
- Extract ONLY English single words (no multi-word phrases or expressions)
- Words should be individual vocabulary items like "beautiful", "understand", "important"
- Do NOT include phrases like "thank you", "good morning", or any multi-word expressions
- For corrections, provide specific advice about English writing (e.g., "過去形を使う時は動詞にedを付けます", "aとtheの使い分けに注意しましょう")
- Do NOT include general conversation feedback, focus on English language learning''';

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

  // 日記の翻訳・添削機能
  static Future<Map<String, dynamic>> correctAndTranslate(String content, {String targetLanguage = 'en'}) async {
    try {
      final apiKey = ApiConfig.getGeminiApiKey();
      if (apiKey == null || apiKey.isEmpty) {
        throw Exception('Gemini API key not found');
      }

      const apiUrl = 'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash-exp:generateContent';
      
      final prompt = '''
あなたは英語教師です。以下の文が日本語であれば英訳してください。
英語であれば文法・語法をチェックし、必要であれば添削してください。

【入力文】
$content

【出力形式】
以下のJSON形式で出力してください：
{
  "judgment": "日本語翻訳" または "英文（正しい）" または "英文（添削必要）",
  "detected_language": "ja" または "en",
  "output_text": "翻訳結果 または 添削済み英文 または 入力文そのまま",
  "original_text": "入力文（変更なし）",
  "corrections": ["添削コメント1", "添削コメント2", ...],
  "improvements": ["改善点1", "改善点2", ...],
  "learned_words": [
    {"english": "word1", "japanese": "単語1の意味"},
    {"english": "word2", "japanese": "単語2の意味"}
  ]
}

注意事項：
- 日本語の場合は自然な英訳を提供
- 英語で正しい場合は、corrections配列は空
- 英語で添削が必要な場合は、具体的な改善点を含める
- learned_wordsには重要な単語（単一の単語のみ）を英語と日本語のペアで含める
- フレーズや熟語は含めない、単語のみ抽出
''';

      final requestBody = {
        "contents": [{
          "parts": [{
            "text": prompt
          }]
        }],
        "generationConfig": {
          "temperature": 0.3,
          "topK": 40,
          "topP": 0.95,
          "maxOutputTokens": 2048,
          "responseMimeType": "application/json",
        },
        "safetySettings": [
          {
            "category": "HARM_CATEGORY_HARASSMENT",
            "threshold": "BLOCK_MEDIUM_AND_ABOVE"
          },
          {
            "category": "HARM_CATEGORY_HATE_SPEECH",
            "threshold": "BLOCK_MEDIUM_AND_ABOVE"
          },
          {
            "category": "HARM_CATEGORY_SEXUALLY_EXPLICIT",
            "threshold": "BLOCK_MEDIUM_AND_ABOVE"
          },
          {
            "category": "HARM_CATEGORY_DANGEROUS_CONTENT",
            "threshold": "BLOCK_MEDIUM_AND_ABOVE"
          }
        ]
      };

      print('[GeminiService] Sending request to Gemini API...');
      final response = await http.post(
        Uri.parse('$apiUrl?key=$apiKey'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      );

      print('[GeminiService] Response status: ${response.statusCode}');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['candidates'] != null && 
            data['candidates'].isNotEmpty &&
            data['candidates'][0]['content'] != null &&
            data['candidates'][0]['content']['parts'] != null &&
            data['candidates'][0]['content']['parts'].isNotEmpty) {
          
          final text = data['candidates'][0]['content']['parts'][0]['text'];
          print('[GeminiService] Raw response text: $text');
          
          // JSONを抽出（マークダウンコードブロックなどを除去）
          String jsonText = text.trim();
          if (jsonText.contains('```json')) {
            jsonText = jsonText.split('```json')[1].split('```')[0].trim();
          } else if (jsonText.contains('```')) {
            jsonText = jsonText.split('```')[1].split('```')[0].trim();
          }
          
          Map<String, dynamic> result;
          try {
            result = jsonDecode(jsonText);
          } catch (jsonError) {
            print('[GeminiService] JSON parse error: $jsonError');
            print('[GeminiService] JSON text: $jsonText');
            throw Exception('Failed to parse JSON response');
          }
          
          // 判定に基づいて結果を整形
          final judgment = result['judgment'] ?? '';
          final outputText = result['output_text'] ?? content;
          
          // learned_wordsを処理
          final learnedWords = <Map<String, String>>[];
          if (result['learned_words'] != null) {
            for (final word in result['learned_words']) {
              if (word is Map && word['english'] != null && word['japanese'] != null) {
                learnedWords.add({
                  'english': word['english'].toString(),
                  'japanese': word['japanese'].toString(),
                });
              }
            }
          }
          
          return {
            'judgment': judgment,
            'detected_language': result['detected_language'] ?? 'en',
            'corrected': outputText,
            'translation': judgment == '日本語翻訳' ? outputText : '',
            'original': content,
            'corrections': List<String>.from(result['corrections'] ?? []),
            'improvements': List<String>.from(result['improvements'] ?? []),
            'learned_words': learnedWords,
            'learned_phrases': [], // 後方互換性のため空配列を保持
          };
        }
      } else {
        print('[GeminiService] API Error Response: ${response.body}');
      }
      
      throw Exception('Failed to get response from Gemini API: ${response.statusCode}');
    } catch (e) {
      print('[GeminiService] Error in correctAndTranslate: $e');
      
      // エラーの種類に応じてより詳細な情報を提供
      String errorMessage = 'エラーが発生しました';
      if (e.toString().contains('API key not found')) {
        errorMessage = 'API設定エラー';
      } else if (e.toString().contains('Failed to parse JSON')) {
        errorMessage = 'レスポンス解析エラー';
      } else if (e.toString().contains('XMLHttpRequest')) {
        errorMessage = 'ネットワークエラー';
      } else if (e.toString().contains('403') || e.toString().contains('401')) {
        errorMessage = 'API認証エラー';
      } else if (e.toString().contains('429')) {
        errorMessage = 'API利用制限に達しました';
      }
      
      // エラー時は入力をそのまま返す
      return {
        'judgment': errorMessage,
        'detected_language': _detectLanguage(content),
        'corrected': content,
        'translation': '',
        'original': content,
        'corrections': [],
        'improvements': [],
        'learned_words': [],
        'learned_phrases': [], // 後方互換性のため
      };
    }
  }

  static String _detectLanguage(String text) {
    // 簡易的な言語検出
    final japanesePattern = RegExp(r'[\u3040-\u309F\u30A0-\u30FF\u4E00-\u9FAF]');
    return japanesePattern.hasMatch(text) ? 'ja' : 'en';
  }
}