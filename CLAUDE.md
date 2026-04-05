# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

日々の摂取カロリーを記録するRails 8.1アプリケーション。SQLite + Hotwire (Turbo/Stimulus) + Tailwind CSS で構成。

## Commands

```bash
# 初回セットアップ
bin/setup

# 開発サーバー起動
bin/dev

# テスト実行
bin/rails test

# 単体テスト実行
bin/rails test test/models/food_test.rb
bin/rails test test/controllers/daily_food_logs_controller_test.rb

# DBシード（食品マスタ登録）
bin/rails db:seed

# Lint
bundle exec rubocop
```

## Architecture

### Models

- **Food** — 食品マスタ。`category` enum (`breakfast`, `lunch_dinner`, `snack`) を持つ。`manual_calories_enabled` が true の食品はログ登録時にカロリーを手動入力できる。
- **DailyFoodLog** — 食事記録。`meal_type` enum (`breakfast`, `lunch`, `dinner`, `snack`)。`before_validation :copy_food_snapshot` で Food の `name` と `calories` をスナップショットとして保存するため、Food 変更後も過去ログは影響を受けない。

**重要な制約**: `meal_type` と Food の `category` の対応関係が固定されており (`Food::CATEGORY_FOR_MEAL_TYPE`)、朝食には `breakfast` カテゴリ、昼・夜食には `lunch_dinner` カテゴリ、間食には `snack` カテゴリの Food のみ登録できる。

### Controller

`DailyFoodLogsController` のみ (root パス)。全アクション (`index`, `create`, `destroy`) で Turbo Stream レスポンスに対応。`load_dashboard` メソッドが `@meal_sections`, `@period_totals`, `@summary_rows` などダッシュボード表示に必要な全データを組み立てる。

create/destroy 成功後は `render_dashboard_updates` で `#flash` と `#dashboard` の2箇所を Turbo Stream で部分更新する。

### View構成

- `daily_food_logs/index.html.erb` — ページ全体のレイアウトと日付ナビゲーション
- `daily_food_logs/_dashboard.html.erb` — Turbo Stream で置き換えられる `id="dashboard"` の部分テンプレート。食事セクション・カロリーサマリーを含む

### Stimulus Controllers

- `manual_calorie_form_controller` — `manual_calories_enabled` な Food 選択時にカロリー入力フォームをトグル表示
- `section_nav_controller` — day/week/month タブの切り替え
- `copy_controller` — `@daily_summary_text` のクリップボードコピー

### Food マスタ管理

Food レコードは `db/seeds.rb` で一元管理。seeds は冪等に設計されており、既存レコードを更新しシードから除外された Food を削除する。新しい食品を追加する際は seeds.rb を編集して `bin/rails db:seed` を実行する。
