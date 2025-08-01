#!/bin/bash
set -e

echo "Building Flutter web app for Vercel..."

# Debug: Show current directory and git status
echo "Current directory: $(pwd)"
echo "Git status:"
git status || echo "Git command failed"

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
    flutter build web --release --dart-define=GEMINI_API_KEY="$GEMINI_API_KEY"
else
    echo "Building without API key (using default)..."
    flutter build web --release
fi

# Fix renderer in flutter_bootstrap.js
echo "Ensuring HTML renderer is used..."
if [ -f "build/web/flutter_bootstrap.js" ]; then
    # Create a temporary file with the fix
    cat build/web/flutter_bootstrap.js | sed 's/"renderer":"canvaskit"/"renderer":"html"/g' > build/web/flutter_bootstrap.js.tmp
    mv build/web/flutter_bootstrap.js.tmp build/web/flutter_bootstrap.js
    echo "Renderer configuration updated to HTML"
fi

echo "Build completed!"