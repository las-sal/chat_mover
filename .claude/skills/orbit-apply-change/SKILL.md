---
name: orbit-apply-change
description: Implement tasks from an orbit change. Use when the user wants to start implementing, continue implementation, or work through tasks.
license: MIT
compatibility: Requires orbit CLI.
metadata:
  author: openspec
  version: "1.0"
  generatedBy: "2.0.1"
---

Implement tasks from an orbit change.

**Input**: Optionally specify a change name. If omitted, check if it can be inferred from conversation context. If vague or ambiguous you MUST prompt for available changes.

**Steps**

0. **Consent at entry (provenance rule — per `orbit-lifecycle-consent`)**

   Apply is a consent-scoped command (the `review-proposal` gate carries `consent: user-invoked`). Determine invocation provenance — an observable transcript fact, never a judgment of delegated intent:
   - **User-invoked**: the triggering turn contains an explicit user invocation — the typed `/orbit:apply` command, or an unambiguous same-turn prose request naming the act ("apply it", "implement the change"). Proceed with ZERO added prompts (only anomaly prompts — the Step 3 gate inflection — may interrupt).
   - **AI-mediated**: everything else — delegation phrases ("finish the cadence"), inference ("continue"), a handoff document, or an eligibility readout pointing here. Fire a consent **AskUserQuestion** BEFORE any write (after the read-only status/instructions loads in Steps 2–3, so the prompt can show real state): the position readout, what apply will write ("begin implementing N tasks from the artifacts"), and exactly two options — **Proceed** / **Abort**. On Abort: stop; no writes, no run summary.
   - **When provenance is uncertain, treat the arrival as AI-mediated** — erring toward one extra click, never toward a silent proceed.

   **Ordering invariant**: provenance is CLASSIFIED at entry (it is a fact about the triggering turn, known before anything runs); the consent prompt itself — and the era stamp below — fire AFTER read-only discovery (change selection, the Step 2–3 status/instructions loads) and BEFORE any write or anomaly prompt. Read-only steps never require consent; writes always follow it.

   Record the consent story for this invocation: `user-invoked` (user-typed) or `prompted` (prompt fired, user proceeded) — it lands in every apply emit this session writes.

   **Consent-era stamp (migrate-on-touch)**: once consent is established (user-typed provenance, or Proceed at the prompt), read the change's `.openspec.yaml`. If it lacks `schema_version`, stamp `consent_era_from: <current UTC timestamp, YYYY-MM-DDTHH:MM:SSZ>` into it (add-only; never overwrite an existing stamp). This marks a pre-capability change as tripwire-covered from this touch onward (per `orbit-lifecycle-consent`'s consent-era marker).

1. **Select the change**

   If a name is provided, use it. Otherwise:
   - Infer from conversation context if the user mentioned a change
   - Auto-select if only one active change exists
   - If ambiguous, run `orbit list --json` to get available changes and use the **AskUserQuestion tool** to let the user select

   Always announce: "Using change: <name>" and how to override (e.g., `/orbit:apply <other>`).

2. **Check status to understand the schema**
   ```bash
   orbit status --change "<name>" --json
   ```
   Parse the JSON to understand:
   - `schemaName`: The workflow being used (e.g., "spec-driven")
   - Which artifact contains the tasks (typically "tasks" for spec-driven, check status for others)

3. **Get apply instructions**

   ```bash
   orbit instructions apply --change "<name>" --json
   ```

   This returns:
   - `contextFiles`: artifact ID -> array of concrete file paths (varies by schema - could be proposal/specs/design/tasks or spec/tests/implementation/docs)
   - Progress (total, complete, remaining)
   - Task list with status
   - Dynamic instruction based on current state

   **Handle states:**
   - If `state: "blocked"` (missing artifacts): show message, suggest using orbit-continue-change
   - If `state: "blocked-by-gate"` (C1 — the `review-proposal` gate is unpassed/stale at apply entry): fire the gate INFLECTION PROMPT via **AskUserQuestion** — **Address the gate** (halt; run the `next_command` the CLI returned, e.g. `/orbit:review --as proposal --fresh <name>`) / **Proceed anyway** / **Abort**. The gate NEVER hard-blocks (apply-parity). On **Proceed anyway**, record the decision in this session's apply emit as a `continuation`/`proceed` judgement entry carrying the gate, its state and its reason (copied from the CLI's `gate` object at decision time — see the Run-summary emit section) and continue to implementation. On **Address**, stop and run the next command. On **Abort**, stop with no changes.
   - If `state: "all_done"`: congratulate, then render the ENGINE-computed next step — read `next_command` (and `position`) from `orbit status --change "<name>" --json` and surface it verbatim. Do NOT hard-code the next command: the gate graph owns the lifecycle flow. Post-apply this resolves to the `review-system` gate's first step — which review that is depends on the schema's cadence and the project's review preference, so it is read rather than predicted — which runs verify as its Pass 0 — verify is NOT a separate lifecycle step (it is Pass 0 of system review; a standalone verify gate would double-count).
   - Otherwise (`ready`): proceed to implementation

