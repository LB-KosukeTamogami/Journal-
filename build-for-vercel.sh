#!/bin/bash
set -e

echo "=== Vercel Build Script ==="
echo "Current directory: $(pwd)"
echo "Files in current directory:"
ls -la

# Install Flutter
echo "Installing Flutter SDK..."
export FLUTTER_ROOT=$HOME/flutter
export PATH=$FLUTTER_ROOT/bin:$PATH

if [ ! -d "$FLUTTER_ROOT" ]; then
    echo "Downloading Flutter SDK..."
    curl -L https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_3.32.5-stable.tar.xz -o flutter.tar.xz
    echo "Extracting Flutter SDK..."
    tar xf flutter.tar.xz -C $HOME
    rm flutter.tar.xz
    echo "Flutter SDK installed"
    
    # Fix git ownership issue
    git config --global --add safe.directory $FLUTTER_ROOT
    git config --global --add safe.directory '*'
fi

# Verify Flutter installation
flutter --version || echo "Flutter version check failed, continuing..."

# Disable analytics
flutter config --no-analytics

# Clean if needed
if [ -d "build" ]; then
    flutter clean
fi

# Get dependencies
flutter pub get

# Build with environment variables
echo "Building web app..."
echo "SUPABASE_URL: ${SUPABASE_URL:+SET}"
echo "SUPABASE_ANON_KEY: ${SUPABASE_ANON_KEY:+SET}"
echo "GEMINI_API_KEY: ${GEMINI_API_KEY:+SET}"

flutter build web --release \
  --dart-define=SUPABASE_URL=$SUPABASE_URL \
  --dart-define=SUPABASE_ANON_KEY=$SUPABASE_ANON_KEY \
  --dart-define=GEMINI_API_KEY=$GEMINI_API_KEY

echo "Build completed!"
ls -la build/web/