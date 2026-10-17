---
name: orbit-verify-change
description: Verify implementation matches change artifacts. Use when the user wants to validate that implementation is complete, correct, and coherent before archiving.
license: MIT
compatibility: Requires orbit CLI.
metadata:
  author: openspec
  version: "1.0"
  generatedBy: "2.0.1"
---

Verify that an implementation matches the change artifacts (specs, tasks, design).

**Input**: Optionally specify a change name. If omitted, check if it can be inferred from conversation context. If vague or ambiguous you MUST prompt for available changes.

**Steps**

1. **If no change name provided, prompt for selection**

   Run `orbit list --json` to get available changes. Use the **AskUserQuestion tool** to let the user select.

   Show changes that have implementation tasks (tasks artifact exists).
   Include the schema used for each change if available.
   Mark changes with incomplete tasks as "(In Progress)".

   **IMPORTANT**: Do NOT guess or auto-select a change. Always let the user choose.

2. **Check status to understand the schema**
   ```bash
   orbit status --change "<name>" --json
   ```
   Parse the JSON to understand:
   - `schemaName`: The workflow being used (e.g., "spec-driven")
   - Which artifacts exist for this change

3. **Get the change directory and load artifacts**

   ```bash
   orbit instructions apply --change "<name>" --json
   ```

   This returns the change directory and `contextFiles` (artifact ID -> array of concrete file paths). Read all available artifacts from `contextFiles`.

4. **Initialize verification report structure**

   Create a report structure with three dimensions:
   - **Completeness**: Track tasks and spec coverage
   - **Correctness**: Track requirement implementation and scenario coverage
   - **Coherence**: Track design adherence and pattern consistency

   Each dimension can have CRITICAL, WARNING, or SUGGESTION issues.

5. **Verify Completeness**

   **Task Completion**:
   - If `contextFiles.tasks` exists, read every file path in it
   - Parse checkboxes: `- [ ]` (incomplete) vs `- [x]` (complete)
   - Count complete vs total tasks
   - If incomplete tasks exist:
     - Add CRITICAL issue for each incomplete task
     - Recommendation: "Complete task: <description>" or "Mark as done if already implemented"

   **Spec Coverage**:
   - If delta specs exist in `orbit/changes/<name>/specs/`:
     - Extract all requirements (marked with "### Requirement:")
     - For each requirement:
       - Search codebase for keywords related to the requirement
       - Assess if implementation likely exists
     - If requirements appear unimplemented:
       - Add CRITICAL issue: "Requirement not found: <requirement name>"
       - Recommendation: "Implement requirement X: <description>"

