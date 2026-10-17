---
name: orbit-bulk-archive-change
description: Archive multiple completed changes at once. Use when archiving several parallel changes.
license: MIT
compatibility: Requires orbit CLI.
metadata:
  author: openspec
  version: "1.0"
  generatedBy: "2.0.1"
---

Archive multiple completed changes in a single operation.

This skill allows you to batch-archive changes, handling spec conflicts intelligently by checking the codebase to determine what's actually implemented.

**Input**: None required (prompts for selection)

**Steps**

1. **Get active changes**

   Run `orbit list --json` to get all active changes.

   If no active changes exist, inform user and stop.

2. **Prompt for change selection**

   Use **AskUserQuestion tool** with multi-select to let user choose changes:
   - Show each change with its schema
   - Include an option for "All changes"
   - Allow any number of selections (1+ works, 2+ is the typical use case)

   **IMPORTANT**: Do NOT auto-select. Always let the user choose.

3. **Batch validation - gather status for all selected changes**

   For each selected change, collect:

   a. **Artifact status** - Run `orbit status --change "<name>" --json`
      - Parse `schemaName` and `artifacts` list
      - Note which artifacts are `done` vs other states

   b. **Task completion** - Read `orbit/changes/<name>/tasks.md`
      - Count `- [ ]` (incomplete) vs `- [x]` (complete), excluding every unchecked task carrying the `(User-validation` marker — the per-change user-validation closure owns those (orbit named edit, per `orbit-archive-modifications`' `User-validation closure at the archive seam`), so a change whose only unchecked tasks carry the marker is never classed incomplete or offered for skipping
      - If no tasks file exists, note as "No tasks"

   c. **Delta specs** - Check `orbit/changes/<name>/specs/` directory
      - List which capability specs exist
      - For each, extract requirement names (lines matching `### Requirement: <name>`)

4. **Detect spec conflicts**

   Build a map of `capability -> [changes that touch it]`:

   ```
   auth -> [change-a, change-b]  <- CONFLICT (2+ changes)
   api  -> [change-c]            <- OK (only 1 change)
   ```

   A conflict exists when 2+ selected changes have delta specs for the same capability.

5. **Resolve conflicts agentically**

   **For each conflict**, investigate the codebase:

   a. **Read the delta specs** from each conflicting change to understand what each claims to add/modify

   b. **Search the codebase** for implementation evidence:
      - Look for code implementing requirements from each delta spec
      - Check for related files, functions, or tests

   c. **Determine resolution**:
      - If only one change is actually implemented -> sync that one's specs
      - If both implemented -> apply in chronological order (older first, newer overwrites)
      - If neither implemented -> skip spec sync, warn user

   d. **Record resolution** for each conflict:
      - Which change's specs to apply
      - In what order (if both)
      - Rationale (what was found in codebase)

6. **Show consolidated status table**

   Display a table summarizing all changes:

   ```
   | Change              | Artifacts | Tasks | Specs   | Conflicts | Status |
   |---------------------|-----------|-------|---------|-----------|--------|
   | schema-management   | Done      | 5/5   | 2 delta | None      | Ready  |
   | project-config      | Done      | 3/3   | 1 delta | None      | Ready  |
   | add-oauth           | Done      | 4/4   | 1 delta | auth (!)  | Ready* |
   | add-verify-skill    | 1 left    | 2/5   | None    | None      | Warn   |
   ```

   For conflicts, show the resolution:
   ```
   * Conflict resolution:
     - auth spec: Will apply add-oauth then add-jwt (both implemented, chronological order)
   ```

   For incomplete changes, show warnings:
   ```
   Warnings:
   - add-verify-skill: 1 incomplete artifact, 3 incomplete tasks
   ```

7. **Confirm batch operation**

   Use **AskUserQuestion tool** with a single confirmation:

   - "Archive N changes?" with options based on status
   - Options might include:
     - "Archive all N changes"
     - "Archive only N ready changes (skip incomplete)"
     - "Cancel"

   If there are incomplete changes, make clear they'll be archived with warnings.

8. **Execute archive for each confirmed change**

   Process changes in the determined order (respecting conflict resolution):

   a. **Sync specs** if delta specs exist:
      - Use the orbit-sync-specs approach (agent-driven intelligent merge)
      - For conflicts, apply in resolved order
      - Track if sync was done

   b. **Perform the archive**:
      ```bash
      mkdir -p orbit/changes/archive
      mv orbit/changes/<name> orbit/changes/archive/YYYY-MM-DD-<name>
      ```

   c. **Track outcome** for each change:
      - Success: archived successfully
      - Failed: error during archive (record error)
      - Skipped: user chose not to archive (if applicable)

9. **Display summary**

   Show final results:

   ```
   ## Bulk Archive Complete

   Archived 3 changes:
   - schema-management-cli -> archive/2026-01-19-schema-management-cli/
   - project-config -> archive/2026-01-19-project-config/
   - add-oauth -> archive/2026-01-19-add-oauth/

   Skipped 1 change:
   - add-verify-skill (user chose not to archive incomplete)

   Spec sync summary:
   - 4 delta specs synced to main specs
   - 1 conflict resolved (auth: applied both in chronological order)
   ```

   If any failures:
   ```
   Failed 1 change:
   - some-change: Archive directory already exists
   ```

**Conflict Resolution Examples**

Example 1: Only one implemented
```
Conflict: specs/auth/spec.md touched by [add-oauth, add-jwt]

Checking add-oauth:
- Delta adds "OAuth Provider Integration" requirement
- Searching codebase... found src/auth/oauth.ts implementing OAuth flow

Checking add-jwt:
- Delta adds "JWT Token Handling" requirement
- Searching codebase... no JWT implementation found

Resolution: Only add-oauth is implemented. Will sync add-oauth specs only.
```

Example 2: Both implemented
```
Conflict: specs/api/spec.md touched by [add-rest-api, add-graphql]

Checking add-rest-api (created 2026-01-10):
- Delta adds "REST Endpoints" requirement
- Searching codebase... found src/api/rest.ts

Checking add-graphql (created 2026-01-15):
- Delta adds "GraphQL Schema" requirement
- Searching codebase... found src/api/graphql.ts

Resolution: Both implemented. Will apply add-rest-api specs first,
then add-graphql specs (chronological order, newer takes precedence).
```

**Output On Success**

```
## Bulk Archive Complete

Archived N changes:
- <change-1> -> archive/YYYY-MM-DD-<change-1>/
- <change-2> -> archive/YYYY-MM-DD-<change-2>/

Spec sync summary:
- N delta specs synced to main specs
- No conflicts (or: M conflicts resolved)
```

**Output On Partial Success**

```
## Bulk Archive Complete (partial)

Archived N changes:
- <change-1> -> archive/YYYY-MM-DD-<change-1>/

Skipped M changes:
- <change-2> (user chose not to archive incomplete)

Failed K changes:
- <change-3>: Archive directory already exists
```

**Output When No Changes**

```
## No Changes to Archive

No active changes found. Create a new change to get started.
```

**Guardrails**
- Allow any number of changes (1+ is fine, 2+ is the typical use case)
- Always prompt for selection, never auto-select
- Detect spec conflicts early and resolve by checking codebase
- When both changes are implemented, apply specs in chronological order
- Skip spec sync only when implementation is missing (warn user)
- Show clear per-change status before confirming
- Use single confirmation for entire batch
- Track and report all outcomes (success/skip/fail)
- Preserve .openspec.yaml when moving to archive
- Archive directory target uses current date: YYYY-MM-DD-<name>
- If archive target exists, fail that change but continue with others

---

# Orbit additions

## Four execution disciplines (epitome)

The four disciplines from `orbit-conventions`, embedded per body; detail lives where each fires.

- **Read-before-reference (authoring-time)**: read a construct's actual definition before naming it; unverifiable → ask or leave a `@review:` marker, never guess.
- **Change completeness (modification-time)**: apply substantive modifications fully across ALL affected artifacts; after mechanical edits, sweep for residue AND new bugs the replacement introduced.
- **Pushback (review-time)**: verify each flagged issue against current state before acting; suppress stale findings with evidence rather than re-fixing already-fixed state.
- **No-chaining (turn boundary)**: invoke only the orbit workflow commands the user's message explicitly requests; completing a command ENDS the turn at the position readout + the engine's eligibility line — gate `passed` means *eligible*, not *commanded*.

## Per-change consent (D1 — per `orbit-lifecycle-consent`)

Archive is a consent-scoped command; the bulk wrapper applies the provenance rule PER CHANGE:

- **User-typed `/orbit:bulk-archive`**: the Step 7 batch confirmation IS the user's invocation for the confirmed set — no per-change consent prompt fires, and each inner archive's run summary records `consent: "user-invoked"`.
- **AI-mediated arrival** (delegation, inference, handoff — no explicit same-turn user invocation of the bulk command): fire the consent **AskUserQuestion** per change BEFORE that change's writes (position readout + what that archive will write: deltas/capabilities to sync + the move — Proceed / Abort). Proceed records `consent: "prompted"` in that change's run summary; Abort skips that change (no writes, no summary for it) without stopping the rest of the batch.
- **When provenance is uncertain, treat the arrival as AI-mediated.**

**Consent-era stamp (migrate-on-touch, per change)**: once consent is established for a change, read its `.openspec.yaml`; if it lacks `schema_version`, stamp `consent_era_from: <current UTC timestamp, YYYY-MM-DDTHH:MM:SSZ>` (add-only) before proceeding with that change.

**Sync inheritance (no double-prompt)**: each inner sync-specs step (Step 8a) inherits its containing archive's consent — it never fires a separate consent prompt.

## PR layer: bulk-archive runs NO tail (D-arc Stage D6)

Bulk-archive archives SEVERAL changes in one invocation, and the PR-attached tail is
inherently SINGLE-BRANCH: HEAD can be on only one branch, so under `pr: per-proposal` — where
every attached change has its own — the tail's HEAD precondition would skip all but at most
one change, and WHICH one would depend on the incidental fact of where the user was standing.
Rather than let outward behavior fall out of that accident, this flow performs no tail at all.

Each change is synced, moved, and emitted exactly as pre-capability. NO commit, push,
description rewrite, or READY flip occurs for any change in the batch, whatever `pr:` reads.
The per-change consent preview accordingly OMITS the outward-writes line (there are none to
preview).

The **Bulk Archive Complete** readout SHALL NAME the PR-attached changes it left DRAFT, with
their PR URLs, so a batch never silently strands a pull request — reporting, never acting, per
`orbit-conventions`' residual outward-actions rule. Resolve each change's attachment from its
own trail: read `pr_attachment` from the LATEST attachment-bearing
PROPOSE or FF emit on that change's trail (read-only — no `gh` query, since the bulk flow
performs no remote work); report its `url` when present, and `attached, no PR recorded`
when the record lacks one; a change with no attachment at all is not named (it never had a
PR). Single-change `/orbit:archive` is the seam that flips.

