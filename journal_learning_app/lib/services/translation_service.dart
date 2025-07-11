import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/word.dart';

class TranslationService {
  // 簡易的な翻訳マッピング（オフライン用）
  static const Map<String, String> _simpleTranslations = {
    // フレーズ（長いものから先に定義）
    'go to school': '学校に行く',
    'go to work': '仕事に行く',
    'go home': '家に帰る',
    'go to': '〜に行く',
    'nice to meet you': 'はじめまして',
    'what is your name': 'お名前は何ですか',
    'how are you': '元気ですか',
    'i am fine': '元気です',
    'my name is': '私の名前は',
    'good morning': 'おはようございます',
    'good evening': 'こんばんは',
    'thank you': 'ありがとう',
    'i love you': '愛しています',
    'i like': '好きです',
    'i went to': '行きました',
    'i had': '食べました',
    'it was': 'でした',
    'very good': 'とても良い',
    'very interesting': 'とても面白い',
    'very delicious': 'とても美味しい',
    
    // 基本的な単語
    'i': '私',
    'you': 'あなた',
    'he': '彼',
    'she': '彼女',
    'it': 'それ',
    'we': '私たち',
    'they': '彼ら',
    'this': 'これ',
    'that': 'あれ',
    'hello': 'こんにちは',
    'goodbye': 'さようなら',
    'please': 'お願いします',
    'yes': 'はい',
    'no': 'いいえ',
    'excuse me': 'すみません',
    'sorry': 'ごめんなさい',
    'was': 'でした',
    'very': 'とても',
    'day': '日',
    'go': '行く',
    'to': '〜へ',
    
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
    '私は': 'i',
    '行きました': 'went',
    '食べました': 'ate',
    'でした': 'was',
    'とても': 'very',
    '好きです': 'like',
    '愛しています': 'love',
    'とても良い': 'very good',
    'とても面白い': 'very interesting',
    'とても美味しい': 'very delicious',
    '学校に行く': 'go to school',
    '仕事に行く': 'go to work',
    '家に帰る': 'go home',
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
    'たのしい': 'enjoyable',
    'おいしい': 'delicious',
    'おもしろい': 'interesting',
    'レストラン': 'restaurant',
    'カフェ': 'cafe',
    '映画': 'movie',
    '本': 'book',
    '音楽': 'music',
    'スポーツ': 'sports',
    '旅行': 'travel',
    '料理': 'cooking',
    'ゲーム': 'game',
    'テレビ': 'television',
    'ニュース': 'news',
    '天気': 'weather',
    '雨': 'rain',
    '雪': 'snow',
    '日本': 'japan',
    'アメリカ': 'america',
    '中国': 'china',
    '韓国': 'korea',
    'イギリス': 'england',
    'フランス': 'france',
    'ドイツ': 'germany',
    'イタリア': 'italy',
    'スペイン': 'spain',
    'ロシア': 'russia',
    'インド': 'india',
    'ブラジル': 'brazil',
    'オーストラリア': 'australia',
    'カナダ': 'canada',
    '男の人': 'man',
    '女の人': 'woman',
    '子供': 'child',
    '赤ちゃん': 'baby',
    'おじいさん': 'grandfather',
    'おばあさん': 'grandmother',
    'お父さん': 'father',
    'お母さん': 'mother',
    'お兄さん': 'older brother',
    'お姉さん': 'older sister',
    '弟': 'younger brother',
    '妹': 'younger sister',
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

  /// オフライン翻訳（改善された実装）
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

    // 言語によって異なる翻訳戦略を使用
    if (targetLanguage == 'ja') {
      return _translateToJapanese(text, lowerText);
    } else {
      return _translateToEnglish(text, lowerText);
    }
  }

