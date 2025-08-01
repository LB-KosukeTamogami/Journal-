#!/bin/bash
# Safe build script for Vercel with minimal Git operations

echo "=== Vercel Build Script (Safe Mode) ==="
echo "Starting at: $(date)"

# Show environment info
echo "Current directory: $(pwd)"
echo "Environment: Vercel"

# Install Flutter without using git clone
echo "Installing Flutter..."
curl -L https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_3.24.5-stable.tar.xz -o flutter.tar.xz
tar xf flutter.tar.xz
export PATH="$PWD/flutter/bin:$PATH"

# Navigate to app directory
cd journal_learning_app

# Get dependencies
echo "Getting dependencies..."
flutter pub get

# Build for web
echo "Building web app..."
if [ -n "$GEMINI_API_KEY" ]; then
    flutter build web --release --web-renderer html --dart-define=GEMINI_API_KEY="$GEMINI_API_KEY"
else
    flutter build web --release --web-renderer html
fi

# Fix renderer
if [ -f "build/web/flutter_bootstrap.js" ]; then
    echo "Fixing renderer configuration..."
    perl -i -pe 's/"renderer":"canvaskit"/"renderer":"html"/g' build/web/flutter_bootstrap.js
fi

echo "Build completed successfully!"