## Context

Claude Code stores a chat under `~/.claude/projects/<slug>/`, where `<slug>` is the project's absolute path with every non-alphanumeric character turned into `-` (observed 2026-10-16, Claude Code 2.1.301; see `orbit/architecture/claude-chat-mover.md` Premise). That directory holds session transcripts (`<uuid>.jsonl`), per-session sidecars (`<uuid>/subagents/`, `<uuid>/tool-results/`) and the project's `memory/`. Rewind checkpoints live separately in `~/.claude/file-history/<uuid>/`.

Other session-keyed stores were checked on 2026-10-17: the only other directory named by a session uuid is `~/.claude/session-env/<uuid>/` (the session-start hook environment — per-machine, regenerated on resume), which is not moved. `sessions/<pid>.json` is keyed by process, not session. No symlinks exist under `projects/` or `file-history/` today; the oldest session transcript is from 2026-09-17.

Transcripts embed absolute paths in two forms that both break on another machine:
- the home path — `"cwd":"/Users/sal/code/chat_mover"`, tool-call file paths;
- the home path **plus the slug** — e.g. `/Users/sal/.claude/projects/-Users-sal-code-chat-mover/memory/` and `…/<uuid>/tool-results/…` (observed: 30 such references in one session of this repo).

The seed example `migrate-claude-to-starlight.sh` already has the right shape (preflight over ssh, slug remap, `rsync --ignore-existing`, `cleanupPeriodDays` guard) but moves every project, matches by slug prefix, skips file-history, rewrites only `$OLD_HOME/` (not the slug), and does its rewrite on the target with GNU `sed -i`, which fails on macOS.

Source is this MacBook (`rsync` is `openrsync`, protocol 29 — supports `-a -z --exclude --ignore-existing`, but not `--mkpath`). Targets: Fedora desktop and Mac mini.

## Goals / Non-Goals

**Goals:**
- One script, one project per run, readable top to bottom (R-claude-chat-mover-4).
- Everything the chat needs lands on the target and resolves there (R-claude-chat-mover-3, -5).
- Same behaviour on Linux and macOS targets (R-claude-chat-mover-2).
- Never overwrite chat data, file history or code on the target; never modify the source.

**Non-Goals:**
- Moving several projects at once, or global config (R-claude-chat-mover-1, -7).
- A dry-run or preview mode — the tool is tested once, up front (R-claude-chat-mover-8).
- Syncing a chat that grew after it was moved (re-run copies only new files; see Risks).
- Sessions started from a subfolder of the project (they have their own slug directory).
- Projects outside `$HOME`.
- Reinstalling dependencies, signing in, or trusting the folder on the target — printed as next steps.

## Decisions

