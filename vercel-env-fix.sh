#!/bin/bash
set -e

# このスクリプトはVercelの環境変数をFlutterビルドに正しく渡すためのヘルパー

echo "=== Vercel Environment Variable Debug Script ==="
echo "Date: $(date)"
echo "PWD: $(pwd)"

echo ""
echo "=== Checking ALL Environment Variables ==="
echo "Total environment variables: $(env | wc -l)"

echo ""
echo "=== Supabase Related Variables ==="
env | grep -i supabase || echo "No SUPABASE variables found in environment"

echo ""
echo "=== Checking Specific Variables ==="
if [ -n "$SUPABASE_URL" ]; then
    echo "✅ SUPABASE_URL is set"
    echo "   Length: ${#SUPABASE_URL}"
    echo "   First 30 chars: ${SUPABASE_URL:0:30}..."
else
    echo "❌ SUPABASE_URL is NOT set"
fi

if [ -n "$SUPABASE_ANON_KEY" ]; then
    echo "✅ SUPABASE_ANON_KEY is set"
    echo "   Length: ${#SUPABASE_ANON_KEY}"
    echo "   First 30 chars: ${SUPABASE_ANON_KEY:0:30}..."
else
    echo "❌ SUPABASE_ANON_KEY is NOT set"
fi

echo ""
echo "=== Creating .env file for debugging ==="
cat > .env.debug << EOF
SUPABASE_URL=${SUPABASE_URL:-NOT_SET}
SUPABASE_ANON_KEY=${SUPABASE_ANON_KEY:-NOT_SET}
EOF

echo "Contents of .env.debug:"
cat .env.debug

echo ""
echo "=== End of Debug Script ==="