  /// 英語から日本語への流暢な翻訳
  static TranslationResult _translateToJapanese(String originalText, String lowerText) {
    // 文の構造を分析して流暢な日本語に翻訳
    String translatedText = _analyzeAndTranslateToJapanese(lowerText);
    
    if (translatedText != lowerText) {
      return TranslationResult(
        originalText: originalText,
        translatedText: translatedText,
        targetLanguage: 'ja',
        success: true,
      );
    }

    // フォールバック: 単語レベルの翻訳
    return _wordLevelTranslation(originalText, lowerText, 'ja');
  }

  /// 日本語から英語への翻訳
  static TranslationResult _translateToEnglish(String originalText, String lowerText) {
    // 単語レベルの翻訳（英語はそのまま）
    return _wordLevelTranslation(originalText, lowerText, 'en');
  }

  /// 英語文を自然な日本語に翻訳
  static String _analyzeAndTranslateToJapanese(String text) {
    // 複数の文がある場合は文ごとに分割して処理
    if (text.contains('.') || text.contains('!') || text.contains('?')) {
      return _translateLongText(text);
    }
    
    // パターンマッチングで一般的な英語表現を自然な日本語に変換
    
    // I go to [場所] パターン（現在形）
    if (text.contains('i go to')) {
      final match = RegExp(r'i go to (?:my\s+)?([\w\s]+?)(?:\s+yesterday|\s+today|\s+tomorrow)?').firstMatch(text);
      if (match != null) {
        final place = match.group(1)!.trim();
        final placeTranslation = _simpleTranslations[place] ?? place;
        
        // 時制を確認
        if (text.contains('yesterday')) {
          return '昨日${placeTranslation}に行きました';
        } else if (text.contains('tomorrow')) {
          return '明日${placeTranslation}に行きます';
        } else if (text.contains('today')) {
          return '今日${placeTranslation}に行きます';
        } else {
          return '${placeTranslation}に行きます';
        }
      }
    }
    
    // I went to [場所] パターン（過去形）
    if (text.contains('i went to')) {
      final match = RegExp(r'i went to (?:my\s+)?([\w\s]+)').firstMatch(text);
      if (match != null) {
        final place = match.group(1)!.trim();
        final placeTranslation = _simpleTranslations[place] ?? place;
        return '${placeTranslation}に行きました';
      }
    }
    
    // I had [食べ物] パターン
    if (text.contains('i had')) {
      final match = RegExp(r'i had ([\w\s]+)').firstMatch(text);
      if (match != null) {
        final food = match.group(1)!.trim();
        final foodTranslation = _simpleTranslations[food] ?? food;
        return '${foodTranslation}を食べました';
      }
    }
    
    // It is/was [形容詞] パターン
    if (text.contains('it is') || text.contains('it was')) {
      final match = RegExp(r'it (?:is|was) ([\w\s]+)').firstMatch(text);
      if (match != null) {
        final adjective = match.group(1)!.trim();
        
        // "very fun" のような表現を特別に処理
        if (adjective == 'very fun') {
          return text.contains('it was') ? 'とても楽しかったです' : 'とても楽しいです';
        }
        
        final adjectiveTranslation = _simpleTranslations[adjective] ?? adjective;
        return text.contains('it was') 
            ? '${adjectiveTranslation}でした' 
            : '${adjectiveTranslation}です';
      }
    }
    
    // I like [対象] パターン
    if (text.contains('i like')) {
      final match = RegExp(r'i like ([\w\s]+)').firstMatch(text);
      if (match != null) {
        final object = match.group(1)!.trim();
        final objectTranslation = _simpleTranslations[object] ?? object;
        return '${objectTranslation}が好きです';
      }
    }
    
    // Very [形容詞] パターン（単独）
    if (text.contains('very')) {
      final match = RegExp(r'very ([\w\s]+)').firstMatch(text);
      if (match != null) {
        final adjective = match.group(1)!.trim();
        final adjectiveTranslation = _simpleTranslations[adjective] ?? adjective;
        return 'とても${adjectiveTranslation}';
      }
    }
    
    // Today I [動詞] パターン
    if (text.startsWith('today i')) {
      final match = RegExp(r'today i ([\w\s]+)').firstMatch(text);
      if (match != null) {
        final verb = match.group(1)!.trim();
        final verbTranslation = _simpleTranslations[verb] ?? verb;
        return '今日は${verbTranslation}';
      }
    }
    
    return text; // 変換できない場合は元のテキストを返す
  }
  
