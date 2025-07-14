import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/diary_entry.dart';
import '../models/user_profile.dart';
import '../models/mission.dart';
import '../models/flashcard.dart';
import '../models/word.dart';
import 'supabase_service.dart';

class StorageService {
  static const String _diaryEntriesKey = 'diary_entries';
  static const String _userProfileKey = 'user_profile';
  static const String _missionsKey = 'missions';
  static const String _flashcardsKey = 'flashcards';
  static const String _wordsKey = 'words';
  static const String _sampleDataKey = 'sample_data_initialized';

  static SharedPreferences? _prefs;

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  static SharedPreferences get prefs {
    if (_prefs == null) {
      throw Exception('StorageService not initialized. Call init() first.');
    }
    return _prefs!;
  }

  static Future<List<DiaryEntry>> getDiaryEntries() async {
    print('[Storage] ========== Getting diary entries ==========');
    print('[Storage] SupabaseService.isAvailable: ${SupabaseService.isAvailable}');
    
    // Supabaseからデータを取得
    List<DiaryEntry> supabaseEntries = [];
    bool supabaseSuccess = false;
    
    if (SupabaseService.isAvailable) {
      try {
        print('[Storage] Attempting to fetch diaries from Supabase...');
        final startTime = DateTime.now();
        supabaseEntries = await SupabaseService.getDiaryEntries();
        final endTime = DateTime.now();
        final duration = endTime.difference(startTime).inMilliseconds;
        print('[Storage] Supabase fetch completed in ${duration}ms');
        print('[Storage] Got ${supabaseEntries.length} diaries from Supabase');
        
        // データの内容を確認
        if (supabaseEntries.isNotEmpty) {
          print('[Storage] First entry title: ${supabaseEntries.first.title}');
          print('[Storage] First entry created at: ${supabaseEntries.first.createdAt}');
        }
        
        supabaseSuccess = true;
      } catch (e, stack) {
        print('[Storage] ERROR getting Supabase diary entries: $e');
        print('[Storage] Stack trace: $stack');
        print('[Storage] Will try to use cached data');
      }
    } else {
      print('[Storage] Supabase not available, using local storage only');
    }

    // ローカルデータを取得
    final jsonString = prefs.getString(_diaryEntriesKey);
    List<DiaryEntry> localEntries = [];
    if (jsonString != null) {
      final List<dynamic> jsonList = json.decode(jsonString);
      localEntries = jsonList.map((json) => DiaryEntry.fromJson(json)).toList();
      print('[Storage] Got ${localEntries.length} diaries from local storage');
    }

    // Supabaseが正常に接続できた場合
    if (supabaseSuccess) {
      print('[Storage] Supabase connection successful');
      
      // Supabaseのデータをローカルにキャッシュ
      final jsonString = json.encode(supabaseEntries.map((e) => e.toJson()).toList());
      await prefs.setString(_diaryEntriesKey, jsonString);
      print('[Storage] Cached ${supabaseEntries.length} entries from Supabase to local');
      print('[Storage] ========== Returning Supabase data ==========');
      
      return supabaseEntries;
    }
    
    // Supabaseに接続できなかった場合はローカルデータを使用
    print('[Storage] Using local cached data (${localEntries.length} diaries)');
    print('[Storage] ========== Returning local data ==========');
    return localEntries;
  }

  static Future<void> saveDiaryEntry(DiaryEntry entry) async {
    print('[Storage] Saving diary entry: ${entry.title}');
    print('[Storage] SupabaseService.isAvailable: ${SupabaseService.isAvailable}');
    
    // Supabaseに保存（必須）
    if (SupabaseService.isAvailable) {
      try {
        print('[Storage] Attempting to save diary to Supabase...');
        await SupabaseService.saveDiaryEntry(entry);
        print('[Storage] Successfully saved diary to Supabase');
        
        // Supabaseに保存成功した場合のみローカルにもキャッシュとして保存
        print('[Storage] Caching diary to local storage...');
        final entries = await _getLocalDiaryEntries();
        
        final existingIndex = entries.indexWhere((e) => e.id == entry.id);
        if (existingIndex != -1) {
          entries[existingIndex] = entry;
        } else {
          entries.add(entry);
        }
        
        entries.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        
        final jsonString = json.encode(entries.map((e) => e.toJson()).toList());
        await prefs.setString(_diaryEntriesKey, jsonString);
        print('[Storage] Successfully cached diary to local storage');
        
      } catch (e) {
        print('[Storage] Error saving diary to Supabase: $e');
        // Supabaseへの保存に失敗した場合は例外を再スロー
        throw Exception('日記の保存に失敗しました。ネットワーク接続を確認してください。\nエラー詳細: $e');
      }
    } else {
      print('[Storage] Supabase not available');
      throw Exception('データベースに接続できません。ネットワーク接続を確認してください。');
    }
  }

