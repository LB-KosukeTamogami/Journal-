import 'dart:convert';
import 'package:http/http.dart' as http;

class WordNetEntry {
  final String word;
  final String partOfSpeech;
  final List<String> definitions;
  final List<String> synonyms;
  final List<String> examples;

  WordNetEntry({
    required this.word,
    required this.partOfSpeech,
    required this.definitions,
    required this.synonyms,
    required this.examples,
  });
}

class JapaneseWordNetService {
  // 実際のAPIエンドポイントに置き換えてください
  static const String _baseUrl = 'https://api.example.com/wordnet/en';
  
  static Future<WordNetEntry?> lookupWord(String word) async {
    try {
      // 単語をクリーンアップ
      final cleanWord = word.trim().toLowerCase().replaceAll(RegExp(r'[^\w\s-]'), '');
      
      if (cleanWord.isEmpty) {
        return null;
      }

      // 開発用のモックデータを返す（実際のAPIが利用可能になったら削除）
      // 本番環境では以下のコメントアウトされたコードを使用
      /*
      final response = await http.get(
        Uri.parse('$_baseUrl/$cleanWord'),
        headers: {'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        return _parseWordNetResponse(data);
      }
      */
      
      // モックデータ（開発用）
      return _getMockData(cleanWord);
    } catch (e) {
      print('Japanese WordNet lookup error: $e');
      return null;
    }
  }

  static WordNetEntry? _parseWordNetResponse(Map<String, dynamic> data) {
    try {
      // APIレスポンスの構造に合わせて調整してください
      return WordNetEntry(
        word: data['word'] ?? '',
        partOfSpeech: data['pos'] ?? 'unknown',
        definitions: List<String>.from(data['definitions'] ?? []),
        synonyms: List<String>.from(data['synonyms'] ?? []),
        examples: List<String>.from(data['examples'] ?? []),
      );
    } catch (e) {
      print('Error parsing WordNet response: $e');
      return null;
    }
  }

  // 開発用のモックデータ
  static WordNetEntry? _getMockData(String word) {
    final mockData = {
      'school': WordNetEntry(
        word: 'school',
        partOfSpeech: '名詞',
        definitions: ['学校', '教育機関', '学び舎'],
        synonyms: ['academy', 'institution', 'college'],
        examples: ['I go to school every day.', 'Our school has a large library.'],
      ),
      'go': WordNetEntry(
        word: 'go',
        partOfSpeech: '動詞',
        definitions: ['行く', '向かう', '出発する'],
        synonyms: ['move', 'travel', 'proceed'],
        examples: ['I will go to Tokyo tomorrow.', 'Let\'s go together.'],
      ),
      'happy': WordNetEntry(
        word: 'happy',
        partOfSpeech: '形容詞',
        definitions: ['幸せな', '嬉しい', '満足した'],
        synonyms: ['joyful', 'glad', 'pleased'],
        examples: ['She looks very happy today.', 'I\'m happy to help you.'],
      ),
      'quickly': WordNetEntry(
        word: 'quickly',
        partOfSpeech: '副詞',
        definitions: ['素早く', '急いで', 'すぐに'],
        synonyms: ['rapidly', 'swiftly', 'fast'],
        examples: ['He runs quickly.', 'Please come quickly.'],
      ),
      'book': WordNetEntry(
        word: 'book',
        partOfSpeech: '名詞',
        definitions: ['本', '書籍', '書物'],
        synonyms: ['volume', 'publication', 'text'],
        examples: ['I bought a new book yesterday.', 'This book is very interesting.'],
      ),
      'write': WordNetEntry(
        word: 'write',
        partOfSpeech: '動詞',
        definitions: ['書く', '記述する', '執筆する'],
        synonyms: ['compose', 'author', 'pen'],
        examples: ['I write in my journal every day.', 'She writes beautiful poems.'],
      ),
      'beautiful': WordNetEntry(
        word: 'beautiful',
        partOfSpeech: '形容詞',
        definitions: ['美しい', '綺麗な', '素敵な'],
        synonyms: ['pretty', 'lovely', 'gorgeous'],
        examples: ['The sunset was beautiful.', 'She has a beautiful smile.'],
      ),
      'friend': WordNetEntry(
        word: 'friend',
        partOfSpeech: '名詞',
        definitions: ['友達', '友人', '仲間'],
        synonyms: ['buddy', 'pal', 'companion'],
        examples: ['He is my best friend.', 'I made new friends at school.'],
      ),
      'study': WordNetEntry(
        word: 'study',
        partOfSpeech: '動詞',
        definitions: ['勉強する', '学習する', '研究する'],
        synonyms: ['learn', 'examine', 'research'],
        examples: ['I study English every day.', 'She studies at the library.'],
      ),
      'time': WordNetEntry(
        word: 'time',
        partOfSpeech: '名詞',
        definitions: ['時間', '時刻', '時'],
        synonyms: ['period', 'moment', 'hour'],
        examples: ['What time is it?', 'I don\'t have much time.'],
      ),
    };

    return mockData[word];
  }

  // 品詞の日本語表記変換
  static String getJapanesePartOfSpeech(String englishPos) {
    final posMap = {
      'noun': '名詞',
      'verb': '動詞',
      'adjective': '形容詞',
      'adverb': '副詞',
      'pronoun': '代名詞',
      'preposition': '前置詞',
      'conjunction': '接続詞',
      'interjection': '間投詞',
      'determiner': '限定詞',
      'article': '冠詞',
    };
    
    return posMap[englishPos.toLowerCase()] ?? englishPos;
  }
}