4. **Read context files**

   Read every file path listed under `contextFiles` from the apply instructions output.
   The files depend on the schema being used:
   - **spec-driven**: proposal, specs, design, tasks
   - Other schemas: follow the contextFiles from CLI output

5. **Show current progress**

   Display:
   - Schema being used
   - Progress: "N/M tasks complete"
   - Remaining tasks overview
   - Dynamic instruction from CLI

6. **Implement tasks (loop until done or blocked)**

   For each pending task:
   - Show which task is being worked on
   - Make the code changes required
   - Keep changes minimal and focused
   - Mark task complete in the tasks file: `- [ ]` → `- [x]`
   - Continue to next task

   **Pause if:**
   - Task is unclear → ask for clarification
   - Implementation reveals a design issue → suggest updating artifacts
   - Error or blocker encountered → report and wait for guidance
   - User interrupts

7. **On completion or pause, show status**

   Display:
   - Tasks completed this session
   - Overall progress: "N/M tasks complete"
   - If all done: render the engine's position + eligibility line (per Step 3's `all_done` handling — the gate graph owns what comes next)
   - If paused: explain why and wait for guidance

**Output During Implementation**

```
## Implementing: <change-name> (schema: <schema-name>)

Working on task 3/7: <task description>
[...implementation happening...]
✓ Task complete

Working on task 4/7: <task description>
[...implementation happening...]
✓ Task complete
```

**Output On Completion**

```
## Implementation Complete

**Change:** <change-name>
**Schema:** <schema-name>
**Progress:** 7/7 tasks complete ✓

### Completed This Session
- [x] Task 1
- [x] Task 2
...

All tasks complete.
Position: <the `position` string from `orbit status --change <name> --json` — e.g. `propose ✓ → review(proposal) (past) → apply ✓ → review(system) unpassed → archive blocked-by-gate`>
Ready when you are: <the `next_command` from `orbit status --change <name> --json`, rendered verbatim — post-apply the gate graph yields whichever class the first uncovered cadence slot needs, NEVER a hardcoded command>
```

**Position-readout convention (C1, D-c1-2)**: every handoff — this completion output AND the emit's `next_recommended` — renders the GATE GRAPH's computed `position` + `next_command` from `orbit status --change <name> --json` (the `--change` form; bare `orbit status` is the D3 orientation surface, whose sprint may be a DIFFERENT change). The skill does NOT hand-write the next lifecycle command — the graph owns the flow (`propose → review-proposal → apply → review-system → archive`), so the "what's next" token is always read from the engine, never authored here. Post-apply the graph yields the `review-system` gate's first step; WHICH CLASS that step needs depends on the schema's cadence, so it is read rather than predicted. It executes verify as its Pass 0.

**Output On Pause (Issue Encountered)**

```
## Implementation Paused

**Change:** <change-name>
**Schema:** <schema-name>
**Progress:** 4/7 tasks complete

### Issue Encountered
<description of the issue>

**Options:**
1. <option 1>
2. <option 2>
3. Other approach

What would you like to do?
```

**Guardrails**
- Keep going through tasks until done or blocked
- Always read context files before starting (from the apply instructions output)
- If task is ambiguous, pause and ask before implementing
- If implementation reveals issues, pause and suggest artifact updates
- Keep code changes minimal and scoped to each task
- Update task checkbox immediately after completing each task
- Pause on errors, blockers, or unclear requirements - don't guess
- Use contextFiles from CLI output, don't assume specific file names

**Fluid Workflow Integration**

This skill supports the "actions on a change" model:

- **Can be invoked anytime**: Before all artifacts are done (if tasks exist), after partial implementation, interleaved with other actions
- **Allows artifact updates**: If implementation reveals design issues, suggest updating artifacts - not phase-locked, work fluidly

---

# Orbit additions

## Four execution disciplines (epitome)

The four disciplines from `orbit-conventions`, embedded per body; detail lives where each fires.

- **Read-before-reference (authoring-time)**: read a construct's actual definition before naming it; unverifiable → ask or leave a `@review:` marker, never guess.
- **Change completeness (modification-time)**: apply substantive modifications fully across ALL affected artifacts; after mechanical edits, sweep for residue AND new bugs the replacement introduced.
- **Pushback (review-time)**: verify each flagged issue against current state before acting; suppress stale findings with evidence rather than re-fixing already-fixed state.
- **No-chaining (turn boundary)**: invoke only the orbit workflow commands the user's message explicitly requests; completing a command ENDS the turn at the position readout + the engine's eligibility line — blanket delegation covers work WITHIN the requested command, never the next one; gate `passed` means *eligible*, not *commanded*.

