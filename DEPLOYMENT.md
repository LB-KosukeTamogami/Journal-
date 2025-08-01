# デプロイメントガイド / Deployment Guide

## 必要な環境変数 / Required Environment Variables

### Vercel環境変数の設定

Vercelで以下の環境変数を設定する必要があります：

1. **SUPABASE_URL**
   - Supabaseプロジェクトの URL
   - 形式: `https://xxxxx.supabase.co`
   - 末尾のスラッシュは含めない

2. **SUPABASE_ANON_KEY**
   - Supabaseの anon/public キー
   - これは公開キーです（service_role キーではありません）

3. **GEMINI_API_KEY** (オプション)
   - Google AI StudioのAPIキー
   - AI機能を使用する場合のみ必要

### Vercelでの環境変数設定方法

1. [Vercelダッシュボード](https://vercel.com/dashboard)にアクセス
2. プロジェクトを選択
3. Settings → Environment Variables に移動
4. 以下の変数を追加：

| Variable Name | Value | Environment |
|--------------|-------|-------------|
| `SUPABASE_URL` | `https://your-project.supabase.co` | Production, Preview, Development |
| `SUPABASE_ANON_KEY` | `eyJhbGciOi...（実際のキー）` | Production, Preview, Development |
| `GEMINI_API_KEY` | `AIzaSy...（実際のキー）` | Production, Preview, Development |

5. プロジェクトを再デプロイ

### よくある問題

- **スペルミス**: 変数名は正確に入力してください
- **使用しないキー**: `SUPABASE_SERVICE_ROLE_KEY`は使用しない（サーバーサイド専用）
- **プレフィックス**: `NEXT_PUBLIC_`プレフィックスは不要
- **引用符**: Vercelでは値を引用符で囲まない
- **末尾のスラッシュ**: URLに末尾のスラッシュを含めない

### 環境変数の確認方法

デプロイ後、環境変数が正しく読み込まれているか確認：
1. デプロイされたアプリにアクセス
2. デバッグメニューから「環境設定を確認」を選択
3. 両方の変数が「設定済み」と表示されることを確認

## ローカル開発環境

ローカルでの開発については、[SETUP_LOCAL.md](./SETUP_LOCAL.md)を参照してください。

## GitHub Actionsでのデプロイ

GitHub Pagesへの自動デプロイは`.github/workflows/deploy.yml`で設定されています。

### GitHub Secretsの設定
1. リポジトリのSettings → Secrets and variables → Actions
2. New repository secretで以下を追加：
   - `SUPABASE_URL`
   - `SUPABASE_ANON_KEY`
   - `GEMINI_API_KEY` (オプション)