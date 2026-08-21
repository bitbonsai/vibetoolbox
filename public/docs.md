# Vibe Toolbox Docs

The install command, what it touches, and how to change your mind later.

## The install command

Every selection in the picker becomes one command:

```bash
curl -fsSL https://vibetoolbox.dev/i/<id> | bash
```

The short id is derived from your exact tool list, so the same selection always produces the same link. You can also skip the picker and name tools directly:

```bash
curl -fsSL https://vibetoolbox.dev/install.sh | bash -s -- --with ghostty,starship,claude-code
curl -fsSL https://vibetoolbox.dev/install.sh | bash -s -- --all
```

The script needs bash, which every Mac ships with. It installs Xcode Command Line Tools and Homebrew first when they are missing; those two are the only hard requirements. Everything else installs in dependency order and a failed tool never aborts the run, it lands in a warning summary at the end.

## Presets

Three starting points, all editable before you copy anything:

- **Essentials.** Terminal, Claude Code, an editor, git tooling, and the core CLI comforts.
- **Recommended.** Essentials plus more agents, git helpers, and power tools. What we actually run.
- **Everything.** The whole catalog.

Ticking a tool that depends on another pulls the dependency in automatically. The toolbox in the nav always shows the full final list.

## How selection works

The installer resolves what to install in this order:

1. A selection baked into a short link (`/i/<id>`) wins.
2. Explicit flags come next: `--with tool1,tool2` or `--all`.
3. With neither, it reuses the selection saved from your last run.

Your selection persists in `~/.config/vibetoolbox/config`, so re-running a bare `install.sh` repairs your existing setup instead of asking again. Unknown tool ids print a warning and are skipped.

## Updates

A background job runs weekly (Mondays at 10:00) and keeps Homebrew packages, global packages, and Claude Code fresh. It logs to `~/.vibetoolbox-update.log`. Run it manually any time with the `update` alias. Re-running your install command is also always safe: it checks what is present, fixes what is missing, and changes nothing else.

## Shell additions

The installer adds two small files to your zsh config: one for environment setup and one for aliases. Every alias is guarded, meaning it only activates when the tool behind it is installed, so any selection produces a working shell. The one worth knowing early: `c` starts Claude Code with its safer auto permission mode.

## Uninstall

```bash
curl -fsSL https://vibetoolbox.dev/install.sh | bash -s -- --uninstall
```

This removes the toolbox configuration, the weekly update job, and the shell additions. The tools themselves and your projects stay exactly where they are; remove individual tools with `brew uninstall <name>` when you want them gone too.

## Troubleshooting

- **New aliases missing?** Shell config loads in new windows. Open a fresh terminal.
- **Something failed mid-install?** Re-run the same command. It is a health check that finishes what broke.
- **Password prompt looks frozen?** Typing stays invisible on purpose. Type it and press Return.
- **Still stuck?** [Open an issue](https://github.com/bitbonsai/vibetoolbox/issues) with the tail of your install output.
