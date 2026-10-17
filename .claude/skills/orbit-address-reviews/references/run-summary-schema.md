# Reference: address-reviews run-summary schema

Each `/orbit:address-reviews` invocation persists a JSON summary. Path varies:

- **Change-scoped** (when scope is a single change directory or `--from-file` points into a change's `.orbit-runs/`): `orbit/changes/<change-name>/.orbit-runs/address-reviews-<TS>.json`
- **Archived-change** (the positional resolved an archived change — the engine's `--change` fallback): `orbit/changes/archive/<YYYY-MM-DD>-<name>/.orbit-runs/address-reviews-<TS>.json`
- **Architecture-scoped** (`--from-file` into `orbit/architecture/.orbit-runs/`): `orbit/architecture/.orbit-runs/address-reviews-<TS>.json` (`change: null`; `doc` carried from the source emit)
- **Whole-repo / cross-change** (bare `orbit emit address-reviews`): `orbit/.orbit-runs/address-reviews-<TS>.json`

Every location is written by the emit surface — no scope hand-writes its log.

## Universal spine inheritance

The spine every emit carries is owned by `orbit-conventions`' `Internal-run JSON summary format` requirement, and is not restated here; the write gate refuses every field the engine composes (`next_recommended` and the `iteration` ordinal among them). For address-reviews, `final_assessment` is the payload's own narrative of the resolution outcome, and `change` is `null` for whole-repo / cross-change and architecture scope, where an architecture-scoped log carries a `doc` field instead.

The schema below documents per-command extensions ADDED to that spine (`source`, `source_path`, `source_command`, `source_token`, `latest_apply_token`, `external_reviewer`, `walk_mode`, `walk_mode_source`, `walk_mode_shifted_at_finding`, `input_findings_summary`, `pushback_verification`, `resolution_summary`, `delegation_directive`, `resolutions` with entry-level `ratified_via`/`resolution` plus `recommendation_fork`, `ripple_cascade`, `sweep` and `ripple_miss_of` sub-objects and the per-entry `remedy`, `routed_to` and `disagreement`, `remaining_markers_in_scope`, `persisted_escalations`) and the engine-computed `ripple_misses`. Per-command extensions are address-reviews-specific state.

## Schema (v2)

```json
{
  "command": "address-reviews",
  "timestamp": "<ISO-8601>",
  "change": "<change-name string for change-scoped; null for whole-repo / cross-change AND architecture scope>",
  "doc": "<architecture scope only: the doc carried from the source review-architecture emit; absent otherwise>",
  "final_assessment": "<short narrative of the resolution outcome>",
  "next_recommended": "<suggested next command, e.g., 're-run /orbit:review --as proposal to confirm convergence'>",
  "kind": "editorial",
  "source": "whole-repo" | "scope" | "from-file" | "auto-discovered",
  "source_path": "<scope path, --from-file path, or the ONE discovered file this log walks; null for whole-repo>",
  "source_command": "<for auto-discovered source: the discovered file's top-level command — 'review' or 'audit-drift' — or null for an external return, which carries none; null otherwise>",
  "source_token": "<for auto-discovered source: the discovered file's filename <TS> token; null otherwise>",
  "latest_apply_token": "<for auto-discovered source: most-recent apply-*.json filename token in the same .orbit-runs/, or null if no apply JSON exists; null for other sources>",
  "external_reviewer": "<from --from-file's Reviewer field, if applicable, else null>",
  "walk_mode": "per_finding" | "batch",
  "walk_mode_source": "flag" | "verbal" | "command-shape-interruption",
  "walk_mode_shifted_at_finding": "<1-indexed finding number when mode shifted mid-walk; present only when walk_mode_source == 'command-shape-interruption'>",
  "input_findings_summary": {
    "critical": 0,
    "warning": 0,
    "suggestion": 0
  },
  "pushback_verification": "<short note: how many findings verified against current state; how many stale>",
  "resolution_summary": {
    "resolved": 0,
    "stale_suppressed": 0,
    "deferred": 0,
    "escalated": 0
  },
  "resolutions": [
    {
      "severity": "CRITICAL" | "WARNING" | "SUGGESTION",
      "title": "<finding title>",
      "marker_source": "inline" | "external" | "internal-review" | "audit-drift",
      "file": "<path>",
      "line": 41,
      "classification": "trivial_fix" | "decision_required" | "stale" | "unresolvable",
      "action": "<what was done — applied edit, filed as task, converted to @todo:, escalated, etc.>",
      "reproduction_rerun": "reproduced" | "not-reproduced" | "cannot-run" | "unreproduced",
      "ratified_via": "chat" | "prompt",
      "resolution": "<the ratified direction verbatim — required when no fork was detected or the direction is off-menu>",
      "recommendation_fork": {
        "detected": true,
        "source": "structured" | "heuristic",
        "options_presented": [{ "label": "A", "body": "..." }, { "label": "B", "body": "..." }],
        "chosen": "A" | "off-menu",
        "structured_path_skipped_reason": "<optional; e.g., 'only 1 entry in array', 'missing label on entry index 2'>"
      },
      "ripple_cascade": {
        "applied": ["<paths edited as part of the cascade>"],
        "flagged_not_applied": [{ "path": "...", "reason": "<OUT-category reason OR `--no-cascade suppressed`>" }]
      },
      "sweep": {
        "retired": ["<wording the fix made false>"],
        "introduced": [{ "path": "<path>", "text": "<text the fix added>" }],
        "searched": ["<what was searched for>"],
        "scope": ["<paths examined beyond file and ripple_cascade.applied>"],
        "kept": [{ "path": "<path>", "why": "<why it keeps a retired string>" }]
      },
      "ripple_miss_of": { "walk": "<earlier walk's filename token>", "title": "<that entry's title>", "file": "<that entry's file>", "kind": "scope" | "query" | "judgement" },
      "remedy": "repair" | "descope" | "redesign",
      "routed_to": "<a REDESIGN's route: orbit/explore/<new-name>/, or orbit/changes/<name>/explore.md on an active change>",
      "disagreement": { "with": { "pass": "<the other pass's filename token>", "title": "<its finding's title>", "file": "<its finding's file>" }, "test": "<the test as run>", "observed": "<its output or derivation>" },
      "outcome": "resolved" | "stale" | "deferred" | "escalated"
    }
  ],
  "ripple_misses": "<engine-computed: the count of resolutions carrying ripple_miss_of; refused in the payload>",
  "delegation_directive": "<optional: the user's verbatim mid-walk delegation, when one was issued>",
  "remaining_markers_in_scope": 0,
  "persisted_escalations": [
    { "file": "...", "line": 0, "title": "...", "reason": "..." }
  ]
}
```

## Example payloads

Five payload files the walk writes, ONE PER PROVENANCE, because the fields that record where the findings came from cannot appear together: a discovered internal review pass on an active change, walked in a mode that switched to batch mid-walk; a discovered external return on an active change (a converged finding, a disagreement, an essential redesign — an active change only, because that route returns the change to exploration); a discovered audit-drift emit (an active change, or an archived one through the archived fallback); a bare whole-repo marker walk; and a `--from-file` walk of an architecture review. The five are independent: each illustrates its own provenance, and no two are written as halves of one walk. Each is real JSON carrying no engine-owned key, and each is tagged with the scopes its own values describe — a bare whole-repo walk must carry `remaining_markers_in_scope`, which drives its recommendation. A test submits each block, unchanged, through the write gate in every scope its tag names, and checks that together they carry every key the schema documents (`orbit-emit-composition`'s `Payload schema references are proven by execution`). The worked-example snippets further down are ILLUSTRATIONS of single fields, not payloads: they omit `command` so the test never reads them as schema blocks.

```json example change
{
  "final_assessment": "Two of two resolved: the CRITICAL by a reordered step, the WARNING by the ratified direction B.",
  "source": "auto-discovered",
  "source_path": "orbit/changes/add-detail-flag/.orbit-runs/review-proposal-2026-10-02T09-00-00Z.json",
  "source_command": "review",
  "source_token": "2026-10-02T09-00-00Z",
  "latest_apply_token": null,
  "external_reviewer": null,
  "walk_mode": "batch",
  "walk_mode_source": "command-shape-interruption",
  "walk_mode_shifted_at_finding": 2,
  "input_findings_summary": { "critical": 1, "warning": 1, "suggestion": 0 },
  "pushback_verification": "Both findings verified against current state; none stale.",
  "resolution_summary": { "resolved": 2, "stale_suppressed": 0, "deferred": 0, "escalated": 0 },
  "resolutions": [
    {
      "severity": "CRITICAL",
      "title": "Archive step deletes the staging directory before the copy is verified",
      "marker_source": "internal-review",
      "file": "design.md",
      "line": 40,
      "classification": "trivial_fix",
      "action": "reordered design.md step 3 after step 4's copy check",
      "reproduction_rerun": "reproduced",
      "evidence": "re-read design.md steps 3-4: the delete preceded the check",
      "ripple_cascade": { "applied": ["orbit/changes/add-detail-flag/tasks.md"], "flagged_not_applied": [] },
      "sweep": { "retired": ["delete the staging directory, then verify the copy"], "introduced": [], "searched": ["staging directory", "verify the copy"], "scope": [], "kept": [] },
      "remedy": "repair",
      "outcome": "resolved"
    },
    {
      "severity": "WARNING",
      "title": "No task updates the generated surface after the template edit",
      "marker_source": "internal-review",
      "file": "tasks.md",
      "line": 12,
      "classification": "decision_required",
      "action": "applied the ratified direction B — folded the update into task 2.3",
      "ratified_via": "chat",
      "recommendation_fork": {
        "detected": true,
        "source": "structured",
        "options_presented": [{ "label": "A", "body": "Add the task to group 5." }, { "label": "B", "body": "Fold it into task 2.3." }],
        "chosen": "B"
      },
      "ripple_cascade": { "applied": [], "flagged_not_applied": [] },
      "sweep": { "retired": [], "introduced": [], "searched": ["generated surface", "update --force"], "scope": [], "kept": [] },
      "remedy": "repair",
      "outcome": "resolved"
    }
  ],
  "delegation_directive": "batch the rest",
  "remaining_markers_in_scope": 0,
  "persisted_escalations": [],
  "model": "claude-opus-5-5"
}
```

```json example change
{
  "final_assessment": "One stale as converged with the fresh half's log, one repaired after a disagreement test, one escalated as an essential redesign; this pass stays outstanding.",
  "source": "auto-discovered",
  "source_path": "orbit/changes/add-detail-flag/.orbit-runs/external-system-2026-10-02T10-00-00Z.md",
  "source_command": null,
  "source_token": "2026-10-02T10-00-00Z",
  "latest_apply_token": "2026-10-02T08-00-00Z",
  "external_reviewer": "GPT-6 Codex",
  "walk_mode": "per_finding",
  "input_findings_summary": { "critical": 1, "warning": 2, "suggestion": 0 },
  "pushback_verification": "All three verified; one converged with the fresh half, one settled by a test.",
  "resolution_summary": { "resolved": 1, "stale_suppressed": 1, "deferred": 0, "escalated": 1 },
  "resolutions": [
    {
      "severity": "WARNING",
      "title": "The detail flag is not documented in the command help",
      "marker_source": "external",
      "file": "src/cli/detail.ts",
      "line": 12,
      "classification": "stale",
      "action": "converged with the fresh half's finding, walked in its log",
      "evidence": "resolved in address-reviews-2026-10-02T11-00-00Z (the earlier pass's log)",
      "outcome": "stale"
    },
    {
      "severity": "WARNING",
      "title": "The parser accepts an empty detail value",
      "marker_source": "external",
      "file": "src/cli/detail.ts",
      "line": 30,
      "classification": "trivial_fix",
      "action": "refused the empty value",
      "disagreement": {
        "with": { "pass": "2026-10-02T09-30-00Z", "title": "The parser refuses an empty detail value", "file": "src/cli/detail.ts" },
        "test": "node bin/cli.js --detail ''",
        "observed": "exit 0 with an empty detail, so the external claim holds and the fresh claim is stale"
      },
      "ripple_cascade": { "applied": [], "flagged_not_applied": [] },
      "sweep": { "retired": [], "introduced": [], "searched": ["--detail", "empty value"], "scope": [], "kept": [] },
      "remedy": "repair",
      "outcome": "resolved"
    },
    {
      "severity": "CRITICAL",
      "title": "The cache the flag reads has no invalidation rule",
      "marker_source": "external",
      "file": "design.md",
      "line": 55,
      "classification": "unresolvable",
      "action": "escalated: invalidation is mechanism nobody has reviewed, and the change cannot ship without it",
      "reproduction_rerun": "unreproduced",
      "remedy": "redesign",
      "routed_to": "orbit/changes/add-detail-flag/explore.md",
      "outcome": "escalated"
    }
  ],
  "remaining_markers_in_scope": 0,
  "persisted_escalations": [],
  "model": "claude-opus-5-5"
}
```

```json example change archived
{
  "final_assessment": "Three drifts resolved: one stale vocabulary line repaired, one requirement the change should not carry descoped, one mechanism routed to a new exploration.",
  "source": "auto-discovered",
  "source_path": "orbit/changes/add-detail-flag/.orbit-runs/audit-drift-2026-10-02T12-00-00Z.json",
  "source_command": "audit-drift",
  "source_token": "2026-10-02T12-00-00Z",
  "latest_apply_token": null,
  "external_reviewer": null,
  "walk_mode": "per_finding",
  "input_findings_summary": { "critical": 0, "warning": 3, "suggestion": 0 },
  "pushback_verification": "All three drifts verified against current state; none stale.",
  "resolution_summary": { "resolved": 3, "stale_suppressed": 0, "deferred": 0, "escalated": 0 },
  "resolutions": [
    {
      "severity": "WARNING",
      "title": "README still names the retired summary flag",
      "marker_source": "audit-drift",
      "file": "README.md",
      "line": 8,
      "classification": "trivial_fix",
      "action": "renamed the flag",
      "ripple_cascade": { "applied": [], "flagged_not_applied": [] },
      "sweep": { "retired": ["--summary-only"], "introduced": [], "searched": ["summary-only"], "scope": [], "kept": [] },
      "remedy": "repair",
      "outcome": "resolved"
    },
    {
      "severity": "WARNING",
      "title": "The change specifies a color theme no stage asked for",
      "marker_source": "audit-drift",
      "file": "proposal.md",
      "line": 20,
      "classification": "decision_required",
      "action": "removed the color-theme requirement, as ratified",
      "ratified_via": "chat",
      "resolution": "drop the theme; it is not this change's",
      "ripple_cascade": { "applied": [], "flagged_not_applied": [] },
      "sweep": { "retired": ["detail output uses the color theme"], "introduced": [], "searched": ["color theme"], "scope": [], "kept": [] },
      "remedy": "descope",
      "outcome": "resolved"
    },
    {
      "severity": "WARNING",
      "title": "The flag's cache warm-up is specified without a review",
      "marker_source": "audit-drift",
      "file": "design.md",
      "line": 70,
      "classification": "decision_required",
      "action": "removed the warm-up from the change and routed it to a new exploration, as ratified",
      "ratified_via": "chat",
      "resolution": "the flag works without warm-up; explore it on its own",
      "ripple_cascade": { "applied": [], "flagged_not_applied": [] },
      "sweep": { "retired": ["warm the cache before the first detail read"], "introduced": [], "searched": ["warm-up", "warm the cache"], "scope": [], "kept": [] },
      "remedy": "redesign",
      "routed_to": "orbit/explore/detail-cache-warmup/",
      "outcome": "resolved"
    }
  ],
  "remaining_markers_in_scope": 0,
  "persisted_escalations": [],
  "model": "claude-opus-5-5"
}
```

```json example project
{
  "final_assessment": "One inline marker resolved; none remain in the repo.",
  "source": "whole-repo",
  "source_path": null,
  "source_command": null,
  "source_token": null,
  "latest_apply_token": null,
  "external_reviewer": null,
  "walk_mode": "per_finding",
  "input_findings_summary": { "critical": 0, "warning": 0, "suggestion": 1 },
  "pushback_verification": "The one marker verified against current state; not stale.",
  "resolution_summary": { "resolved": 1, "stale_suppressed": 0, "deferred": 0, "escalated": 0 },
  "resolutions": [
    {
      "severity": "SUGGESTION",
      "title": "should this be five or four?",
      "marker_source": "inline",
      "file": "README.md",
      "line": 41,
      "classification": "trivial_fix",
      "action": "five → four, with the explicit list added",
      "ripple_cascade": { "applied": [], "flagged_not_applied": [] },
      "sweep": { "retired": ["the five supported formats"], "introduced": [], "searched": ["five", "formats"], "scope": [], "kept": [] },
      "remedy": "repair",
      "outcome": "resolved"
    }
  ],
  "remaining_markers_in_scope": 0,
  "persisted_escalations": [],
  "model": "claude-opus-5-5"
}
```

```json example doc
{
  "final_assessment": "One of one resolved: the dependency cycle broken by dropping s5's edge.",
  "source": "from-file",
  "source_path": "orbit/architecture/.orbit-runs/review-architecture-2026-10-02T11-00-00Z.json",
  "source_command": null,
  "source_token": null,
  "latest_apply_token": null,
  "external_reviewer": null,
  "walk_mode": "per_finding",
  "input_findings_summary": { "critical": 0, "warning": 1, "suggestion": 0 },
  "pushback_verification": "The finding verified against the doc's current Depends-on slots.",
  "resolution_summary": { "resolved": 1, "stale_suppressed": 0, "deferred": 0, "escalated": 0 },
  "resolutions": [
    {
      "severity": "WARNING",
      "title": "Stage s4 depends on s5, which depends on s4",
      "marker_source": "internal-review",
      "file": "program.md",
      "line": 88,
      "classification": "decision_required",
      "action": "dropped s5's Depends-on edge, as ratified",
      "ratified_via": "chat",
      "resolution": "s5 does not need s4; drop its edge",
      "ripple_cascade": { "applied": [], "flagged_not_applied": [] },
      "sweep": { "retired": [], "introduced": [], "searched": ["Depends-on", "s4"], "scope": [], "kept": [] },
      "remedy": "repair",
      "outcome": "resolved"
    }
  ],
  "remaining_markers_in_scope": 0,
  "persisted_escalations": [],
  "model": "claude-opus-5-5"
}
```

## v1 → v2 format migration (reader guidance)

The v2 shape is a **structural change** from v1, not a rename. Readers handling archived JSONs from both eras MUST detect which version they're reading:

- **v2 detection**: presence of `walk_mode` (top-level) OR `ripple_cascade` (per-resolution) indicates v2. v2 emits these fields on every walk.
- **v1 detection**: presence of `ripple_flagged_files_aggregate` (top-level flat array of strings) indicates v1. v1 did NOT emit `walk_mode` or per-resolution `ripple_cascade`.

**Why NOT a rename**: v1 aggregated ripple-flagged paths in a single top-level array across ALL resolutions, with no per-resolution attribution. v2 splits per-resolution into `ripple_cascade.applied[]` + `ripple_cascade.flagged_not_applied[]`. The shapes are NOT bijective — v1 archived JSONs cannot be losslessly upconverted to v2 (per-resolution attribution is lost in v1). Treat v1's aggregate as the union of all per-resolution ripple sets across the run; attribution to specific findings is unavailable.

**v2 fields not present in v1**: `walk_mode`, `walk_mode_source`, `walk_mode_shifted_at_finding`, per-resolution `recommendation_fork`, per-resolution `ripple_cascade`. Downstream consumers (e.g., a downstream status reader's tier-1 best-effort parse) handle absence as v1 and proceed gracefully.

## Field notes

- **`source`** distinguishes invocation paths: `whole-repo` for default scan, `scope` for positional `<scope>` argument (and the markers' log of a discovering walk), `from-file` for `--from-file <path>`, `auto-discovered` for a source the walk's discovery found (an outstanding pass or an unwalked audit-drift emit). Discovery's rule: `orbit-address-reviews`' `Address-reviews command available`.
- **`source_path`** carries the scope, the `--from-file` path, OR the ONE discovered file this log walks; `null` for `whole-repo`. A walk that discovered several sources writes one log per source, each naming its own (`orbit-address-reviews`' `One invocation writes one log per discovered source`).
- **`source_command`**, **`source_token`**, **`latest_apply_token`** — the discovery audit-trail fields. Emitted ONLY when `source: "auto-discovered"`; `null` for other sources. `source_command` = the discovered file's top-level `command` value (`"review"` or `"audit-drift"`), or `null` for an external return, which carries none; `source_token` = its filename `<TS>` token; `latest_apply_token` = the most-recent `apply-*.json` filename token in the same `.orbit-runs/` (orbit doesn't refuse to walk a pass older than the latest apply, but the log records both timestamps so downstream auditors can assess staleness). The retired recency rule's tie-break field is no longer written; the payload table still accepts it, and logs written before rc08b carry it.
- **`external_reviewer`** parsed from the `**Reviewer**:` field in the `--from-file` input; lets downstream tools track which AI's findings have been ingested. Only populated when `marker_source` is `external` (external-review markdown input); set to `null` for inline / internal-review / audit-drift sources (those have no human-readable reviewer-name field).
- **`input_findings_summary`** counts findings by severity at the input boundary (before pushback suppression). Total findings always = sum of `resolved` + `stale_suppressed` + `deferred` + `escalated` in `resolution_summary`.
- **`pushback_verification`** is a short prose note (1-2 sentences) summarizing pushback work — "all 9 findings verified against current state; 0 stale suppressions" or "9 findings; 3 stale-suppressed with commit evidence."
- **`marker_source`** distinguishes virtual-marker provenance: `inline` (grep-found `@review:` markers), `external` (external-review markdown parsed from `--from-file`), `internal-review` (internal `review-<mode>-*.json` JSON parsed from `--from-file`), `audit-drift` (`audit-drift-*.json` JSON parsed from `--from-file`).
- **`classification`** is the pushback-and-classify outcome before action.
- **`outcome`** is the final disposition; aligns with the ✓ Resolved / ⚠ Stale / ⏸ Deferred / ✗ Escalated counts in the resolution log.
- **`persisted_escalations`** captures `@review(escalated):` markers deliberately left in place; mirrors the resolution log's escalated section so downstream queries don't re-parse the log.
- **`next_recommended`** is the closing suggestion shown in the final-assessment line.
- **`walk_mode`** records the lifecycle mode the run used (per #11): `per_finding` (default — each marker walked sequentially with its own pushback → classify → fix → cascade → remove cycle) or `batch` (all markers complete pushback + classify + fix in one pass, then cascade as a single aggregated step).
- **`walk_mode_source`** distinguishes how batch-mode was entered: `flag` (`--batch` argv), `verbal` (recognized batch-intent phrase in the invocation message — "fix them all", "batch them", "go ahead with all", or equivalent), `command-shape-interruption` (bare unambiguous mid-walk mode-switch message — "go batch", "switch to batch", "batch the rest"). Omitted when `walk_mode == "per_finding"`.
- **`walk_mode_shifted_at_finding`** is the 1-indexed finding number at which the mode shifted; present ONLY when `walk_mode_source == "command-shape-interruption"`; omitted otherwise.
- **`reproduction_rerun`** (per-resolution, REQUIRED on every CRITICAL entry, absent below CRITICAL — rc02b): the Step 3a step-(0) result, one of the CLOSED values `reproduced` / `not-reproduced` / `cannot-run` (the marker carried a reproduction and it was re-run) or `unreproduced` (the marker carried none); the output or derivation rides `evidence`. A reader that does not know the field ignores it (the `recommendation_options` precedent). Owned by `orbit-address-reviews`' resolution-log shape requirement.
- **`ratified_via`** (per-resolution, REQUIRED for every decision-lane resolution — forked or not): `"chat"` (a user-typed directive ratified the resolution) or `"prompt"` (the optional closure `AskUserQuestion` did). Absent on non-decision-lane resolutions.
- **`resolution`** (per-resolution, conditionally required): the ratified direction verbatim — required when no fork was detected (AI-derived prose options) OR when the direction is off-menu; optional when `recommendation_fork.chosen` names a presented option.
- **`delegation_directive`** (top-level, optional): the user's verbatim mid-walk delegation, present when one was issued.
- **`recommendation_fork`** (per-resolution, OPTIONAL) — present only when detection fired in Step 3b.5; carries the DETECTION data (the ratification channel lives at the entry level): `detected` (always true when present — absence IS the no-fork representation; a `detected: false` variant is never emitted), `source` (`"structured"` | `"heuristic"`), `options_presented`, `chosen` (a presented label, or `"off-menu"` with the entry-level `resolution` carrying the direction), `structured_path_skipped_reason` (optional, malformed-structured-input cases). The retired `discuss_invoked` appears only in pre-D4 logs; readers tolerate both generations.
- **`ripple_cascade`** (per-resolution) — replaces v1's top-level `ripple_flagged_files_aggregate`. Object splits each resolution's ripples into `applied` (paths cascade-edited consistent with the primary fix; recorded for audit) AND `flagged_not_applied` (paths identified as ripple targets but NOT edited, with `{path, reason}` entries). Reasons fall into TWO source categories:
  - **Structural OUT-category reasons** (4 codes): `audit-trail file; cascade skipped by policy` / `baseline spec; add a delta to your current change's specs/<capability>/spec.md to capture this ripple` / `cross-change ripple; cascade scope is current change only` / `safe-exclusion path; never edited`. Fire when cascade was ON and the file matched an OUT prefix.
  - **Mode-suppression reason** (1 code): `--no-cascade suppressed`. Fires uniformly for ALL ripple-flagged files when `--no-cascade` was set, regardless of IN/OUT classification.
- **`sweep`** (per-resolution, on `resolved` entries — rc08a): the five arrays `retired` / `introduced` / `searched` / `scope` / `kept` composed at Step 3d.5. Shape owned by `orbit-address-reviews`' `A resolved walk entry records its sweep evidence`; checks owned by `orbit-emit-composition`'s `The walk write gate checks sweep evidence`. A log written before rc08a carries none.
- **`ripple_miss_of`** (per-resolution, optional — rc08a): `{walk, title, file, kind}` naming the earlier walk entry that missed this finding, written at triage (Step 2). Shape owned by `orbit-address-reviews`' `A ripple miss is attributed by the walk that finds it`; the pointer check by `orbit-emit-composition`'s `A ripple-miss pointer resolves and is counted`.
- **`remedy`**, **`routed_to`** (per-resolution — rc08b): R-crc-6's lane — what the resolution DID, beside the process `lane` — and a REDESIGN's route. Values, dispositions and routes owned by `orbit-address-reviews`' `A walk entry records its remedy, and a REDESIGN leaves the walk`; recorded, never checked at the write gate. A log written before rc08b carries neither.
- **`disagreement`** (per-resolution, optional — rc08b): `{with: {pass, title, file}, test, observed}` on the entry in the LATER pass's log, when the halves of a pair contradicted each other and one test settled it. Shape and rule owned by `orbit-address-reviews`' `A disagreement between the halves of a pair is settled by one test`; recorded, never checked.
- **`ripple_misses`** (top-level, engine-computed — rc08a): the count of this walk's resolutions carrying `ripple_miss_of`; never supplied, per `orbit-emit-composition`'s `A ripple-miss pointer resolves and is counted`.

## Worked-example JSON snippets

### (a) Walk-mode clean run (per_finding default, all IN, no fork)

```json
{
  "walk_mode": "per_finding",
  "resolutions": [
    {
      "title": "<finding>",
      "classification": "trivial_fix",
      "action": "applied edit at design.md:14",
      "ripple_cascade": {
        "applied": ["orbit/changes/foo/design.md", "orbit/changes/foo/tasks.md"],
        "flagged_not_applied": []
      },
      "sweep": { "retired": ["<old wording>"], "introduced": [], "searched": ["<old wording>"], "scope": [], "kept": [] },
      "outcome": "resolved"
    }
  ]
}
```

### (b) Batch-mode with verbal source

```json
{
  "walk_mode": "batch",
  "walk_mode_source": "verbal",
  "resolutions": [/* ... */]
}
```

### (c) Decision-fork ratified by chat directive

```json
{
  "resolutions": [
    {
      "title": "Test coverage gap — file follow-up or extend scope?",
      "classification": "decision_required",
      "recommendation_fork": {
        "detected": true,
        "source": "structured",
        "options_presented": [
          { "label": "A", "body": "file a follow-up issue tracking the v2 polish" },
          { "label": "B", "body": "extend scope to tasks.md" }
        ],
        "chosen": "B"
      },
      "ratified_via": "chat",
      "action": "applied the ratified direction B — added Group 19 to tasks.md",
      "ripple_cascade": { "applied": ["orbit/changes/foo/tasks.md"], "flagged_not_applied": [] },
      "sweep": { "retired": [], "introduced": [{ "path": "orbit/changes/foo/tasks.md", "text": "## 19." }], "searched": ["Group 19"], "scope": [], "kept": [] },
      "outcome": "resolved"
    }
  ]
}
```

### (d) `--no-cascade` — all ripples flagged-not-applied

```json
{
  "walk_mode": "per_finding",
  "resolutions": [
    {
      "title": "<finding>",
      "ripple_cascade": {
        "applied": [],
        "flagged_not_applied": [
          { "path": "orbit/changes/foo/design.md", "reason": "--no-cascade suppressed" },
          { "path": "orbit/changes/foo/tasks.md", "reason": "--no-cascade suppressed" }
        ]
      }
    }
  ]
}
```
