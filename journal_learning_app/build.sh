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

# Build web
echo "Building web..."
flutter build web --release --web-renderer html

echo "Build completed!"