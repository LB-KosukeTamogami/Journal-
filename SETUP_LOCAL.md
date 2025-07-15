# ローカル開発環境のセットアップ

## 1. 環境変数の設定

### Supabaseプロジェクトの作成
1. [Supabase](https://supabase.com)にアクセスしてアカウントを作成
2. 新しいプロジェクトを作成
3. プロジェクトが作成されたら、左側メニューから「Settings」→「API」に移動
4. 以下の情報をメモ：
   - **Project URL**: `https://xxxxx.supabase.co`の形式
   - **anon public key**: `eyJhbGciOi...`で始まる長い文字列

### .envファイルの作成
```bash
# プロジェクトルートで実行
cp .env.example .env
```

### .envファイルの編集
テキストエディタで`.env`ファイルを開き、以下のように設定：

```env
# Supabase設定（必須）
SUPABASE_URL=https://your-project-id.supabase.co
SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...（実際のキー）

# Gemini API設定（オプション）
GEMINI_API_KEY=AIzaSy...（実際のキー）
```

## 2. アプリケーションの実行

### 開発サーバーの起動
```bash
./run_local.sh
```

このスクリプトは自動的に：
- `.env`ファイルから環境変数を読み込み
- Flutterアプリを`--dart-define`パラメータ付きで起動
- ChromeブラウザでWebアプリを開く

### ビルド（本番用）
```bash
./build_local.sh
```

## 3. 動作確認

1. ブラウザでアプリが開いたら、デバッグメニューから「Supabase接続状態」を選択
2. 以下を確認：
   - 接続状態: Connected
   - User ID: 表示される
   - データ統計: ローカルとSupabaseのデータ数

## トラブルシューティング

### "Supabase not available"エラー
- `.env`ファイルの設定を確認
- URLとキーが正しくコピーされているか確認
- スクリプトを再実行

### データがローカルにのみ保存される
- Supabaseダッシュボードで接続を確認
- ブラウザのコンソールログでエラーを確認
- ネットワーク接続を確認

### ビルドエラー
- Flutter SDKが最新版か確認: `flutter doctor`
- 依存関係を更新: `flutter pub get`
- キャッシュをクリア: `flutter clean`