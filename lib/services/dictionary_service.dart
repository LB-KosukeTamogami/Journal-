import 'dart:convert';
import 'package:http/http.dart' as http;
import 'word_cache_service.dart';
import 'gemini_service.dart';

class DictionaryService {
  static const String _baseUrl = 'https://api.dictionaryapi.dev/api/v2/entries/en/';
  
  /// 単語の詳細情報を取得
  static Future<DictionaryResult> lookupWord(String word) async {
    if (word.trim().isEmpty) {
      return DictionaryResult(
        word: word,
        definitions: [],
        success: false,
        error: '単語が空です',
      );
    }

    // まずキャッシュから検索
    final cached = await WordCacheService.fetchCachedWord(word.toLowerCase());
    if (cached != null && cached['definition'] != null) {
      return DictionaryResult(
        word: word,
        definitions: [
          Definition(
            partOfSpeech: cached['part_of_speech'] ?? 'unknown',
            definition: cached['definition']!,
            example: cached['example'],
          ),
        ],
        success: true,
        source: 'cache',
      );
    }

    // 基本的な単語辞書を先にチェック（特に不規則動詞の過去形）
    final basicResult = _getBasicDefinition(word);
    if (basicResult.success) {
      return basicResult;
    }

    try {
      // Free Dictionary APIを使用
      final response = await http.get(
        Uri.parse('$_baseUrl${Uri.encodeComponent(word.toLowerCase())}'),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final result = _parseDictionaryResponse(word, data);
        
        // 英語の定義を日本語に翻訳
        for (final def in result.definitions) {
          if (def.japaneseDefinition == null && def.definition.isNotEmpty) {
            // 英語の定義をより適切に日本語に翻訳
            try {
              final japaneseDefinition = await _translateDefinitionWithContext(
                word: word,
                definition: def.definition,
                partOfSpeech: def.partOfSpeech,
              );
              def.japaneseDefinition = japaneseDefinition;
            } catch (e) {
              // エラーの場合はGemini APIで翻訳を試みる
              print('Translation error for $word: $e');
              try {
                final fallbackResult = await _lookupWithGemini(word);
                if (fallbackResult.success && fallbackResult.definitions.isNotEmpty) {
                  def.japaneseDefinition = fallbackResult.definitions.first.japaneseDefinition;
                } else {
                  def.japaneseDefinition = '（英語の単語）';
                }
              } catch (fallbackError) {
                def.japaneseDefinition = '（英語の単語）';
              }
            }
          }
        }
        
        // 最初の定義をキャッシュに保存
        if (result.definitions.isNotEmpty) {
          final firstDef = result.definitions.first;
          await WordCacheService.cacheWordTranslation(
            jaWord: word.toLowerCase(),
            enWord: word.toLowerCase(),
            definition: firstDef.japaneseDefinition ?? firstDef.definition,
            source: 'dictionary_api',
          );
        }
        
        return result;
      } else if (response.statusCode == 404) {
        // 辞書APIで見つからない場合はGemini APIを使用
        return await _lookupWithGemini(word);
      } else {
        // その他のエラーの場合もGemini APIにフォールバック
        return await _lookupWithGemini(word);
      }
    } catch (e) {
      // エラーが発生した場合もGemini APIを使用
      return await _lookupWithGemini(word);
    }
  }

