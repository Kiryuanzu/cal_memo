declare namespace Cloudflare {
  interface Env {
    DB: D1Database;
    READ_TOKEN: string;
    SYNC_TOKEN: string;
  }
}

type Bindings = Cloudflare.Env;
