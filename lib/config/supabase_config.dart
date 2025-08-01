class SupabaseConfig {
  // Supabaseのプロジェクト設定
  // これらの値は環境変数またはビルド時に設定します
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: '', // SupabaseプロジェクトのURLを設定
  );
  
  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: '', // Supabaseのanon keyを設定
  );
  
  // 設定が有効かどうかをチェック
  static bool get isConfigured => 
    supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;
  
  // デバッグ情報を出力
  static void printDebugInfo() {
    print('[SupabaseConfig] Debug info:');
    print('[SupabaseConfig] URL: ${supabaseUrl.isNotEmpty ? "SET (${supabaseUrl.length} chars)" : "NOT SET"}');
    print('[SupabaseConfig] Anon Key: ${supabaseAnonKey.isNotEmpty ? "SET (${supabaseAnonKey.length} chars)" : "NOT SET"}');
    print('[SupabaseConfig] Is configured: $isConfigured');
  }
}