# Reference: rarely-used review flags — `--mark` / `--parallel` / `--focus`

Loaded only when one of these flags is set (D5 body-economy pass; content moved from the body verbatim).

### 11. (Optional) `--mark` writer (proposal mode only)

If `--mark` is set and the mode is `proposal`:

For each finding with severity CRITICAL or WARNING (skip SUGGESTION by default; a BLOCK is not a finding and gets no marker):
- Locate the finding's `file:line`.
- Insert a `@review: <finding title — recommendation>` marker at that line.
  - In markdown: append after existing content on the line, or as a sibling line if structure prevents inline insertion.
  - In code: wrap in the file's comment syntax (e.g., `// @review: …`, `# @review: …`).
- After insertion, sweep the modified artifacts for double-insertion or content overwrites; the change-completeness discipline applies.

In system mode, `--mark` is accepted but ignored with the note `--mark writes to source files is v2; ignored for v1 system-mode runs.`

### 12. `--parallel` execution

If `--parallel` is set:

- Proposal mode: spawn subagents for Passes 2 (Internal Coherence), 4 (Archive Consistency), 6 (Gap Hunt). Run Passes 1, 3, 5, 7, 8, 9 in the main context.
- System mode: spawn subagents for Passes 2 (Cohesion), 3 (Surface Walk), 4 (Perspectives), 5 (Critical Paths). Run Passes 0, 1, 6 in the main context.

Each subagent gets a focused brief (the pass description + the relevant context files). Merge findings into the unified report. Subagents inherit the four execution disciplines.

### 13. `--focus` lens

Lens-specific emphasis (additive — does NOT skip other passes):

| Lens | Mode | Passes emphasized | Why |
|---|---|---|---|
| `rename` | proposal | 7 (Drift), 3 (Cross-Doc), 4 (Archive) | renames leak old names |
| `flip` | proposal | 2 (Internal Coherence on direction), 5 (Codegen Readiness) | direction must be unambiguous |
| `refactor` | both | proposal: 4, 7, 3; system: 2, 6 | old shape ripples into callers/docs |
| `extension` | proposal | 6 (Gap Hunt) | coverage must match existing depth |
| `hotpath` | system | 5 (Critical-Path Scan) | landed work touched perf/race-sensitive paths |

When `--focus <lens>` is set, run all passes but apply elevated rigor (more probes, longer cite chains) to the listed ones.
