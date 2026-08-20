import { describe, expect, test, beforeAll, afterAll } from "bun:test";
import { createHash } from "node:crypto";
import { mkdtempSync, rmSync, mkdirSync, writeFileSync, existsSync, readFileSync } from "fs";
import { tmpdir } from "os";
import { join } from "path";

const ROOT = join(import.meta.dir, "..");
const SCRIPT = join(ROOT, "public", "install.sh");

const script = () => readFileSync(SCRIPT, "utf8");

// Everything before the `clear` at the top of main.sh: helpers, catalog,
// selection engine, prefs — safe to source and drive directly in bash.
const scriptPrelude = () => {
  const s = script();
  const idx = s.indexOf("\nclear\n");
  if (idx === -1) throw new Error("could not find clear marker in install.sh");
  return s.slice(0, idx);
};

function runBash(
  snippet: string,
  opts: { home?: string; args?: string[] } = {},
): { stdout: string; stderr: string; exitCode: number } {
  const home = opts.home ?? mkdtempSync(join(tmpdir(), "vtb-test-"));
  const proc = Bun.spawnSync(["bash", "-c", snippet, "bash", ...(opts.args ?? [])], {
    env: { ...process.env, HOME: home, VTB_TEST: "1" },
    stdin: new Uint8Array(),
  });
  return {
    stdout: proc.stdout.toString(),
    stderr: proc.stderr.toString(),
    exitCode: proc.exitCode,
  };
}

