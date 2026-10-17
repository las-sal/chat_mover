---
name: orbit-review
description: Editorial review of an orbit change or an architecture doc: proposal mode (pre-apply, 9 passes over artifacts), system mode (post-apply, verify-change + 6 system-wide passes), or architecture mode (a doc under orbit/architecture/, 6 passes, no gate). Use when the user wants a second-pair-of-eyes pass before applying or archiving, or a graded pass over a program architecture doc.
license: MIT
compatibility: Requires orbit CLI. System-mode Pass 0 invokes the `orbit-verify-change` skill. System-mode Pass 6 invokes the `orbit-audit-drift` skill.
metadata:
  author: openspec
  version: "0.1"
  capability: orbit-review
  generatedBy: "2.0.1"
---

Run an editorial review of an orbit change or an architecture doc. Three modes: `--as proposal` reviews a change's pre-implementation artifacts (9 passes); `--as system` reviews the whole product state after apply (verify-change as Pass 0 + 6 system-wide passes); `--as architecture` reviews an architecture DOC under `orbit/architecture/` (6 passes, NO gate — D-arc Stage D2). All modes share the 3-dimension scorecard (Completeness / Correctness / Coherence), the severity ladder (CRITICAL / WARNING / SUGGESTION — defined ONCE, by consequence, in `orbit-conventions`' Severity ladder; every pass rule NAMES it and defines nothing of its own), pushback discipline, and `.orbit-runs/` persistence. They differ on which passes run, what the final-assessment references (the `review-proposal` / `review-system` gates for the change modes; NO gate in architecture mode), and a few mode-specific flags (`--mark` for proposal, `--skip-verify` for system). The command additionally carries the REVIEWER axis (D-arc Stage D5): `--reviewer in-context|fresh|external|blind-pair` (default `in-context`). The first three are the reviewer classes; `blind-pair` is not a class but an INVOCATION of both independent classes at once — one fresh pass and one external pass, blind to each other. Each value has ONE shorthand that is exactly `--reviewer <value>`: `--in-context`, `--fresh`, `--external`, `--blind-pair`; an invocation carries AT MOST ONE reviewer selector (the selector table under Step 3). `--reviewer external` and `--reviewer blind-pair`, by either spelling, REQUIRE `--as proposal|system` (architecture mode supports in-context and fresh only; the combination is a clean usage error naming the constraint, and writes no prompt file and no T0 emit). `external` dispatches to the EXTERNAL-HANDOFF BRANCH: load `references/external-handoff.md` and follow it — it packages the prompt file and the T0 emit, then either prints the chat invocation snippet for paste or, with a reachable recorded runner, launches that runner and saves its return; no pass of the internal classes runs in that invocation. `blind-pair` loads `references/blind-pair.md` AND `references/external-handoff.md` and follows the pair reference, which runs both halves. The in-context and fresh branches load neither reference.

**Generates findings; does not resolve them.** Resolution flows through `/orbit:address-reviews` (inline `@review:` markers, OR `--from-file` ingesting external-review markdown OR internal review JSON OR audit-drift JSON) or by the user replying directly to the report.

