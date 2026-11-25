import { type Context, Hono, type MiddlewareHandler } from "hono";
import { bearerAuth } from "hono/bearer-auth";
import { buildOpenApiDocument } from "./openapi";

const MEAL_TYPES = ["breakfast", "lunch", "dinner", "snack"] as const;
const MAX_RANGE_DAYS = 366;
const DEFAULT_RANGE_DAYS = 7;
const DAY_MS = 86_400_000;

type FoodLog = {
  id: number;
  date: string;
  meal_type: (typeof MEAL_TYPES)[number];
  food_name: string;
  calories: number;
  protein_g: number;
  food_group: string;
  comment: string | null;
};

const app = new Hono<{ Bindings: Bindings }>();

// Tokens live in Worker secrets, so the middleware is built per request from c.env.
function requireToken(name: "READ_TOKEN" | "SYNC_TOKEN"): MiddlewareHandler<{ Bindings: Bindings }> {
  return (c, next) => {
    const token = c.env[name];
    if (!token) return Promise.resolve(c.json({ error: `${name} is not configured` }, 500));
    // bearerAuth is typed against the default env; the cast only widens c.
    return bearerAuth({ token })(c as Context, next);
  };
}

app.get("/openapi.json", (c) => c.json(buildOpenApiDocument(new URL(c.req.url).origin)));

app.use("/logs", requireToken("READ_TOKEN"));
app.use("/summary", requireToken("READ_TOKEN"));
app.use("/sync", requireToken("SYNC_TOKEN"));

app.post("/sync", async (c) => {
  const body = await c.req.json().catch(() => null);
  const logs = (body as { logs?: unknown } | null)?.logs;
  if (!Array.isArray(logs)) return c.json({ error: "body must be {\"logs\": [...]}" }, 400);

  const invalidIndex = logs.findIndex((log) => !isFoodLog(log));
  if (invalidIndex !== -1) return c.json({ error: `logs[${invalidIndex}] is invalid` }, 400);

  const syncedAt = new Date().toISOString();
  // One batch = one transaction: either everything is replaced or nothing changes.
  // json_each() expands the JSON array inside SQLite, so the whole upload is a single
  // INSERT no matter how many logs there are.
  await c.env.DB.batch([
    c.env.DB.prepare("DELETE FROM food_logs"),
    c.env.DB.prepare(
      `INSERT INTO food_logs (id, date, meal_type, food_name, calories, protein_g, food_group, comment)
       SELECT json_extract(value, '$.id'), json_extract(value, '$.date'), json_extract(value, '$.meal_type'),
              json_extract(value, '$.food_name'), json_extract(value, '$.calories'), json_extract(value, '$.protein_g'),
              json_extract(value, '$.food_group'), json_extract(value, '$.comment')
       FROM json_each(?1)`,
    ).bind(JSON.stringify(logs)),
    c.env.DB.prepare(
      `INSERT INTO sync_meta (id, last_synced_at, log_count) VALUES (1, ?1, ?2)
       ON CONFLICT (id) DO UPDATE SET last_synced_at = excluded.last_synced_at, log_count = excluded.log_count`,
    ).bind(syncedAt, logs.length),
  ]);

  return c.json({ log_count: logs.length, last_synced_at: syncedAt });
});

app.get("/logs", async (c) => {
  const range = parseRange(c.req.query("from"), c.req.query("to"));
  if ("error" in range) return c.json({ error: range.error }, 400);

  const { results } = await c.env.DB.prepare(
    `SELECT id, date, meal_type, food_name, calories, protein_g, food_group, comment
     FROM food_logs WHERE date BETWEEN ?1 AND ?2
     ORDER BY date, CASE meal_type WHEN 'breakfast' THEN 0 WHEN 'lunch' THEN 1 WHEN 'dinner' THEN 2 ELSE 3 END, id`,
  )
    .bind(range.from, range.to)
    .all<FoodLog>();

  return c.json({ ...range, last_synced_at: await lastSyncedAt(c.env.DB), logs: results });
});

