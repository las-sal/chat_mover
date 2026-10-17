---
name: orbit-propose
description: Propose a new change with all artifacts generated in one step. Use when the user wants to quickly describe what they want to build and get a complete proposal with design, specs, and tasks ready for implementation.
license: MIT
compatibility: Requires orbit CLI.
metadata:
  author: openspec
  version: "1.0"
  generatedBy: "2.0.1"
---

Propose a new change - create the change and generate all artifacts in one step.

I'll create a change with artifacts:
- proposal.md (what & why)
- design.md (how)
- tasks.md (implementation steps)

When ready to implement, run /orbit:apply

---

**Input**: The user's request should include a change name (kebab-case) OR a description of what they want to build.

**Steps**

1. **If no clear input provided, ask what they want to build**

   Use the **AskUserQuestion tool** (open-ended, no preset options) to ask:
   > "What change do you want to work on? Describe what you want to build or fix."

   From their description, derive a kebab-case name (e.g., "add user authentication" → `add-user-auth`).

   **IMPORTANT**: Do NOT proceed without understanding what the user wants to build.

2. **Create the change directory**
   ```bash
   orbit new change "<name>"
   ```
   This creates a scaffolded change at `orbit/changes/<name>/` with `.openspec.yaml`.

3. **Get the artifact build order**
   ```bash
   orbit status --change "<name>" --json
   ```
   Parse the JSON to get:
   - `applyRequires`: array of artifact IDs needed before implementation (e.g., `["tasks"]`)
   - `artifacts`: list of all artifacts with their status and dependencies

4. **Create artifacts in sequence until apply-ready**

   Use the **TodoWrite tool** to track progress through the artifacts.

   Loop through artifacts in dependency order (artifacts with no pending dependencies first):

   a. **For each artifact that is `ready` (dependencies satisfied)**:
      - Get instructions:
        ```bash
        orbit instructions <artifact-id> --change "<name>" --json
        ```
      - The instructions JSON includes:
        - `context`: Project background (constraints for you - do NOT include in output)
        - `rules`: Artifact-specific rules (constraints for you - do NOT include in output)
        - `template`: The structure to use for your output file
        - `instruction`: Schema-specific guidance for this artifact type
        - `outputPath`: Where to write the artifact
        - `dependencies`: Completed artifacts to read for context
      - Read any completed dependency files for context
      - Create the artifact file using `template` as the structure
      - Apply `context` and `rules` as constraints - but do NOT copy them into the file
      - Show brief progress: "Created <artifact-id>"

   b. **Continue until all `applyRequires` artifacts are complete**
      - After creating each artifact, re-run `orbit status --change "<name>" --json`
      - Check if every artifact ID in `applyRequires` has `status: "done"` in the artifacts array
      - Stop when all `applyRequires` artifacts are done

   c. **If an artifact requires user input** (unclear context):
      - Use **AskUserQuestion tool** to clarify
      - Then continue with creation

5. **Show final status**
   ```bash
   orbit status --change "<name>"
   ```

**Output**

After completing all artifacts, summarize:
- Change name and location
- List of artifacts created with brief descriptions
- What's ready: "All artifacts created! Ready for implementation."
- Prompt: "Run `/orbit:apply` or ask me to implement to start working on the tasks."

**Artifact Creation Guidelines**

- Follow the `instruction` field from `orbit instructions` for each artifact type
- The schema defines what each artifact should contain - follow it
- Read dependency artifacts for context before creating new ones
- Use `template` as the structure for your output file - fill in its sections
- **IMPORTANT**: `context` and `rules` are constraints for YOU, not content for the file
  - Do NOT copy `<context>`, `<rules>`, `<project_context>` blocks into the artifact
  - These guide what you write, but should never appear in the output

