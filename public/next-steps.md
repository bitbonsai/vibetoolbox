# Next steps

Your Mac is ready. Ten minutes of orientation and you are off. Everything below assumes a fresh terminal window.

## Open a fresh terminal

Your shell config only loads in new windows. With Ghostty and Starship installed you should see a clean prompt line with your folder and git branch. With eza and zoxide, try:

```bash
ls        # listings via eza
lt        # file tree
z dev     # jump to a folder you have visited
```

## Your projects start in ~/dev

On a fresh setup, Ghostty opens in `~/dev` instead of your home folder. This keeps agent sessions focused on project files and reduces accidental exposure of personal files in `~/`. To change it, edit `~/.config/ghostty/config`:

```
working-directory = ~/dev
```

Use another `~/...` path, use `home`, or remove the line for Ghostty's default. Restart Ghostty after saving. Existing Ghostty configs are never touched.

## Connect your AI agent

The agents need an account to think with:

- **You already have a subscription.** Claude Pro or Max unlocks Claude Code: run `claude` and sign in. A ChatGPT plan unlocks Codex: run `codex` and sign in.
- **No subscription, one bill.** OpenCode offers its own plans with model access included: run `opencode` and follow the sign-up.
- **All models, pay per use.** Create an [OpenRouter](https://openrouter.ai) key and use it with pi, crush, or opencode.

The alias `c` starts Claude Code with sensible permissions.

## Make your first thing

```bash
mkdir ~/dev/playground && cd ~/dev/playground && c
```

Then just describe what you want: "make me a single-page site about my dog, dark theme, big type." Watch it work. Ask for changes. That loop is the whole game.

## Grant your Mac apps their permissions

- **Shottr** asks for Screen Recording on your first screenshot. Grant it in System Settings → Privacy & Security, then take the shot again.
- **Handy** needs Microphone and Accessibility to turn speech into text. It walks you through both on first launch, then you pick a hotkey.

## Cheatsheet

| Type | Get |
|------|-----|
| `c` | Claude Code, auto permissions |
| `gs` / `gaa` / `gcm "msg"` / `gp` | git status, add all, commit, push |
| `git ac "msg"` | add everything and commit in one go |
| `git lg` | pretty history graph |
| `lg` | lazygit, visual git |
| `ls` / `lsa` / `lt` | listings and trees via eza |
| `eza --code` | lines of code grouped by language |
| `z somefolder` | jump to a folder you have visited |
| `ff` | fuzzy-find files with preview |
| `update` | run the weekly updater now |
| `zconf` | open ~/.zshrc in your editor |
| `zreload` | reload shell config |

## Good to know

- Re-run your install command any time. It is a system check that fixes only what is missing.
- Updates run weekly (Mondays, 10:00) in the background. Log: `~/.vibetoolbox-update.log`
- Want more tools later? Go back to the picker, adjust, paste the new command.
- Remove the toolbox config with `--uninstall`. Your tools and projects stay.
