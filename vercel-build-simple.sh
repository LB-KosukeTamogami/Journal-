#!/bin/bash
set -e

echo "=== Simple Vercel Build Script ==="

# Install Flutter
echo "Installing Flutter SDK..."
export FLUTTER_ROOT=$HOME/flutter
export PATH=$FLUTTER_ROOT/bin:$PATH

if [ ! -d "$FLUTTER_ROOT" ]; then
    curl -L https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_3.24.5-stable.tar.xz -o flutter.tar.xz
    tar xf flutter.tar.xz -C $HOME
fi

# Navigate to app directory
cd journal_learning_app

# Clean build cache
flutter clean

# Get dependencies
flutter pub get

# Build with environment variables
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
    # Use perl for compatibility
    perl -i -pe 's/"renderer":"canvaskit"/"renderer":"html"/g' build/web/flutter_bootstrap.js
    echo "Renderer configuration updated to HTML"
fi

echo "Build completed!"