  static Future<void> deleteDiaryEntry(String id) async {
    // Supabaseから削除
    if (SupabaseService.isAvailable) {
      try {
        await SupabaseService.deleteDiaryEntry(id);
      } catch (e) {
        print('[Storage] Error deleting from Supabase: $e');
      }
    }

    // ローカルストレージからも削除
    final entries = await _getLocalDiaryEntries();
    entries.removeWhere((e) => e.id == id);
    
    final jsonString = json.encode(entries.map((e) => e.toJson()).toList());
    await prefs.setString(_diaryEntriesKey, jsonString);
  }

  static Future<UserProfile?> getUserProfile() async {
    final jsonString = prefs.getString(_userProfileKey);
    if (jsonString == null) return null;

    final Map<String, dynamic> json = jsonDecode(jsonString);
    return UserProfile.fromJson(json);
  }

  static Future<void> saveUserProfile(UserProfile profile) async {
    final jsonString = json.encode(profile.toJson());
    await prefs.setString(_userProfileKey, jsonString);
  }

  static Future<List<Mission>> getMissions() async {
    final jsonString = prefs.getString(_missionsKey);
    if (jsonString == null) return [];

    final List<dynamic> jsonList = json.decode(jsonString);
    return jsonList.map((json) => Mission.fromJson(json)).toList();
  }

  static Future<void> saveMission(Mission mission) async {
    final missions = await getMissions();
    
    final existingIndex = missions.indexWhere((m) => m.id == mission.id);
    if (existingIndex != -1) {
      missions[existingIndex] = mission;
    } else {
      missions.add(mission);
    }
    
    final jsonString = json.encode(missions.map((m) => m.toJson()).toList());
    await prefs.setString(_missionsKey, jsonString);
  }

  static Future<void> saveMissions(List<Mission> missions) async {
    final jsonString = json.encode(missions.map((m) => m.toJson()).toList());
    await prefs.setString(_missionsKey, jsonString);
  }

  static Future<List<Flashcard>> getFlashcards() async {
    final jsonString = prefs.getString(_flashcardsKey);
    if (jsonString == null) return [];

    final List<dynamic> jsonList = json.decode(jsonString);
    return jsonList.map((json) => Flashcard.fromJson(json)).toList();
  }

  static Future<void> saveFlashcard(Flashcard flashcard) async {
    final flashcards = await getFlashcards();
    
    final existingIndex = flashcards.indexWhere((f) => f.id == flashcard.id);
    if (existingIndex != -1) {
      flashcards[existingIndex] = flashcard;
    } else {
      flashcards.add(flashcard);
    }
    
    final jsonString = json.encode(flashcards.map((f) => f.toJson()).toList());
    await prefs.setString(_flashcardsKey, jsonString);
  }

  static Future<void> saveFlashcards(List<Flashcard> flashcards) async {
    final jsonString = json.encode(flashcards.map((f) => f.toJson()).toList());
    await prefs.setString(_flashcardsKey, jsonString);
  }

  static Future<void> clearAll() async {
    await prefs.clear();
  }

  // ダミーデータのみを削除
  static Future<void> clearSampleData() async {
    // サンプル日記エントリーの削除
    final entries = await getDiaryEntries();
    final filteredEntries = entries.where((entry) => !entry.id.startsWith('sample_')).toList();
    final jsonString = json.encode(filteredEntries.map((e) => e.toJson()).toList());
    await prefs.setString(_diaryEntriesKey, jsonString);
    
    // サンプル単語の削除
    final words = await getWords();
    final filteredWords = words.where((word) => !word.id.startsWith('sample_')).toList();
    final wordsJsonString = json.encode(filteredWords.map((w) => w.toJson()).toList());
    await prefs.setString(_wordsKey, wordsJsonString);
    
    // サンプルデータ初期化フラグをリセット
    await prefs.setBool(_sampleDataKey, false);
  }

