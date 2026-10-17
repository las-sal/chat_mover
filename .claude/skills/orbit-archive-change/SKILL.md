---
name: orbit-archive-change
description: Archive a completed change in the experimental workflow. Use when the user wants to finalize and archive a change after implementation is complete.
license: MIT
compatibility: Requires orbit CLI.
metadata:
  author: openspec
  version: "1.0"
  generatedBy: "2.0.1"
---

Archive a completed change in the experimental workflow.

**Input**: Optionally specify a change name. If omitted, check if it can be inferred from conversation context. If vague or ambiguous you MUST prompt for available changes.

**Steps**

1. **If no change name provided, prompt for selection**

   Run `orbit list --json` to get available changes. Use the **AskUserQuestion tool** to let the user select.

   Show only active changes (not already archived).
   Include the schema used for each change if available.

   **IMPORTANT**: Do NOT guess or auto-select a change. Always let the user choose.

2. **Check artifact completion status**

   Run `orbit status --change "<name>" --json` to check artifact completion.

   Parse the JSON to understand:
   - `schemaName`: The workflow being used
   - `artifacts`: List of artifacts with their status (`done` or other)

   **If any artifacts are not `done`:**
   - Display warning listing incomplete artifacts
   - Use **AskUserQuestion tool** to confirm user wants to proceed
   - Proceed if user confirms

