# Reference: archive run-summary schema

The orbit additions to `/orbit:archive` write a JSON summary to `orbit/changes/archive/<YYYY-MM-DD>-<change-name>/.orbit-runs/archive-<TS>.json` after a successful archive operation (the `<YYYY-MM-DD>-` prefix is added by upstream's archive move step). An aborted archive writes NO summary.

## Universal spine inheritance

The spine every emit carries is owned by `orbit-conventions`' `Internal-run JSON summary format` requirement, and is not restated here; the write gate refuses every field the engine composes. For archive, `final_assessment` is the payload's narrative of what was archived (e.g. `"Archived <change-name> to <archive_path>."`), and `next_recommended` is the engine's post-archive line, chosen by the archived change's `architecture:` citation: a cited change whose doc exists gets `/orbit:architect <doc> — change archived; review stage <stage> and take up the program's next stage, …`, and any other change the uncited line shown in the block below (per `orbit-emit-composition`).

The schema below documents the per-command extensions ADDED to that spine (`archive_path`, `audit`, `sync_specs`, `unresolved_markers`, `user_decision`, `warnings`), per the `kind: "lifecycle"` extensions in `orbit-conventions`, plus the `consent` field (D1), the conditional `fingerprint_overridden` / `fingerprints_unverified` (C2) fields, the conditional `judgements` array (rc04a), and the conditional `deferred_validations` array (rc10). A `continuation`/`proceed` entry of that array is the SOLE record of a proceed-anyway past a gate the Step 3.4 prompt listed (the gate set `orbit-engine-gates`' `Inflection-prompt override contract` owns): the C1-era field it once accompanied is RETIRED (rc04c), and emits written before that retirement carry it as a PRIOR GENERATION that readers continue to accept.

**Note on `sync_specs`**: this field reports the result of the archive flow invoking the `orbit-sync-specs` upstream primitive (kept upstream-verbatim per `orbit-conventions`' `Generated-file disposition`).

## Schema

```json
{
  "command": "archive",
  "timestamp": "<ISO-8601>",
  "change": "<change-name>",
  "final_assessment": "<narrative of what was archived>",
  "next_recommended": "/orbit:architect <name> — change archived; plan the next piece of work, or run /orbit:audit-drift for a project-wide drift check.",
  "kind": "lifecycle",
  "archive_path": "orbit/changes/archive/<YYYY-MM-DD>-<change-name>/",
  "audit": {
    "ran": true | false,
    "failure_reason": "<text or null>",
    "findings_summary": { "critical": 0, "warning": 0, "suggestion": 0 },
    "summary_path": "<path to the audit-drift-<TS>.json summary, or null if not run>"
  },
  "audit_skipped_via_flag": true,
  "sync_specs": {
    "ran": true | false,
    "skipped_reason": "<text or null>",
    "capabilities_updated": ["<capability name>"],
    "added": 0,
    "modified": 0,
    "removed": 0,
    "renamed": 0
  },
  "unresolved_markers": ["<file>:<line> — <marker text>"],
  "user_decision": "proceeded_with_no_critical" | "proceeded_despite_critical" | "audit_skipped_via_flag",
  "consent": "user-invoked" | "prompted",
  "pr_url": "<D6, optional: the attached PR's URL as observed by the read-only preflight>",
  "pr_state": "draft" | "ready",  // D6, optional: OBSERVED at preflight; elided when unobservable OR positively invalid (closed/merged/retargeted) — that condition is off the draft/ready axis
  "judgements": [
    { "kind": "continuation", "disposition": "proceed", "formed_against": ["<independent pass TS>"], "reasoning": "<prose>", "ratified_by": "ai|user", "gate": "<a gate the Step 3.4 prompt listed>", "gate_state": "<unpassed|stale|blocked>", "gate_reason": "<gate reason at decision time>" },
    { "kind": "readiness", "formed_against": ["<independent pass TS>"], "disposition": "ready|not-ready", "reasoning": "<prose>", "ratified_by": "ai|user", "accepted": [ { "claim": "<what was left unresolved>", "why": "<why that was acceptable>" } ] }
  ],
  "fingerprint_overridden": [
    { "capability": "<name>", "requirement": "<name>", "base_hash": "sha256:<hex>", "live_hash": "sha256:<hex>" }
  ],
  "fingerprints_unverified": [
    { "capability": "<name>", "requirement": "<name>" }
  ],
  "deferred_validations": [
    { "task": "<task id>", "why": "<why it was not observed at this seam>", "when": "<the moment it will be>", "where": "<the place>" }
  ],
  "warnings": [
    "<text — e.g., 'Archived with 2 incomplete artifacts'>"
  ]
}
```

## Example payload

A payload file the archive writes after the move — here an archive that took every conditional branch at once (`--skip-audit`, a proceed-anyway past an unpassed `review-system` gate, a fingerprint override, an unverified requirement, a deferred user-validation task, an attached draft PR), so one payload carries every key the block documents. Real JSON, accepted by `orbit emit archive --change <name>` against the ARCHIVED directory, carrying no engine-owned key. An archive that took none of those branches simply omits the conditional keys. A test submits this block, unchanged, through the write gate, with the archived trail seeded with the pass its `formed_against` arrays name and the archived `tasks.md` with the `(User-validation` task its deferral names (`orbit-emit-composition`'s `Payload schema references are proven by execution`).

```json example archived
{
  "final_assessment": "Archived add-detail-flag to orbit/changes/archive/2026-10-04-add-detail-flag/.",
  "archive_path": "orbit/changes/archive/2026-10-04-add-detail-flag/",
  "audit": { "ran": false, "failure_reason": null, "findings_summary": { "critical": 0, "warning": 0, "suggestion": 0 }, "summary_path": null },
  "audit_skipped_via_flag": true,
  "sync_specs": {
    "ran": true,
    "skipped_reason": null,
    "capabilities_updated": ["orbit-status-output"],
    "added": 1,
    "modified": 2,
    "removed": 0,
    "renamed": 0
  },
  "unresolved_markers": [],
  "user_decision": "audit_skipped_via_flag",
  "consent": "user-invoked",
  "pr_url": "https://github.com/example/repo/pull/42",
  "pr_state": "draft",
  "judgements": [
    {
      "kind": "continuation",
      "disposition": "proceed",
      "formed_against": ["2026-10-03T14-20-00Z"],
      "reasoning": "The one unresolved WARNING is a scenario title's wording; another pass would not change what the archive syncs.",
      "ratified_by": "user",
      "gate": "review-system",
      "gate_state": "unpassed",
      "gate_reason": "one WARNING unresolved on the external pass"
    },
    {
      "kind": "readiness",
      "formed_against": ["2026-10-03T14-20-00Z"],
      "disposition": "ready",
      "reasoning": "The external pass found nothing the walk left open beyond the accepted residual.",
      "ratified_by": "ai",
      "accepted": [{ "claim": "The --detail flag is untested on Windows paths", "why": "No Windows runner exists here; recorded for the first adopter report." }]
    }
  ],
  "fingerprint_overridden": [
    { "capability": "orbit-status-output", "requirement": "Detail flag", "base_hash": "sha256:1111111111111111111111111111111111111111111111111111111111111111", "live_hash": "sha256:2222222222222222222222222222222222222222222222222222222222222222" }
  ],
  "fingerprints_unverified": [
    { "capability": "orbit-status-output", "requirement": "Compact flag" }
  ],
  "deferred_validations": [
    { "task": "5.3", "why": "The flag's first real use is the next change's review, after this one merges.", "when": "the next change that runs orbit status --detail", "where": "that change's review cycle" }
  ],
  "warnings": ["Sync skipped one MODIFIED block already byte-equal to the baseline"],
  "model": "claude-opus-5-5"
}
```

## Field notes

- **`audit.ran`** = `false` either because `--skip-audit` was set (then the top-level `audit_skipped_via_flag: true` is recorded) or because audit-drift failed (then `failure_reason` is set). The two cases are disambiguated by those flags.
- **`audit.findings_summary`** is the severity count (`critical` / `warning` / `suggestion`) of the pre-archive sweep's findings — the archive's own record; the standalone audit-drift emit carries no severity summary.
- **`audit_skipped_via_flag`** (top-level boolean): recorded as `true` only when `/orbit:archive --skip-audit` was used; omit the field otherwise. This is the flat field the skill body and the `orbit-archive-modifications` baseline require — it is NOT nested inside `audit`.
- **`sync_specs.capabilities_updated`** lists capability names whose `orbit/specs/<capability>/spec.md` was edited; the delta counts (`added`/`modified`/`removed`/`renamed`) sit DIRECTLY under `sync_specs`, mirroring `orbit-conventions`' canonical lifecycle example.
- **`unresolved_markers`** is an ARRAY of the `@review:` markers still present when the archive proceeded (empty array when none) — one `"<file>:<line> — <marker text>"` entry per marker. Marker-prompt outcomes that halt the archive write no summary at all.
- **`user_decision`** captures the AUDIT-drift prompt decision and has exactly three values: `proceeded_with_no_critical` (clean audit or warnings only), `proceeded_despite_critical` (user explicitly proceeded past CRITICAL findings), `audit_skipped_via_flag` (`--skip-audit` used). An abort at the critical-findings prompt cancels the archive and writes no summary.
- **`pr_url` / `pr_state`** (D6, per `orbit-pr-lifecycle`) record the attached PR's identity and the state the READ-ONLY PREFLIGHT observed — normally `"draft"`, and truthfully `"ready"` when the PR was already flipped by the USER at an earlier point (including at a prior program's arc-done, for an adopted program PR; never by a stage). The preflight runs BEFORE this emit, so the value is an OBSERVATION, never a forward-looking claim about the flip the tail is about to perform. On POSITIVE invalidation `pr_state` is ELIDED while `pr_url` is still recorded — the identity that was validated and rejected. Both absent for UNATTACHED changes; present whenever an attachment resolves, EVEN IF `pr:` now reads `never` (attachment authority).
- **`consent`** (D1, per `orbit-lifecycle-consent`) records the invocation's consent story from the Step 0 provenance check: `"user-invoked"` (user-typed `/orbit:archive`, or a user-typed `/orbit:bulk-archive` whose flow confirmed the batch) or `"prompted"` (AI-mediated arrival, consent prompt fired, user proceeded). Exactly two values — a consent Abort writes NO summary. REQUIRED on every post-capability archive emit; absence is the audit-drift tripwire condition. DISTINCT from `user_decision` (audit outcome), the `continuation` judgement entry (cadence decision), and the fingerprint fields (content guard).
- **`fingerprint_overridden`** (C2) is present ONLY when the Step 3.45 fingerprint check reported `diverged` requirement(s) and the user chose **Proceed anyway** at the divergence inflection prompt — one `{capability, requirement, base_hash, live_hash}` entry per diverged requirement, captured at decision time. Absent when no fingerprint override occurred; REQUIRED when proceed-anyway was chosen. DISTINCT from the `continuation` judgement entry (review-cadence decision) and `user_decision` (audit-drift outcome).
- **`fingerprints_unverified`** (C2) is present ONLY when the archive proceeded past requirement(s) whose fingerprint status was `unverified` (no base recorded — e.g. a hand-authored or pre-C2 delta) — one `{capability, requirement}` entry each. Absent when every touched requirement was verified.
- **`judgements`** (rc04a) is present ONLY when a CADENCE JUDGEMENT was taken at this seam — a decision that holds a CADENCE POSITION, whether or not independent output existed to cite; the key is OMITTED when none was, so its presence means a judgement happened. The archive is the ONE emit admitting both kinds: a `continuation/proceed` (composed at Step 3.4 as the SOLE record of a proceed-anyway, ONE per gate the prompt listed — the gate set `orbit-engine-gates`' `Inflection-prompt override contract` owns — carrying that gate, its state and its reason at decision time as `gate`/`gate_state`/`gate_reason`) and the terminal `readiness` (Step 5.5). `formed_against` may be EMPTY only on a `continuation`/`proceed`, and only when the trail carries no accepted independent pass earlier than this emit — the write gate refuses an empty citation naming the latest preceding pass otherwise. Which passes count, and when an empty citation is legal, is `orbit-run-summary-emit`'s totality rule; this reference names it and does not restate it. DISTINCT from `user_decision` (the audit-drift outcome) and from `warnings` (SEAM-ARISING process notes, formed against no pass and holding no cadence position). A `not-ready` readiness is an ARCHIVE-TIME DISSENT — the author's own judgement, `ratified_by` either `ai` or `user` — and it RECORDS without blocking; Step 5.65 states it in the completion readout.
- **`deferred_validations`** (rc10) is present ONLY when Step 3.2 DEFERRED an unchecked `(User-validation` task — one `{task, why, when, where}` entry each: the task id, and non-empty prose naming why it was not observed at this seam, the moment it will be, and the place. Its refusals are `orbit-archive-modifications`' `User-validation closure at the archive seam`'s production; the write gate checks the id set against the archived `tasks.md`, never whether the prose is true. An OBSERVED task is checked in `tasks.md` and carries no entry. DISTINCT from `warnings`, which no longer carries a validation handoff as an incomplete task.
- **`warnings`** captures the upstream warning surfaces (incomplete artifacts, incomplete tasks other than user-validation ones, sync skipped) — kept human-readable since they vary in shape.
