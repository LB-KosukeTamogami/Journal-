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
      
      print('JapaneseWordNet: Looking up word: "$word" -> cleaned: "$cleanWord"');
      
      if (cleanWord.isEmpty) {
        print('JapaneseWordNet: Clean word is empty, returning null');
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
      final result = _getMockData(cleanWord);
      print('JapaneseWordNet: Mock data result: ${result != null ? "Found" : "Not found"}');
      if (result != null) {
        print('JapaneseWordNet: Definitions: ${result.definitions}');
      }
      return result;
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
    // 単語を小文字に統一
    final lowerWord = word.toLowerCase();
    
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
      // よく使われる単語を追加
      'today': WordNetEntry(
        word: 'today',
        partOfSpeech: '名詞/副詞',
        definitions: ['今日', '本日', '現在'],
        synonyms: ['this day', 'nowadays'],
        examples: ['Today is Monday.', 'I have a meeting today.'],
      ),
      'yesterday': WordNetEntry(
        word: 'yesterday',
        partOfSpeech: '名詞/副詞',
        definitions: ['昨日', '前日'],
        synonyms: ['the day before'],
        examples: ['I went to school yesterday.', 'Yesterday was sunny.'],
      ),
      'tomorrow': WordNetEntry(
        word: 'tomorrow',
        partOfSpeech: '名詞/副詞',
        definitions: ['明日', '翌日'],
        synonyms: ['the next day'],
        examples: ['See you tomorrow.', 'Tomorrow will be better.'],
      ),
      'day': WordNetEntry(
        word: 'day',
        partOfSpeech: '名詞',
        definitions: ['日', '一日', '昼間'],
        synonyms: ['daytime', 'date'],
        examples: ['It was a beautiful day.', 'Every day is a new beginning.'],
      ),
      'good': WordNetEntry(
        word: 'good',
        partOfSpeech: '形容詞',
        definitions: ['良い', '優れた', '善い'],
        synonyms: ['nice', 'fine', 'excellent'],
        examples: ['That\'s a good idea.', 'Have a good day!'],
      ),
      'very': WordNetEntry(
        word: 'very',
        partOfSpeech: '副詞',
        definitions: ['とても', '非常に', '大変'],
        synonyms: ['extremely', 'greatly', 'highly'],
        examples: ['She is very kind.', 'Thank you very much.'],
      ),
      'eat': WordNetEntry(
        word: 'eat',
        partOfSpeech: '動詞',
        definitions: ['食べる', '食事をする'],
        synonyms: ['consume', 'dine', 'have'],
        examples: ['Let\'s eat lunch.', 'I eat breakfast every morning.'],
      ),
      'see': WordNetEntry(
        word: 'see',
        partOfSpeech: '動詞',
        definitions: ['見る', '会う', '理解する'],
        synonyms: ['look', 'watch', 'view'],
        examples: ['I can see the mountain.', 'See you later!'],
      ),
      'work': WordNetEntry(
        word: 'work',
        partOfSpeech: '名詞/動詞',
        definitions: ['仕事', '働く', '作品'],
        synonyms: ['job', 'labor', 'employment'],
        examples: ['I work at a bank.', 'This machine doesn\'t work.'],
      ),
      'home': WordNetEntry(
        word: 'home',
        partOfSpeech: '名詞',
        definitions: ['家', '自宅', '故郷'],
        synonyms: ['house', 'residence', 'dwelling'],
        examples: ['Welcome home!', 'I\'m going home.'],
      ),
      'love': WordNetEntry(
        word: 'love',
        partOfSpeech: '名詞/動詞',
        definitions: ['愛', '愛する', '恋'],
        synonyms: ['affection', 'adore', 'cherish'],
        examples: ['I love you.', 'Love is beautiful.'],
      ),
      'like': WordNetEntry(
        word: 'like',
        partOfSpeech: '動詞/前置詞',
        definitions: ['好き', '～のような', '好む'],
        synonyms: ['enjoy', 'prefer', 'similar to'],
        examples: ['I like coffee.', 'It looks like rain.'],
      ),
      'want': WordNetEntry(
        word: 'want',
        partOfSpeech: '動詞',
        definitions: ['欲しい', '望む', '必要とする'],
        synonyms: ['desire', 'wish', 'need'],
        examples: ['I want to learn Japanese.', 'What do you want?'],
      ),
      'make': WordNetEntry(
        word: 'make',
        partOfSpeech: '動詞',
        definitions: ['作る', '製造する', '～にさせる'],
        synonyms: ['create', 'produce', 'build'],
        examples: ['I make coffee every morning.', 'Let\'s make a cake.'],
      ),
      'think': WordNetEntry(
        word: 'think',
        partOfSpeech: '動詞',
        definitions: ['思う', '考える', '思考する'],
        synonyms: ['believe', 'consider', 'ponder'],
        examples: ['I think so too.', 'Think before you speak.'],
      ),
      'know': WordNetEntry(
        word: 'know',
        partOfSpeech: '動詞',
        definitions: ['知る', '知っている', '理解する'],
        synonyms: ['understand', 'realize', 'comprehend'],
        examples: ['I know the answer.', 'Do you know her?'],
      ),
      'people': WordNetEntry(
        word: 'people',
        partOfSpeech: '名詞',
        definitions: ['人々', '人間', '国民'],
        synonyms: ['persons', 'individuals', 'humans'],
        examples: ['Many people came to the party.', 'People are kind here.'],
      ),
      'new': WordNetEntry(
        word: 'new',
        partOfSpeech: '形容詞',
        definitions: ['新しい', '新たな', '最近の'],
        synonyms: ['fresh', 'novel', 'recent'],
        examples: ['I bought a new car.', 'Happy New Year!'],
      ),
      'old': WordNetEntry(
        word: 'old',
        partOfSpeech: '形容詞',
        definitions: ['古い', '年をとった', '昔の'],
        synonyms: ['aged', 'elderly', 'ancient'],
        examples: ['This is an old book.', 'My old friend visited me.'],
      ),
      // 追加の一般的な単語
      'i': WordNetEntry(
        word: 'I',
        partOfSpeech: '代名詞',
        definitions: ['私', '僕', '自分'],
        synonyms: ['me', 'myself'],
        examples: ['I am a student.', 'I love music.'],
      ),
      'you': WordNetEntry(
        word: 'you',
        partOfSpeech: '代名詞',
        definitions: ['あなた', '君', 'あなた方'],
        synonyms: ['yourself'],
        examples: ['You are welcome.', 'How are you?'],
      ),
      'he': WordNetEntry(
        word: 'he',
        partOfSpeech: '代名詞',
        definitions: ['彼', 'その男性'],
        synonyms: ['him', 'himself'],
        examples: ['He is my brother.', 'He works hard.'],
      ),
      'she': WordNetEntry(
        word: 'she',
        partOfSpeech: '代名詞',
        definitions: ['彼女', 'その女性'],
        synonyms: ['her', 'herself'],
        examples: ['She is a doctor.', 'She likes reading.'],
      ),
      'it': WordNetEntry(
        word: 'it',
        partOfSpeech: '代名詞',
        definitions: ['それ', 'あれ'],
        synonyms: ['itself'],
        examples: ['It is raining.', 'I like it.'],
      ),
      'we': WordNetEntry(
        word: 'we',
        partOfSpeech: '代名詞',
        definitions: ['私たち', '我々'],
        synonyms: ['us', 'ourselves'],
        examples: ['We are friends.', 'We went together.'],
      ),
      'they': WordNetEntry(
        word: 'they',
        partOfSpeech: '代名詞',
        definitions: ['彼ら', '彼女ら', 'それら'],
        synonyms: ['them', 'themselves'],
        examples: ['They are coming.', 'They said yes.'],
      ),
      'am': WordNetEntry(
        word: 'am',
        partOfSpeech: '動詞',
        definitions: ['～です（一人称）', '存在する'],
        synonyms: ['be'],
        examples: ['I am happy.', 'I am here.'],
      ),
      'is': WordNetEntry(
        word: 'is',
        partOfSpeech: '動詞',
        definitions: ['～です', '～である', '存在する'],
        synonyms: ['be', 'exists'],
        examples: ['He is tall.', 'It is important.'],
      ),
      'are': WordNetEntry(
        word: 'are',
        partOfSpeech: '動詞',
        definitions: ['～です（複数）', '～である'],
        synonyms: ['be'],
        examples: ['They are students.', 'You are right.'],
      ),
      'was': WordNetEntry(
        word: 'was',
        partOfSpeech: '動詞',
        definitions: ['～でした', '～だった'],
        synonyms: ['be (past)'],
        examples: ['I was tired.', 'It was fun.'],
      ),
      'were': WordNetEntry(
        word: 'were',
        partOfSpeech: '動詞',
        definitions: ['～でした（複数）', '～だった'],
        synonyms: ['be (past plural)'],
        examples: ['They were happy.', 'We were there.'],
      ),
      'my': WordNetEntry(
        word: 'my',
        partOfSpeech: '所有格',
        definitions: ['私の', '僕の'],
        synonyms: ['mine'],
        examples: ['This is my book.', 'My name is...'],
      ),
      'your': WordNetEntry(
        word: 'your',
        partOfSpeech: '所有格',
        definitions: ['あなたの', '君の'],
        synonyms: ['yours'],
        examples: ['Your idea is great.', 'Is this your pen?'],
      ),
      'his': WordNetEntry(
        word: 'his',
        partOfSpeech: '所有格',
        definitions: ['彼の'],
        synonyms: [],
        examples: ['His car is new.', 'This is his.'],
      ),
      'her': WordNetEntry(
        word: 'her',
        partOfSpeech: '所有格/目的格',
        definitions: ['彼女の', '彼女を/に'],
        synonyms: ['hers'],
        examples: ['Her dress is beautiful.', 'I saw her.'],
      ),
      'this': WordNetEntry(
        word: 'this',
        partOfSpeech: '指示代名詞',
        definitions: ['これ', 'この'],
        synonyms: [],
        examples: ['This is nice.', 'This book is mine.'],
      ),
      'that': WordNetEntry(
        word: 'that',
        partOfSpeech: '指示代名詞',
        definitions: ['あれ', 'あの', 'その'],
        synonyms: [],
        examples: ['That is correct.', 'I know that.'],
      ),
      'these': WordNetEntry(
        word: 'these',
        partOfSpeech: '指示代名詞',
        definitions: ['これら', 'これらの'],
        synonyms: [],
        examples: ['These are my friends.', 'These books are new.'],
      ),
      'those': WordNetEntry(
        word: 'those',
        partOfSpeech: '指示代名詞',
        definitions: ['あれら', 'あれらの', 'それらの'],
        synonyms: [],
        examples: ['Those were the days.', 'Those people are kind.'],
      ),
      'get': WordNetEntry(
        word: 'get',
        partOfSpeech: '動詞',
        definitions: ['得る', '入手する', '理解する', '到着する'],
        synonyms: ['obtain', 'receive', 'acquire'],
        examples: ['I get up early.', 'Did you get it?'],
      ),
      'take': WordNetEntry(
        word: 'take',
        partOfSpeech: '動詞',
        definitions: ['取る', '持っていく', '撮る', '時間がかかる'],
        synonyms: ['grab', 'carry', 'require'],
        examples: ['Take this.', 'It takes time.'],
      ),
      'give': WordNetEntry(
        word: 'give',
        partOfSpeech: '動詞',
        definitions: ['与える', 'あげる', '提供する'],
        synonyms: ['provide', 'offer', 'grant'],
        examples: ['Give me a chance.', 'I gave him a book.'],
      ),
      'come': WordNetEntry(
        word: 'come',
        partOfSpeech: '動詞',
        definitions: ['来る', '到着する', '起こる'],
        synonyms: ['arrive', 'approach'],
        examples: ['Come here.', 'Spring has come.'],
      ),
      'went': WordNetEntry(
        word: 'went',
        partOfSpeech: '動詞',
        definitions: ['行った（goの過去形）'],
        synonyms: ['go (past)'],
        examples: ['I went to school.', 'They went home.'],
      ),
    };

    // モックデータから検索
    final entry = mockData[lowerWord];
    if (entry != null) {
      print('JapaneseWordNet: Found in mock data: $lowerWord');
      return entry;
    }
    
    print('JapaneseWordNet: Not found in mock data, generating default for: $lowerWord');
    // モックデータに存在しない場合は、基本的な辞書エントリを生成
    // これにより、すべての英单語に対して何らかの情報を表示
    return WordNetEntry(
      word: word,
      partOfSpeech: _inferPartOfSpeech(lowerWord),
      definitions: [_generateDefaultDefinition(word)],
      synonyms: [],
      examples: [],
    );
  }
  
  // 品詞を推測する簡易的なメソッド
  static String _inferPartOfSpeech(String word) {
    // 簡単な品詞推測ロジック
    if (word.endsWith('ly')) return '副詞';
    if (word.endsWith('ing') || word.endsWith('ed')) return '動詞';
    if (word.endsWith('tion') || word.endsWith('ment') || word.endsWith('ness')) return '名詞';
    if (word.endsWith('ful') || word.endsWith('less') || word.endsWith('ous')) return '形容詞';
    
    // デフォルトは名詞とする
    return '名詞';
  }
  
  // デフォルトの定義を生成
  static String _generateDefaultDefinition(String word) {
    // 一般的な単語に対して簡易的な定義を提供
    final simpleDefinitions = {
      'the': '定冠詞',
      'a': '不定冠詞',
      'an': '不定冠詞',
      'is': '～である',
      'are': '～である（複数）',
      'was': '～だった',
      'were': '～だった（複数）',
      'have': '持つ/ある',
      'has': '持つ/ある（三人称）',
      'had': '持った/あった',
      'do': 'する',
      'does': 'する（三人称）',
      'did': 'した',
      'will': '～だろう/～するつもり',
      'can': '～できる',
      'may': '～かもしれない',
      'must': '～しなければならない',
      'should': '～すべきだ',
      'could': '～できた/～できるかも',
      'would': '～だろう/～したものだ',
      'and': 'そして/と',
      'or': 'または',
      'but': 'しかし',
      'if': 'もし',
      'when': 'いつ/～するとき',
      'where': 'どこで/～する場所',
      'why': 'なぜ',
      'how': 'どうやって/どのように',
      'what': '何',
      'who': '誰',
      'which': 'どちら/どの',
      'in': '～の中に',
      'on': '～の上に',
      'at': '～で/～に',
      'to': '～へ/～に',
      'for': '～のために',
      'from': '～から',
      'with': '～と一緒に',
      'by': '～によって',
      'of': '～の',
      'about': '～について',
      'into': '～の中へ',
      'out': '外へ',
      'up': '上へ',
      'down': '下へ',
    };
    
    final lowerWord = word.toLowerCase();
    final definition = simpleDefinitions[lowerWord];
    if (definition != null) {
      print('JapaneseWordNet: Found simple definition for: $lowerWord -> $definition');
      return definition;
    }
    print('JapaneseWordNet: No simple definition found for: $lowerWord');
    return '[詳細な定義は準備中]';
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