  /// Gemini APIを使用して単語の意味を取得
  static Future<DictionaryResult> _lookupWithGemini(String word) async {
    try {
      // 単語の意味を直接Gemini APIで取得（より適切な定義のため）
      final prompt = '''
以下の英単語の意味を、日本人の英語学習者向けに説明してください。

単語: $word

説明のルール:
1. 最も一般的な意味を優先する
2. 簡潔で分かりやすい日本語で説明する
3. 必要に応じて品詞情報も含める（動詞、名詞、形容詞など）
4. 過去形や過去分詞の場合は、元の動詞と関連付けて説明する（例：「went」→「行った（goの過去形）」）
5. 複数の重要な意味がある場合は、箇条書きで最大3つまで示す

日本語の説明のみを返してください:''';

      // 特別なプロンプトを使ってGeminiで単語の意味を取得
      final customPrompt = '''単語の意味を返答してください。
$prompt''';
      
      final result = await GeminiService.correctAndTranslate(
        customPrompt,
        targetLanguage: 'ja',
      );
      final translation = result['translation'] ?? '';
      
      if (translation.isNotEmpty && translation != '意味を取得できませんでした' && translation != '（英語の単語）') {
        // 成功した場合はキャッシュに保存
        await WordCacheService.cacheWordTranslation(
          jaWord: word.toLowerCase(),
          enWord: word.toLowerCase(),
          definition: translation,
          source: 'gemini',
        );
        
        return DictionaryResult(
          word: word,
          definitions: [
            Definition(
              partOfSpeech: 'unknown',
              definition: translation,
              japaneseDefinition: translation,
            ),
          ],
          success: true,
          source: 'gemini',
        );
      }
    } catch (e) {
      print('Gemini API error: $e');
    }
    
    // すべて失敗した場合は基本的な単語辞書を使用
    return _getBasicDefinition(word);
  }

