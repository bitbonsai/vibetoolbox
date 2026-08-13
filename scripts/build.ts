// Build script: generates installer/catalog.sh from catalog.json, then
// concatenates installer/*.sh modules into public/install.sh
// Usage: bun scripts/build.ts

import { join } from "path";

const ROOT = join(import.meta.dir, "..");
const INSTALLER_DIR = join(ROOT, "installer");
const OUTPUT = join(ROOT, "public", "install.sh");

const catalog = await Bun.file(join(ROOT, "catalog.json")).json(); // throws on invalid JSON

// Version lives in package.json; the site reads it via catalog.js
const pkg = await Bun.file(join(ROOT, "package.json")).json();
catalog.version = pkg.version;

// --- Generate installer/catalog.sh from catalog.json ---
const rows = catalog.tools.map(
  (t: { id: string; kind: string; target: string; app?: string; bin?: string; name: string; requires?: string[] }) =>
    `    "${[t.id, t.kind, t.target, t.app ?? "", t.bin ?? "", t.name, (t.requires ?? []).join(",")].join("|")}"`,
);

const catalogSh = `# =============================================================================
# TOOL CATALOG (generated from catalog.json by scripts/build.ts — do not edit)
# =============================================================================
# Fields: id|kind|target|app|bin|name|requires

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

console.log(
  `Built public/install.sh from ${MODULES.length} modules (${catalog.tools.length} tools in catalog)`,
);
