# Reference: the external-handoff branch (`--reviewer external`)

This branch packages a review request for an external AI (codex, fresh Claude, GPT, etc.) to perform a second-opinion review of an orbit change — the behavior formerly invoked as the standalone `/orbit:review-external` command (RETIRED at D-arc Stage D5; the RECORD VOCABULARY IS FROZEN: the T0 emit keeps `command: "review-external"` and its `review-external-<TS>.json` filename, prompts keep `external-prompt-<as>-<TS>.md`, findings keep `external-<as>-<TS>.md` — gates, orientation WAITING arithmetic, the report ordinal, and the address-reviews parser all key on those names). The branch writes a self-contained markdown prompt to `orbit/changes/<change-name>/.orbit-runs/external-prompt-<as>-<TS>.md` (committed; the external AI reads it from the repo), then takes ONE of two routes. **With no runner launched** (none recorded, or the recorded one not on `PATH`) it emits a short invocation snippet to chat that tells the user what to paste into the external AI's session — the handoff exactly as it was before runners existed. **With the user's recorded runner reachable** it launches that runner on the prompt itself, in a throwaway worktree at the handoff commit, and saves and commits the return — no paste (Step 9).

**Runs the review ONLY through the user's recorded runner, and NEVER ingests findings.** The runner is the one the user recorded in their per-user global config (`orbit-external-runner`; read through `orbit external runner --json`); a runner merely present on `PATH` is never launched. With none, the external AI is the user's to run. Either way, ingestion is the change-scoped `/orbit:address-reviews <change-name>`, which discovers the saved return as an outstanding pass, or an explicit `--from-file <path>` aim — invoked separately, never by this branch.

**Input**: the change name and `--as proposal|system` resolved by the review trunk before this reference loads (`--reviewer external` requires `--as proposal|system`; architecture mode never reaches this branch). Compose the T0 emit via `orbit emit review-external --change <name>` — the engine owns the spine, the recommendation `orbit-run-summary-emit`'s `Review-external T0 multi-step recommendation` owns, and `awaiting_findings`.

## Disciplines

The four execution disciplines travel with the review body that loaded this reference; the one branch-specific note: the prompt instructs the external AI **not** to apply pushback (`Do not push back on stale findings`) — pushback is enforced at resolution, in `/orbit:address-reviews`.

## Steps

### 1. Resolve the change

If a change name is provided, use it. Otherwise:
- Run `orbit list --json` to get available changes.
- Use **AskUserQuestion** to let the user select.

State `Using change: <name>` at the top of the chat output.

### 2. Resolve the mode

Mode comes from `--as proposal|system` if specified. If omitted:

1. Read `orbit/changes/<name>/tasks.md`.
2. **All unchecked** → infer `proposal`.
3. **All checked + code changes visible** (heuristic: `git log` shows commits after the change directory was created) → infer `system`.
4. **Ambiguous** → use **AskUserQuestion** to let the user pick.

Emit a one-line inference note in chat output when `--as` was omitted: `` Generating external-review prompt as `<as>` (inferred from tasks state). ``

### 3. Handoff preflight — committed-and-pushed state

The pull-based handoff only works if the external AI can actually see the reviewed state. Record two facts (used by Step 8):

1. **Working tree**: `git status --porcelain` — any output means the reviewed state is not fully committed (and the prompt file written in Step 7 will itself be uncommitted).
2. **Remote sync**: `git rev-list @{u}..HEAD --count` (skip if no upstream) — a non-zero count means local commits aren't pushed.

