import { Hono } from "hono";
import { serveStatic } from "hono/bun";
import { Database } from "bun:sqlite";
import { join } from "path";

const ROOT = join(import.meta.dir, "..");
const PUBLIC_DIR = join(ROOT, "public");
const DB_PATH = process.env.VTB_DB_PATH ?? join(ROOT, "data", "vibetoolbox.sqlite");

const catalog = await Bun.file(join(ROOT, "catalog.json")).json();
const validIds = new Set<string>(catalog.tools.map((t: { id: string }) => t.id));

export const db = new Database(DB_PATH, { create: true });
db.run(`
  CREATE TABLE IF NOT EXISTS selections (
    slug TEXT PRIMARY KEY,
    tools TEXT NOT NULL,
    created_at TEXT NOT NULL DEFAULT (datetime('now')),
    hits INTEGER NOT NULL DEFAULT 0
  )
`);

const insertSelection = db.prepare(
  "INSERT OR IGNORE INTO selections (slug, tools) VALUES (?, ?)",
);
const getSelection = db.prepare(
  "SELECT tools FROM selections WHERE slug = ?",
);
const bumpHits = db.prepare(
  "UPDATE selections SET hits = hits + 1 WHERE slug = ?",
);

// Content-addressed slug: same selection always maps to the same URL.
function slugFor(tools: string[]): string {
  const canonical = tools.join(",");
  const hash = new Bun.CryptoHasher("sha256").update(canonical).digest("hex");
  return hash.slice(0, 10);
}

function normalizeTools(input: unknown): string[] | null {
  if (!Array.isArray(input) || input.length === 0) return null;
  const cleaned = [...new Set(input.map((t) => String(t).trim().toLowerCase()))]
    .filter((t) => t.length > 0)
    .sort();
  if (cleaned.length === 0) return null;
  const unknown = cleaned.filter((t) => !validIds.has(t));
  if (unknown.length > 0) return null;
  return cleaned;
}

export const app = new Hono();

app.post("/api/select", async (c) => {
  let body: unknown;
  try {
    body = await c.req.json();
  } catch {
    return c.json({ error: "invalid JSON body" }, 400);
  }
  const tools = normalizeTools((body as { tools?: unknown })?.tools);
  if (!tools) {
    return c.json({ error: "tools must be a non-empty array of known tool ids" }, 400);
  }
  const slug = slugFor(tools);
  insertSelection.run(slug, tools.join(","));
  return c.json({
    slug,
    tools,
    command: `curl -fsSL ${siteUrl(c.req.url)}/i/${slug} | bash`,
  });
});

app.get("/i/:slug", async (c) => {
  const slug = c.req.param("slug");
  const row = getSelection.get(slug) as { tools: string } | null;
  if (!row) {
    return c.text(
      `echo "Unknown Vibe Toolbox link. Pick your tools at ${siteUrl(c.req.url)}" >&2; exit 1\n`,
      404,
      { "Content-Type": "text/plain; charset=utf-8" },
    );
  }
  bumpHits.run(slug);
  const script = await Bun.file(join(PUBLIC_DIR, "install.sh")).text();
  const baked = script.replace(
    /^VTB_SELECTION=.*$/m,
    `VTB_SELECTION="${row.tools}"`,
  );
  return c.text(baked, 200, {
    "Content-Type": "text/x-shellscript; charset=utf-8",
    "Cache-Control": "no-cache",
  });
});

app.get("/healthz", (c) => c.text("ok"));

app.use("/*", serveStatic({ root: "./public" }));

function siteUrl(reqUrl: string): string {
  if (process.env.SITE_URL) return process.env.SITE_URL;
  const u = new URL(reqUrl);
  return `${u.protocol}//${u.host}`;
}

if (import.meta.main) {
  const port = Number(process.env.PORT ?? 8080);
  Bun.serve({ port, fetch: app.fetch });
  console.log(`vibetoolbox.dev server on http://localhost:${port}`);
}