## Per-change user-validation closure (rc10 — NEW step inside upstream Step 8)

(Per `orbit-archive-modifications`' `User-validation closure at the archive seam`)

For EACH confirmed change, before its fingerprint check, its Step 8a sync and its Step 8b move, run `orbit-archive-change`'s Step 3.2 for that change: dispose of every unchecked `(User-validation` task in its `tasks.md` as OBSERVED (check the box with a one-line evidence note) or DEFERRED (compose a `deferred_validations` entry `{task, why, when, where}` for that change's own archive run summary), and check each case of the production below — a CHECKED MIRROR of the owner's fence — against the composed deferrals. A marked task with no id, in no group, or with an id another task line carries (cases 2, 3 and 8), or an unreadable `tasks.md`, is reported to the user, who repairs it or skips that change (record it as Skipped in the Step 9 summary) without stopping the rest of the batch.

```
DEFERRAL REFUSALS — the archive write gate refuses each, naming the task or line, and Step 3.2 checks each before the move:
1 an unchecked task carrying the (User-validation marker, with no deferral naming it
2 a marked unchecked task with no task id, which no deferral can key
3 a marked unchecked line the reader places in no ## task group, found by a fence-aware line scan the reader's set lacks
4 a deferral naming a checked task, an unchecked task without the marker, or no task
5 a second deferral naming one task
6 a deferral whose why, when or where is missing, not a string, or empty
7 a deferral carrying a key other than task, why, when and where
8 a marked unchecked task whose task id another task line also carries, checked or not, naming both lines
A missing tasks.md is an empty marked set; any other failure to read it is refused, naming the error. An empty deferred_validations array is accepted and written as absent.
```

