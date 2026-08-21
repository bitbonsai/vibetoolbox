// Build script: generates installer/catalog.sh from catalog.json,
// concatenates installer/*.sh modules into public/install.sh, and renders
// site/pages/*.html (with site/partials includes) into public/*.html
// Usage: bun scripts/build.ts

import { createHash } from "node:crypto";
import { join } from "path";
import { readdir } from "node:fs/promises";

const ROOT = join(import.meta.dir, "..");
const INSTALLER_DIR = join(ROOT, "installer");
const OUTPUT = join(ROOT, "public", "install.sh");

const catalog = await Bun.file(join(ROOT, "catalog.json")).json(); // throws on invalid JSON

// Version lives in package.json; the site reads it via catalog.js
const pkg = await Bun.file(join(ROOT, "package.json")).json();
catalog.version = pkg.version;

// --- Generate installer/catalog.sh from catalog.json ---
const rows = catalog.tools.map(
  (t: { id: string; kind: string; target: string; app?: string; bin?: string; name: string; requires?: string[]; post?: string }) =>
    `    "${[t.id, t.kind, t.target, t.app ?? "", t.bin ?? "", t.name, (t.requires ?? []).join(","), t.post ?? ""].join("|")}"`,
);

const catalogSh = `# =============================================================================
# TOOL CATALOG (generated from catalog.json by scripts/build.ts — do not edit)
# =============================================================================
# Fields: id|kind|target|app|bin|name|requires|post

CATALOG=(
${rows.join("\n")}
)
`;
await Bun.write(join(INSTALLER_DIR, "catalog.sh"), catalogSh);

// Copy catalog.json into public/ so the picker can fetch it
await Bun.write(
  join(ROOT, "public", "catalog.json"),
  Bun.file(join(ROOT, "catalog.json")),
);

// Emit catalog.js so the picker renders synchronously (no fetch pop-in)
await Bun.write(
  join(ROOT, "public", "catalog.js"),
  `window.VTB_CATALOG = ${JSON.stringify(catalog)};\n`,
);

// Module order matters — functions must be defined before use in main.sh
const MODULES = [
  "header.sh",
  "common.sh",
  "catalog.sh",
  "selection.sh",
  "uninstall.sh",
  "prefs.sh",
  "prereqs.sh",
  "tools.sh",
  "update.sh",
  "autoupdate.sh",
  "git-config.sh",
  "github-cli.sh",
  "shell.sh",
  "main.sh",
];

const parts: string[] = [];
for (const module of MODULES) {
  const file = Bun.file(join(INSTALLER_DIR, module));
  if (!(await file.exists())) {
    console.error(`ERROR: Missing module: ${join(INSTALLER_DIR, module)}`);
    process.exit(1);
  }
  let text = await file.text();
  // package.json is the version source of truth; update.sh greps ^VERSION=
  if (module === "common.sh") {
    text = text.replace(/^VERSION="[^"]*"/m, `VERSION="${pkg.version}"`);
  }
  parts.push(text);
}
await Bun.write(OUTPUT, parts.join("\n"));

// --- Render site/pages/*.html with site/partials includes ---
// Include syntax: <!-- @include name.html key="value" ... -->
// Partials use {{key}} placeholders; unknown keys render empty.
const PAGES_DIR = join(ROOT, "site", "pages");
const PARTIALS_DIR = join(ROOT, "site", "partials");
const INCLUDE_RE = /<!--\s*@include\s+(\S+?)((?:\s+\w+="[^"]*")*)\s*-->/g;

async function renderPage(html: string): Promise<string> {
  const matches = [...html.matchAll(INCLUDE_RE)];
  for (const m of matches) {
    const partialFile = Bun.file(join(PARTIALS_DIR, m[1]));
    if (!(await partialFile.exists())) {
      console.error(`ERROR: Missing partial: ${m[1]}`);
      process.exit(1);
    }
    const vars: Record<string, string> = {};
    for (const [, key, value] of m[2].matchAll(/(\w+)="([^"]*)"/g)) {
      vars[key] = value;
    }
    const partial = (await partialFile.text())
      .replace(/\{\{(\w+)\}\}/g, (_, key) => vars[key] ?? "")
      .trimEnd();
    html = html.replace(m[0], partial);
  }
  return html;
}

