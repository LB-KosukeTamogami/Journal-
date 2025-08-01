#!/bin/bash

echo "Flutter セットアップスクリプト"
echo "=========================="

# Homebrewの確認
if ! command -v brew &> /dev/null; then
    echo "Homebrewがインストールされていません。"
    echo "以下のコマンドでHomebrewをインストールしてください："
    echo '/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"'
    exit 1
fi

# Flutterのインストール
echo "1. Flutterをインストールしています..."
brew install --cask flutter

# Flutter doctorの実行
echo "2. Flutter環境をチェックしています..."
flutter doctor

echo ""
echo "セットアップが完了しました！"
echo ""
echo "次のステップ："
echo "1. ターミナルを再起動するか、以下を実行："
echo "   source ~/.zshrc"
echo ""
echo "2. プロジェクトの依存関係をインストール："
echo "   flutter pub get"
echo ""
echo "3. アプリを実行："
echo "   flutter run"