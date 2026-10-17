---
name: orbit-architect
description: Author or resume an architecture doc (program layer above changes): parseable stage declarations, ruling capture, engine-rendered state, and the completion-ratification flow. Never a required entry point — /orbit:explore plus hand-editing remains first-class.
license: MIT
compatibility: Requires orbit CLI (orbit architecture status/show/validate). Composes with /orbit:explore (citation-carrying explorations) and /orbit:review --as architecture.
metadata:
  author: openspec
  version: "0.1"
  capability: orbit-architect
  generatedBy: "2.0.1"
---

Enter an architect session against one architecture doc under `orbit/architecture/`. This is the PROGRAM layer — cross-change structure (premise, rulings, stages with charters and exit criteria) — sitting above per-change flow. The session captures program-level material into the doc the way `/orbit:explore` captures decisions, while ALL state rendering comes from the engine.

**Input**: Optional `<doc-name>` (the filename stem — the doc's citable identity). With a name: create `orbit/architecture/<doc-name>.md` if absent, or resume the existing doc. Bare: list docs via `orbit architecture status` and prompt selection via **AskUserQuestion** (offering create-new).

**Never a gatekeeper**: architecture authoring via `/orbit:explore` plus hand-editing remains a first-class path. This command is a stance, not a checkpoint — no orbit surface requires an architect session, and no validation or drift check flags architecture content, or a change, for having originated outside one. The canonical flow is architect-first and returns here — architect → explore → propose → review → apply → review → archive → architect, the closing session ratifying the stage and taking up the next — and that is a suggestion, never a requirement: orbit's start surfaces name `/orbit:architect` first, and `/orbit:explore` remains a working path for a one-off fix.

## Four execution disciplines (epitome)

The four disciplines from `orbit-conventions`, embedded per body; detail lives where each fires.

- **Read-before-reference (authoring-time)**: read a construct's actual definition before naming it in the doc or a ruling; unverifiable → ask or leave a `@review:` marker, never guess.
- **Change completeness (modification-time)**: doc edits land whole — a stage added to the grammar, its Depends-on slots, and the status-log entry move together; re-read after to confirm.
- **Pushback (review-time)**: verify a claimed stage state against `orbit architecture status` before restating it; computed state wins over remembered state.
- **No-chaining (turn boundary)**: invoke only the orbit workflow commands the user's message explicitly requests; completing a command ENDS the turn at the position readout + the engine's eligibility line — gate `passed` means *eligible*, not *commanded*.

## Steps

### 1. Resolve the doc

- **Named**: `/orbit:architect <doc-name>` targets `orbit/architecture/<doc-name>.md`.
- **Bare**: run `orbit architecture status --json`; present the docs (parseable with their computed positions; legacy as opaque; malformed flagged toward validate) via **AskUserQuestion**, with a create-new option.

### 2. Create (doc absent) — scaffold the parseable format

Write the doc scaffolded in the parseable structure BY CONSTRUCTION — format correctness never depends on prose memory:

```markdown
# Program: <doc-name>

> Position is COMPUTED — run `orbit architecture status`. This doc declares; the engine renders.

## Premise

<why this program exists; what it must produce>

## Goals

<the program's falsifiable goals>

## Rulings index

<dated, attributed, addressable IDs — e.g. **R-<doc>-1** (<who>, <YYYY-MM-DD>) — <ruling>>

## Program stages

### Stage <kebab-id> — <title>

Depends-on: (none)
Complete: [ ]

<charter prose; exit criteria>

## Considered & out

<rejected directions with rationale + date>

## Status log

<append-only ledger; the engine never reads it>
```

The stage-heading grammar is `### Stage <kebab-id> — <title>` (kebab-case id unique in the doc, em-dash separator). The two slot lines are OPTIONAL with omission semantics (absent `Depends-on:` = no dependencies; absent `Complete:` = unratified); when present they follow the exact grammar `Depends-on: (none)` / `Depends-on: <id>[, <id>…]` and `Complete: [ ]` / `Complete: [x] <YYYY-MM-DD> (<who>)` / `Complete: [~] <YYYY-MM-DD> (<who>)` — unratified, ratified, ENDED (the user's declaration that the stage ended without meeting its exit criteria; no free-text suffix — the reason lives in the status log). The `Complete:` productions in that sentence are a CHECKED MIRROR of `orbit-architecture-engine`'s `Parseable architecture-doc format` requirement, which OWNS the slot grammar — this body cannot resolve the owner at runtime, so it carries the copy and says so (held byte-equal by a parity test). Everything else — charter prose, exit criteria, rulings, status log — is engine-opaque judgment text.

### 3. Resume (doc exists) — the doc is authoritative

Read the doc AND `orbit architecture status` (its computed position) BEFORE any edit. If `status` lists the doc as MALFORMED, surface the grammar violations (they point at `orbit architecture validate <doc>`) and offer to fix them first — malformed docs are fixed, not extended.

### 4. Session stance: capture as ratified, render never author

During the session, capture program-level material into the doc as it is ratified in conversation, with brief chat acknowledgment ("captured"):

- **Rulings** — appended to the rulings index: dated, attributed, addressable ID.
- **Stage declarations** — heading + slots + charter prose + exit criteria, in the parseable grammar.
- **Considered & out** — rejected directions with rationale + date.

**Render state, never author it**: ALL stage-state and program-position statements come from `orbit architecture status` — rendered verbatim, never inferred. The body is PROHIBITED from hand-writing state into the doc: no `*State:*` lines, no position summaries duplicating what the engine computes. When the doc predates this contract (carries legacy hand-written state lines), FLAG them for deletion rather than updating them — every hand-maintained state line is a future staleness bug.

**R-d-8 residency sweep at every conversation boundary**: pending recommendations, leanings, and open items discussed but not yet ratified must be file-resident BEFORE the emit writes — written into the owning section (e.g. an open question's standing-recommendation slot). Chat is never the store of record.

### 5. Completion-ratification flow (the completion flow's one AskUserQuestion — the doc selector in Step 1 is the body's other prompt)

When `orbit architecture status` shows a stage quiescent-awaiting-ratification (all citing work archived, `Complete:` slot unratified), SURFACE it and ask via **AskUserQuestion** — **ratify** / **not yet** / **ended**. The offer's text states what ended means: the stage's exit criteria will not be met, the stage renders `ended`, and the mark is a slot edit that can be reversed by hand.

- **Ratify**: write `Complete: [x] <YYYY-MM-DD> (<who>)` into that stage's slot. If the stage was slotless, INSERT the `Complete:` line directly after the stage's `Depends-on:` line — or directly after the heading when no slots exist (the format's omission semantics). Record the ratified stage id in the session's emit (`completions_ratified`).
- **Not yet**: the slot stays `[ ]`, nothing else changes, and the readout continues to render awaiting-ratification.
- **Ended**: write `Complete: [~] <YYYY-MM-DD> (<who>)` into that stage's slot with the same insert rule, and record the stage id in the session's emit under `stages_ended` — never under `completions_ratified`. The readout then renders `ended (declared <date> by <who>)`.

The offer fires on the awaiting state ONLY: a stage rendering `ended`, `ended-from-explore` or `complete` is offered nothing.

**The unprompted route** — the mark is the USER's word. Inside an architect session the user may declare a stage ended with no offer having fired — the only route for a `premised` stage, which no offer reaches. Write the same `[~]` production with the same insert rule, and record the id under `stages_ended`, when the stage's observed state (read from `orbit architecture status --json`) is `premised`, `quiescent` or `concluded` AND its `Complete:` slot is UNDATED (absent, or `[ ]`). Both tests read off that payload alone, no doc re-read: the stage is UNDATED when its `ratified` and `ended` fields are both `false` (absent and `[ ]` are indistinguishable there and need not be told apart); the LIVE citer to name is the `citing[]` entry of kind `active-change`, else the `explore` entry that lacks `concluded: true` (a concluded explore citer carries that flag). Otherwise DECLINE and write nothing:

- on a LIVE stage (`in-change`, or a live `exploring`): name the live citing artifact and the act that would make the mark supportable — archive the change, or conclude the exploration. These are the two observations the engine's composition table refuses, and this flow never writes them.
- on a slot that already carries a DATED mark (`[x]` or `[~]`): name the existing mark and point at the hand edit as the way to reverse or re-date it — this flow never authors a reversal of a recorded mark.

The body NEVER checks or ends a stage on its own judgment, and never nags: the offer fires when the user opens the doc's architect session — not as an interruption elsewhere. (A mark on an observation the engine's composition rule refuses is an inconsistency the status render and audit-drift surface; this flow only ever writes marks the engine's observation supports — and the ended mark is supported wherever no live work contradicts it, `premised` included. The composition table is owned by `orbit-architecture-engine`'s `Computed stage state with completion-as-ratification` requirement; this body names it and restates none of it.)

### 5.5. Arc-done readout: the program PR's human acts (D-arc Stage D6)

On EVERY invocation — unconditional and IDEMPOTENT — check whether the doc is ARC-DONE:
every stage archived AND the closing `--as architecture` review recorded (from
`orbit architecture status --json` plus the architecture trail). This check is deliberately
NOT gated on the ratification interaction above: the natural ordering is final-stage archive
→ final-stage ratification → closing review, so arc-done becomes true at the LAST step, after
that interaction has already passed. A ratification-gated readout would never fire.

When arc-done, run `orbit pr program <doc> --json` and surface the program PR and its human
acts per `references/pr-resolution.md` — recommend, NEVER invoke; this body makes no outward
write. The engine locates the PR (the latest URL-bearing record, else the constrained query),
validates it LIVE and falls through on a positive invalidation; the readout is NEVER SUPPRESSED
by any outcome, since a silent readout is indistinguishable from an unfinished program. The
acts (`human_acts`: ready, then merge) are the user's; orbit flips nothing here and merges
nothing anywhere. The readout repeats on every later invocation until the PR is no longer
draft. A whole-program body rewrite is OPTIONAL polish available on request, never a required
transition step.

### 6. Out of scope (deliberately — D-d2-6 rungs 6–8)

The body does NOT carry explore-grade thinking-partner stance prose, stage-lifecycle helpers (spin-up/close-out choreography), or retrofit guidance for converting legacy docs. Those are later rungs; v1 is create/resume + capture + render + ratification.

## Run-summary emit (conversation-boundary timing, architecture trail — via the engine emit surface)

(Per `orbit-run-summary-emit` — `/orbit:architect` is a multi-turn conversational command; emit at conversation boundaries: user stop/pause signal, or AI-initiated wrap. Composed and written via `orbit emit architect` — `orbit-emit-composition`.)

**No emit without sweep** (D-arc Stage D5, leak-hardening layer 2 — shared with named-mode explore): the Step 4 R-d-8 residency sweep precedes EVERY boundary emit, riding this existing trigger with no new prompt — the emit describes the swept doc. Architect fires no BEGIN emit (the begin+boundary genre is named-mode explore's).

Compose the payload — `final_assessment`, `stages_touched`, `rulings_captured`, `completions_ratified` (may be empty), `stages_ended` (the stage ids this session declared ended, by the offer or the unprompted route — may be empty; optional, so every earlier emit stays valid), `handoff`, + the required nullable `model` — into a temp file and invoke:

```bash
orbit emit architect --doc <doc-name> --payload <payload-file>
```

The ENGINE owns the spine (`change: null` + `doc`), the FOURTH trail location (`orbit/architecture/.orbit-runs/`, shared by all docs, never moved by change archiving), timestamp + collision handling, and mirrors the handoff's `next_command` into `next_recommended`. The `handoff` section is arc ruling R-d-9(b), complied with from birth: `boot_sequence` entries are POINTERS (paths + one-line why), never content copies; `next_command` is the one command a cold session would run first; `model_hint` and `seam` complete the shape. `/orbit:review --as architecture` emits carry the same `handoff` shape (owned here).

## Output at session end

Render the doc's computed position from `orbit architecture status` verbatim, then the eligibility line (`Ready when you are: <command>` — never an imperative). Completing this command ENDS the turn there.
