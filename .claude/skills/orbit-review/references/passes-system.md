# Reference: system-mode passes (0–6)

Loaded by Step 6 when the resolved mode is `system`.

#### System-mode passes (0–6)

```
PASS                                  WHAT IT CHECKS
─────────────────────────────────────────────────────────────────────
0. verify-change (delegated upstream) tasks done; spec coverage; design
                                       adhered (full verify-change findings)
1. Baseline Compliance                does this change break archived
                                       baseline requirements?
2. Cohesion                           callers/dependents outside the tasks —
                                       signature drift, ripple effects
3. Surface Walk                       every CLI/MCP/HTTP surface still
                                       coherent? (surfaces derived from specs)
4. Perspective Reviews                from each registered caller-perspective
                                       in lenses/perspectives.md
5. Critical-Path Scan                 each flow in lenses/critical-paths.md,
                                       walked end-to-end
6. Drift / Residue                    calls /orbit:audit-drift as a library
```

**Pass 0 — verify-change delegation**. Invoke the `orbit-verify-change` skill via `/orbit:verify <change-name>`. Fold its findings into the scorecard: task-completion + spec-coverage → Completeness; requirement-implementation-mapping + scenario-coverage → Correctness; design-adherence + code-pattern-consistency → Coherence. GRADE the folded findings per `orbit-conventions`' Severity ladder as this body's own (the composing body is their AUTHOR here — not a reader re-grading verify-change, whose own emit is untouched): an incomplete task or an uncovered scenario is WARNING — an implementation built to the artifact would diverge; a violated requirement is CRITICAL ONLY when the violation breaks a user path or loses data, with the requirement and the observed behaviour as its `reproduction` — a violated formatting or documentation requirement with neither consequence is WARNING; a CRITICAL this body cannot reproduce folds as WARNING. If `--skip-verify` set, omit Pass 0 with note `Pass 0: skipped per --skip-verify`.

**Pass 1 — Baseline Compliance**. Read every requirement in archived `orbit/specs/*/spec.md` (not just deltas). Does the change break any baseline behavior? A violated baseline requirement: CRITICAL, per `orbit-conventions`' Severity ladder, ONLY when the violation breaks a user path or loses data — with the violated requirement and the observed behaviour as the reproduction; a violation with neither consequence (a formatting or documentation rule): WARNING, per the ladder — the artifact and the product diverge; a regressed-looking scenario: WARNING, per the ladder — regression RISK is a divergence an implementation could make.

**Pass 2 — Cohesion**. Files the change touched (from `git diff` + tasks list). Walk callers/dependents not in the change's tasks for signature drift, semantic shifts, new side effects. A downstream clearly broken: CRITICAL, per `orbit-conventions`' Severity ladder — a reproducible user path, with the break as the reproduction; caller-side contract drift: WARNING, per the ladder — divergence risk.

**Pass 3 — Surface Walk**. Enumerate surfaces from `orbit/specs/<capability>/spec.md` — **capabilities ARE surfaces**; do not redefine them in lenses. Check each (CLI flags / subcommand names, HTTP routes, MCP tool names, public function signatures) remains coherent after the change. A surface removed unintentionally: CRITICAL only with the removal shown as the reproduction, per `orbit-conventions`' Severity ladder — else WARNING; an inconsistency: WARNING, per the ladder.

**Pass 4 — Perspective Reviews**. If `orbit/lenses/perspectives.md` exists and is non-empty: for each named perspective, simulate typical call patterns from that caller's POV. Awkward, inconsistent, or surprising interactions from that POV: WARNING, per `orbit-conventions`' Severity ladder — a caller built against the artifact would diverge; SUGGESTION below that. If the file is empty or absent, skip Pass 4 with the note `no perspectives defined; skip Pass 4`.

**Pass 5 — Critical-Path Scan**. If `orbit/lenses/critical-paths.md` exists and is non-empty: for each named flow, walk the code end-to-end checking for breakage, regression, or drift. Path breakage: CRITICAL, per `orbit-conventions`' Severity ladder — with the walk that breaks as the reproduction; regression risk: WARNING, per the ladder — the ladder's own two definitions. If absent, skip with `no critical paths defined; skip Pass 5`.

**Pass 6 — Drift / Residue**. Invoke `/orbit:audit-drift` as a library function (via the orbit-audit-drift skill). Fold its findings into the report under the Coherence dimension. Audit-drift handles its own scorecard and severity assignment; preserve those (a statement site the Severity ladder names as a known limit — not this body's to re-grade).

##### `--fast` subset (system mode)

When `--fast` is set, run Passes 0, 1, 6. Report remaining as `skipped per --fast`. Combining `--fast --skip-verify` runs only Passes 1 and 6.


#### System-mode mapping

| Dimension | Passes contributing |
|---|---|
| **Completeness** | Pass 0 (verify-change completeness portion: task-completion + spec-coverage), Pass 5 (critical-paths existence) |
| **Correctness** | Pass 0 (verify-change correctness portion: requirement-implementation-mapping + scenario-coverage), Pass 1 (Baseline), Pass 2 (Cohesion), Pass 5 (critical-paths working) |
| **Coherence** | Pass 0 (verify-change coherence portion: design-adherence + code-pattern-consistency), Pass 3 (Surface Walk), Pass 4 (Perspective Reviews), Pass 6 (Drift/Residue from audit-drift) |