describe("built script", () => {
  test("exists and passes bash -n", () => {
    expect(existsSync(SCRIPT)).toBe(true);
    const proc = Bun.spawnSync(["bash", "-n", SCRIPT]);
    expect(proc.exitCode).toBe(0);
  });

  test("has no Miro-internal remnants", () => {
    const s = script().toLowerCase();
    for (const banned of ["miro", "artifactory", "warp-cli", "vctk", "opencode-legacy"]) {
      expect(s).not.toContain(banned);
    }
  });

  test("catalog matches catalog.json", () => {
    const catalog = JSON.parse(readFileSync(join(ROOT, "catalog.json"), "utf8"));
    for (const tool of catalog.tools) {
      expect(script()).toContain(`"${tool.id}|`);
    }
  });

  test("eza replaces tree and documents code stats", () => {
    const catalog = JSON.parse(readFileSync(join(ROOT, "catalog.json"), "utf8"));
    expect(catalog.tools.some((tool: { id: string }) => tool.id === "tree")).toBe(false);
    expect(catalog.presets.essentials).not.toContain("tree");
    expect(catalog.presets.recommended).not.toContain("tree");
    expect(catalog.tools.find((tool: { id: string }) => tool.id === "eza").try).toBe("eza --code");
  });

  test("recommended uses Pi and includes Worktrunk setup", () => {
    const catalog = JSON.parse(readFileSync(join(ROOT, "catalog.json"), "utf8"));
    const worktrunk = catalog.tools.find((tool: { id: string }) => tool.id === "worktrunk");
    const caveman = catalog.tools.find((tool: { id: string }) => tool.id === "caveman");
    expect(catalog.presets.recommended).toContain("pi");
    expect(catalog.presets.recommended).not.toContain("claude-code");
    expect(catalog.presets.recommended).not.toContain("opencode");
    expect(catalog.presets.recommended).toContain("caveman");
    expect(caveman.requires).toContain("bun");
    expect(caveman.requires).not.toContain("claude-code");
    expect(script()).toContain('bunx skills add "$target" -g -y -s "$id"');
    expect(catalog.presets.recommended).toContain("worktrunk");
    expect(catalog.presets.recommended).toContain("agent-browser");
    expect(catalog.presets.recommended).toContain("shottr");
    expect(catalog.presets.recommended).toContain("uv");
    expect(catalog.tools.find((tool: { id: string }) => tool.id === "uv").target).toBe("uv");
    expect(worktrunk.requires).toContain("bun");
    expect(worktrunk.post).toContain("max-sixty/worktrunk@worktrunk");
  });

  test("site assets use content hashes", () => {
    const html = readFileSync(join(ROOT, "public", "index.html"), "utf8");
    for (const asset of ["styles.css", "catalog.js", "picker.js", "alpine.min.js"]) {
      const hash = createHash("sha256")
        .update(readFileSync(join(ROOT, "public", asset)))
        .digest("hex")
        .slice(0, 12);
      expect(html).toContain(`${asset}?v=${hash}`);
    }
  });

  test("tools search starts filtering at two characters", () => {
    const html = readFileSync(join(ROOT, "public", "tools.html"), "utf8");
    const picker = readFileSync(join(ROOT, "public", "picker.js"), "utf8");
    expect(html).toContain('x-model="query"');
    expect(html).toContain("No tools match that search");
    expect(picker).toContain("this.searchTerm().length >= 2");
  });

  test("picker cards link to tool details", () => {
    const html = readFileSync(join(ROOT, "public", "index.html"), "utf8");
    expect(html).toContain("'/tools?tool=' + encodeURIComponent(tool.id)");
    expect(html).toContain("More info");
  });

  test("page menu auto-closes", () => {
    const html = readFileSync(join(ROOT, "public", "index.html"), "utf8");
    const picker = readFileSync(join(ROOT, "public", "picker.js"), "utf8");
    expect(html).toContain("mobile-menu-toggle");
    for (const path of ["/tools", "/about", "/docs", "/next-steps"]) expect(html).toContain(`href="${path}"`);
    expect(picker).toContain("mobilePagesTimer = setTimeout");
    expect(picker).toContain("}, 5000)");
  });

  test("next steps explains menu visits", () => {
    const html = readFileSync(join(ROOT, "public", "next-steps.html"), "utf8");
    expect(html).toContain('x-show="!installed.length"');
    expect(html).toContain("This is the post-install guide");
    expect(html).toContain("Ghostty opens in <code>~/dev</code> instead of your home folder");
    const source = readFileSync(join(ROOT, "site", "pages", "next-steps.html"), "utf8");
    expect(source).toContain("working-directory = ~/dev");
  });

  test("site follows system color scheme including syntax colors", () => {
    const styles = readFileSync(join(ROOT, "public", "styles.css"), "utf8");
    expect(styles).toContain("@media (prefers-color-scheme: light)");
    expect(styles).toContain("--green: #16763f");
    expect(styles).toContain(".tok-cmd { color: var(--green); }");
    expect(styles).toContain(".tok-flag { color: var(--orange); }");
    expect(styles).toContain(".tok-url { color: var(--blue); }");
  });

  test("site uses rem units and a minor-third type scale", () => {
    const styles = readFileSync(join(ROOT, "public", "styles.css"), "utf8");
    expect(styles).not.toMatch(/-?\d*\.?\d+px\b/);
    expect(styles).toContain("--type-xs: 0.75rem");
    expect(styles).toContain("--type-base: 1rem");
    expect(styles).toContain("--type-md: 1.2rem");
    expect(styles).toContain("--type-lg: 1.44rem");
  });
});

