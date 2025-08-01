# GitHub Actions 無効化の手順

Vercelを使用してデプロイしているため、GitHub Actionsの重複したワークフローを無効化します。

## 無効化するワークフロー：
1. build-and-deploy.yml
2. vercel-deploy.yml
3. deploy.yml
4. flutter-web-deploy.yml

## 変更内容：
- `on: push:` のトリガーを削除
- `workflow_dispatch:` のみに変更（手動実行のみ可能）

これにより、GitHubへのプッシュ時に不要なビルドが実行されなくなります。