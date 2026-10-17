# Reference: review run-summary schema

Each `/orbit:review` invocation persists a JSON summary. The location is PER MODE (D-arc Stage D2): `orbit/changes/<change-name>/.orbit-runs/review-<mode>-<TS>.json` for `proposal` and `system` modes, and `orbit/architecture/.orbit-runs/review-architecture-<TS>.json` for `architecture` mode (the architecture trail — shared by all docs, never moved by change archiving). `<TS>` is ISO-8601 with hyphens (e.g., `review-proposal-2026-05-18T14-35-23Z.json`).

Create the trail directory if it doesn't exist. The file is **committed** (not gitignored) so iteration history travels with the change into archive (change modes) or persists in the architecture trail (architecture mode).

## Universal spine inheritance

The spine every emit carries is owned by `orbit-conventions`' `Internal-run JSON summary format` requirement, and is not restated here. For review the engine composes every spine field and the payload supplies only `model`: `final_assessment` is the DETERMINISTIC severity-counts sentence computed from the emit's own scorecard (`"X critical, Y warning, Z suggestion."` / `"No findings."`, never a verdict), and in change modes `next_recommended` is the DETERMINISTIC pointer `orbit-emit-composition`'s `Deterministic facts are engine-composed per command` composes — the change-scoped walk when the pass has findings, the report render when clean; that requirement owns the values, and this body does not restate them (the engine-computed canonical next rides the rendered tail, never the emit). `change` is `null` in architecture mode, where a `doc` field names the reviewed doc instead.

The schema below documents per-command extensions ADDED to that spine (`mode`, `iteration`, `depth`, `reviewer_class`, `flags`, `passes_run`, `passes_skipped`, `scorecard`, `findings`, `blocks`, `stale_suppressed`, `commentary`, `direction`, `verification`, and the engine-computed `pass_genre` and `verified_walks`). The former `findings_summary` and `iteration_note` fields are RETIRED in CHANGE MODES (D-arc Stage D4): `scorecard` supersedes the counts (readers tolerate both generations), and the iteration note is RENDERER-computed from the trail — a stored copy would be a second stale voice. (Architecture-mode emits carry the same `scorecard` shape; the interim hand-rendered report path documented below reads it — no render surface covers the architecture trail yet.) Per-command extensions are review-specific state; they supplement, not replace, the spine.

## Schema

```json
{
  "command": "review",
  "timestamp": "<ISO-8601>",
  "change": "<change-name>",         // null in architecture mode
  "final_assessment": "<counts sentence, e.g. "0 critical, 1 warning, 3 suggestion.">",
  "next_recommended": "<engine-composed — the pointer orbit-emit-composition's 'Deterministic facts are engine-composed per command' owns>",
  "kind": "editorial",
  "mode": "proposal" | "system" | "architecture",
  "iteration": <integer, per-mode>,
  "pass_genre": "REVIEW" | "VERIFICATION",        // engine-computed; refused in the payload
  "verified_walks": ["<address-reviews TS token>"], // engine-computed; [] on every REVIEW-genre pass
  "depth": "fast" | "full" | "thorough",
  "reviewer_class": "in-context" | "fresh" | "external",
  "flags": {
    "parallel": false,
    "focus": null,
    "strict": false,
    "fresh": false,
    "mark": false,
    "skip_verify": false
  },
  "passes_run": ["1", "2", ...],
  "passes_skipped": [],
  "scorecard": {
    "completeness": { "critical": 0, "warning": 0, "suggestion": 0 },
    "correctness": { "critical": 0, "warning": 0, "suggestion": 0 },
    "coherence": { "critical": 0, "warning": 0, "suggestion": 0 }
  },
  "findings": [
    {
      "pass": "1",
      "severity": "CRITICAL" | "WARNING" | "SUGGESTION",
      "dimension": "completeness" | "correctness" | "coherence",
      "file": "design.md",
      "line": 159,
      "title": "<finding title>",
      "recommendation": "<actionable recommendation>",
      "reproduction": "<the finding's reproduction, as orbit-conventions' Severity ladder defines one — REQUIRED non-empty on CRITICAL, optional otherwise; multi-line allowed>",
      "recommendation_options": [
        { "label": "A", "body": "<option A body>" },
        { "label": "B", "body": "<option B body>" }
      ],
      "walk_entry": { "title": "<a walk entry's title>", "file": "<its file>" }
    }
  ],
  "blocks": ["<optional: one single-line entry per lifecycle block with its location — a validate failure, an unresolved @review: marker; absent when none>"],
  "stale_suppressed": [
    {
      "pass": "<pass id>",
      "title": "<original finding title>",
      "evidence": "<grep output or commit hash showing why it's stale>"
    }
  ],
  "commentary": "<optional — the reviewer's color commentary, rendered verbatim into the report's delimited Commentary slot>",
  "direction": {
    "disposition": "forward" | "hold",
    "reasoning": "<the reviewer's forward recommendation — WHICH WAY and WHY; multi-line allowed. OWED when reviewer_class is fresh or external, optional in-context>"
  },
  "verification": [
    { "title": "<owed walk entry's title>", "file": "<its file>", "verdict": "landed" | "regressed" }
  ]
}
```