(The external AI pulls the repo, so it only sees what's committed AND pushed. A pull-based invocation emitted against dirty or unpushed state hands the external AI a repo without the change — the handoff silently reviews stale state or fails.)

If the repo has no remote at all, the preflight is satisfied by the local-path handoff route (see Graceful degradation).

**3a. The runner.** At this step, read the user's runner:

```bash
orbit external runner --json
```

It prints ONE object: `{"runner": null}`, or `{"runner": {"form", "name", "argv", "reachable"}}` with `{worktree}` and `{output}` placeholders in `argv` (any warning goes to standard error and the object is still `null`). The engine resolves the record and executes nothing; this branch holds no preset knowledge — use `argv` exactly as printed.

- `{"runner": null}` → the branch is UNCHANGED: Steps 4–8, then the T0 emit.
- `reachable: false` → UNCHANGED but for one extra item in Step 8 (item 6) naming the unresolved command.
- `reachable: true` → the LAUNCH route. Fact 1 above now DECIDES: a dirty working tree, read BEFORE the prompt file is written, means the reviewed state is not committed — do NOT launch and write NOTHING (no prompt file, no T0); print `Not launched: <name> reviews the committed state, and the working tree has uncommitted changes. Commit the pending work, then re-run the review.` and stop. Never auto-commit the user's pending work. A clean tree continues to Step 4; unpushed commits do not block — they go with the handoff push in Step 9.

**3b. A blind pair's half.** Decide whether this run is a HALF of a blind pair. Every half of a pair reviews the state the pair was launched on — the rule, its BASE and REVIEWED COMMIT, and its named limit are `orbit-review-external`'s `A pair's external half reads the pair's reviewed state`; this step is its procedure. Outside a pair, nothing in this step applies and every later step reads as written.

- **The pair's first run** — this reference was loaded by `references/blind-pair.md`. The pair reference owns the ORDER: its Step 1 is this branch's runner read (do not read the runner again here) and its dirty-tree preflight; its Step 3 makes the handoff commit, which IS the pair's BASE, and pushes it on both routes. This reference supplies the packaging (Steps 4–7), the T0 with `pair: true`, the launch (9b–9c), the save command and the commit message (9d), and the failed-run paragraph. The REVIEWED COMMIT is `git rev-parse HEAD` read BEFORE the handoff commit.
- **A RE-RUN of the pair's missing external half** — read `orbit status --change <name> --json`. When the mode's reviewed gate row carries `openPair: {missing: "external"}`, the run is a RE-RUN: find the OPEN launch L — the latest `review-external-<TS>.json` of this mode carrying `pair: true`, reading only its `mode` and `pair` fields — and list the trail's `apply-*.json` tokens. The re-run packages as usual — its own prompt, its own T0 WITHOUT `pair` (so it refills the open pair rather than launching another), its own handoff commit — and decides its WORKTREE COMMIT and SAVE TOKEN by whether an apply token is later than L:
  - **No apply later than L**: BASE is `git log --diff-filter=A --format=%H -- <L's T0 path> | tail -1` (a hash-only read) and the REVIEWED COMMIT is `git rev-parse <BASE>^1`. The worktree commit is BASE; the save token is L, so supersession is measured from the state the re-run reviews.
  - **An apply later than L**: the landed fresh member was emitted after that apply (one emitted before it would be stale, and the gate would report no `openPair`), so it reviewed the post-apply state, and the engine counts this run as the pair's missing member — never a single. The REVIEWED COMMIT is the state that member reviewed: `git rev-parse <M>^1`, where M is `git log --diff-filter=A --format=%H -- <member path> | tail -1` (the same hash-only read; the member is the earliest `review-<mode>-*.json` later than L whose `reviewer_class` field is `fresh`, read from that field alone). The worktree commit is that REVIEWED COMMIT; the save token is this run's OWN T0 token, which is later than the apply. When M is empty — the member's file is not committed — stop and print `The pair's fresh member <path> is not committed; commit it alone, then re-run the review.`
  On the launch route: 9b adds the worktree at the WORKTREE COMMIT, never at the re-run's own handoff commit (which holds the committed fresh partner); 9c feeds the prompt from the LIVE CHECKOUT's copy of the re-run's committed prompt file, since the worktree commit does not contain it; 9d saves with `--launch <SAVE TOKEN>`.
- **No `openPair`, and the latest launch's one landed member is STALE** — read from the trail, never from the gate's reason, whose text names the first failing clause, not the pair: the latest `pair: true` launch L of this mode has exactly ONE landed member (its earliest `review-<mode>-*.json` with `reviewer_class` `fresh`, or earliest `external-<mode>-*.md`, later than L — and none of the other class), no `address-reviews-*.json` names that member in its `source_path`, and an `apply-*.json` token is later than the member's token — a single. Print `The pair launched at <L> reviewed a superseded state (an apply landed after its <class> member); this run is an ordinary single on the current state — a <class> review lands as a single and covers, and a run of the other class becomes that pair's missing member and covers nothing.` and continue as a single.
- **Any other state** — no `openPair` for the mode, or one missing `fresh` — a single; nothing here applies.

**A pair half's reviewed commit.** For a pair half — first run or re-run — printed for PASTE, the prompt's `## Repo` line (Step 7) reads `<repo URL or path> — read the repository at commit <REVIEWED COMMIT>`, and in system mode the read list's commit range ends at that commit, not `HEAD` (`git diff <change-start>..<REVIEWED COMMIT>`), with the change's files read at it (`git show <REVIEWED COMMIT>:<path>`); and when a LAUNCHED pair half fails, the paste fallback's commit line (9d) names the REVIEWED COMMIT in place of `<handoff-sha>`. The re-run test is this body's reading of the trail; the gate's computation is authoritative.

### 4. Count iterations (per mode)

In `orbit/changes/<name>/.orbit-runs/`, count files matching `external-<as>-*.md` (findings files from prior external reviews in this mode — distinct from `external-prompt-<as>-*.md` which are prompt files).

- N matching files → this is iteration N+1.
- 0 matching files → iteration 1; note `first external review for this change in <as> mode`.

### 5. Load cycle context

The "Cycle context" section of the prompt carries the **iteration number ONLY** (Step 4) — no finding, open or resolved, internal or external, and no pointer at the trail for the reviewer to read. An external pass is REVIEW pass genre, and what a REVIEW-genre brief may carry is `orbit-conventions`' `Review mode decision framework`'s rule, stated there once. This branch still READS the trail to count iterations (Step 4) and to pick the recommended session (Step 6); the reviewer never does.

If `.orbit-runs/` is absent or holds no prior external file for this mode: iteration 1.

### 6. Compute the recommended-session note

Read the `**Reviewer**:` field from existing `external-<as>-*.md` files in `.orbit-runs/` (these record which AI did each prior review). Pick the phrasing:

- **Iteration 1**: `Fresh session recommended — first external pass; sets independent baseline. Pick any AI (codex / fresh Claude / GPT / etc.).`
- **Iteration 2**: `Fresh session in a DIFFERENT AI than iter 1's reviewer recommended (model diversity catches different blind spots). If iter 1 was <prior reviewer>, try <suggest different model>.`
- **Iteration 3+**: `Fresh session in a previously-unused AI recommended (maximum independence); when every available AI has reviewed this change in this mode, a fresh session of the least-recently-used.`

Least-recently-used is decided by ONE ordering input: each reviewer's latest `external-<as>-*.md` token in this mode; the reviewer whose latest token is oldest is least-recently-used. A continued same-AI session is never recommended: it would carry its prior findings in its own head into a REVIEW-genre pass (the owner's brief rule, above).

