#!/bin/bash
set -e

# Set locale to avoid warnings
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8

echo "Starting Vercel build process..."

# Print all environment variables first
if [ -f "print-env-vars.sh" ]; then
    bash print-env-vars.sh
fi

# Run environment debug script
if [ -f "vercel-env-fix.sh" ]; then
    bash vercel-env-fix.sh
fi

echo "========================================"
echo "Environment Variables Check:"
echo "======================================="

# List all environment variables that contain SUPABASE
echo "All SUPABASE-related environment variables:"
env | grep -i supabase || echo "No SUPABASE variables found"

echo "----------------------------------------"

# Export environment variables if they exist with different names
if [ -z "$SUPABASE_URL" ] && [ -n "$NEXT_PUBLIC_SUPABASE_URL" ]; then
    export SUPABASE_URL="$NEXT_PUBLIC_SUPABASE_URL"
    echo "Exported SUPABASE_URL from NEXT_PUBLIC_SUPABASE_URL"
fi

if [ -z "$SUPABASE_ANON_KEY" ] && [ -n "$NEXT_PUBLIC_SUPABASE_ANON_KEY" ]; then
    export SUPABASE_ANON_KEY="$NEXT_PUBLIC_SUPABASE_ANON_KEY"
    echo "Exported SUPABASE_ANON_KEY from NEXT_PUBLIC_SUPABASE_ANON_KEY"
fi

# Check specific variables
echo "Checking specific environment variables:"
echo "SUPABASE_URL=${SUPABASE_URL:-NOT SET}"
echo "SUPABASE_ANON_KEY=${SUPABASE_ANON_KEY:-NOT SET}"
echo "NEXT_PUBLIC_SUPABASE_URL=${NEXT_PUBLIC_SUPABASE_URL:-NOT SET}"
echo "NEXT_PUBLIC_SUPABASE_ANON_KEY=${NEXT_PUBLIC_SUPABASE_ANON_KEY:-NOT SET}"

echo "========================================"

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
    echo "SUPABASE_URL first 30 chars: ${SUPABASE_URL:0:30}..."
else
    echo "WARNING: SUPABASE_URL is not set"
fi

if [ -n "$SUPABASE_ANON_KEY" ]; then
    echo "SUPABASE_ANON_KEY is set (length: ${#SUPABASE_ANON_KEY})"
    echo "SUPABASE_ANON_KEY first 30 chars: ${SUPABASE_ANON_KEY:0:30}..."
else
    echo "WARNING: SUPABASE_ANON_KEY is not set"
fi

# Verify the environment variables are properly formatted
echo "Verifying environment variable format..."
if [[ "$SUPABASE_URL" =~ ^https://.*\.supabase\.co$ ]]; then
    echo "SUPABASE_URL format looks correct"
else
    echo "WARNING: SUPABASE_URL format may be incorrect"
fi

# Create .env file from Vercel environment variables
if [ -f "create-env-from-vercel.sh" ]; then
    bash create-env-from-vercel.sh
fi

# Build web with environment variables and HTML renderer
echo "Building Flutter web with HTML renderer..."

# Force set the variables for the build
SUPABASE_URL="${SUPABASE_URL}"
SUPABASE_ANON_KEY="${SUPABASE_ANON_KEY}"

# Final verification before build
if [ -z "$SUPABASE_URL" ] || [ -z "$SUPABASE_ANON_KEY" ]; then
    echo "ERROR: Environment variables are not set!"
    echo "SUPABASE_URL: ${SUPABASE_URL:-EMPTY}"
    echo "SUPABASE_ANON_KEY: ${SUPABASE_ANON_KEY:-EMPTY}"
    echo "Build will continue but Supabase features will not work."
fi

if [ -n "$GEMINI_API_KEY" ]; then
    echo "Building with Gemini API key and Supabase..."
    flutter build web --release --web-renderer html \
        --source-maps \
        --dart-define="GEMINI_API_KEY=${GEMINI_API_KEY}" \
        --dart-define="SUPABASE_URL=${SUPABASE_URL}" \
        --dart-define="SUPABASE_ANON_KEY=${SUPABASE_ANON_KEY}"
else
    echo "Building with Supabase only..."
    echo "Using SUPABASE_URL: ${SUPABASE_URL}"
    echo "Using SUPABASE_ANON_KEY: ${SUPABASE_ANON_KEY:0:20}..."
    
    flutter build web --release --web-renderer html \
        --source-maps \
        --dart-define="SUPABASE_URL=${SUPABASE_URL}" \
        --dart-define="SUPABASE_ANON_KEY=${SUPABASE_ANON_KEY}"
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