# Word Cache システム実装ガイド

## 概要
日本語WordNet APIから取得した単語の翻訳結果をSupabaseにキャッシュし、API使用量を削減するシステムです。

## 実装内容

### 1. Supabaseテーブル構成
`supabase/migrations/20240115_word_cache.sql`にSQLスキーマを作成しました。

```sql
CREATE TABLE public.word_cache (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    ja_word TEXT NOT NULL UNIQUE,
    en_word TEXT NOT NULL,
    definition TEXT,
    source TEXT DEFAULT 'wordnet',
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP NOT NULL
);
```

### 2. WordCacheService
`lib/services/word_cache_service.dart`に実装

主な機能：
- `fetchCachedWord(String jaWord)`: 単語のキャッシュを検索
- `cacheWordTranslation()`: 翻訳結果をキャッシュに保存
- `fetchCachedWords()`: 複数単語の一括検索
- `getRecentCachedWords()`: 最近のキャッシュを取得（デバッグ用）

### 3. 既存サービスとの統合

#### GeminiService
- `getWordDefinition()`: WordNet APIアクセス前にキャッシュを確認
- 取得した定義は自動的にキャッシュに保存

#### TranslationService  
- `translate()`: 単語翻訳時にキャッシュを優先的に使用

#### ConversationSummaryScreen
- `_getWordMeaning()`: キャッシュ → 基本辞書 → Gemini APIの順で検索

## 使用フロー

1. **単語の意味取得リクエスト**
   ```
   キャッシュ確認 → ヒット → 返却
        ↓
      ミス
        ↓
   WordNet API or Gemini API
        ↓
   キャッシュに保存
        ↓
      返却
   ```

2. **APIコール削減効果**
   - 同じ単語の2回目以降のリクエストはAPIを使用しない
   - 複数画面で同じ単語を使用してもAPIは1回のみ

## Supabaseでの設定

1. Supabaseダッシュボードにログイン
2. SQL Editorで`supabase/migrations/20240115_word_cache.sql`を実行
3. RLSポリシーが自動的に設定される
   - 読み取り: 全ユーザー可能
   - 書き込み: 認証済みユーザーのみ

## 今後の拡張案

1. **キャッシュの有効期限**
   - 古いエントリの自動削除
   - 更新日時の記録

2. **品詞情報の保存**
   - WordNet APIから取得した品詞情報もキャッシュ

3. **使用頻度の記録**
   - よく使われる単語の優先度管理

4. **オフライン対応**
   - ローカルキャッシュとの同期