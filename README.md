# Cal Memo

摂取カロリーを手早くメモするための小さな Rails アプリです。

## 機能

- 食品名、カロリー、日時、メモを記録
- 記録の一覧表示
- 今日の合計カロリー表示
- 記録の編集と削除

## 動かし方

```bash
mise install
bin/rails db:migrate
bin/dev
```

ブラウザで `http://localhost:3000` を開くと使えます。

## テスト

```bash
bin/rails test
```
