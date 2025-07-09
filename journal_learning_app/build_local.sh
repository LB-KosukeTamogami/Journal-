#!/bin/bash
set -e

# Load environment variables from .env file
if [ -f .env ]; then
    echo "Loading environment variables from .env file..."
    export $(cat .env | grep -v '^#' | xargs)
fi

# Build Flutter web with environment variables
echo "Building Flutter web app with environment variables..."
if [ -n "$GEMINI_API_KEY" ]; then
    echo "Building with Gemini API key..."
    flutter build web --release --dart-define=GEMINI_API_KEY="$GEMINI_API_KEY"
else
    echo "Warning: GEMINI_API_KEY not found in .env file"
    flutter build web --release
fi

echo "Build completed!"