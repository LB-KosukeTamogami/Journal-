// API設定ファイル
// 本番環境では環境変数やセキュアストレージから読み込んでください

class ApiConfig {
  // Gemini API Key (開発環境用のデフォルト値)
  static const String _defaultGeminiApiKey = 'AIzaSyBRgV7ts1Viv7YaMmtHRUOgHXGi3-GqXos';
  
  // 環境変数からAPIキーを取得（エラーを投げずにnullを返す）
  static String? getGroqApiKey() {
    // ビルド時の環境変数から読み込む
    const buildTimeKey = String.fromEnvironment('GROQ_API_KEY');
    if (buildTimeKey.isNotEmpty) {
      return buildTimeKey;
    }
    
    // APIキーが設定されていない場合はnullを返す
    return null;
  }
  
  // Gemini APIキーを取得
  static String? getGeminiApiKey() {
    // ビルド時の環境変数から読み込む
    const buildTimeKey = String.fromEnvironment('GEMINI_API_KEY');
    if (buildTimeKey.isNotEmpty) {
      return buildTimeKey;
    }
    
    // 開発環境用のデフォルト値を使用
    // 本番環境では必ず環境変数 GEMINI_API_KEY を設定してください
    return _defaultGeminiApiKey;
  }
  
  static String? getGoogleTranslateApiKey() {
    // ビルド時の環境変数から読み込む
    const buildTimeKey = String.fromEnvironment('GOOGLE_TRANSLATE_API_KEY');
    if (buildTimeKey.isNotEmpty) {
      return buildTimeKey;
    }
    
    // APIキーが設定されていない場合はnullを返す
    return null;
  }
}