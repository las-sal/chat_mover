## Context

Claude Code stores a chat under `~/.claude/projects/<slug>/`, where `<slug>` is the project's absolute path with every non-alphanumeric character turned into `-` (observed 2026-10-16, Claude Code 2.1.301; see `orbit/architecture/claude-chat-mover.md` Premise). That directory holds session transcripts (`<uuid>.jsonl`), per-session sidecars (`<uuid>/subagents/`, `<uuid>/tool-results/`) and the project's `memory/`. Rewind checkpoints live separately in `~/.claude/file-history/<uuid>/`.

Transcripts embed absolute paths in two forms that both break on another machine:
- the home path — `"cwd":"/Users/sal/code/chat_mover"`, tool-call file paths;
- the home path **plus the slug** — e.g. `/Users/sal/.claude/projects/-Users-sal-code-chat-mover/memory/` and `…/<uuid>/tool-results/…` (observed: 30 such references in one session of this repo).

The seed example `migrate-claude-to-starlight.sh` already has the right shape (preflight over ssh, slug remap, `rsync --ignore-existing`, `cleanupPeriodDays` guard) but moves every project, matches by slug prefix, skips file-history, rewrites only `$OLD_HOME/` (not the slug), and does its rewrite on the target with GNU `sed -i`, which fails on macOS.

Source is this MacBook (`rsync` is `openrsync`, protocol 29 — supports `-a -z -n --exclude --ignore-existing`). Targets: Fedora desktop and Mac mini.

## Goals / Non-Goals

**Goals:**
- One script, one project per run, readable top to bottom (R-claude-chat-mover-4).
- Everything the chat needs lands on the target and resolves there (R-claude-chat-mover-3, -5).
- Same behaviour on Linux and macOS targets (R-claude-chat-mover-2).
- Never overwrite on the target; never modify the source.

**Non-Goals:**
- Moving several projects at once, or global config (R-claude-chat-mover-1, -7).
- Syncing a chat that grew after it was moved (re-run copies only new files; see Risks).
- Sessions started from a subfolder of the project (they have their own slug directory).
- Reinstalling dependencies, signing in, or trusting the folder on the target — printed as next steps.

## Decisions

### D1 — Exact slug match, not prefix glob
Compute `slug = slugify(abs project path)` and use only `~/.claude/projects/<slug>`. The seed's `"$OLD_PREFIX"-*` glob is what pulls `home-env-test` in with `home-env`. *Alternative:* scan transcripts for `cwd` under the project — more complete (subfolder sessions) but more code and slower; rejected for simplicity.

### D2 — Rewrite on a local staging copy, then rsync
Copy the slug directory to a temp staging dir on the Mac (`mktemp -d`), rename it to the target slug, rewrite there, then `rsync -a --ignore-existing` the staged tree to the target's `~/.claude/projects/`. *Why:* the target needs only `ssh` + `rsync` (no `sed -i` dialect issue, no python on the target), the source is never modified, and there is nothing to "double-rewrite" on a re-run. *Alternative:* the seed's remote rewrite — rejected for the BSD/GNU `sed -i` split and because it rewrites files already on the target.

### D3 — Rewrite with Python, byte-level, boundary-aware
A small embedded `python3` (present on this Mac) walks the staged tree and, per file, replaces bytes:
1. `OLD_HOME` → `NEW_HOME` where the next byte is `/`, `"`, `'`, whitespace, `\`, or end of file (regex lookahead `(?=[/"'\s\\]|$)`) — so `/Users/salvador` is not touched;
2. `OLD_SLUG` → `NEW_SLUG` (plain replace; runs after step 1 so `-Users-sal-…` inside already-rewritten memory paths becomes `-home-sal-…`).

Step 2 is a plain substring replace: the old slug of `home-env` also matches the start of `-Users-sal-code-home-env-test` in text, and the result (`-home-sal-code-home-env-test`) is that project's correct target slug, so it is consistent. Files are rewritten only when their content changes. *Alternative:* `sed` — rejected for portability and no lookahead.

### D4 — What is not rewritten
`file-history/` holds snapshots of the user's file contents used by rewind; rewriting them would make rewind restore altered files, so they copy verbatim. Project code is copied verbatim too (it's the user's repo). Temp/scratchpad paths (`/private/tmp/claude-501/<slug>/…`) are dead on any target; the slug replace may touch them, which is harmless.

### D5 — File-history selection
For each `<uuid>.jsonl` directly in the slug directory, copy `~/.claude/file-history/<uuid>/` if it exists, with `rsync -a --ignore-existing` into the target's `~/.claude/file-history/`.

### D6 — Code copy
`rsync -a -z --ignore-existing` of `$PROJECT/` to `$TARGET:<path relative to home>/`, excluding `node_modules .venv venv __pycache__ .DS_Store`. A project outside `$HOME` has no meaningful target path, so the tool exits with an error unless `--skip-code` is given (then only chat data moves). `--ignore-existing` means a repo already cloned on the target keeps its files; the Mac's untracked files fill gaps.

### D7 — `cleanupPeriodDays` edited on the source side
Read the target's `~/.claude/settings.json` with `ssh cat`, adjust it locally with `python3` (keep all keys; `max(existing, 365)`), and write it back with `ssh 'cat > file'` only when it changed. Unparseable JSON → warn and leave it. Keeps the target requirement at ssh + rsync. Runs only after chat data is copied.

### D8 — CLI shape kept from the seed
`move-chat.sh <project> [--remote HOST] [--dry-run] [--skip-code] [--yes]`. `--remote` defaults to nothing (required), since there are two targets. Same `say`/`warn`/`die` helpers, `set -euo pipefail`. Dry run builds the plan (counts, sizes) from local data plus the ssh preflight and stops before staging.

## Risks / Trade-offs

- [Chat keeps growing on the Mac after a move] → re-running copies only *new* files; an already-copied transcript that grew is not updated (`--ignore-existing`). Plan says so; for a clean re-move, delete the target's copy first by hand.
- [A `claude` process is writing the chat during the move] → preflight warns; the user should exit the session first.
- [Claude Code changes its on-disk layout] → the layout was observed on 2.1.301; the plan output makes surprises visible before anything is copied.
- [Project trust / per-project settings live in `~/.claude.json` on the source] → not moved (global file, R-7); first launch on the target asks to trust the folder once.
- [Code paths inside project files (e.g. `.claude/settings.local.json`) still say `/Users/sal`] → code is not rewritten by design; the closing next-steps text tells the user to check the project's `.claude/` and `CLAUDE.md` for old-home paths.

## Touchpoints

- `move-chat.sh` — the new tool (preflight, plan, staging + rewrite, transfer, settings guard, next steps).
- `migrate-claude-to-starlight.sh` — read-only reference; unchanged.

## Alternatives considered

- **Moving all projects** (seed behaviour) — out by R-claude-chat-mover-1.
- **A single session as the unit** — out by R-claude-chat-mover-5 (memory is per project).
- **Moving global config** — out by R-claude-chat-mover-7.
- **Rewriting on the target** — see D2.