// Shell syntax highlighting for static <pre><code> blocks (the dynamic
// ones use the same tokenizer in picker.js)
const escapeHtml = (s: string) =>
  s.replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;");
const decodeHtml = (s: string) =>
  s.replace(/&lt;/g, "<").replace(/&gt;/g, ">").replace(/&amp;/g, "&");

function highlightLine(line: string): string {
  let comment = "";
  const ci = line.indexOf("#");
  if (ci === 0 || (ci > 0 && line[ci - 1] === " ")) {
    comment = line.slice(ci);
    line = line.slice(0, ci);
  }
  let expectCmd = true;
  const out = line.split(/(\s+)/).map((tok) => {
    if (!tok.trim()) return escapeHtml(tok);
    const e = escapeHtml(tok);
    if (tok === "|" || tok === "&&" || tok === ";") { expectCmd = true; return `<span class="tok-pipe">${e}</span>`; }
    if (/^https?:\/\//.test(tok)) { expectCmd = false; return `<span class="tok-url">${e}</span>`; }
    if (/^-/.test(tok)) { expectCmd = false; return `<span class="tok-flag">${e}</span>`; }
    if (expectCmd) { expectCmd = false; return `<span class="tok-cmd">${e}</span>`; }
    return e;
  });
  if (comment) out.push(`<span class="tok-comment">${escapeHtml(comment)}</span>`);
  return out.join("");
}

const highlightShell = (text: string) =>
  text.split("\n").map(highlightLine).join("\n");

function highlightPage(html: string): string {
  return html.replace(
    /(<pre[^>]*><code[^>]*>)([\s\S]*?)(<\/code><\/pre>)/g,
    (_, open, body, close) =>
      body.includes("<span") || body.trim() === ""
        ? open + body + close
        : open + highlightShell(decodeHtml(body)) + close,
  );
}

// Content hashes keep CDN-cached assets immutable without requiring a release bump.
const assets = ["styles.css", "catalog.js", "picker.js", "alpine.min.js"];
const assetHashes = Object.fromEntries(await Promise.all(assets.map(async (asset) => [
  asset,
  createHash("sha256").update(await Bun.file(join(ROOT, "public", asset)).bytes()).digest("hex").slice(0, 12),
])));
const bustAssets = (html: string) =>
  html.replace(
    /((?:href|src)=")(styles\.css|catalog\.js|picker\.js|alpine\.min\.js)(")/g,
    (_, open, asset, close) => `${open}${asset}?v=${assetHashes[asset]}${close}`,
  );

const pageNames = (await readdir(PAGES_DIR)).filter((n) => n.endsWith(".html"));
for (const name of pageNames) {
  const source = await Bun.file(join(PAGES_DIR, name)).text();
  const rendered =
    "<!-- GENERATED from site/pages/" + name + " by scripts/build.ts - do not edit -->\n" +
    bustAssets(highlightPage(await renderPage(source)));
  await Bun.write(join(ROOT, "public", name), rendered);
}

console.log(
  `Built public/install.sh from ${MODULES.length} modules (${catalog.tools.length} tools in catalog); rendered ${pageNames.length} pages`,
);

// --- Generate public/tools.md (llms.txt-friendly catalog dump) ---
const mdLines: string[] = [
  "# Vibe Toolbox tool catalog",
  "",
  `${catalog.tools.length} tools across ${catalog.categories.length} categories. Each lists what it is, why it is in the catalog, and how it installs.`,
  "",
];
for (const cat of catalog.categories) {
  const catTools = catalog.tools.filter((t: { category: string }) => t.category === cat.id);
  if (!catTools.length) continue;
  mdLines.push(`## ${cat.name}`, "");
  for (const t of catTools) {
    mdLines.push(`### ${t.name} (\`${t.id}\`)`, "", t.desc, "");
    if (t.why) mdLines.push(`**Why:** ${t.why}`, "");
    const req = t.requires?.length ? ` (requires ${t.requires.join(", ")})` : "";
    mdLines.push(`- Install: ${t.kind} \`${t.target}\`${req}`, `- Homepage: ${t.url}`, "");
  }
}
mdLines.push("## Presets", "");
for (const [id, ids] of Object.entries(catalog.presets)) {
  mdLines.push(`- **${id}**: ${(ids as string[]).join(", ")}`);
}
mdLines.push("");
await Bun.write(join(ROOT, "public", "tools.md"), mdLines.join("\n"));
