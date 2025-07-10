#!/bin/bash
set -e

echo "Building Flutter web app for Vercel..."

# Install Flutter
if ! command -v flutter &> /dev/null; then
    echo "Installing Flutter..."
    git clone https://github.com/flutter/flutter.git -b stable --depth 1 $HOME/flutter
    export PATH="$HOME/flutter/bin:$PATH"
fi

# Navigate to app directory
cd journal_learning_app

# Get dependencies
echo "Getting dependencies..."
flutter pub get

# Build for web with environment variables
echo "Building web app..."
if [ -n "$GEMINI_API_KEY" ]; then
    echo "Building with Gemini API key..."
    flutter build web --release --web-renderer html --dart-define=GEMINI_API_KEY="$GEMINI_API_KEY"
else
    echo "Building without API key (using default)..."
    flutter build web --release --web-renderer html
fi

echo "Build completed!"