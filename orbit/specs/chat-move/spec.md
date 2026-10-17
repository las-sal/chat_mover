# chat-move Specification

## Purpose
Moving one project's Claude Code chat data (and optionally its code) from this Mac to another machine so it resumes there — selection, confirmation, transfer, path rewriting, code copy, target safety.

## Requirements

### Requirement: Chat selection by project folder
The tool SHALL take exactly one project argument. An argument containing no `/` SHALL mean `~/code/<argument>`; any other argument SHALL be a path to the project folder. The folder SHALL exist, and the tool SHALL resolve it to its physical absolute path (`cd <folder> && pwd -P`, matching the working directory Claude Code records) and compute its slug (that path with every non-alphanumeric character replaced by `-`). A project whose physical path is not under the source home SHALL be refused with an error, whatever other flags are given. The chat SHALL be the single directory `~/.claude/projects/<slug>` matched EXACTLY; directories whose names merely start with the slug SHALL NOT be included. When the folder or the slug directory does not exist the tool SHALL exit non-zero naming what is missing and SHALL change nothing.

#### Scenario: Project by name
- **WHEN** the user runs `move-chat.sh home-env --remote fedora`
- **THEN** the tool selects `~/.claude/projects/-Users-sal-code-home-env` as the chat

#### Scenario: Prefix-sibling excluded
- **WHEN** the user moves `home-env` and `~/.claude/projects/-Users-sal-code-home-env-test` also exists
- **THEN** no file from `-Users-sal-code-home-env-test` is copied to the target

#### Scenario: Unknown project
- **WHEN** the user selects a folder that has no slug directory under `~/.claude/projects`
- **THEN** the tool exits non-zero naming the missing directory, and nothing is copied

#### Scenario: Project outside home
- **WHEN** the project folder's physical path is not under the source home, with or without `--skip-code`
- **THEN** the tool exits non-zero before copying anything

### Requirement: Chat contents
The moved chat SHALL consist of: every file and directory inside the selected slug directory (session transcripts `<uuid>.jsonl`, per-session sidecar directories `<uuid>/` including `subagents/` and `tool-results/`, and `memory/`), plus `~/.claude/file-history/<uuid>/` for each session `<uuid>` that has a transcript in the slug directory and a file-history directory on the source. No other `~/.claude` content SHALL be moved; per-machine session state such as `~/.claude/session-env/<uuid>/` stays behind.

#### Scenario: Sessions, sidecars, memory and file history move together
- **WHEN** the selected chat has two sessions, one with `subagents/` and `tool-results/`, a `memory/` directory, and file-history for both sessions
- **THEN** all of those files exist on the target under the target slug directory and `~/.claude/file-history/`

#### Scenario: Global config untouched
- **WHEN** a chat is moved
- **THEN** the source's `~/.claude/CLAUDE.md`, `skills/`, `commands/`, `agents/`, `history.jsonl` and `settings.json` are not copied to the target

### Requirement: Confirmation before copying
After preflight and before copying anything, the tool SHALL print the source chat directory, the target chat directory (`<host>:~/.claude/projects/<target slug>`), the source and target project folders (or that code is skipped), and the number of sessions. When the target chat directory already exists, the target line SHALL say so and that only missing files will be added. Unless `--yes` is given, the tool SHALL then ask for confirmation and SHALL proceed only when the answer is `y` or `Y`. The tool SHALL have no dry-run mode.

#### Scenario: Directories shown before copying
- **WHEN** the user runs `move-chat.sh home-env --remote fedora` and the target home is `/home/sal`
- **THEN** before any copy the tool prints `~/.claude/projects/-Users-sal-code-home-env` as the source and `fedora:~/.claude/projects/-home-sal-code-home-env` as the target

#### Scenario: Target chat already present
- **WHEN** the target already has `~/.claude/projects/<target slug>`
- **THEN** the confirmation's target line says it already exists and only missing files will be added

#### Scenario: Declined confirmation
- **WHEN** the user runs without `--yes` and answers anything other than `y` or `Y` at the prompt
- **THEN** the tool exits without copying anything

