-- Supabaseのセットアップスクリプト
-- このSQLをSupabaseのSQL Editorで実行してください

-- 1. diary_entriesテーブルの作成
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

-- 2. wordsテーブルの作成
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

-- 3. インデックスの作成
CREATE INDEX IF NOT EXISTS idx_diary_entries_user_id ON diary_entries(user_id);
CREATE INDEX IF NOT EXISTS idx_diary_entries_created_at ON diary_entries(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_words_user_id ON words(user_id);
CREATE INDEX IF NOT EXISTS idx_words_diary_entry_id ON words(diary_entry_id);

-- 4. Row Level Security (RLS) の有効化
ALTER TABLE diary_entries ENABLE ROW LEVEL SECURITY;
ALTER TABLE words ENABLE ROW LEVEL SECURITY;

-- 5. RLSポリシーの作成
-- 匿名ユーザーでも自分のデータを読み書きできるようにする

-- diary_entriesのポリシー
CREATE POLICY "Users can view their own diary entries" ON diary_entries
    FOR SELECT USING (true);  -- 一時的に全て許可（デバッグ用）

CREATE POLICY "Users can create diary entries" ON diary_entries
    FOR INSERT WITH CHECK (true);  -- 一時的に全て許可（デバッグ用）

CREATE POLICY "Users can update their own diary entries" ON diary_entries
    FOR UPDATE USING (true);  -- 一時的に全て許可（デバッグ用）

CREATE POLICY "Users can delete their own diary entries" ON diary_entries
    FOR DELETE USING (true);  -- 一時的に全て許可（デバッグ用）

-- wordsのポリシー
CREATE POLICY "Users can view their own words" ON words
    FOR SELECT USING (true);  -- 一時的に全て許可（デバッグ用）

CREATE POLICY "Users can create words" ON words
    FOR INSERT WITH CHECK (true);  -- 一時的に全て許可（デバッグ用）

CREATE POLICY "Users can update their own words" ON words
    FOR UPDATE USING (true);  -- 一時的に全て許可（デバッグ用）

CREATE POLICY "Users can delete their own words" ON words
    FOR DELETE USING (true);  -- 一時的に全て許可（デバッグ用）

-- 6. 現在の設定を確認
SELECT 
    schemaname,
    tablename,
    policyname,
    permissive,
    roles,
    cmd,
    qual,
    with_check
FROM pg_policies 
WHERE schemaname = 'public' 
AND tablename IN ('diary_entries', 'words');

-- 7. テーブルの存在確認
SELECT 
    table_name,
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns
WHERE table_schema = 'public' 
AND table_name IN ('diary_entries', 'words')
ORDER BY table_name, ordinal_position;