# muse_api

cal_memo の食事記録を Meta Muse に読み取り専用で渡すための API。Cloudflare Workers + D1 で動く。

```
[Mac: cal_memo (SQLite, 正本)]
   │  bin/rails muse:sync      ← 手動
   │  POST /sync  (SYNC_TOKEN)
   ▼
[Cloudflare Workers + D1]
   │  GET /logs, /summary      (READ_TOKEN)
   │  GET /openapi.json        (認証なし)
   ▼
[Meta Muse カスタムコネクタ]
```

## エンドポイント

| メソッド | パス | 認証 | 内容 |
|---|---|---|---|
| GET | `/logs?from=YYYY-MM-DD&to=YYYY-MM-DD` | READ_TOKEN | 期間内の食事一覧。省略時は直近 7 日 (JST) |
| GET | `/summary?from=&to=` | READ_TOKEN | 日別の kcal / たんぱく質合計と食事区分ごとの内訳 |
| GET | `/openapi.json` | なし | Muse に読ませる API 仕様 |
| POST | `/sync` | SYNC_TOKEN | 全件置き換え。cal_memo の `muse:sync` 専用 |

期間は最大 366 日。レスポンスの `last_synced_at` で、いつ時点のデータかが分かる。

## 初回デプロイ

```bash
cd muse_api
npm install
npx wrangler login                         # ブラウザで Cloudflare にログイン
npx wrangler d1 create cal_memo_muse       # 出力の database_id を wrangler.jsonc に貼る
npm run db:migrate:remote                  # 本番 D1 にテーブルを作る
npx wrangler secret put READ_TOKEN         # Muse 用 (例: openssl rand -hex 32 で生成)
npx wrangler secret put SYNC_TOKEN         # 同期用 (READ_TOKEN とは別の値)
npm run deploy                             # https://cal-memo-muse-api.<subdomain>.workers.dev が出力される
```

## 同期 (手動)

```bash
cd ..   # cal_memo ルート
MUSE_API_URL=https://cal-memo-muse-api.<subdomain>.workers.dev \
MUSE_API_SYNC_TOKEN=<SYNC_TOKEN> \
bin/rails muse:sync
```

## Muse への登録

Muse でカスタムコネクタを作るよう頼み、`https://…workers.dev/openapi.json` の URL を渡す。トークンを聞かれたら READ_TOKEN を、チャットではなく認証情報の入力欄に入れる。

## ローカル開発

```bash
printf 'READ_TOKEN=local-read\nSYNC_TOKEN=local-sync\n' > .dev.vars
npm run db:migrate:local
npm run dev                                # http://localhost:8787
npm test                                   # Workers ランタイム (Miniflare) 上で Vitest
npm run typecheck
```

---

## Cloudflare の仕組みメモ

### Workers: どこで、どう動くか

- コードは Cloudflare の全拠点 (エッジ) に配られ、リクエストを受けた拠点で動く。サーバーやコンテナを常駐させる PaaS とは違い、リクエストが来るたびに V8 の isolate (軽量なサンドボックス) が立ち上がる。コールドスタートが数 ms なので、無料枠でも「スリープ」がない。
- 実行環境は Node.js ではなく `workerd` (Web 標準 API + Cloudflare 独自 API)。`fetch` や `Request`/`Response`、`Intl` は使えるが、Node のファイルシステムなどはない。Hono はこの Web 標準の上で動くので相性がよい。
- エントリポイントは `export default { fetch(request, env, ctx) }` 形式。Hono の `app` はこの形を満たしているので `export default app` で済む (`src/index.ts`)。
- Workers のタイムゾーンは UTC。cal_memo の日付は日本時間なので、「今日」は `Intl.DateTimeFormat` で Asia/Tokyo を指定して求めている。

### バインディング: `env` に何が入るか

- `wrangler.jsonc` に書いた D1 や、`wrangler secret put` で登録したシークレットは、実行時に `env` (Hono では `c.env`) に注入される。これを「バインディング」と呼ぶ。
- D1 は URL や接続文字列を持たない。`env.DB` というオブジェクト経由でしか触れないので、DB を外部に公開する設定ミスが起きにくい。
- シークレットはダッシュボードでも値を再表示できない。ローカルでは `.dev.vars` が同じ役割を担う (git 管理外)。

