# Reference: the program PR at arc-done

```bash
orbit pr program <doc> --json
```

`orbit pr program` locates the program PR, validates it live and falls through to the
constrained query on its own; it observes and never writes. A non-zero exit is a usage error:
report it verbatim. `off` means no program-PR attachment names this doc: say nothing. Otherwise
(it never skips) surface:

- `observations.pr`: its `url` and `state`. A `state` of `unverified` means the observation
  failed: say so in one line and claim nothing more.
- `observations.invalidated`: when set, the recorded PR was closed, merged or retargeted, and
  `observations.pr` is the open replacement the query found, or null when none exists.
- `observations.candidates`: when there are several, name every one.
- `human_acts`: show each argv verbatim as the user's act (ready, then merge). Run none of them.

When `observations.pr` is null the readout still speaks, from `observations.outcome`, and
never confuses not knowing with knowing there is none:

- `unobserved` or `gh-absent`: the program PR could not be observed; name the cause from
  `observations.resolution_failure` or `observations.query_error` when present.
- `none`: the query ran and found no open program PR.
- a positive-invalidation reason or `not-found`: the recorded PR is in that state and no open
  replacement exists.
- `several`: the candidates above, with no acts.

The readout repeats on every arc-done invocation until the PR is no longer draft.
