# Reference: audit-drift worked example (standalone, full depth)

## Worked example (standalone, full depth)

```
## Audit-drift report

Context: standalone
Depth: full
Flags: none

### Summary

| Category | Critical | Warning | Suggestion |
|----------|----------|---------|------------|
| 1 — Vocabulary residue | 0 | 2 | 0 |
| 2 — Lens staleness     | 0 | 1 | 0 |
| 3 — Cross-doc          | 1 | 0 | 0 |
| 4 — Archive coherence  | 0 | 0 | 0 |

Scorecard rollup:

| Dimension    | Critical | Warning | Suggestion |
|--------------|----------|---------|------------|
| Completeness | 0        | 0       | 0          |
| Correctness  | 0        | 3       | 0          |
| Coherence    | 1        | 0       | 0          |

### Findings

#### CRITICAL
- **[Category 3] CLAUDE.md:14** — Claims "all surface tools live under `tools/`"; current spec `orbit/specs/surface-tools/spec.md:8` says they live under `surface/`.
  Recommendation: update CLAUDE.md to match the spec (the spec is canonical).

#### WARNING
- **[Category 1] orbit/specs/host-lifecycle/spec.md:23** — Stale `BridgeServer` reference (renamed to `HostLifecycle` in 2026-03 archived change `rename-bridge-server`).
  Recommendation: delta this file in a future change OR apply a hotfix commit replacing the term.
- **[Category 1] orbit/specs/host-lifecycle/spec.md:71** — Same stale `BridgeServer` reference.
  Recommendation: same as above; both occurrences in this spec.
- **[Category 2] orbit/lenses/perspectives.md:8** — Perspective "API client" references `<api-server>` capability; no `orbit/specs/api-server/` exists.
  Recommendation: rename the surface ref to match the current capability name OR remove the perspective if obsolete.

### Final assessment

1 critical issue(s) found.

Run summary: orbit/.orbit-runs/audit-drift-2026-05-18T15-04-11Z.json
```