3. **Check task completion status**

   Read the tasks file (typically `tasks.md`) to check for incomplete tasks.

   Count tasks marked with `- [ ]` (incomplete) vs `- [x]` (complete). Exclude every unchecked task carrying the `(User-validation` marker from the count — Step 3.2 owns those (orbit named edit, per `orbit-archive-modifications`' `User-validation closure at the archive seam`).

   **If incomplete tasks found:**
   - Display warning showing count of incomplete tasks
   - Use **AskUserQuestion tool** to confirm user wants to proceed
   - Proceed if user confirms

   **If no tasks file exists:** Proceed without task-related warning.

4. **Assess delta spec sync state**

   Check for delta specs at `orbit/changes/<name>/specs/`. If none exist, proceed without sync prompt.

   **If delta specs exist:**
   - Compare each delta spec with its corresponding main spec at `orbit/specs/<capability>/spec.md`
   - Determine what changes would be applied (adds, modifications, removals, renames)
   - Show a combined summary before prompting

   **Prompt options:**
   - If changes needed: "Sync now (recommended)", "Archive without syncing"
   - If already synced: "Archive now", "Sync anyway", "Cancel"

   If user chooses sync, use Task tool (subagent_type: "general-purpose", prompt: "Use Skill tool to invoke orbit-sync-specs for change '<name>'. Delta spec analysis: <include the analyzed delta spec summary>"). Proceed to archive regardless of choice.

5. **Perform the archive**

   Create the archive directory if it doesn't exist:
   ```bash
   mkdir -p orbit/changes/archive
   ```

   Generate target name using current date: `YYYY-MM-DD-<change-name>`

   **Check if target already exists:**
   - If yes: Fail with error, suggest renaming existing archive or using different date
   - If no: Move the change directory to archive

   ```bash
   mv orbit/changes/<name> orbit/changes/archive/YYYY-MM-DD-<name>
   ```

6. **Display summary**

   Show archive completion summary including:
   - Change name
   - Schema that was used
   - Archive location
   - Whether specs were synced (if applicable)
   - Note about any warnings (incomplete artifacts/tasks)
   - One line per Step 3.2 deferral (orbit, rc10): `deferred: <task> — <why>; when <when>, where <where>`

**Output On Success**

```
## Archive Complete

**Change:** <change-name>
**Schema:** <schema-name>
**Archived to:** orbit/changes/archive/YYYY-MM-DD-<name>/
**Specs:** ✓ Synced to main specs (or "No delta specs" or "Sync skipped")

All artifacts complete. All tasks complete.
```

**Guardrails**
- Always prompt for change selection if not provided
- Use artifact graph (orbit status --change <name> --json) for completion checking
- Don't block archive on warnings - just inform and confirm
- Preserve .openspec.yaml when moving to archive (it moves with the directory)
- Show clear summary of what happened
- If sync is requested, use orbit-sync-specs approach (agent-driven)
- If delta specs exist, always run the sync assessment and show the combined summary before prompting

---

# Orbit additions

The sections below describe orbit-specific additions on top of upstream's archive flow. The upstream content above is as `orbit-conventions`' `Generated-file disposition` records it. Orbit adds a **consent check at entry** (D1), a **pre-archive `audit-drift` sweep**, a `--skip-audit` opt-out, an **unresolved `@review:` marker warning**, a **user-validation closure** (rc10), a **base-fingerprint divergence check** (C2), an **archive run summary** written to `.orbit-runs/`, and a small set of edge-case behaviors.

## Four execution disciplines (epitome)

The four disciplines from `orbit-conventions`, embedded per body; detail lives in the step where each fires.

- **Read-before-reference (authoring-time)**: the run summary cites audit findings, the user decision, and sync-specs results — read the actual outputs before composing it; false claims corrupt the archived trail.
- **Change completeness (modification-time)**: the flow moves the change dir, writes baseline via sync-specs, and emits the summary — sweep after each step so no dangling baseline references or unreflected deltas survive.
- **Pushback (review-time)**: second-pass-verify each pre-archive audit finding against current session state; stale findings get a note in the summary, not a re-prompt.
- **No-chaining (turn boundary)**: invoke only the orbit workflow commands the user's message explicitly requests; completing a command ENDS the turn at the position readout + the engine's eligibility line — gate `passed` means *eligible*, not *commanded*.

## NEW Step 0 — Consent at entry (provenance rule, per `orbit-lifecycle-consent`)

BEFORE any other step — before the Step 1.5 marker scan, the Step 3.4 gate prompt, and every write. Archive is a consent-scoped command (the `review-system` gate carries `consent: user-invoked`); consent asks "should we be here at all", the anomaly prompts (gate, fingerprint, audit) ask "is the state sound".

**Ordering invariant**: provenance is CLASSIFIED at entry (a fact about the triggering turn); the consent prompt itself — and the era stamp below — fire AFTER read-only discovery (change selection; the read-only look at `orbit/changes/<name>/specs/` that supplies the write preview) and BEFORE any write or anomaly prompt. Read-only steps never require consent; writes always follow it.

Determine invocation provenance — an observable transcript fact, never a judgment of delegated intent:

- **User-invoked**: the triggering turn contains an explicit user invocation — the typed `/orbit:archive` command, or an unambiguous same-turn prose request naming the act ("archive it"). Proceed with ZERO added prompts (only the anomaly prompts may interrupt); the run summary records `consent: "user-invoked"`.
- **AI-mediated**: everything else — delegation phrases ("finish the cadence"), inference ("continue"), a handoff document, or an eligibility readout pointing here. Fire a consent **AskUserQuestion** BEFORE any of the command's writes: the position readout, what the archive will write (N deltas across M capabilities synced to baseline + the change moved to archive — from a read-only look at `orbit/changes/<name>/specs/`), and exactly two options — **Proceed** / **Abort**. When the change is PR-ATTACHED (D6 — resolve this from the change's trail as part of the same read-only discovery), the preview ADDITIONALLY names the tail's OUTWARD writes: the branch the archive commit lands on, the PUSH to the resolved remote, and — for a per-proposal PR — the READY FLIP, or for a program PR the APPENDED stage entry. This is required precisely because the tail rides this same entry consent and fires no second prompt: a preview enumerating only in-repo writes would obtain consent for a spec sync and a directory move, then push to a remote and flip a pull request public. The outward line is OMITTED for unattached changes, so the pre-capability prompt is unchanged wherever no PR exists — and it is likewise omitted under `/orbit:bulk-archive`, which runs no tail. Proceed records `consent: "prompted"` in the run summary; **Abort leaves no baseline write, no sync, no move, and no run summary**.
- **When provenance is uncertain, treat the arrival as AI-mediated** — erring toward one extra click, never toward a silent proceed.

**Consent-era stamp (migrate-on-touch)**: once consent is established (user-typed provenance, or Proceed at the prompt), read the change's `.openspec.yaml`. If it lacks `schema_version`, stamp `consent_era_from: <current UTC timestamp, YYYY-MM-DDTHH:MM:SSZ>` into it (add-only; never overwrite an existing stamp) — this marks a pre-capability change as tripwire-covered from this touch onward.

