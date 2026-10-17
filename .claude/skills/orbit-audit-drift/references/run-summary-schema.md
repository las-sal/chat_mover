# Reference: audit-drift run-summary schema

Each `/orbit:audit-drift` invocation persists a JSON summary. Path varies by invocation mode (three modes, per `orbit-run-summary-emit`'s `Audit-drift standalone recommendations` requirement):

- **Change-scoped standalone** (`/orbit:audit-drift <name>` — user invokes with a change name; no caller signal): `orbit/changes/<change-name>/.orbit-runs/audit-drift-<TS>.json`
- **Project-wide standalone** (`/orbit:audit-drift` — no positional; no caller signal): `orbit/.orbit-runs/audit-drift-<TS>.json` (create `orbit/.orbit-runs/` if needed)
- **Library / pre-archive** (caller signal present — invoked by `/orbit:review --as system` Pass 6 or `/orbit:archive` pre-archive sweep): no separate audit-drift JSON — findings fold into the caller's emit (the review's `review-system-<TS>.json`, or the archive's `archive-<TS>.json` `audit.*` fields).

## Universal spine inheritance

The spine every emit carries — its fields, their types and which of them the engine composes — is owned by `orbit-conventions`' `Internal-run JSON summary format` requirement, and is not restated here; the write gate refuses every field the engine composes. The example below carries exactly what a payload supplies, `model` included.

The payload this command writes is OWNED by `orbit-run-summary-emit`'s `Audit-drift standalone recommendations` requirement, which this reference MIRRORS and never defines: the per-command extensions are `categories_run`, `findings` and `stale_suppressed`, plus `final_assessment`. The two counts — `findings_total` and `findings_by_category` — are ENGINE-COMPUTED from `findings` and refused in the payload, per `orbit-emit-composition`'s `Audit-drift counts are engine-computed`. The write gate refuses any other key.

## Schema

```json
{
  "command": "audit-drift",
  "timestamp": "<ISO-8601>",
  "change": "<change-name string for change-scoped standalone; null for project-wide standalone>",
  "final_assessment": "<stock phrasing per invocation mode>",
  "next_recommended": "<engine-composed, per orbit-run-summary-emit's Audit-drift standalone recommendations — never supplied>",
  "kind": "editorial",
  "model": "<the emitting AI's model identity, or null>",
  "categories_run": ["1", "2", "3", "4", "5", "6"],
  "findings_total": <integer>,                     // engine-computed; refused in the payload
  "findings_by_category": { "<category id>": <integer> }, // engine-computed; refused in the payload
  "findings": [
    {
      "category": "1",
      "severity": "CRITICAL" | "WARNING" | "SUGGESTION",
      "file": "orbit/specs/foo/spec.md",
      "line": 42,
      "title": "Stale 'BridgeServer' reference (renamed to HostLifecycle in 2026-03)",
      "recommendation": "Delta the file in a future change or apply a hotfix commit.",
      "recommendation_options": [
        { "label": "A", "body": "<option A body>" },
        { "label": "B", "body": "<option B body>" }
      ]
    }
  ],
  "stale_suppressed": [
    { "category": "<category id>", "title": "...", "evidence": "..." }
  ]
}
```

## Example payload

The payload file Step 10 writes — real JSON, accepted by `orbit emit audit-drift` with `--change <name>` and bare. It carries no engine-owned key. A test submits this block, unchanged, through the write gate in both scopes (`orbit-emit-composition`'s `Payload schema references are proven by execution`).

```json example change project
{
  "final_assessment": "No critical issues. 1 warning(s) to consider.",
  "categories_run": ["1", "2", "3", "4", "5", "6"],
  "findings": [
    {
      "category": "1",
      "severity": "WARNING",
      "file": "orbit/specs/orbit-status/spec.md",
      "line": 42,
      "title": "Stale 'BridgeServer' reference (renamed to HostLifecycle)",
      "recommendation": "Replace the name in the next change that touches orbit-status."
    },
    {
      "category": "3",
      "severity": "SUGGESTION",
      "file": "README.md",
      "line": 12,
      "title": "README and orbit-onboard disagree on the command count",
      "recommendation": "Make one side canonical and point the other at it.",
      "recommendation_options": [
        { "label": "A", "body": "README is canonical; orbit-onboard points at it." },
        { "label": "B", "body": "orbit-onboard is canonical; README points at it." }
      ]
    }
  ],
  "stale_suppressed": [
    { "category": "2", "title": "Lens 'verify-first' names a retired command", "evidence": "grep finds no 'verify-first' in orbit/ since 1a2b3c4d" }
  ],
  "model": "claude-opus-5-5"
}
```

## Field notes

- **`categories_run`** is an array of category-id strings, `"1"` through `"6"` (5 = Touchpoints divergence, 6 = Emit attestation cross-check — D-arc Stage D5) — the categories that ran; skip reasons belong in the report body, not the array. The write gate refuses any other shape (an object of booleans, numbers), never coerces it — and checks the TYPE only: an id outside `"1"`–`"6"` is accepted and counted like any other, so the range is this body's to keep.
- **`category`** on each finding is REQUIRED, a non-empty category-id string — `findings_by_category` counts it.
- **`findings_total` / `findings_by_category`** are ENGINE-COMPUTED and refused in the payload: the length of `findings`, and one key per id in `categories_run` plus one per category a finding carries, each the number of findings carrying it — per `orbit-emit-composition`'s `Audit-drift counts are engine-computed`. `stale_suppressed` entries are not counted.
- **`recommendation_options`** is OPTIONAL on each finding. Present only when the finding's recommendation is genuinely disjunctive — multiple defensible remediation paths the user must choose between. Producer-side contract (per `orbit-audit-drift` spec's `Optional recommendation_options field on audit-drift finding entries`): MUST contain ≥ 2 entries; each entry MUST have non-empty `label` (typically `"A"`, `"B"`, `"C"`, …) and non-empty `body`. Per-category emit guidance: Category 1 (vocabulary residue) typically single-recommendation; Category 2 (lens staleness) often disjunctive (rename-vs-remove); Category 3 (cross-doc consistency) often disjunctive (which side is canonical); Category 4 (archive coherence) typically single. The prose `recommendation` field still summarizes the disjunction for human readers. Field shape is identical to `orbit-review`'s `recommendation_options`; consumer (address-reviews) parses both producers uniformly. Omit for single-recommendation findings.
