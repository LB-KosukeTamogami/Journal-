# Journal英語学習アプリ

日記を通じて英語学習を楽しく継続できるモバイルアプリケーションです。グラスモーフィズムデザインを採用した美しいUIで、毎日の英語学習をサポートします。

## 🚀 デプロイメント

このアプリケーションはGitHub Pagesで自動デプロイされます。

### デプロイURL：

#### Vercel (推奨):
https://journal-brown-three.vercel.app/

#### GitHub Pages:
https://lb-kosuketamogami.github.io/Journal-/

### Vercelデプロイ手順：

1. Vercelでプロジェクトをインポート
2. リポジトリを選択: `LB-KosukeTamogami/Journal-`
3. Framework Presetは "Other" を選択
4. Build Commandを空欄に設定
5. Output Directoryを `journal_learning_app/build/web` に設定
6. Deploy

### GitHub Pages設定手順：
1. GitHubリポジトリの Settings > Pages に移動
2. Source を "Deploy from a branch" に設定
3. Branch を "gh-pages" に設定（GitHub Actionsで自動作成されます）
4. Save をクリック

## 機能

- 📝 日記記録・管理
- 🤖 AI添削・翻訳
- 🔊 音声読み上げ（TTS）
- 📚 暗記カード
- 📊 学習分析
- 🎯 ミッション機能
- 💬 会話ジャーナル

## セットアップ

### 前提条件

- Flutter SDK (3.0.0以上)
- Dart SDK
- iOS: Xcode (iOS開発の場合)
- Android: Android Studio (Android開発の場合)

### インストール手順

1. Flutter SDKのインストール
```bash
# macOSの場合
brew install flutter

# または公式サイトからダウンロード
# https://flutter.dev/docs/get-started/install
```

2. プロジェクトのセットアップ
```bash
cd journal_learning_app
flutter pub get
```

3. 実行
```bash
# iOS
flutter run -d ios

# Android
flutter run -d android

# Webプレビュー
flutter run -d chrome
```

## プロジェクト構造

```
lib/
├── main.dart              # アプリケーションのエントリーポイント
├── screens/               # 各画面のウィジェット
│   ├── home_screen.dart
│   ├── journal_screen.dart
│   ├── learning_screen.dart
│   ├── analytics_screen.dart
│   └── my_page_screen.dart
├── models/                # データモデル
├── services/              # APIやデータベースとの通信
├── widgets/               # 再利用可能なウィジェット
└── utils/                 # ユーティリティ関数

assets/
├── images/               # 画像ファイル
└── fonts/                # フォントファイル
```

## 開発ガイドライン

### コーディング規約

- Dartの公式スタイルガイドに従う
- ウィジェットは可能な限り再利用可能に設計
- 状態管理にはProviderパターンを使用

### Git運用

- feature/機能名 でブランチを作成
- コミットメッセージは日本語可

## ビルド

### iOS
```bash
flutter build ios
```

### Android
```bash
flutter build apk
```

## 今後の実装予定

- [ ] Firebase認証の実装
- [ ] Firestore/Supabaseとの連携
- [ ] AI APIの統合
- [ ] 通知機能の実装
- [ ] 製本機能の実装

## ライセンス

本プロジェクトはプライベートプロジェクトです。 
