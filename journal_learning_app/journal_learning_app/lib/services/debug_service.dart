import 'supabase_service.dart';

class DebugService {
  // デバッグモードのフラグ
  static bool _showAllEntries = false;
  
  static bool get showAllEntries => _showAllEntries;
  
  static void toggleShowAllEntries() {
    _showAllEntries = !_showAllEntries;
    print('[Debug] Show all entries: $_showAllEntries');
  }
  
  // 全てのエントリを取得（ユーザーIDフィルタなし）
  static Future<List<dynamic>> getAllDiaryEntries() async {
    if (!SupabaseService.isAvailable) {
      print('[Debug] Supabase not available');
      return [];
    }
    
    try {
      final response = await SupabaseService.client!
          .from('diary_entries')
          .select()
          .order('created_at', ascending: false);
      
      print('[Debug] Total entries without user filter: ${response.length}');
      return response;
    } catch (e) {
      print('[Debug] Error getting all entries: $e');
      return [];
    }
  }
  
  // 全てのユーザーIDを取得
  static Future<Set<String>> getAllUserIds() async {
    if (!SupabaseService.isAvailable) {
      return {};
    }
    
    try {
      final response = await SupabaseService.client!
          .from('diary_entries')
          .select('user_id');
      
      final userIds = <String>{};
      for (final entry in response) {
        if (entry['user_id'] != null) {
          userIds.add(entry['user_id'] as String);
        }
      }
      
      print('[Debug] Found ${userIds.length} unique user IDs: $userIds');
      return userIds;
    } catch (e) {
      print('[Debug] Error getting user IDs: $e');
      return {};
    }
  }
}