### Requirement: Path rewriting
The tool SHALL rewrite, in every moved regular file under the slug directory, each occurrence of the source home path that is followed by `/`, `"`, `'`, whitespace, `\`, or end of text — never as a prefix of a longer name — to the target home path, and then each occurrence of the source slug to the target slug. The slug directory SHALL be created on the target under the target slug. The rewrite SHALL happen on a staging copy on the source; source files SHALL NOT be modified. Each rewritten file SHALL keep its original modification and access times. Symbolic links SHALL be copied as links and SHALL NOT be opened, followed or rewritten, and the tool SHALL warn listing any it finds. Files under `file-history/` and the project's code SHALL NOT be rewritten. When the source and target homes are identical the rewrite SHALL be a no-op.

#### Scenario: Linux target
- **WHEN** a chat for `/Users/sal/code/home-env` is moved to a target whose home is `/home/sal`
- **THEN** the target holds `~/.claude/projects/-home-sal-code-home-env/`, and its transcripts contain `"cwd":"/home/sal/code/home-env"` and `/home/sal/.claude/projects/-home-sal-code-home-env/memory/` where the source had the `/Users/sal` forms

#### Scenario: Escaped occurrence
- **WHEN** a transcript contains the JSON string text `/Users/sal\n`
- **THEN** the target copy contains `/home/sal\n`

#### Scenario: Same home on a Mac target
- **WHEN** the target home is `/Users/sal`
- **THEN** the slug and file contents on the target are byte-identical to the source

#### Scenario: No partial-name match
- **WHEN** a transcript contains `/Users/salvador/notes`
- **THEN** that text is unchanged on the target

#### Scenario: File times kept
- **WHEN** a transcript last modified on 2026-09-17 is rewritten
- **THEN** its copy on the target still has a modification time of 2026-09-17

#### Scenario: Symlink not followed
- **WHEN** the slug directory contains a symlink pointing at a file elsewhere on the source
- **THEN** the referent's contents are unchanged after the move, and the tool's output names the link

#### Scenario: Source untouched
- **WHEN** a move completes
- **THEN** every file in the source slug directory has the same contents and times as before the run

### Requirement: Project code copy
Unless `--skip-code` is given, the tool SHALL copy the project folder to the same path relative to home on the target (e.g. `~/code/home-env`), creating its parent directories when absent and quoting the destination for the target's shell so a folder name with spaces arrives intact, including `.git` and untracked files, excluding `node_modules`, `.venv`, `venv`, `__pycache__` and `.DS_Store`. Code SHALL NOT be path-rewritten. When `--skip-code` is given the project folder SHALL NOT be copied.

#### Scenario: Code copied with exclusions
- **WHEN** the project contains `.git/` and `node_modules/`
- **THEN** the target project folder contains `.git/` and does not contain `node_modules/`

#### Scenario: Missing parent on the target
- **WHEN** the target has no `~/code` directory
- **THEN** the move creates `~/code/` and copies the project into `~/code/<name>`

#### Scenario: Folder name with a space
- **WHEN** the project folder is `~/code/my app`
- **THEN** the target holds the project's files under `~/code/my app/`

#### Scenario: Skip code
- **WHEN** the user passes `--skip-code`
- **THEN** only Claude chat data is copied and the confirmation says code is skipped

### Requirement: No overwrite on the target
The tool SHALL NOT overwrite or delete any existing chat data, file history or code on the target. The single permitted change to an existing target file is the `cleanupPeriodDays` key in `~/.claude/settings.json`, under the Session retention requirement. Re-running the same move SHALL leave the target's chat data, file history and code unchanged.

#### Scenario: Re-run is a no-op
- **WHEN** the same chat is moved to the same target twice
- **THEN** the second run copies no files and the target's chat data, file history and code are unchanged

#### Scenario: Existing code kept
- **WHEN** the target already has `~/code/home-env/README.md` with different content
- **THEN** the target's `README.md` is unchanged after the move

### Requirement: Session retention on the target
Directly after copying chat data and file history, and before copying code, the tool SHALL ensure the target's `~/.claude/settings.json` has `cleanupPeriodDays` of at least the age in days of the oldest moved session transcript plus 365, keeping an existing larger value and every other key. A missing or empty file SHALL be treated as `{}` and written. If the existing file cannot be read, or is non-empty and cannot be parsed as JSON, the tool SHALL leave it unchanged and print a warning telling the user to set the value by hand. The tool SHALL write the file in place, so it keeps its permissions and, when it is a symbolic link, the link and its target.

#### Scenario: Low cleanup window raised
- **WHEN** the oldest moved session is 40 days old and the target's settings have `cleanupPeriodDays` absent or below 405
- **THEN** after the move it is 405 and all other settings keys are unchanged

#### Scenario: Larger window kept
- **WHEN** the target's `cleanupPeriodDays` is 1000 and the oldest moved session is 40 days old
- **THEN** the value stays 1000

#### Scenario: Missing settings
- **WHEN** the target has no `~/.claude/settings.json`
- **THEN** after the move it exists and contains the computed `cleanupPeriodDays`

#### Scenario: Permissions and symlink kept
- **WHEN** the target's `settings.json` has mode 600, or is a symlink to a dotfiles copy, and its window is raised
- **THEN** afterwards it still has mode 600, or is still the symlink and the dotfiles copy holds the new value

#### Scenario: Unreadable settings
- **WHEN** the target's `settings.json` exists but cannot be read
- **THEN** the file is unchanged and a warning is printed

#### Scenario: Unparseable settings
- **WHEN** the target's `settings.json` is non-empty and not valid JSON
- **THEN** the file is unchanged and a warning is printed

### Requirement: Preflight and target platforms
Before any copy the tool SHALL verify that `rsync` and `python3` exist on the source, that it can reach the target with `ssh -o BatchMode=yes`, and that `rsync` exists on the target, and SHALL read the target's home directory. The home directory SHALL read back as a clean absolute path — beginning with `/` and containing no control characters; anything else means the target's shell prints output for non-interactive ssh commands (which also breaks rsync), and the tool SHALL exit non-zero before copying anything, saying so and how to fix it. The tool SHALL require nothing on the target beyond `ssh`, `rsync` and a POSIX shell, and SHALL work for both a Fedora Linux target and a macOS target. When a `claude` process is running on the source the tool SHALL print a warning that transcripts may be incomplete.

#### Scenario: Unreachable target
- **WHEN** the target cannot be reached over ssh without a password prompt
- **THEN** the tool exits non-zero with a message saying how to fix it, and nothing is copied

#### Scenario: Noisy remote shell
- **WHEN** the target's shell startup prints a terminal-title escape sequence for every command, so the home directory reads back as `\e]0;printf | /home/sal\a/home/sal`
- **THEN** the tool exits non-zero naming the problem and the fix, and nothing is copied

#### Scenario: macOS target
- **WHEN** the target is a Mac with the default BSD userland
- **THEN** the move completes with the same results as on Linux
