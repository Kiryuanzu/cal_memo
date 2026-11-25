import { env } from "cloudflare:test";
import { describe, expect, it } from "vitest";
import app from "../src/index";

const READ = { Authorization: "Bearer test-read-token" };
const SYNC = { Authorization: "Bearer test-sync-token" };

const sampleLogs = [
  { id: 1, date: "2026-11-20", meal_type: "breakfast", food_name: "トースト", calories: 200, protein_g: 6, food_group: "staple", comment: null },
  { id: 2, date: "2026-11-20", meal_type: "lunch", food_name: "カレー", calories: 700, protein_g: 20, food_group: "main", comment: "大盛り" },
  { id: 3, date: "2026-11-21", meal_type: "dinner", food_name: "鮭定食", calories: 600, protein_g: 30, food_group: "main", comment: null },
  { id: 4, date: "2026-11-22", meal_type: "snack", food_name: "プリン", calories: 150, protein_g: 4, food_group: "snack", comment: null },
];

function sync(logs: unknown, headers: Record<string, string> = SYNC) {
  return app.request(
    "/sync",
    { method: "POST", headers: { ...headers, "Content-Type": "application/json" }, body: JSON.stringify({ logs }) },
    env,
  );
}

function get(path: string, headers: Record<string, string> = READ) {
  return app.request(path, { headers }, env);
}

describe("authentication", () => {
  it("rejects read endpoints without a token", async () => {
    expect((await get("/logs", {})).status).toBe(401);
    expect((await get("/summary", {})).status).toBe(401);
  });

  it("rejects the sync token on read endpoints and the read token on sync", async () => {
    expect((await get("/logs", SYNC)).status).toBe(401);
    expect((await sync(sampleLogs, READ)).status).toBe(401);
  });

  it("serves the OpenAPI document without a token", async () => {
    const res = await get("/openapi.json", {});
    expect(res.status).toBe(200);
    const doc = await res.json<{ openapi: string; paths: Record<string, unknown>; servers: { url: string }[] }>();
    expect(doc.openapi).toMatch(/^3\./);
    expect(Object.keys(doc.paths)).toEqual(expect.arrayContaining(["/logs", "/summary"]));
    expect(doc.paths).not.toHaveProperty("/sync");
    expect(doc.servers[0].url).toBe("http://localhost");
  });
});

describe("POST /sync", () => {
  it("replaces all logs and records sync metadata", async () => {
    expect((await sync(sampleLogs)).status).toBe(200);

    const res = await sync([sampleLogs[0]]);
    expect(res.status).toBe(200);
    const body = await res.json<{ log_count: number; last_synced_at: string }>();
    expect(body.log_count).toBe(1);
    expect(body.last_synced_at).toMatch(/^\d{4}-\d{2}-\d{2}T/);

    const { results } = await env.DB.prepare("SELECT id FROM food_logs").all();
    expect(results).toEqual([{ id: 1 }]);
  });

  it("rejects malformed payloads without touching existing data", async () => {
    await sync(sampleLogs);
    const res = await sync([{ id: 9, date: "not-a-date" }]);
    expect(res.status).toBe(400);

    const row = await env.DB.prepare("SELECT COUNT(*) AS n FROM food_logs").first<{ n: number }>();
    expect(row?.n).toBe(4);
  });
});

describe("GET /logs", () => {
  it("returns logs in the requested inclusive range, ordered by date then meal", async () => {
    await sync(sampleLogs);
    const res = await get("/logs?from=2026-11-20&to=2026-11-21");
    expect(res.status).toBe(200);
    const body = await res.json<{ from: string; to: string; last_synced_at: string | null; logs: typeof sampleLogs }>();
    expect(body.from).toBe("2026-11-20");
    expect(body.to).toBe("2026-11-21");
    expect(body.last_synced_at).not.toBeNull();
    expect(body.logs.map((l) => l.id)).toEqual([1, 2, 3]);
    expect(body.logs[1]).toEqual(sampleLogs[1]);
  });

  it("defaults to the last 7 days when no range is given", async () => {
    const res = await get("/logs");
    expect(res.status).toBe(200);
    const body = await res.json<{ from: string; to: string }>();
    const days = (Date.parse(body.to) - Date.parse(body.from)) / 86_400_000;
    expect(days).toBe(6);
  });

  it("rejects invalid dates and reversed or overly long ranges", async () => {
    expect((await get("/logs?from=2026-13-01&to=2026-13-02")).status).toBe(400);
    expect((await get("/logs?from=2026-11-21&to=2026-11-20")).status).toBe(400);
    expect((await get("/logs?from=2024-01-01&to=2026-11-20")).status).toBe(400);
  });
});

describe("GET /summary", () => {
  it("aggregates calories and protein per day with a per-meal breakdown", async () => {
    await sync(sampleLogs);
    const res = await get("/summary?from=2026-11-20&to=2026-11-22");
    expect(res.status).toBe(200);
    const body = await res.json<{
      total: { calories: number; protein_g: number; days_with_logs: number };
      days: { date: string; calories: number; protein_g: number; meals: Record<string, number> }[];
    }>();
    expect(body.total).toEqual({ calories: 1650, protein_g: 60, days_with_logs: 3 });
    expect(body.days[0]).toEqual({
      date: "2026-11-20",
      calories: 900,
      protein_g: 26,
      meals: { breakfast: 200, lunch: 700, dinner: 0, snack: 0 },
    });
    expect(body.days.map((d) => d.date)).toEqual(["2026-11-20", "2026-11-21", "2026-11-22"]);
  });
});
