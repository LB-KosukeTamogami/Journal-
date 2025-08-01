#!/bin/bash
# このスクリプトはVercelの環境変数から.envファイルを作成します

echo "Creating .env file from Vercel environment variables..."

# .envファイルを作成
cat > .env << EOF
SUPABASE_URL=$SUPABASE_URL
SUPABASE_ANON_KEY=$SUPABASE_ANON_KEY
GEMINI_API_KEY=$GEMINI_API_KEY
EOF

echo ".env file created with:"
echo "- SUPABASE_URL: ${SUPABASE_URL:+SET}"
echo "- SUPABASE_ANON_KEY: ${SUPABASE_ANON_KEY:+SET}"
echo "- GEMINI_API_KEY: ${GEMINI_API_KEY:+SET}"