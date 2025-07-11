// このファイルは一時的なテスト用です。本番では使用しないでください。

class SupabaseConfigHardcoded {
  // Vercelの環境変数が読み込めない場合のフォールバック
  // 実際の値はVercelの環境変数から取得すべきです
  static const String supabaseUrl = ''; // ここに実際のURLを入れてテスト
  static const String supabaseAnonKey = ''; // ここに実際のキーを入れてテスト
  
  static bool get isConfigured => 
    supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;
}