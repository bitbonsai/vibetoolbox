# About Vibe Toolbox

One command that sets up a Mac for building with AI coding agents, with nothing installed that you did not pick.

## The problem

A useful coding setup needs a terminal, Homebrew, runtimes, git, an agent, an editor, and a handful of smaller tools. Installing each piece by hand can take an afternoon, and one missed PATH line can leave half the setup broken. Vibe Toolbox turns your choices into one command, so you can spend that time building instead.

## You choose everything

You choose every tool on the site. Vibe Toolbox encodes that selection in a short link, and the same selection always produces the same link, making setups easy to save or share. Required dependencies stay visible: if a tool needs Bun, Bun appears in your toolbox before you copy the command.

## Idempotent by design

Re-running the command is safe. Installed tools are skipped, missing pieces are repaired, and your existing setup stays in place. Shell aliases activate only when their command exists. The `c` shortcut starts Claude Code with its safer auto permission mode.

## Tools stay current

A local update runs every Monday at 10:00, keeping Homebrew packages, global Bun and npm tools, and Claude Code current. Results go to `~/.vibetoolbox-update.log`.

## Easy to undo

`--uninstall` removes the Vibe Toolbox config, scheduled update job, and shell additions. Your installed tools and projects stay where they are.

## Practical over clever

Vibe Toolbox removes setup work and stays easy to inspect. The installer is plain Bash, works without an account or daemon, and is MIT licensed in [one repository on GitHub](https://github.com/bitbonsai/vibetoolbox).