  /// 基本的な単語辞書から定義を取得
  static DictionaryResult _getBasicDefinition(String word) {
    final basicDefinitions = {
      // 頻出単語の定義
      'the': '定冠詞（特定のものを指す）',
      'a': '不定冠詞（1つの）',
      'an': '不定冠詞（母音で始まる語の前）',
      'and': '〜と、そして',
      'or': '〜または',
      'but': 'しかし、〜だが',
      'in': '〜の中に',
      'on': '〜の上に',
      'at': '〜で、〜において',
      'to': '〜へ、〜に',
      'from': '〜から',
      'with': '〜と一緒に',
      'by': '〜によって',
      'for': '〜のために',
      'of': '〜の',
      'about': '〜について',
      'as': '〜として',
      'like': '〜のような',
      'through': '〜を通して',
      'after': '〜の後に',
      'before': '〜の前に',
      'between': '〜の間に',
      'into': '〜の中へ',
      'during': '〜の間',
      'without': '〜なしに',
      'under': '〜の下に',
      'over': '〜の上に',
      'up': '上へ',
      'down': '下へ',
      'out': '外へ',
      'off': '離れて',
      'if': 'もし〜なら',
      'when': 'いつ、〜の時',
      'where': 'どこで',
      'what': '何',
      'who': '誰',
      'which': 'どちら、どの',
      'how': 'どのように',
      'why': 'なぜ',
      'because': 'なぜなら',
      'so': 'だから、とても',
      'very': 'とても',
      'really': '本当に',
      'quite': 'かなり',
      'just': 'ちょうど、単に',
      'only': '〜だけ',
      'also': '〜もまた',
      'too': '〜も、あまりに',
      'now': '今',
      'then': 'その時、それから',
      'here': 'ここに',
      'there': 'そこに',
      'all': 'すべて',
      'some': 'いくつかの',
      'many': '多くの',
      'much': 'たくさんの',
      'few': '少しの',
      'little': '小さい、少し',
      'more': 'もっと',
      'most': '最も',
      'other': '他の',
      'another': 'もう一つの',
      'each': 'それぞれの',
      'every': 'すべての',
      'any': 'いずれかの',
      'both': '両方',
      'either': 'どちらか',
      'neither': 'どちらも〜ない',
      'first': '最初の',
      'last': '最後の',
      'next': '次の',
      'new': '新しい',
      'old': '古い',
      'good': '良い',
      'bad': '悪い',
      'great': '素晴らしい',
      'small': '小さい',
      'large': '大きい',
      'long': '長い',
      'short': '短い',
      'high': '高い',
      'low': '低い',
      'right': '正しい、右',
      'wrong': '間違った',
      'big': '大きい',
      'different': '異なる',
      'same': '同じ',
      'own': '自分の',
      'such': 'そのような',
      'still': 'まだ、じっとした',
      'well': 'よく、上手に',
      'even': '〜でさえ',
      'back': '戻って、背中',
      'after': '〜の後',
      'use': '使う',
      'make': '作る',
      'go': '行く',
      'come': '来る',
      'take': '取る',
      'give': '与える',
      'get': '得る',
      'keep': '保つ',
      'let': '〜させる',
      'begin': '始める',
      'seem': '〜のように見える',
      'help': '助ける',
      'talk': '話す',
      'turn': '回る、変わる',
      'start': '始める',
      'show': '見せる',
      'hear': '聞く',
      'play': '遊ぶ、演奏する',
      'run': '走る',
      'move': '動く',
      'live': '生きる、住む',
      'believe': '信じる',
      'bring': '持ってくる',
      'happen': '起こる',
      'write': '書く',
      'provide': '提供する',
      'sit': '座る',
      'stand': '立つ',
      'lose': '失う',
      'pay': '払う',
      'meet': '会う',
      'include': '含む',
      'continue': '続ける',
      'set': '設定する',
      'learn': '学ぶ',
      'change': '変える',
      'lead': '導く',
      'understand': '理解する',
      'watch': '見る',
      'follow': '従う',
      'stop': '止まる',
      'create': '作成する',
      'speak': '話す',
      'read': '読む',
      'spend': '過ごす、使う',
      'grow': '成長する',
      'open': '開く',
      'walk': '歩く',
      'win': '勝つ',
      'teach': '教える',
      'offer': '提供する',
      'remember': '覚えている',
      'love': '愛する',
      'consider': '考慮する',
      'appear': '現れる',
      'buy': '買う',
      'wait': '待つ',
      'serve': '仕える、提供する',
      'die': '死ぬ',
      'send': '送る',
      'build': '建てる',
      'stay': '滞在する',
      'fall': '落ちる',
      'cut': '切る',
      'reach': '届く',
      'kill': '殺す',
      'raise': '上げる',
      'effort': '努力、取り組み',
      'efforts': '努力、取り組み（複数形）',
      // 動詞の三人称単数形
      'pays': '払う（payの三人称単数形）',
      'goes': '行く（goの三人称単数形）',
      'does': 'する（doの三人称単数形）',
      'has': '持つ（haveの三人称単数形）',
      'says': '言う（sayの三人称単数形）',
      'makes': '作る（makeの三人称単数形）',
      'takes': '取る（takeの三人称単数形）',
      'comes': '来る（comeの三人称単数形）',
      'sees': '見る（seeの三人称単数形）',
      'knows': '知る（knowの三人称単数形）',
      'gets': '得る（getの三人称単数形）',
      'gives': '与える（giveの三人称単数形）',
      'finds': '見つける（findの三人称単数形）',
      'thinks': '考える（thinkの三人称単数形）',
      'tells': '話す（tellの三人称単数形）',
      'becomes': 'なる（becomeの三人称単数形）',
      'shows': '見せる（showの三人称単数形）',
      'feels': '感じる（feelの三人称単数形）',
      'tries': '試す（tryの三人称単数形）',
      'leaves': '去る（leaveの三人称単数形）',
      'works': '働く（workの三人称単数形）',
      'seems': '〜のように見える（seemの三人称単数形）',
      'asks': '尋ねる（askの三人称単数形）',
      'needs': '必要とする（needの三人称単数形）',
      'means': '意味する（meanの三人称単数形）',
      'keeps': '保つ（keepの三人称単数形）',
      'starts': '始める（startの三人称単数形）',
      'helps': '助ける（helpの三人称単数形）',
      'talks': '話す（talkの三人称単数形）',
      'turns': '回る（turnの三人称単数形）',
      'puts': '置く（putの三人称単数形）',
      'believes': '信じる（believeの三人称単数形）',
      'lives': '生きる（liveの三人称単数形）',
      'brings': '持ってくる（bringの三人称単数形）',
      'happens': '起こる（happenの三人称単数形）',
      'writes': '書く（writeの三人称単数形）',
      'provides': '提供する（provideの三人称単数形）',
      'sits': '座る（sitの三人称単数形）',
      'stands': '立つ（standの三人称単数形）',
      'loses': '失う（loseの三人称単数形）',
      'meets': '会う（meetの三人称単数形）',
      'includes': '含む（includeの三人称単数形）',
      'continues': '続ける（continueの三人称単数形）',
      'sets': '設定する（setの三人称単数形）',
      'learns': '学ぶ（learnの三人称単数形）',
      'changes': '変える（changeの三人称単数形）',
      'leads': '導く（leadの三人称単数形）',
      'understands': '理解する（understandの三人称単数形）',
      'watches': '見る（watchの三人称単数形）',
      'follows': '従う（followの三人称単数形）',
      'stops': '止まる（stopの三人称単数形）',
      'creates': '作成する（createの三人称単数形）',
      'speaks': '話す（speakの三人称単数形）',
      'reads': '読む（readの三人称単数形）',
      'spends': '過ごす（spendの三人称単数形）',
      'grows': '成長する（growの三人称単数形）',
      'opens': '開く（openの三人称単数形）',
      'walks': '歩く（walkの三人称単数形）',
      'wins': '勝つ（winの三人称単数形）',
      'teaches': '教える（teachの三人称単数形）',
      'offers': '提供する（offerの三人称単数形）',
      'remembers': '覚えている（rememberの三人称単数形）',
      'loves': '愛する（loveの三人称単数形）',
      'considers': '考慮する（considerの三人称単数形）',
      'appears': '現れる（appearの三人称単数形）',
      'buys': '買う（buyの三人称単数形）',
      'waits': '待つ（waitの三人称単数形）',
      'serves': '仕える（serveの三人称単数形）',
      'dies': '死ぬ（dieの三人称単数形）',
      'sends': '送る（sendの三人称単数形）',
      'builds': '建てる（buildの三人称単数形）',
      'stays': '滞在する（stayの三人称単数形）',
      'falls': '落ちる（fallの三人称単数形）',
      'reaches': '届く（reachの三人称単数形）',
      'kills': '殺す（killの三人称単数形）',
      'raises': '上げる（raiseの三人称単数形）',
      'cuts': '切る（cutの三人称単数形）',
      // 不規則動詞の過去形
      'went': '行った（goの過去形）',
      'came': '来た（comeの過去形）',
      'saw': '見た（seeの過去形）',
      'made': '作った（makeの過去形）',
      'got': '得た、手に入れた（getの過去形）',
      'gave': '与えた（giveの過去形）',
      'took': '取った（takeの過去形）',
      'found': '見つけた（findの過去形）',
      'told': '話した、伝えた（tellの過去形）',
      'knew': '知っていた（knowの過去形）',
      'thought': '思った、考えた（thinkの過去形）',
      'felt': '感じた（feelの過去形）',
      'became': 'なった（becomeの過去形）',
      'left': '去った、離れた（leaveの過去形）',
      'brought': '持ってきた（bringの過去形）',
      'began': '始めた（beginの過去形）',
      'kept': '保った（keepの過去形）',
      'held': '持った、開催した（holdの過去形）',
      'wrote': '書いた（writeの過去形）',
      'stood': '立った（standの過去形）',
      'heard': '聞いた（hearの過去形）',
      'met': '会った（meetの過去形）',
      'ran': '走った（runの過去形）',
      'paid': '払った（payの過去形）',
      'sat': '座った（sitの過去形）',
      'spoke': '話した（speakの過去形）',
      'lay': '横たわった（lieの過去形）',
      'led': '導いた（leadの過去形）',
      'read': '読んだ（readの過去形）',
      'grew': '成長した（growの過去形）',
      'lost': '失った（loseの過去形）',
      'fell': '落ちた（fallの過去形）',
      'sent': '送った（sendの過去形）',
      'built': '建てた（buildの過去形）',
      'understood': '理解した（understandの過去形）',
      'drew': '描いた（drawの過去形）',
      'broke': '壊した（breakの過去形）',
      'spent': '過ごした、使った（spendの過去形）',
      'cut': '切った（cutの過去形）',
      'rose': '上がった（riseの過去形）',
      'drove': '運転した（driveの過去形）',
      'bought': '買った（buyの過去形）',
      'wore': '着た（wearの過去形）',
      'chose': '選んだ（chooseの過去形）',
      'ate': '食べた（eatの過去形）',
      'drank': '飲んだ（drinkの過去形）',
      'slept': '寝た（sleepの過去形）',
      'woke': '起きた（wakeの過去形）',
      'taught': '教えた（teachの過去形）',
      'won': '勝った（winの過去形）',
      'forgot': '忘れた（forgetの過去形）',
      'flew': '飛んだ（flyの過去形）',
      'caught': '捕まえた（catchの過去形）',
      'fought': '戦った（fightの過去形）',
      'died': '死んだ（dieの過去形）',
      // 過去分詞形でよく使われるもの
      'been': 'であった（beの過去分詞）',
      'done': 'した（doの過去分詞）',
      'gone': '行った（goの過去分詞）',
      'seen': '見た（seeの過去分詞）',
      'taken': '取った（takeの過去分詞）',
      'given': '与えた（giveの過去分詞）',
      'written': '書いた（writeの過去分詞）',
      'spoken': '話した（speakの過去分詞）',
      'eaten': '食べた（eatの過去分詞）',
      'known': '知られた（knowの過去分詞）',
      'shown': '見せた（showの過去分詞）',
      'hidden': '隠した（hideの過去分詞）',
      'fallen': '落ちた（fallの過去分詞）',
      'driven': '運転した（driveの過去分詞）',
      'broken': '壊れた（breakの過去分詞）',
      // be動詞の活用形
      'am': '〜です（I amで使用）',
      'is': '〜です（三人称単数）',
      'are': '〜です（複数形）',
      'was': '〜でした（過去形・単数）',
      'were': '〜でした（過去形・複数）',
      // 助動詞
      'can': '〜できる',
      'could': '〜できた、〜かもしれない',
      'will': '〜するでしょう',
      'would': '〜するだろう',
      'shall': '〜しましょう',
      'should': '〜すべきだ',
      'may': '〜かもしれない',
      'might': '〜かもしれない（可能性低）',
      'must': '〜しなければならない',
      'ought': '〜すべきだ',
      // 現在進行形でよく使う
      'being': '〜している（beの現在分詞）',
      'having': '持っている（haveの現在分詞）',
      'doing': 'している（doの現在分詞）',
      'going': '行っている（goの現在分詞）',
      'making': '作っている（makeの現在分詞）',
      'taking': '取っている（takeの現在分詞）',
      'coming': '来ている（comeの現在分詞）',
      'thinking': '考えている（thinkの現在分詞）',
      'looking': '見ている（lookの現在分詞）',
      'using': '使っている（useの現在分詞）',
      'finding': '見つけている（findの現在分詞）',
      'getting': '得ている（getの現在分詞）',
      'wanting': '欲しがっている（wantの現在分詞）',
      'giving': '与えている（giveの現在分詞）',
      'telling': '話している（tellの現在分詞）',
      'working': '働いている（workの現在分詞）',
      'calling': '呼んでいる（callの現在分詞）',
      'trying': '試している（tryの現在分詞）',
      'asking': '尋ねている（askの現在分詞）',
      'needing': '必要としている（needの現在分詞）',
      'feeling': '感じている（feelの現在分詞）',
      'becoming': 'なっている（becomeの現在分詞）',
      'leaving': '去っている（leaveの現在分詞）',
      'putting': '置いている（putの現在分詞）',
      'meaning': '意味している（meanの現在分詞）',
      'keeping': '保っている（keepの現在分詞）',
      'letting': 'させている（letの現在分詞）',
      'beginning': '始めている（beginの現在分詞）',
      'seeming': '〜のように見える（seemの現在分詞）',
      'helping': '助けている（helpの現在分詞）',
      'talking': '話している（talkの現在分詞）',
      'turning': '回している（turnの現在分詞）',
      'showing': '見せている（showの現在分詞）',
      'hearing': '聞いている（hearの現在分詞）',
      'playing': '遊んでいる（playの現在分詞）',
      'running': '走っている（runの現在分詞）',
      'moving': '動いている（moveの現在分詞）',
      'living': '生きている（liveの現在分詞）',
      'believing': '信じている（believeの現在分詞）',
      'bringing': '持ってきている（bringの現在分詞）',
      'happening': '起こっている（happenの現在分詞）',
      'writing': '書いている（writeの現在分詞）',
      'sitting': '座っている（sitの現在分詞）',
      'standing': '立っている（standの現在分詞）',
      'losing': '失っている（loseの現在分詞）',
      'paying': '払っている（payの現在分詞）',
      'meeting': '会っている（meetの現在分詞）',
      'including': '含んでいる（includeの現在分詞）',
      'continuing': '続けている（continueの現在分詞）',
      'setting': '設定している（setの現在分詞）',
      'learning': '学んでいる（learnの現在分詞）',
      'changing': '変えている（changeの現在分詞）',
      'leading': '導いている（leadの現在分詞）',
      'understanding': '理解している（understandの現在分詞）',
      'watching': '見ている（watchの現在分詞）',
      'following': '従っている（followの現在分詞）',
      'stopping': '止めている（stopの現在分詞）',
      'creating': '作成している（createの現在分詞）',
      'speaking': '話している（speakの現在分詞）',
      'reading': '読んでいる（readの現在分詞）',
      'spending': '過ごしている（spendの現在分詞）',
      'growing': '成長している（growの現在分詞）',
      'opening': '開いている（openの現在分詞）',
      'walking': '歩いている（walkの現在分詞）',
      'winning': '勝っている（winの現在分詞）',
      'teaching': '教えている（teachの現在分詞）',
      'offering': '提供している（offerの現在分詞）',
      'remembering': '覚えている（rememberの現在分詞）',
      'loving': '愛している（loveの現在分詞）',
      'considering': '考慮している（considerの現在分詞）',
      'appearing': '現れている（appearの現在分詞）',
      'buying': '買っている（buyの現在分詞）',
      'waiting': '待っている（waitの現在分詞）',
      'serving': '仕えている（serveの現在分詞）',
      'dying': '死んでいる（dieの現在分詞）',
      'sending': '送っている（sendの現在分詞）',
      'building': '建てている（buildの現在分詞）',
      'staying': '滞在している（stayの現在分詞）',
      'falling': '落ちている（fallの現在分詞）',
      'cutting': '切っている（cutの現在分詞）',
      'reaching': '届いている（reachの現在分詞）',
      'killing': '殺している（killの現在分詞）',
      'raising': '上げている（raiseの現在分詞）',
      // 追加の基本単語
      'stayed': '滞在した、止まった（stayの過去形）',
      'late': '遅い、遅刻の',
      'studying': '勉強している（studyの現在分詞）',
      'studied': '勉強した（studyの過去形）',
      'early': '早い、早朝の',
      'today': '今日',
      'yesterday': '昨日',
      'tomorrow': '明日',
      'week': '週',
      'month': '月',
      'year': '年',
      'time': '時間',
      'day': '日、一日',
      'night': '夜',
      'morning': '朝',
      'afternoon': '午後',
      'evening': '夕方',
      'people': '人々',
      'person': '人',
      'man': '男性',
      'woman': '女性',
      'child': '子供',
      'children': '子供たち',
      'home': '家',
      'house': '家、建物',
      'school': '学校',
      'office': 'オフィス、事務所',
      'place': '場所',
      'city': '都市',
      'country': '国',
      'world': '世界',
      'life': '人生、生活',
      'family': '家族',
      'friend': '友達',
      'food': '食べ物',
      'water': '水',
      'money': 'お金',
      'job': '仕事',
      'company': '会社',
      'student': '学生',
      'teacher': '先生',
      'book': '本',
      'computer': 'コンピューター',
      'phone': '電話',
      'car': '車',
      'train': '電車',
      'bus': 'バス',
      'road': '道',
      'door': 'ドア',
      'window': '窓',
      'room': '部屋',
      'table': 'テーブル',
      'chair': '椅子',
      'bed': 'ベッド',
      'kitchen': 'キッチン',
      'bathroom': 'バスルーム',
      'garden': '庭',
      'park': '公園',
      'street': '通り',
      'shop': '店',
      'store': '店舗',
      'market': '市場',
      'restaurant': 'レストラン',
      'hospital': '病院',
      'airport': '空港',
      'station': '駅',
      'hotel': 'ホテル',
      'bank': '銀行',
      'library': '図書館',
      'museum': '博物館',
      'cinema': '映画館',
      'theater': '劇場',
      'university': '大学',
      'college': '大学、カレッジ',
      'language': '言語',
      'english': '英語',
      'japanese': '日本語',
      'music': '音楽',
      'art': '芸術',
      'science': '科学',
      'history': '歴史',
      'math': '数学',
      'mathematics': '数学',
      'sport': 'スポーツ',
      'sports': 'スポーツ',
      'game': 'ゲーム',
      'movie': '映画',
      'film': '映画',
      'photo': '写真',
      'picture': '写真、絵',
      'color': '色',
      'colour': '色',
      'red': '赤',
      'blue': '青',
      'green': '緑',
      'yellow': '黄色',
      'black': '黒',
      'white': '白',
      'brown': '茶色',
      'orange': 'オレンジ',
      'purple': '紫',
      'pink': 'ピンク',
      'gray': '灰色',
      'grey': '灰色',
    };

    final lowerWord = word.toLowerCase();
    final definition = basicDefinitions[lowerWord];
    
    if (definition != null) {
      // キャッシュに保存
      WordCacheService.cacheWordTranslation(
        jaWord: lowerWord,
        enWord: lowerWord,
        definition: definition,
        source: 'basic',
      );
      
      return DictionaryResult(
        word: word,
        definitions: [
          Definition(
            partOfSpeech: 'unknown',
            definition: definition,
            japaneseDefinition: definition,
          ),
        ],
        success: true,
        source: 'basic',
      );
    }

    // 基本辞書にない場合でも、エラーではなく一般的な説明を返す
    return DictionaryResult(
      word: word,
      definitions: [
        Definition(
          partOfSpeech: 'unknown',
          definition: '（英語の単語）',
          japaneseDefinition: '（英語の単語）',
        ),
      ],
      success: false,
      source: 'fallback',
    );
  }