  /// 長いテキストを文ごとに分割して翻訳
  static String _translateLongText(String text) {
    // 文を区切り文字で分割（区切り文字も保持）
    final sentencePattern = RegExp(r'([^.!?]+[.!?])');
    final matches = sentencePattern.allMatches(text);
    
    if (matches.isEmpty) {
      // 区切り文字がない場合は全体を1文として処理
      return _translateSingleSentence(text);
    }
    
    final translatedSentences = <String>[];
    
    for (final match in matches) {
      final sentence = match.group(1)!;
      final trimmedSentence = sentence.trim().toLowerCase();
      
      // 文末の記号を取得
      final punctuation = trimmedSentence.endsWith('!') ? '！' 
                        : trimmedSentence.endsWith('?') ? '？' 
                        : '。';
      
      // 記号を除いた文を翻訳
      final sentenceWithoutPunct = trimmedSentence.replaceAll(RegExp(r'[.!?]\s*$'), '').trim();
      
      if (sentenceWithoutPunct.isEmpty) continue;
      
      // 文ごとに翻訳を試みる
      final translated = _translateSingleSentence(sentenceWithoutPunct);
      
      if (translated != sentenceWithoutPunct) {
        // 成功した翻訳に適切な句読点を追加
        translatedSentences.add(translated + punctuation);
      } else {
        // パターンマッチしない場合は単語レベルで翻訳
        final wordTranslated = _translateWordsInSentence(sentenceWithoutPunct);
        translatedSentences.add(wordTranslated + punctuation);
      }
    }
    
    return translatedSentences.join('');
  }
  
  /// 単一の文を翻訳（再帰呼び出しを防ぐ）
  static String _translateSingleSentence(String text) {
    // パターンマッチングで一般的な英語表現を自然な日本語に変換
    
    // I go to [場所] パターン（現在形）
    if (text.contains('i go to')) {
      final match = RegExp(r'i go to (?:my\s+)?([\w\s]+?)(?:\s+yesterday|\s+today|\s+tomorrow)?').firstMatch(text);
      if (match != null) {
        final place = match.group(1)!.trim();
        final placeTranslation = _simpleTranslations[place] ?? place;
        
        // 時制を確認
        if (text.contains('yesterday')) {
          return '昨日${placeTranslation}に行きました';
        } else if (text.contains('tomorrow')) {
          return '明日${placeTranslation}に行きます';
        } else if (text.contains('today')) {
          return '今日${placeTranslation}に行きます';
        } else {
          return '${placeTranslation}に行きます';
        }
      }
    }
    
    // I went to [場所] パターン（過去形）
    if (text.contains('i went to')) {
      final match = RegExp(r'i went to (?:my\s+)?([\w\s]+)').firstMatch(text);
      if (match != null) {
        final place = match.group(1)!.trim();
        final placeTranslation = _simpleTranslations[place] ?? place;
        return '${placeTranslation}に行きました';
      }
    }
    
    // I had [食べ物] パターン
    if (text.contains('i had')) {
      final match = RegExp(r'i had ([\w\s]+)').firstMatch(text);
      if (match != null) {
        final food = match.group(1)!.trim();
        final foodTranslation = _simpleTranslations[food] ?? food;
        return '${foodTranslation}を食べました';
      }
    }
    
    // It is/was [形容詞] パターン
    if (text.contains('it is') || text.contains('it was')) {
      final match = RegExp(r'it (?:is|was) ([\w\s]+)').firstMatch(text);
      if (match != null) {
        final adjective = match.group(1)!.trim();
        
        // "very fun" のような表現を特別に処理
        if (adjective == 'very fun') {
          return text.contains('it was') ? 'とても楽しかったです' : 'とても楽しいです';
        }
        
        final adjectiveTranslation = _simpleTranslations[adjective] ?? adjective;
        return text.contains('it was') 
            ? '${adjectiveTranslation}でした' 
            : '${adjectiveTranslation}です';
      }
    }
    
    // I like [対象] パターン
    if (text.contains('i like')) {
      final match = RegExp(r'i like ([\w\s]+)').firstMatch(text);
      if (match != null) {
        final object = match.group(1)!.trim();
        final objectTranslation = _simpleTranslations[object] ?? object;
        return '${objectTranslation}が好きです';
      }
    }
    
    // Very [形容詞] パターン（単独）
    if (text.contains('very')) {
      final match = RegExp(r'very ([\w\s]+)').firstMatch(text);
      if (match != null) {
        final adjective = match.group(1)!.trim();
        final adjectiveTranslation = _simpleTranslations[adjective] ?? adjective;
        return 'とても${adjectiveTranslation}';
      }
    }
    
    // Today I [動詞] パターン
    if (text.startsWith('today i')) {
      final match = RegExp(r'today i ([\w\s]+)').firstMatch(text);
      if (match != null) {
        final verb = match.group(1)!.trim();
        final verbTranslation = _simpleTranslations[verb] ?? verb;
        return '今日は${verbTranslation}';
      }
    }
    
    return text; // 変換できない場合は元のテキストを返す
  }
  