  static Future<int> getDiaryStreak() async {
    final entries = await getDiaryEntries();
    if (entries.isEmpty) return 0;

    int streak = 0;
    DateTime currentDate = DateTime.now();
    
    for (final entry in entries) {
      final entryDate = DateTime(entry.createdAt.year, entry.createdAt.month, entry.createdAt.day);
      final checkDate = DateTime(currentDate.year, currentDate.month, currentDate.day);
      
      if (entryDate == checkDate || entryDate == checkDate.subtract(const Duration(days: 1))) {
        streak++;
        currentDate = currentDate.subtract(const Duration(days: 1));
      } else {
        break;
      }
    }
    
    return streak;
  }

  static Future<Map<String, int>> getAnalyticsData() async {
    final entries = await getDiaryEntries();
    final missions = await getMissions();
    final flashcards = await getFlashcards();
    
    final totalWords = entries.fold<int>(0, (sum, entry) => sum + entry.wordCount);
    final completedMissions = missions.where((m) => m.isCompleted).length;
    final learnedWords = flashcards.where((f) => f.isLearned).length;
    final streak = await getDiaryStreak();
    
    return {
      'totalEntries': entries.length,
      'totalWords': totalWords,
      'completedMissions': completedMissions,
      'learnedWords': learnedWords,
      'currentStreak': streak,
    };
  }

  // 単語関連のメソッド
  static Future<List<Word>> getWords() async {
    // デバッグ情報を出力
    print('[Storage] Getting words...');
    print('[Storage] SupabaseService.isAvailable: ${SupabaseService.isAvailable}');
    
    // Supabaseからデータを取得
    List<Word> supabaseWords = [];
    if (SupabaseService.isAvailable) {
      try {
        print('[Storage] Attempting to get words from Supabase...');
        supabaseWords = await SupabaseService.getWords();
        print('[Storage] Got ${supabaseWords.length} words from Supabase');
      } catch (e) {
        print('[Storage] Error getting Supabase words: $e');
      }
    } else {
      print('[Storage] Supabase not available, using local storage only');
    }

    // ローカルデータを取得
    final jsonString = prefs.getString(_wordsKey);
    List<Word> localWords = [];
    if (jsonString != null) {
      final List<dynamic> jsonList = json.decode(jsonString);
      localWords = jsonList.map((json) => Word.fromJson(json)).toList();
      print('[Storage] Got ${localWords.length} words from local storage');
    }

    // Supabaseデータがある場合はそちらを優先、なければローカルデータを使用
    if (supabaseWords.isNotEmpty) {
      // Supabaseデータをローカルにも保存（キャッシュ）
      print('[Storage] Using Supabase data and caching locally');
      final jsonString = json.encode(supabaseWords.map((w) => w.toJson()).toList());
      await prefs.setString(_wordsKey, jsonString);
      return supabaseWords;
    }
    
    print('[Storage] Using local data (${localWords.length} words)');
    return localWords;
  }

  static Future<void> saveWord(Word word) async {
    print('[Storage] Saving word: ${word.english}');
    print('[Storage] SupabaseService.isAvailable: ${SupabaseService.isAvailable}');
    
    // Supabaseに保存（必須）
    if (SupabaseService.isAvailable) {
      try {
        print('[Storage] Attempting to save word to Supabase...');
        await SupabaseService.saveWord(word);
        print('[Storage] Successfully saved word to Supabase');
        
        // Supabaseに保存成功した場合のみローカルにもキャッシュとして保存
        print('[Storage] Caching word to local storage...');
        final words = await _getLocalWords();
        
        final existingIndex = words.indexWhere((w) => w.id == word.id);
        if (existingIndex != -1) {
          words[existingIndex] = word;
          print('[Storage] Updated existing word in local cache');
        } else {
          words.add(word);
          print('[Storage] Added new word to local cache');
        }
        
        final jsonString = json.encode(words.map((w) => w.toJson()).toList());
        await prefs.setString(_wordsKey, jsonString);
        print('[Storage] Successfully cached word to local storage. Total: ${words.length}');
        
      } catch (e) {
        print('[Storage] Error saving word to Supabase: $e');
        // Supabaseへの保存に失敗した場合は例外を再スロー
        throw Exception('単語の保存に失敗しました。ネットワーク接続を確認してください。\nエラー詳細: $e');
      }
    } else {
      print('[Storage] Supabase not available');
      throw Exception('データベースに接続できません。ネットワーク接続を確認してください。');
    }
  }