  /// 文脈を考慮して英語の定義を日本語に翻訳
  static Future<String> _translateDefinitionWithContext({
    required String word,
    required String definition,
    required String partOfSpeech,
  }) async {
    try {
      // 定義が短すぎる場合は、そのまま返す
      if (definition.length < 3) {
        return definition;
      }
      
      // Gemini APIで専用のプロンプトを使って翻訳
      final prompt = '''
以下の英単語の定義を、日本人の英語学習者にとって分かりやすい日本語に翻訳してください。

単語: $word
品詞: $partOfSpeech
英語の定義: $definition

翻訳のルール:
1. 学習者にとって分かりやすい、簡潔な日本語にする
2. 品詞情報を考慮する（動詞なら「〜する」、名詞なら「〜」、形容詞なら「〜な/い」など）
3. 専門用語は避け、日常的な言葉を使う
4. 定義が複数の意味を含む場合は、最も一般的な意味を優先する
5. 英語の定義をそのまま直訳せず、日本語として自然な表現にする

日本語訳のみを返してください（説明や追加情報は不要）:''';

      // 特別なプロンプトを使ってGeminiで翻訳
      final customPrompt = '''以下の内容を日本語に翻訳してください。
$prompt''';
      
      final result = await GeminiService.correctAndTranslate(
        customPrompt,
        targetLanguage: 'ja',
      );
      final translation = result['translation'] ?? '';
      
      if (translation.isNotEmpty && translation.length < 100) {
        return translation;
      } else {
        return _getBasicTranslation(definition);
      }
    } catch (e) {
      print('Translation error: $e');
      return _getBasicTranslation(definition);
    }
  }