### Example payload (change modes)

A payload file the body writes for a fresh proposal-mode pass — real JSON, accepted by `orbit emit review --change <name>`, carrying no engine-owned key. It omits `verification`, which the write gate owes only on a VERIFICATION-genre pass and refuses on this one (the genre is computed from the trail; see the field note). A test submits this block, unchanged, through the write gate (`orbit-emit-composition`'s `Payload schema references are proven by execution`).

```json example change
{
  "mode": "proposal",
  "reviewer_class": "fresh",
  "depth": "full",
  "flags": { "parallel": false, "focus": null, "strict": false, "fresh": true, "mark": false, "skip_verify": false },
  "passes_run": ["1", "2", "3", "4", "5", "6", "7", "8", "9"],
  "passes_skipped": [],
  "scorecard": {
    "completeness": { "critical": 0, "warning": 1, "suggestion": 0 },
    "correctness": { "critical": 1, "warning": 0, "suggestion": 0 },
    "coherence": { "critical": 0, "warning": 0, "suggestion": 1 }
  },
  "findings": [
    {
      "pass": "4",
      "severity": "CRITICAL",
      "dimension": "correctness",
      "file": "design.md",
      "line": 40,
      "title": "Archive step deletes the staging directory before the copy is verified",
      "recommendation": "Verify the copy before deleting the source.",
      "reproduction": "Run the archive flow on a change whose copy fails (read-only target): design.md step 3 deletes orbit/changes/<name>/ before step 4 checks the copy, so the change is lost."
    },
    {
      "pass": "2",
      "severity": "WARNING",
      "dimension": "completeness",
      "file": "tasks.md",
      "line": 12,
      "title": "No task updates the generated surface after the template edit",
      "recommendation": "Add a task running orbit update --force after the template change.",
      "recommendation_options": [
        { "label": "A", "body": "Add the task to group 5." },
        { "label": "B", "body": "Fold it into task 2.3." }
      ]
    },
    {
      "pass": "7",
      "severity": "SUGGESTION",
      "dimension": "coherence",
      "file": "proposal.md",
      "line": 3,
      "title": "Why section names the capability by an older title",
      "recommendation": "Use the capability's current name."
    }
  ],
  "blocks": ["orbit validate <name> --strict fails: specs/cap/spec.md has a requirement with no scenario"],
  "stale_suppressed": [
    { "pass": "3", "title": "Touchpoints omit the parser", "evidence": "design.md:88 lists src/core/parsers/explore-rules.ts since 4f3e2d1c" }
  ],
  "commentary": "The design is sound; the one CRITICAL is an ordering slip in the archive step, not a structural problem.",
  "direction": {
    "disposition": "hold",
    "reasoning": "Walk the CRITICAL before apply: the ordering defect loses a change on the first failed copy, and the fix is one reordered step."
  },
  "model": "claude-opus-5-5"
}
```

## Field notes

- **`reviewer_class`** (C1) is the first-class execution-context field the engine's reviewed-gate convergence reads for cadence class coverage: `"fresh"` when the pass ran in a clean context (`--fresh`), else `"in-context"` (externally-sourced findings in `external-<as>-<TS>.md` are structurally `"external"`). For emits predating this field the engine infers (`flags.fresh: true` → `fresh`; `external-*.md` provenance → `external`; otherwise `in-context`), so absence never breaks gate computation.
- **`iteration`** is per-mode: proposal-mode and system-mode iterations count separately on the same change.
- **`passes_run` / `passes_skipped`** are strings (pass IDs); skip reasons go in the report body but not the summary array.
- **`scorecard`** is the REQUIRED counts shape (3 dimensions × 3 severities, non-negative integers): each cell SHALL equal the count of ACTIVE findings with that `dimension` + severity (suppressed excluded) — the renderer validates the equality and fails the render on mismatch.
- **`dimension`** on each finding names the owning scorecard cell (`completeness` | `correctness` | `coherence`).
- **`stale_suppressed`** captures findings that pushback removed; they are excluded from the scorecard and active findings, and render in the report's dedicated Suppressed section (first-class, with evidence).
- **`final_assessment` / `next_recommended`** carry the deterministic facts stated under Universal spine inheritance — no verdicts, no eligibility judgments (the engine-rendered tail owns those).
- **`commentary`** is OPTIONAL: the reviewer's voice for the report's delimited Commentary slot — the pattern behind the findings, what was probed, risk texture; NEVER finding counts, gate verdicts, or next commands (those exist only in the report's engine-computed sections).
- **`reproduction`** (rc02b) is a string on each finding — multi-line allowed, never a single-line slot — REQUIRED non-empty when `severity` is `CRITICAL` and optional otherwise, per `orbit-conventions`' Severity ladder — which also defines what a reproduction IS; this note defines nothing. `orbit emit review` REFUSES a CRITICAL without one in every mode, naming the finding, and refuses a present non-string one at any severity (per `orbit-emit-composition`); the engine checks presence, never truth — whether it reproduces is the walk's call. Prior-generation emits lack the field and remain valid; the report renders such a CRITICAL `[unreproduced]`.
- **`blocks`** (rc02b) is an OPTIONAL array of single-line strings, one per lifecycle BLOCK the pass found — a condition that must be addressed before apply and is not a severity, per `orbit-conventions`' Severity ladder (by pointer; this reference defines no block of its own) — each naming the condition and its location. Never counted in the scorecard, never a finding, never a gate input; the report renders them above the findings. The surface refuses a non-array or a multi-line entry naming `blocks[<i>]`.
- **`direction`** (rc04b) is the pass's FORWARD RECOMMENDATION, the object the block above shows: OWED when `reviewer_class` is `fresh` or `external` and OPTIONAL in-context — `orbit emit review` refuses the payload otherwise, in every mode. Its SHAPE is owned by `orbit-emit-composition`'s **The review payload carries `direction`** and its CONTENT contract by `orbit-report-rendering`'s **Direction renders as its own section and its absence is marked on independent passes** (which also renders it as `### Direction` and marks a prior-generation independent pass `[no direction]`); the authoring instruction is Step 8 of the body. The vocabulary is `orbit-run-summary-emit`'s judgement record's (`disposition` + `reasoning`) — adopted, not invented. This note names the owners and re-lists nothing.
- **`pass_genre` / `verified_walks`** (rc03c) are ENGINE-COMPUTED on every review emit, in every mode, and REFUSED in the payload: the pass genre by the table `orbit-conventions`' **Review mode decision framework** owns, and the qualifying walks it read, by `orbit-emit-composition`'s **The review emit records its pass genre and the walks it verifies**. Never supply either; a refusal naming the owed record is how a body learns the engine computed VERIFICATION.
- **`verification` / `walk_entry`** (rc03c) are the VERIFICATION RECORD and a finding's link to it: `verification` is OWED when the computed `pass_genre` is `VERIFICATION` (`[]` when nothing is owed) and REFUSED in any form on a REVIEW-genre pass; `walk_entry` is optional on each finding. Their shapes, the owed set and the meaning of `landed` / `regressed` are owned by `orbit-emit-composition`'s **A VERIFICATION-genre payload carries its verdicts and its findings link to the walk record**; the render (`### Verification`, the `walk entry:` line, `[outside the walk record]`, `[no verification record]`) by `orbit-report-rendering`'s **Verification renders as its own section and its absence is marked**; the grading procedure is Step 5's VERIFICATION branch. This note names the owners and re-lists nothing.
- **`recommendation_options`** is OPTIONAL on each finding. Present only when the finding's recommendation is genuinely disjunctive — multiple defensible paths the user must choose between. Producer-side contract (per `orbit-review` spec's `Optional recommendation_options field on finding entries`): MUST contain ≥ 2 entries; each entry MUST have non-empty `label` (typically `"A"`, `"B"`, `"C"`, … or `"1"`, `"2"`, …) and non-empty `body`. The prose `recommendation` field still summarizes the disjunction for human readers. Consumer (address-reviews) uses this for the structured decision-fork detection path; absence triggers heuristic fallback. Omit the field for single-recommendation findings.

## Architecture-mode extensions (D-arc Stage D2)

Architecture-mode emits (`review-architecture-<TS>.json` in the architecture trail) use the same spine and per-command extensions with these differences:

- `change: null` and a REQUIRED `doc` field (the reviewed doc's filename stem — iteration counting anchors to matching-`doc` emits only).
- `mode: "architecture"`; `iteration` is per-doc (not per-change).
- `scorecard` is the same 3-dimension × 3-severity shape as change modes — the engine runs the scorecard rollup check in architecture mode too (corrected 2026-09-11 by the schema-table parity test; `findings_summary` was never accepted by the review payload table); findings cite `<doc>.md:line`.
- `flags.mark` / `flags.skip_verify` are absent (change-mode-only flags); `parallel`/`fast`/`focus` record their no-op values.
- `final_assessment` / `next_recommended` are GATE-LESS: with findings, address-reviews targeting this emit; all-clear, `"No findings. The architecture trail records this pass."` — never a lifecycle command.
- A REQUIRED `handoff` section per arc ruling R-d-9(b) (shape owned by `orbit-architect`): `boot_sequence` (ordered POINTERS into existing artifacts, never duplicated substance), `next_command`, `model_hint` (nullable), `seam`.

```json
{
  "command": "review",
  "timestamp": "<ISO-8601>",
  "change": null,
  "doc": "<doc-name>",
  "mode": "architecture",
  "reviewer_class": "in-context" | "fresh" | "external",
  "iteration": <integer, per-doc>,
  "scorecard": { "completeness": { "critical": 0, "warning": 0, "suggestion": 0 }, "correctness": { "critical": 0, "warning": 0, "suggestion": 0 }, "coherence": { "critical": 0, "warning": 0, "suggestion": 0 } },
  "findings": [ ... same finding shape ... ],
  "final_assessment": "<gate-less phrasing>",
  "next_recommended": "<address-reviews targeting this emit, or the all-clear sentence>",
  "kind": "editorial",
  "handoff": {
    "boot_sequence": ["<pointer + one-line why>", "..."],
    "next_command": "<the one command a cold session runs first>",
    "model_hint": null,
    "seam": "<which phase seam this boundary is>"
  }
}
```

### Example payload (architecture mode)

A payload file the body writes for an in-context architecture-mode pass — real JSON, accepted by `orbit emit review --doc <doc-name>`, carrying no engine-owned key. A test submits this block, unchanged, through the write gate.

```json example doc
{
  "mode": "architecture",
  "reviewer_class": "in-context",
  "scorecard": {
    "completeness": { "critical": 0, "warning": 0, "suggestion": 0 },
    "correctness": { "critical": 0, "warning": 1, "suggestion": 0 },
    "coherence": { "critical": 0, "warning": 0, "suggestion": 0 }
  },
  "findings": [
    {
      "pass": "3",
      "severity": "WARNING",
      "dimension": "correctness",
      "file": "program.md",
      "line": 88,
      "title": "Stage s4 depends on s5, which depends on s4",
      "recommendation": "Drop one Depends-on edge; the cycle leaves both stages premised forever."
    }
  ],
  "handoff": {
    "boot_sequence": ["orbit/architecture/program.md — the stages and their exit criteria"],
    "next_command": "/orbit:address-reviews --from-file <this emit's path>",
    "model_hint": null,
    "seam": "architecture review → walk"
  },
  "model": "claude-opus-5-5"
}
```