BRIEF that change's dispositions in chat right there, BEFORE its sync and move — one line per task: the change, the task id, OBSERVED or DEFERRED and, for a deferral, its `why` — so a weak `why` reaches the user while the change is still active, and repeat them in the Step 9 **Bulk Archive Complete** summary. The brief reports; it does not prompt (halting that change stays the user's, by stopping the batch).

## Per-change archive emit (rc10 — NEW step inside upstream Step 8, after 8b)

After each change's Step 8b move, write that change's archive run summary exactly as `orbit-archive-change`'s Step 5.5 does — compose the payload its `references/archive-summary-schema.md` lists, carrying this change's `consent`, its fingerprint fields when its check produced any, and its Step 3.2 `deferred_validations` — and invoke:

```bash
orbit emit archive --change <name> --payload <payload-file>
```

The engine resolves the change's archived directory itself. Each emit is checked by the same write gate as a single archive's; a refusal after the move is repaired by re-running that change's `orbit emit archive`, never by repeating its sync or move.

## Per-change base-fingerprint check (C2 — NEW step inside upstream Step 8)

(Per `orbit-base-fingerprints` and `orbit-archive-modifications`' `Fingerprint-divergence inflection prompt` requirement)

For EACH confirmed change, immediately before its Step 8a sync and Step 8b move, run:

```bash
orbit fingerprint "<name>" --check --json
```

This check is the bulk path's ONLY guard layer — Step 8 applies deltas agent-driven and moves
with `mv`, so the engine guard inside the `orbit archive` CLI never runs here. Branch per
change on the `status` values, exactly as `orbit-archive-change`'s Step 3.45 defines:

- **any `diverged`** → fire the divergence inflection prompt (reconcile / proceed-anyway /
  abort) for THAT change, showing what the sync would overwrite. Reconcile or abort skips that
  change (record as Skipped in the Step 9 summary) without stopping the rest of the batch;
  proceed-anyway records `fingerprint_overridden: [{capability, requirement, base_hash,
  live_hash}]` in that change's own archive run summary.
- **`unverified` present, none `diverged`** → prompt proceed/abort for that change; proceeding
  records `fingerprints_unverified` in its run summary.
- **all `verified`** → proceed silently.
- **any `missing`** → surface with the diverged prompt if one fires; otherwise skip the change
  with the check output shown (its sync would fail regardless).

NOTE this interacts with Step 5's conflict resolution: when two selected changes touch the same
requirement, the FIRST one's sync changes the baseline, so the SECOND one's check will report
`diverged` by design — that per-change prompt (showing exactly what the second sync would
overwrite) supersedes Step 5c's "newer overwrites" heuristic. Do not proceed past it without the
user's explicit choice, and record the per-change outcome in the Step 9 summary table.

## Scope: does NOT emit run-summary JSON

(Per `orbit-run-summary-emit` capability)

`/orbit:bulk-archive` is a wrapper around `/orbit:archive`; each archived change gets its own `archive-<TS>.json`, written by the per-change archive emit step above per the universal-spine convention. The outer `/orbit:bulk-archive` wrapper adds NO additional "what's next" signal and SHALL NOT emit a separate `bulk-archive-<TS>.json`.

Downstream consumers see N `archive-<TS>.json` files (one per inner archive) and read each independently.