### 7. Write the prompt file

Compose the full self-contained prompt (per the reference template below) and write to:

```
orbit/changes/<change-name>/.orbit-runs/external-prompt-<as>-<TS>.md
```

`<TS>` is ISO-8601 with hyphens (e.g., `2026-05-18T14-35-23Z`). Create `.orbit-runs/` if it doesn't exist. The file is **committed**, not gitignored.

**On the launch route**, first fix the run's scratch directory OUTSIDE the repository: `<run-dir>` = `<absolute system temp dir>/orbit-external-<change-name>-<TS>` (the prompt's `<TS>`; resolve the temp dir with `node -p "require('os').tmpdir()"`). The worktree will be `<run-dir>/worktree`, the runner's `{output}` `<run-dir>/return.md`, its log `<run-dir>/runner.log`. The prompt's `## Repo` line names `<run-dir>/worktree` — the runner's working directory, a checkout of the handoff commit — NEVER the live checkout's path. (A pair's re-run: a checkout of BASE, Step 3b.) **On the paste route**, a pair half's `## Repo` line names the repository and the pair's REVIEWED COMMIT (Step 3b); a single's is the repository as before.

Mode-specific content:

- **"What to read for THIS review"** lists files appropriate to the mode (proposal mode emphasizes the change directory artifacts; system mode adds `git diff`, codebase paths, lens files).
- **"What to look for"** enumerates the 9 proposal-mode passes or the 7 system-mode passes (see below).

The **"Output format"** block inside the prompt MUST appear verbatim — the section headers (`## CRITICAL` / `## WARNING` / `## SUGGESTION` / `## Blocks` / `## Direction`) and the field labels (`**File**:`, `**Description**:`, `**Reproduction**:`, `**Disposition**:`) are what `/orbit:address-reviews --from-file` and the report renderer parse. Deviating breaks ingestion. The `## Severity` paragraph before it is `orbit-conventions`' Severity ladder, mirrored byte-equal (a parity test holds it) — carry it as written.

### 8. Emit the chat invocation snippet (no runner launched)

On the launch route, skip this step: Step 9 owns the chat output. Otherwise print to chat, in this exact order:

1. **(optional)** Mode-inference note when `--as` was omitted: `` Generating external-review prompt as `<as>` (inferred from tasks state). ``
2. **(required)** Recommended-session note: `Recommended session: <phrasing from Step 6>`
3. **(required)** The prompt file path: `Prompt: orbit/changes/<change-name>/.orbit-runs/external-prompt-<as>-<TS>.md`
4. **(conditional — preflight gate)** ONE of:
   - **Preflight satisfied** (clean tree, no unpushed commits — or local-path route): FIRST affirmatively state the prompt's committed-and-pushed state with evidence — `Prompt committed (<short-sha>) and pushed to <remote>/<branch>` (or, on the local-path route, the equivalent naming the path) — NEVER implied by the mere absence of a warning; THEN the copy-paste-ready invocation: `Pull <repo URL> and read <prompt-file-path>. Follow its instructions; write findings to the path specified inside.` (Get `<short-sha>` from `git rev-parse --short HEAD` and `<remote>/<branch>` from `git rev-parse --abbrev-ref --symbolic-full-name @{u}` after the push.)
   - **Preflight failed** (dirty tree and/or unpushed commits): the pull invocation is WITHHELD. Emit instead: `Handoff blocked: <dirty tree | N unpushed commit(s)>. Commit the pending work (including the prompt file above) and push, then hand off: Pull <repo URL> and read <prompt-file-path>. ...` — the commit+push action leads; the pull text is framed as the after-push step, never as an immediately-usable instruction.
5. **(required)** The eventual findings path: `When findings come back: /orbit:address-reviews --from-file orbit/changes/<change-name>/.orbit-runs/external-<as>-<TS>.md (TS will be set by the external AI when it writes).`
6. **(conditional — a recorded runner with `reachable: false`)** `Recorded runner <argv[0]> not found on PATH — printing the prompt for paste.`

No other items. Required items always appear in the specified order. With nothing recorded, item 6 never appears and the output is the handoff's before runners existed. (The T0 emit's `next_recommended` mirrors the gate: when the preflight failed, it leads with the commit+push action before the paste step.)

