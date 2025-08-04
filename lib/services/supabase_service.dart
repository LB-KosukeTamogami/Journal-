import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/diary_entry.dart';
import '../models/word.dart';
import '../config/supabase_config.dart';

class SupabaseService {
  static SupabaseClient? _client;
  static bool _isInitialized = false;
  static bool _isAvailable = false;

  static bool get isInitialized => _isInitialized;
  static bool get isAvailable => _isAvailable && _client != null;
  static SupabaseClient? get client => _client;

  static Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      print('[SupabaseService] Starting initialization...');
      
      // 設定の確認
      if (!SupabaseConfig.isConfigured) {
        print('[SupabaseService] Supabase is not configured. Running in offline mode.');
        _isInitialized = true;
        _isAvailable = false;
        return;
      }

      // Supabaseの初期化
      await Supabase.initialize(
        url: SupabaseConfig.supabaseUrl,
        anonKey: SupabaseConfig.supabaseAnonKey,
      );

      _client = Supabase.instance.client;
      _isInitialized = true;

      // 接続テスト
      print('[SupabaseService] Testing connection...');
      final response = await _client!
          .from('diary_entries')
          .select('id')
          .limit(1);
      
      print('[SupabaseService] Connection test successful');
      _isAvailable = true;
    } catch (e) {
      print('[SupabaseService] Initialization error: $e');
      _isInitialized = true;
      _isAvailable = false;
    }
  }
  
  // ユーザーIDを取得
  static String getUserId() {
    if (_isAvailable && _client != null) {
      final user = _client!.auth.currentUser;
      if (user != null) {
        return user.id;
      }
    }
    return 'anonymous_user';
  }

  // 日記エントリーの取得
  static Future<List<DiaryEntry>> getDiaryEntries() async {
    if (!isAvailable) {
      print('[SupabaseService] Not available, returning empty list');
      return [];
    }

    try {
      final response = await _client!
          .from('diary_entries')
          .select()
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => DiaryEntry.fromSupabase(json))
          .toList();
    } catch (e) {
      print('[SupabaseService] Error getting diary entries: $e');
      return [];
    }
  }

  // 日記エントリーの保存
  static Future<void> saveDiaryEntry(DiaryEntry entry) async {
    if (!isAvailable) {
      throw Exception('Supabase is not available');
    }

    try {
      await _client!
          .from('diary_entries')
          .upsert(entry.toSupabase());
    } catch (e) {
      print('[SupabaseService] Error saving diary entry: $e');
      throw e;
    }
  }

  // 日記エントリーの削除
  static Future<void> deleteDiaryEntry(String id) async {
    if (!isAvailable) {
      throw Exception('Supabase is not available');
    }

    try {
      await _client!
          .from('diary_entries')
          .delete()
          .eq('id', id);
    } catch (e) {
      print('[SupabaseService] Error deleting diary entry: $e');
      throw e;
    }
  }

  // 単語の取得
  static Future<List<Word>> getWords() async {
    if (!isAvailable) {
      print('[SupabaseService] Not available, returning empty list');
      return [];
    }

    try {
      final response = await _client!
          .from('words')
          .select()
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => Word.fromSupabase(json))
          .toList();
    } catch (e) {
      print('[SupabaseService] Error getting words: $e');
      return [];
    }
  }

  // 単語の保存
  static Future<void> saveWord(Word word) async {
    if (!isAvailable) {
      throw Exception('Supabase is not available');
    }

    try {
      await _client!
          .from('words')
          .upsert(word.toSupabase());
    } catch (e) {
      print('[SupabaseService] Error saving word: $e');
      throw e;
    }
  }

  // 単語の削除
  static Future<void> deleteWord(String id) async {
    if (!isAvailable) {
      throw Exception('Supabase is not available');
    }

    try {
      await _client!
          .from('words')
          .delete()
          .eq('id', id);
    } catch (e) {
      print('[SupabaseService] Error deleting word: $e');
      throw e;
    }
  }

  // 翻訳キャッシュの保存
  static Future<void> saveTranslationCache({
    required String diaryEntryId,
    required String translatedText,
    String? correctedText,
    List<String>? improvements,
    String? judgment,
    List<String>? learnedPhrases,
    List<Map<String, String>>? extractedWords,
    List<Map<String, String>>? learnedWords,
  }) async {
    if (!isAvailable) return;

    try {
      await _client!.from('translation_cache').upsert({
        'diary_entry_id': diaryEntryId,
        'translated_text': translatedText,
        'corrected_text': correctedText,
        'improvements': improvements,
        'judgment': judgment,
        'learned_phrases': learnedPhrases,
        'extracted_words': extractedWords,
        'learned_words': learnedWords,
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      print('[SupabaseService] Error saving translation cache: $e');
    }
  }

  // 翻訳キャッシュの取得
  static Future<Map<String, dynamic>?> getTranslationCache(String diaryEntryId) async {
    if (!isAvailable) return null;

    try {
      final response = await _client!
          .from('translation_cache')
          .select()
          .eq('diary_entry_id', diaryEntryId)
          .single();

      return response;
    } catch (e) {
      print('[SupabaseService] Error getting translation cache: $e');
      return null;
    }
  }
}