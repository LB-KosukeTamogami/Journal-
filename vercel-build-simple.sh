#!/bin/bash
set -e

echo "=== Simple Vercel Build Script ==="
echo "Current directory: $(pwd)"
echo "Home directory: $HOME"

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
    
    # Configure git to trust the newly installed Flutter directory
    git config --global --add safe.directory $FLUTTER_ROOT 2>/dev/null || true
fi

# Verify Flutter installation
if ! command -v flutter &> /dev/null; then
    echo "Error: Flutter installation failed"
    exit 1
fi

flutter --version

# Configure git to trust the Flutter directory
git config --global --add safe.directory $FLUTTER_ROOT 2>/dev/null || true
git config --global --add safe.directory '*' 2>/dev/null || true

# Disable analytics and accept licenses
flutter config --no-analytics || true
yes | flutter doctor --android-licenses 2>/dev/null || true

# Stay in current directory (no need to navigate)
# cd journal_learning_app

# Clean build cache (only if build directory exists)
if [ -d "build" ]; then
    flutter clean
else
    echo "No existing build directory, skipping clean"
fi

# Get dependencies
flutter pub get

# Build with environment variables
echo "Building web app..."
echo "Checking environment variables..."
echo "GEMINI_API_KEY: ${GEMINI_API_KEY:+SET}"
echo "SUPABASE_URL: ${SUPABASE_URL:+SET}"
echo "SUPABASE_ANON_KEY: ${SUPABASE_ANON_KEY:+SET}"

# Build with all environment variables
DART_DEFINES=""
if [ -n "$GEMINI_API_KEY" ]; then
    DART_DEFINES="${DART_DEFINES} --dart-define=GEMINI_API_KEY=$GEMINI_API_KEY"
fi
if [ -n "$SUPABASE_URL" ]; then
    DART_DEFINES="${DART_DEFINES} --dart-define=SUPABASE_URL=$SUPABASE_URL"
fi
if [ -n "$SUPABASE_ANON_KEY" ]; then
    DART_DEFINES="${DART_DEFINES} --dart-define=SUPABASE_ANON_KEY=$SUPABASE_ANON_KEY"
fi

echo "Building with environment variables..."
flutter build web --release $DART_DEFINES

# Fix renderer in flutter_bootstrap.js
echo "Ensuring HTML renderer is used..."
if [ -f "build/web/flutter_bootstrap.js" ]; then
    # Use perl for compatibility
    perl -i -pe 's/"renderer":"canvaskit"/"renderer":"html"/g' build/web/flutter_bootstrap.js
    echo "Renderer configuration updated to HTML"
fi

echo "Build completed!"

# List build output
echo "Checking build output..."
ls -la build/web/ || echo "build/web directory not found"
