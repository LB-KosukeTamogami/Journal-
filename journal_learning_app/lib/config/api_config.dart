// API設定ファイル
// 本番環境では環境変数やセキュアストレージから読み込んでください

class ApiConfig {
  // Groq API設定
  static const String groqApiKey = 'YOUR_API_KEY_HERE';
  
  // その他のAPI設定
  static const String googleTranslateApiKey = 'YOUR_API_KEY_HERE';
  
  // 開発環境でのみ使用するデモキー
  // 本番環境では必ず環境変数から読み込んでください
  static String getGroqApiKey() {
    // 環境変数から読み込む
    const envKey = String.fromEnvironment('GROQ_API_KEY');
    if (envKey.isNotEmpty) {
      return envKey;
    }
    
    // デモ用（開発環境のみ）
    // TODO: 本番環境では削除してください
    return groqApiKey;
  }
}