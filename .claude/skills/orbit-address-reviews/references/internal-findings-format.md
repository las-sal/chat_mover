# Reference: internal-findings file format (for `--from-file` JSON parsing AND discovery)

This parser contract is consumed by BOTH explicit `--from-file <path>` invocations AND discovery from `.orbit-runs/` when `/orbit:address-reviews <change-name>` walks a change's outstanding passes and unwalked audit-drift emits (the DISCOVERY fence in SKILL.md Step 1). The parsing logic and virtual-marker construction are IDENTICAL regardless of how the JSON entered the lifecycle — only the resolution log's `source` field differs (`"from-file"` vs `"auto-discovered"`).

The `--from-file <path>` flag accepts TWO format families: (a) external-review markdown (see `external-findings-format.md`), (b) internal findings JSON (this file). The parser auto-detects format via content sniff: leading `{` routes to JSON; leading `# External Review:` routes to markdown; anything else triggers a format-mismatch error.

This format MUST match what `/orbit:review` writes to `orbit/changes/<name>/.orbit-runs/review-<mode>-<TS>.json` for `proposal`/`system` modes, what it writes to `orbit/architecture/.orbit-runs/review-architecture-<TS>.json` for `architecture` mode (D-arc Stage D2 — `change: null` plus a `doc` field naming the reviewed doc), OR what `/orbit:audit-drift` writes to its summary JSON paths (per the audit-drift run-summary-schema). V1 accepts BOTH `command: "review"` AND `command: "audit-drift"` JSON; other `command` values are rejected. The full JSON schemas live in the producer skills' bundled references — the `orbit-review` skill's `references/run-summary-schema.md` and the `orbit-audit-drift` skill's `references/run-summary-schema.md` (shipped alongside each generated skill); this file documents the `--from-file` parser's subset of those schemas (the fields it reads to construct virtual markers).

## Expected file format

### Review JSON (`command: "review"`)

```json
{
  "command": "review",
  "timestamp": "<ISO-8601>",
  "change": "<change-name>",              // null in architecture mode (a doc field names the reviewed doc)
  "doc": "<doc-name, architecture mode only>",
  "mode": "proposal" | "system" | "architecture",
  "iteration": <integer>,
  "scorecard": {
    "completeness": { "critical": <int>, "warning": <int>, "suggestion": <int> },
    "correctness": { "critical": <int>, "warning": <int>, "suggestion": <int> },
    "coherence": { "critical": <int>, "warning": <int>, "suggestion": <int> }
  },
  "findings": [
    {
      "pass": "<pass id>",
      "severity": "CRITICAL" | "WARNING" | "SUGGESTION",
      "file": "<path>",
      "line": <integer>,
      "title": "<finding title>",
      "recommendation": "<actionable recommendation>",
      "reproduction": "<present on every CRITICAL written since rc02b; optional below; multi-line allowed>",
      "recommendation_options": [
        { "label": "A", "body": "..." },
        { "label": "B", "body": "..." }
      ]
    }
  ],
  "blocks": ["<optional: lifecycle blocks the pass found — listed FIRST at triage, never virtual markers>"]
}
```

Review emits written before D-arc Stage D4 carry `findings_summary` (flat severity counts) instead of `scorecard`; that legacy field is still READ — this parser consumes neither, only `findings[]` — but no current review emit writes it.

### Audit-drift JSON (`command: "audit-drift"`)

```json
{
  "command": "audit-drift",
  "timestamp": "<ISO-8601>",
  "change": "<change-name string OR null for project-wide standalone>",
  "categories_run": ["1", "2", "3", "4", "5", "6"],
  "findings_total": <int>,
  "findings_by_category": { "<category id>": <int> },
  "findings": [
    {
      "category": "1" | "2" | "3" | "4" | "5" | "6",
      "severity": "CRITICAL" | "WARNING" | "SUGGESTION",
      "file": "<path>",
      "line": <integer>,
      "title": "<finding title>",
      "recommendation": "<actionable recommendation>",
      "recommendation_options": [
        { "label": "A", "body": "..." },
        { "label": "B", "body": "..." }
      ]
    }
  ]
}
```

### Optional `recommendation_options` field (BOTH formats)