### 9. Launch the recorded runner (launch route only)

Reached only with `reachable: true` and a clean tree (Step 3a). The engine never runs a process and reads no git state here; every git act and the launch are this body's steps.

**9a. The handoff commit.** Emit the T0 now (see Run-summary emit) with `target` set to the runner's `name`. Then commit the prompt file and the T0 emit — and nothing else — and push:

```bash
git add <prompt-path> <t0-path>
git commit --only <prompt-path> <t0-path> -m "External review handoff (<as>, iter <N>): <change-name>"
git push
```

A failed push, or no remote, is REPORTED and the launch PROCEEDS — the runner reads a local worktree and needs no remote. Record whether the push landed: every later attestation says "pushed" only when it did.

**9b. The worktree.** Add a detached worktree at the handoff commit, outside the repository:

```bash
git worktree add --detach <run-dir>/worktree <handoff-sha>
```

On a RE-RUN of a pair's missing external half (Step 3b), its WORKTREE COMMIT replaces `<handoff-sha>`: the worktree holds no fresh pass file of the pair.

**9c. The launch.** Substitute `{worktree}` → `<run-dir>/worktree` and `{output}` → `<run-dir>/return.md` into `argv` FIRST. Then build ONE command line that keeps every element exactly one argument: single-quote EVERY element, writing an embedded `'` as `'\''`; run it with the worktree as the working directory; feed the prompt by a `<` redirect; send the runner's own chatter to the log. The directory change is scoped to a subshell, so nothing after the launch runs inside the worktree:

