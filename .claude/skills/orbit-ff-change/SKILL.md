---
name: orbit-ff-change
description: Fast-forward through orbit artifact creation. Use when the user wants to quickly create all artifacts needed for implementation without stepping through each one individually.
license: MIT
compatibility: Requires orbit CLI.
metadata:
  author: openspec
  version: "1.0"
  generatedBy: "2.0.1"
---

Fast-forward through artifact creation - generate everything needed to start implementation in one go.

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
   This creates a scaffolded change at `orbit/changes/<name>/`.

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
      - Show brief progress: "✓ Created <artifact-id>"

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
- If a change with that name already exists, suggest continuing that change instead
- Verify each artifact file exists after writing before proceeding to next

---

# Orbit additions

## Four execution disciplines (epitome)

The four disciplines from `orbit-conventions`, embedded per body; detail lives where each fires.

- **Read-before-reference (authoring-time)**: read a construct's actual definition before naming it; unverifiable → ask or leave a `@review:` marker, never guess.
- **Change completeness (modification-time)**: apply substantive modifications fully across ALL affected artifacts; after mechanical edits, sweep for residue AND new bugs the replacement introduced.
- **Pushback (review-time)**: verify each flagged issue against current state before acting; suppress stale findings with evidence rather than re-fixing already-fixed state.
- **No-chaining (turn boundary)**: invoke only the orbit workflow commands the user's message explicitly requests; completing a command ENDS the turn at the position readout + the engine's eligibility line — gate `passed` means *eligible*, not *commanded*.

## Base-fingerprint capture (NEW step)

(Per `orbit-base-fingerprints`' `Fingerprint capture at every spec-authoring point` requirement)

Immediately after the change's delta specs are generated (the `specs` artifact is written), run:

```bash
orbit fingerprint "<name>"
```

This stamps `base_fingerprints` into the change's `.openspec.yaml` — the SHA-256 of each
MODIFIED/REMOVED/RENAMED requirement's CURRENT baseline block — so the archive-time guard can
detect a parallel change landing on the same requirements (no silent spec data-loss). Stamping is
add-missing-only (`--refresh` is the deliberate re-stamp after reconciling a divergence);
ADDED-only changes stamp nothing; a "skipped — requirement not found in live baseline" warning
means the delta references a nonexistent requirement (fix the delta; validation also catches it).

## PR lifecycle (config-gated — D-arc Stage D6)

`ff` is propose-in-one-breath, so it carries the IDENTICAL choreography — a change is never
treated differently for how it was started.

**Position (this section is placed last for reading, not for running).** Phase 1
(`orbit pr select`, then running its switch) runs BEFORE Step 2 (`orbit new change`): that
step writes `orbit/changes/<name>/.openspec.yaml`, a path a compatible branch already TRACKS,
so a switch attempted after it is exactly the `git switch` refusal the ordering exists to
prevent. Phase 2 (generation + validation, ON that branch) IS Steps 2–4; phase 3 (the no-CI
note, then `orbit pr publish`: its land-and-open segment, the emit, then its record segment)
runs after Step 5's final status.

Read the RESOLVED regime from the engine FIRST
— `orbit status --json`, field `pr` (never parse `orbit/config.yaml` yourself: the value
set is closed and every inert path already resolves to `never` with the reader's warning):
`never`, absent, or an inert value/shape means RETURN IMMEDIATELY — probe nothing, emit no
note. Only an ACTIVE mode loads `references/pr-choreography.md` and follows it: the
`orbit pr` call at each phase, the table you act on its record by, and the judgment that stays
yours. The engine computes every precondition, the commit scope and the program-PR query.

(`/orbit:new` and `/orbit:continue` are explicitly NOT extended: they never attach, and a
change built that way reaches archive unattached — the tail's PR path terminates there before
any remote or `gh` work.)

## Run-summary emit (one-shot at command completion — via the engine emit surface)

(Per `orbit-run-summary-emit`; composed and written via `orbit emit ff` — `orbit-emit-composition`.)

At command completion, compose the narrative payload (`final_assessment`, the required
nullable `model`, and — when `orbit pr publish` ran — the `pr_attachment` object per
`references/pr-choreography.md`) into a temp file and invoke:

```bash
orbit emit ff --change <name> --payload <payload-file>
```

The ENGINE owns the spine, the trail path, timestamp + collision handling, and `next_recommended` composition (propose-shaped: the review-gate pointer). Never hand-compose the JSON.

When `publish` printed a second segment, the emit is NOT the last act: run that segment with
the just-written emit's path as `<emit-path>`, so the attachment record the archive reads
reaches the branch. After a failed step or a PR-half degradation the emit stays LOCAL; the
failure line names the recovery.

**Completion-prompt override (chat)**: where the upstream steps above prompt "Run `/orbit:apply` or ask me to implement", instead prompt: "Run `/orbit:review <name>` — review the artifacts before implementation."

