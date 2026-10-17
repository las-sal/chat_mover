---
name: orbit-address-reviews
description: Resolve `@review:` markers anywhere in the repo (or review findings via `--from-file` markdown / JSON, or, aimed at a change, every outstanding pass its reviewed gates report — internal JSON and external returns alike — plus its unwalked audit-drift emits) by walking each through pushback → classify → resolve-per-lane → ripple-cascade → remove-marker (obvious-fix findings previewed at triage and applied without prompts; decision-lane findings briefed in prose and ratified by chat directive or an optional closure prompt). Walk-mode (per-finding) is the default; `--batch` opts in. Cascade-by-default auto-applies ripple edits to IN-set files (everything outside the four lifecycle-invariant OUT categories: audit trail, baseline specs, cross-change/archive dirs, safe-exclusions); `--no-cascade` opts out. Use after `/orbit:review` writes findings to `.orbit-runs/` (discovered from the gate's outstanding passes; no `--mark` pre-step needed), after `/orbit:review --as <mode> --reviewer external` returns external findings, after `/orbit:audit-drift` writes drift findings, or any time the repo has accumulated `@review:` annotations.
license: MIT
compatibility: Requires orbit CLI. Ingests findings via `--from-file` (external-review markdown OR internal `review-<mode>-*.json` OR `audit-drift-*.json`) OR via discovery on a change: its inline markers, every outstanding pass `orbit status --change <name> --json` lists on its reviewed gates, and its unwalked audit-drift emits, one log per source. Default behaviors: walk-mode (per-finding); cascade-on (auto-applies ripples to IN-set files). `--batch` opts INTO batch-mode; `--no-cascade` opts OUT of cascade. `--mark` is optional, not prerequisite.
metadata:
  author: openspec
  version: "0.1"
  capability: orbit-address-reviews
  generatedBy: "2.0.1"
---

Resolve `@review:` markers across the repo (or external-review findings from a file) with pushback discipline. The lifecycle: **discover → triage → walk → report**, where each walked finding completes its inner cycle (pushback → classify → fix → ripple-cascade → remove-marker) in walk-mode by default. Cascade-by-default auto-applies parallel edits to ripple-flagged IN-set files. Markers are removed from their source files on resolution (the marker-removal invariant) so they don't leak into canonical artifacts.

**Generates resolutions; does not generate findings.** This is the counterpart to `/orbit:review`. Primary use case: close the cross-AI review cycle by ingesting external-AI findings via `--from-file`. Secondary use case: walk repo-scanned inline `@review:` markers with structured pushback.

**Input**: Optional scope (path or pattern) and optional flags. Default: whole-repo scan with safe exclusions.

## Four execution disciplines (epitome)

The four disciplines from `orbit-conventions`, embedded per body; detail lives in the step where each fires.

- **Pushback (review-time) — primary here**: verify every claim against current state before acting (procedure in Step 3a); stale findings are suppressed with evidence, never re-fixed.
- **Read-before-reference (authoring-time)**: read a file's actual current content before editing or citing it; re-read after edits to confirm they landed.
- **Change completeness (modification-time)**: apply resolutions across ALL affected artifacts — the Step 3d ripple cascade is this discipline mechanized; sweep just-touched files for residue after mechanical edits.
- **No-chaining (turn boundary)**: invoke only the orbit workflow commands the user's message explicitly requests; completing a command ENDS the turn at the position readout + the engine's eligibility line — gate `passed` means *eligible*, not *commanded*.

## Steps

### 1. Discover (or ingest)

**Discovery** decides which sources this invocation walks. The fence below is a CHECKED MIRROR of `orbit-address-reviews`' `Address-reviews command available`, its owner. An installed skill has no specs to point at, so the copy exists here; a parity test holds it byte-equal to the owner's fence. Never edit it here.

```
DISCOVERY — rows tested in order, first match wins:
1 --from-file <path>, with or without a positional: the file ONLY; no marker grep, no trail discovery, no openPair warning; the positional, if any, resolves only where the log lands.
2 no positional, exactly one active change (per orbit list --json): say "resolved to the single active change <name>; markers outside it are not scanned", then re-enter these rows as a positional naming that change.
3 no positional, zero or several active changes: the whole-repo @review: marker scan; several are named in the header so the user can aim the walk.
4 active change, a reviewed gate neither blocked nor superseded reports openPair: before triage, warn that the pair is half-landed, naming the missing member and the gate's canonical next command. When the landed half is listed in that gate's unresolvedPasses or unwalkedPasses, offer two choices — stop (walk nothing, write no log, so the missing review can run) or walk now. Walking now ends the pair: on an invoked slot the walked half then covers alone; on a blind-pair slot no pair can form on this state. On walk, continue at row 5. When the landed half is listed in neither (it carries no finding), no walk can end the pair: say so, name the routes that can — a further review of the landed half's class, which on an invoked slot lands as a single and covers, or a continuation/proceed judgement at the gate's seam — then walk nothing and write no log.
5 active change: the UNION of @review: markers in the change directory, every unresolvedPasses and unwalkedPasses entry of each reviewed gate neither blocked nor superseded (internal review-<mode>-*.json and external external-<mode>-*.md alike), and every audit-drift-*.json in its .orbit-runs/ whose basename no address-reviews-*.json there names in source_path.
6 archived change: markers in the archived directory + its unwalked audit-drift-*.json by the same basename rule; its review passes are reached by --from-file, and the header says so.
7 a positional resolving to no change (a path or pattern): markers in that scope only.
AFTER the matched row: when it discovered nothing, print "No @review: markers and no outstanding passes in scope. Nothing to walk.", then list each audit-drift-*.json in scope that a log already names as "walked before; reach by --from-file <path>", and exit clean.
```

**The outstanding set is the gate's, never a second rule here.** On an active change, read `orbit status --change <name> --json`. From each `gates[]` row with `kind: "reviewed"` whose `state` is not `blocked` and that does not carry `superseded: true`, take its `unresolvedPasses` and its `unwalkedPasses` (each entry `{token, file, mode, source}`, `file` repo-relative, oldest first) and its `openPair` (`{missing}`, present only when a pair is half-landed). Row 4 reads `openPair`, and row 5 reads the union of the two lists. `unresolvedPasses` holds the passes the gate holds on; `unwalkedPasses` holds every other pass carrying a finding of any severity that no walk record references, so a suggestion-only pass is discovered and walked like any other — the walk holds nothing on the gate, though, like any walk, it raises the following cadence slot's ordering bar. audit-drift is not a gate pass, so row 5 finds it by the basename rule.

**A marker that restates a discovered finding** — at that finding's `file`, its text beginning with the finding's title (the form `/orbit:review --mark` writes) — is walked AS that finding, in its pass's log, and removed at Step 3e. The markers' log omits it, so no finding is walked twice. `--mark` stays a stylistic choice, never a prerequisite.

**Default — whole-repo scan** (row 3): `grep -rn "@review:"` with the safe exclusions `.git/`, `node_modules/`, `dist/`, `build/`. No trail is read.

**Positional `<scope>`** resolves active change → archived change (lexicographically-latest date on collision) → path/pattern fallback. (Details: `references/resolution-detail.md`.)

**Every discovered pass and audit-drift emit walks the `--from-file` ingest path below**, exactly as if its path had been passed, and gets its own log (Step 6).

**`--from-file` ingest** auto-detects format by content sniff (content only — never extension): leading `{` → internal JSON, accepting `command: "review"` or `"audit-drift"` only (`"address-reviews"` rejected on purpose — cycle prevention; contract at `references/internal-findings-format.md`); leading `# External Review:` → external markdown (`references/external-findings-format.md`); neither → clean format-mismatch error naming both. Each finding becomes a virtual marker (`severity` / `title` / `file:line` / `description` / `reproduction` when present / `source` tagged `external` / `internal-review` / `audit-drift`) walking the same lifecycle as inline markers, except Step 3e marker-removal is a no-op — the source file is an audit artifact that travels with the change into archive.

**Fresh pushback applies to every virtual marker**: the source's own `stale_suppressed[]` filtered at source-run time, but state may have changed since; Step 3a runs regardless of provenance.

### 2. Triage

Present discovered markers (or parsed virtual markers) as a numbered list:

```
Found 12 markers in scope:

  1. orbit/changes/foo/proposal.md:41 — "@review: should this be five or four?"
  2. orbit/changes/foo/design.md:159  — "@review: 9 vs 8 after merge"
  3. src/api/auth.ts:88                   — "// @review: token TTL configurable per env?"
  ...
 12. (external) proposal.md:33            — [CRITICAL] orbit-conventions bullet omits three disciplines
```

Mark external-sourced entries explicitly (`(external)` prefix). **Blocks come first**: when the source carries lifecycle blocks (markdown `## Blocks` items; the review JSON's `blocks[]`), list them at the TOP of the triage table under a `Blocks (not walked)` heading — one line each, verbatim — before any numbered finding; they are never virtual markers, never walked, and never counted (per `orbit-conventions`' Severity ladder; the stop is the human's). A CRITICAL marker that carries no reproduction is tagged `unreproduced` in its triage line. The triage OPENS with the **obvious-fix lane preview** (D-arc Stage D4): every finding provisionally headed for the obvious-fix lane is listed compactly — finding + its one-line resolution — BEFORE any fix lands, so the user can pull any item into the decision lane with a word ("discuss the import one"). The preview derives from a PROVISIONAL classification (per-finding pushback has not yet run); walk-time pushback may reclassify, and a reclassified item is announced before its fix lands. Scoping (walk all — the default — / a subset / only-critical / cancel) is settled by the user's response to the preview; an `AskUserQuestion` is optional closure when the response doesn't settle it.

**Ripple-miss attribution** (a change-scoped walk): read the change's EARLIER walk logs (`address-reviews-*.json` on its trail) against each finding. Where a finding sits at a site an earlier `resolved` entry's fix should have reached, that finding's resolution — once it resolves — carries `ripple_miss_of: {walk, title, file, kind}`, naming the earlier entry with `title` and `file` copied from that log, never retyped, and `kind` one of: `scope` (the site lay outside that entry's check scope), `query` (inside it, but matched by none of its `retired` or `searched` strings), or `judgement` (matched, and judged unaffected). An entry written before sweep records existed has no `retired`/`searched`; read its scope as the change directory (on a change-scoped walk), its `file` and its `ripple_cascade.applied`. Attribution is your judgement and optional: a finding no earlier entry touched carries none. Shape and rule: `orbit-address-reviews`' `A ripple miss is attributed by the walk that finds it`.

**Several sources, one triage.** When discovery yields more than one source, triage runs ONCE across all of them, grouped by source: passes in the engine's token order, oldest first, then the markers. Mark each finding that converges with a finding of another discovered pass (same site, same claim) as found by both. The split (found by both / one pass only / contradictory) is a triage rendering and is never stored as a merged record. A converged finding is walked in the log of the EARLIER pass. In each later pass's log it takes the earlier entry's disposition: `stale` with evidence naming the earlier log's token when the earlier entry is `resolved` or `stale`, and the same `deferred` or `escalated` disposition (and `routed_to`, when present) when the earlier entry stays open. A later pass is never closed by a finding that has not closed. Shape and rule: `orbit-address-reviews`' `One invocation writes one log per discovered source`.

**A rediscovered pass** — discovery lists it although a log already names it: its latest log left an entry `deferred` or `escalated`, names only some of its substantive findings, or is unreadable with summary counts that leave an entry open or carry none — is presented with that log's dispositions, where it has any; a substantive finding that log does not name is walked. Its new log must name every substantive finding of the pass, because the gate reads only the latest log. So each finding the earlier log closed is re-checked by pushback against current state: still fixed, it is recorded `stale`, with evidence naming the earlier log's token; reproduced — the fix regressed — it is walked again like any finding, with a fresh `sweep`. The open findings are walked again, except one the earlier log escalated with `remedy: "redesign"` and a `routed_to`: re-record it `escalated` with the same `routed_to`, do not walk it, and name its route again in the report. Nothing is copied forward: a copied `resolved` entry would owe a fresh `sweep` the write gate checks against today's files.

**A disagreement** — two discovered passes of one blind pair making CONTRADICTORY claims about one site, or about two sites whose premises contradict — is settled by ONE cheap empirical test (a command run, or a constructed case derived against the current artifact), run AT TRIAGE before either pass's log is written. Record it on the entry in the LATER pass's log as `disagreement: {with, test, observed}`: `with` is `{pass, title, file}` naming the other pass's token and its finding, `test` the test as run, `observed` its output or derivation. A claim the test refutes is `stale` with the test's output as its evidence, in its OWN pass's log; a claim it upholds is walked like any finding. When the test cannot be run, `observed` says so and the finding enters the decision lane, so the user decides. A claim pushback finds stale at HEAD is not a disagreement, and neither is a difference in the two passes' forward `direction` (that is the readiness record's). Rule: `orbit-address-reviews`' `A disagreement between the halves of a pair is settled by one test`.

### 3. Walk each marker

**Walk-mode is the default**: each marker receives its own complete inner cycle — pushback → classify → resolve per LANE → ripple-cascade → remove-marker — before the next marker's pushback begins. Obvious-fix findings (previewed at triage) apply with no prompt and no discussion; decision-lane findings follow the present → discuss → ratify protocol (3b.5). There is NO mandatory per-finding `AskUserQuestion`. The user can interrupt between markers; the resolution log captures partial completion if interrupted.

**Batch-mode is opt-in** via one of three mutually-exclusive triggers (first match wins; recorded in `walk_mode_source`): the `--batch` flag (`"flag"`), a batch-intent phrase in the INVOCATION message itself — never in a later walk response (`"fix them all"`, `"batch them"`, … → `"verbal"`), or a bare command-shaped mid-walk switch (`"go batch"` → `"command-shape-interruption"`, recording the 1-indexed `walk_mode_shifted_at_finding`). Ambiguous mid-walk phrases (`"fine, fix them all"`) never shift mode; the full trigger table lives in `references/resolution-detail.md`. In batch-mode, all markers complete pushback + classify + resolve before ripples apply once as a single aggregated step — and decision-lane findings STILL get their per-finding briefing and ratification; batch never merges decisions into one prompt, it only suppresses per-finding pacing for obvious-fix and stale findings.

For every marker in the chosen scope, execute the lifecycle below sequentially.

#### 3a. Apply pushback (primary discipline)

Run the verification procedure:

0. For a CRITICAL marker that carries a `reproduction`, RE-RUN it FIRST — execute the command, or re-derive the constructed case against the current artifact — and record the result as the entry's first evidence: `reproduction_rerun` is `reproduced` / `not-reproduced` / `cannot-run`, with the output or derivation in `evidence`. A CRITICAL carrying none is noted `unreproduced` and pushback proceeds on the claim alone — never re-grading it (per `orbit-conventions`' Severity ladder, severity is the author's). When the re-run's observed result now matches the expected one, the marker is **stale-with-evidence** (the re-run's output IS the evidence) and no further edit is made. Below CRITICAL the field is absent.
1. Identify the marker's referenced symbol, name, or concept.
2. `grep -rn` for current presence in expected locations (the marker's file, related files, baseline specs).
3. If the symbol is absent where the marker expects it, `git log -S "<symbol>" --since=<window>` (default: since the marker file's last modification) to confirm intentional removal.
4. Read the relevant file's current content and compare to the marker's claim.
5. Decide: **still applies** / **already fixed** / **partially applies**.
6. On already-fixed, record the commit hash or current-content evidence as part of suppression — the marker is removed without further edit; never re-edit already-fixed state.

#### 3b. Classify

Apply heuristics in order:

1. **stale** — pushback determined the issue is already resolved at HEAD. Skip directly to Step 3e (marker removal no-op for virtual markers; log as ⚠ Stale). Step 3b.5 (decision-fork detection) and Step 3d (ripple cascade) do NOT fire for stale findings — no fix was applied so no ripples to derive.
2. **trivial fix** — single-line edit or a few-line localized edit with one obvious correct answer (no design implication, no scope question, no ambiguity in intent). Proceed to 3c without `AskUserQuestion`. Step 3b.5 does NOT fire (no decision needed); Step 3d ripple cascade DOES fire after the fix lands.
3. **decision required** — resolution requires ambiguity resolution, a design choice between defensible alternatives, a scope decision, or has implications beyond the immediate location. Hand off to Step 3b.5 (the decision lane): construct 2–4 concrete options FOR THE PROSE BRIEFING (detection supplies them when the recommendation is disjunctive; otherwise derive them from context) — no prompt fires here; the `AskUserQuestion` exists only as post-discussion closure per 3b.5. Step 3d cascade fires after the ratified fix.
4. **unresolvable** — resolution needs information not currently available (deferred decision, future capability, blocked on external input). Default: file as a task in `tasks.md` in Step 3c (action "filed as task"); Step 3d cascade does NOT fire (no fix was applied; no ripples); Step 3e marker-removal proceeds normally. Alternatives via **AskUserQuestion**: convert to `@todo: <content>` or escalate to `@review(escalated): <content with explanation>` — in both alternative cases, the marker is **transformed** in place (Step 3e) rather than removed; cascade still does not fire.

**Then the remedy** — R-crc-6's three lanes, recorded per entry as `remedy`, a field separate from the process `lane` above (which says how a finding was CONDUCTED; `remedy` says what its resolution DID). Decide it by one test — does closing the finding require mechanism nobody has reviewed? — never by the finding's size. `repair`: the right thing is local, fixed here. `descope`: the change was doing something it should not, so it is removed (the removal's sweep rides `sweep`). `redesign`: closing it needs unreviewed mechanism. The values, dispositions and routes are `orbit-address-reviews`' `A walk entry records its remedy, and a REDESIGN leaves the walk` (a four-row table). Every `resolved` entry carries `remedy`, and so does every `escalated` entry routed out; a `stale` entry, and an unrouted `deferred` or `escalated` one, carries no `remedy`.

**A REDESIGN is never closed in place.** If the unreviewed mechanism can leave the change (separable), remove it from the change, record the entry `resolved` with `routed_to: "orbit/explore/<new-name>/"`, and sweep the removal. If it cannot (essential), the entry is `escalated`. It holds the gate only where the gate reads it: on a CRITICAL or WARNING of a reviewed-gate pass, that pass stays unresolved; an escalated SUGGESTION, or an entry from an audit-drift emit or from markers, records the route and holds nothing. While the hold stands, the eligibility line stays on the walk; that walk carries the routed entry forward unwalked (Step 2) — a named limit until the explored repair lands. `routed_to` is `orbit/changes/<name>/explore.md` on an ACTIVE change, and on any other scope (an archived change, a project-wide or architecture walk) a new exploration, `orbit/explore/<new-name>/`. The report names the route — `/orbit:explore <new-name>`, or `/orbit:explore <name>` on an active change — and the walk invokes nothing (no-chaining). Where that command lands is the explore re-entry table's to decide; promise no resume.

#### 3b.5. The decision lane: present → discuss → ratify (classify == "decision required")

**Fires only when classify == "decision required"**. Skip this sub-step entirely for `stale` / `trivial fix` / `unresolvable` classifications — they short-circuit straight to 3c.

The lane's protocol (D-arc Stage D4): (1) **PRESENT** — a FULL-PROSE briefing in chat: what the finding means, why it matters, terminology level-setting where concepts are novel, and the concrete options with real tradeoffs. The briefing is the presentation — option content is never confined to prompt labels. (2) **DISCUSS** — genuine back-and-forth for as many exchanges as the finding needs (zero exchanges is legitimate for crisp cases). (3) **RATIFY** — a direction the user types in chat IS ratification (user-typed provenance, the consent model's strongest signal); the `AskUserQuestion` is an OPTIONAL CLOSURE DEVICE, fired only AFTER the finding's discussion concludes without a crisp user directive (never before the briefing, never mid-discussion), carrying the discussed conclusion as its default option. A dismissed or inconclusive prompt RE-PRESENTS the finding — the walk position and briefing context are never lost. The prompt NEVER precedes the briefing, and one prompt NEVER spans multiple findings (batch prompts are prohibited). **Batch DELEGATION** — an explicit user directive compressing the lane ("handle the rest, only brief me on real decisions") — remains the user's prerogative and is recorded verbatim in the resolution log's top-level `delegation_directive`.

**Hybrid detection** supplies the briefing's option set — structured first: a well-formed `recommendation_options: [{label, body}]` array with ≥ 2 complete entries is used DIRECTLY (`recommendation_fork.source: "structured"`); otherwise a STRICT-disjunctive heuristic over the prose recommendation (numbered alternatives / clause-level "Either … or …" / an "Options:" prefix — never loose "or"; `source: "heuristic"`). Malformed structured input warns on stderr and falls back to heuristic with `structured_path_skipped_reason` recorded; it never aborts the walk. No detection at all: the finding STILL gets its full-prose briefing with 2–4 AI-derived options, and NO `recommendation_fork` object is recorded (absence IS the no-fork representation).

**Ratification recording** — every decision-lane resolution records `ratified_via: "chat" | "prompt"` at the ENTRY level, plus a verbatim `resolution` string when no fork was detected or the ratified direction is off-menu; the `recommendation_fork` object (when detection fired) carries the detection data. Exact trigger rules, malformed-input handling, the recording shape, and a mini decision-lane trace: `references/resolution-detail.md`. (The `[discuss]` escape hatch is RETIRED — discussion is the medium; pre-D4 logs carry it, readers tolerate both generations.)

#### 3c. Apply the fix

- **trivial fix**: apply the edit. Re-read the file after to confirm.
- **decision required**: apply the RATIFIED resolution (the user's chat directive, or the closure prompt's outcome) per the decision-lane protocol in 3b.5.
- **unresolvable (default)**: append a task to `orbit/changes/<change>/tasks.md` (or repo-level `TODO.md` if no change context); task text is the marker's content + ripple-flag context.
- **unresolvable (`@todo:` or `@review(escalated):`)**: replace the marker text in place (do NOT remove — the new form persists as future signal).

#### 3d. Ripple cascade (auto-apply by default; `--no-cascade` opts out)

If the resolution edited a normative artifact, compute the ripple-flag set — files that need parallel edits to stay consistent with the primary fix. Then split each ripple into **IN** (auto-applied) and **OUT** (recorded in `flagged_not_applied[]`).

**OUT — the four lifecycle-invariant exclusion categories** (these are the ONLY structural exclusions; any other file is IN):

| OUT category | Path prefix | Reason recorded in `flagged_not_applied` |
|---|---|---|
| Audit trail (all four locations) | `orbit/changes/<name>/.orbit-runs/*`, `orbit/.orbit-runs/*`, `orbit/explore/<name>/.orbit-runs/*`, AND `orbit/architecture/.orbit-runs/*` (D-arc Stage D2) | `audit-trail file; cascade skipped by policy` |
| Baseline specs | `orbit/specs/<capability>/spec.md` | `baseline spec; add a delta to your current change's specs/<capability>/spec.md to capture this ripple` |
| Cross-change (active + archived) | `orbit/changes/<other-name>/*` AND `orbit/changes/archive/*` | `cross-change ripple; cascade scope is current change only` |
| Safe-exclusions (exact set) | `.git/`, `node_modules/`, `dist/`, `build/` | `safe-exclusion path; never edited` |

**The safe-exclusion prefix set is EXACT** — do NOT extend ad-hoc to other paths during application. Expanding the set requires a spec change.

**IN — everything else.** File extension is NOT a discriminator: `.py`, `.swift`, `.c`, `.sh`, `.md`, dotfiles, configs — all eligible if ripple-flagged and not matching an OUT prefix. For each IN file, apply the parallel edit consistent with the primary fix (run pushback against the file's current state first; classify as decision-required if ambiguous and surface a fork prompt). Record the path in `ripple_cascade.applied[]`.

**`--no-cascade` flag** (opt-out): when set, NO ripples are edited regardless of IN/OUT classification. ALL ripple-flagged files are recorded under `ripple_cascade.flagged_not_applied[]` with reason `--no-cascade suppressed`. Use case: user wants to inspect the ripple set before allowing edits.

**Cascade trusts the ripple-flag analysis** — no independent "should this file be touched?" judgments beyond the four-category OUT check; if analysis didn't surface a file, cascade doesn't touch it. `--no-cascade suppressed` is a mode-suppression reason that fires uniformly when the flag is set — NOT a fifth OUT category (structural OUT reasons fire only when cascade was ON).

#### 3d.5. Record the sweep (`resolved` entries only)

As the entry's last step before marker removal — in batch mode, for every entry after the one aggregated cascade — compose its `sweep`: five arrays, any of them empty, an empty array being the WRITTEN answer that there is nothing of that kind (shape: `orbit-address-reviews`' `A resolved walk entry records its sweep evidence`). A `stale`, `deferred` or `escalated` entry edited nothing and carries none.

- `retired` — wording the fix made FALSE, which must no longer appear anywhere the gate looks.
- `introduced` — `{path, text}`: text the fix added, which must appear in `path` (name text specific to this edit).
- `searched` — what you searched for to find the fix's other sites (a phrase, an identifier, a grep pattern); a record, never checked.
- `scope` — files or directories you examined beyond the entry's `file` and `ripple_cascade.applied`.
- `kept` — `{path, why}`: a file that must keep a retired string (history quoting the old wording, a test asserting its absence); the WHOLE file leaves that entry's retired check, so when it also carries live prose, retire a string specific to the live site. Under `--keep-resolved-markers`, a file whose retained marker quotes a retired string is listed here with the flag as its `why`.

The scope the gate checks and the rule every path you write resolves by are below — a CHECKED MIRROR of `orbit-emit-composition`'s `The walk write gate checks sweep evidence`, its owner. An installed skill has no specs to point at, so the copy exists here; a parity test holds it byte-equal to the owner's fence. Never edit it here.

```
CHECK SCOPE — the union of: on a change-scoped walk, every file under the change directory except its .orbit-runs/ trail; the entry's file; its ripple_cascade.applied paths; its sweep.scope paths, a directory contributing the regular files under it (a symlink met inside a directory is not followed; a path named explicitly is read at its target). Files under .git/, node_modules/, dist/ and build/ are never read, however the path entered the scope; for the change directory's own files those names are read below the change directory.
PATH — strip a trailing :<line> or :<line>:<column> (digits only, at the very end; a path carrying anything after the suffix, such as "design.md:40 (section)", is not stripped, and resolves to nothing); a path beginning orbit/changes/<name>/ for the walk's own change resolves under the change directory, archived or active; otherwise it resolves against the project root, then, on a change-scoped walk and only when nothing exists there, against the change directory.
```

`orbit emit address-reviews` checks the record against the files as they stand at emit time. A refusal names the string, the path and the line: fix that file, or list it under `kept` with its `why` — never trim `retired` to get past it.

#### 3e. Remove the marker (invariant)

Unless `--keep-resolved-markers` is set, delete the original `@review: <text>` from its source file:

- **Markdown**: remove the marker text. If it was the only content on a line, remove the line.
- **Source code (C-style)**: remove just the marker text. If the comment now contains only whitespace or the comment delimiters (`//`, `/* */`), remove the whole comment.
- **Source code (hash)**: same as C-style for `# @review:` comments.
- **Virtual marker (external markdown, internal-review JSON, or audit-drift JSON)**: no-op — there's no source text to remove (the source file is an audit artifact). Log as resolved with the appropriate `source` tag (`external`, `internal-review`, or `audit-drift`).

For `unresolvable` conversions (`@todo:` / `@review(escalated):`), the marker is **transformed** in place rather than removed; this is still considered "resolution" for log purposes.

`--keep-resolved-markers` flag: skip the removal step entirely. Debug use only — markers persist after resolution.

### 4. (Internal — Step 3 runs inside this loop)

Iteration. After all markers in scope have walked Step 3, proceed to reporting.

### 5. Report — emit the resolution log

Resolution log is NOT a 3-dimension scorecard. Output structure:

```
## Address-reviews report

Source: <whole-repo | scope <path> | --from-file <path> | auto-discovered <path> — one report section per log when the walk wrote several>
Markers found: <N>
Markers walked: <M> (subset specified: <yes/no>)

### Summary

| Status        | Count |
|---------------|-------|
| ✓ Resolved    | 5     |
| ⚠ Stale       | 2     |
| ⏸ Deferred    | 1     |
| ✗ Escalated   | 1     |

### ✓ Resolved
- **orbit/changes/foo/proposal.md:41** — `@review: five or four?`
  Action: applied trivial fix (`five` → `four` + added explicit list).
  Ripple: design.md, README.md flagged for sibling consistency.

- **src/api/auth.ts:88** — `// @review: token TTL configurable per env?`
  Action: applied user-selected option B (env-var override with default).
  Ripple: src/api/auth.test.ts flagged.

### ⚠ Stale
- **orbit/changes/foo/design.md:159** — `@review: 9 vs 8 after merge`
  Evidence: already corrected in commit abc1234. Marker removed without edit.

### ⏸ Deferred (filed as tasks / converted)
- **orbit/changes/foo/proposal.md:88** — `@review: caching scope`
  Action: filed as task `tasks.md` 10.5; marker removed.

### ✗ Escalated
- **orbit/changes/foo/design.md:204** — `@review: blocking on legal decision re: data retention`
  Action: converted to `@review(escalated): blocking on legal decision re: data retention (escalated 2026-05-18 — see explore.md)`.

### Final assessment

0 unresolved inline markers remaining in scope.
1 escalated marker deliberately persisted.
Suggested next: re-run /orbit:review --as proposal to confirm clean baseline.
```

The final-assessment line summarizes remaining-in-scope markers (0 if clean) plus any deliberately persisted escalations, and names any REDESIGN's route (`/orbit:explore <name>`) without invoking it. What runs next is the engine's eligibility line, read from `orbit status --change <name> --json`.

### 6. Persist the run summary

**ONE resolution log PER SOURCE.** A walk that discovered more than one source writes one log per discovered pass, one per discovered audit-drift emit, and one for the markers when any were found. Each carries its own single `source_path` (the markers' log carries the scope, `source: "scope"`), so the gate's per-pass match reads every log unchanged. The logs go in token order, oldest first, then the markers. In walk mode, write each source's log when that source's findings are walked, before the next source begins. In batch mode the invocation resolves every source's findings, runs its ONE aggregated cascade, then writes every source's log, in the same order; an interrupted batch writes no log for a source whose log was not yet written, and a mid-walk switch to batch applies only to the sources whose logs are not yet written. An interrupted walk leaves the logs it completed on the trail; the sources whose logs were not written stay outstanding, and the next invocation discovers them again. A discovered source's log carries `source: "auto-discovered"`, `source_path` (that one file), `source_command` (its top-level `command`, or `null` for an external return), `source_token` and `latest_apply_token`; no `tie_break_rationale` is written, because nothing is selected by recency.

Compose each payload — narrative + per-command extension fields ONLY; `references/run-summary-schema.md` lists what the AI supplies. The ENGINE owns the spine, the iteration ordinal, `next_recommended` composition, filename + collision handling, and the write gate. Write the payload to a temp file and invoke:

```bash
orbit emit address-reviews --change <name> --payload <payload-file>
```

Architecture-scoped ingest (the source was a `review-architecture-*.json` emit): `--doc <doc-name>` instead of `--change` — the log lands on `orbit/architecture/.orbit-runs/` with `change: null`, keeping the architecture evidence chain whole. Whole-repo / cross-change walks with no change anchor: invoke BARE — `orbit emit address-reviews --payload <payload-file>` — and the engine writes `orbit/.orbit-runs/address-reviews-<TS>.json` with `change: null`. An ARCHIVED change name resolves through the same `--change <name>` invocation (the engine falls back to the archived trail). Every walk persists through the emit surface — never hand-compose the JSON.

## Marker syntax across file types

The command recognizes these marker forms uniformly:

| Context | Form |
|---|---|
| Markdown | `@review: <text>` (bare) |
| C-style code (TS/JS/Go/Rust/C/C++/Java) | `// @review: <text>` or `/* @review: <text> */` |
| Hash-comment files (Python/Ruby/shell/YAML/TOML) | `# @review: <text>` |

Adjacent forms (same discovery grep, different semantics):

| Marker | Meaning | Handled by this command? |
|---|---|---|
| `@review: <text>` | Needs review/decision | Yes — full lifecycle |
| `@review(escalated): <text>` | Escalated, awaiting human | Yes — listed in resolution log; NOT auto-walked unless explicitly scoped |
| `@todo: <text>` | Known follow-up work, NOT a review item | No — out of scope |

## Constraints

- **Never write new `@review:` markers.** Only `/orbit:review --as proposal --mark` does that. address-reviews can transform markers (e.g., to `@todo:` or `@review(escalated):`) but never creates fresh `@review:` markers.
- **Cascade by default; `--no-cascade` opts out.** Ripple-flagged files in the IN set (everything outside the four lifecycle-invariant OUT categories — audit trail, baseline specs, cross-change/archive dirs, safe-exclusions) are auto-edited per Step 3d. File extension is NOT a discriminator.
- **Walk-mode by default; `--batch` opts in.** Each marker gets its own complete pushback → classify → fix → cascade → remove cycle. Batch-mode triggers via `--batch` flag, verbal phrase in the invocation message, or a bare command-shape interruption mid-walk (per Step 3 trigger table).

## Worked examples

Two full ingest walkthroughs — a `--from-file` external-markdown nine-finding walk and a single-SUGGESTION internal-JSON walk — live in `references/resolution-detail.md`.

## Graceful degradation

Every no-input, malformed-input, and unsupported-format case exits clean with a named error; the exact messages and error shapes live in `references/resolution-detail.md`. Two worth knowing at triage: an empty `findings: []` JSON is NOT an error (a clean informational walk report), and a marker found in a baseline spec (`orbit/specs/<capability>/`) is flagged as unusual but walked per user choice.

