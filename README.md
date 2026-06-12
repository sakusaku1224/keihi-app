# 立替経費申請アプリ

<!-- TODO: アプリのスクリーンショットを貼る -->
<!-- ![スクリーンショット](スクショのURL) -->

## アプリ概要

<!-- TODO: 一言で説明する -->
> 社員が立替えた経費をオンラインで申請・管理できるWebアプリケーションです。

## 主な機能

- 経費申請のCRUD（下書き・提出・承認のステータス管理）
- 領収書画像・PDFのアップロード
- **OCR読み取り機能**（領収書を撮影するだけで明細を自動入力）
- セルフチェック（重複明細・領収書未添付の警告）
- ダッシュボード（件数サマリー・最近の申請一覧）
- ゲストログイン（登録なしで全機能を体験可能）
- ページネーション

## 使い方

1. トップページの「ゲストログイン」からすぐに試せます
2. 「新規申請」から経費申請を作成
3. 明細を追加（手入力 or 領収書をアップロードしてOCR自動入力）
4. 提出前にセルフチェックで内容を確認
5. 提出完了

## なぜこれを作ったか

<!-- TODO: 開発の動機・背景を書く -->

## 工夫したところ

<!-- TODO: 技術的なこだわりポイントを書く -->
<!-- 例：OCRにClaude APIを使ったこと、セルフチェック機能、Flatpickrの日付入力など -->

## 使用技術

| カテゴリ | 技術 |
|----------|------|
| バックエンド | Ruby on Rails 7.2 |
| データベース | PostgreSQL |
| フロントエンド | Bootstrap 5, JavaScript |
| 認証 | Devise |
| ファイルアップロード | Active Storage |
| OCR | Claude API (claude-haiku-4-5) |
| ページネーション | Kaminari |
| テスト | RSpec, FactoryBot |
| インフラ | <!-- TODO: Render など --> |

## ER図

<!-- TODO: ER図の画像を貼る -->

## 環境構築（ローカル）

```bash
git clone https://github.com/<!-- TODO: リポジトリURL -->
cd keihi-app
bundle install
rails db:create db:migrate db:seed
rails s
```

`.env` に以下を設定してください：

```
ANTHROPIC_API_KEY=your_api_key
```
