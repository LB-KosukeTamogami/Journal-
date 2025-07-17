-- Supabase SQL Schema for Diary Details Enhancement
-- This file contains the SQL to update the database structure for better diary details storage

-- 1. Update translation_cache table to include more details
ALTER TABLE translation_cache 
ADD COLUMN IF NOT EXISTS learned_phrases jsonb DEFAULT '[]'::jsonb,
ADD COLUMN IF NOT EXISTS extracted_words jsonb DEFAULT '[]'::jsonb,
ADD COLUMN IF NOT EXISTS learned_words jsonb DEFAULT '[]'::jsonb;

-- Add indexes for better performance
CREATE INDEX IF NOT EXISTS idx_translation_cache_diary_entry_id ON translation_cache(diary_entry_id);
CREATE INDEX IF NOT EXISTS idx_translation_cache_user_id ON translation_cache(user_id);
CREATE INDEX IF NOT EXISTS idx_translation_cache_created_at ON translation_cache(created_at DESC);

-- 2. Create a view for easier querying of diary entries with their translations
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
LEFT JOIN translation_cache tc ON de.id = tc.diary_entry_id;

-- 3. Update RLS (Row Level Security) policies if needed
-- Enable RLS on translation_cache if not already enabled
ALTER TABLE translation_cache ENABLE ROW LEVEL SECURITY;

-- Policy for users to read their own translation cache
CREATE POLICY IF NOT EXISTS "Users can read own translation cache" 
ON translation_cache FOR SELECT 
USING (auth.uid()::text = user_id);

-- Policy for users to insert their own translation cache
CREATE POLICY IF NOT EXISTS "Users can insert own translation cache" 
ON translation_cache FOR INSERT 
WITH CHECK (auth.uid()::text = user_id);

-- Policy for users to update their own translation cache
CREATE POLICY IF NOT EXISTS "Users can update own translation cache" 
ON translation_cache FOR UPDATE 
USING (auth.uid()::text = user_id);

-- Policy for users to delete their own translation cache
CREATE POLICY IF NOT EXISTS "Users can delete own translation cache" 
ON translation_cache FOR DELETE 
USING (auth.uid()::text = user_id);

-- 4. Function to clean up old translation cache (optional)
CREATE OR REPLACE FUNCTION cleanup_old_translation_cache()
RETURNS void AS $$
BEGIN
    DELETE FROM translation_cache
    WHERE created_at < NOW() - INTERVAL '90 days';
END;
$$ LANGUAGE plpgsql;

-- 5. Add constraint to ensure diary_entry_id uniqueness per user
ALTER TABLE translation_cache 
DROP CONSTRAINT IF EXISTS unique_diary_entry_per_user;

ALTER TABLE translation_cache 
ADD CONSTRAINT unique_diary_entry_per_user 
UNIQUE(diary_entry_id, user_id);