  static Future<void> saveWords(List<Word> words) async {
    // Supabaseに保存
    if (SupabaseService.isAvailable) {
      try {
        await SupabaseService.saveWords(words);
      } catch (e) {
        print('[Storage] Error saving words to Supabase: $e');
      }
    }

    // ローカルストレージにも保存
    final jsonString = json.encode(words.map((w) => w.toJson()).toList());
    await prefs.setString(_wordsKey, jsonString);
  }

  static Future<void> deleteWord(String id) async {
    // Supabaseから削除
    if (SupabaseService.isAvailable) {
      try {
        await SupabaseService.deleteWord(id);
      } catch (e) {
        print('[Storage] Error deleting word from Supabase: $e');
      }
    }

    // ローカルストレージからも削除
    final words = await _getLocalWords();
    words.removeWhere((w) => w.id == id);
    
    final jsonString = json.encode(words.map((w) => w.toJson()).toList());
    await prefs.setString(_wordsKey, jsonString);
  }
  
  static Future<void> deleteJapaneseWords() async {
    final words = await getWords();
    // 日本語の文字（ひらがな、カタカナ、漢字）を含む単語を削除
    final japanesePattern = RegExp(r'[\u3040-\u309F\u30A0-\u30FF\u4E00-\u9FAF]');
    words.removeWhere((w) => japanesePattern.hasMatch(w.english));
    
    final jsonString = json.encode(words.map((w) => w.toJson()).toList());
    await prefs.setString(_wordsKey, jsonString);
  }
  
  static Future<void> deletePhrases() async {
    final words = await getWords();
    // スペースを含む（複数語の）熟語を削除
    words.removeWhere((w) => w.english.trim().contains(' '));
    
    // 更新されたリストを保存
    await saveWords(words);
  }

  static Future<List<Word>> getWordsByDiaryEntry(String diaryEntryId) async {
    final words = await getWords();
    return words.where((w) => w.diaryEntryId == diaryEntryId).toList();
  }

  // ローカルデータのみを取得するヘルパーメソッド
  static Future<List<DiaryEntry>> _getLocalDiaryEntries() async {
    final jsonString = prefs.getString(_diaryEntriesKey);
    if (jsonString == null) return [];

    final List<dynamic> jsonList = json.decode(jsonString);
    return jsonList.map((json) => DiaryEntry.fromJson(json)).toList();
  }

  static Future<List<Word>> _getLocalWords() async {
    final jsonString = prefs.getString(_wordsKey);
    if (jsonString == null) return [];

    final List<dynamic> jsonList = json.decode(jsonString);
    return jsonList.map((json) => Word.fromJson(json)).toList();
  }

  static Future<void> updateWordReview(String wordId, {required int masteryLevel}) async {
    final words = await getWords();
    final index = words.indexWhere((w) => w.id == wordId);
    
    if (index != -1) {
      final word = words[index];
      final updatedWord = word.copyWith(
        reviewCount: word.reviewCount + 1,
        lastReviewedAt: DateTime.now(),
        isMastered: masteryLevel == 2, // Keep backward compatibility
        masteryLevel: masteryLevel,
      );
      
      // 更新された単語を保存
      await saveWord(updatedWord);
    }
  }