Both review JSON and audit-drift JSON MAY emit an optional `recommendation_options: [{label, body}]` array on a finding when the recommendation is genuinely disjunctive — multiple defensible paths the user must choose between. The address-reviews parser reads this field for the **structured decision-fork detection path** (per `orbit-address-reviews` spec's `Disjunctive recommendation fields surface as decision forks` requirement). Field shape is identical across the two producer formats; consumer parses both uniformly.

Producer-side contract (enforced by orbit-review and orbit-audit-drift specs):

- MUST contain ≥ 2 entries when emitted (single-option arrays defeat the purpose; the prose `recommendation` field carries single recommendations).
- Each entry MUST have non-empty `label` (typically `"A"`, `"B"`, `"C"`, … or `"1"`, `"2"`, …) and non-empty `body` (the concrete action the user would take if they pick this option).
- The prose `recommendation` field still summarizes the disjunction for human readers; the structured field complements it, doesn't replace.
- OPTIONAL on every finding — single-recommendation findings omit it.

The two shapes are identical at the universal-spine + `findings[]` level. They differ only in the provenance slot per finding: review JSON carries `pass` (string pass-id), audit-drift JSON carries `category` (one of `"1"`–`"6"`, the audit-drift category ids; the emit's shape is owned by `orbit-run-summary-emit`'s `Audit-drift standalone recommendations`).

### Universal-spine field requirements (BOTH formats)

The universal-spine fields (`command`, `timestamp`, `change`, `final_assessment`, `next_recommended`, `kind`, `model` — `model` absent on pre-capability emits) are REQUIRED in every real orbit-emitted JSON per `orbit-conventions`'s `Internal-run JSON summary format` requirement; downstream tools rely on them being present. The address-reviews `--from-file` parser does NOT consume them when constructing virtual markers — it only reads `command` (as the discriminator) and `findings[]` (for marker construction). Other top-level fields (`final_assessment`, `next_recommended`, `kind`, `depth`, `flags`, `passes_run`, `passes_skipped`, `stale_suppressed`, `iteration_note`, `categories_run`, `findings_total`, `findings_by_category`, etc.) are present in real JSON and IGNORED by this parser — they're consumed by other tooling (e.g., a downstream status reader).

## Parser contract

For each entry in the JSON's `findings[]` array, construct a virtual marker with:

| Virtual marker field | Source JSON field |
|---|---|
| `severity` | The entry's `severity` field (`CRITICAL` / `WARNING` / `SUGGESTION`) |
| `title` | The entry's `title` field |
| `file:line` | The entry's `file` + `line` fields joined as `<file>:<line>` |
| `description` | The entry's `recommendation` field |
| `reproduction` | The entry's `reproduction` field when present (review JSON; required on a CRITICAL written since rc02b, absent on prior-generation emits) — a CRITICAL marker without one is tagged `unreproduced` at triage and in its resolution entry's `reproduction_rerun` |
| `source` | `internal-review` for `command: "review"` JSON; `audit-drift` for `command: "audit-drift"` JSON (vs `external` for markdown, `inline` for grep-found) |
| `provenance_detail` | The entry's `pass` field (for review JSON) OR `category` field (for audit-drift JSON) — preserved verbatim in the resolution log |
| `recommendation_options` (optional) | The entry's `recommendation_options[]` array if present and well-formed. Drives the structured decision-fork detection path in Step 3b.5 of the SKILL.md walk. Malformed input (< 2 entries, missing label/body) triggers heuristic fallback with a stderr warning + `structured_path_skipped_reason` field in the resolution log. |

The review JSON's optional top-level `blocks[]` entries are listed FIRST in the triage table as blocks and never become virtual markers (the same rule as the markdown format's `## Blocks` section).

Virtual markers walk the same lifecycle as inline markers, with one exception: **the marker-removal step (Step 3e in the SKILL.md walk) is a no-op** — there's no source-file marker text to delete. (Same behavior as external-markdown virtual markers; the no-op is shared across all virtual-marker provenance.)

### Command field discriminator

The parser MUST check the top-level `command` field after JSON parse succeeds:

- `command: "review"` → proceed with `findings[]` extraction; tag virtual markers `source: "internal-review"`.
- `command: "audit-drift"` → proceed with `findings[]` extraction; tag virtual markers `source: "audit-drift"`; use the per-finding `category` field as the provenance-detail slot (rather than `pass`).
- Any other `command` value (e.g., `"address-reviews"`, `"apply"`, `"archive"`, `"propose"`, `"explore"`, `"new"`, `"continue"`, `"ff"`, `"review-external"`) → emit a clean error message naming the supported `command` values (`"review"`, `"audit-drift"`) and the observed value, then exit without acting on any findings.

