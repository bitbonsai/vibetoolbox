# Vibe Toolbox tool catalog

36 tools across 7 categories. Each lists what it is, why it is in the catalog, and how it installs.

## Terminal

### Ghostty (`ghostty`)

Fast, GPU-accelerated terminal. The home for everything else here.

**Why:** Terminals all look alike until you use a good one. Ghostty is the first in years that feels genuinely native on a Mac, built by Mitchell Hashimoto, who has taste.

- Install: cask `ghostty`
- Homepage: https://ghostty.org

### JetBrains Mono Nerd Font (`nerd-font`)

Monospace font with all the icons your prompt and file listings need.

**Why:** Half of all 'my terminal looks broken' reports are a missing patched font, so installing it up front deletes an entire class of confusion. And of all the coding fonts, JetBrains Mono is the one that stays crisp from tiny terminal sizes to a 4K editor.

- Install: cask `font-jetbrains-mono-nerd-font`
- Homepage: https://www.nerdfonts.com

### Starship (`starship`)

Minimal, fast prompt that shows git branch and status at a glance.

**Why:** Prompt frameworks ship a hundred options you will never touch. Starship gives the four things you actually need and stays out of the way.

- Install: brew `starship`
- Homepage: https://starship.rs

## AI Coding

### Claude Code (`claude-code`)

Anthropic's coding agent for the terminal. Needs a Claude subscription or API key.

**Why:** The strongest coding agent right now, and the one this toolbox is built around. If you install only one agent, make it this one.

- Install: curl `https://claude.ai/install.sh`
- Homepage: https://claude.com/claude-code

### Codex CLI (`codex`)

OpenAI's coding agent. Needs a ChatGPT subscription or API key.

**Why:** Competition keeps agents honest. If your subscription is ChatGPT, this is your Claude Code.

- Install: brew `codex`
- Homepage: https://github.com/openai/codex

### Pi (`pi`)

Minimal coding agent by Mario Zechner. Bring any model provider.

**Why:** Pi stays out of the model's way: the harness adds almost nothing, so modern models work the way they were trained to. The extension ecosystem is good, and it actively encourages you to build your own. It has fewer guardrails than the big agents, so it rewards a little attention and repays it with a lot of power.

- Install: bun `@earendil-works/pi-coding-agent` (requires bun)
- Homepage: https://pi.dev

### OpenCode (`opencode`)

Open-source terminal coding agent. Works with any model, has its own plans too.

**Why:** The escape hatch from subscription lock-in. Models come and go; an agent that speaks to all of them ages well.

- Install: bun `opencode-ai` (requires bun)
- Homepage: https://opencode.ai

### Crush (`crush`)

Charm's glamorous coding agent for the terminal.

**Why:** Looks matter in tools you stare at all day. Charm has made the terminal delightful for years, and Crush carries that into agents.

- Install: bun `@charmland/crush` (requires bun)
- Homepage: https://github.com/charmbracelet/crush

### Herdr (`herdr`)

Agent multiplexer. Run and watch several coding agents in one terminal.

**Why:** One agent working is nice. Three agents working while you review is the real unlock, and Herdr makes that manageable instead of chaotic.

- Install: brew `herdr`
- Homepage: https://herdr.dev

### Orca (`orca`)

Desktop cockpit for running fleets of coding agents in parallel.

**Why:** Some people prefer a window with buttons to a wall of terminal panes. Orca is the GUI way to run and watch several agents at once.

- Install: cask `stablyai/orca/orca`
- Homepage: https://github.com/stablyai/orca

### ccpeek (`ccpeek`)

Browse your Claude Code session history locally.

**Why:** Sessions vanish from memory fast. Answering 'what did the agent change yesterday and what did it cost' is worth the tiny install.

- Install: brew `ahmedelgabri/tap/ccpeek`
- Homepage: https://github.com/ahmedelgabri/ccpeek

### Caveman (`caveman`)

Agent add-on: ultra-compressed replies, ~75% fewer tokens.

**Why:** Cutting three quarters of output tokens is a free lunch for your bill. The terser replies are also quicker to read, so working with the agent feels more direct.

- Install: plugin `JuliusBrussee/caveman` (requires bun)
- Homepage: https://github.com/JuliusBrussee/caveman

### Agent Browser (`agent-browser`)

Browser automation CLI built for AI agents. Click, fill, screenshot.

**Why:** An agent that can see and click your app finds bugs your tests miss. This is the lightest way to hand any agent a browser.

- Install: bun `agent-browser` (requires bun)
- Homepage: https://github.com/vercel-labs/agent-browser

## Editors

### Zed (`zed`)

Fast, clean code editor with built-in AI. Great first editor.

**Why:** A nice option if you prefer an editor over the terminal. Where it really shines is speed and getting out of your way: it never makes you wait and never nags.

- Install: cask `zed`
- Homepage: https://zed.dev

### Cursor (`cursor`)

VS Code fork built around AI editing. Needs a subscription for the good parts.

**Why:** The safest bet if you want the editor the whole internet writes tutorials for, with AI turned up to the max.

- Install: cask `cursor`
- Homepage: https://cursor.com

### Visual Studio Code (`vscode`)

The classic. Free, huge extension ecosystem.

**Why:** Boring in the best way. When something breaks, the answer already exists, and every extension supports it first.

- Install: cask `visual-studio-code`
- Homepage: https://code.visualstudio.com

## Git & GitHub

### Git (`git`)

Version control. Everything else assumes you have it.

**Why:** Not optional. Agents make many changes fast; without checkpoints you are one bad prompt away from losing an afternoon.

- Install: brew `git`
- Homepage: https://git-scm.com

### GitHub CLI (`gh`)

