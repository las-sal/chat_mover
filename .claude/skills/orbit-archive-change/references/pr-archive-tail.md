# Reference: the PR-attached archive

Loaded when `orbit pr preflight` returned anything but `off`. The ATTACHMENT recorded at propose
or ff is the only gate: the live `pr:` value is not consulted, so `pr: never` stops new
attachments and never abandons an open PR. `orbit pr` observes through read-only `git` and `gh`
and PRINTS each write; you act on its record by the table below and author only the judgment.
Never re-derive a step the record decided.

## Preflight, before the move

```bash
orbit pr preflight <name> --json
```

It runs while the change is still active (after the move it is a usage error). Its ONE
observation is carried forward to both the emit and the tail, so they cannot disagree:

- `observations.emit` supplies the archive emit's `pr_url` and `pr_state`, copied as given; an
  absent key stays absent.
- `observations.outcome` is the tail's `--outcome`, passed verbatim.
- `observations.citation.diverged` true: one note that the frozen attachment governs, naming
  what `observations.citation.would_select` selects now (when the `pr` regime reads `never`,
  that no PR would be selected now).
- `degraded: "pr"`: one note naming the outcome and `reason.detail`: `observed` is what the PR
  now shows and `expected` what it should (for example `retargeted to` its `observed` base,
  away from the `expected` default). The tail's commit and push still run; its PR steps do not.
- `skip`: one note from `reason`; the emit carries no PR field.

## Tail, after the move and the emit

```bash
orbit pr tail <name> --outcome <outcome> --include <path> --json
```

Pass `--include` once for every path the archive edited at its at-archive steps (a status log,
an arc doc's stage entry, CLAUDE.md), so those edits land in the tail's commit. Before its
segment, author `<message-file>` and, when a `rewrite` or `append` step is printed,
`<body-file>`:

- `rewrite` (a per-change PR): the ACHIEVEMENT body, replacing the intent: the outcomes, the
  review-cycle story, the decisions ratified along the way.
- `append` (a program PR): `observations.current_body` with this stage's entry appended, never
  the entry alone. The entry comes from the arc status-log entry written at this archive, else
  from the emit's `final_assessment` plus the change name and date; name the source in one line.

A `skip` with `reason.code` `head-mismatch` names both branches and shows
`reason.detail.recovery`'s argv; when its `case` is `absent` (no argv), say plainly that no
switch recovers the branch, naming `observations.attachment` as the record of what was expected.
A per-change tail whose `observations.pr_state` is `ready` prints no `ready` step: report in
one line that the PR was already READY and was not re-flipped. Name `observations.unrelated_staged`
and `observations.unrelated_unstaged` in one line when either is non-empty: those paths stay as
they were, staged or unstaged, and outside the commit.

## At the close

Show every `human_acts` argv verbatim, labelled as the user's own act: the merge, then the return
to the default branch after it. Run none of them. A program PR's tail prints none; its flip and
merge belong to arc-done.

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
