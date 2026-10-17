# External Review: single-chat-move (iteration 1)

**Reviewer**: GPT-6
**Date**: 2026-10-17

## CRITICAL

None.

## WARNING

### Scenario coverage is absent from the scenario map
**File**: orbit/changes/single-chat-move/tasks.md:26
**Description**: `orbit status --change single-chat-move --scenarios --json` reports 27 uncovered scenarios, with no behaviour, text, observed, or untestable declarations. Completed task checkboxes and narrative test results do not provide the requested scenario coverage. Register the harness and real-machine observations using supported scenario declarations, then verify the scenario map recognizes them.

### Remote code destination is not shell-quoted
**File**: move-chat.sh:188
**Description**: Quoting `"$REMOTE:$REL/"` protects the local argument but does not protect its path when protocol-29 rsync constructs the remote shell command. A supported project such as `~/code/my project` reaches the code-copy step with an unquoted remote destination containing whitespace; shell metacharacters can also change command interpretation. Chat data and settings have already been transferred when this fails. Quote the destination for the remote shell using a method compatible with the supported rsync and POSIX shell. The fake rsync wrapper bypasses remote shell parsing, so add verification that exercises that boundary.

### Settings read errors are treated as missing settings
**File**: move-chat.sh:161
**Description**: `cat ~/.claude/settings.json 2>/dev/null || true` suppresses every read failure. An existing unreadable settings file therefore becomes `{}` locally. If the containing directory is writable, the subsequent temporary-file rename can replace that existing file with only `cleanupPeriodDays`, losing its other settings. Distinguish an absent file from an unsuccessful read; abort the settings update with an explicit diagnostic on read errors.

### Concurrent moves can lose settings or fail after transferring chat data
**File**: move-chat.sh:180
**Description**: Every invocation uses the same `settings.json.move-chat` temporary filename, and the read-modify-write sequence has no coordination. Two moves to the same host can overwrite each other's temporary contents, fail when one has already renamed the shared file, or replace a larger retention window with a smaller value computed from stale settings. Use a unique temporary file and serialize the complete settings read, maximum calculation, and replacement on the target.

## SUGGESTION

None.

## Blocks

None.

## Direction

**Disposition**: hold

The basic transfer follows the design, but destination quoting and settings updates need stronger handling before this is dependable for the full documented input surface. The verification record also needs to connect its evidence to the declared scenarios.

## Notes

Reviewed the change range beginning at `b60a449`, the architecture and change artifacts, both new scripts, and the unchanged seed script. All tasks are checked; the real-machine re-run task explicitly records a user-requested substitution with harness evidence.

`orbit validate single-chat-move` passed. Bash syntax checks passed for both scripts. Shellcheck is unavailable. The harness was not executed because it creates files and this environment permits only reads; real-machine results were inspected as recorded evidence, not independently repeated.

No `CLAUDE.md`, `orbit/project.md`, root convention files, archived `orbit/specs/`, or perspective/critical-path lenses are present. Baseline and named-lens checks therefore had no inputs.

The findings file could not be written, committed, or pushed because the workspace is read-only. This complete chat output is the fallback record for manual saving and committing.