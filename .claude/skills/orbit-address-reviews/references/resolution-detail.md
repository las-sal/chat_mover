# Reference: resolution detail — discovery, batch triggers, fork detection, worked examples, degradation

Moved from the body verbatim (D5 body-economy pass). The body carries the compact protocol; this file carries the full rules, tables, examples, and error shapes.

## Scope resolution and discovery (Step 1 detail)

**Positional `<scope>` argument** — resolve in this order:

1. **Active change**: `orbit/changes/<scope>/` exists → treat `<scope>` as a change name; the marker grep is restricted to that directory, and trail discovery applies (the body's DISCOVERY rows 4 and 5).
2. **Archived change**: no active match, but `orbit/changes/archive/` contains one or more entries matching the regex `^\d{4}-\d{2}-\d{2}-<scope>$` → treat as a change name resolving to the archive directory. If multiple archive entries match the same `<scope>` suffix (rare; same change name archived on different dates), the lexicographically-latest date wins (most-recent archive). Its markers and its unwalked audit-drift emits are discovered (row 6); `orbit status` cannot address an archived change, so its review passes are reached by `--from-file`, and the triage header says so.
3. **Path/pattern fallback**: no active or archive match → treat as a path/pattern scope; grep restricted to that path; no trail is read (row 7).

**Discovery is the DISCOVERY fence in the body's Step 1**, a checked mirror of `orbit-address-reviews`' `Address-reviews command available`; this file does not restate it. The outstanding passes come from the engine's `unresolvedPasses` and `unwalkedPasses` on each reviewed gate's status row, so the walk and the gate read one list. The single-newest-by-`<TS>` rule that this section used to carry is retired: it walked one pass when the gate held two, and it never reached an external return.

**Each discovered source is fed to the `--from-file` ingest path** (content-sniff routes JSON to the parser per `references/internal-findings-format.md` and `# External Review:` markdown per `references/external-findings-format.md`; identical lifecycle and virtual-marker construction to an explicit `--from-file` invocation). The only difference is the log's provenance fields (`source: "auto-discovered"` — see the schema reference).

**`--mark` is optional, not prerequisite**: historically, `/orbit:review --as proposal --mark` was the way to produce markers that address-reviews would later walk. Discovery makes `--mark` purely a stylistic choice (do you want findings annotated in source for diff-readability?). A marker that restates a discovered finding is walked AS that finding, in its pass's log, so nothing is walked twice. A pass whose findings are all SUGGESTION-grade holds nothing on the gate, but it is still discovered while no walk record references it, through the gate's `unwalkedPasses`: severity ranks a finding and does not decide whether one is read.

## Batch-mode trigger table (Step 3)

| Trigger | Detection | `walk_mode_source` |
|---|---|---|
| **`--batch` flag** | Present in the invocation argv. Canonical signal. | `"flag"` |
| **Verbal `--batch` in invocation message** | The user's invocation message (the message that triggered the command) contains one of these batch-intent phrases: `"fix them all"`, `"batch them"`, `"go ahead with all"`, `"address all at once"`, or another clearly equivalent phrase conveying batch-resolution intent. The phrase MUST be in the invocation message — phrases inside subsequent walk-step responses do NOT shift mode (see next row). | `"verbal"` |
| **Mid-walk command-shape interruption** | During an active walk, the user sends a bare, unambiguous mode-switch message: `"go batch"`, `"switch to batch"`, `"batch the rest"`. The message must be command-shaped (typically 2-4 words, no conversational filler) — ambiguous phrases like `"yeah let's just keep going"` or `"fine, fix them all"` mid-walk do NOT shift mode. Record the 1-indexed finding number at which the shift occurred in the resolution log's `walk_mode_shifted_at_finding` field. | `"command-shape-interruption"` |

## Fork detection machinery, recording shape, and trace (Step 3b.5)

**Hybrid detection** (supplies the BRIEFING's option set; structured first, heuristic fallback):

1. **Structured path** — if the finding came from a JSON-virtual marker (internal-review or audit-drift JSON via `--from-file` or discovery) AND the source JSON's finding entry includes a `recommendation_options: [{label, body}]` array with ≥ 2 entries AND every entry has non-empty `label` AND non-empty `body`: use that array DIRECTLY as the briefing's options. Skip heuristic. Record `recommendation_fork.source: "structured"` in the resolution log.

2. **Heuristic fallback** — if structured path was unavailable (missing field, malformed entry — see malformed-handling below) OR the marker is markdown-sourced (external markdown, inline markers): scan the finding's recommendation text for STRICT disjunctive signals. Triggers (all are non-fuzzy):
   - **Numbered alternatives**: `(A) … (B)`, `1. … 2.`, `[A] … [B]`
   - **"Either … or …"** with clause-level branches (each clause is a recognizable recommendation)
   - **"Options:" prefix** (accepting both bold variants: `**Options**:` colon-outside-bold, `**Options:**` colon-inside-bold; normalize markdown emphasis before pattern-matching) followed by a list or numbered enumeration

   **NOT triggers** — do NOT fire on loose "or" in prose: `"fix it now or later"`, `"X or Y could happen"`, `"the issue is A or B and we should address one of them"`. False-negative bias intentional.

   On heuristic match, parse the recommendation text into options (each option becomes `{label, body}`; labels typically `"A"`, `"B"`, …). Record `recommendation_fork.source: "heuristic"` in the resolution log.

3. **No detection** — neither structured nor heuristic triggered: the finding STILL gets its full-prose briefing, with 2–4 concrete options the AI derives from context surfaced IN PROSE; resolution proceeds per the same protocol. No `recommendation_fork` object is recorded (absence IS the no-fork representation).

**Malformed structured input** (zero entries, single entry, missing `label` or empty `label`, missing `body` or empty `body`): emit a stderr warning naming the finding + reason (`"only 1 entry in array"`, `"missing label on entry index 2"`, `"empty body on entry index 0"`); FALL BACK to heuristic detection over the prose `recommendation`. Record `recommendation_fork.source: "heuristic"` AND `recommendation_fork.structured_path_skipped_reason: "<reason>"` in the resolution log. Malformed input never aborts the walk.

**Ratification recording** — EVERY decision-lane resolution records, at the ENTRY level (forked or not): `ratified_via: "chat" | "prompt"` and — when no fork was detected, or the ratified direction is off-menu — a verbatim `resolution` string. The `recommendation_fork` object (present only when detection fired) carries the DETECTION data:

```json
"ratified_via": "chat",
"resolution": "<the ratified direction verbatim — required for non-fork and off-menu cases>",
"recommendation_fork": {
  "detected": true,
  "source": "structured" | "heuristic",
  "options_presented": [{ "label": "A", "body": "..." }, { "label": "B", "body": "..." }],
  "chosen": "A" | "off-menu",
  "structured_path_skipped_reason": "<optional; only when structured was attempted then skipped>"
}
```

(The `[discuss]` escape-hatch option is RETIRED — discussion is the medium, not an escape; `discuss_invoked` is no longer emitted. Pre-D4 logs carry it; readers tolerate both generations.)

**Decision-lane behavior in batch-mode**: decision-lane findings STILL receive their per-finding briefing and ratification in batch-mode — batch never merges decisions into one prompt; it only suppresses per-finding pacing for obvious-fix and stale findings.

**Mini decision-lane trace**:

```
Walking finding W1 (WARNING, decision lane):
  Title: Test suite covers ~30 of ~45 spec scenarios
  Recommendation: "Either (A) file a follow-up issue tracking the v2 polish, or
                  (B) add Group 19 to tasks.md extending this change's scope."

Detection fired via heuristic → the BRIEFING presents both paths in prose:
  what the coverage gap means, what each option costs, which the reviewer leaned toward.

User types: "file the issue — A". That chat directive IS the ratification.
Resolution-log entry records:
  ratified_via: "chat",
  recommendation_fork: {
    detected: true, source: "heuristic",
    options_presented: [{label: "A", body: "..."}, {label: "B", body: "..."}],
    chosen: "A"
  }

(Had the discussion trailed off without a directive, an AskUserQuestion would fire
carrying the discussed conclusion as its default — and a dismissed prompt would
simply re-present the finding, losing nothing.)
```

## Worked example (`--from-file` markdown ingest, iter 5 of add-review-workflows)

```
## Address-reviews report

Source: --from-file orbit/changes/add-review-workflows/.orbit-runs/external-proposal-2026-05-18T14-35-23Z.md
External reviewer: Claude Opus 4.7 (fresh-context in-session subagent — iter 5)
Input findings: 0 CRITICAL / 4 WARNING / 5 SUGGESTION
Markers walked: 9 (all)
Walk mode: per_finding (default)
Pushback verification: all 9 verified against current state; 0 stale suppressions.
Cascade summary: 14 IN files cascaded across 9 resolutions; 3 OUT files flagged_not_applied (2 baseline specs, 1 cross-change archive ref).

### Summary

| Status        | Count |
|---------------|-------|
| ✓ Resolved    | 9     |
| ⚠ Stale       | 0     |
| ⏸ Deferred    | 0     |
| ✗ Escalated   | 0     |

### ✓ Resolved
- **proposal.md:41** — [WARNING] "five new SKILL.md + command body pairs" should be four.
  Action: trivial fix — changed "five" to "four" + added explicit list.
  Ripple: design.md, README.md flagged.

- **design.md:159** — [WARNING] "9 capability specs" should be 8 after merge.
  Action: trivial fix — changed 9 to 8 with parenthetical merge context.

- **sketches/review.md:3** — [WARNING] corrupted filenames (sed residue from rename).
  Action: trivial fix — restored proper filenames.

- (6 more, all trivial fix or applied decision)

### Final assessment

0 unresolved external findings.
Suggested next: re-run /orbit:review --as proposal to confirm convergence.

Run summary: orbit/changes/add-review-workflows/.orbit-runs/address-reviews-2026-05-18T14-43-41Z.json
```

## Worked example (`--from-file` JSON ingest, single SUGGESTION from a system-mode review)

```
## Address-reviews report

Source: --from-file orbit/changes/harden-export-validation/.orbit-runs/review-system-2026-05-26T20-01-08Z.json
Source format: internal review JSON (command: "review", mode: system, iteration: 2)
Input findings: 0 CRITICAL / 0 WARNING / 1 SUGGESTION
Markers walked: 1 (all)
Pushback verification: 1 verified against current state; 0 stale suppressions.

### Summary

| Status        | Count |
|---------------|-------|
| ✓ Resolved    | 1     |
| ⚠ Stale       | 0     |
| ⏸ Deferred    | 0     |
| ✗ Escalated   | 0     |

### ✓ Resolved
- **<skills-dir>/orbit-review/references/run-summary-schema.md:22** — [SUGGESTION] Schema reference does not document new convergence fields emitted by iteration-aware logic.
  Source: internal-review
  Action: classified as `decision required` (out-of-scope deferral vs include-in-current-change). User chose to defer to a future change; filed as task in `tasks.md` referencing the schema-doc gap; original JSON unchanged (marker-removal no-op for virtual markers).
  Ripple: orbit-review/SKILL.md flagged (consumer of the schema doc).

### Final assessment

0 unresolved findings.
Suggested next: continue with current change's archive flow; the schema-doc gap is filed as a follow-up task and will be addressed in a future change.

Run summary: orbit/changes/harden-export-validation/.orbit-runs/address-reviews-2026-05-26T20-XX-XXZ.json
```

This example demonstrates the JSON path: the input is an internal `review-system-*.json` produced by `/orbit:review --as system`; auto-detect routes to the JSON parser (leading `{`); the single `findings[]` entry becomes a virtual marker; the lifecycle walks it (pushback verifies the schema gap still exists → classify as `decision required` → user defers → file as task → marker-removal no-op since virtual). Identical lifecycle to the markdown example above, different parser routing.

## Graceful degradation

- **Nothing discovered, by any row** (a whole-repo or path scan finding no marker; or a change with no markers, every reviewed gate reporting `unresolvedPasses: []` and `unwalkedPasses: []`, every audit-drift emit already named by a log) → emit `No @review: markers and no outstanding passes in scope. Nothing to walk.`, list each audit-drift emit a log already names as `walked before; reach by --from-file <path>`, and exit clean (the DISCOVERY fence's AFTER line).
- **A half-landed pair** (a reviewed gate reports `openPair`) → NOT a degradation case: before triage the walk warns, naming the missing member and the gate's canonical next command. When the landed half is listed, it offers to stop (walk nothing, write no log, so the missing review can run) or to walk now, which ends the pair; when the landed half carries no finding, nothing can be walked to end it, so the walk names the routes that can and stops (row 4). The landed half is the pass of the class `openPair` does not name: an external return is listed with `source: "external"`, a fresh pass is an `internal-review` entry whose record's `reviewer_class` is `fresh`.
- **`--from-file` path missing** → fail clearly with usage; don't fall back to repo scan.
- **`--from-file` neither-format-detected** → emit a clean format-mismatch error naming both supported formats (referencing `references/external-findings-format.md` and `references/internal-findings-format.md`) plus the observed leading-content snippet; refuse to act on partial parse. Concrete error shape:

  ```
  `--from-file <path>`: unrecognized format.

  Supported formats:
  - External-review markdown — see references/external-findings-format.md
  - Internal review JSON (review-<mode>-*.json) — see references/internal-findings-format.md

  Detected: <observed first-line snippet>
  ```
- **`--from-file` JSON parse failure** (leading `{` but invalid JSON) → emit a clean parse-error message naming the file and the JSON parse-error position (best-effort); exit without acting. User fixes the file and re-runs.
- **`--from-file` unsupported JSON `command` field** (valid JSON but `command` is neither `"review"` nor `"audit-drift"`) → emit a clean error naming the supported values (`"review"`, `"audit-drift"`) and the unsupported value detected; reference both format docs for self-diagnosis; exit without acting. V1 supports `review-<mode>-*.json` and `audit-drift-*.json` only. `command: "address-reviews"` is rejected on purpose (cycle prevention).
- **`--from-file` markdown malformed** (leading `# External Review:` but missing required sections / broken field labels) → emit a markdown-parse-error message with format guidance from `references/external-findings-format.md`; exit without acting.
- **`--from-file` JSON missing `findings[]`** → treat as malformed input; emit a clean error naming the missing/malformed field; reference `internal-findings-format.md`; exit.
- **`--from-file` JSON with empty `findings: []`** → NOT an error. Succeed with zero virtual markers; resolution log reports a clean empty walk with note `Source JSON had no findings to walk; resolution log is informational.` A clean review with `findings: []` is the expected state for an all-clear pass.
- **No `tasks.md` in change context** → unresolvable-default-file-as-task falls back to creating a root-level `TODO.md` entry with a note.
- **Marker found in a baseline spec** (`orbit/specs/<capability>/`) → warn that this is unusual; baseline specs should not carry markers; still walk it per user choice but flag in the log.
