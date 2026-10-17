# Reference: the blind pair (`--reviewer blind-pair`)

This reference runs a BLIND PAIR — one `fresh` pass and one `external` pass of the mode, blind to each other — in ONE invocation. Its step order is `orbit-review`'s `The blind-pair reviewer runs both halves in one invocation`; what the launch record means is `orbit-engine-gates`' `A pair's membership is computed from its launch`. The external half's packaging, launch, save and commit are `references/external-handoff.md`'s (loaded with this one) and are NAMED below, never restated; the fresh half is the trunk's **Dispatching a fresh pass**, also named, not restated.

**Input**: the change name and `--as proposal|system`, resolved by the review trunk before this reference loads (architecture mode never reaches it).

**This session orchestrates; it is neither half.** It runs no pass work, writes no pass file, and reads neither half's return before both are committed — beyond the trail listing Step 6 needs (filenames and the `reviewer_class` field). Every git act is a body step (zero engine git), and every commit adds NAMED paths only — `git add <paths>` then `git commit --only <paths>` — so work the user stages during the run stays out.

**Other flags.** Every other flag of the command applies to each half exactly as it applies to that half's single run — the fresh half as under `--reviewer fresh`, the external half as under `--reviewer external`.

## Steps

### 1. Preflight and the runner

Run `git status --porcelain`. ANY output refuses the pair: write NOTHING — no prompt file, no T0 — dispatch no subagent, launch no runner, and print `Not run: a blind pair reviews the committed state, and the working tree has uncommitted changes:` followed by each uncommitted path, then `Commit the pending work, then re-run the review.` Never auto-commit the user's pending work. Unpushed commits are allowed: they ride Step 3's push.

Then read the runner ONCE — this IS the handoff reference's Step 3a read, which is not repeated:

```bash
orbit external runner --json
```

Record the ROUTE: `reachable: true` → LAUNCHED; `{"runner": null}` or `reachable: false` → PASTED. The route decides what the packaging writes (the prompt's `## Repo` line, the T0's `target`) and Step 4; the runner is never read again in this run.

### 2. The launch

Read the REVIEWED COMMIT now: `git rev-parse HEAD`. Run the handoff reference's Steps 4–7 for the route — the iteration count, the cycle context, the recommended-session note, and the prompt file (on the launched route, Step 7's `<run-dir>` and worktree `## Repo` line; on the pasted route, the pair-half `## Repo` line of its Step 3b, naming the REVIEWED COMMIT). Then emit the T0 with `pair: true` — the payload shape is the handoff reference's pair-launch example (`target` the runner's `name` on the launched route, `null` otherwise):

```bash
orbit emit review-external --change <change-name> --payload <payload-file>
```

The prompt file and this T0 are ONE act, the LAUNCH. Its token is L.

### 3. BASE

Commit the prompt file and the T0 — and nothing else — as the HANDOFF COMMIT, on BOTH routes, and push:

```bash
git add <prompt-path> <t0-path>
git commit --only <prompt-path> <t0-path> -m "External review handoff (<as>, iter <N>): <change-name> — blind pair launch"
git push
```

That commit is the pair's BASE. A failed push, or no remote, is REPORTED and the run goes on; record whether the push landed — every later attestation says "pushed" only when it did.

### 4. The route

Step 1's reading decides: LAUNCHED takes Step 5a, PASTED takes Step 5b. Step 5c runs on both, after Step 3.

### 5a. The external half, launched

Run the handoff reference's 9b (the worktree at BASE, which is the handoff commit) and 9c (the launch, in the background, with `run_in_background`). Print its 9e items 1–4, then, in place of item 5, the recovery line under **Session end** below. Its return stays at `<run-dir>/return.md`, OUTSIDE the repository, and is NOT saved yet (the handoff reference's 9d hands control back here).

### 5b. The external half, pasted

Print the handoff reference's Step 8 items in order, with item 4 the output Step 3's push left selected: when the push landed, the attestation `Prompt committed (<short-sha>) and pushed to <remote>/<branch>` and the pull invocation; when it did not, `Handoff blocked: the handoff commit <short-sha> is not pushed. Push, then hand off: Pull <repo URL> and read <prompt-path>. ...` — the prompt is already committed, so only the push leads.