GitHub from the terminal: auth, repos, pull requests.

**Why:** Lets agents open PRs and read CI results, which turns GitHub from a website into part of your terminal.

- Install: brew `gh`
- Homepage: https://cli.github.com

### lazygit (`lazygit`)

Visual git in the terminal. Stage, commit, and browse history without memorizing commands.

**Why:** The fastest way to build git intuition: you watch the state change as you press keys. The undo key alone justifies it.

- Install: brew `lazygit`
- Homepage: https://github.com/jesseduffield/lazygit

### Worktrunk (`worktrunk`)

Git worktrees made practical for running coding agents in parallel.

**Why:** Git worktrees are ideal for parallel agents, but raw worktree commands are awkward. Worktrunk turns the whole workflow into a few commands you can remember.

- Install: brew `worktrunk` (requires bun)
- Homepage: https://worktrunk.dev

### delta (`git-delta`)

Syntax-highlighted, side-by-side diffs for git.

**Why:** Reviewing agent diffs in raw git output is punishment. Delta turns review into reading.

- Install: brew `git-delta`
- Homepage: https://dandavison.github.io/delta/

## CLI Comforts

### eza (`eza`)

Modern ls with icons, trees, Git status, and code stats.

**Why:** One fast tool now covers everyday listings, directory trees, and codebase size. That makes separate file-listing utilities redundant.

- Install: brew `eza`
- Homepage: https://eza.rocks

### bat (`bat`)

cat with syntax highlighting and line numbers.

**Why:** Syntax highlighting on every file you peek at, thousands of times a year. Small upgrade, constant payoff.

- Install: brew `bat`
- Homepage: https://github.com/sharkdp/bat

### zoxide (`zoxide`)

Smarter cd. Jump to any directory you have visited by typing a fragment.

**Why:** cd ../../../projects/thing is a tax. zoxide refunds it on every jump.

- Install: brew `zoxide`
- Homepage: https://github.com/ajeetdsouza/zoxide

### fzf (`fzf`)

Fuzzy finder for files, history, anything.

**Why:** Once fuzzy-finding is in your muscle memory, every list on your machine becomes searchable. It rewires how you use a terminal.

- Install: brew `fzf`
- Homepage: https://github.com/junegunn/fzf

### ripgrep (`ripgrep`)

grep, but fast and friendly. AI agents love it too.

**Why:** Your agent already uses rg under the hood. Having it yourself means checking the agent's work at the same speed.

- Install: brew `ripgrep`
- Homepage: https://github.com/BurntSushi/ripgrep

### fd (`fd`)

Find files fast, with syntax a human can remember.

**Why:** find has scared people for forty years. fd is the version you can teach in one sentence.

- Install: brew `fd`
- Homepage: https://github.com/sharkdp/fd

### btop (`btop`)

Gorgeous system monitor: CPU, memory, and what is eating them.

**Why:** When the fans spin up, this answers 'what is doing that' in five seconds, and looks great doing it.

- Install: brew `btop`
- Homepage: https://github.com/aristocratos/btop

### mkcert (`mkcert`)

Locally trusted HTTPS certificates with zero configuration.

**Why:** The https://localhost problem appears once per project and wastes an hour each time unless this is already installed.

- Install: brew `mkcert`
- Homepage: https://github.com/FiloSottile/mkcert

### jq (`jq`)

Slice and pretty-print JSON from the command line.

**Why:** Every API answer, config dump, and agent log is JSON. Ten minutes of jq pays itself back weekly.

- Install: brew `jq`
- Homepage: https://jqlang.org

### trash-cli (`trash-cli`)

Delete to the Trash instead of rm's point of no return.

**Why:** Someone, human or agent, will eventually delete the wrong file. With the Trash in the loop that is a two-second fix instead of a disaster.

- Install: bun `trash-cli` (requires bun)
- Homepage: https://github.com/sindresorhus/trash-cli

## Runtimes

### Node.js (`node`)

JavaScript runtime. Many tools and MCP servers need it.

**Why:** Too much of the ecosystem assumes Node exists to skip it, including many MCP servers your agents will want.

- Install: brew `node`
- Homepage: https://nodejs.org

### Bun (`bun`)

Fast JavaScript runtime and package manager.

**Why:** Dramatically faster installs, and it replaces three separate JavaScript tools. This toolbox uses it for its own installs.

- Install: brew `bun`
- Homepage: https://bun.sh

### uv (`uv`)

Fast Python package, project, and runtime manager.

**Why:** Modern Python tooling in one command. It is dramatically faster than pip and removes several overlapping tools beginners would otherwise need to learn.

- Install: brew `uv`
- Homepage: https://docs.astral.sh/uv/

## Mac apps

### Shottr (`shottr`)

Pixel-accurate screenshots with annotations, OCR, and rulers. Free.

**Why:** Screenshots are how you show an agent what looks wrong. Shottr makes them precise, annotated, and instant.

- Install: cask `shottr`
- Homepage: https://shottr.cc

### Handy (`handy`)

Free, open-source voice dictation. Talk instead of type, anywhere.

**Why:** Talking is faster than typing prompts. Free, local, and open source, which is rare for dictation apps.

- Install: cask `handy`
- Homepage: https://handy.computer

## Presets

- **essentials**: ghostty, nerd-font, starship, claude-code, zed, git, gh, eza, bat, zoxide, fzf, ripgrep, jq, trash-cli, node, bun
- **recommended**: ghostty, nerd-font, starship, pi, caveman, herdr, agent-browser, zed, git, gh, lazygit, worktrunk, git-delta, eza, bat, zoxide, fzf, ripgrep, jq, trash-cli, fd, btop, node, bun, uv, shottr