  // サンプルデータの初期化
  static Future<void> initializeSampleData() async {
    final bool isInitialized = prefs.getBool(_sampleDataKey) ?? false;
    if (isInitialized) return;

    // サンプル単語データ
    final sampleWords = <Word>[
      // 単語
      Word(
        id: 'sample_1',
        english: 'amazing',
        japanese: '素晴らしい',
        example: 'The view from the mountain was amazing.',
        diaryEntryId: 'sample_diary_1',
        createdAt: DateTime.now().subtract(const Duration(days: 3)),
        reviewCount: 2,
        isMastered: false,
        masteryLevel: 1, // △
      ),
      Word(
        id: 'sample_2',
        english: 'journey',
        japanese: '旅',
        example: 'Life is a journey, not a destination.',
        diaryEntryId: 'sample_diary_1',
        createdAt: DateTime.now().subtract(const Duration(days: 3)),
        reviewCount: 1,
        isMastered: false,
        masteryLevel: 0, // ×
      ),
      // フレーズ
      Word(
        id: 'sample_3',
        english: 'look forward to',
        japanese: '〜を楽しみにする',
        example: 'I look forward to hearing from you.',
        diaryEntryId: 'sample_diary_2',
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
        reviewCount: 3,
        isMastered: true,
        masteryLevel: 2, // ○
      ),
      Word(
        id: 'sample_4',
        english: 'peaceful',
        japanese: '穏やかな',
        diaryEntryId: 'sample_diary_2',
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
        reviewCount: 0,
        isMastered: false,
        masteryLevel: 0, // ×
      ),
      // 慣用句
      Word(
        id: 'sample_5',
        english: 'break the ice',
        japanese: '緊張をほぐす、打ち解ける',
        example: 'He told a joke to break the ice.',
        diaryEntryId: 'sample_diary_3',
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
        reviewCount: 5,
        isMastered: true,
        masteryLevel: 2, // ○
      ),
      Word(
        id: 'sample_6',
        english: 'appreciate',
        japanese: '感謝する',
        diaryEntryId: 'sample_diary_3',
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
        reviewCount: 1,
        isMastered: false,
        masteryLevel: 1, // △
      ),
      // フレーズ
      Word(
        id: 'sample_7',
        english: 'make the most of',
        japanese: '〜を最大限に活用する',
        example: 'We should make the most of this opportunity.',
        diaryEntryId: 'sample_diary_4',
        createdAt: DateTime.now(),
        reviewCount: 4,
        isMastered: true,
        masteryLevel: 2, // ○
      ),
      Word(
        id: 'sample_8',
        english: 'accomplish',
        japanese: '達成する',
        diaryEntryId: 'sample_diary_4',
        createdAt: DateTime.now(),
        reviewCount: 0,
        isMastered: false,
        masteryLevel: 0, // ×
      ),
      // 追加のフレーズと慣用句
      Word(
        id: 'sample_9',
        english: 'once in a blue moon',
        japanese: 'めったに〜ない',
        example: 'I only eat junk food once in a blue moon.',
        diaryEntryId: 'sample_diary_1',
        createdAt: DateTime.now().subtract(const Duration(days: 3)),
        reviewCount: 2,
        isMastered: false,
        masteryLevel: 1, // △
      ),
      Word(
        id: 'sample_10',
        english: 'take it easy',
        japanese: 'のんびりする、無理をしない',
        example: 'You should take it easy this weekend.',
        diaryEntryId: 'sample_diary_2',
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
        reviewCount: 6,
        isMastered: true,
        masteryLevel: 2, // ○
      ),
    ];

    // サンプル日記データ
    final sampleDiaries = <DiaryEntry>[
      DiaryEntry(
        id: 'sample_diary_1',
        title: 'My First Day in Tokyo',
        content: 'Today was an amazing journey through Tokyo. I discovered many interesting places and met friendly people.',
        translatedContent: '今日は東京を巡る素晴らしい旅でした。たくさんの興味深い場所を発見し、親切な人々に出会いました。',
        createdAt: DateTime.now().subtract(const Duration(days: 3)),
        updatedAt: DateTime.now().subtract(const Duration(days: 3)),
        wordCount: 16,
        learnedWords: ['amazing', 'journey'],
      ),
      DiaryEntry(
        id: 'sample_diary_2',
        title: 'A Peaceful Morning',
        content: 'I woke up early and enjoyed a peaceful morning in the park. The weather was perfect for walking.',
        translatedContent: '早起きして公園で穏やかな朝を楽しみました。散歩に最適な天気でした。',
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
        updatedAt: DateTime.now().subtract(const Duration(days: 2)),
        wordCount: 17,
        learnedWords: ['discover', 'peaceful'],
      ),
      DiaryEntry(
        id: 'sample_diary_3',
        title: 'Learning Japanese Culture',
        content: 'Today I had a wonderful experience learning about Japanese culture. I really appreciate the kindness of my teachers.',
        translatedContent: '今日は日本文化について学ぶ素晴らしい経験をしました。先生方の親切さに本当に感謝しています。',
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
        updatedAt: DateTime.now().subtract(const Duration(days: 1)),
        wordCount: 17,
        learnedWords: ['experience', 'appreciate'],
      ),
      DiaryEntry(
        id: 'sample_diary_4',
        title: 'A Challenging Day',
        content: 'Today was challenging but I managed to accomplish all my tasks. I feel proud of my progress.',
        translatedContent: '今日は挑戦的な一日でしたが、すべてのタスクを達成することができました。自分の進歩を誇りに思います。',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        wordCount: 16,
        learnedWords: ['challenging', 'accomplish'],
      ),
    ];

    // データを保存
    await saveWords(sampleWords);
    await prefs.setString(_diaryEntriesKey, json.encode(sampleDiaries.map((e) => e.toJson()).toList()));
    await prefs.setBool(_sampleDataKey, true);
  }
}