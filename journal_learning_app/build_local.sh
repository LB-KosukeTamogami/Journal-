#!/bin/bash
set -e

# Load environment variables from .env file
if [ -f .env ]; then
    echo "Loading environment variables from .env file..."
    export $(cat .env | grep -v '^#' | xargs)
fi

# Build Flutter web with environment variables
echo "Building Flutter web app with environment variables..."

# Check for required environment variables
if [ -z "$SUPABASE_URL" ] || [ -z "$SUPABASE_ANON_KEY" ]; then
    echo "ERROR: SUPABASE_URL and SUPABASE_ANON_KEY must be set in .env file"
    echo "Please create a .env file with:"
    echo "SUPABASE_URL=your_supabase_url"
    echo "SUPABASE_ANON_KEY=your_supabase_anon_key"
    echo "GEMINI_API_KEY=your_gemini_api_key (optional)"
    exit 1
fi

echo "Building with Supabase configuration..."
echo "SUPABASE_URL: ${SUPABASE_URL:0:30}..."
echo "SUPABASE_ANON_KEY: ${SUPABASE_ANON_KEY:0:20}..."

if [ -n "$GEMINI_API_KEY" ]; then
    echo "Building with Gemini API key..."
    flutter build web --release \
        --dart-define=GEMINI_API_KEY="$GEMINI_API_KEY" \
        --dart-define=SUPABASE_URL="$SUPABASE_URL" \
        --dart-define=SUPABASE_ANON_KEY="$SUPABASE_ANON_KEY"
else
    echo "Warning: GEMINI_API_KEY not found in .env file"
    flutter build web --release \
        --dart-define=SUPABASE_URL="$SUPABASE_URL" \
        --dart-define=SUPABASE_ANON_KEY="$SUPABASE_ANON_KEY"
fi

echo "Build completed!"