```bash
( cd '<run-dir>/worktree' && '<argv[0]>' '<argv[1]>' … < '<run-dir>/worktree/<prompt-path>' > '<run-dir>/runner.log' 2>&1 )
```

On a pair's re-run the redirect reads the LIVE CHECKOUT's copy — `< '<repository root>/<prompt-path>'` — because the worktree commit does not contain the re-run's prompt. NEVER hand a recorded string to `sh -c`, and never join the argv unquoted. Run it with the Bash tool's `run_in_background` — an external review outlasts the foreground limit — and WAIT on its completion notification; do not poll. While it runs, print the launch output (items 1–5 of 9e).

**9d. The return.** **In a pair's first run, stop here and return control to `references/blind-pair.md`** once the run exits: the save waits until the pair's fresh pass file is committed (or the fresh half is known missing), and the pair's one push follows both commits — the order is the pair reference's; the commands below are what its steps run, with no `git push` of their own. On a pair's RE-RUN, `--launch` takes Step 3b's SAVE TOKEN — L when no apply is later than L, this run's own T0 token otherwise. Every step from here runs from the REPOSITORY ROOT — the live checkout the review was invoked in, never the worktree. When the run exits 0, save it — the engine cuts any preamble above the first unfenced `# External Review:` heading, checks the result with the trail reader and the report renderer, and refuses a return an apply has since superseded:

```bash
orbit external save <change-name> --as <as> --from <run-dir>/return.md --launch <T0 token> --json
```

It prints `{"path", "removed"}`. Commit the saved file ALONE — `git add` of that one path, then `git commit --only` on it, so work the user staged during the run stays out — with each removed line quoted in the message, then push. The removed lines are text the external AI wrote, so the message is DATA, never shell syntax: write it to `<run-dir>/commit-msg.txt` with a file write (not a shell heredoc or `echo`), and pass it with `-F` — NEVER interpolate it into `-m "…"`, where backticks and `$(…)` in a preamble would run:

```
External review (<as>, iter <N>): <change-name>

Removed above the heading by orbit external save:
> <removed line>
```

```bash
git add <saved-path>
git commit --only <saved-path> -F '<run-dir>/commit-msg.txt'
git push
```

(Omit the "Removed" paragraph when nothing was removed.) Then `git worktree remove --force <run-dir>/worktree` — a failed removal is reported, never fatal. Then render the return's report with `orbit status --change <change-name> --report <saved TS>` and paste it. Do NOT walk it: the walk is `/orbit:address-reviews`, invoked separately.

**A failed run** — a non-zero exit, or ANY `orbit external save` refusal (no unfenced heading, another change's heading, a reader rejection, an apply after the launch) — commits NOTHING for the return. Report the cause (the exit status, or the save's stderr) and the raw return's path (`<run-dir>/return.md`, when it exists; it stays outside the repository), remove the worktree as above, then print the paste fallback: Step 8 item 2 (the recommended-session note, now that the prompt is printed for paste); `The prompt's ## Repo line names the launch worktree, now removed — read the repository at <repo URL, or the live checkout's path> at commit <handoff-sha> instead.` — for a pair half, the pair's REVIEWED COMMIT in place of `<handoff-sha>` (Step 3b); the Step 8 item 4 pull invocation with its attestation when the handoff push landed, or, when it did not, `Handoff blocked: the handoff commit <short-sha> is not pushed. Push, then hand off: Pull <repo URL> and read <prompt-path>. ...` — the prompt is already committed, so only the push leads (never Step 8's commit-the-pending-work text); then Step 8 item 5. The T0 stands, so the gate keeps presenting the external half. An apply after the launch is the one failure with NO paste fallback: the prompt reviews a superseded state, so say so and that the review should be re-run, which packages a new prompt.

