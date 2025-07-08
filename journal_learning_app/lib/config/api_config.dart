// API設定ファイル
// 本番環境では環境変数やセキュアストレージから読み込んでください

class ApiConfig {
  // 環境変数からAPIキーを取得
  static String getGroqApiKey() {
    // 環境変数から読み込む
    const envKey = String.fromEnvironment('GROQ_API_KEY');
    if (envKey.isNotEmpty) {
      return envKey;
    }
    
    // デフォルト（テスト用）
    // 本番環境では必ず環境変数 GROQ_API_KEY を設定してください
    throw Exception('GROQ_API_KEY environment variable is not set');
  }
  
  static String getGoogleTranslateApiKey() {
    const envKey = String.fromEnvironment('GOOGLE_TRANSLATE_API_KEY');
    if (envKey.isNotEmpty) {
      return envKey;
    }
    throw Exception('GOOGLE_TRANSLATE_API_KEY environment variable is not set');
  }
}