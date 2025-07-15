import 'package:supabase_flutter/supabase_flutter.dart';

class WordCacheService {
  static final _supabase = Supabase.instance.client;
  
  // キャッシュされた単語を検索
  static Future<Map<String, dynamic>?> fetchCachedWord(String jaWord) async {
    try {
      final response = await _supabase
          .from('word_cache')
          .select('ja_word, en_word, definition, source')
          .eq('ja_word', jaWord.trim())
          .maybeSingle();
      
      if (response != null) {
        print('[WordCacheService] Cache hit for: $jaWord');
        return {
          'ja_word': response['ja_word'],
          'en_word': response['en_word'],
          'definition': response['definition'],
          'source': response['source'],
        };
      }
      
      print('[WordCacheService] Cache miss for: $jaWord');
      return null;
    } catch (e) {
      print('[WordCacheService] Error fetching cached word: $e');
      return null;
    }
  }
  
  // 翻訳結果をキャッシュに保存
  static Future<bool> cacheWordTranslation({
    required String jaWord,
    required String enWord,
    String? definition,
    String source = 'wordnet',
  }) async {
    try {
      await _supabase
          .from('word_cache')
          .upsert({
            'ja_word': jaWord.trim(),
            'en_word': enWord.trim(),
            'definition': definition?.trim(),
            'source': source,
          }, 
          onConflict: 'ja_word',
          ignoreDuplicates: false,
        );
      
      print('[WordCacheService] Cached translation: $jaWord -> $enWord');
      return true;
    } catch (e) {
      print('[WordCacheService] Error caching translation: $e');
      return false;
    }
  }
  
  // 複数の単語を一括で検索
  static Future<Map<String, Map<String, dynamic>>> fetchCachedWords(List<String> jaWords) async {
    try {
      final cleanedWords = jaWords.map((word) => word.trim()).toList();
      
      final response = await _supabase
          .from('word_cache')
          .select('ja_word, en_word, definition, source')
          .inFilter('ja_word', cleanedWords);
      
      final Map<String, Map<String, dynamic>> cachedWords = {};
      
      for (final row in response) {
        cachedWords[row['ja_word']] = {
          'en_word': row['en_word'],
          'definition': row['definition'],
          'source': row['source'],
        };
      }
      
      print('[WordCacheService] Batch cache hit: ${cachedWords.length}/${jaWords.length} words');
      return cachedWords;
    } catch (e) {
      print('[WordCacheService] Error fetching cached words batch: $e');
      return {};
    }
  }
  
  // 最近キャッシュされた単語を取得（デバッグ用）
  static Future<List<Map<String, dynamic>>> getRecentCachedWords({int limit = 10}) async {
    try {
      final response = await _supabase
          .from('word_cache')
          .select('*')
          .order('created_at', ascending: false)
          .limit(limit);
      
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('[WordCacheService] Error fetching recent cached words: $e');
      return [];
    }
  }
  
  // キャッシュの統計情報を取得
  static Future<int> getCacheCount() async {
    try {
      final response = await _supabase
          .from('word_cache')
          .select('id');
      
      return (response as List).length;
    } catch (e) {
      print('[WordCacheService] Error getting cache count: $e');
      return 0;
    }
  }
}