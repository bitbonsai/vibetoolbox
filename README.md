# Vibe Toolbox

Pick your tools, paste one command, start vibecoding.

Vibe Toolbox sets up a Mac for AI-assisted coding. It is built for designers,
PMs, and anyone learning to code who wants a great terminal without a weekend
of yak shaving. You choose tools on [vibetoolbox.dev](https://vibetoolbox.dev),
it gives you a short command, the command does the rest. Re-running it later
checks your setup and fixes only what is missing.

```
curl -fsSL https://vibetoolbox.dev/i/<your-slug> | bash
```

No selection link handy? Explicit lists work too:

```
curl -fsSL https://vibetoolbox.dev/install.sh | bash -s -- --with ghostty,starship,claude-code
curl -fsSL https://vibetoolbox.dev/install.sh | bash -s -- --all
```

## What's in the box

| Category | Tools |
|----------|-------|
| Terminal | Ghostty, JetBrains Mono Nerd Font, Starship |
| AI coding | Claude Code, Codex CLI, Pi, OpenCode, Crush, Herdr, Orca, ccpeek, Caveman, Agent Browser |
| Editors | Zed, Cursor, Visual Studio Code |
| Git & GitHub | git, GitHub CLI, lazygit, delta |
| CLI comforts | eza, bat, zoxide, fzf, ripgrep, fd, btop, mkcert, jq, trash-cli |
| Runtimes | Node.js, Bun |
| Mac apps | Shottr, Handy |

Everything is opt-in. Dependencies resolve automatically (pick trash-cli, get
Bun). The full catalog lives in [`catalog.json`](catalog.json), which drives
both the website picker and the installer.

## How it works

- **The installer** is plain bash, built from modules in `installer/` by
  `scripts/build.ts`. No `set -e`; every step has explicit error handling and
  non-critical failures warn instead of aborting. Piped-friendly: prompts read
  from `/dev/tty`.
- **The server** (`src/server.ts`) is a small Bun + Hono app. The picker POSTs
  a selection to `/api/select`, gets back a content-addressed slug (SQLite),
  and `/i/<slug>` serves the installer with that selection baked in.
- **Idempotent re-runs.** The installer starts with a status scan and installs
  only what is missing. Your selection is saved to
  `~/.config/vibetoolbox/config` and reused when you re-run without arguments.
- **Weekly auto-update.** A launchd agent runs Mondays at 10:00: brew upgrade,
  bun and npm global updates, Claude Code update, and a version check against
  the site. Log at `~/.vibetoolbox-update.log`.
- **Uninstall**: `bash install.sh --uninstall` removes aliases, config, the
  launchd agent, and logs. Installed tools and your projects stay.

## Development

Requires [Bun](https://bun.sh).

```
bun install
bun run build     # catalog.sh + install.sh + catalog.js + render site/pages -> public/*.html
bun run test      # build, bash -n, bun test
bun run dev       # server with watch on http://localhost:8080
```

Edit modules in `installer/` and pages in `site/`, never `public/install.sh`
or `public/*.html` directly (both are generated). The catalog is the single
source of truth: add a tool to `catalog.json` and it appears in the picker,
the tools page, and the installer after a build.

## Credits

- Toolbox icon by [Salman Azzumardi](https://thenounproject.com/creator/salmanazzumardi/)
  (Noun Project)
- Tool logos belong to their respective projects; the remaining icons are
  [Lucide](https://lucide.dev) (ISC)

## License

MIT