**Named limits.** A writable own runner may follow the prompt's write/commit/push steps inside the worktree; the saved return is the only record, and the worktree is removed with `--force`. A return that opens with the heading and parses yet is truncated is not detected here — read its `**Reviewer**:` line at each runner's first use. The T0's `next_recommended` keeps the paste/save prose the emit surface requires even when a runner launched; the launch is reported in chat.

**9e. Chat output (launch route)**, in this order:

1. **(optional)** The mode-inference note, as in Step 8.
2. **(required)** `Launching <name> — your recorded external runner; no paste needed` (in place of the recommended-session note).
3. **(required)** `Prompt: <prompt-path>`
4. **(required)** `Prompt committed (<short-sha>); launched <name> at that commit` — on a pair's RE-RUN, `launched <name> at <worktree-commit short-sha>, the pair's reviewed state` in place of `at that commit` — followed by `, pushed to <remote>/<branch>` ONLY when the push landed — otherwise the push failure, or the local-path note.
5. **(required)** `Raw output: <run-dir>/return.md — if this session ends before the run does, save it with: orbit external save <change-name> --as <as> --from <run-dir>/return.md --launch <T0 token>, commit the saved file alone, and run git worktree remove --force <run-dir>/worktree` — on a pair's RE-RUN, Step 3b's SAVE TOKEN in place of `<T0 token>` — then `Findings will be saved as orbit/changes/<change-name>/.orbit-runs/external-<as>-<TS>.md (TS set when the return is saved).`

When the run ends, add: `Saved <saved-path>`; `Findings committed (<short-sha>)` followed by ` and pushed` ONLY when that push landed; `Removed <k> line(s) above the heading`; then the rendered report. A failed run adds instead the failure and the paste fallback above.

## Reference prompt template

The template's `## Notes` instruction carries the Commentary content contract (D-arc Stage
D4): the Notes body renders VERBATIM into the report's delimited Commentary slot, so the
external reviewer must carry pattern/probing/risk texture and
do NOT state finding counts, gate verdicts, or next commands — those exist only in the
report's engine-computed sections. The template's `## Direction` instruction carries the
direction's content contract the same way (rc04b): the section is REQUIRED on every return,
owned by `orbit-conventions`' External-review findings markdown format, its content contract by
`orbit-report-rendering`'s Direction requirement; a return without it is still a pass and renders
marked `[no direction]`.

The full template for the file written in Step 7 lives at `references/prompt-template.md`. Read that file when composing the prompt. The template is verbatim — preserve named sections and especially the "Output format" block (the `## CRITICAL` / `## WARNING` / `## SUGGESTION` / `## Blocks` / `## Direction` headers + `**File**:` / `**Description**:` / `**Reproduction**:` / `**Disposition**:` field labels) so `/orbit:address-reviews --from-file` parses cleanly.

## Mode-specific sections

Mode-specific content (the "What to read for THIS review" file list and the "What to look for" pass list) lives at `references/mode-sections.md`. Read that file and substitute the appropriate block (proposal: 9 passes / system: 7 passes) into the template.

## Worked example (chat output, iter 5 proposal-mode review of `add-review-workflows`)

```
Generating external-review prompt as `proposal` (inferred from tasks state).

Recommended session: Iter 5 — Fresh session in a previously-unused AI recommended
(maximum independence); iters 1–4 were codex and Claude, so try GPT.

Prompt: orbit/changes/add-review-workflows/.orbit-runs/external-prompt-proposal-2026-05-18T14-35-23Z.md

To run (handoff preflight satisfied — tree clean, remote in sync): Pull <repo URL> and read
orbit/changes/add-review-workflows/.orbit-runs/external-prompt-proposal-2026-05-18T14-35-23Z.md.
Follow its instructions; write findings to the path specified inside.

When findings come back: /orbit:address-reviews --from-file
orbit/changes/add-review-workflows/.orbit-runs/external-proposal-<TS>.md
(<TS> will be set by the external AI when it writes.)
```

