# Supabaseセットアップガイド

## 問題の診断

「接続はConnectedだが、データがローカルに保存される」という問題は、通常以下の原因で発生します：

1. **テーブルが存在しない**
2. **Row Level Security (RLS) が有効だが、適切なポリシーが設定されていない**
3. **匿名認証が無効になっている**

## セットアップ手順

### 1. Supabaseダッシュボードにログイン
[Supabase Dashboard](https://supabase.com/dashboard)にアクセスし、プロジェクトを選択

### 2. SQL Editorでテーブルを作成
左側メニューから「SQL Editor」を選択し、以下のSQLを実行：

```sql
-- diary_entriesテーブルの作成
CREATE TABLE IF NOT EXISTS diary_entries (
    id TEXT PRIMARY KEY,
    user_id TEXT NOT NULL,
    title TEXT NOT NULL,
    content TEXT NOT NULL,
    translated_content TEXT,
    word_count INTEGER DEFAULT 0,
    learned_words TEXT[],
    created_at TIMESTAMP WITH TIME ZONE NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL
);

-- wordsテーブルの作成
CREATE TABLE IF NOT EXISTS words (
    id TEXT PRIMARY KEY,
    user_id TEXT NOT NULL,
    english TEXT NOT NULL,
    japanese TEXT,
    example TEXT,
    diary_entry_id TEXT,
    review_count INTEGER DEFAULT 0,
    last_reviewed_at TIMESTAMP WITH TIME ZONE,
    is_mastered BOOLEAN DEFAULT FALSE,
    mastery_level INTEGER DEFAULT 0,
    category TEXT DEFAULT 'other',
    created_at TIMESTAMP WITH TIME ZONE NOT NULL
);
```

### 3. Row Level Security (RLS) の設定

**重要**: RLSを有効にする場合は、適切なポリシーを設定する必要があります。

#### オプション1: RLSを無効にする（開発/テスト用）
```sql
-- RLSを無効にする
ALTER TABLE diary_entries DISABLE ROW LEVEL SECURITY;
ALTER TABLE words DISABLE ROW LEVEL SECURITY;
```

#### オプション2: RLSを有効にして、全アクセスを許可（推奨）
```sql
-- RLSを有効にする
ALTER TABLE diary_entries ENABLE ROW LEVEL SECURITY;
ALTER TABLE words ENABLE ROW LEVEL SECURITY;

-- 全てのユーザーに読み書きを許可するポリシー
CREATE POLICY "Enable all access for all users" ON diary_entries
    FOR ALL USING (true) WITH CHECK (true);

CREATE POLICY "Enable all access for all users" ON words
    FOR ALL USING (true) WITH CHECK (true);
```

### 4. 匿名認証の有効化
1. Supabaseダッシュボードで「Authentication」→「Providers」に移動
2. 「Anonymous」を有効にする

### 5. 設定の確認
アプリケーションで以下を確認：
1. デバッグメニュー → 「Supabase接続状態」
2. 「Supabase接続テスト」ボタンをクリック
3. テストエントリーが正常に保存されるか確認

## トラブルシューティング

### エラー: "permission denied for table diary_entries"
→ RLSが有効だが、ポリシーが設定されていない

**解決方法**: 上記の「RLSの設定」を実行

### エラー: "relation \"diary_entries\" does not exist"
→ テーブルが作成されていない

**解決方法**: 上記の「テーブルを作成」のSQLを実行

### データが保存されない（エラーなし）
→ 保存は成功しているが、取得時にRLSでフィルタされている

**解決方法**: RLSポリシーを確認し、適切な権限を設定

## 完全なセットアップSQL

`supabase_setup.sql`ファイルを参照して、完全なセットアップを実行できます。