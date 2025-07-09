#!/bin/bash
set -e

# Load environment variables from .env file
if [ -f .env ]; then
    echo "Loading environment variables from .env file..."
    export $(cat .env | grep -v '^#' | xargs)
fi

# Run Flutter with environment variables
echo "Starting Flutter app with environment variables..."
if [ -n "$GEMINI_API_KEY" ]; then
    echo "Running with Gemini API key..."
    flutter run -d chrome --dart-define=GEMINI_API_KEY="$GEMINI_API_KEY"
else
    echo "Warning: GEMINI_API_KEY not found in .env file"
    flutter run -d chrome
fi