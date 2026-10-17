# Reference: external-findings file format (for `--from-file` markdown parsing)

This is ONE of two supported `--from-file` formats; the other is internal findings JSON (covers both `command: "review"` AND `command: "audit-drift"` shapes) — see `internal-findings-format.md`. The parser auto-detects format via content sniff (leading `# External Review:` → this format; leading `{` → JSON).

The `--from-file <path>` markdown path ingests an external-AI's findings file. The file is produced by the external-handoff branch of `/orbit:review --as <mode> --reviewer external` — typically the external AI writes it after pulling the repo and reading the prompt.

This format MUST match what `/orbit:review --as <mode> --reviewer external` instructs the external AI to write. Deviations on either side break the cross-AI loop.

## Expected file format

```markdown
# External Review: <change-name> (iteration <N>)

**Reviewer**: <model name>
**Date**: <YYYY-MM-DD>

## CRITICAL

### <Finding title>
**File**: <path>:<line>
**Description**: <what's wrong + specific recommendation>
**Reproduction**: <the re-executable case, per `orbit-conventions`' Severity ladder; a CRITICAL without one is counted and marked unreproduced, never re-graded>

## WARNING

### <Finding title>
**File**: <path>:<line>
**Description**: <text>

## SUGGESTION

### <Finding title>
**File**: <path>:<line>
**Description**: <text>

## Blocks

<Optional — conditions that must be addressed before apply but are not severities (an `orbit validate` failure, an unresolved `@review:` marker), one `- <what>` line each; `None.` if none. Listed FIRST at triage and never walked as findings.>

## Direction

**Disposition**: <forward | hold>

<REQUIRED on every return — the reviewer's forward recommendation (which way and why), per `orbit-conventions`' External-review findings markdown format, which owns the section and its opener; the content contract is `orbit-report-rendering`'s Direction requirement's. NEVER WALKED: the walk lists no entry for it — the report renders it in its own `### Direction` section and marks a return without it `[no direction]`, a non-conforming one `[direction malformed]`; the counters ignore the section.>

## Notes

<Optional — the Notes body renders VERBATIM into the report's Commentary slot; it carries pattern/probing/risk texture and never finding counts, gate verdicts, or next commands. The format is owned by `orbit-conventions`' External-review findings markdown format; the prompt template in the `orbit-review` skill (`references/prompt-template.md`) is its checked copy.>
```

The `**Reproduction**:` body follows the `**Description**:` body and runs to the next `###` or `##` heading; a `**Reproduction**:` line placed BEFORE `**Description**:` is not recognised. Inside any body, a field-shaped line (`**File**: other.md:9`) is CONTENT — the finding's file is the `**File**:` line read before its Description opened (per `orbit-conventions`' External-review findings markdown format, the field-line rule).

## Parser contract

For each finding under each severity section, construct a virtual marker with:

| Virtual marker field | Source |
|---|---|
| `severity` | The `## <SEVERITY>` section header (CRITICAL / WARNING / SUGGESTION) |
| `title` | The `### <Finding title>` line |
| `file:line` | The `**File**: <path>:<line>` field (read BEFORE the Description body opens — a path quoted inside a body never re-files the finding) |
| `description` | The `**Description**: <text>` body (ended by `**Reproduction**:`, the next `###`, or the next `##`) |
| `reproduction` | The `**Reproduction**: <text>` body when present; absent otherwise — a CRITICAL marker without one is tagged `unreproduced` at triage and in its resolution entry's `reproduction_rerun` |
| `source` | Always `external` (vs `inline` for grep-found markers) |

Entries under `## Blocks` (`- <what>` lines) are NOT virtual markers: they are listed FIRST in the triage table as blocks and never walked (per `orbit-conventions`' Severity ladder, a block is a report with a name; nothing stops on it mechanically and the stop is the human's).

Virtual markers walk the same lifecycle as inline markers, with one exception: **the marker-removal step (Step 3e in the SKILL.md walk) is a no-op for virtual markers** — there's no source-file marker text to delete.

## Malformed input handling

If the file is missing required sections, has broken field labels, or otherwise can't be parsed cleanly:

- Report a parse error to the user with the expected format above
- Exit without acting on partial input — do not attempt to walk a half-parsed marker set
- The user fixes the file and re-runs

## Tolerated variations

The parser SHOULD be lenient on:

- Whitespace between sections (blank lines OK)
- `**Reviewer**:` and `**Date**:` field absence (warn, don't fail; reviewer attribution falls back to "unknown external AI")
- Optional `## Notes` section absent (treated as no notes)
- **Empty-severity sentinel**: when a severity section contains the single body line `None.` (or equivalent — `None`, `none.`, `(none)`) with no `### <Title>` entries underneath, the section parses cleanly to zero findings at that severity. This matches what external reviewers naturally write when there are no findings at a given severity.

The parser MUST be strict on:

- Severity section headers (`## CRITICAL`, `## WARNING`, `## SUGGESTION` — exact case)
- Finding titles use `### ` prefix
- `**File**:`, `**Description**:` and `**Reproduction**:` field labels (exact)

The reason for the strict/lenient split: the strict items are what the orbit format guarantees and what allows cross-AI loops to work; the lenient items vary across reviewers without breaking semantics.

## Quick worked example of valid input

```markdown
# External Review: <change-name> (iteration 1)

**Reviewer**: GPT-5 Codex
**Date**: 2026-05-18

## CRITICAL

None.

## WARNING

### First finding title
**File**: path/to/file.md:42
**Description**: What's wrong + recommendation.

### Second finding title
**File**: another/path.md:88
**Description**: Detail.

## SUGGESTION

### A suggestion
**File**: README.md:909
**Description**: Detail.

## Notes

Overall impression goes here.
```

This example has 0 CRITICAL (using `None.` sentinel), 2 WARNING, 1 SUGGESTION. The codex-pushed iter-1 system-mode findings file (`orbit/changes/add-review-workflows/.orbit-runs/external-system-2026-05-18T17-33-40Z.md`) is a real-world example produced by GPT-5 Codex.
