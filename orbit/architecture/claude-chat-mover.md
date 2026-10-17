# Program: claude-chat-mover

> Position is COMPUTED — run `orbit architecture status`. This doc declares; the engine renders.

## Premise

Claude Code chats live on the machine they were started on. This MacBook holds chats that need to continue on another machine — a Fedora Linux desktop or a Mac mini — with their history, memory and supporting files intact, so `claude --resume` on the target picks the chat up as if it had never moved.

The program produces one small tool (a shell script, in the spirit of the seed example `migrate-claude-to-starlight.sh` in the repo root) that moves ONE chat at a time: it analyzes only the chosen chat, copies everything that chat needs to the target, and rewrites machine-specific paths so the chat resolves on the target.

Grounding — what a chat is on disk (observed 2026-10-16 on this MacBook, Claude Code 2.1.301):

- `~/.claude/projects/<slug>/` — one directory per working directory; `<slug>` is the absolute cwd with every non-alphanumeric character replaced by `-` (e.g. `/Users/sal/code/chat_mover` → `-Users-sal-code-chat-mover`). The mapping is lossy (`_` and `/` both become `-`), so the real cwd must be read from the transcripts' `"cwd"` field, not reversed from the slug.
  - `<session-uuid>.jsonl` — the transcript of each session; every entry carries absolute `"cwd"` and tool-call paths.
  - `<session-uuid>/subagents/` and `<session-uuid>/tool-results/` — per-session sidecars (subagent transcripts, spilled tool output).
  - `memory/` — the per-project memory store (`MEMORY.md` index + one file per memory).
- `~/.claude/file-history/<session-uuid>/` — per-session file snapshots backing rewind/checkpoints.
- Transient per-machine state (`sessions/`, `session-env/`, `shell-snapshots/`, `ide/`, `cache/`) is not part of a chat.

## Goals

1. **One chat, whole.** Given one chat directory, the tool moves every file that chat owns (transcripts, sidecars, memory, file-history for its sessions) and nothing belonging to any other chat.
2. **Resumes on the target.** After a move, `cd <project> && claude --resume` on the target lists the moved sessions, opens them with their full history, and the project's memory is loaded.
3. **Paths are right.** Every source-home path inside the moved files (and the slug directory name itself) is rewritten to the target's home, for both a Linux target (`/home/<user>`) and a macOS target (`/Users/<user>`, possibly unchanged).
4. **Safe to run.** Before copying, the tool shows the source and target directories and asks to confirm; a run never overwrites existing chat data, file history or code on the target and leaves the source untouched. Correctness is proven by testing once, up front — not by previewing every move.
5. **Simple.** One readable script; no daemon, no database, no dependencies beyond what both targets already have (ssh, rsync, and a POSIX shell).

## Rulings index

- **R-claude-chat-mover-1** (user, 2026-10-16) — The unit of work is ONE chat directory per run; only that chat is analyzed and moved.
- **R-claude-chat-mover-2** (user, 2026-10-16) — Source is this MacBook; targets are a Fedora Linux desktop and a Mac mini. Both are first-class.
- **R-claude-chat-mover-3** (user, 2026-10-16) — Everything the chat needs moves — transcripts, memory, files — so the chat is picked up on the target with its memory intact; file paths are rewritten as needed.
- **R-claude-chat-mover-4** (user, 2026-10-16) — Keep it simple: build from the seed example `migrate-claude-to-starlight.sh`, not a fancy or general system.
- **R-claude-chat-mover-5** (user, 2026-10-16) — "One chat" = one project folder under `~/code` (e.g. `~/code/home-env`, `~/code/orbit-spec`): ALL Claude sessions recorded for that folder plus its memory. Resolves OQ-1.
- **R-claude-chat-mover-6** (user, 2026-10-16) — Move everything that makes sense, project code included (dependency/build folders excluded); `--skip-code` skips the code, since it can be re-pulled from GitHub. Resolves OQ-2.
- **R-claude-chat-mover-7** (user, 2026-10-16) — Global Claude config (`~/.claude/CLAUDE.md`, skills, commands, agents, settings) is out of scope; project-scoped config travels with the code. Resolves OQ-3.
- **R-claude-chat-mover-8** (user, 2026-10-17) — No dry-run mode. Test the tool once, up front, instead of previewing every move; each run just finds and confirms the source and target directories before copying.