## Out of scope

The command runs the review only through the recorded runner and never ingests findings:

- **Running the review**: with a reachable recorded runner, Step 9 launches it; otherwise the external AI is the user's to run. A runner on `PATH` that the user has not recorded is never launched.
- **Ingesting findings**: `/orbit:address-reviews <change-name>` discovers the saved return; `--from-file <path>` aims at it explicitly. This command emits (or, on the launch route, commits) the path the return is saved to.

## Graceful degradation

- **No `.orbit-runs/`** → create it as part of writing the prompt file; iteration is 1.
- **No prior external review** → recommended-session note uses iter 1 phrasing; cycle context reads `- Iteration: 1`.
- **No lenses files** → "Project context (read first)" line for those still appears (the `(if present)` qualifier handles the absence); external AI will see they're absent when it pulls the repo.
- **No git remote / repo URL unknown** → emit the local path instead of a URL and add a note: `If you don't have access to this repo, copy it to a shared location and update the invocation.`

## Run-summary emit (T0 — when prompt is packaged, before findings return)

(Per `orbit-run-summary-emit` capability)

The external-handoff branch writes TWO artifacts during a single invocation:

1. **The prompt file**: `external-prompt-<as>-<TS>.md` written per Step 7.
2. **The T0 run-summary JSON**: emitted at command completion (after Step 8's chat invocation snippet), recording that the external pass was packaged and is awaiting findings. On the launch route it is emitted at Step 9a instead, BEFORE the handoff commit (it is one of that commit's two files), with `target` set to the runner's `name`; its token is the `--launch` token Step 9d passes.

The T0 emit goes to:

```
orbit/changes/<name>/.orbit-runs/review-external-<TS>.json
```

Where `<TS>` is ISO-8601 UTC with hyphens. Create `.orbit-runs/` if it doesn't exist. Use a FRESH timestamp distinct from the prompt file's `<TS>` (one ISO-second resolution may make them identical; bump by one second if so).

This is the T0 emit. T1 (findings returned and walked, by discovery or by `--from-file`) is the EXISTING `address-reviews-<TS>.json` emit and is unaffected.

### JSON shape

Per the universal spine in `orbit-conventions`'s `Internal-run JSON summary format` + per-command extensions:

```json
{
  "command": "review-external",
  "timestamp": "<ISO-8601 UTC>",
  "change": "<name>",
  "final_assessment": "<narrative, e.g., 'External review prompt packaged for <name> (iter <N>, mode <as>); awaiting findings from <target>.'>",
  "next_recommended": "<multi-step prose; see below>",
  "kind": "editorial",
  "mode": "proposal" | "system",
  "prompt_path": "orbit/changes/<name>/.orbit-runs/external-prompt-<as>-<TS>.md",
  "target": "<named external AI if user specified; null otherwise>",
  "pair": true,
  "awaiting_findings": true,
  "judgements": [ { "kind": "continuation", "disposition": "spend", "formed_against": ["<independent pass TS>"], "reasoning": "<why a further pass was bought>", "ratified_by": "ai|user" } ]
}
```

