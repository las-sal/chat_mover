# Reference: mode-specific sections

Substitute these into the `## What to read for THIS review` and `## What to look for` sections of the prompt template (`references/prompt-template.md`) based on the resolved `--as` mode.

## Proposal mode — "What to read for THIS review"

```
- orbit/changes/<change-name>/proposal.md
- orbit/changes/<change-name>/design.md
- orbit/changes/<change-name>/tasks.md
- orbit/changes/<change-name>/specs/<capability>/spec.md (every spec under specs/)
- orbit/changes/<change-name>/explore.md (if present)
- orbit/specs/<capability>/spec.md (archived baselines — for delta consistency checks)
```

## Proposal mode — "What to look for" (9 passes)

1. **Structure & Delta Integrity** — required artifacts present; ADDED/MODIFIED/REMOVED/RENAMED valid; `orbit validate` would pass.
2. **Internal Coherence** — proposal aligns with design aligns with specs aligns with tasks. Count/label consistency. No scope creep.
3. **Cross-Doc Coherence** — `CLAUDE.md`, `project.md`, `*_convention.md` still accurate after this change.
4. **Archive Consistency** — ADDED don't contradict baseline; RENAMED FROM names exist; REMOVED not still referenced.
5. **Codegen Readiness** — no implicit requirements; no decisions left to codegen; no ambiguity.
6. **Gap Hunt** — could a fresh AI implement this from these specs alone? Unstated assumptions? Error paths? State transitions?
7. **Drift Hunt** — old vocabulary lingering; consistency with `*_convention.md`.
8. **Inline Review Marker Residue** — any `@review:` markers still present (must be addressed before apply)?
9. **Pre-Handoff Sweep** — anything else before shipping?

## System mode — "What to read for THIS review"

```
- orbit/changes/<change-name>/proposal.md, design.md, tasks.md, specs/
- The change's commit range: git diff <change-start>..HEAD -- . ':!orbit/changes/<change-name>/.orbit-runs' (<change-start> is the commit that first added the change's proposal.md — find it by hash alone: git log --diff-filter=A --format=%h -- orbit/changes/<change-name>/proposal.md | tail -1; commit subjects can carry prior passes' counts, so do not read them)
- orbit/specs/<capability>/spec.md (archived baselines — for baseline-compliance check)
- orbit/lenses/perspectives.md, orbit/lenses/critical-paths.md (judgment layer)
- Code paths touched by the change (cohesion + surface walk)
```

## System mode — "What to look for" (7 passes)

0. **verify-change-style structural check** — tasks done, spec coverage, design adhered (the external AI runs its own equivalent of upstream verify-change). Take scenario test coverage from `orbit status --change <change-name> --scenarios --json` (the scenario map), never by searching test files; an external reviewer who cannot run it reports the check as not run.
1. **Baseline Compliance** — does this change break any archived `orbit/specs/` requirement?
2. **Cohesion** — callers/dependents outside the tasks list. Signature drift, ripple effects, side-effect additions.
3. **Surface Walk** — every CLI / MCP / HTTP / public-function surface in `orbit/specs/` still coherent? Capabilities ARE surfaces; don't redefine them.
4. **Perspective Reviews** — for each named perspective in `orbit/lenses/perspectives.md`, simulate the caller's POV.
5. **Critical-Path Scan** — for each flow in `orbit/lenses/critical-paths.md`, walk end-to-end.
6. **Drift / Residue** — vocabulary residue, stale references, archive-coherence misses.
