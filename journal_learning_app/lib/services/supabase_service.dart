import 'dart:math' as math;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';
import '../models/diary_entry.dart';
import '../models/word.dart';

class SupabaseService {
  static SupabaseClient? _client;
  static bool _initialized = false;
  
  // Supabaseクライアントの初期化
  static Future<void> initialize() async {
    if (_initialized) {
      print('[Supabase] Already initialized');
      return;
    }
    
    print('[Supabase] Checking configuration...');
    print('[Supabase] URL configured: ${SupabaseConfig.supabaseUrl.isNotEmpty}');
    print('[Supabase] Anon key configured: ${SupabaseConfig.supabaseAnonKey.isNotEmpty}');
    
    if (!SupabaseConfig.isConfigured) {
      print('[Supabase] Not configured. SUPABASE_URL and SUPABASE_ANON_KEY environment variables are required.');
      print('[Supabase] Skipping initialization - app will run without Supabase features');
      return;
    }
    
    try {
      print('[Supabase] Initializing with URL: ${SupabaseConfig.supabaseUrl.substring(0, math.min(30, SupabaseConfig.supabaseUrl.length))}...');
      await Supabase.initialize(
        url: SupabaseConfig.supabaseUrl,
        anonKey: SupabaseConfig.supabaseAnonKey,
        debug: false, // デバッグモードを無効化
        authOptions: const FlutterAuthClientOptions(
          authFlowType: AuthFlowType.pkce,
          autoRefreshToken: true,
        ),
      );
      
      _client = Supabase.instance.client;
      _initialized = true;
      print('[Supabase] Initialized successfully');
    } catch (e, stack) {
      print('[Supabase] Initialization error: $e');
      print('[Supabase] Stack trace:\n$stack');
      // エラーを再スローせず、アプリは続行
      _initialized = false;
      _client = null;
    }
  }
  
  // クライアントの取得
  static SupabaseClient? get client => _client;
  
  // 翻訳キャッシュの保存
  static Future<void> saveTranslationCache({
    required String userId,
    required String diaryEntryId,
    required String originalText,
    required String translatedText,
    required String correctedText,
    required List<String> improvements,
    required String detectedLanguage,
    required String targetLanguage,
  }) async {
    if (_client == null) {
      print('Supabase client not initialized');
      return;
    }
    
    try {
      await _client!.from('translation_cache').upsert({
        'user_id': userId,
        'diary_entry_id': diaryEntryId,
        'original_text': originalText,
        'translated_text': translatedText,
        'corrected_text': correctedText,
        'improvements': improvements,
        'detected_language': detectedLanguage,
        'target_language': targetLanguage,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      }, onConflict: 'diary_entry_id');
      
      print('Translation cache saved successfully');
    } catch (e) {
      print('Error saving translation cache: $e');
    }
  }
  
  // 翻訳キャッシュの取得
  static Future<Map<String, dynamic>?> getTranslationCache({
    required String diaryEntryId,
  }) async {
    if (_client == null) {
      print('Supabase client not initialized');
      return null;
    }
    
    try {
      final response = await _client!
          .from('translation_cache')
          .select()
          .eq('diary_entry_id', diaryEntryId)
          .single();
      
      return response;
    } catch (e) {
      print('Error getting translation cache: $e');
      return null;
    }
  }
  
  // ユーザーの翻訳履歴を取得
  static Future<List<Map<String, dynamic>>> getUserTranslationHistory({
    required String userId,
    int limit = 50,
  }) async {
    if (_client == null) {
      print('Supabase client not initialized');
      return [];
    }
    
    try {
      final response = await _client!
          .from('translation_cache')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .limit(limit);
      
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error getting translation history: $e');
      return [];
    }
  }

  // ユーザーIDを取得（匿名認証を使用）
  static Future<String> getUserId() async {
    if (_client == null) {
      print('[Supabase] Client not initialized');
      return 'local_user';
    }

    try {
      final session = _client!.auth.currentSession;
      if (session != null) {
        return session.user.id;
      }

      // 匿名サインイン
      print('[Supabase] Signing in anonymously...');
      final response = await _client!.auth.signInAnonymously();
      return response.user?.id ?? 'local_user';
    } catch (e) {
      print('[Supabase] Error getting user ID: $e');
      return 'local_user';
    }
  }

  // === 日記データの同期 ===
  
