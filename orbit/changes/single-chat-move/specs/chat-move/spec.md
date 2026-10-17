## ADDED Requirements

### Requirement: Chat selection by project folder
The tool SHALL take exactly one project argument — a folder name under `~/code` or a path to a project folder — and SHALL resolve it to an absolute path and to its slug (the absolute path with every non-alphanumeric character replaced by `-`). The chat SHALL be the single directory `~/.claude/projects/<slug>` matched EXACTLY; directories whose names merely start with the slug SHALL NOT be included. When the slug directory does not exist the tool SHALL exit with an error naming the expected directory and SHALL change nothing.

#### Scenario: Project by name
- **WHEN** the user runs `move-chat.sh home-env --remote fedora`
- **THEN** the tool selects `~/.claude/projects/-Users-sal-code-home-env` as the chat

#### Scenario: Prefix-sibling excluded
- **WHEN** the user selects `home-env` and `~/.claude/projects/-Users-sal-code-home-env-test` also exists
- **THEN** no file from `-Users-sal-code-home-env-test` appears in the plan or on the target

#### Scenario: Unknown project
- **WHEN** the user selects a folder that has no slug directory under `~/.claude/projects`
- **THEN** the tool exits non-zero naming the missing directory, and nothing is copied

### Requirement: Chat contents
The moved chat SHALL consist of: every file and directory inside the selected slug directory (session transcripts `<uuid>.jsonl`, per-session sidecar directories `<uuid>/` including `subagents/` and `tool-results/`, and `memory/`), plus `~/.claude/file-history/<uuid>/` for each session `<uuid>` that has a transcript in the slug directory and a file-history directory on the source. No other `~/.claude` content SHALL be moved.

#### Scenario: Sessions, sidecars, memory and file history move together
- **WHEN** the selected chat has two sessions, one with `subagents/` and `tool-results/`, a `memory/` directory, and file-history for both sessions
- **THEN** all of those files exist on the target under the target slug directory and `~/.claude/file-history/`

#### Scenario: Global config untouched
- **WHEN** a chat is moved
- **THEN** the source's `~/.claude/CLAUDE.md`, `skills/`, `commands/`, `agents/`, `history.jsonl` and `settings.json` are not copied to the target

### Requirement: Plan and dry run
Before copying, the tool SHALL print a plan listing the source project path and target project path, the source and target slug, the number of sessions, sidecar directories, memory files and file-history directories, whether code will be copied and its size, and the total size. With `--dry-run` the tool SHALL print the plan and SHALL make no change on the source or the target. Without `--dry-run` and without `--yes` the tool SHALL ask for confirmation and SHALL abort unless the answer is yes.

#### Scenario: Dry run changes nothing
- **WHEN** the user runs the tool with `--dry-run`
- **THEN** the plan is printed, and no file is created or modified on the target or the source

#### Scenario: Declined confirmation
- **WHEN** the user runs without `--dry-run` or `--yes` and answers anything other than `y` at the prompt
- **THEN** the tool exits without copying anything

### Requirement: Path rewriting
The tool SHALL rewrite, in every moved file under the slug directory, each occurrence of the source home path (when followed by `/`, a quote, whitespace, or end of text — never as a prefix of a longer name) to the target home path, and each occurrence of the source slug to the target slug. The slug directory SHALL be created on the target under the target slug. The rewrite SHALL happen on a staging copy on the source; source files SHALL NOT be modified. Files under `file-history/` and the project's code SHALL NOT be rewritten. When the source and target homes are identical the rewrite SHALL be a no-op.

#### Scenario: Linux target
- **WHEN** a chat for `/Users/sal/code/home-env` is moved to a target whose home is `/home/sal`
- **THEN** the target holds `~/.claude/projects/-home-sal-code-home-env/`, and its transcripts contain `"cwd":"/home/sal/code/home-env"` and `/home/sal/.claude/projects/-home-sal-code-home-env/memory/` where the source had the `/Users/sal` forms

#### Scenario: Same home on a Mac target
- **WHEN** the target home is `/Users/sal`
- **THEN** the slug and file contents on the target are byte-identical to the source

#### Scenario: No partial-name match
- **WHEN** a transcript contains `/Users/salvador/notes`
- **THEN** that text is unchanged on the target

#### Scenario: Source untouched
- **WHEN** a move completes
- **THEN** every file in the source slug directory has the same contents as before the run

### Requirement: Project code copy
Unless `--skip-code` is given, the tool SHALL copy the project folder to the same path relative to home on the target (e.g. `~/code/home-env`), including `.git` and untracked files, excluding `node_modules`, `.venv`, `venv`, `__pycache__` and `.DS_Store`. Code SHALL NOT be path-rewritten. When `--skip-code` is given the project folder SHALL NOT be copied. When the project folder is not under the source home and `--skip-code` is not given, the tool SHALL exit with an error before copying anything.

#### Scenario: Code copied with exclusions
- **WHEN** the project contains `.git/` and `node_modules/`
- **THEN** the target project folder contains `.git/` and does not contain `node_modules/`

#### Scenario: Skip code
- **WHEN** the user passes `--skip-code`
- **THEN** only Claude chat data is copied and the plan says code is skipped

#### Scenario: Project outside home
- **WHEN** the project folder is not under the source home and `--skip-code` is not given
- **THEN** the tool exits non-zero before copying anything, saying to pass `--skip-code`

### Requirement: No overwrite on the target
The tool SHALL NOT overwrite or delete any existing file on the target — chat data, file history, or code. Re-running the same move SHALL leave the target unchanged.

#### Scenario: Re-run is a no-op
- **WHEN** the same chat is moved to the same target twice
- **THEN** the second run copies no files and the target's files are unchanged

#### Scenario: Existing code kept
- **WHEN** the target already has `~/code/home-env/README.md` with different content
- **THEN** the target's `README.md` is unchanged after the move

### Requirement: Session retention on the target
After copying chat data (not on a dry run), the tool SHALL ensure the target's `~/.claude/settings.json` has `cleanupPeriodDays` of at least 365, creating the file if absent and preserving every other key. If the existing file cannot be parsed as JSON the tool SHALL leave it unchanged and print a warning telling the user to set the value by hand.

#### Scenario: Low cleanup window raised
- **WHEN** the target's settings have `cleanupPeriodDays` absent or below 365
- **THEN** after the move it is 365 and all other settings keys are unchanged

#### Scenario: Unparseable settings
- **WHEN** the target's `settings.json` is not valid JSON
- **THEN** the file is unchanged and a warning is printed

### Requirement: Preflight and target platforms
Before any copy the tool SHALL verify it can reach the target with `ssh -o BatchMode=yes`, that `rsync` exists on both machines, and SHALL read the target's home directory. The tool SHALL require nothing on the target beyond `ssh`, `rsync` and a POSIX shell, and SHALL work for both a Fedora Linux target and a macOS target. When a `claude` process is running on the source the tool SHALL print a warning that transcripts may be incomplete.

#### Scenario: Unreachable target
- **WHEN** the target cannot be reached over ssh without a password prompt
- **THEN** the tool exits non-zero with a message saying how to fix it, and nothing is copied

#### Scenario: macOS target
- **WHEN** the target is a Mac with the default BSD userland
- **THEN** the move completes with the same results as on Linux
