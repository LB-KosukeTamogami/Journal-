#!/bin/bash
set -e

echo "Starting Vercel build process..."

# Clean up any existing Flutter installation
if [ -d "flutter" ]; then
  echo "Removing existing Flutter installation..."
  rm -rf flutter
fi

# Download Flutter SDK
echo "Downloading Flutter SDK..."
curl -L https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_3.32.5-stable.tar.xz -o flutter.tar.xz

# Extract Flutter SDK with proper permissions
echo "Extracting Flutter SDK..."
tar --no-same-owner -xf flutter.tar.xz

# Remove the tar file
rm flutter.tar.xz

# Set PATH
export PATH="$PWD/flutter/bin:$PATH"

# Accept Flutter licenses
echo "Accepting Flutter licenses..."
yes | flutter doctor --android-licenses 2>/dev/null || true

# Run Flutter doctor for web only
echo "Checking Flutter web setup..."
flutter doctor -v || true

# Disable analytics to avoid permission issues
flutter config --no-analytics --no-cli-animations 2>/dev/null || true

# Configure git to trust the directory
git config --global --add safe.directory /vercel/path0/journal_learning_app/flutter 2>/dev/null || true
git config --global --add safe.directory '*' 2>/dev/null || true

# Clean build cache
echo "Cleaning build cache..."
flutter clean

# Get dependencies
echo "Getting Flutter dependencies..."
flutter pub get

# Debug: Check environment variables
echo "Checking environment variables..."
if [ -n "$SUPABASE_URL" ]; then
    echo "SUPABASE_URL is set (length: ${#SUPABASE_URL})"
else
    echo "WARNING: SUPABASE_URL is not set"
fi

if [ -n "$SUPABASE_ANON_KEY" ]; then
    echo "SUPABASE_ANON_KEY is set (length: ${#SUPABASE_ANON_KEY})"
else
    echo "WARNING: SUPABASE_ANON_KEY is not set"
fi

# Build web with environment variables and HTML renderer
echo "Building Flutter web with HTML renderer..."
if [ -n "$GEMINI_API_KEY" ]; then
    echo "Building with Gemini API key and Supabase..."
    flutter build web --release --web-renderer html \
        --source-maps \
        --dart-define=GEMINI_API_KEY="$GEMINI_API_KEY" \
        --dart-define=SUPABASE_URL="$SUPABASE_URL" \
        --dart-define=SUPABASE_ANON_KEY="$SUPABASE_ANON_KEY"
else
    echo "Building with Supabase only..."
    flutter build web --release --web-renderer html \
        --source-maps \
        --dart-define=SUPABASE_URL="$SUPABASE_URL" \
        --dart-define=SUPABASE_ANON_KEY="$SUPABASE_ANON_KEY"
fi

# Fix renderer in flutter_bootstrap.js
echo "Ensuring HTML renderer is used..."
if [ -f "build/web/flutter_bootstrap.js" ]; then
    # Create a temporary file with the fix
    cat build/web/flutter_bootstrap.js | sed 's/"renderer":"canvaskit"/"renderer":"html"/g' > build/web/flutter_bootstrap.js.tmp
    mv build/web/flutter_bootstrap.js.tmp build/web/flutter_bootstrap.js
    echo "Renderer configuration updated to HTML"
fi

echo "Build completed successfully!"