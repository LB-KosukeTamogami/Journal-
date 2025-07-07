#!/bin/bash
set -e

echo "Installing Flutter for Vercel..."

# Create a local directory for Flutter
mkdir -p $HOME/.flutter
cd $HOME/.flutter

# Download Flutter SDK
echo "Downloading Flutter SDK..."
curl -L https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_3.16.0-stable.tar.xz -o flutter.tar.xz

# Extract Flutter
echo "Extracting Flutter SDK..."
tar xf flutter.tar.xz

# Add Flutter to PATH
export PATH="$HOME/.flutter/flutter/bin:$PATH"

# Return to the original directory
cd $VERCEL_PATH0/journal_learning_app

# Disable analytics
flutter config --no-analytics || true

# Get dependencies
echo "Getting dependencies..."
flutter pub get

# Build web
echo "Building web..."
flutter build web --release --web-renderer html

echo "Build completed!"