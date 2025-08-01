# API設定ガイド

## Groq API設定

### 1. APIキーの取得
1. https://console.groq.com/ にアクセス
2. アカウント作成/ログイン
3. API Keysページでキーを生成
4. キーをコピー

### 2. 設定方法

#### 開発環境
`lib/config/api_config.dart`を編集し、`groqApiKey`に実際のキーを設定

```dart
static const String groqApiKey = 'gsk_xxxxxxxxxxxxxxxxxxxxx';
```

#### 本番環境（推奨）
環境変数`GROQ_API_KEY`を設定

### 3. セキュリティ注意事項
- APIキーは絶対にGitコミットしない
- `.env`ファイルは`.gitignore`に追加済み
- 本番環境では環境変数を使用する

### 4. 使用モデル
- `llama-3.3-70b-versatile`: 添削・翻訳用（2025年1月更新）
- 無料枠: 7,000 requests/分

### 5. 機能
- 日記の自動添削
- 多言語翻訳
- 文法改善提案
- 重要フレーズ抽出