6. **Verify Correctness**

   **Requirement Implementation Mapping**:
   - For each requirement from delta specs:
     - Search codebase for implementation evidence
     - If found, note file paths and line ranges
     - Assess if implementation matches requirement intent
     - If divergence detected:
       - Add WARNING: "Implementation may diverge from spec: <details>"
       - Recommendation: "Review <file>:<lines> against requirement X"

   **Scenario Coverage**:
   - For each scenario in delta specs (marked with "#### Scenario:"):
     - Check if conditions are handled in code
     - If a scenario's conditions are not handled in code:
       - Add WARNING: "Scenario not handled in code: <scenario name>"
       - Recommendation: "Implement scenario: <description>"
   - Take test coverage from the scenario map — never trace scenarios to tests by searching test files:
     ```bash
     orbit status --change "<name>" --scenarios --json
     ```
     Report what it returns by this table, a CHECKED MIRROR of `orbit-verify-modifications`' `Verify's Scenario Coverage step reads the scenario map`, held byte-equal to it by a parity test (an installed skill cannot open that spec). The table is exhaustive: `change` and `tests` carry no coverage fact and raise nothing.

| what the surface returns | what verify reports |
|---|---|
| the command fails (a non-zero exit, or output that does not parse) | one note naming the error, and the check listed as skipped, per the body's Graceful Degradation; no other row applies |
| `check` is `"off"` | one note: the scenario-map check is off because `scenario_map:` is absent from, or malformed in, `orbit/config.yaml`; no other row applies — no scenario, orphan or malformed finding, and no tracing by any other means |
| `check` is `"on"`, `scenarios` is empty, and no `malformed` entry has `source: "spec"` | one note: the change has no delta scenarios; the rows below for `orphans`, `malformed` and `counts` still apply |
| a `scenarios` entry with `uncovered: true` | a WARNING `Scenario not covered: <capability> :: <requirement> :: <scenario>`, recommending a `@scenario` tag above the test that exercises it, or a ledger entry |
| a `scenarios` entry with any declaration | no finding; its declared kinds are listed as the surface gives them, never summed and never re-graded |
| one or more `malformed` entries with `source: "spec"` (`reason: "unkeyable"`) | ONE WARNING per distinct capability, requirement and scenario triple, naming the triple and its number of entries, stating that `orbit validate` reports it at the level `orbit-scenario-map` assigns, and recommending the title be renamed; every `orphans` entry whose `key` equals that triple joined by ` :: ` is listed under it and is never a finding of its own |
| any other `orphans` entry | a WARNING naming the tag's file and line, or the ledger index, and the key, stating that the key names no scenario of the baseline or this change's delta — a renamed, removed or mistyped key, or a scenario another active change adds, which the map does not distinguish — and recommending the tag or ledger entry be corrected unless it names another active change's scenario |
| a `malformed` entry with source `tag` or `ledger` | a WARNING naming the file and line, or the ledger index, and the surface's `reason` |
| a `malformed` entry with source `ledger-file` | a WARNING naming `orbit/scenario-ledger.yaml`, with no line, and the surface's `reason` |
| `counts` | printed as counts; no ratio of covered scenarios appears in the report or its scorecard |
| `counts.baseline_undeclared` | printed as a count, never a finding |

   An uncovered, orphan or malformed finding is a WARNING for the run-summary emit's fail mode, which `orbit-run-summary-emit`'s `Verify fail-mode recommendations` owns, precedence included — never `scenarios-fail`. Judge nothing the surface computed: whether a declared test really exercises its scenario is the declaration's own record (its kind word).

7. **Verify Coherence**

   **Design Adherence**:
   - If `contextFiles.design` exists:
     - Extract key decisions (look for sections like "Decision:", "Approach:", "Architecture:")
     - Verify implementation follows those decisions
     - If contradiction detected:
       - Add WARNING: "Design decision not followed: <decision>"
       - Recommendation: "Update implementation or revise design.md to match reality"
   - If no design.md: Skip design adherence check, note "No design.md to verify against"

   **Code Pattern Consistency**:
   - Review new code for consistency with project patterns
   - Check file naming, directory structure, coding style
   - If significant deviations found:
     - Add SUGGESTION: "Code pattern deviation: <details>"
     - Recommendation: "Consider following project pattern: <example>"

8. **Generate Verification Report**

   **Summary Scorecard**:
   ```
   ## Verification Report: <change-name>

   ### Summary
   | Dimension    | Status           |
   |--------------|------------------|
   | Completeness | X/Y tasks, N reqs|
   | Correctness  | M/N reqs covered |
   | Coherence    | Followed/Issues  |
   ```

   **Issues by Priority**:

   1. **CRITICAL** (Must fix before archive):
      - Incomplete tasks
      - Missing requirement implementations
      - Each with specific, actionable recommendation

   2. **WARNING** (Should fix):
      - Spec/design divergences
      - Missing scenario coverage
      - Each with specific recommendation

   3. **SUGGESTION** (Nice to fix):
      - Pattern inconsistencies
      - Minor improvements
      - Each with specific recommendation

   **Final Assessment**:
   - If CRITICAL issues: "X critical issue(s) found. Fix before archiving."
   - If only warnings: "No critical issues. Y warning(s) to consider. Ready for archive (with noted improvements)."
   - If all clear: "All checks passed. Ready for archive."

**Verification Heuristics**

- **Completeness**: Focus on objective checklist items (checkboxes, requirements list)
- **Correctness**: Use keyword search, file path analysis, reasonable inference - don't require perfect certainty
- **Coherence**: Look for glaring inconsistencies, don't nitpick style
- **False Positives**: When uncertain, prefer SUGGESTION over WARNING, WARNING over CRITICAL
- **Actionability**: Every issue must have a specific recommendation with file/line references where applicable

**Graceful Degradation**

- If only tasks.md exists: verify task completion only, skip spec/design checks
- If tasks + specs exist: verify completeness and correctness, skip design
- If full artifacts: verify all three dimensions
- Always note which checks were skipped and why

**Output Format**

Use clear markdown with:
- Table for summary scorecard
- Grouped lists for issues (CRITICAL/WARNING/SUGGESTION)
- Code references in format: `file.ts:123`
- Specific, actionable recommendations
- No vague suggestions like "consider reviewing"

---

# Orbit additions

## Four execution disciplines (epitome)

The four disciplines from `orbit-conventions`, embedded per body; detail lives where each fires.

- **Read-before-reference (authoring-time)**: read a construct's actual definition before naming it; unverifiable → ask or leave a `@review:` marker, never guess.
- **Change completeness (modification-time)**: apply substantive modifications fully across ALL affected artifacts; after mechanical edits, sweep for residue AND new bugs the replacement introduced.
- **Pushback (review-time)**: verify each flagged issue against current state before acting; suppress stale findings with evidence rather than re-fixing already-fixed state.
- **No-chaining (turn boundary)**: invoke only the orbit workflow commands the user's message explicitly requests; completing a command ENDS the turn at the position readout + the engine's eligibility line — gate `passed` means *eligible*, not *commanded*.

## Fail-mode classification

The fail mode is YOURS to classify — the engine composes its recommendation from the `fail_mode` you hand it and classifies nothing (`orbit-run-summary-emit`'s `Verify fail-mode recommendations` owns the modes and their precedence). Before composing the emit, run:

```bash
orbit validate <name>
```

Then take the FIRST that holds, by the precedence validator-error > tasks-incomplete > scenarios-fail: `validator-error` when validate fails (its message verbatim as `validator_message`); `tasks-incomplete` when any task is unchecked; `scenarios-fail` when spec scenarios fail against the implementation; otherwise `warnings` on a pass with warnings, and no fail mode on a clean pass.

## Run-summary emit (one-shot at command completion — via the engine emit surface)

(Per `orbit-run-summary-emit`; composed and written via `orbit emit verify` — `orbit-emit-composition`.)

At command completion, compose the narrative payload (`final_assessment`, `verdict`, `fail_mode`, `validator_message`, `warnings_count` (required when `fail_mode: "warnings"`), `scenarios_failed` (optional count with `fail_mode: "scenarios-fail"`), + the required nullable `model`) into a temp file and invoke:

```bash
orbit emit verify --change <name> --payload <payload-file>
```

The ENGINE owns the spine, the trail path, timestamp + collision handling, and `next_recommended` composition (the fail-mode-conditional recommendation — validator-error / tasks-incomplete / scenarios-fail / warnings (pass WITH non-blocking findings — never recorded as clean) / incomplete (aborted or partial verify run) / clean — is composed from the payload's `verdict`/`fail_mode` — the mode you classified above, never re-classified). Never hand-compose the JSON.