app.get("/summary", async (c) => {
  const range = parseRange(c.req.query("from"), c.req.query("to"));
  if ("error" in range) return c.json({ error: range.error }, 400);

  const { results } = await c.env.DB.prepare(
    `SELECT date, meal_type, SUM(calories) AS calories, SUM(protein_g) AS protein_g
     FROM food_logs WHERE date BETWEEN ?1 AND ?2
     GROUP BY date, meal_type ORDER BY date`,
  )
    .bind(range.from, range.to)
    .all<{ date: string; meal_type: string; calories: number; protein_g: number }>();

  const days = new Map<string, { date: string; calories: number; protein_g: number; meals: Record<string, number> }>();
  for (const row of results) {
    let day = days.get(row.date);
    if (!day) {
      day = { date: row.date, calories: 0, protein_g: 0, meals: Object.fromEntries(MEAL_TYPES.map((m) => [m, 0])) };
      days.set(row.date, day);
    }
    day.calories += row.calories;
    day.protein_g += row.protein_g;
    day.meals[row.meal_type] = (day.meals[row.meal_type] ?? 0) + row.calories;
  }

  const dayList = [...days.values()];
  return c.json({
    ...range,
    last_synced_at: await lastSyncedAt(c.env.DB),
    total: {
      calories: dayList.reduce((sum, d) => sum + d.calories, 0),
      protein_g: dayList.reduce((sum, d) => sum + d.protein_g, 0),
      days_with_logs: dayList.length,
    },
    days: dayList,
  });
});

async function lastSyncedAt(db: D1Database): Promise<string | null> {
  const row = await db.prepare("SELECT last_synced_at FROM sync_meta WHERE id = 1").first<{ last_synced_at: string }>();
  return row?.last_synced_at ?? null;
}

function parseRange(from?: string, to?: string): { from: string; to: string } | { error: string } {
  if (!from && !to) {
    const today = todayInTokyo();
    return { from: shiftDate(today, -(DEFAULT_RANGE_DAYS - 1)), to: today };
  }
  if (!from || !to) return { error: "specify both from and to, or neither" };
  if (!isIsoDate(from) || !isIsoDate(to)) return { error: "from/to must be YYYY-MM-DD" };
  if (from > to) return { error: "from must not be after to" };
  if ((Date.parse(to) - Date.parse(from)) / DAY_MS + 1 > MAX_RANGE_DAYS) {
    return { error: `range must be at most ${MAX_RANGE_DAYS} days` };
  }
  return { from, to };
}

// Workers run in UTC; cal_memo's dates are Japan-local.
function todayInTokyo(): string {
  return new Intl.DateTimeFormat("sv-SE", { timeZone: "Asia/Tokyo" }).format(new Date());
}

function shiftDate(date: string, days: number): string {
  return new Date(Date.parse(date) + days * DAY_MS).toISOString().slice(0, 10);
}

function isIsoDate(value: unknown): value is string {
  if (typeof value !== "string" || !/^\d{4}-\d{2}-\d{2}$/.test(value)) return false;
  const time = Date.parse(value);
  return !Number.isNaN(time) && new Date(time).toISOString().slice(0, 10) === value;
}

function isFoodLog(value: unknown): value is FoodLog {
  if (typeof value !== "object" || value === null) return false;
  const v = value as Record<string, unknown>;
  return (
    Number.isInteger(v.id) &&
    isIsoDate(v.date) &&
    MEAL_TYPES.includes(v.meal_type as FoodLog["meal_type"]) &&
    typeof v.food_name === "string" &&
    Number.isInteger(v.calories) &&
    Number.isInteger(v.protein_g) &&
    typeof v.food_group === "string" &&
    (v.comment === null || typeof v.comment === "string")
  );
}

export default app;