**Sync inheritance (no double-prompt)**: the sync-specs step this flow invokes (upstream Step 4) inherits THIS flow's consent — it never fires a separate consent prompt.

## NEW Step 0.7 — PR-attachment entry observation (READ-ONLY, every provenance path — D-arc Stage D6)

Before ANY archive write — before upstream Step 1, before sync (Step 4) and the move (Step 5)
— resolve whether this change is PR-ATTACHED: read `pr_attachment` from the LATEST
attachment-bearing PROPOSE or FF emit on the change's trail (the same read the consent
preview in Step 0 uses on the AI-mediated path; Step 4.9's `orbit pr preflight` reads the same record). This
step mutates nothing and runs on EVERY provenance path, user-typed included. When attached,
compare HEAD's branch (`git branch --show-current`) with `pr_attachment.branch`. On mismatch,
SAY SO NOW — in the consent preview when one fires, otherwise as one line before Step 1 —
naming both branches and the case-specific switch (`git switch <branch>` locally; the
tracking form when only the remote has it). The tail's HEAD precondition (in the reference)
remains the GUARD that skips the PR half; this observation is the early warning that lets the
user switch first instead of carrying uncommitted sync, move, and emit writes across a
`git switch` afterward. Unattached changes see nothing here.

## NEW Step 1.5 — Unresolved `@review:` marker warning

After upstream Step 1 (selection) but before Step 2 (artifact completion check):

Grep the change directory for `@review:` markers:

```bash
grep -rn "@review:" orbit/changes/<change-name>/
```

If any markers are found, warn:

```
N unaddressed `@review:` markers will land in archive — convert to `@todo:` or address before archiving?
```

Prompt via `AskUserQuestion`:

- **Address now** — halt the archive; user runs `/orbit:address-reviews orbit/changes/<change-name>/` to resolve before re-invoking.
- **Convert to `@todo:`** — run a bulk transform replacing each `@review:` with `@todo:` in place (preserves the content as known follow-up rather than unresolved review).
- **Proceed** — archive with the markers in place; record this decision in the archive run summary.

If no markers, proceed without prompting.

## NEW Step 3.2 — User-validation closure (rc10)

After upstream Step 3 (task-completion check) and BEFORE the Step 3.4 gate prompt — so the brief informs the gate decision, and so every predictable refusal surfaces while the change is still active. The rule is `orbit-archive-modifications`' `User-validation closure at the archive seam`; this step carries it out.

Find every unchecked task in `tasks.md` whose line carries the `(User-validation` marker — whether or not an apply emit declared it — and dispose of EACH as exactly one of:

- **OBSERVED** — the validation has happened (during the change's own cycle, or here). Check the box and append to the task line a one-line note naming the evidence (an emit token, a commit, what was seen). No deferral entry.
- **DEFERRED** — the validation was not observed at this seam: it can happen only after the change ships (a merge, a later stage, a later session), OR it could have happened and has not. The box stays unchecked; compose a `deferred_validations` entry `{task, why, when, where}` for the Step 5.5 payload — `why` saying honestly which case it is. A task whose assertion is about state that exists only AFTER this step — the baseline after sync, the archived directory, or the archive emit — is DEFERRED here: this step precedes the sync and the move.

Then check every case of the production below against `tasks.md` and the composed deferrals. A marked task with no id, in no `## ` group, or with an id another task line carries (cases 2, 3 and 8), or a `tasks.md` that cannot be read, is REPORTED to the user, who repairs `tasks.md` before the archive proceeds, or aborts; fix any other case in the composed deferrals yourself. This is a CHECKED MIRROR of the production `orbit-archive-modifications`' `User-validation closure at the archive seam` states once — no engine surface runs the write gate before the move, so the step carries the production itself:

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

**BRIEF the user before the move** — in chat, one line per task: its id, its disposition and, for a deferral, its `why` (and `when`/`where`). The brief is a REPORT, not a prompt: it asks nothing, and halting stays the user's, by aborting. When no marked task is unchecked, the step says nothing.

**Recovery after the move**: if `orbit emit archive` still refuses at Step 5.5, repair the payload and re-run the emit against the archived directory — NEVER repeat the sync or the move.

## NEW Step 3.4 — Gate inflection prompt (C1; every reviewed gate since rc10)

After Step 3.2 but before the audit sweep (Step 3.5) — the gate prompt fires FIRST among the anomaly prompts per the gated-phase contract:

Query `orbit status --change "<change-name>" --json` (there is NO `orbit instructions archive` phase — the archive workflow sources gate state from `status`) and read EVERY `gates[]` row whose `kind` is `reviewed`. LIST each one whose `state` is not `passed` and whose `superseded` field is not `true` — the gate set at archive is `orbit-engine-gates`' `Inflection-prompt override contract`'s, which this body points at rather than restates. When at least one gate is listed, fire ONE inflection prompt via **AskUserQuestion** showing each listed gate with its `state` and `reason` (its `independentSpend` MAY be shown; it never decides whether a gate is listed) and the top-level `next_command`:

- **Address the gate** — halt; run the canonical `next_command` the CLI returned — its CLASS depends on the schema's cadence, so it is read rather than predicted.
- **Proceed anyway** — continue the archive; record the decision in the archive run summary as the `continuation` entries described below (captured at decision time), ONE PER LISTED GATE.
  **THE CONTINUATION RECORD (rc04a; the SOLE record as of rc04c).** This seam — not apply's — is where the proceed-anyway decision is most often taken. For EACH listed gate, compose a `judgements` entry `{kind: "continuation", disposition: "proceed", gate: <id>, gate_state: <state>, gate_reason: <reason>}` carrying that gate's state and reason AS THE CLI REPORTED THEM at decision time, with `formed_against` naming the independent pass tokens the decision was taken knowing about and `reasoning` saying why proceeding was right anyway. **CAPTURE THE TOKENS NOW, HERE, BEFORE THE MOVE** — carry them forward to Step 5.5, where the change directory no longer exists under its active path. **If the trail carries NO independent pass earlier than this emit, the entry IS STILL WRITTEN, with `formed_against: []`.** The emptiness is legal precisely when it is true of the trail — the write gate reads the trail and REFUSES an empty citation, naming the latest preceding pass, when one exists — so the decision is recorded rather than lost, and inventing a token is refused. The token source is the TRAIL ITSELF, not `orbit status`: the change-tier status payload reports gate spend COUNTS and reason strings, never pass tokens. List `orbit/changes/<change-name>/.orbit-runs/` and take the `<TS>` of each `review-<mode>-<TS>.json` whose `reviewer_class` is `fresh` or `external`, plus each `external-<mode>-<TS>.md` the trail reader ACCEPTED as a pass — a return the gate's `reason` names as REJECTED is not citable, and enumerating filenames alone over-counts by exactly those. Which passes count is `orbit-run-summary-emit`'s rule (the trail reader's pass set); this body names it and does not restate it — the write gate enforces it and names the pass it refuses on.
- **Abort** — cancel the archive; no move, no sync-specs, no summary.

The gate NEVER hard-blocks (apply-parity): the engine reports, the skill prompts, the user decides, the trail records. When no gate is listed (every reviewed gate passed or superseded, or the schema declares none), proceed without prompting. This gate prompt is DISTINCT from the Step 0 consent prompt (consent asks "should we be here at all"; this asks "is the state sound"), the fingerprint prompt (Step 3.45), and the audit-drift prompt (Step 3.5); a single invocation MAY fire consent first and the anomaly prompts after (gate, then fingerprints, then audit).

## NEW Step 3.45 — Base-fingerprint divergence check (C2)

After the Step 3.4 gate prompt resolves but before the Step 3.5 audit sweep. **This check is the
workflow path's ONLY guard layer**: this flow applies deltas agent-driven (sync-specs at Step 4)
and moves with `mv` (Step 5), so the engine guard inside the `orbit archive` CLI never runs
here (per `orbit-base-fingerprints`' two-layer coverage model).

Run:

```bash
orbit fingerprint "<change-name>" --check --json
```

and branch on the per-requirement `status` values:

| Check state | Action |
|---|---|
| any `diverged` | Fire the divergence inflection prompt (below). |
| `unverified` present, none `diverged` | Prompt via `AskUserQuestion`: proceed / abort — "can't verify — no base recorded" (hand-authored or pre-C2 delta). Proceeding records `fingerprints_unverified: [{capability, requirement}]` in the run summary. |
| all `verified` (or the change touches no existing requirements) | Proceed silently; no prompt, no summary fields. |
| any `missing` | The touched requirement no longer exists in baseline (a sibling renamed/removed it). Include it in the divergence prompt if one fires; otherwise halt and show the check output — the sync would fail on it regardless. |

### Divergence inflection prompt (`AskUserQuestion`)

Present each diverged requirement (capability / requirement / `base_hash` → `live_hash`) plus
the divergence detail: read the LIVE requirement block from `orbit/specs/<capability>/spec.md`
and the delta's MODIFIED block, and show what the sync would overwrite — content present live but
absent from the delta is exactly what would be destroyed. When `unverified` requirements exist
alongside diverged ones, list them too (proceeding records both summary fields). Exactly three
options:

- **Reconcile** — halt the archive. Print the guided-manual instructions IN THIS ORDER: (1)
  hand-edit the delta spec(s) under `orbit/changes/<name>/specs/` to incorporate the divergent
  live content shown; (2) re-stamp via `orbit fingerprint <name> --refresh`. Then re-invoke
  `/orbit:archive`. (A refresh WITHOUT the edit re-opens the loss hole — an accepted,
  deliberate-only Phase-0 footgun; the Phase-1 3-way merge removes it.)
- **Proceed anyway** — continue the archive flow past the check (no CLI flag is involved on this
  agent-driven path; `--override-fingerprints` is the equivalent for CLI-direct `orbit archive`
  runs). Record `fingerprint_overridden: [{capability, requirement, base_hash, live_hash}]` in
  the archive run summary, captured at decision time.
- **Abort** — cancel the archive; no move, no sync-specs, no summary.

This prompt is DISTINCT from the Step 3.4 gate prompt and the Step 3.5 audit prompt.

## NEW Step 3.5 — Pre-archive audit-drift sweep

After upstream Step 3 (task-completion check) but before Step 4 (sync-specs):

**Unless `--skip-audit` is set**, invoke `/orbit:audit-drift` as a library function with context `pre-archive` and the current change name. Wait for the findings.

### Branching on audit findings

| Audit state | Action |
|---|---|
| **≥1 CRITICAL findings** | Prompt user via `AskUserQuestion`: "Address now / Proceed with archive / Abort?" Show the full audit findings to inform the choice. |
| **No CRITICAL, only WARNING/SUGGESTION** | Proceed without prompting; warnings logged in the archive run summary. |
| **No findings** | Proceed without prompting; clean audit recorded in summary. |
| **Audit failed to run** (parse error, internal exception) | Proceed with a warning. Archive run summary records `audit.ran: false` with the failure reason. Do NOT block on audit-tool failures. |

### Prompt outcomes (for the ≥1 CRITICAL case)

- **Address now** → archive does not proceed. User fixes the drift issues and re-invokes `/orbit:archive`. No summary written this run.
- **Proceed with archive** → archive proceeds normally. Summary records `user_decision: proceeded_despite_critical`.
- **Abort** → archive is cancelled. No move, no sync-specs, no summary.

### `--skip-audit` flag

When `/orbit:archive --skip-audit <name>` is invoked, the entire Step 3.5 audit is skipped. The archive run summary records `audit_skipped_via_flag: true`. Use case: the user has just run `/orbit:audit-drift` manually and doesn't need to repeat it.

## NEW Step 4.9 — PR preflight (`orbit pr preflight`, READ-ONLY, BEFORE the move — D-arc Stage D6; moved before the move by rc12)

After the sync (upstream Step 4) and BEFORE upstream Step 5's move, while the change is still
active (after the move the call is a usage error):

```bash
orbit pr preflight <name> --json
```

It mutates nothing. `off` means the change is UNATTACHED: no tail runs at Step 5.6 and the
archive ends exactly as pre-capability; when the `pr` regime read from `orbit status --json`
is active, write ONE line noting the unattached state (`/orbit:new` + `/orbit:continue`
changes never attach). Anything else loads `references/pr-archive-tail.md`, and its record
is carried forward: `observations.emit` supplies the Step 5.5 emit's `pr_url`/`pr_state`,
and `observations.outcome` is Step 5.6's `--outcome`, so the emit and the tail act on ONE
observation. Nothing it observes is changed by the move. A non-zero exit is a usage error:
report it verbatim, and the archive continues unattached.

(The HEAD-vs-attachment observation already fired at Step 0.7, before any archive write; the
tail re-checks HEAD immediately before staging as its guard.)

## NEW Step 5.5 — Archive run summary

After upstream Step 5 (move-to-archive) completes, compose the payload — narrative + the extension fields `references/archive-summary-schema.md` lists (`archive_path`, `audit`, `sync_specs`, `unresolved_markers`, `user_decision`, `consent`, `warnings`, plus Step 3.2's `deferred_validations` when it deferred any task) — write it to a temp file, and invoke:

**COMPOSE THE READINESS RECORD (rc04a).** When this archive CONCLUDES A REVIEW CADENCE — readable as the change's trail carrying independent passes — the payload SHALL carry a `judgements` entry with `kind: "readiness"`. Its `formed_against` is those passes' `<TS>` tokens; its `disposition` is your own judgement; its `accepted` list is where RESIDUAL RISK goes, one `{claim, why}` pair each. Where Step 3.4 fired **Proceed anyway**, its `continuation` entries sit in the SAME array — the archive is the one emit admitting both kinds, which is why the carrier is an array.

The token source is the TRAIL ITSELF, not `orbit status`: the change-tier status payload reports gate spend COUNTS and reason strings, never pass tokens. List `<archive_path>/.orbit-runs/` and take the `<TS>` of each `review-<mode>-<TS>.json` whose `reviewer_class` is `fresh` or `external`, plus each `external-<mode>-<TS>.md` the trail reader ACCEPTED as a pass — a return the gate's `reason` names as REJECTED is not citable, and enumerating filenames alone over-counts by exactly those. Which passes count is `orbit-run-summary-emit`'s rule (the trail reader's pass set); this body names it and does not restate it — the write gate enforces it and names the pass it refuses on. The trail MOVED with the change at Step 5, so the ACTIVE path no longer resolves and `orbit status --change <name> --json` now errors — read the archived directory, or reuse the tokens Step 3.4 captured before the move.

A `disposition: "not-ready"` is an ARCHIVE-TIME DISSENT, not a routing decision: it says the work was archived against your own judgement, and `ratified_by` records honestly whether that belief was yours (`ai`) or the user's (`user`). It does NOT block — the seam already carries consent, gate and audit prompts for stopping — and Step 5.65 states it where a human is looking. (Routing a cadence back to architecture instead of archiving is a real judgement with no carrier here, deliberately: the archive readout is this record's only reader, and in the routing case there is no archive to read it.)

**`accepted` versus `warnings`, and the test that separates them**: a residual formed AGAINST the independent passes is an `accepted` pair; something that arose at the SEAM ITSELF and was formed against no pass — a divergence observed at archive, a correction made in flow — stays a `warnings` entry. The test is whether independent review output informed it, which is also what makes the ordering check possible; a `warnings` entry cites nothing and can be ordered against nothing. Writing a pass-formed residual into `warnings` is the practice this record replaces.

```bash
orbit emit archive --change <name> --payload <payload-file>
```

The ENGINE resolves the post-move landing itself (the lexically-greatest `orbit/changes/archive/*-<name>/` scan) and owns the spine, filename, and collision handling — never hand-compose the JSON or the path.

## NEW Step 5.6 — The PR-attached tail (AFTER the emit, BEFORE the completion readout — D-arc Stage D6)

Runs ONLY when Step 4.9's preflight was not `off`. Follow `references/pr-archive-tail.md`:

```bash
orbit pr tail <name> --outcome <outcome> --include <path> --json
```

with the preflight's `observations.outcome` verbatim and one `--include` per at-archive
edit; then run its segment (commit → push → description rewrite or stage-entry append → the
READY flip for a per-change PR), authoring the commit message and the body it asks for.

The tail's outward writes ride the archive's OWN entry consent — no second prompt. A failed
step stops the segment with ONE line naming the completed, the failed and the skipped steps, the
failed step's argv and then each skipped step's shown as the recovery. The archive itself (sync, move, emit) has already
succeeded and never rolls back.

## NEW Step 5.65 — The readiness line in the completion readout (rc04a)

When the archive emit carried a `readiness` entry with `disposition: "not-ready"`, the completion readout SHALL state it in ONE line, naming the record AND RENDERING `ratified_by`, because that field says WHOSE dissent it was and a line that presupposes one value misreports the other: `readiness: NOT READY — archived against this session's own judgement; see archive-<TS>.json` when `ratified_by` is `ai`, and `readiness: NOT READY — archived against the user's ratified judgement; see archive-<TS>.json` when it is `user`. A `ready` disposition renders NOTHING: the ordinary case needs no announcement, and a readout that speaks on every archive teaches readers to skip it.

This line is the record's READER, and it is not decoration. A judgement record that no surface consumes would repeat exactly the defect this program already found in the RETIRED field this record superseded — written by every body, read by nothing — inside the change that exists to fix it. A change archived against the author's own judgement should say so where a human is looking, not only inside a JSON field.

## NEW Step 5.7 — Stage-line garnish in the completion readout (D-arc Stage D2)

When the archived change's metadata carries an `architecture: {doc, stage}` citation, the "Archive Complete" readout gains ONE stage line: after the move, run `orbit architecture status --json` and render the cited stage's post-archive computed position (e.g. `stage d2-architect: now quiescent — completion is yours to ratify`). One line riding the existing position render — no prompt, no doc edit; ratification never happens here (D-d2-4). Uncited changes see no stage line.

## NEW Step 5.8 — Residual outward-actions echo (per `orbit-conventions`)

When the flow hands control back at an OUTWARD seam, the completion readout shows the acts that
stay the human's. After a per-change tail, show each of `orbit pr tail`'s `human_acts`
argv verbatim, labelled as the user's own: the merge, then the return to the default branch
after it. Run none of them. After a program-PR append: the program PR is named and the flip
stays at arc-done. After a tail whose PR half was SKIPPED on positive invalidation (the commit
and push landed; the rewrite/append and flip did not): name the specific reason and that any
action on that pull request is the user's. No echo fires for an unattached change — there is
no outward seam to hand back at.

## `.orbit-runs/` moves with the change

Upstream Step 5's `mv orbit/changes/<name> orbit/changes/archive/YYYY-MM-DD-<name>` already moves the entire change directory, including `.orbit-runs/`. No additional handling required — `.orbit-runs/` is just a subdirectory of the change.

All prior internal-run summaries (`review-*-*.json`, `audit-drift-*.json`, `address-reviews-*.json`) and external-review findings (`external-*.md` + `external-prompt-*-*.md`) persist in the archived location at `orbit/changes/archive/<YYYY-MM-DD>-<change-name>/.orbit-runs/`.

## Edge cases

### Already archived

If `orbit/changes/archive/<YYYY-MM-DD>-<change-name>/` already exists when the user invokes `/orbit:archive <change-name>` (i.e., a same-day prior archive for the same change name):

Halt with a clear error:

```
Change <name> is already at orbit/changes/archive/<YYYY-MM-DD>-<name>/.
```

Do NOT prompt to overwrite; the user must explicitly resolve the conflict (rename existing archive, use different date, etc.).

### audit-drift fails to run

Already covered in Step 3.5 — proceed with warning; summary records `audit.ran: false` + failure reason. Do NOT block on audit-tool failures.

## Audit is informational, not gate

Audit-drift findings are **informational** unless the user explicitly chooses to abort. The archive command does NOT:

- Attempt to resolve audit findings automatically (user's responsibility via `/orbit:address-reviews` or manual edit).
- Auto-invoke `/orbit:review --as system` even if it hasn't run for this change. System-mode review is the user's gate — their responsibility to run it before archiving if they want that signal.

This is a deliberate choice (per `orbit-archive-modifications`' `Audit informational, not blocking by default` requirement): users may legitimately archive with known drift (e.g., follow-up commit planned). orbit captures the decision in the summary for traceability, but doesn't override.