V1 supports `review-<mode>-*.json` AND `audit-drift-*.json` (standalone audit-drift only — library/pre-archive contexts write no separate audit-drift JSON; their findings travel inside the caller's emit). Other internal JSONs are rejected explicitly rather than silently mis-parsed. **`command: "address-reviews"` is rejected on purpose**: address-reviews ingest of its own resolution log would loop (the lifecycle would feed itself recursively); cycle prevention requires explicit rejection.

### Fresh pushback applies to JSON virtual markers (both review and audit-drift)

The source JSON's own `stale_suppressed[]` array already filtered stale findings at source-run time. **Fresh pushback against current state IS still applied** when address-reviews ingests the JSON: state may have changed between the source run and the resolve (e.g., user fixed an issue ad-hoc; another commit landed). The SKILL.md walk step (3a — Apply pushback) executes for each JSON-virtual marker the same way it would for an inline marker or external-markdown virtual marker, regardless of whether the source was `/orbit:review` or `/orbit:audit-drift`.

This is intentional double-pushback: the JSON-side filter is a subset of staleness; the lifecycle-side check is a superset.

## Malformed input handling

If the file is JSON but malformed in any of these ways, the parser MUST refuse to act on partial input:

- **JSON parse failure** (file looks like JSON but invalid syntax) → emit a parse-error message naming the file + the JSON parse-error position (best-effort), then exit. User fixes the file and re-runs.
- **Missing `command` field** OR `command` value other than `"review"` / `"audit-drift"` → emit the unsupported-command error (see "Command field discriminator" above).
- **Missing `findings[]` field** OR `findings` present but not an array → emit a clean error naming the missing/malformed `findings[]` requirement; reference this file for the expected shape; exit.
- **Empty `findings: []`** → NOT an error. Succeed with zero virtual markers; the resolution log reports a clean empty walk (`✓ Resolved: 0, ⚠ Stale: 0, ⏸ Deferred: 0, ✗ Escalated: 0`) with a one-line note `Source JSON had no findings to walk; resolution log is informational.` A clean review OR clean audit-drift run with `findings: []` is the expected state for an all-clear pass — feeding it through `--from-file` is a valid no-op invocation.

## Tolerated variations

The parser SHOULD be lenient on:

- **Missing optional `line` field** on a finding → construct the virtual marker with `file` only (no line component); resolution log shows the file path without `:line`. Some findings are file-scoped rather than line-scoped (e.g., "this file needs a top-level section added").
- **Missing optional `pass` field** → virtual marker's `pass` provenance is reported as `unknown` in the resolution log; lifecycle proceeds normally.
- **Extra top-level JSON fields** (e.g., `dogfood_note`, `convergence_state`, `flags`, `iteration_note`) → ignored; not consumed by the parser. These exist for other tooling and don't affect virtual-marker construction.
- **Mixed-case `severity`** values (`Critical`, `warning`, etc.) → normalize to upper-case before comparison.

The parser MUST be strict on:

- **Top-level `command` field** — must be exactly `"review"` OR `"audit-drift"` (case-sensitive). Other values rejected per the unsupported-command path.
- **Per-finding `severity` field** — must be one of `CRITICAL`, `WARNING`, `SUGGESTION` after case normalization.
- **Per-finding `title` field** — must be a non-empty string.
- **Per-finding `file` field** — must be a non-empty string (the file path).
- **Per-finding `recommendation` field** — must be a non-empty string (becomes the virtual marker's description).

The reason for the strict/lenient split: the strict items are what the orbit run-summary schema guarantees by spec (per `orbit-conventions`'s `Internal-run JSON summary format` requirement + `orbit-review`'s per-command extensions); the lenient items are best-effort fields that downstream tools handle but the parser doesn't strictly require.

**On optional structured fields** — the strict/lenient split does NOT assert the absence of optional fields. `recommendation_options[]` is OPTIONAL on every finding; presence triggers the structured decision-fork detection path (Step 3b.5 of SKILL.md), absence triggers heuristic fallback. Malformed presence (< 2 entries, missing fields) triggers heuristic fallback with a stderr warning + `structured_path_skipped_reason` field in the resolution log. Parser MUST gracefully handle both presence and absence without erroring.

## Quick worked example of valid input

```json
{
  "command": "review",
  "timestamp": "2026-05-26T20:01:08Z",
  "change": "harden-review-mode-recommendations",
  "mode": "system",
  "iteration": 2,
  "findings_summary": {
    "critical": 0,
    "warning": 0,
    "suggestion": 1
  },
  "findings": [
    {
      "pass": "2",
      "severity": "SUGGESTION",
      "file": "<skills-dir>/orbit-review/references/run-summary-schema.md",
      "line": 22,
      "title": "Schema reference does not document new convergence fields emitted by iteration-aware logic",
      "recommendation": "Out of scope for this change. Track as a follow-up: future change touching the run-summary contract should add convergence_state / convergence_state_label / convergence_inputs (plus skip_reasons and dogfood_note) to references/run-summary-schema.md."
    }
  ]
}
```

This example has 0 CRITICAL, 0 WARNING, 1 SUGGESTION. Ingesting it via `--from-file` produces one virtual marker:

- `severity`: `SUGGESTION`
- `title`: `Schema reference does not document new convergence fields emitted by iteration-aware logic`
- `file:line`: `<skills-dir>/orbit-review/references/run-summary-schema.md:22`
- `description`: (the `recommendation` text)
- `source`: `internal-review`

The lifecycle walks this marker: pushback verifies the gap still applies → classify as `decision required` (out-of-scope/defer or include-in-current-change) → user makes the call → log entry written. Marker removal is no-op (no source file to delete from).
