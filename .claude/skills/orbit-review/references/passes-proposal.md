# Reference: proposal-mode passes (9)

Loaded by Step 6 when the resolved mode is `proposal`. Pass CONTENT is unchanged by the reference split (an organizational move only).

#### Proposal-mode passes (9)

```
PASS                                  WHAT IT CHECKS
─────────────────────────────────────────────────────────────────────
1. Structure & Delta Integrity        artifacts present; delta sections valid;
                                       orbit validate passes
2. Internal Coherence                 proposal/design/specs/tasks align;
                                       counts consistent; no scope creep
3. Cross-Doc Coherence                CLAUDE.md / project.md / *_convention.md
                                       still accurate after this change
4. Archive Consistency                ADDED don't contradict baseline; RENAMED
                                       FROM exists; REMOVED not still referenced
5. Codegen Readiness                  no implicit requirements; no ambiguity;
                                       no decisions left to codegen
6. Gap Hunt (generative completeness) could a fresh AI implement this from
                                       these specs alone? unstated assumptions?
                                       error paths? state transitions?
7. Drift Hunt                         old vocabulary lingering; consistency
                                       with *_convention.md
8. Inline Review Marker Residue       any @review: markers still present?
                                       (a BLOCK — must address before apply)
9. Pre-Handoff Sweep                  small things missed on first read
```

**Pass 1 — Structure & Delta Integrity**. Run `orbit validate "<name>"`; confirm required artifacts present; check delta sections (ADDED/MODIFIED/REMOVED/RENAMED Requirements) follow the delta-spec format. A validate failure is a BLOCK, per `orbit-conventions`' Severity ladder — it stops apply whatever it would cost a user, so it is composed into the emit's `blocks` array, never into `findings[]` and never a scorecard cell; a delta-section anomaly: WARNING, per the ladder — an implementation built to a malformed delta would diverge; a cosmetic issue: SUGGESTION.

**Pass 2 — Internal Coherence**. Compare proposal / design / specs / tasks: scope alignment, design-to-requirement mapping, requirement-to-task coverage, count consistency, no scope creep. A spec requirement with no task: WARNING, per `orbit-conventions`' Severity ladder — an implementation built to the artifact would omit it (it gates; it buys no further independent pass); count/label disagreement: WARNING, per the ladder — the same divergence risk.

**Pass 3 — Cross-Doc Coherence**. Will `CLAUDE.md`, `orbit/project.md`, `*_convention.md` files still be accurate post-apply? Look for renamed concepts referenced under old names, new capabilities missing from project context, conventions contradicting deltas. Stale post-apply context: WARNING, per `orbit-conventions`' Severity ladder — a reader built to the stale doc would diverge; enrichment: SUGGESTION.

**Pass 4 — Archive Consistency**. ADDED requirements don't conflict with archived baseline; RENAMED FROM names exist in archive; REMOVED requirements aren't still referenced. A direct contradiction of baseline: CRITICAL only with a reproduction naming the baseline behaviour that breaks, per `orbit-conventions`' Severity ladder — else WARNING; a dangling reference: WARNING, per the ladder.

**Pass 5 — Codegen Readiness**. Per requirement: precise enough that two implementers produce the same code? Inputs/outputs/side effects stated? Hidden assumptions ("the obvious path", "the usual default") made explicit? Ambiguity that could split implementations: WARNING, per `orbit-conventions`' Severity ladder — this is the ladder's WARNING definition itself.

**Pass 6 — Gap Hunt (generative completeness)**. Per requirement in spec deltas, probe: (a) unstated assumptions an implementer would have to invent? (b) error/edge-case paths specified, not just happy paths? (c) state transitions explicit, including invalid ones? (d) "X SHALL do Y" — Y precise enough? Cite file:line + the specific gap; suggest concrete spec additions.

**Pass 7 — Drift Hunt**. Search artifacts for old vocabulary the change is replacing. Grep change directory AND project docs (`*_convention.md`, `project.md`, `CLAUDE.md`). Old vocabulary in a delta itself: WARNING, per `orbit-conventions`' Severity ladder — an implementation built to the delta would carry the old name; old vocabulary in project docs: WARNING, per the ladder — the same divergence, one layer out.

**Pass 8 — Inline Review Marker Residue**. Grep change directory for `@review:` markers. **Actual unresolved markers** in artifact content → a BLOCK, per `orbit-conventions`' Severity ladder (must address before applying): composed into the emit's `blocks` array — one single-line entry naming the marker and its file:line — never into `findings[]`, never a scorecard cell; nothing stops on it mechanically (the ladder's known limit), so the report's Blocks section is what the human reads before apply. **Documentation appearances** inside fenced code blocks, inline-code spans, or explicit "example" prose contexts → NOT findings. When ambiguous, list the marker as a block and grade nothing — the user decides during `/orbit:address-reviews`.

**Pass 9 — Pre-Handoff Sweep**. Final read asking "what would I be embarrassed to ship?" — awkward wording, stale TODO/FIXMEs in artifacts, inconsistent capitalization, examples that don't match prose. Almost always SUGGESTION, per `orbit-conventions`' Severity ladder — nothing here breaks a path or splits an implementation.

##### `--fast` subset (proposal mode)

When `--fast` is set, run only Passes 1, 7, 8. Report remaining passes as `skipped per --fast`.


#### Proposal-mode mapping

| Dimension | Passes contributing |
|---|---|
| **Completeness** | 1 (Structure & Delta), 5 (Codegen Readiness), 6 (Gap Hunt) |
| **Correctness** | 2 (Internal Coherence), 4 (Archive Consistency) |
| **Coherence** | 3 (Cross-Doc), 7 (Drift Hunt), 8 (Inline Marker Residue), 9 (Pre-Handoff) |