describe("selection", () => {
  test("no selection: exits 0 with picker pointer, installs nothing", () => {
    const r = runBash(`bash ${SCRIPT}`);
    expect(r.exitCode).toBe(0);
    expect(r.stdout).toContain("No tools selected");
    expect(r.stdout).toContain("vibetoolbox.dev");
  });

  test("unknown-only selection: exits 1", () => {
    const r = runBash(`bash ${SCRIPT} --with bogus,fake`);
    expect(r.exitCode).toBe(1);
    expect(r.stdout).toContain("Unknown tool 'bogus'");
  });

  test("resolve_selection pulls in and deduplicates dependencies", () => {
    const home = mkdtempSync(join(tmpdir(), "vtb-test-"));
    writeFileSync(join(home, "prelude.sh"), scriptPrelude());
    const r = runBash(
      `source "$HOME/prelude.sh"; resolve_selection "trash-cli,caveman"; selection_csv`,
      { home },
    );
    const ids = r.stdout.trim().split(",");
    expect(ids).toContain("trash-cli");
    expect(ids).toContain("bun");
    expect(ids).toContain("caveman");
    expect(ids).not.toContain("claude-code");
    expect(ids.filter((id) => id === "bun")).toHaveLength(1);
  });

  test("--all selects the whole catalog", () => {
    const home = mkdtempSync(join(tmpdir(), "vtb-test-"));
    writeFileSync(join(home, "prelude.sh"), scriptPrelude());
    const r = runBash(
      `source "$HOME/prelude.sh"; resolve_selection "all"; echo "\${#SELECTED_IDS[@]}"`,
      { home },
    );
    const catalog = JSON.parse(readFileSync(join(ROOT, "catalog.json"), "utf8"));
    expect(Number(r.stdout.trim())).toBe(catalog.tools.length);
  });

  test("baked VTB_SELECTION wins over saved config", () => {
    const s = script();
    const baked = s.replace(/^VTB_SELECTION=.*$/m, 'VTB_SELECTION="jq"');
    const home = mkdtempSync(join(tmpdir(), "vtb-test-"));
    writeFileSync(join(home, "baked.sh"), baked);
    // No brew in a bare temp HOME... jq status scan runs before installs,
    // so cut the run right after the scan by checking output only.
    const proc = Bun.spawnSync(["bash", join(home, "baked.sh")], {
      env: { ...process.env, HOME: home, VTB_TEST: "1", PATH: "/usr/bin:/bin" },
      stdin: new Uint8Array(),
    });
    const out = proc.stdout.toString();
    expect(out).toContain("System check");
    expect(out).toContain("jq");
    expect(out).not.toContain("No tools selected");
  });
});

describe("prefs", () => {
  test("save_config persists the selection, load_config restores it", () => {
    const home = mkdtempSync(join(tmpdir(), "vtb-test-"));
    writeFileSync(join(home, "prelude.sh"), scriptPrelude());
    const r = runBash(
      `source "$HOME/prelude.sh"
       resolve_selection "ghostty,starship"
       save_config
       SELECTED_IDS=()
       load_config
       echo "$SAVED_VTB_SELECTED"`,
      { home },
    );
    expect(r.stdout.trim()).toBe("ghostty,starship");
  });
});

describe("generated app config", () => {
  test("Cursor selection installs its CLI", () => {
    const s = script();
    expect(s).toContain("/Applications/Cursor.app/Contents/Resources/app/bin/cursor");
    expect(s).toContain('ln -sf "$cursor_cli" "$bin_dir/cursor"');
  });

  test("Ghostty starts fresh setups in ~/dev and preserves existing config", () => {
    const home = mkdtempSync(join(tmpdir(), "vtb-test-"));
    writeFileSync(join(home, "prelude.sh"), scriptPrelude());

    const fresh = runBash(
      `source "$HOME/prelude.sh"; resolve_selection "ghostty"; do_write_configs >/dev/null`,
      { home },
    );
    expect(fresh.exitCode).toBe(0);
    const configPath = join(home, ".config", "ghostty", "config");
    expect(readFileSync(configPath, "utf8")).toContain("working-directory = ~/dev");

    writeFileSync(configPath, "theme = custom\n");
    const existing = runBash(
      `source "$HOME/prelude.sh"; resolve_selection "ghostty"; do_write_configs >/dev/null`,
      { home },
    );
    expect(existing.exitCode).toBe(0);
    expect(readFileSync(configPath, "utf8")).toBe("theme = custom\n");
  });
});

