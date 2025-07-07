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

# Extract Flutter SDK
echo "Extracting Flutter SDK..."
tar xf flutter.tar.xz

# Remove the tar file
rm flutter.tar.xz

# Set PATH
export PATH="$PWD/flutter/bin:$PATH"

# Run Flutter doctor
echo "Running Flutter doctor..."
flutter doctor -v

# Get dependencies
echo "Getting Flutter dependencies..."
flutter pub get

# Build web
echo "Building Flutter web..."
flutter build web --release --web-renderer html

echo "Build completed successfully!"