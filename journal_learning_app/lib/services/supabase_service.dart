import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';

class SupabaseService {
  static SupabaseClient? _client;
  static bool _initialized = false;
  
  // Supabaseクライアントの初期化
  static Future<void> initialize() async {
    if (_initialized) {
      return;
    }
    
    if (!SupabaseConfig.isConfigured) {
      print('Supabase is not configured. SUPABASE_URL and SUPABASE_ANON_KEY environment variables are required.');
      return;
    }
    
    try {
      await Supabase.initialize(
        url: SupabaseConfig.supabaseUrl,
        anonKey: SupabaseConfig.supabaseAnonKey,
      );
      
      _client = Supabase.instance.client;
      _initialized = true;
      print('Supabase initialized successfully');
    } catch (e) {
      print('Supabase initialization error: $e');
      throw e; // エラーを再スローして上位でキャッチできるようにする
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
}