**Input**: Optional change name (or, with `--as architecture`, a doc name) and optional `--as proposal|system|architecture` mode flag plus secondary flags. If change name omitted, prompt via `AskUserQuestion` over `orbit list --json` (architecture mode prompts over `orbit architecture status --json`'s parseable docs instead). If mode omitted, infer from `tasks.md` state (see Step 3) — architecture mode is NEVER inferred.

## Four execution disciplines (epitome)

The four disciplines from `orbit-conventions`, embedded per body; detail lives in the step where each fires.

- **Pushback (review-time) — primary here**: verify every finding against current state before reporting; suppress a stale finding with an evidence note (`stale finding suppressed: <evidence>`) whose evidence is what the current state shows. A VERIFICATION-genre pass additionally reads its walk (Step 5).
- **Read-before-reference (authoring-time)**: every construct a finding names is backed by an actual read (enforcement rule under Special cases); unverifiable → downgrade or omit.
- **Change completeness (modification-time)**: `--mark` insertions land fully in one pass, then sweep for residue (Step 11); stale or partial prior `.orbit-runs/` files are cleaned before persisting.
- **No-chaining (turn boundary)**: invoke only the orbit workflow commands the user's message explicitly requests; completing a command ENDS the turn at the position readout + the engine's eligibility line — review-cycle COUNT is the user's call; gate `passed` means *eligible*, not *commanded*.

## Pass genre

The table below is a CHECKED MIRROR of `orbit-conventions`' `Review mode decision framework` — the owner of how a pass's genre is determined and of what a REVIEW-genre brief may carry. An installed skill has no specs to point at, so the copy exists here; a parity test holds it byte-equal to the owner's fence. Never edit it here. The pass genre is a record and a header word; the gate reads nothing of it.

```
| reviewer class | mode | trail position | pass genre |
|---|---|---|---|
| `fresh` or `external` | proposal or system | any | REVIEW — reads the whole artifact and the thesis |
| `in-context` | proposal or system | a qualifying walk of this mode precedes the pass | VERIFICATION — reads that walk and answers landed / regressed per resolution |
| `in-context` | proposal or system | no qualifying walk of this mode precedes it | REVIEW — a reaction with nothing yet to verify; the cadence's slot arithmetic is unchanged by pass genre |
| `in-context` | proposal or system | only MODE-LESS walks precede it | REVIEW — a walk whose mode cannot be read is not evidence of a qualifying walk of this mode |
| `in-context` or `fresh` | architecture | — | REVIEW — the architecture trail carries no change-mode walk records and the mode has no gate |
| `external` | architecture | — | not a member — refused by `orbit-review`'s mode constraint |
```

## Steps

### 1. Resolve the mode

Resolve the MODE first — it decides what the positional even IS. Mode comes from `--as proposal|system|architecture`. **Architecture mode is NEVER inferred** — it requires the explicit flag; a positional that happens to match a doc name does NOT trigger it. If `--as` is omitted, infer between the change modes from `orbit/changes/<name>/tasks.md` checkbox arithmetic: all unchecked → `proposal`; all checked + code changes since the change was proposed (`git log --format=%h -- orbit/changes/<name>/ ':!orbit/changes/<name>/.orbit-runs'` — hashes only: the inference needs only whether such a commit exists, and commit subjects can carry prior passes' counts) → `system`; mixed or ambiguous → `AskUserQuestion`. State the resolution in the report header (`Mode: proposal (inferred from 12 unchecked tasks)`).

### 2. Resolve the target

**Change modes** — the target is a CHANGE: use the provided name; otherwise prompt via `AskUserQuestion` over `orbit list --json` (mark changes with incomplete tasks `(In Progress)`). Announce `Using change: <name> --as <mode>` at the start of the report header.

**Architecture mode** — the target is a DOC, never a change: do NOT run `orbit list` or prompt over changes, and NONE of the change-oriented steps below apply (Step 4's change CLI calls, Step 9's gate tail). The positional resolves against `orbit/architecture/` (the filename stem); when omitted or ambiguous, prompt over `orbit architecture status --json`'s parseable docs. A doc resolving LEGACY (zero stage-prefixed headings outside fences) is an error suggesting retrofit; MALFORMED (fails the near-miss rule) is an error naming the grammar violation. Announce `Using doc: <doc-name> --as architecture`.

### 3. Resolve flags

| Flag | Default | Effect |
|---|---|---|
| `--fast` / `--full` / `--thorough` | `--full` | Depth. Mutually exclusive. `--thorough` is partially specified; fall back to `--full` if unclear. |
| `--parallel` | off | Spawn subagents for heavy passes. Proposal: parallelize Passes 2, 4, 6. System: parallelize Passes 2, 3, 4, 5. |
| `--focus <lens>` | none | Emphasize specific passes (additive — does not skip others). See `references/flags-detail.md`. |
| `--strict` | off | Fail-fast on the first CRITICAL or the first BLOCK — stop on what must be addressed. Useful for CI-like runs. |
| `--reviewer <value>` | `in-context` | Reviewer: `in-context` (this session — the reacting class) / `fresh` (same model, clean context — a clean-context subagent; see Dispatching a fresh pass) / `external` (a different AI in a separate session — the handoff branch, `references/external-handoff.md`) / `blind-pair` (one fresh and one external pass in one invocation — `references/blind-pair.md`). |
| `--in-context` | off | Exactly `--reviewer in-context`. |
| `--fresh` | off | Exactly `--reviewer fresh` (same model, clean context). |
| `--external` | off, proposal/system only | Exactly `--reviewer external`. |
| `--blind-pair` | off, proposal/system only | Exactly `--reviewer blind-pair`. |
| `--mark` | off, proposal only | After report, write `@review: <text>` markers at each finding's file:line. See `references/flags-detail.md`. |
| `--skip-verify` | off, system only | Skip Pass 0 (verify-change). Use when verify-change was run separately. |

**Reviewer selectors.** Resolve the reviewer BEFORE anything is read or written, by this table; every error row is a clean usage error that runs no pass and writes no file:

| selectors given | resolves to |
|---|---|
| none | `--reviewer in-context`, the default |
| exactly one shorthand | exactly `--reviewer <its value>` |
| `--reviewer <value>` alone | that value |
| two shorthands, or a shorthand with an explicit `--reviewer` — even when they agree | usage error naming the shorthand equivalence: `--<value> is exactly --reviewer <value>; give one reviewer selector` |
| `external` or `blind-pair`, by either spelling, with `--as architecture` | usage error: `--reviewer <value> requires --as proposal|system; architecture mode supports in-context and fresh only` |
| a `--reviewer` value outside the four | usage error naming the four: `in-context`, `fresh`, `external`, `blind-pair` |

If a flag is specified for the wrong mode (e.g., `--mark` in system mode or `--skip-verify` in proposal mode), accept it silently and emit a one-line note in the report (`Note: --mark writes to source files is v2; ignored for v1 system-mode runs.`). In architecture mode, `--parallel`, `--fast`, and `--focus <lens>` are accepted but are no-ops (architecture docs are small; all six passes run in one context — no per-mode subset or lens table is defined), each noted in the report the same way.

### 4. Load context

**Architecture mode**: the change-oriented CLI calls below do NOT apply — there is no change. Load instead: the doc itself (`orbit/architecture/<doc>.md`), `orbit architecture status --json` (computed stage states, for cross-checks), and root `CLAUDE.md`; then continue at Step 5. `orbit architecture show <doc> <stage>` slices single stages when the whole doc is not needed.

**Change modes** — use the orbit CLI as source of truth:

```bash
orbit status --change "<name>" --json
orbit instructions apply --change "<name>" --json
```

From the returned `contextFiles`, read every artifact: `proposal`, `design`, `tasks`, all paths under `specs`. Also read:
- `orbit/changes/<name>/explore.md` if present
- `orbit/changes/<name>/sketches/` if present
- Project context: `CLAUDE.md` (root), `orbit/project.md`, any `*_convention.md` at project root
- Baseline: `orbit/specs/*/spec.md`
- Orbit lenses: `orbit/lenses/perspectives.md`, `orbit/lenses/critical-paths.md` (system mode primarily; proposal mode uses for cross-doc checks)

System mode also reads:
- `git diff <change-start>..HEAD -- . ':!orbit/changes/<name>/.orbit-runs'` — `<change-start>` is the commit that first added the change's `proposal.md`, found by hash alone (`git log --diff-filter=A --format=%h -- orbit/changes/<name>/proposal.md | tail -1`); commit subjects can carry prior passes' counts, so a REVIEW-genre pass never reads them. The pathspec keeps the trail's pass records and walk logs out of what the pass reads
- Code paths around the change (cohesion + surface walks)

### 5. Inspect prior runs (VERIFICATION pass genre only)

Decide this pass's PASS GENRE first, by the table under **Pass genre** above. A `fresh` pass and any architecture-mode pass are REVIEW. An in-context pass in a change mode decides from ONE bounded metadata probe — the token-ordered listing of the change's `.orbit-runs/` pass and walk records: `review-<mode>-*.json` reading each record's `reviewer_class` field (or `flags.fresh` when that field is absent — a legacy fresh pass), `external-<mode>-*.md` by filename, and `address-reviews-*.json` reading each record's `source_path` — to find the latest ACCEPTED independent pass of this mode and any walk of this mode after it. Open no record's findings, suppressed list or resolutions to decide; a walk whose `source_path` resolves to no mode is MODE-LESS and qualifies for none; an unreadable listing is REVIEW. Every `external-<mode>-*.md` file counts as a pass here — whether the engine ACCEPTS a return cannot be read from metadata; the owner names that limit, and where the two differ the engine's computation is authoritative.

- **REVIEW pass genre** — SKIP the rest of this step: the metadata probe above is the ONLY read of the trail's pass and walk records a REVIEW-genre pass makes. Pushback is current-state verification and needs no prior list, and the iteration ordinal and trend are ENGINE-computed at render time from the trail — never authored here. The owner's ONE exemption: architecture mode keeps its hand-computed per-doc iteration note (Step 8), counted over `review-architecture-*.json` emits in `orbit/architecture/.orbit-runs/` whose `doc` field equals the doc under review — the trail is shared across docs, and a review of doc B must never treat doc A's run as its previous iteration.
- **VERIFICATION pass genre** — this pass VERIFIES the walks; it does not re-review the whole artifact. The procedure is `orbit-review`'s **Verification-genre passes grade the walk record**; each step below names the owner it points at and restates none.
  - **(a) Genre.** The probe above is this body's reading; the ENGINE's computation, by `orbit-conventions`' table, is authoritative. When `orbit emit review` refuses the payload — an owed `verification` missing, a key omitted, a verdict not owed — the refusal names each key as `walk <token>: (<title>, <file>)`: read those entries, grade or drop them, and emit again. The refusal is the reconciling channel, in BOTH directions — never a second probe, never a hand-computed walk set: when it says `verification` is refused on a REVIEW-genre pass, the engine computed REVIEW, so drop `verification` and every `walk_entry`, run this pass as a REVIEW-genre pass over the whole artifact, and emit again.
  - **(b) Read the walks.** Open the address-reviews records of this mode after the latest accepted independent pass — the walks the probe found — and each entry's disposition.
  - **(c) Grade.** Every OWED entry — the `resolved` ones, at every severity — gets one verdict, `landed` or `regressed`, by the definition under **Verdicts** below and the owed set `orbit-emit-composition`'s **A VERIFICATION-genre payload carries its verdicts and its findings link to the walk record** owns. Read each entry's SWEEP SCOPE: its `file`, every path in its `ripple_cascade.applied` (the cascade record `orbit-address-reviews` specifies), and, on an entry that carries one, every path in its `sweep.scope` (the sweep record `orbit-address-reviews`' `A resolved walk entry records its sweep evidence` owns; a directory contributes its files, and every path resolves by the rule under **Sweep scope and paths** below). A `stale`, `deferred` or `escalated` entry owes nothing, but a wrong call there is still a finding.
  - **(d) Review the scope, then the residual check.** Run this mode's FILE-SET passes over the union of the sweep scopes — every proposal-mode pass; system-mode Passes 1–5. A pass whose subject is the whole change or the whole project — system-mode Pass 0 (verify-change) and Pass 6 (audit-drift) — is NOT run: list it in `passes_skipped` naming that reason. Then list `git diff --name-only <C> -- . ':!orbit/changes/<name>/.orbit-runs'` plus `git ls-files --others --exclude-standard -- . ':!orbit/changes/<name>/.orbit-runs'`, where `<C>` is `git log --diff-filter=A --format=%h -- <base file> | tail -1` (a hash-only read), or `HEAD` when that file is not yet committed — the BASE FILE is the latest accepted independent pass's file, or, when this mode has no accepted independent pass, the file of the pass the earliest walk you verify walked. Name each listed file outside every entry's EDIT RECORD — its `file` plus its `ripple_cascade.applied`; `sweep.scope` names paths examined, not edited, so it never exempts a file here — as a SUGGESTION without `walk_entry` — a record gap, not a defect; a defect you find in such a file is its own finding, graded by `orbit-conventions`' Severity ladder. KNOWN LIMIT: an edit committed in `<C>` itself — the commit that added the base file — is outside the diff's reach; never claim the scope was checked against that commit. It is the ORDINARY case, not an edge, when the base file was committed together with the walks' edits — commit the pass file BEFORE the walks' edits so they stay in range.
  - **(e) Compose.** `verification` — one `{title, file, verdict}` per owed entry, `[]` when nothing is owed — and, on each finding about a walk entry, `walk_entry: {title, file}`: a defect in a `resolved` entry's edit names that entry and grades it `regressed` (every `regressed` verdict needs a finding naming it); a finding about a `stale`, `deferred` or `escalated` entry names that entry; a finding about no entry carries no link, and the report marks it `[outside the walk record]` per `orbit-report-rendering`'s **Verification renders as its own section and its absence is marked**. Never supply `pass_genre` or `verified_walks` — the engine computes both.

#### Verdicts

The definition below is a CHECKED MIRROR of `orbit-emit-composition`'s **A VERIFICATION-genre payload carries its verdicts and its findings link to the walk record** — its owner. An installed skill has no specs to point at, so the copy exists here; a parity test holds it byte-equal to the owner's fence. Never edit it here.

```
landed — the resolution's edit is PRESENT, COMPLETE across every site the resolution claims, CLEAN (it introduced no defect), and NOT UNDONE by a later edit.
regressed — any of those fails, or the verifying pass cannot decide (an undecidable claim is not a held one); its cause is stated by the finding that names it.
```

#### Sweep scope and paths

The rule below is a CHECKED MIRROR of `orbit-emit-composition`'s **The walk write gate checks sweep evidence** — its owner, which the walk's write gate enforces. An installed skill has no specs to point at, so the copy exists here; a parity test holds it byte-equal to the owner's fence. Never edit it here. Grade over the paths it resolves, so you read the file the gate read.

```
CHECK SCOPE — the union of: on a change-scoped walk, every file under the change directory except its .orbit-runs/ trail; the entry's file; its ripple_cascade.applied paths; its sweep.scope paths, a directory contributing the regular files under it (a symlink met inside a directory is not followed; a path named explicitly is read at its target). Files under .git/, node_modules/, dist/ and build/ are never read, however the path entered the scope; for the change directory's own files those names are read below the change directory.
PATH — strip a trailing :<line> or :<line>:<column> (digits only, at the very end; a path carrying anything after the suffix, such as "design.md:40 (section)", is not stripped, and resolves to nothing); a path beginning orbit/changes/<name>/ for the walk's own change resolves under the change directory, archived or active; otherwise it resolves against the project root, then, on a change-scoped walk and only when nothing exists there, against the change directory.
```

### Dispatching a fresh pass (`--reviewer fresh`)

A fresh pass is REVIEW pass genre. Spawn a clean-context subagent (the **Task tool**, general-purpose — never a fork of this conversation, which would carry its context) with the review contract, and hand it the brief below. What the brief may carry is `orbit-conventions`' `Review mode decision framework`'s rule, stated there once; the brief adds nothing beyond it and nothing from the trail. The subagent persists through `orbit emit review` with `reviewer_class: "fresh"` and its owed `direction` (Step 8); this conversation then renders the report from the engine (Step 10) and pastes it. Dispatch is the INVOKING session's act alone: a subagent holding this brief is the worker, skips this step, and never dispatches again.

```
You are the fresh-context reviewer this session dispatched for /orbit:review --as <mode> --reviewer
fresh on <target> in this repository: the WORKER, not a dispatcher. Load the orbit-review skill and run
its steps for that mode as a REVIEW-genre pass, SKIPPING its "Dispatching a fresh pass" step: that step
is the invoking session's and is already done; you never dispatch again. Read what the skill's read list
names for the mode — the change's artifacts, the baseline specs, the lens files and, in system mode, the
commit range with the trail excluded by the pathspec it gives. Persist through orbit emit review with
reviewer_class "fresh" and a direction.
```

**A re-run of a blind pair's missing fresh half.** Before dispatching, read `orbit status --change <name> --json`. When the mode's reviewed gate row carries `openPair: {missing: "fresh"}`, the run is a RE-RUN: find the pair's open launch L — the latest `review-external-<TS>.json` of this mode carrying `pair: true`, reading only its `mode` and `pair` fields — and list the trail's `apply-*.json` tokens. With NO apply token later than L, BASE is `git log --diff-filter=A --format=%H -- <L's T0 path> | tail -1` (a hash-only read) and the REVIEWED COMMIT is `git rev-parse <BASE>^1`. With an apply token later than L, the landed external member was emitted after it and reviewed the post-apply state, and the engine counts this run as the pair's missing member: the REVIEWED COMMIT is `git rev-parse <M>^1`, M being `git log --diff-filter=A --format=%H -- <member path> | tail -1` for the earliest `external-<mode>-*.md` later than L (when M is empty, stop and say to commit that file alone first). Either way the brief gains these lines after its last: `Review the repository as it stands at commit <REVIEWED COMMIT>, not the live checkout: read the change's files and, in system mode, the code and the commit range ending at that commit (git show <commit>:<path>; git diff <change-start>..<commit>). Where the skill's steps read state through the orbit CLI — orbit status, orbit instructions, the scenario map, Pass 0's structural check — that output describes the live checkout, not the reviewed commit: take the artifacts you review from the commit, use the CLI only for what the emit needs, and say in the pass which readings came from the live checkout. Run orbit emit review from the repository root as usual.` The isolation is instructed, not physical — the rule and its named limit are `orbit-review-external`'s `A pair's external half reads the pair's reviewed state`. When the mode has no `openPair` and the latest launch's one landed member is STALE — read from the trail: exactly one landed member later than L (an earliest fresh `review-<mode>-*.json` or earliest `external-<mode>-*.md`, and none of the other class), no `address-reviews-*.json` naming it in its `source_path`, and an `apply-*.json` token later than it — never from the gate's reason — say `The pair launched at <L> reviewed a superseded state (an apply landed after its <class> member); this run is an ordinary single on the current state.` and dispatch the brief unchanged. The re-run test is this body's reading of the trail; the gate's computation is authoritative.

### 6. Run passes (load the resolved mode's reference ONLY)

Load `references/passes-<mode>.md` for the RESOLVED mode — proposal (9 passes), system (0–6), or architecture (6) — and run its pass set sequentially (or in parallel for the marked passes when `--parallel` is on). Only the resolved mode's reference is loaded; the other two stay lazy. For each pass:

1. Apply the read-before-reference discipline to every cited construct.
2. Apply the pushback discipline against current state.
3. Emit findings tagged CRITICAL / WARNING / SUGGESTION with file:line + actionable recommendation, graded by `orbit-conventions`' Severity ladder as each pass rule names it: a CRITICAL carries its `reproduction` (the surface refuses one without it); a lifecycle BLOCK (Pass 1's validate failure, Pass 8's unresolved marker) goes to the payload's `blocks`, never to a finding.

### Disjunctive recommendations: emit structured `recommendation_options`

When a finding's recommendation genuinely offers the user a choice between two or more defensible concrete paths (different outcomes, not rewordings), emit `recommendation_options: [{label, body}]` alongside the prose `recommendation` — each entry a non-empty `label` (`"A"`, `"B"`, …) plus the concrete action the user would take. Do NOT emit it for single-action recommendations or loose conversational "or" ("fix it now or later") — false-negative bias is intentional. The prose field still summarizes the disjunction for human readers; the structured field is the producer-side fork affordance address-reviews consumes, OPTIONAL on every finding and ignorable by downstream parsers (canonical JSON shape: `references/run-summary-schema.md`).

### 7. Apply scorecard rollup

Roll every pass's findings into the 3-dimension scorecard per the mode's dimension mapping (in the loaded pass reference).

### 8. Author the direction and the commentary

**The direction.** An independent pass OWES its forward recommendation: when `reviewer_class` is `fresh` or `external`, compose the `direction` object — `disposition` exactly one of `forward` | `hold`, `reasoning` a non-empty string, multi-line allowed. The SHAPE is owned by `orbit-emit-composition`'s **The review payload carries `direction`**, which the write gate enforces: `orbit emit review` REFUSES a fresh or external payload without it, and a mis-shaped one at any class, in every mode (an architecture-mode fresh pass owes it too — the rule keys on class, never on mode). An `in-context` pass MAY carry one and is not incomplete without it: the reacting class's direction is the readiness record's job (R-crc-11(f)). The CONTENT contract is owned by `orbit-report-rendering`'s **Direction renders as its own section and its absence is marked on independent passes**, carried here because a reviewer reads this body, not the spec: the direction says WHICH WAY and WHY — your own recommendation on moving forward — and never states finding counts, the gate's state, or a command token; those exist only in the report's engine-computed sections, and the report renders the direction in its own `### Direction` section inside the quarantine with the engine tail still last. The vocabulary is rc04a's judgement record's (`disposition` + `reasoning`), adopted, not invented. The engine judges presence and shape only: whether the direction is RIGHT, and whether its reasons agree with its token, is the in-context reaction's and the readiness author's call.

**The commentary** (change modes). The reviewer's insight travels as the emit's OPTIONAL `commentary` field — the pattern behind
the findings, what was probed and how hard, risk texture: everything the structured sections
can't say. Commentary NEVER states finding counts, gate verdicts, or next commands (those
exist only in the report's engine-computed sections; the contract is enforced at this source).
The iteration note is NOT authored — the renderer computes it from the trail (D-arc Stage D4).
Architecture mode keeps its hand-computed iteration note (matching mode AND `doc`, per Step 5
— never cross-doc): `Note: N of these findings appeared in the last run on <date>. M new this
run.` / `First architecture review for this doc.`

### 9. Persist via the emit surface (persist-first)

Compose the NARRATIVE payload only — `mode`, `reviewer_class` (`"fresh"` under `--reviewer fresh`, else `"in-context"`), `depth`, `flags`, `scorecard`, `findings` (each with its owning `dimension`, `title`, `file`, `line`, `recommendation`, `reproduction` — a string, multi-line allowed, never a single-line slot; REQUIRED non-empty when `severity` is CRITICAL per `orbit-conventions`' Severity ladder and refused by the surface otherwise, optional below — plus `recommendation_options` when disjunctive), `blocks` (optional array of single-line strings — Pass 1's validate failure and Pass 8's unresolved markers compose into it, never into `findings[]`; absent when none), `direction` (OWED when `reviewer_class` is `fresh` or `external` — the surface refuses the payload without it — and optional in-context; composed per Step 8), `verification` (OWED when the engine computes VERIFICATION pass genre, refused on a REVIEW-genre pass; each finding may carry `walk_entry` — composed per Step 5's VERIFICATION branch), `stale_suppressed`, `commentary`, `passes_run`/`passes_skipped`, and the required nullable `model` — and invoke:

```bash
orbit emit review --change <name> --payload <payload.json> --render   # proposal/system
orbit emit review --doc <doc-name> --payload <payload.json>           # architecture mode
```

The ENGINE owns everything else (per `orbit-emit-composition`): the spine, the severity-counts `final_assessment`, the findings-dependent `next_recommended`, the shared-axis `iteration` (per-doc in architecture mode), the computed `pass_genre` and `verified_walks`, the filename token, and the write gate — never hand-compose the JSON (the retired practice; the surface rejects engine-owned and unknown payload keys, so a payload the table doesn't name fails loudly). Architecture-mode payloads additionally carry the architect-owned `handoff` section; the engine mirrors `handoff.next_command` into the spine. Payload fields are documented in `references/run-summary-schema.md` — a MIRROR of the engine's authoritative table, never its definition.

### 10. Render and paste the report (change modes)

`--render` on the Step 9 invocation already printed the engine report (persist-first and run-and-paste in one breath); otherwise run `orbit status --change <name> --report`. Paste the output VERBATIM as the report. The
body NEVER hand-renders the structured report sections — header, trend, scorecard table,
findings, Suppressed, or the gate/position/eligibility tail; hand-rendering them is PROHIBITED
in change modes (architecture mode is EXEMPT — it has no render surface yet and keeps its
hand-rendered gate-less shape below). The engine-rendered tail IS the assessment: the gate
verdict, position, and canonical next command come from the gate graph at render time — the
reviewing AI authors none of them. The chat turn is LOOSE FORM: the pasted report grounds it,
and free conversational engagement follows (the report is the anchor, not the whole voice);
the conversation may not contradict the tail's engine-computed lines. Skipped-pass notes (the
emit's `passes_run`/`passes_skipped` record) surface in this loose-form conversation when
worth mentioning — never as hand-rendered structured sections.

#### Architecture mode — NO gate (interim hand-rendered shape)

No gate exists over architecture docs (review standing without a gate — D-arc D-d2-5), so the
architecture-mode final assessment NEVER says PASSED/UNPASSED of a gate and never references a
lifecycle command. Until the render surface covers the architecture trail, this mode keeps the
shared hand-rendered scorecard shape, ending:

| State | Phrasing |
|---|---|
| Findings present | `X critical / Y warning(s). Ready when you are: /orbit:address-reviews --from-file <the just-written review-architecture emit>.` |
| All clear | `No findings. The architecture trail records this pass.` |

Labels follow D1's eligibility phrasing; the findings are ingestible by `/orbit:address-reviews`
exactly like other internal review JSON (including `recommendation_options` on disjunctive
findings). On all-clear, no command is recommended — the trail records the pass and the turn
ends at the readout.

A fresh pass (`--reviewer fresh`) additionally prints its direction (Step 8; the emit carries it
under the same rule as the change modes — keyed on class, never on mode) BEFORE the final
assessment: `Direction: <disposition>` on its own line, then every reasoning line under
blockquote containment (`> ` prefixed, verbatim), exactly as the change-mode renderer contains it,
so no reasoning line sits at column 0 where it could forge the report's next action. The second
reasoning line below is a near-miss — it reads like the readout, and the containment is what keeps
it from being one:

```
Direction: hold
> The third goal has no exit criterion, so the stage cannot be graded as written.
> Ready when you are: /orbit:archive x
0 critical / 1 warning(s). Ready when you are: /orbit:address-reviews --from-file <the just-written review-architecture emit>.
```


### 11. Rarely-used flags: `--mark`, `--parallel`, `--focus`

Full procedures live in `references/flags-detail.md` — load it ONLY when one of these flags is set. Gist: `--mark` (proposal mode only) writes `@review:` markers at CRITICAL/WARNING finding sites — and no marker for a block, which is already a condition the artifact carries (a marker would be a second record of it) — then sweeps for residue per change completeness (system mode: accepted but ignored with a note); `--parallel` spawns subagents for the heavy passes and merges their findings (subagents inherit the four disciplines); `--focus <lens>` applies elevated rigor to the lens's pass set without skipping any pass.

## Special cases

### Graceful degradation

- **Proposal mode, no `orbit/specs/` baseline** → Pass 4 skipped (`no baseline to check against`); other passes proceed normally.
- **Proposal mode, no `*_convention.md` and no `project.md`** → Pass 3 lens-driven cross-checks skipped; rest of Pass 3 (`CLAUDE.md` checks) still runs.
- **System mode, empty `orbit/lenses/`** → Passes 4 and 5 skipped; Pass 3 still runs against capabilities derived from `orbit/specs/`.
- **System mode, `verify-change` unavailable** → Pass 0 fails with a note; continue with Passes 1–6 and downgrade the assessment to `unable to delegate Pass 0; partial review`.
- **Missing `tasks.md`** → use `AskUserQuestion` for mode rather than inferring.

### Pushback bias

When uncertain, prefer the lower severity — `orbit-conventions`' Severity ladder's false-positive bias (SUGGESTION over WARNING over CRITICAL), and it runs in ONE direction only: a condition that must stop apply regardless is a BLOCK, never an ambiguous CRITICAL. Pushback against the bias to over-flag — the goal is signal, not volume.

### Read-before-reference enforcement

Every finding that cites a specific file:line must be backed by an actual read of that line. If the citation is inferred (e.g., "I think this is around line 50 of design.md"), either read first or downgrade to a less specific finding ("design.md mentions <topic> but does not specify <X>" — searchable, but no false-precision line number).

## Output format (change modes)

The report IS the engine render: run `orbit status --change <name> --report` after persisting
the emit and paste the output verbatim — header, trend, scorecard table, findings (blockquote-
contained recommendations, labeled options), Suppressed, the delimited Commentary slot, and
the engine tail (gate / position / eligibility) last. Never hand-render those sections in
change modes; free conversational engagement follows the pasted report (loose form).
Architecture mode keeps its hand-rendered gate-less shape (Step 10) until the render surface
covers the architecture trail.

## Worked example (the change-mode turn shape)

```
[persist orbit/changes/example-change/.orbit-runs/review-system-2026-05-26T15-12-08Z.json]
[run: orbit status --change example-change --report]
[paste the rendered report verbatim — it ends with the engine tail, e.g.:
---
Gate review-system: unpassed — pass 2026-05-26T15-12-08Z has unresolved substantive findings
Position: propose ✓ → review(proposal) (past) → apply ✓ → review(system) unpassed → archive blocked-by-gate
Ready when you are: /orbit:address-reviews example-change]

[then loose-form conversation: what the pattern behind the findings means, what to probe
next, anything the structure can't say — never contradicting the tail's engine lines]
```