  /// 英語の定義を簡単に日本語に翻訳
  static String _getBasicTranslation(String englishDefinition) {
    // 定義が短い場合は、基本的な定義を返す
    if (englishDefinition.isEmpty || englishDefinition.length < 3) {
      return '（英語の単語）';
    }
    
    // よくある英語の定義パターンを日本語に変換
    final patterns = {
      'to prop; support; sustain': '支える、維持する',
      'to review materials': '教材を復習する',
      'a shift.*late in the day': '遅番シフト',
      'scheduled work period': '予定された勤務時間',
      'a person who': '〜する人',
      'the act of': '〜すること',
      'the state of being': '〜である状態',
      'relating to': '〜に関する',
      'having': '〜を持つ',
      'without': '〜なしに',
      'someone who': '〜する人',
      'something that': '〜するもの',
      'used to': '〜するために使われる',
      'in a way that': '〜のような方法で',
      'to be': '〜である',
      'to have': '〜を持つ',
      'to do': '〜をする',
      'to make': '〜を作る',
      'to go': '行く',
      'to come': '来る',
      'to take': '取る',
      'to give': '与える',
      'to get': '得る',
      'to see': '見る',
      'to know': '知る',
      'to think': '考える',
      'to say': '言う',
      'to use': '使う',
      'to find': '見つける',
      'to want': '欲しがる',
      'to tell': '伝える',
      'to ask': '尋ねる',
      'to work': '働く',
      'to try': '試す',
      'to need': '必要とする',
      'to feel': '感じる',
      'to become': 'なる',
      'to leave': '去る',
      'to put': '置く',
      'to mean': '意味する',
    };
    
    String translated = englishDefinition.toLowerCase();
    
    // パターンマッチングで翻訳
    for (final entry in patterns.entries) {
      final pattern = RegExp(entry.key, caseSensitive: false);
      if (pattern.hasMatch(translated)) {
        return entry.value;
      }
    }
    
    // それでも英語のままの場合は、基本的な定義を返す
    return '（英語の単語）';
  }

