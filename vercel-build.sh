#!/bin/bash
set -e

echo "Building Flutter web app for Vercel..."

# Install Flutter
if ! command -v flutter &> /dev/null; then
    echo "Installing Flutter..."
    git clone https://github.com/flutter/flutter.git -b stable --depth 1 $HOME/flutter
    export PATH="$HOME/flutter/bin:$PATH"
fi

# Navigate to app directory
cd journal_learning_app

# Get dependencies
echo "Getting dependencies..."
flutter pub get

# Build for web
echo "Building web app..."
flutter build web --release

echo "Build completed!"