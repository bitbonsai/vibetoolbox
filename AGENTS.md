# Vibe Toolbox - Session Context

## Project

**Vibe Toolbox** (vibetoolbox.dev) - open-source macOS environment installer
for designers and PMs learning to code. OSS successor to an internal v3
toolkit; everything company-specific was removed.

- **Owner:** Mauricio Wolff (github: bitbonsai)
- **Audience:** designers and PMs transitioning to coding
- **Model:** selection is mandatory. Users pick tools on the website, the
  server mints a short content-addressed URL, the pasted command installs
  exactly that set. Zero decisions inside the terminal.

## Structure

```
vibetoolbox/
├── catalog.json          # SINGLE SOURCE OF TRUTH: tools, categories, presets
├── installer/            # bash modules, concatenated by scripts/build.ts
│   ├── header.sh         # shebang + VTB_SELECTION placeholder (server-injected)
│   ├── common.sh         # colors, helpers, checks, VERSION, SITE_URL
│   ├── catalog.sh        # GENERATED from catalog.json - do not edit
│   ├── selection.sh      # resolve --with/--all/baked/saved + dependency expansion
│   ├── uninstall.sh      # --uninstall path (runs before main's arg parsing)
│   ├── prefs.sh          # ~/.config/vibetoolbox/config (VTB_SELECTED persisted)
│   ├── prereqs.sh        # Xcode CLI, Rosetta, Homebrew (fatal failures)
│   ├── tools.sh          # phase-ordered install: brew → cask → curl → bun → plugin
│   ├── update.sh         # writes ~/.config/vibetoolbox/update.sh payload
│   ├── autoupdate.sh     # launchd agent dev.vibetoolbox.update, WEEKLY Mon 10:00
│   ├── git-config.sh     # git identity prompts
│   ├── github-cli.sh     # gh auth login (only when gh selected)
│   ├── shell.sh          # env.zsh + aliases.zsh, ALL runtime-guarded
│   └── main.sh           # arg parsing, status scan, linear flow
├── scripts/build.ts      # bun: catalog.json → catalog.sh; concat → public/install.sh
├── site/                 # HTML sources: pages/*.html + partials/*.html
│   ├── pages/            # index, tools, about, next-steps (edit HTML HERE)
│   └── partials/         # head (SEO/OG vars), navs, footer, scripts
├── public/               # static site + built install.sh + catalog copies
│   ├── *.html            # GENERATED from site/pages by build.ts - do not edit
│   ├── picker.js         # Alpine components: picker (hash sync, cart, guide) + toolsPage
│   ├── catalog.js        # GENERATED window.VTB_CATALOG + version (no fetch pop-in)
│   ├── alpine.min.js     # vendored Alpine 3
│   ├── img/              # tool brand SVGs (rest use inline Lucide in picker.js)
│   └── styles.css        # system light/dark glassy theme, rem typescale, 8pt grid
├── src/server.ts         # Bun + Hono + bun:sqlite
└── tests/install.test.ts # bun test: script behavior + server API
```

## Key decisions

- **Selection mandatory, all tools default off.** Bare install.sh run prints a
  pointer to the picker and exits 0.
- **Selection priority:** baked `VTB_SELECTION` (from /i/<slug>) > `--with`/
  `--all` > saved `VTB_SELECTED` from last run. Unknown ids warn and drop.
- **Dependency expansion** in both picker.js and selection.sh (requires field):
  pi/opencode/crush/trash-cli need bun; caveman needs claude-code.
- **Install kinds:** brew, cask (app field for detection), curl (Claude Code
  official installer), bun (`bun i -g`), plugin (Claude Code marketplace).
  Phase order matters: brew (incl. runtimes) → cask → curl → bun → plugin.
- **Taps:** targets like `user/tap/formula` auto-tap + `brew trust` (Homebrew 6,
  guarded for older). Used by orca (stablyai/orca) and ccpeek (ahmedelgabri/tap).
- **Slugs are content-addressed:** sha256 of the sorted id list, first 10 hex
  chars. Same selection = same URL. SQLite table `selections`, no expiry.