## Program stages

### Stage single-chat-move — Move one chat to a target machine

Depends-on: (none)
Complete: [ ]

Charter: turn the seed example (which moves ALL projects plus global config and code) into a script that moves ONE chosen chat directory to a named target over ssh.

Scope:
- Select the chat by project folder name or path under `~/code` (R-claude-chat-mover-5); refuse a project outside `$HOME`. Match its slug directory EXACTLY — a slug-prefix match is wrong: `-Users-sal-code-home-env` is a prefix of `-Users-sal-code-home-env-test`, a different project.
- Show the source and target chat directories and project folders, and the session count, then confirm (R-claude-chat-mover-8).
- Copy the chat's slug directory (transcripts, sidecars, memory) and `file-history/<uuid>` for each of its sessions; never overwrite on the target.
- Copy the project folder itself to the same place under the target's home, `.git` included, dependency/build folders (`node_modules`, `.venv`, `venv`, `__pycache__`, `.DS_Store`) excluded; `--skip-code` skips it (R-claude-chat-mover-6).
- Rewrite source-home paths to the target home inside the copied files, and rename the slug directory to the target slug.
- Keep the moved sessions' original mtimes, and raise the target's `cleanupPeriodDays` far enough that none of them is purged.
- Confirmation prompt, `--yes`, `--remote HOST`, `--skip-code`.

Known seed-example gap to fix: the remote half uses GNU `sed -i`, which fails on a macOS target (BSD `sed` needs `-i ''`); the rewrite must work on both Fedora and macOS.

Exit criteria:
- Tested once, up front: a move against each target copies exactly the chosen chat — the confirmation names its source directory, and nothing from a prefix-sibling project lands on the target.
- A real run moves a chat with sessions, subagents, tool-results and memory to the Fedora desktop, and `claude --resume` there opens the session with full history and memory.
- The same holds for the Mac mini.
- Re-running the same move is a no-op (no overwrites, no duplicate rewrites).
- Moving `home-env` moves nothing from `home-env-test` (or any other project).

## Open questions

_None open._ OQ-1..OQ-3 resolved 2026-10-16 by R-claude-chat-mover-5..7.

## Considered & out

- **Moving all chats at once** (the seed example's behavior) — out by R-claude-chat-mover-1 (2026-10-16): one chat per run, nothing else analyzed.
- **A single session as the unit** (2026-10-16) — out by R-claude-chat-mover-5: memory is per-project, so the project folder is the unit.
- **Moving global Claude config** (seed example step "global items" + staged `settings.json`) — out by R-claude-chat-mover-7 (2026-10-16): not owned by any one chat. The only target-side settings touch kept is the `cleanupPeriodDays` guard, which protects the moved sessions.
- **Pull instead of push** (user, 2026-10-17) — running the tool on the target and pulling from the MacBook was considered and declined: it needs the MacBook awake and running an ssh server, needs `python3` on the target (the Mac mini lacks it without the Xcode tools), and reworks the script's local reads. Push stays: the tool runs on the MacBook; targets need only an ssh server and `rsync` (R-claude-chat-mover-2).
- **Rewriting scratchpad/temp paths** (2026-10-16) — transcripts also record macOS temp cwds like `/private/tmp/claude-501/<slug>/<uuid>/scratchpad/…`; these are dead scratch locations on any other machine, so they are left as-is rather than remapped.

## Status log

- 2026-10-16 — Doc created via `/orbit:architect claude-chat-mover` (scaffold only).
- 2026-10-16 — Premise, goals, rulings R-1..R-4, stage `single-chat-move` and open questions OQ-1..OQ-3 captured from the user's brief and an on-disk survey of `~/.claude`.
- 2026-10-16 — OQ-1..OQ-3 resolved as R-claude-chat-mover-5..7; `single-chat-move` scope updated (exact slug match, code copy with `--skip-code`).
- 2026-10-17 — R-claude-chat-mover-8 captured during the proposal-review walk of `single-chat-move` (dry-run mode dropped; up-front tests instead); stage scope, Goal 4 and exit criteria updated to match.