  /// 文中の単語を翻訳
  static String _translateWordsInSentence(String sentence) {
    final words = sentence.split(' ');
    final translatedWords = <String>[];
    
    for (final word in words) {
      final cleanWord = word.replaceAll(RegExp(r'[^\w]'), '').toLowerCase();
      final translation = _simpleTranslations[cleanWord];
      if (translation != null) {
        translatedWords.add(translation);
      } else if (cleanWord.isNotEmpty) {
        translatedWords.add(cleanWord);
      }
    }
    
    return translatedWords.join(' ');
  }

  /// 単語レベルの翻訳（フォールバック）
  static TranslationResult _wordLevelTranslation(String originalText, String lowerText, String targetLanguage) {
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
      String result = translatedWords.join(' ');
      // 日本語の場合はスペースを削除
      if (targetLanguage == 'ja') {
        result = result.replaceAll(' ', '');
      }
      
      return TranslationResult(
        originalText: originalText,
        translatedText: result,
        targetLanguage: targetLanguage,
        success: true,
        isPartialTranslation: true,
      );
    }

    // 翻訳できない場合
    return TranslationResult(
      originalText: originalText,
      translatedText: originalText,
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
  
  /// 正規表現の特殊文字をエスケープ
  static String _escapeRegExp(String str) {
    return str.replaceAllMapped(RegExp(r'[.*+?^${}()|[\]\\]'), (match) => '\\${match.group(0)}');
  }
  
  /// フレーズと単語を認識して位置情報とともに返す
  static List<PhraseInfo> detectPhrasesAndWords(String text) {
    final result = <PhraseInfo>[];
    final lowerText = text.toLowerCase();
    final processedIndices = <int>{};
    
    // フレーズから検索（長いものから）
    final sortedPhrases = _simpleTranslations.keys.where((key) => key.contains(' ')).toList()
      ..sort((a, b) => b.split(' ').length.compareTo(a.split(' ').length));
    
    for (final phrase in sortedPhrases) {
      // 単語境界を考慮した正規表現パターンを作成
      final pattern = RegExp('\\b${_escapeRegExp(phrase)}\\b');
      final matches = pattern.allMatches(lowerText);
      
      for (final match in matches) {
        final start = match.start;
        final end = match.end;
        
        // すでに処理済みの位置でないかチェック
        bool isOverlapping = false;
        for (int i = start; i < end; i++) {
          if (processedIndices.contains(i)) {
            isOverlapping = true;
            break;
          }
        }
        
        if (!isOverlapping) {
          result.add(PhraseInfo(
            text: text.substring(start, end),
            translation: _simpleTranslations[phrase] ?? '',
            startIndex: start,
            endIndex: end,
            isPhrase: true,
          ));
          
          // 処理済みとしてマーク
          for (int i = start; i < end; i++) {
            processedIndices.add(i);
          }
        }
      }
    }
    
    // 単語境界で分割（記号や空白を保持）
    final wordPattern = RegExp(r'(\b\w+\b|\W+)');
    final matches = wordPattern.allMatches(text);
    
    for (final match in matches) {
      final word = match.group(0)!;
      final start = match.start;
      final end = match.end;
      
      // すでに処理済みの位置かチェック
      bool isProcessed = false;
      for (int i = start; i < end; i++) {
        if (processedIndices.contains(i)) {
          isProcessed = true;
          break;
        }
      }
      
      if (!isProcessed) {
        final cleanWord = word.replaceAll(RegExp(r'[^\w]'), '');
        if (cleanWord.isNotEmpty) {
          final translation = _simpleTranslations[cleanWord.toLowerCase()];
          
          result.add(PhraseInfo(
            text: word,
            translation: translation ?? '',
            startIndex: start,
            endIndex: end,
            isPhrase: false,
          ));
        } else {
          // 記号やスペースもそのまま追加
          result.add(PhraseInfo(
            text: word,
            translation: '',
            startIndex: start,
            endIndex: end,
            isPhrase: false,
          ));
        }
      }
    }
    
    // 開始位置でソート
    result.sort((a, b) => a.startIndex.compareTo(b.startIndex));
    
    return result;
  }

  /// 言語を自動検出（簡易的）
  static String detectLanguage(String text) {
    // 日本語文字（ひらがな、カタカナ、漢字）が含まれているかチェック
    final japanesePattern = RegExp(r'[\u3040-\u309F\u30A0-\u30FF\u4E00-\u9FAF]');
    
    // 英文字のパターン
    final englishPattern = RegExp(r'[a-zA-Z]');
    
    bool hasJapanese = japanesePattern.hasMatch(text);
    bool hasEnglish = englishPattern.hasMatch(text);
    
    if (hasJapanese && hasEnglish) {
      // 日英混在の場合は「mixed」を返す
      return 'mixed';
    } else if (hasJapanese) {
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

class PhraseInfo {
  final String text;
  final String translation;
  final int startIndex;
  final int endIndex;
  final bool isPhrase;

  PhraseInfo({
    required this.text,
    required this.translation,
    required this.startIndex,
    required this.endIndex,
    required this.isPhrase,
  });
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
  
  // 単語のカテゴリを推測する関数
  static WordCategory inferWordCategory(String english) {
    final word = english.toLowerCase().trim();
    
    // 複数の単語（フレーズ）の場合
    if (word.contains(' ')) {
      return WordCategory.phrase;
    }
    
    // 動詞のパターン
    final verbPatterns = [
      'go', 'went', 'gone',
      'do', 'did', 'done',
      'make', 'made',
      'take', 'took', 'taken',
      'get', 'got', 'gotten',
      'come', 'came',
      'see', 'saw', 'seen',
      'know', 'knew', 'known',
      'think', 'thought',
      'look', 'looked',
      'want', 'wanted',
      'give', 'gave', 'given',
      'use', 'used',
      'find', 'found',
      'tell', 'told',
      'ask', 'asked',
      'work', 'worked',
      'seem', 'seemed',
      'feel', 'felt',
      'leave', 'left',
      'call', 'called',
      'eat', 'ate', 'eaten',
      'drink', 'drank', 'drunk',
      'sleep', 'slept',
      'walk', 'walked',
      'run', 'ran',
      'write', 'wrote', 'written',
      'read', 'read',
      'speak', 'spoke', 'spoken',
      'learn', 'learned', 'learnt',
      'study', 'studied',
      'play', 'played',
      'watch', 'watched',
      'listen', 'listened',
      'buy', 'bought',
      'sell', 'sold',
      'love', 'loved',
      'like', 'liked',
      'hate', 'hated',
      'try', 'tried',
      'help', 'helped',
      'need', 'needed',
      'start', 'started',
      'stop', 'stopped',
      'finish', 'finished',
      'begin', 'began', 'begun',
      'send', 'sent',
      'receive', 'received',
      'bring', 'brought',
      'meet', 'met',
      'sit', 'sat',
      'stand', 'stood',
      'live', 'lived',
      'die', 'died',
      'grow', 'grew', 'grown',
      'open', 'opened',
      'close', 'closed',
      'turn', 'turned',
      'move', 'moved',
      'happen', 'happened',
      'become', 'became',
      'change', 'changed',
      'hear', 'heard',
      'believe', 'believed',
      'understand', 'understood',
      'remember', 'remembered',
      'forget', 'forgot', 'forgotten'
    ];
    
    // 形容詞のパターン（語尾）
    final adjectiveEndings = ['-able', '-ible', '-al', '-ful', '-ic', '-ive', '-less', '-ous', '-y'];
    final commonAdjectives = [
      'good', 'bad', 'new', 'old', 'great', 'high', 'low', 'big', 'small', 
      'large', 'long', 'short', 'hot', 'cold', 'easy', 'hard', 'fast', 'slow',
      'happy', 'sad', 'angry', 'beautiful', 'ugly', 'rich', 'poor', 'young',
      'strong', 'weak', 'clean', 'dirty', 'simple', 'difficult', 'important',
      'interesting', 'boring', 'dangerous', 'safe', 'modern', 'ancient',
      'delicious', 'sweet', 'bitter', 'sour', 'spicy', 'bland',
      'fun', 'funny', 'serious', 'cool', 'warm', 'nice', 'mean',
      'smart', 'stupid', 'clever', 'wise', 'foolish'
    ];
    
    // 副詞のパターン（語尾）
    final adverbEndings = ['-ly'];
    final commonAdverbs = [
      'very', 'really', 'quite', 'too', 'so', 'just', 'only', 'even',
      'still', 'already', 'yet', 'often', 'sometimes', 'always', 'never',
      'here', 'there', 'now', 'then', 'today', 'tomorrow', 'yesterday',
      'soon', 'later', 'early', 'late', 'fast', 'slow', 'well', 'badly'
    ];
    
    // 動詞チェック
    if (verbPatterns.contains(word)) {
      return WordCategory.verb;
    }
    
    // 形容詞チェック
    if (commonAdjectives.contains(word) || 
        adjectiveEndings.any((ending) => word.endsWith(ending))) {
      return WordCategory.adjective;
    }
    
    // 副詞チェック
    if (commonAdverbs.contains(word) || 
        (word.endsWith('ly') && word.length > 3)) {
      return WordCategory.adverb;
    }
    
    // 代名詞、冠詞、前置詞などは名詞として扱わない
    final functionWords = [
      'i', 'you', 'he', 'she', 'it', 'we', 'they', 'me', 'him', 'her', 'us', 'them',
      'my', 'your', 'his', 'her', 'its', 'our', 'their',
      'this', 'that', 'these', 'those',
      'a', 'an', 'the',
      'in', 'on', 'at', 'to', 'from', 'with', 'by', 'for', 'of', 'about',
      'and', 'or', 'but', 'if', 'when', 'where', 'what', 'who', 'which', 'how',
      'is', 'am', 'are', 'was', 'were', 'be', 'been', 'being',
      'have', 'has', 'had', 'having',
      'do', 'does', 'did', 'doing',
      'will', 'would', 'shall', 'should', 'may', 'might', 'can', 'could', 'must'
    ];
    
    if (functionWords.contains(word)) {
      return WordCategory.other;
    }
    
    // それ以外は名詞として扱う
    return WordCategory.noun;
  }
}