### D1: SQLite をエッジで

- 中身は SQLite。cal_memo の SQLite と同じ SQL 方言がそのまま使える。
- `env.DB.prepare(sql).bind(...).all()` / `.first()` で問い合わせる。`?1` のような番号付きプレースホルダが使える。
- `env.DB.batch([...])` は複数の文を 1 回の往復で送り、1 つのトランザクションとして実行する。途中で失敗すれば全体が巻き戻る。`/sync` の「全件削除 → 全件挿入 → メタ情報更新」はこれで原子的に行っている。
- 1 回の Worker 呼び出しで発行できるクエリ数や、1 つのバインド値の大きさには上限がある。行ごとに INSERT すると件数に比例してクエリが増えるため、`/sync` では JSON 配列を 1 つの値として渡し、SQLite の `json_each()` で展開して 1 文で挿入している。2026-11 時点で約 2300 件 ≈ 400KB 程度。今後バインド値の上限に近づいたら、分割送信を検討する。
- スキーマ変更は `migrations/*.sql` に連番で置き、`wrangler d1 migrations apply` で適用する。適用済みかどうかは D1 内の `d1_migrations` テーブルで管理される (Rails の `schema_migrations` と同じ発想)。

### Wrangler: CLI と設定

- `wrangler dev` は手元で `workerd` と、SQLite ファイルで模した D1 を起動する (`.wrangler/state/` に保存)。`--remote` を付けると本番のリソースを使う。
- `wrangler deploy` は TypeScript を esbuild でまとめてアップロードする。ビルド設定は不要。
- `compatibility_date` は、ランタイムの挙動をその日付時点に固定するためのもの。Cloudflare 側の更新で既存コードが壊れないようにする仕組み。

### テスト: `@cloudflare/vitest-plugin`

- Vitest のテストを Node ではなく `workerd` の中で実行する。本番と同じランタイムで、D1 も Miniflare が提供する本物の SQLite になる。
- テストごとにストレージが分離されるので、テスト間でデータが漏れない。マイグレーションは `vitest.config.ts` で読み込み、`test/apply-migrations.ts` で毎回適用している。
- 旧名は `@cloudflare/vitest-pool-workers` (非推奨)。

### 無料枠 (2026-11-24 に公式ドキュメントで確認)

Free プランは上限を超えるとエラーで止まり、課金はされない。有料の Workers Paid (月 $5〜) は自分で選んだときだけ切り替わる。

| 項目 | Free の上限 | 超えたとき |
|---|---|---|
| Workers リクエスト | 1 日 10 万件 (UTC 0 時リセット) | Error 1027 |
| Workers CPU 時間 | 1 リクエスト 10ms (DB や fetch の待ち時間は含まない) | Error 1102 |
| D1 読み取り / 書き込み | 1 日 500 万行 / 10 万行 | クエリがエラー |
| D1 ストレージ | アカウント全体 5GB、1 DB 500MB | 削除するまで書き込み不可 |
| D1 クエリ数 | 1 回の呼び出しで 50 (`batch()` は 1 と数える) | エラー |
| D1 バインド値 / SQL 文 | 1 つの値 2MB、1 文 100KB | エラー |

- 1 回の同期の書き込みは約 2300 行で、1 日の上限の数 % 程度。
- `/sync` は約 400KB の JSON を処理するため、CPU 時間 10ms の上限に注意。`wrangler dev` では上限がかからないので、デプロイ後に実測する。
- Workers Logs は 2026-12-01 から料金体系が変わるため、`wrangler.jsonc` で無効にしている。

出典: [Workers Pricing](https://developers.cloudflare.com/workers/platform/pricing/) / [Workers Limits](https://developers.cloudflare.com/workers/platform/limits/) / [D1 Pricing](https://developers.cloudflare.com/d1/platform/pricing/) / [D1 Limits](https://developers.cloudflare.com/d1/platform/limits/) / [Workers Logs](https://developers.cloudflare.com/workers/observability/logs/workers-logs/)