## Run-summary emit (chunk-aware — via the engine emit surface)

(Per `orbit-run-summary-emit`; composed and written via `orbit emit apply` — `orbit-emit-composition`.)

`/orbit:apply` is a chunked multi-turn command. Fire the emit at every chunk boundary, at a mid-chunk session pause, or once at session end for a no-chunking change — the conversation-boundary judgment is yours; everything else is engine-computed. Compose the payload into a temp file and invoke:

```bash
orbit emit apply --change <name> --payload <payload-file>
```

Payload fields (the ONLY things the AI supplies):

- `assessment_suffix` (optional) — one clause appended to the engine's computed final-assessment core (blockers, session notes worth persisting).
- `user_validation_tasks` (optional) — identifier list of unchecked tasks recognized as user-validation work (the ONE checkbox judgment the payload carries); the engine verifies each and derives the counts.
- `judgements` (rc04a) — the CADENCE JUDGEMENT record, an ARRAY. Present when a CADENCE JUDGEMENT was taken at this seam — a decision holding a CADENCE POSITION, whether or not independent output existed to cite; the key is OMITTED entirely when none was, so its presence means a judgement happened. Each entry: `kind` (`continuation` | `readiness`), `formed_against` (array of independent pass `<TS>` tokens; may be EMPTY only on a `continuation`/`proceed` and only when the trail carries no accepted independent pass earlier than this emit — `orbit-run-summary-emit`'s totality rule, which the write gate enforces; named here, not restated), `disposition`, `reasoning` (prose), `ratified_by` (`ai` | `user` — never inferred). A `continuation/proceed` additionally carries `gate`/`gate_state`/`gate_reason`; a `readiness` carries `accepted: [{claim, why}]`. The CARRIER TABLE IS CLOSED and enforced by KIND as well as by command: **apply admits `continuation` only** (a `readiness` here is refused — the cadence does not end at apply). The write gate also REFUSES any entry citing a token that is not STRICTLY earlier than this emit's own, or that resolves to no independent pass on the trail, and an EMPTY citation on a `continuation`/`proceed` when an independent pass DOES precede the emit (naming the latest one) — belief is not observable, ordering is.
  **AT THIS SEAM**: when Step 3's inflection prompt was answered **Proceed anyway**, compose a `continuation` entry with `disposition: "proceed"` carrying `gate`/`gate_state`/`gate_reason` as the CLI's `gate` object reported them at decision time — this entry is the SOLE record of the decision. `formed_against` is the independent pass tokens the decision was taken knowing about; when the trail carries none earlier than this emit, write the entry anyway with `formed_against: []` — the write gate accepts an empty citation exactly when the trail bears it out, and refuses it naming the latest preceding pass when it does not. The token source is the TRAIL ITSELF, not `orbit status`: the change-tier status payload reports gate spend COUNTS and reason strings, never pass tokens. List `orbit/changes/<change-name>/.orbit-runs/` and take the `<TS>` of each `review-<mode>-<TS>.json` whose `reviewer_class` is `fresh` or `external`, plus each `external-<mode>-<TS>.md` the trail reader ACCEPTED as a pass — a return the gate's `reason` names as REJECTED is not citable, and enumerating filenames alone over-counts by exactly those. Which passes count is `orbit-run-summary-emit`'s rule (the trail reader's pass set); this body names it and does not restate it — the write gate enforces it and names the pass it refuses on.
- `consent` — `"user-invoked" | "prompted"` per Step 0's provenance classification (D1, `orbit-lifecycle-consent`); CONSTANT across one invocation's chunk emits; a consent Abort writes NO summary.
- `model` — the emitting AI's model identity (required, nullable).

The ENGINE owns everything else: chunk detection from the tasks.md preamble (malformed preamble → stderr warning + no-chunking fallback), chunk identity + completion, task arithmetic, `files_touched` against the prior emit's `diff_base` tree snapshot, the whole `next_recommended` advancement (next chunk / mid-chunk resume / the gate graph's `next_command` on apply-complete), spine, filename, and collision handling. Never hand-compose them.

**Completion-prompt override (chat)**: on `all_done`, do NOT congratulate-and-suggest-archive (upstream) and do NOT hand-write `/orbit:verify` — instead render the gate graph's computed `next_command` + `position` from `orbit status --change <name> --json`. The lifecycle flow lives in the gate graph, not in this body; verify is Pass 0 of the `review-system` step the graph points to, not a separate lifecycle node (D5 — a separate verify gate would double-count).

**Why chunk-aware**: per-chunk emits bound post-apply regression bisection to a single chunk's task set (typically 10-20× blast-radius reduction) and give clean resume boundaries between sessions.

