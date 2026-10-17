# Reference: the PR lifecycle at propose and ff

Loaded ONLY when the engine-resolved regime (`orbit status --json`, field `pr`) is
`per-proposal` or `per-architecture`. Under `never` (also what an absent key and every inert
value resolve to) do not load this file and probe nothing.

The engine computes every PR step and performs none: `orbit pr` observes through read-only
`git` and `gh` and PRINTS each write as an argv. You call it at each phase, act on its record by
the table below, and author only the judgment: the title, the intent body, the commit messages
and the wording of each one-line note. Never re-derive a step the record decided. There is no
hand-run fallback; a body carrying both would run both.

## Phase 1 — select, before any artifact is written

```bash
orbit pr select <name> --json
```

On `proceed`, run its one segment: the switch, plus a fast-forward when one is printed. `off`,
`skip`, a non-zero exit, or a failed step ENDS the PR layer for this invocation: `publish` is
never called, generation proceeds on the current branch, and the emit carries no
`pr_attachment`. Name `observations.untracked` in one line when it is non-empty; on the program
path, note a non-zero `observations.ahead_by` (the PR's diff carries that gap until the user
integrates; never merge or rebase it).

## Phase 2 — generate and validate, on that branch

Exactly as without the PR layer. A failure commits, pushes and opens nothing; the note names the
branch phase 1 switched to, and `git switch <default-branch>` as the recovery.

## Phase 3 — publish, only after phase 2 succeeds

```bash
orbit pr publish <name> --json
```

Before segment 1, author the inputs it names: normally `<message-file>` (the commit message),
`<title>`, and `<body-file>` (an adopted program PR names no title or body, and an empty
scope no message file), the INTENT body adapted from proposal.md's Why and What (a program PR: program
intent from the doc's opening prose plus its stage list). The title, quoted from
`orbit-pr-lifecycle`'s `Agent-written landmark descriptions at seams only`: `<change-name>: <summary>` for per-change PRs, where `<summary>` is ONE line the agent writes from proposal.md's Why (the proposal template carries no title line, so the summary is judgment, written once), and `<doc stem>: <doc title line>` for program PRs (every architecture doc opens with a `# ` line) — and no seam rewrites it.
When `observations.ci` is `absent`, note in one line that no CI is configured.

Run segment 1, then write the propose (or ff) emit with `pr_attachment` composed per the table's
row for `publish`'s first segment, and pass the emit's path as `<emit-path>` to segment 2, which
lands the record on the branch. When `publish` printed one segment (a PR-half degradation), there
is no segment 2: the emit stays local.

**Worked example.** Segment 1's `open` step prints
`["gh", "pr", "create", "--repo", "acme/widget", "--draft", "--base", "main", "--head",
"add-thing", "--title", "<title>", "--body-file", "<body-file>"]`. With the title
`add-thing: Skip the "dirty tree" check` and the body written to `/tmp/pr-body.md`, run:

```bash
gh pr create --repo acme/widget --draft --base main --head add-thing --title 'add-thing: Skip the "dirty tree" check' --body-file /tmp/pr-body.md
```

The title reaches `gh` as ONE argument. A title containing `'` closes the quote: write it as
`'\''`.

**No consent prompt.** Propose and ff fire none: the steps ride the user's own invocation, and
the outward write is a DRAFT PR on the change's branch.

## Acting on the record

A CHECKED COPY of `orbit-pr-lifecycle`'s consumption table (`PR actions are workflow-body
choreography (zero engine git)`), carried because an installed skill cannot open the owner; a
parity test holds it byte-equal. Every shape an `orbit pr` call returns has a row:

| the call returns | the body |
|---|---|
| a non-zero exit (a usage error, the only one) | stops the PR layer and reports the error verbatim; the lifecycle continues unattached |
| `action: off` | engages no PR step and writes no note of its own, beyond the unattached line `preflight`'s requirement assigns it |
| `action: skip` | writes ONE line from `reason.code` and `reason.detail`, runs nothing, and continues unattached |
| `action: proceed`, `degraded: null` | runs `segments` in order; before each segment it authors that segment's `inputs`; it runs each step's `argv` exactly, substituting only an element equal to an input token, every element shell-quoted |
| `action: proceed`, `degraded: "pr"` | the same, plus ONE line for the PR-half degradation from `reason` |
| `select` returns `off` or `skip`, exits non-zero, or one of its steps fails | ends the PR layer for this invocation: `publish` is never called, and generation proceeds on the current branch, unattached; a failed step is named in ONE line with no recovery shown, since running it would attach nothing |
| a `publish` or `tail` step fails | stops at that step and writes ONE line naming the completed, the failed and the skipped steps by their `step` names, showing the failed step's argv and then each skipped step's, verbatim with every input filled, as the recovery the user runs in that order, and stating the consequence for its seam: at propose and ff the change proceeds unattached until that recovery lands; at the archive tail the archive itself has landed and never rolls back, and the PR stays as the completed steps left it; no later PR step runs, and the lifecycle's own steps (the emit among them) still do |
| a segment whose `inputs` name `<emit-path>` | writes the emit between the segments and passes its path |
| `publish`'s first segment ends | composes the emit's `pr_attachment` as `observations.attachment` plus, when the `open` step created a PR, `url` from that step's standard output and `state: "draft"`, or, on adoption, `url` and `state` from `observations.adopted_url` and `observations.adopted_state`; after a PR-half degradation the attachment carries neither, and the second segment does not run; after a failed step the emit is still written, its attachment `observations.attachment` alone, and stays local, the second segment's argv joining the failure line's recovery with both its inputs filled: `<emit-path>` the emit just written, and `<message-file>` a record commit message the body authors before writing the line |
| `tail` is called | passes every path the archive flow edited at its at-archive steps as `--include <path>`, so those edits land in the tail's commit |
| `human_acts` non-empty | shows each act's argv verbatim, labelled as the user's own act; never runs one |
| `observations` | reads only what the emit or a note needs; never re-decides a step from it |