### 5c. The fresh half

Dispatch the fresh half per the trunk's **Dispatching a fresh pass** — a clean-context subagent with that section's brief, unchanged — in the background (the **Task tool** with `run_in_background`). It reads the live checkout at BASE and persists through `orbit emit review` with `reviewer_class: "fresh"` like any fresh pass; it carries no launch token.

### 6. Wait

Wait on both background completions — on the pasted route, the fresh half's only. A half ends when its process exits or the user stops it; invent no timeout, and do not poll.

Whether the fresh half LANDED is read from the TRAIL, never from the worker's exit: list `orbit/changes/<change-name>/.orbit-runs/review-<as>-*.json` and read each one's `reviewer_class` field only. The earliest one with `reviewer_class: "fresh"` and a token later than L IS the landed member, however the worker ended (a worker stopped after its emit landed); with none, the fresh half is MISSING. The external half is MISSING when its run exits non-zero or Step 8's save refuses it. Nothing is committed for a missing half.

### 7. The fresh pass file

Commit the landed fresh pass file ALONE, BEFORE Step 8:

```bash
git add <fresh-path>
git commit --only <fresh-path> -m "Fresh review (<as>): <change-name> — blind pair, fresh half"
```

### 8. The external return

LAUNCHED route only, and only after Step 7 — or once the fresh half is known MISSING: save the return with the handoff reference's 9d command, `--launch` taking L:

```bash
orbit external save <change-name> --as <as> --from <run-dir>/return.md --launch <L> --json
```

A non-zero run exit or a save refusal is the handoff reference's **A failed run** paragraph: nothing committed for the return, its cause and raw path reported, its paste fallback printed with the commit line naming the REVIEWED COMMIT — except after an apply later than the launch, which has no fallback.

### 9. The saved return

Commit the saved file ALONE exactly as the handoff reference's 9d does — the message written to `<run-dir>/commit-msg.txt` with the removed lines quoted, passed with `-F` — but WITHOUT 9d's `git push`:

```bash
git add <saved-path>
git commit --only <saved-path> -F '<run-dir>/commit-msg.txt'
```

### 10. Push

ONCE, after Steps 7 and 9 (whichever committed): `git push`. A failed push is reported; the commits stand; no retry.

### 11. The worktree

LAUNCHED route only: `git worktree remove --force <run-dir>/worktree`, after the return was read. A failed removal is reported, never fatal.

### 12. Reports

For each LANDED pass — the fresh pass, then the saved external return — render `orbit status --change <change-name> --report <TS>` and paste it.

### 13. End

Render the position readout and the engine's eligibility line from `orbit status --change <change-name> --json` — `Ready when you are: <next_command>`. The walk is NEVER invoked: `/orbit:address-reviews` is the user's to run (no-chaining). When a half is missing — after Step 5b, or a run that failed or wrote nothing — the pair ends OPEN and no half covers alone; read what the gate reports from that same status JSON, never from this text. With one half landed it carries `openPair` naming the missing class (after Step 5b, `{missing: "external"}`: the pasted return completes the pair when it is saved); with BOTH missing it carries no `openPair` and its reason says neither member has landed.

## Session end

A session that ends mid-pair leaves work outside the record. On the LAUNCHED route print, in place of the handoff reference's 9e item 5:

`Raw output: <run-dir>/return.md — if this session ends before the pair does: first, IF a fresh pass file landed (the review-<as>-*.json with reviewer_class "fresh" later than <L>), commit it alone (git add <path>, then git commit --only <path>) — with none, the pair stays open missing its fresh half — then save the return with: orbit external save <change-name> --as <as> --from <run-dir>/return.md --launch <L>, commit the saved file alone, push, and run git worktree remove --force <run-dir>/worktree`

On the PASTED route print: `If this session ends before the fresh half does: IF a fresh pass file landed (the review-<as>-*.json with reviewer_class "fresh" later than <L>), commit it alone (git add <path>, then git commit --only <path>) and push; with none, the pair stays open missing its fresh half.`
