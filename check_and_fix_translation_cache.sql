-- Step 1: まず現在のtranslation_cacheテーブルの構造を確認
-- このクエリを最初に実行してください
SELECT 
    column_name, 
    data_type,
    column_default
FROM information_schema.columns 
WHERE table_schema = 'public' 
  AND table_name = 'translation_cache'
ORDER BY ordinal_position;

-- Step 2: 必要なカラムを一つずつ追加（エラーが出たら次に進む）

-- 2-1: judgment カラムを追加
ALTER TABLE translation_cache ADD COLUMN judgment text;

-- 2-2: learned_phrases カラムを追加
ALTER TABLE translation_cache ADD COLUMN learned_phrases jsonb DEFAULT '[]'::jsonb;

-- 2-3: extracted_words カラムを追加
ALTER TABLE translation_cache ADD COLUMN extracted_words jsonb DEFAULT '[]'::jsonb;

-- 2-4: learned_words カラムを追加
ALTER TABLE translation_cache ADD COLUMN learned_words jsonb DEFAULT '[]'::jsonb;

-- Step 3: インデックスを作成（既に存在する場合はスキップ）
CREATE INDEX IF NOT EXISTS idx_translation_cache_diary_entry_id ON translation_cache(diary_entry_id);
CREATE INDEX IF NOT EXISTS idx_translation_cache_user_id ON translation_cache(user_id);
CREATE INDEX IF NOT EXISTS idx_translation_cache_created_at ON translation_cache(created_at DESC);

-- Step 4: ビューを作成または更新
CREATE OR REPLACE VIEW diary_entries_with_translations AS
SELECT 
    de.*,
    tc.translated_text,
    tc.corrected_text,
    tc.improvements,
    tc.detected_language,
    tc.target_language,
    tc.judgment,
    tc.learned_phrases,
    tc.extracted_words,
    tc.learned_words,
    tc.created_at as translation_created_at,
    tc.updated_at as translation_updated_at
FROM diary_entries de
LEFT JOIN translation_cache tc ON de.id::text = tc.diary_entry_id;

-- Step 5: RLSポリシーの設定
ALTER TABLE translation_cache ENABLE ROW LEVEL SECURITY;

-- 既存のポリシーを削除
DROP POLICY IF EXISTS "Users can read own translation cache" ON translation_cache;
DROP POLICY IF EXISTS "Users can insert own translation cache" ON translation_cache;
DROP POLICY IF EXISTS "Users can update own translation cache" ON translation_cache;
DROP POLICY IF EXISTS "Users can delete own translation cache" ON translation_cache;

-- 新しいポリシーを作成
CREATE POLICY "Users can read own translation cache" 
ON translation_cache FOR SELECT 
USING (auth.uid()::text = user_id);

CREATE POLICY "Users can insert own translation cache" 
ON translation_cache FOR INSERT 
WITH CHECK (auth.uid()::text = user_id);

CREATE POLICY "Users can update own translation cache" 
ON translation_cache FOR UPDATE 
USING (auth.uid()::text = user_id);

CREATE POLICY "Users can delete own translation cache" 
ON translation_cache FOR DELETE 
USING (auth.uid()::text = user_id);

-- Step 6: ユニーク制約を追加
ALTER TABLE translation_cache 
DROP CONSTRAINT IF EXISTS unique_diary_entry_per_user;

ALTER TABLE translation_cache 
ADD CONSTRAINT unique_diary_entry_per_user 
UNIQUE(diary_entry_id, user_id);

-- Step 7: 最終確認 - 更新後のテーブル構造を確認
SELECT 
    column_name, 
    data_type,
    column_default
FROM information_schema.columns 
WHERE table_schema = 'public' 
  AND table_name = 'translation_cache'
ORDER BY ordinal_position;