### D1 — Exact slug match, not prefix glob
Resolve the project argument (no `/` → `~/code/<arg>`, else a path), require the folder to exist, take its physical path with `cd … && pwd -P` (what Claude Code's recorded `cwd` is), refuse it unless it lies under `$HOME`, compute `slug = slugify(path)` and use only `~/.claude/projects/<slug>`. The seed's `"$OLD_PREFIX"-*` glob is what pulls `home-env-test` in with `home-env`. *Alternative:* scan transcripts for `cwd` under the project — more complete (subfolder sessions) but more code and slower; rejected for simplicity.

### D2 — Rewrite on a local staging copy, then rsync
Copy the slug directory with a local `rsync -a` (times kept, symlinks copied as links) into a temp staging dir on the Mac (`mktemp -d`), under the target slug name; rewrite there; then `rsync -a --ignore-existing` the staged tree to the target's `~/.claude/projects/`. *Why:* the target needs only `ssh` + `rsync` (no `sed -i` dialect issue, no python on the target), the source is never modified, and there is nothing to "double-rewrite" on a re-run. *Alternative:* the seed's remote rewrite — rejected for the BSD/GNU `sed -i` split and because it rewrites files already on the target.

### D3 — Rewrite with Python, byte-level, boundary-aware
A small embedded `python3` walks the staged tree and, per regular file (`os.path.islink` → skip and report; never opened), replaces bytes:
1. `OLD_HOME` → `NEW_HOME` where the next byte is `/`, `"`, `'`, whitespace, `\`, or end of file (regex lookahead `(?=[/"'\s\\]|$)`) — so `/Users/salvador` is not touched;
2. `OLD_SLUG` → `NEW_SLUG` (plain replace; runs after step 1 so `-Users-sal-…` inside already-rewritten memory paths becomes `-home-sal-…`).

Step 2 is a plain substring replace: the old slug of `home-env` also matches the start of `-Users-sal-code-home-env-test` in text, and the result (`-home-sal-code-home-env-test`) is that project's correct target slug, so it is consistent. Files are rewritten only when their content changes, and each rewritten file gets its original atime/mtime back with `os.utime`, so the resume list keeps its order and the retention window (D7) measures real age. The symlinks found are printed as a warning. *Alternative:* `sed` — rejected for portability and no lookahead.

### D4 — What is not rewritten
`file-history/` holds snapshots of the user's file contents used by rewind; rewriting them would make rewind restore altered files, so they copy verbatim. Project code is copied verbatim too (it's the user's repo). Temp/scratchpad paths (`/private/tmp/claude-501/<slug>/…`) are dead on any target; the slug replace may touch them, which is harmless.

### D5 — File-history selection
For each `<uuid>.jsonl` directly in the slug directory, copy `~/.claude/file-history/<uuid>/` if it exists, with `rsync -a --ignore-existing` into the target's `~/.claude/file-history/`.

### D6 — Code copy
`ssh mkdir -p` the target project's parent directory (openrsync has no `--mkpath`), then `rsync -a -z --ignore-existing` of `$PROJECT/` to `$TARGET:<path relative to home>/`, excluding `node_modules .venv venv __pycache__ .DS_Store`. `--ignore-existing` means a repo already cloned on the target keeps its files; the Mac's untracked files fill gaps.

### D7 — `cleanupPeriodDays` edited on the source side, before the code copy
The one permitted write to an existing target file. Directly after chat data and file history are copied — before the code copy, so a code-copy failure can't skip it — read the target's `~/.claude/settings.json` with `ssh 'cat … 2>/dev/null || true'`; a missing or empty file is `{}`. Compute `needed = age in days of the oldest moved transcript (by mtime) + 365`; set `cleanupPeriodDays = max(existing, needed)` locally with `python3`, keeping all other keys, and write it back with `ssh 'cat > file'` only when it changed. Non-empty unparseable JSON → warn and leave it. Keeps the target requirement at ssh + rsync.

### D8 — CLI shape and confirmation
`move-chat.sh <project> --remote HOST [--skip-code] [--yes]`. `--remote` is required, since there are two targets. Same `say`/`warn`/`die` helpers, `set -euo pipefail`. Preflight checks `rsync` and `python3` locally, ssh reachability and `rsync` on the target, and that the target's `$HOME` reads back as a clean absolute path (`^/[^[:cntrl:]]*$`). A shell startup file that prints for non-interactive sessions — observed 2026-10-17 on starlight, whose terminal-title `DEBUG` trap prefixed every command's output with `\e]0;…\a` — would otherwise corrupt `NEW_HOME`, and with it every rewritten path, and breaks rsync's protocol. Then the tool prints the source chat directory, the target chat directory, the source/target project folders (or "code skipped") and the session count, and asks `Proceed? [y/N]` — `y` or `Y` proceeds — unless `--yes`. No dry-run mode (R-claude-chat-mover-8): correctness is established by the up-front tests in tasks group 5.

## Risks / Trade-offs

- [Chat keeps growing on the Mac after a move] → re-running copies only *new* files; an already-copied transcript that grew is not updated (`--ignore-existing`). The confirmation step says so; for a clean re-move, delete the target's copy first by hand.
- [A `claude` process is writing the chat during the move] → preflight warns; the user should exit the session first.
- [Claude Code changes its on-disk layout] → the layout was observed on 2.1.301; the confirmation shows which directories will be copied, and the up-front tests would need re-running after a Claude Code upgrade that changes the layout.
- [No preview of individual files] → by choice (R-claude-chat-mover-8); the prefix-sibling and contents behaviour is proven once by tasks 5.3–5.5 instead of being inspected on every run.
- [A symlink appears in a chat later] → it is copied as a link and named in a warning; on the target it may dangle.
- [Project trust / per-project settings live in `~/.claude.json` on the source] → not moved (global file, R-7); first launch on the target asks to trust the folder once.
- [Code paths inside project files (e.g. `.claude/settings.local.json`) still say `/Users/sal`] → code is not rewritten by design; the closing next-steps text tells the user to check the project's `.claude/` and `CLAUDE.md` for old-home paths.

## Touchpoints

- `move-chat.sh` — the new tool (preflight, confirmation, staging + rewrite, transfer, settings guard, next steps).
- `migrate-claude-to-starlight.sh` — read-only reference; unchanged.

## Alternatives considered

- **Moving all projects** (seed behaviour) — out by R-claude-chat-mover-1.
- **A single session as the unit** — out by R-claude-chat-mover-5 (memory is per project).
- **Moving global config** — out by R-claude-chat-mover-7.
- **Rewriting on the target** — see D2.
- **Pull from the target instead of push from the Mac** (2026-10-17) — declined by the user; see the architecture doc's Considered & out.
- **A dry-run mode listing every file or every session** (2026-10-17) — out by R-claude-chat-mover-8: test the tool up front instead of previewing each move.
- **Keeping a project outside `$HOME` at its absolute path on the target** (2026-10-17) — rejected; R-claude-chat-mover-5 scopes a chat to a folder under `~/code`, so outside-home projects are refused.
- **A fixed 365-day window, or not preserving file times** (2026-10-17) — rejected: a fixed window deletes sessions older than it; fresh mtimes would scramble the resume list.