**Guardrails**
- Create ALL artifacts needed for implementation (as defined by schema's `apply.requires`)
- Always read dependency artifacts before creating a new one
- If context is critically unclear, ask the user - but prefer making reasonable decisions to keep momentum
- If a change with that name already exists, ask if user wants to continue it or create a new one
- Verify each artifact file exists after writing before proceeding to next

---

# Orbit additions

The sections below describe orbit-specific additions on top of upstream's standalone propose flow. The upstream content above is as `orbit-conventions`' `Generated-file disposition` records it. Orbit adds a **consume mode** that activates when `orbit/explore/<name>/explore.md` exists from a prior `/orbit:explore` session — the exploration becomes the authoritative seed for artifact generation rather than asking the user for a description.

## Four execution disciplines (epitome)

The four disciplines from `orbit-conventions`, embedded per body; detail lives where each fires.

- **Read-before-reference (authoring-time)**: read a construct's actual definition before naming it; unverifiable → ask or leave a `@review:` marker, never guess.
- **Change completeness (modification-time)**: apply substantive modifications fully across ALL affected artifacts; after mechanical edits, sweep for residue AND new bugs the replacement introduced.
- **Pushback (review-time)**: verify each flagged issue against current state before acting; suppress stale findings with evidence rather than re-fixing already-fixed state.
- **No-chaining (turn boundary)**: invoke only the orbit workflow commands the user's message explicitly requests; completing a command ENDS the turn at the position readout + the engine's eligibility line — gate `passed` means *eligible*, not *commanded*.

## Mode detection (NEW Step 0 — runs before upstream Step 1)

Before any upstream step, detect whether to run in consume mode or fall through to upstream standalone behavior:

1. **Check for staging directory**: does `orbit/explore/<name>/explore.md` exist?
   - **If user provided `<name>`** as the argument: check that specific name.
   - **If user provided no name** but exactly one LIVE staging directory exists under `orbit/explore/`: propose that name to the user via `AskUserQuestion`. On accept, treat as if the name was provided. A directory whose `explore.md`'s FIRST NON-BLANK line carries the `concluded` token (per `orbit-conventions`' status-header production — read that line, never `head -1`) is NOT a candidate; count LIVE staging directories only, so one live directory beside any number of concluded ones proposes the live name without a pick prompt.
   - **If user provided no name and zero or multiple LIVE staging directories exist**: prompt user to specify a name (zero) or pick one (multiple).

2. **Check for conflict**: do both `orbit/explore/<name>/` AND `orbit/changes/<name>/` exist?
   - If yes AND the staging `explore.md`'s FIRST NON-BLANK line carries the `concluded` token → **REFUSED before any prompt**: print `both <staging path> (concluded <YYYY-MM-DD>) and <change path> exist — a second claim on one truth; propose neither deletes nor overwrites a concluded record; resolve by hand` and STOP. None of the three choices below is offered, nothing is deleted, overwritten or moved.
   - If yes and the staging file is live, halt with a conflict report and prompt via `AskUserQuestion`:
     - **Regenerate from explore** — overwrite the existing change directory with new artifacts.
     - **Continue from change** — discard the explore staging directory, proceed in standalone-like mode on the existing change.
     - **Abort** — do nothing; user decides next.

3. **Resolve mode** (precedence: the conflict check above fires first — its concluded refuse, then its prompt; then, in this order):
   - Staging exists, no unresolved conflict, and `explore.md`'s FIRST NON-BLANK line carries the `concluded` token (per `orbit-conventions`' status-header production — read that line, never `head -1`) → **REFUSED**. Print `this exploration concluded on <YYYY-MM-DD>. Re-entry: <the live CONCLUDED entry's Re-entry: slot, verbatim — first in file order when two entries carry one, as the readout resolves it; (no Re-entry: slot found) when none>` and STOP: no `AskUserQuestion`, no `orbit new change`, no metadata, no move. The PR layer's phase 1 (select + switch) is never reached, because it runs AFTER this step — a refused promotion cuts no branch. A concluded exploration is done: propose neither reopens it nor offers to (the reopen edit belongs to the explore body, per `orbit-explore-modifications`' re-entry requirement — pointed at, not restated here).
   - Staging exists, no unresolved conflict, header NOT `concluded` (the `exploring` token, or neither token) → **consume mode** (continue with consume-mode flow below; skip upstream Step 1).
   - No staging → **standalone mode** (skip the consume-mode flow; resume at upstream Step 1).

## Consume-mode flow

Replaces upstream Step 1 (the "ask what to build" prompt). All later upstream steps (create change directory, generate artifacts in dependency order) still run, but they read the exploration material rather than prompting the user.

### Step 0a — Validate `explore.md` structure

Read `orbit/explore/<name>/explore.md`. Check for the sections the format's owner lists, in its order — Premise, Mechanism, Decisions, Open questions, Considered & out, References.

*Mirror of `orbit-conventions`' `explore.md` format requirement — the owner of this list; a parity test holds this copy byte-equal.*

