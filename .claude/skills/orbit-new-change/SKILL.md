---
name: orbit-new-change
description: Start a new orbit change using the experimental artifact workflow. Use when the user wants to create a new feature, fix, or modification with a structured step-by-step approach.
license: MIT
compatibility: Requires orbit CLI.
metadata:
  author: openspec
  version: "1.0"
  generatedBy: "2.0.1"
---

Start a new change using the experimental artifact-driven approach.

**Input**: The user's request should include a change name (kebab-case) OR a description of what they want to build.

**Steps**

1. **If no clear input provided, ask what they want to build**

   Use the **AskUserQuestion tool** (open-ended, no preset options) to ask:
   > "What change do you want to work on? Describe what you want to build or fix."

   From their description, derive a kebab-case name (e.g., "add user authentication" → `add-user-auth`).

   **IMPORTANT**: Do NOT proceed without understanding what the user wants to build.

2. **Determine the workflow schema**

   Use the default schema (omit `--schema`) unless the user explicitly requests a different workflow.

   **Use a different schema only if the user mentions:**
   - A specific schema name → use `--schema <name>`
   - "show workflows" or "what workflows" → run `orbit schemas --json` and let them choose

   **Otherwise**: Omit `--schema` to use the default.

3. **Create the change directory**
   ```bash
   orbit new change "<name>"
   ```
   Add `--schema <name>` only if the user requested a specific workflow.
   This creates a scaffolded change at `orbit/changes/<name>/` with the selected schema.

4. **Show the artifact status**
   ```bash
   orbit status --change "<name>"
   ```
   This shows which artifacts need to be created and which are ready (dependencies satisfied).

5. **Get instructions for the first artifact**
   The first artifact depends on the schema (e.g., `proposal` for spec-driven).
   Check the status output to find the first artifact with status "ready".
   ```bash
   orbit instructions <first-artifact-id> --change "<name>"
   ```
   This outputs the template and context for creating the first artifact.

6. **STOP and wait for user direction**

**Output**

After completing the steps, summarize:
- Change name and location
- Schema/workflow being used and its artifact sequence
- Current status (0/N artifacts complete)
- The template for the first artifact
- Prompt: "Ready to create the first artifact? Just describe what this change is about and I'll draft it, or ask me to continue."

**Guardrails**
- Do NOT create any artifacts yet - just show the instructions
- Do NOT advance beyond showing the first artifact template
- If the name is invalid (not kebab-case), ask for a valid name
- If a change with that name already exists, suggest continuing that change instead
- Pass --schema if using a non-default workflow

---

# Orbit additions

## Four execution disciplines (epitome)

The four disciplines from `orbit-conventions`, embedded per body; detail lives where each fires.

- **Read-before-reference (authoring-time)**: read a construct's actual definition before naming it; unverifiable → ask or leave a `@review:` marker, never guess.
- **Change completeness (modification-time)**: apply substantive modifications fully across ALL affected artifacts; after mechanical edits, sweep for residue AND new bugs the replacement introduced.
- **Pushback (review-time)**: verify each flagged issue against current state before acting; suppress stale findings with evidence rather than re-fixing already-fixed state.
- **No-chaining (turn boundary)**: invoke only the orbit workflow commands the user's message explicitly requests; completing a command ENDS the turn at the position readout + the engine's eligibility line — gate `passed` means *eligible*, not *commanded*.

## Run-summary emit (one-shot at command completion — via the engine emit surface)

(Per `orbit-run-summary-emit`; composed and written via `orbit emit new` — `orbit-emit-composition`.)

At command completion, compose the narrative payload (`final_assessment` + the required nullable `model`) into a temp file and invoke:

```bash
orbit emit new --change <name> --payload <payload-file>
```

The ENGINE owns the spine, the trail path, timestamp + collision handling, and `next_recommended` composition (completion-aware: continue-vs-review from artifact state). Never hand-compose the JSON.

