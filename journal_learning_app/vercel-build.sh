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
curl -L https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_3.16.0-stable.tar.xz -o flutter.tar.xz

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

# Get dependencies
echo "Getting Flutter dependencies..."
flutter pub get

# Build web
echo "Building Flutter web..."
flutter build web --release --web-renderer html

echo "Build completed successfully!"