  /// Free Dictionary APIのレスポンスをパース
  static DictionaryResult _parseDictionaryResponse(String word, dynamic data) {
    final List<Definition> definitions = [];
    
    try {
      if (data is List && data.isNotEmpty) {
        final entry = data[0];
        final meanings = entry['meanings'] as List?;
        
        if (meanings != null) {
          for (final meaning in meanings) {
            final partOfSpeech = meaning['partOfSpeech'] ?? 'unknown';
            final defs = meaning['definitions'] as List?;
            
            if (defs != null) {
              // 定義を最大3つまでに制限（多すぎると見づらいため）
              final defsToAdd = defs.take(3);
              for (final def in defsToAdd) {
                definitions.add(Definition(
                  partOfSpeech: partOfSpeech,
                  definition: def['definition'] ?? '',
                  example: def['example'],
                  synonyms: List<String>.from(def['synonyms'] ?? []),
                  antonyms: List<String>.from(def['antonyms'] ?? []),
                ));
              }
            }
          }
        }
      }
    } catch (e) {
      print('Error parsing dictionary response: $e');
    }
    
    return DictionaryResult(
      word: word,
      definitions: definitions,
      success: definitions.isNotEmpty,
      source: 'dictionary_api',
    );
  }
}

class DictionaryResult {
  final String word;
  final List<Definition> definitions;
  final bool success;
  final String? error;
  final String source;

  DictionaryResult({
    required this.word,
    required this.definitions,
    required this.success,
    this.error,
    this.source = 'unknown',
  });
}

class Definition {
  final String partOfSpeech;
  final String definition;
  final String? example;
  final List<String> synonyms;
  final List<String> antonyms;
  String? japaneseDefinition;

  Definition({
    required this.partOfSpeech,
    required this.definition,
    this.example,
    this.synonyms = const [],
    this.antonyms = const [],
    this.japaneseDefinition,
  });
}