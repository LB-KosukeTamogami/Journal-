-- Supabase SQL Schema for Diary Details Enhancement (Fixed Version)
-- This file safely updates the database structure for better diary details storage

-- First, let's check what columns already exist in translation_cache table
-- Run this query first to see the current structure:
/*
SELECT column_name, data_type 
FROM information_schema.columns 
WHERE table_name = 'translation_cache'
ORDER BY ordinal_position;
*/

-- 1. Add missing columns to translation_cache table (one at a time)
-- Add judgment column if it doesn't exist
DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
        AND table_name = 'translation_cache' 
        AND column_name = 'judgment'
    ) THEN
        ALTER TABLE public.translation_cache ADD COLUMN judgment text;
        RAISE NOTICE 'Added judgment column';
    ELSE
        RAISE NOTICE 'judgment column already exists';
    END IF;
END $$;

-- Add learned_phrases column if it doesn't exist
DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
        AND table_name = 'translation_cache' 
        AND column_name = 'learned_phrases'
    ) THEN
        ALTER TABLE public.translation_cache ADD COLUMN learned_phrases jsonb DEFAULT '[]'::jsonb;
        RAISE NOTICE 'Added learned_phrases column';
    ELSE
        RAISE NOTICE 'learned_phrases column already exists';
    END IF;
END $$;

-- Add extracted_words column if it doesn't exist
DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
        AND table_name = 'translation_cache' 
        AND column_name = 'extracted_words'
    ) THEN
        ALTER TABLE public.translation_cache ADD COLUMN extracted_words jsonb DEFAULT '[]'::jsonb;
        RAISE NOTICE 'Added extracted_words column';
    ELSE
        RAISE NOTICE 'extracted_words column already exists';
    END IF;
END $$;

-- Add learned_words column if it doesn't exist
DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
        AND table_name = 'translation_cache' 
        AND column_name = 'learned_words'
    ) THEN
        ALTER TABLE public.translation_cache ADD COLUMN learned_words jsonb DEFAULT '[]'::jsonb;
        RAISE NOTICE 'Added learned_words column';
    ELSE
        RAISE NOTICE 'learned_words column already exists';
    END IF;
END $$;

-- 2. Add indexes for better performance
CREATE INDEX IF NOT EXISTS idx_translation_cache_diary_entry_id ON translation_cache(diary_entry_id);
CREATE INDEX IF NOT EXISTS idx_translation_cache_user_id ON translation_cache(user_id);
CREATE INDEX IF NOT EXISTS idx_translation_cache_created_at ON translation_cache(created_at DESC);

-- 3. Create or replace the view for easier querying
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

-- 4. Update RLS (Row Level Security) policies
-- Enable RLS on translation_cache if not already enabled
ALTER TABLE translation_cache ENABLE ROW LEVEL SECURITY;

-- Drop and recreate policies to ensure they're correct
DROP POLICY IF EXISTS "Users can read own translation cache" ON translation_cache;
DROP POLICY IF EXISTS "Users can insert own translation cache" ON translation_cache;
DROP POLICY IF EXISTS "Users can update own translation cache" ON translation_cache;
DROP POLICY IF EXISTS "Users can delete own translation cache" ON translation_cache;

-- Create policies
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

-- 5. Create cleanup function
CREATE OR REPLACE FUNCTION cleanup_old_translation_cache()
RETURNS void AS $$
BEGIN
    DELETE FROM translation_cache
    WHERE created_at < NOW() - INTERVAL '90 days';
END;
$$ LANGUAGE plpgsql;

-- 6. Add constraint for diary_entry_id uniqueness per user
-- First drop if exists, then add
ALTER TABLE translation_cache 
DROP CONSTRAINT IF EXISTS unique_diary_entry_per_user;

ALTER TABLE translation_cache 
ADD CONSTRAINT unique_diary_entry_per_user 
UNIQUE(diary_entry_id, user_id);

-- 7. Verify the final structure
-- Run this query after executing all the above to verify:
/*
SELECT column_name, data_type 
FROM information_schema.columns 
WHERE table_name = 'translation_cache'
ORDER BY ordinal_position;
*/