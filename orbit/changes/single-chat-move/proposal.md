## Why

Claude Code chats are tied to the machine they started on. Chats on this MacBook need to continue on a Fedora Linux desktop or a Mac mini with their history, memory and files intact, one project at a time. The seed example `migrate-claude-to-starlight.sh` moves *everything* to one Linux host, matches project folders by name prefix (so `home-env` drags `home-env-test` along), skips per-session file history, and its remote `sed -i` breaks on a macOS target.

Implements stage `single-chat-move` of `orbit/architecture/claude-chat-mover.md` (rulings R-claude-chat-mover-1..7).

## What Changes

- New script `move-chat.sh`, run on the MacBook: `./move-chat.sh <project> --remote <host> [--dry-run] [--skip-code] [--yes]`.
- `<project>` names one folder under `~/code` (or a path to it); the script analyzes ONLY that project's Claude data, matched by exact slug directory.
- Moves the project's session transcripts, per-session sidecars (subagents, tool-results), project memory, and `~/.claude/file-history/<session>` for each of its sessions.
- Rewrites the source home path and the source slug inside the moved Claude data to the target's, so `claude --resume` on the target finds the sessions and their memory.
- Copies the project folder itself (including `.git`, excluding dependency/build folders) unless `--skip-code`.
- Never overwrites anything on the target; never changes anything on the source; raises the target's `cleanupPeriodDays` so moved sessions aren't purged as "old".
- Works for both a Linux target (`/home/<user>`) and a macOS target (`/Users/<user>`).
- The seed example stays in the repo as reference; it is not modified.

## Capabilities

### New Capabilities
- `chat-move`: moving one project's Claude Code chat data (and optionally its code) from this Mac to another machine so it resumes there — selection, plan/dry run, transfer, path rewriting, code copy, target safety.

### Modified Capabilities
(none)

## Impact

- New file: `move-chat.sh` (repo root).
- Source machine: read-only access to `~/.claude/projects/<slug>/`, `~/.claude/file-history/`, and the project folder; a temporary staging directory.
- Target machine: needs `ssh` (key-based, no prompt) and `rsync`; writes under `~/.claude/projects/`, `~/.claude/file-history/`, `~/.claude/settings.json` (one key), and the project's folder under the target home.
- No global Claude config moves (R-claude-chat-mover-7).