  // 日記を保存
  static Future<void> saveDiaryEntry(DiaryEntry entry) async {
    if (_client == null) {
      print('[Supabase] Client not initialized, skipping diary save');
      return;
    }

    try {
      final userId = await getUserId();
      
      await _client!.from('diary_entries').upsert({
        'id': entry.id,
        'user_id': userId,
        'title': entry.title,
        'content': entry.content,
        'translated_content': entry.translatedContent,
        'word_count': entry.wordCount,
        'learned_words': entry.learnedWords,
        'created_at': entry.createdAt.toIso8601String(),
        'updated_at': entry.updatedAt.toIso8601String(),
      }, onConflict: 'id');
      
      print('[Supabase] Diary entry saved: ${entry.id}');
    } catch (e) {
      print('[Supabase] Error saving diary entry: $e');
    }
  }

  // 日記一覧を取得
  static Future<List<DiaryEntry>> getDiaryEntries() async {
    if (_client == null) {
      print('[Supabase] Client not initialized, returning empty list');
      return [];
    }

    try {
      final userId = await getUserId();
      
      final response = await _client!
          .from('diary_entries')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);
      
      final List<DiaryEntry> entries = [];
      for (final data in response) {
        try {
          entries.add(DiaryEntry.fromJson(data));
        } catch (e) {
          print('[Supabase] Error parsing diary entry: $e');
        }
      }
      
      print('[Supabase] Retrieved ${entries.length} diary entries');
      return entries;
    } catch (e) {
      print('[Supabase] Error getting diary entries: $e');
      return [];
    }
  }

  // 日記を削除
  static Future<void> deleteDiaryEntry(String entryId) async {
    if (_client == null) {
      print('[Supabase] Client not initialized, skipping diary delete');
      return;
    }

    try {
      await _client!.from('diary_entries').delete().eq('id', entryId);
      print('[Supabase] Diary entry deleted: $entryId');
    } catch (e) {
      print('[Supabase] Error deleting diary entry: $e');
    }
  }

  // === 単語データの同期 ===
  
  // 単語を保存
  static Future<void> saveWord(Word word) async {
    if (_client == null) {
      print('[Supabase] Client not initialized, skipping word save');
      return;
    }

    try {
      final userId = await getUserId();
      
      await _client!.from('words').upsert({
        'id': word.id,
        'user_id': userId,
        'english': word.english,
        'japanese': word.japanese,
        'example': word.example,
        'diary_entry_id': word.diaryEntryId,
        'review_count': word.reviewCount,
        'last_reviewed_at': word.lastReviewedAt?.toIso8601String(),
        'is_mastered': word.isMastered,
        'mastery_level': word.masteryLevel,
        'category': word.category.name,
        'created_at': word.createdAt.toIso8601String(),
      }, onConflict: 'id');
      
      print('[Supabase] Word saved: ${word.english}');
    } catch (e) {
      print('[Supabase] Error saving word: $e');
    }
  }

  // 単語一覧を取得
  static Future<List<Word>> getWords() async {
    if (_client == null) {
      print('[Supabase] Client not initialized, returning empty list');
      return [];
    }

    try {
      final userId = await getUserId();
      
      final response = await _client!
          .from('words')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);
      
      final List<Word> words = [];
      for (final data in response) {
        try {
          words.add(Word.fromJson(data));
        } catch (e) {
          print('[Supabase] Error parsing word: $e');
        }
      }
      
      print('[Supabase] Retrieved ${words.length} words');
      return words;
    } catch (e) {
      print('[Supabase] Error getting words: $e');
      return [];
    }
  }

  // 単語を削除
  static Future<void> deleteWord(String wordId) async {
    if (_client == null) {
      print('[Supabase] Client not initialized, skipping word delete');
      return;
    }

    try {
      await _client!.from('words').delete().eq('id', wordId);
      print('[Supabase] Word deleted: $wordId');
    } catch (e) {
      print('[Supabase] Error deleting word: $e');
    }
  }

  // 複数の単語を一括保存
  static Future<void> saveWords(List<Word> words) async {
    if (_client == null || words.isEmpty) {
      print('[Supabase] Client not initialized or no words to save');
      return;
    }

    try {
      final userId = await getUserId();
      
      final wordsData = words.map((word) => {
        'id': word.id,
        'user_id': userId,
        'english': word.english,
        'japanese': word.japanese,
        'example': word.example,
        'diary_entry_id': word.diaryEntryId,
        'review_count': word.reviewCount,
        'last_reviewed_at': word.lastReviewedAt?.toIso8601String(),
        'is_mastered': word.isMastered,
        'mastery_level': word.masteryLevel,
        'category': word.category.name,
        'created_at': word.createdAt.toIso8601String(),
      }).toList();
      
      await _client!.from('words').upsert(wordsData, onConflict: 'id');
      print('[Supabase] ${words.length} words saved');
    } catch (e) {
      print('[Supabase] Error saving words: $e');
    }
  }

  // データ同期状態を確認
  static bool get isAvailable => _client != null && _initialized;
}