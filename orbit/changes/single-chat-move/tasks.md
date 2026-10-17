## 1. Script skeleton

- [ ] 1.1 Create `move-chat.sh` (executable) with `set -euo pipefail`, header usage text, `say`/`warn`/`die`/`slugify` helpers from the seed, and argument parsing for `<project> --remote HOST --dry-run --skip-code --yes -h` (D8); missing project or `--remote` → usage + non-zero exit
- [ ] 1.2 Resolve `<project>`: bare name → `~/code/<name>`, otherwise a path; make it absolute; compute `OLD_SLUG`; require `~/.claude/projects/$OLD_SLUG` to exist exactly (D1); refuse a project outside `$HOME` unless `--skip-code`

## 2. Preflight and plan

- [ ] 2.1 Preflight: `ssh -o BatchMode=yes` reachability with the seed's fix-it message, read `NEW_HOME`, check `rsync` on the target; warn if a `claude` process is running locally
- [ ] 2.2 Compute `NEW_SLUG` from the target project path (`$NEW_HOME/<path relative to $HOME>`) and list the chat: session uuids (`*.jsonl` directly in the slug dir), sidecar dirs, memory files, existing `file-history/<uuid>` dirs (D5)
- [ ] 2.3 Print the plan: source/target project path, source/target slug, counts, code size or "skipped", total size, and the note that already-copied transcripts are not updated on re-run; `--dry-run` stops here; otherwise confirm unless `--yes`

## 3. Stage and rewrite

- [ ] 3.1 Copy the slug dir into a `mktemp -d` staging dir under the target slug name; `trap` removes the staging dir on exit (D2)
- [ ] 3.2 Embedded `python3` rewrite over the staged tree: `OLD_HOME` → `NEW_HOME` with the `(?=[/"'\s\\]|$)` boundary, then `OLD_SLUG` → `NEW_SLUG`; byte-level; write only changed files; print how many files changed (D3)

## 4. Transfer

- [ ] 4.1 `ssh mkdir -p` the target's `~/.claude/projects` and `~/.claude/file-history`; `rsync -a -z --ignore-existing` the staged slug dir to `~/.claude/projects/`
- [ ] 4.2 `rsync -a -z --ignore-existing` each selected `~/.claude/file-history/<uuid>/` verbatim (D4, D5)
- [ ] 4.3 Unless `--skip-code`: `rsync -a -z --ignore-existing` the project folder with the excludes to the same home-relative path on the target (D6)
- [ ] 4.4 `cleanupPeriodDays` guard: fetch target `settings.json` via `ssh cat`, raise to ≥365 locally with `python3` preserving other keys, write back only if changed; unparseable → warn, leave untouched (D7)
- [ ] 4.5 Print next steps: `cd <target project> && claude --resume`, reinstall dependencies, trust the folder on first launch, check project `.claude/` / `CLAUDE.md` for old-home paths

## 5. Verify (stage exit criteria)

- [ ] 5.1 `bash -n move-chat.sh` and `shellcheck move-chat.sh` (if installed) are clean
- [ ] 5.2 Rewrite check on a fixture: run the python rewrite on a temp tree containing `"cwd":"/Users/sal/code/x"`, `/Users/sal/.claude/projects/-Users-sal-code-x/memory/`, and `/Users/salvador/notes`; confirm the first two map to `/home/sal…`/`-home-sal-code-x` and the third is unchanged
- [ ] 5.3 `./move-chat.sh home-env --remote <fedora> --dry-run`: plan lists only `-Users-sal-code-home-env` content (nothing from `home-env-test`) and the target is unchanged
- [ ] 5.4 Real move to the Fedora desktop: `claude --resume` in `~/code/<project>` lists the sessions, opens one with full history, and memory is loaded
- [ ] 5.5 Real move to the Mac mini: same checks as 5.4
- [ ] 5.6 Re-run 5.4's move: no files copied, target unchanged; source slug dir unchanged (compare checksums before/after)
