import 'package:shared_preferences/shared_preferences.dart';
import 'supabase_service.dart';
import '../models/diary_entry.dart';

class DebugService {
  static const String _debugModeKey = 'debug_mode_enabled';
  
  static Future<bool> isDebugMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_debugModeKey) ?? false;
  }
  
  static Future<void> setDebugMode(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_debugModeKey, enabled);
  }
  
  static void log(String message) {
    if (const bool.fromEnvironment('dart.vm.product')) {
      return; // Don't log in production
    }
    print('[DEBUG] $message');
  }
  
  // Debug methods for supabase status screen
  static Future<List<String>> getAllUserIds() async {
    try {
      if (!SupabaseService.isAvailable || SupabaseService.client == null) {
        return ['anonymous_user'];
      }
      
      // Get all unique user IDs from diary_entries table
      final response = await SupabaseService.client!
          .from('diary_entries')
          .select('user_id')
          .order('created_at', ascending: false);
      
      if (response == null || response.isEmpty) {
        return ['anonymous_user'];
      }
      
      // Extract unique user IDs
      final Set<String> userIds = {};
      for (final entry in response) {
        if (entry['user_id'] != null) {
          userIds.add(entry['user_id'].toString());
        }
      }
      
      return userIds.toList();
    } catch (e) {
      log('Error getting all user IDs: $e');
      return ['anonymous_user'];
    }
  }
  
  static Future<List<DiaryEntry>> getAllDiaryEntries() async {
    try {
      if (!SupabaseService.isAvailable || SupabaseService.client == null) {
        return [];
      }
      
      // Get all diary entries from database
      final response = await SupabaseService.client!
          .from('diary_entries')
          .select()
          .order('created_at', ascending: false);
      
      if (response == null || response.isEmpty) {
        return [];
      }
      
      // Convert to DiaryEntry objects
      return response.map<DiaryEntry>((json) => DiaryEntry.fromJson(json)).toList();
    } catch (e) {
      log('Error getting all diary entries: $e');
      return [];
    }
  }
}