**Example payload.** A payload file this branch writes when the handoff is a spend bought past a passed gate — real JSON, accepted by `orbit emit review-external --change <name>`, carrying no engine-owned key (`awaiting_findings` is composed). A handoff that is not a spend OMITS `judgements`. A test submits this block, unchanged, through the write gate, with the trail seeded with the pass its `formed_against` names (`orbit-emit-composition`'s `Payload schema references are proven by execution`).

```json example change
{
  "mode": "system",
  "prompt_path": "orbit/changes/add-detail-flag/.orbit-runs/external-prompt-system-2026-10-02T09-15-00Z.md",
  "target": "GPT-6 Codex",
  "final_assessment": "External review prompt packaged for add-detail-flag (iter 3, mode system); awaiting findings from GPT-6 Codex.",
  "judgements": [
    {
      "kind": "continuation",
      "disposition": "spend",
      "formed_against": ["2026-10-01T16-40-00Z"],
      "reasoning": "The gate passed on the blind pair, but the walk rewrote the parser's input domain; one more external pass on the walked tree is worth its cost.",
      "ratified_by": "user"
    }
  ],
  "model": "claude-opus-5-5"
}
```

**THE PAIR LAUNCH (rc17a).** `pair` is OPTIONAL. A T0 carrying `pair: true` is a blind pair's LAUNCH: its meaning is `orbit-engine-gates`' `A pair's membership is computed from its launch`, and the field's checks are `orbit-emit-composition`'s `The review-external payload carries pair` (a boolean; `pair: true` needs an explicit `mode` of `proposal` or `system`; `pair: false` writes the ordinary T0). No step of this branch writes it on its own: it is written only when `references/blind-pair.md` runs this packaging as a blind pair's external half (`--reviewer blind-pair`). A re-run of a missing external half re-packages WITHOUT it, so the re-run refills the open pair rather than launching a new one. The payload below is a launch's:

```json example change
{
  "mode": "system",
  "pair": true,
  "prompt_path": "orbit/changes/add-detail-flag/.orbit-runs/external-prompt-system-2026-10-02T09-15-00Z.md",
  "target": "GPT-6 Codex",
  "final_assessment": "External review prompt packaged for add-detail-flag (iter 1, mode system) as the external half of a launched blind pair; awaiting findings from GPT-6 Codex.",
  "model": "claude-opus-5-5"
}
```

**THE SPEND RECORD (rc04a).** When this handoff is a FURTHER independent pass bought past a gate that has ALREADY passed — a decision the cadence has no other home for — the payload SHALL carry a `judgements` entry with `kind: "continuation"` and `disposition: "spend"`, written at exactly the moment the decision is taken rather than reconstructed later. `formed_against` names the passes already returned; `reasoning` says why another was worth buying. The token source is the TRAIL ITSELF, not `orbit status`: the change-tier status payload reports gate spend COUNTS and reason strings, never pass tokens. List `orbit/changes/<change-name>/.orbit-runs/` and take the `<TS>` of each `review-<mode>-<TS>.json` whose `reviewer_class` is `fresh` or `external`, plus each `external-<mode>-<TS>.md` the trail reader ACCEPTED as a pass — a return the gate's `reason` names as REJECTED is not citable, and enumerating filenames alone over-counts by exactly those. Which passes count is `orbit-run-summary-emit`'s rule (the trail reader's pass set); this body names it and does not restate it — the write gate enforces it and names the pass it refuses on. This emit admits `continuation` ONLY — a `readiness` here is refused, since the T0 handoff record has no reader for one. A handoff that merely covers a DECLARED, still-uncovered cadence slot is not a spend decision and carries no record.

`awaiting_findings: true` is always set at T0. Future tooling may flip this when findings land; for now it's a flag that downstream consumers can use to identify "T0 emit, not yet completed cycle." `reviewer_class: "external"` (C1) describes the intended handoff class for audit readability — but per `orbit-run-summary-emit`, a T0 emit is a PACKAGING record, NOT a completed pass: whichever cadence slot an external return would satisfy — a bare `external` slot, an `independent` slot, the external half of a `blind-pair`, or an `invoked` slot (as a single, or as a launched pair's external member) — is satisfied ONLY when an `external-<as>-<TS>.md` findings file exists, so a packaged-but-unreturned external never counts as class coverage.

### `next_recommended` — multi-step prose

Per `orbit-run-summary-emit`'s `Review-external T0 multi-step recommendation` requirement, the recommendation is multi-step prose describing the user action ONLY, ending at the save step — it names no walk command; what follows the save is the gate's canonical next, read from `orbit status --change <name> --json`:

```
"Paste orbit/changes/<name>/.orbit-runs/external-prompt-<as>-<TS>.md
 into the target AI, and save the response as
 orbit/changes/<name>/.orbit-runs/external-<as>-<TS>.md"
```

A downstream status reader's tier-1 best-effort parse SHALL find no leading `/orbit:<verb>` (because the string leads with "Paste"); `command` and `args` are left null, and the full verbatim string is surfaced in `reason`. This is the expected behavior — multi-step user actions are accurately represented as prose, not collapsed into a single command.
