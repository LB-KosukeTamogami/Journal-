#!/bin/bash
set -e

echo "Starting Flutter web build..."

# Download and setup Flutter
export FLUTTER_ROOT=$PWD/flutter
export PATH=$FLUTTER_ROOT/bin:$PATH

# Download Flutter if not exists
if [ ! -d "flutter" ]; then
    echo "Downloading Flutter SDK..."
    git clone https://github.com/flutter/flutter.git -b stable --depth 1
fi

# Disable analytics
flutter config --no-analytics || true

# Get dependencies
echo "Getting dependencies..."
flutter pub get

# Clean build cache
echo "Cleaning build cache..."
flutter clean

# Get dependencies again
echo "Getting dependencies after clean..."
flutter pub get

# Build web with environment variables
echo "Building web..."
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