describe("generated shell config", () => {
  test("aliases are runtime-guarded and c never bypasses permissions", () => {
    const s = script();
    expect(s).toContain('command -v eza >/dev/null');
    expect(s).toContain('command -v rg >/dev/null');
    expect(s).toContain('alias c="claude --permission-mode auto"');
    expect(s).toContain("zconf() {");
    expect(s).toContain('zed "$HOME/.zshrc"');
    expect(s).toContain('nvim "$HOME/.zshrc"');
    expect(s).toContain('nano "$HOME/.zshrc"');
    expect(s).not.toContain('open -t "$HOME/.zshrc"');
    expect(s).not.toContain("bypassPermissions");
    expect(s).not.toContain("dangerously-skip-permissions");
  });

  test("launchd agent is weekly with the vibetoolbox label", () => {
    const s = script();
    expect(s).toContain("dev.vibetoolbox.update");
    expect(s).toContain("<key>Weekday</key>");
  });
});

describe("uninstall", () => {
  test("removes config dir, logs, zshrc lines", () => {
    const home = mkdtempSync(join(tmpdir(), "vtb-test-"));
    mkdirSync(join(home, ".config", "vibetoolbox"), { recursive: true });
    writeFileSync(join(home, ".config", "vibetoolbox", "config"), "VTB_VERSION=1.0\n");
    writeFileSync(join(home, ".vibetoolbox-install.log"), "log\n");
    writeFileSync(
      join(home, ".zshrc"),
      '# keep me\n# Vibe Toolbox (managed - do not edit this block)\n[ -f "$HOME/.config/vibetoolbox/env.zsh" ] && source "$HOME/.config/vibetoolbox/env.zsh"\n[ -f "$HOME/.config/vibetoolbox/aliases.zsh" ] && source "$HOME/.config/vibetoolbox/aliases.zsh"\n',
    );
    const r = runBash(`bash ${SCRIPT} --uninstall`, { home });
    expect(r.exitCode).toBe(0);
    expect(existsSync(join(home, ".config", "vibetoolbox"))).toBe(false);
    expect(existsSync(join(home, ".vibetoolbox-install.log"))).toBe(false);
    const zshrc = readFileSync(join(home, ".zshrc"), "utf8");
    expect(zshrc).toContain("# keep me");
    expect(zshrc).not.toContain("vibetoolbox/env.zsh");
  });
});

describe("server", () => {
  let dbDir: string;
  let app: (typeof import("../src/server"))["app"];

  beforeAll(async () => {
    dbDir = mkdtempSync(join(tmpdir(), "vtb-db-"));
    process.env.VTB_DB_PATH = join(dbDir, "test.sqlite");
    process.env.SITE_URL = "https://vibetoolbox.dev";
    ({ app } = await import("../src/server"));
  });

  afterAll(() => {
    rmSync(dbDir, { recursive: true, force: true });
  });

  test("POST /api/select returns a stable slug and command", async () => {
    const res = await app.request("/api/select", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ tools: ["zed", "ghostty", "zed"] }),
    });
    expect(res.status).toBe(200);
    const body = await res.json();
    expect(body.tools).toEqual(["ghostty", "zed"]);
    expect(body.command).toBe(`curl -fsSL https://vibetoolbox.dev/i/${body.slug} | bash`);

    // Content-addressed: same set, same slug
    const res2 = await app.request("/api/select", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ tools: ["ghostty", "zed"] }),
    });
    expect((await res2.json()).slug).toBe(body.slug);
  });

  test("POST /api/select rejects unknown tools and empty lists", async () => {
    for (const tools of [[], ["notreal"], "ghostty"]) {
      const res = await app.request("/api/select", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ tools }),
      });
      expect(res.status).toBe(400);
    }
  });

  test("GET /i/:slug serves the script with the selection baked in", async () => {
    const sel = await app.request("/api/select", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ tools: ["starship", "ghostty"] }),
    });
    const { slug } = await sel.json();
    const res = await app.request(`/i/${slug}`);
    expect(res.status).toBe(200);
    const body = await res.text();
    expect(body).toContain('VTB_SELECTION="ghostty,starship"');
    expect(body).toContain("#!/bin/bash");
  });

  test("GET /i/unknown returns a safe failing script", async () => {
    const res = await app.request("/i/nope123456");
    expect(res.status).toBe(404);
    expect(await res.text()).toContain("exit 1");
  });
});
