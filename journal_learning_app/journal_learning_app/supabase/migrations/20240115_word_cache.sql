-- word_cache テーブルの作成
CREATE TABLE IF NOT EXISTS public.word_cache (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    ja_word TEXT NOT NULL UNIQUE,
    en_word TEXT NOT NULL,
    definition TEXT,
    source TEXT DEFAULT 'wordnet',
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP NOT NULL
);

-- インデックスの作成（検索パフォーマンス向上）
CREATE INDEX IF NOT EXISTS idx_word_cache_ja_word ON public.word_cache (ja_word);
CREATE INDEX IF NOT EXISTS idx_word_cache_created_at ON public.word_cache (created_at);

-- RLS (Row Level Security) の有効化
ALTER TABLE public.word_cache ENABLE ROW LEVEL SECURITY;

-- RLSポリシー：全ユーザーが読み取り可能
CREATE POLICY "Word cache is viewable by everyone" ON public.word_cache
    FOR SELECT
    USING (true);

-- RLSポリシー：認証済みユーザーのみ書き込み可能
CREATE POLICY "Authenticated users can insert word cache" ON public.word_cache
    FOR INSERT
    WITH CHECK (auth.uid() IS NOT NULL);

-- コメントの追加
COMMENT ON TABLE public.word_cache IS '単語翻訳のキャッシュテーブル';
COMMENT ON COLUMN public.word_cache.ja_word IS '日本語単語（ユニーク）';
COMMENT ON COLUMN public.word_cache.en_word IS '英訳';
COMMENT ON COLUMN public.word_cache.definition IS '日本語での意味説明';
COMMENT ON COLUMN public.word_cache.source IS '辞書ソース（デフォルト: wordnet）';