- **Prefer bun** over npm for JS-distributed tools (user preference).
- **Gemini CLI deliberately excluded:** replaced by Antigravity CLI, individual
  tier shut down June 2026.
- **Aliases all runtime-guarded** (`command -v x && alias ...`) so any
  selection produces a working shell. `c` = `claude --permission-mode auto`,
  never bypassPermissions.
- **No `set -e`**; soft-fail pattern `cmd || true` + verify + track_warn.
  Only Xcode CLT and Homebrew are fatal.
- **Piped install:** prompts via fd 3 on /dev/tty (`init_prompt_input`).
  `VTB_TEST=1` keeps PROMPT_FD=0 for tests.
- **Theme follows `prefers-color-scheme`.** UI, syntax tokens, and Lucide icons
  use CSS variables; white brand SVGs use `.theme-invert` in light mode.

## Patterns

- Edit `installer/` modules, `catalog.json`, or `site/`, then `bun run test`
  (builds, syntax-checks, tests). Never edit `public/install.sh`,
  `installer/catalog.sh`, `public/catalog.js`, or `public/*.html` by hand.
- Version source of truth is `package.json`; build injects it into
  `catalog.js` (site pill) and the `VERSION=` line of `install.sh`.
- New tool = one `catalog.json` entry (id, name, category, kind, target,
  app/bin as needed, requires, url, desc, more, why, try, post). `more` =
  plain explanation, `why` = opinionated pick rationale (tools-page dialog),
  `try` = sample command, `post` = shell run once after successful install
  (e.g. `agent-browser install`). Picker, tools page, and installer pick it
  up on build. Icon: brand SVG in `public/img/` + ICONS entry in picker.js,
  else inline Lucide there.
- No em dashes in user-facing copy. No emojis in headings.
- Secrets never in files; this project stores none at all.

## Gotchas (this repo)

- URL hash carries tool selection. Never use anchor links on index; dot-nav
  uses scrollIntoView + click.prevent. Anchor hrefs would clobber selection.
- Nested backdrop-filter fails: child inside backdrop-filtered parent won't
  blur page. cart-panel is sibling of .nav-container for this reason.
- Shared `.modal h2` margin-bottom beat `.tool-modal-head h2` on source
  order (equal specificity): flex centered the margin box, icon sat 12px
  low. Dialog head resets it via `.modal .tool-modal-head h2`.
- Grid `1fr` + `<pre>` = min-content overflow on mobile. Use minmax(0, 1fr).
- Alpine defer order load-bearing: catalog.js, picker.js (registers on
  alpine:init), alpine.min.js last.
- simpleicons CDN lacks openai, visualstudiocode, charm, lazygit, jq,
  ripgrep, nerdfonts slugs. Most product "logos" online are wide wordmarks,
  useless as card icons; Lucide fallback stays.
- Nav cart toolbox icon = Noun Project (Salman Azzumardi); keep the
  attribution comment next to the SVG.
- Mobile page-strip collapse cannot use `display: none` for `.cart-btn`: cart
  returns before delayed CTA and escapes nav. Delay size/visibility with CTA.
- 320px page strip has tight width budget. Keep compact `max-width: 360px`
  spacing so brand version stays visible without horizontal overflow.
- Shell syntax highlighting is one tokenizer implemented twice: build.ts
  (static pre/code at render) + picker.js `hl()` (Alpine x-html). Change both.
- `scripts/ship.ts` ignores `-y`; `yes | bun run ship` floods Clack and hangs.
  Use TTY automation; send Enter after `test passed`.

## Carried gotchas (from the v3 ancestor)

- `gh auth login` needs TERM=dumb + all fds on /dev/tty under curl|bash,
  and an INT trap so Ctrl+C doesn't kill the whole script.
- Homebrew installer needs /dev/tty stdin for its sudo prompt; do NOT use
  NONINTERACTIVE=1.
- launchd doesn't source .zshrc: update.sh runs via `zsh -lc`.
- `sed` patterns containing `/` use `\|...|` delimiters.
- macOS ships bash 3.2: no associative arrays in installer code.
