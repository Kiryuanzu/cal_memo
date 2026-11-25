-- Synced copy of cal_memo's daily_food_logs. Replaced wholesale on every sync.
CREATE TABLE food_logs (
  id INTEGER PRIMARY KEY,
  date TEXT NOT NULL,
  meal_type TEXT NOT NULL,
  food_name TEXT NOT NULL,
  calories INTEGER NOT NULL,
  protein_g INTEGER NOT NULL,
  food_group TEXT NOT NULL,
  comment TEXT
);
CREATE INDEX index_food_logs_on_date ON food_logs (date);

CREATE TABLE sync_meta (
  id INTEGER PRIMARY KEY CHECK (id = 1),
  last_synced_at TEXT NOT NULL,
  log_count INTEGER NOT NULL
);