- **All listed sections present** → proceed normally.
- **Missing one or more sections** → warn the user naming the missing sections; prompt via `AskUserQuestion` to confirm proceed-anyway (default: proceed). An absent `## Mechanism` section is a format note like any other — and on proceed, every live rule is UNACCOUNTED (state `absent`) in the record Step 0c.6 writes.
- **Cannot read or parse** → halt with a clear error; user fixes and re-invokes.

### Step 0b — Handle Open questions

For each entry in the Open questions section, prompt the user via `AskUserQuestion` with three options:

- **Resolve now** — user provides a resolution. The resolution becomes a Decision: appended to the Decisions section of `explore.md` (the file is updated, not just the in-memory parse), and used to inform generated artifacts. The appended entry is CONFORMING — written in the entry form below, `Kind:` per the answer's normative force (a rule PRESCRIBES across a set of situations; a fact describes one world; a scope choice is one-off), `Disposition: live` — never a bare bullet: an entry without the opener has no ID and reads as an open rule nobody can name. When the answer is a RULE, tell the user at the prompt that no Mechanism entry is authored at propose, so the rule will stand as an open domain (state `absent`) in the Step 0c.6 record.
- **Defer as `@review:` marker** — a `@review: <question text>` marker is inserted at the most relevant location in the generated artifacts (typically `design.md` or the relevant spec). The Open question is moved to a "Deferred to markers" subsection of Open questions in `explore.md` (or tagged `deferred`).
- **Abandon** — the question is moved to Considered & out with a brief rationale; no marker is created.

**Bulk handling**: if more than ~5 Open questions exist, offer "Resolve all (walk one by one)" / "Defer all (mark in artifacts)" / "Abandon all" / "Walk each individually" via `AskUserQuestion`. Default: walk each individually.

