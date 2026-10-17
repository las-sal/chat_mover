## 1. Script skeleton

- [x] 1.1 Create `move-chat.sh` (executable) with `set -euo pipefail`, header usage text, `say`/`warn`/`die`/`slugify` helpers from the seed, and argument parsing for `<project> --remote HOST --skip-code --yes -h` (D8); missing project or `--remote` → usage + non-zero exit
- [x] 1.2 Resolve `<project>` (D1): no `/` → `~/code/<arg>`, else a path; the folder must exist; physical path via `cd … && pwd -P`; refuse a path not under `$HOME`; compute `OLD_SLUG`; require `~/.claude/projects/$OLD_SLUG` to exist exactly

## 2. Preflight and confirmation

- [x] 2.1 Preflight: `rsync` and `python3` on the source; `ssh -o BatchMode=yes` reachability with the seed's fix-it message; read `NEW_HOME`; `rsync` on the target; warn if a `claude` process is running locally
- [x] 2.2 Compute `NEW_SLUG` from the target project path (`$NEW_HOME/<path relative to $HOME>`) and collect the chat: session uuids (`*.jsonl` directly in the slug dir) and existing `file-history/<uuid>` dirs (D5)
- [x] 2.3 Print the source chat dir, target chat dir (`<host>:~/.claude/projects/$NEW_SLUG`), source/target project folders or "code skipped", the session count, and the note that already-copied transcripts are not updated on re-run; ask `Proceed? [y/N]` (`y`/`Y` only) unless `--yes` (D8)

## 3. Stage and rewrite

- [x] 3.1 Local `rsync -a` of the slug dir into a `mktemp -d` staging dir under the target slug name (times kept, symlinks as links); `trap` removes the staging dir on exit (D2)
- [x] 3.2 Embedded `python3` rewrite over the staged tree: skip and report symlinks; `OLD_HOME` → `NEW_HOME` with the `(?=[/"'\s\\]|$)` boundary, then `OLD_SLUG` → `NEW_SLUG`; byte-level; write only changed files and restore their atime/mtime with `os.utime`; print how many files changed and warn naming any symlinks (D3)

## 4. Transfer

- [x] 4.1 `ssh mkdir -p` the target's `~/.claude/projects`, `~/.claude/file-history` and (unless `--skip-code`) the target project's parent directory; `rsync -a -z --ignore-existing` the staged slug dir to `~/.claude/projects/`
- [x] 4.2 `rsync -a -z --ignore-existing` each selected `~/.claude/file-history/<uuid>/` verbatim (D4, D5)
- [x] 4.3 `cleanupPeriodDays` guard (D7): fetch target `settings.json` via `ssh cat` (missing/empty → `{}`); `needed` = oldest moved transcript's age in days + 365; set `max(existing, needed)` with `python3` keeping other keys; write back only if changed; non-empty unparseable → warn, leave untouched
- [x] 4.4 Unless `--skip-code`: `rsync -a -z --ignore-existing` the project folder with the excludes to the same home-relative path on the target (D6)
- [x] 4.5 Print next steps: `cd <target project> && claude --resume`, reinstall dependencies, trust the folder on first launch, check project `.claude/` / `CLAUDE.md` for old-home paths

## 5. Up-front tests (stage exit criteria — run once, not per move)

- [x] 5.1 `bash -n move-chat.sh` and `shellcheck move-chat.sh` (if installed) are clean
- [x] 5.2 Rewrite fixture: run the python rewrite on a temp tree containing `"cwd":"/Users/sal/code/x"`, `/Users/sal/.claude/projects/-Users-sal-code-x/memory/`, `/Users/sal\n` (escaped), `/Users/salvador/notes`, and a symlink to a file outside the tree; confirm the first three map to `/home/sal…`/`-home-sal-code-x`, the fourth is unchanged, every rewritten file keeps its mtime, the symlink's referent is unchanged, and the link is named in the output
- [ ] 5.3 Real move of `home-env` to the Fedora desktop while `-Users-sal-code-home-env-test` exists on the source: the confirmation names `-Users-sal-code-home-env` as the source, and the target has no `-home-sal-code-home-env-test` directory and no file-history from `home-env-test`'s sessions
- [ ] 5.4 On the Fedora desktop: `claude --resume` in `~/code/<project>` lists the sessions, opens one with full history, memory is loaded, and moved transcripts keep their source mtimes
- [ ] 5.5 Real move to the Mac mini: same checks as 5.3–5.4
- [ ] 5.6 Re-run 5.3's move: no chat data, file history or code copied, and those unchanged on the target; source slug dir unchanged (compare checksums and mtimes before/after)
- [x] 5.7 Error and edge paths: unknown project and a project outside `$HOME` exit non-zero with nothing copied; answering `n` at the prompt copies nothing; an existing different `~/code/<project>/README.md` on the target is kept; target `settings.json` absent, below the needed window, above it, and non-empty invalid JSON each behave per the Session retention requirement
