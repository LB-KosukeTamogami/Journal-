import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class WordCacheService {
  static const String _cacheKey = 'word_translation_cache';
  static const int _maxCacheSize = 1000;
  static const Duration _cacheExpiry = Duration(days: 30);

  // キャッシュされた単語を取得
  static Future<Map<String, dynamic>?> fetchCachedWord(String word) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheJson = prefs.getString(_cacheKey);
      
      if (cacheJson == null) return null;
      
      final cache = Map<String, dynamic>.from(jsonDecode(cacheJson));
      final wordLower = word.toLowerCase();
      
      if (cache.containsKey(wordLower)) {
        final entry = Map<String, dynamic>.from(cache[wordLower]);
        final cachedAt = DateTime.parse(entry['cachedAt']);
        
        // キャッシュの有効期限チェック
        if (DateTime.now().difference(cachedAt) < _cacheExpiry) {
          return entry;
        } else {
          // 期限切れの場合は削除
          cache.remove(wordLower);
          await _saveCache(cache);
        }
      }
      
      return null;
    } catch (e) {
      print('[WordCacheService] Error fetching cached word: $e');
      return null;
    }
  }

  // 単語の翻訳をキャッシュ
  static Future<void> cacheWordTranslation({
    required String jaWord,
    required String enWord,
    String? definition,
    String? source,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheJson = prefs.getString(_cacheKey);
      
      final cache = cacheJson != null 
          ? Map<String, dynamic>.from(jsonDecode(cacheJson))
          : <String, dynamic>{};
      
      // キャッシュサイズ制限
      if (cache.length >= _maxCacheSize) {
        // 古いエントリを削除
        final entries = cache.entries.toList()
          ..sort((a, b) {
            final aTime = DateTime.parse(a.value['cachedAt']);
            final bTime = DateTime.parse(b.value['cachedAt']);
            return aTime.compareTo(bTime);
          });
        
        // 古い順に20%削除
        final removeCount = (_maxCacheSize * 0.2).floor();
        for (int i = 0; i < removeCount && i < entries.length; i++) {
          cache.remove(entries[i].key);
        }
      }
      
      // 新しいエントリを追加
      cache[jaWord.toLowerCase()] = {
        'ja_word': jaWord,
        'en_word': enWord,
        'definition': definition,
        'source': source,
        'cachedAt': DateTime.now().toIso8601String(),
      };
      
      await _saveCache(cache);
    } catch (e) {
      print('[WordCacheService] Error caching word translation: $e');
    }
  }

  // 複数単語の一括キャッシュ
  static Future<void> batchCacheWords(List<Map<String, String>> words) async {
    for (final word in words) {
      await cacheWordTranslation(
        jaWord: word['japanese'] ?? '',
        enWord: word['english'] ?? '',
        definition: word['definition'],
        source: word['source'] ?? 'gemini',
      );
    }
  }

  // キャッシュのクリア
  static Future<void> clearCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_cacheKey);
    } catch (e) {
      print('[WordCacheService] Error clearing cache: $e');
    }
  }

  // キャッシュ統計情報の取得
  static Future<Map<String, dynamic>> getCacheStats() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheJson = prefs.getString(_cacheKey);
      
      if (cacheJson == null) {
        return {
          'totalWords': 0,
          'cacheSize': 0,
          'oldestEntry': null,
          'newestEntry': null,
        };
      }
      
      final cache = Map<String, dynamic>.from(jsonDecode(cacheJson));
      
      if (cache.isEmpty) {
        return {
          'totalWords': 0,
          'cacheSize': cacheJson.length,
          'oldestEntry': null,
          'newestEntry': null,
        };
      }
      
      DateTime? oldest;
      DateTime? newest;
      
      for (final entry in cache.values) {
        final cachedAt = DateTime.parse(entry['cachedAt']);
        if (oldest == null || cachedAt.isBefore(oldest)) {
          oldest = cachedAt;
        }
        if (newest == null || cachedAt.isAfter(newest)) {
          newest = cachedAt;
        }
      }
      
      return {
        'totalWords': cache.length,
        'cacheSize': cacheJson.length,
        'oldestEntry': oldest?.toIso8601String(),
        'newestEntry': newest?.toIso8601String(),
      };
    } catch (e) {
      print('[WordCacheService] Error getting cache stats: $e');
      return {
        'totalWords': 0,
        'cacheSize': 0,
        'oldestEntry': null,
        'newestEntry': null,
      };
    }
  }

  // キャッシュの保存
  static Future<void> _saveCache(Map<String, dynamic> cache) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_cacheKey, jsonEncode(cache));
  }

  // 期限切れエントリの削除
  static Future<void> cleanExpiredEntries() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheJson = prefs.getString(_cacheKey);
      
      if (cacheJson == null) return;
      
      final cache = Map<String, dynamic>.from(jsonDecode(cacheJson));
      final now = DateTime.now();
      final keysToRemove = <String>[];
      
      cache.forEach((key, value) {
        final cachedAt = DateTime.parse(value['cachedAt']);
        if (now.difference(cachedAt) > _cacheExpiry) {
          keysToRemove.add(key);
        }
      });
      
      if (keysToRemove.isNotEmpty) {
        for (final key in keysToRemove) {
          cache.remove(key);
        }
        await _saveCache(cache);
        print('[WordCacheService] Removed ${keysToRemove.length} expired entries');
      }
    } catch (e) {
      print('[WordCacheService] Error cleaning expired entries: $e');
    }
  }
}