The entry form (a checked mirror of `orbit-conventions`' "Decision entry identity and classification" — the owner; the grammar module supplies it):

```
- **<YYYY-MM-DD> — <ID>: <title>** <prose…>            the opener; the ID slot; <ID> ::= D-[a-z0-9]+-[0-9]+, unique within the file
  Kind: rule | fact | scope                               ^\s*(?:[-*+]\s+)?Kind:\s*(rule|fact|scope)\s*$
  Disposition: live | superseded <ID or pointer> | assigned <stage-id>     same optional bullet prefix as Kind:
  Re-entry: <what would reopen it>                        concluded entries only; exactly one LIVE entry carries it
```

**The Mechanism read — after this step's LAST write to `explore.md`, before generation.** Read the `## Mechanism` section by the grammar `orbit-conventions`' Mechanism-entry requirement owns — carried here as a checked mirror, because your repository may not hold that spec (the grammar module supplies it; a parity test holds it equal to the owner):

```
## Mechanism
### <ID> — <rule title>              an entry; ends at the next heading of level 1–3, or EOF
Domain: <the set, in one line>
| member | covered by |              the enumeration, as a table (R-crc-7: decision tables); at least one member row; cells follow GFM — `\|` is a literal pipe, never a separator
Closure: <TOKEN>[ — <justification>]   <TOKEN> ::= DERIVED | SOURCED | BOUNDED, matched from line start to the first ` — ` or end of line
Residual kind: <what lies outside>            required iff BOUNDED, forbidden otherwise
Residual method: <how a member would be found> required iff BOUNDED, forbidden otherwise
Moves:
- <MOVE>: applied — <what it found>   |   - <MOVE>: not applied — <reason>     (` — ` is the literal em-dash)
                                      nine lines, one per move, each move exactly once
### Case <n> — <title>               evidence, free-form, cited by move lines by name
```

Take from it the entry set, each entry's `Closure:` token, and a BOUNDED entry's two residual lines VERBATIM; Step 0c.6 says what conformance to it decides. Read NO prior explore emit as a source or cross-check — git keeps no modification time, so no trail record can be shown to describe the file's current bytes — and fire none: propose's one emit is its completion emit (`orbit-run-summary-emit`'s one-shot rule, untouched). Your reading of the file is the SOLE source of the Step 0c.6 record, whose header always says so.

### Step 0c — Section-to-artifact mapping

When generating artifacts in upstream Step 4, apply this mapping:

| `explore.md` section | Feeds into |
|---|---|
| **Premise** | `proposal.md`'s "Why" / motivation section |
| **Decisions** | Spec requirements + `design.md` decisions + `tasks.md` task seeds. **Preserve specific decision wording** where artifact format permits; don't paraphrase. |
| **Open questions** (resolved at Step 0b) | Promoted to Decisions and treated as above |
| **Open questions** (deferred at Step 0b) | `@review:` markers in `design.md` or the relevant spec |
| **Mechanism** | Per Step 0c.6 — the `Mechanism section consumption` requirement's decision table (a partition over the owner's live-rule status × the readout's accounting state) and the `## Mechanism → artifacts` record |
| **Considered & out** | `design.md`'s "Alternatives considered" section (prevents future rediscovery) |
| **References** | Read during artifact generation as context; cited in `design.md` where relevant; not copied verbatim |
| **Decisions + References (codebase leanings)** | Seed `design.md`'s `## Touchpoints` section (authored below) |

When `design.md` references background or decisions originally from `explore.md`, **cite the source** (`see explore.md`) rather than paraphrasing without attribution.

### Step 0c.5 — Author `## Touchpoints` in design.md (BOTH modes — D-arc Stage D5)

The generated `design.md` carries a `## Touchpoints` section: the PREDICTED map of where the work lands in the codebase (files/modules to be created or modified) — seeded from the exploration's leanings and references in consume mode, authored fresh from the description + codebase reads in standalone mode.

**Entry grammar** (CLOSED form — the engine's boot render and `orbit-audit-drift`'s divergence check parse it): each entry is a markdown list item whose LEADING inline-code span(s) name the targets — one span, or several `+`-joined spans for grouped alternatives; everything after the spans (the ` — annotation` tail, parentheticals) is prose the checks never parse. Each target is exactly one of: (a) an exact repo-relative file path; (b) a directory prefix with a trailing `/`; (c) a glob containing `*` (single-segment, fnmatch semantics). Example:

```markdown
## Touchpoints

- `src/cli/program.ts` — registration; flags.
- `src/commands/` — new command module.
- `src/core/templates/workflows/*.ts` — the body pass.
- `src/core/orientation.ts` + `src/core/artifact-graph/gates.ts` — either home works.
```

**Frozen at apply**: the predicted map is revised only through normal artifact revision (the proposal review cadence bounds its staleness) and is FROZEN once apply begins — from the first apply commit onward it reads as "the plan", while the ACTUAL map is engine-computed from the diff (the boot render's Touchpoints view). Never hand-update the section after apply's first commit; predicted-vs-actual divergence is a computed check (`orbit-audit-drift`), not a maintenance chore.

### Step 0c.6 — Carry the Mechanism section (the `Mechanism section consumption` requirement)

Every Mechanism entry, and every live rule with none, is disposed of by ONE row of this table — rows tested IN ORDER, first match wins. A live rule is ACCOUNTED when it is counted in `rules_total` AND not in `rules_open` (`orbit-emit-composition` owns those fields; the readout's parser is the judge of FORM) — and you decide that from the FILE, by the grammar mirrored under Step 0b: the rule is accounted when its entry CONFORMS in FULL (a heading whose ID matches its Decisions entry; a `Domain:` line and a table with at least one member row; a `Closure:` token from the closed set; the two residual slots present exactly when BOUNDED; nine move lines, each exactly once). An entry failing ANY clause, or no entry, is OPEN; name the failing clause in the record's state column (the readout's state word when one is at hand). A key defect is an entry whose heading ID matches no Decisions entry (an orphan) or a second entry or heading under an already-used ID (a duplicate). The table is a checked mirror of the requirement's; a parity test holds it byte-equal:

| row | owner's Decisions state | accounting state | lands in |
|---|---|---|---|
| 1 | any, or none — tested FIRST | in `key_defects` (an orphan entry whose heading ID matches no Decisions entry; a second entry or heading under an already-used ID) | reported in chat at the Mechanism read (after Step 0b's last write, before generation); no carrier — a key with no owner has nowhere to land, and a duplicate is excluded from `rules_total`. Its record row: the heading's ID plus `line N`, the defect kind (`orphan` / `duplicate`) in the state column, owner `none` (orphan) or `duplicate` (a second claim on an owned ID), destination `none` |
| 2 | NOT a live rule (`Kind: fact` / `scope`, or `Disposition: superseded` / `assigned`) | any — an entry or none, well-formed or not | nowhere — permitted history; `explore.md` travels unchanged; the record lists it as not carried with NO state word (the engine assigns none to a non-live owner) |
| 3 | live rule | OPEN — in `rules_open` (any state that field defines, whatever `Closure:` token the entry carries); from the file alone: no entry, or an entry failing any clause of the Mechanism grammar | UNACCOUNTED: ONE `design.md` Risks entry naming the rule as the readout names it — the ID, or `line N` for an ID-less entry, per `orbit-run-summary-emit`'s identifier rule — with the state word (the readout's when one is at hand; else the failing grammar clause, in the grammar's vocabulary); the spec delta carries nothing for it; never blocking |
| 4 | live rule | accounted, `Closure: DERIVED` or `SOURCED` | the spec delta requirement the rule derives: the domain table as one of the CLOSED shapes below, the `Closure:` justification as the sentence naming the source |
| 5 | live rule | accounted, `Closure: BOUNDED` (both residual slots present, by construction) | `Residual kind:` and `Residual method:` VERBATIM in that requirement's text as a named limit (the OWNER — only spec text survives archive); ONE `design.md` Risks entry naming the rule ID and POINTING at the requirement, restating nothing |

**The CLOSED shapes** (a checked mirror of the requirement's list): a normative TABLE (the re-entry table in `orbit-explore-modifications`), a GRAMMAR or production block (the Mechanism grammar's fences in `orbit-conventions`), a SCENARIO SET — one scenario per member (the maturity rungs in `orbit-run-summary-emit`), or a SENTENCE naming the source with the members in prose (the concluded outcome's reader sentence in `orbit-conventions`). Which shape fits is your judgement; the record says which was chosen. The set is BOUNDED and its named limit is stated ONCE, in the requirement — point at it; never restate the two residual lines here.

**The record.** `design.md` carries a `## Mechanism → artifacts` section: a header line reading "the proposing AI's reading of the file; no engine record" — always that sentence — then one table row per Mechanism entry (and per live rule with none): the rule as the readout names it (ID, or `line N` for an ID-less entry; a key defect by ID plus `line N`), its closure token or its state word (the readout's when one is at hand; else the failing grammar clause; the defect kind for a key defect), its owner's state (`none` for an orphan; `duplicate` for a second claim), and its destination as a requirement title (plus the shape, for CLOSED entries; `none` for a key defect).

**Before Step 0d**: for every BOUNDED entry the table sent to row 5 (a live, accounted rule — never a history row), grep the change's `specs/` for both residual lines; a miss is reported and fixed before the move. Propose consumes FORM, as the readout renders form: whether an enumeration is TRUE, a residual honest, or a rule written down at all stays the reviewer's judgement.

### Step 0d — Move the staging directory (with the staged-metadata MERGE)

After all upstream steps complete successfully (artifacts generated, non-strict validation passes) and the
size brief below has run, FIRST merge the staged metadata, THEN bulk-move (D-arc Stage D2):

1. **Staged-metadata MERGE** (before the bulk move): if `orbit/explore/<name>/.openspec.yaml`
   exists, read it via the change-metadata helpers and merge FIELD-LEVEL into the change's
   freshly-written `orbit/changes/<name>/.openspec.yaml`. The merge is GENERIC with a
   fresh-owned DENYLIST: the fresh metadata's `schema`/`created`/`schema_version` values win
   (the staged copies were placeholders); EVERY OTHER staged field — `architecture:` today, and
   any explore-side field a future capability adds — carries forward with STAGED precedence on
   conflict (for `architecture:` specifically: the exploration's citation is the captured
   decision; note the override in chat). Do NOT enumerate carried fields — copying only known
   ones would silently discard future extensions. Then DISCARD the staged file (delete it; it is
   never bulk-moved — a stale metadata copy inside the change directory would be a second claim
   on one truth). When no staged `.openspec.yaml` exists (pre-D2 staging dir), skip this step
   entirely — the move proceeds exactly as before, and no removal runs.

2. **Bulk move**:

```bash
[ -d orbit/explore/<name>/.orbit-runs ] && mv orbit/explore/<name>/.orbit-runs orbit/changes/<name>/.orbit-runs
[ -f orbit/explore/<name>/.openspec.yaml ] && rm orbit/explore/<name>/.openspec.yaml  # staged metadata: merged above, then discarded (guarded — pre-D2 staging dirs have none)
mv orbit/explore/<name>/* orbit/changes/<name>/
rmdir orbit/explore/<name>
```

(Or equivalent — preserve `explore.md` AND any sibling files like `sketches/` AND any draft convention files AND the `.orbit-runs/` run trail. The `.orbit-runs/` directory is dot-prefixed, so a bare `*` glob does NOT match it — move it explicitly first (as above) or use a dotfile-aware move; otherwise it is left behind and the `rmdir` fails. The `rm` of the staged `.openspec.yaml` is conditional on its existence. The staging directory should no longer exist; its contents land alongside the generated artifacts in the change directory.)

After the move, `orbit/changes/<name>/` contains both:
- The moved exploration files (`explore.md`, `sketches/`, draft conventions)
- The generated artifacts (`proposal.md`, `design.md`, `specs/`, `tasks.md`)

`explore.md` persists unchanged as the historical record of how the change took shape.

## Standalone mode (unchanged from upstream)

When no `orbit/explore/<name>/` exists, fall through to upstream Step 1: prompt for description, generate artifacts from the description. Upstream behavior is otherwise unchanged, with ONE addition: the generated `design.md` still carries the `## Touchpoints` section (Step 0c.5 — authored fresh from the description and codebase reads; the entry grammar and frozen-at-apply rule apply identically).

## Graceful degradation

- **`explore.md` missing one or more sections** → warn, proceed-anyway by default; a missing section feeds nothing — except `## Mechanism`, whose absence makes every live rule UNACCOUNTED in the Step 0c.6 record.
- **`explore.md` has no Decisions** → the generated artifacts proceed but flag that they're being generated from Premise + Open questions alone, which usually means the exploration wasn't ready for promotion. Suggest user run more `/orbit:explore` work before applying.
- **`orbit/changes/<name>/` already exists in conflict** → three-way prompt (regenerate / continue / abort) is mandatory; do not silently overwrite.
- **No staging directory but user explicitly invoked propose** → standalone mode, no message.

## Base-fingerprint capture (NEW step — both modes)

(Per `orbit-base-fingerprints`' `Fingerprint capture at every spec-authoring point` requirement)

Immediately after the change's delta specs are generated (the `specs` artifact is written, in
consume mode or standalone mode alike), run:

```bash
orbit fingerprint "<name>"
```

This stamps `base_fingerprints` into the change's `.openspec.yaml` — the SHA-256 of each
MODIFIED/REMOVED/RENAMED requirement's CURRENT baseline block — so the archive-time guard can
detect a parallel change landing on the same requirements (no silent spec data-loss). Notes:

- Stamping is **add-missing-only**: it never overwrites an existing fingerprint (`--refresh` is
  the deliberate re-stamp reserved for after reconciling a divergence).
- ADDED-only changes stamp nothing — that's normal (new requirements have no base).
- A "skipped — requirement not found in live baseline" warning means the delta references a
  requirement that doesn't exist; fix the delta spec (validation also catches this).
- If delta specs are edited again later in the session, re-run the stamp so newly touched
  requirements gain fingerprints too (still add-missing-only; safe to repeat).

## Size brief after generation (NEW step — both modes)

(Per `orbit-propose-modifications`' `Size brief after generation`; the figures are `orbit-change-size`'s.)

**Position**: after every artifact is generated and `orbit validate "<name>"` passes NON-STRICT — size never fails
non-strict validation, so a breach never stops the flow before this brief, which handles it — in consume mode and
standalone mode alike —
BEFORE Step 0d's move, BEFORE the PR choreography's Phase 3 (commit, push, draft PR) and BEFORE the
completion emit, so a declaration written here lands in the proposal Phase 3 commits.

Read the `size` object from `orbit status --change "<name>" --json` (never compute a figure yourself) and act
by this table:

| `size` | the body |
|---|---|
| `ceiling` is `null` (the check is OFF) | says nothing about size |
| `breaches` is empty | says nothing about size |
| every breach `declared` | states each declared breach in one line, at the completion summary |
| any breach not `declared` | BRIEFS the user before the completion emit: each undeclared dimension with its figure and maximum, and the two routes below |

For an undeclared breach, ask with **AskUserQuestion** — the user's answer decides; never choose for them:

- **Split** — the change is split before review (R-crc-9). Do not split it here: say which dimensions are over and
  recommend returning to `/orbit:explore <name>` or the architecture doc. Leave every artifact in place and write no
  `## Size` section. The split recommendation REPLACES the completion prompt to review (below). The rest of the
  flow runs unchanged — Step 0d's move, the PR choreography's Phase 3 and the completion emit — so only the closing
  chat line differs: say that the emit's pointer names the review only because the artifacts are complete, and that
  `orbit validate "<name>" --strict` keeps failing on the undeclared breach until the change is split.
- **Declare** — write a `## Size` section into `proposal.md` (or add to an existing one), one item per undeclared
  dimension, carrying the user's reason in the user's words. Then run `orbit validate "<name>" --strict`.

The declaration's production — a CHECKED MIRROR of `orbit-change-size`'s `A breach is declared in the proposal's
Size section`, carried here because an installed skill has neither the owner's spec nor its parser (a parity test
holds it byte-equal to the owner's fence):

```
## Size
- <dimension>: <reason>        <dimension> ::= capabilities | requirements | changed_bytes | tasks; <reason> non-empty, on the item's first line
```

Only `-` items declare; the heading is `## Size`, case-sensitive; the reason begins on the item's first line. The engine
reads WHICH dimensions are declared, never what a reason says. The brief REPORTS: it blocks nothing, and the
change's artifacts are complete whichever route is taken.

## PR lifecycle (config-gated — D-arc Stage D6)

**Position (NEW Step 0.5 — this section is placed last for reading, not for running).**
Phase 1 (`orbit pr select`, then running its switch) runs AFTER Step 0's mode detection and
BEFORE Step 0a / upstream Step 1: generation must land on the target branch, and `select` reads
`orbit/explore/<name>/` while it is still in place. Phase 2 (generation +
validation, ON that branch) IS upstream Step 1 onward / the consume-mode flow, run exactly as
without the PR layer. Phase 3 (the no-CI note, then `orbit pr publish`: its land-and-open
segment, the emit, then its record segment) runs AFTER Step 0d's move, whose moved material and
staging-directory deletions `publish` enumerates.

Read the RESOLVED regime from the engine FIRST — `orbit status --json`, field `pr` (never parse `orbit/config.yaml` yourself: the value set is closed and every inert path already resolves to `never` with the reader's warning). When it is `never`, absent, or an inert
value/shape, RETURN IMMEDIATELY from this section: probe nothing (no `orbit pr` call, no
`gh`) and emit NO note — `never`'s promise is silence, and behavior stays byte-identical to
pre-capability. Only an ACTIVE mode (`per-proposal` / `per-architecture`) loads
`references/pr-choreography.md` and follows it.

That reference names the `orbit pr` call at each phase, the table you act on its record by,
and the judgment that stays yours (the title, the intent body, the commit messages, the notes).
The engine computes every precondition, the commit scope and the program-PR query; do not
re-derive any of them from this summary.

Two things that stay TRUE HERE regardless of config: propose fires NO consent prompt (it is
not consent-scoped — the choreography rides the user's own invocation), and generation +
validation are never rolled back by a PR-layer failure.

## Run-summary emit (one-shot at command completion — via the engine emit surface)

(Per `orbit-run-summary-emit`; composed and written via `orbit emit propose` — `orbit-emit-composition`.)

At command completion, compose the narrative payload (`final_assessment`, the required
nullable `model`, and — when `orbit pr publish` ran — the `pr_attachment` object per
`references/pr-choreography.md`) into a temp file and invoke:

```bash
orbit emit propose --change <name> --payload <payload-file>
```

The ENGINE owns the spine, the trail path, timestamp + collision handling, and `next_recommended` composition (propose-shaped: the review-gate pointer). Never hand-compose the JSON.

When `publish` printed a second segment, the emit is NOT the last act: run that segment with
the just-written emit's path as `<emit-path>`, so the attachment record the archive reads
reaches the branch. After a failed step or a PR-half degradation the emit stays LOCAL; the
failure line names the recovery.

**Completion-prompt override (chat)**: where the upstream steps above prompt "Run `/orbit:apply` or ask me to implement", instead prompt: "Run `/orbit:review <name>` — review the artifacts before implementation." The upstream text above is kept verbatim; this override is the operative instruction — except after the size brief's **Split** route, whose split recommendation is the closing chat line instead.

