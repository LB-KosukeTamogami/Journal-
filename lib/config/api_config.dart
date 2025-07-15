// API設定ファイル
// 本番環境では環境変数やセキュアストレージから読み込んでください

class ApiConfig {
  // Gemini APIキーを取得
  static String? getGeminiApiKey() {
    // ビルド時の環境変数から読み込む
    const buildTimeKey = String.fromEnvironment('GEMINI_API_KEY');
    if (buildTimeKey.isNotEmpty) {
      return buildTimeKey;
    }
    
    // APIキーが設定されていない場合はnullを返す
    return null;
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