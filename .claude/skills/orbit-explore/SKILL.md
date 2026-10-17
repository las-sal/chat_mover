---
name: orbit-explore
description: Enter explore mode - a thinking partner for exploring ideas, investigating problems, and clarifying requirements. Use when the user wants to think through something before or during a change.
license: MIT
compatibility: Requires orbit CLI.
metadata:
  author: openspec
  version: "1.0"
  generatedBy: "2.0.1"
---

Enter explore mode. Think deeply. Visualize freely. Follow the conversation wherever it goes.

**IMPORTANT: Explore mode is for thinking, not implementing.** You may read files, search code, and investigate the codebase, but you must NEVER write code or implement features. If the user asks you to implement something, remind them to exit explore mode first and create a change proposal. You MAY create orbit artifacts (proposals, designs, specs) if the user asks—that's capturing thinking, not implementing.

**This is a stance, not a workflow.** There are no fixed steps, no required sequence, no mandatory outputs. You're a thinking partner helping the user explore.

---

## The Stance

- **Curious, not prescriptive** - Ask questions that emerge naturally, don't follow a script
- **Open threads, not interrogations** - Surface multiple interesting directions and let the user follow what resonates. Don't funnel them through a single path of questions.
- **Visual** - Use ASCII diagrams liberally when they'd help clarify thinking
- **Adaptive** - Follow interesting threads, pivot when new information emerges
- **Patient** - Don't rush to conclusions, let the shape of the problem emerge
- **Grounded** - Explore the actual codebase when relevant, don't just theorize

---

## What You Might Do

Depending on what the user brings, you might:

**Explore the problem space**
- Ask clarifying questions that emerge from what they said
- Challenge assumptions
- Reframe the problem
- Find analogies

**Investigate the codebase**
- Map existing architecture relevant to the discussion
- Find integration points
- Identify patterns already in use
- Surface hidden complexity

**Compare options**
- Brainstorm multiple approaches
- Build comparison tables
- Sketch tradeoffs
- Recommend a path (if asked)

**Visualize**
```
┌─────────────────────────────────────────┐
│     Use ASCII diagrams liberally        │
├─────────────────────────────────────────┤
│                                         │
│      ┌────────┐         ┌────────┐      │
│      │ State  │────────▶│ State  │      │
│      │   A    │         │   B    │      │
│      └────────┘         └────────┘      │
│                                         │
│   System diagrams, state machines,      │
│   data flows, architecture sketches,    │
│   dependency graphs, comparison tables  │
│                                         │
└─────────────────────────────────────────┘
```

**Surface risks and unknowns**
- Identify what could go wrong
- Find gaps in understanding
- Suggest spikes or investigations

---

## Orbit Awareness

You have full context of the orbit system. Use it naturally, don't force it.

### Check for context

At the start, quickly check what exists:
```bash
orbit list --json
```

This tells you:
- If there are active changes
- Their names, schemas, and status
- What the user might be working on

### When no change exists

Think freely. When insights crystallize, you might offer:

- "This feels solid enough to start a change. Want me to create a proposal?"
- Or keep exploring - no pressure to formalize

### When a change exists

If the user mentions a change or you detect one is relevant:

1. **Read existing artifacts for context**
   - `orbit/changes/<name>/proposal.md`
   - `orbit/changes/<name>/design.md`
   - `orbit/changes/<name>/tasks.md`
   - etc.

2. **Reference them naturally in conversation**
   - "Your design mentions using Redis, but we just realized SQLite fits better..."
   - "The proposal scopes this to premium users, but we're now thinking everyone..."

3. **Offer to capture when decisions are made**

    | Insight Type               | Where to Capture               |
    |----------------------------|--------------------------------|
    | New requirement discovered | `specs/<capability>/spec.md` |
    | Requirement changed        | `specs/<capability>/spec.md` |
    | Design decision made       | `design.md`                  |
    | Scope changed              | `proposal.md`                |
    | New work identified        | `tasks.md`                   |
    | Assumption invalidated     | Relevant artifact              |

   Example offers:
   - "That's a design decision. Capture it in design.md?"
   - "This is a new requirement. Add it to specs?"
   - "This changes scope. Update the proposal?"

4. **The user decides** - Offer and move on. Don't pressure. Don't auto-capture.

---

## What You Don't Have To Do

- Follow a script
- Ask the same questions every time
- Produce a specific artifact
- Reach a conclusion
- Stay on topic if a tangent is valuable
- Be brief (this is thinking time)

---

## Handling Different Entry Points

**User brings a vague idea:**
```
User: I'm thinking about adding real-time collaboration

You: Real-time collab is a big space. Let me think about this...

      COLLABORATION SPECTRUM
      ════════════════════════════════════════════

      Awareness          Coordination         Sync
          │                   │                 │
          ▼                   ▼                 ▼
      ┌────────┐         ┌────────┐        ┌────────┐
      │Presence│         │Cursors │        │  CRDT  │
      │  "3    │         │ Multi  │        │Conflict│
      │online" │         │ select │        │  free  │
      └────────┘         └────────┘        └────────┘
          │                   │                 │
       trivial            moderate           complex

      Where's your head at?
```

**User brings a specific problem:**
```
User: The auth system is a mess

You: [reads codebase]

     ┌─────────────────────────────────────────────┐
     │              CURRENT AUTH FLOW              │
     └─────────────────────────────────────────────┘
                        │
          ┌─────────────┼─────────────┐
          ▼             ▼             ▼
     ┌─────────┐  ┌─────────┐  ┌─────────┐
     │ Google  │  │  GitHub │  │  Email  │
     │  OAuth  │  │  OAuth  │  │  Magic  │
     └────┬────┘  └────┬────┘  └────┬────┘
          │             │             │
          └─────────────┼─────────────┘
                        ▼
                  ┌───────────┐
                  │  Session  │
                  └─────┬─────┘
                        │
                        ▼
                  ┌───────────┐
                  │   Perms   │
                  └───────────┘

     I see three tangles. Which one's burning?
```

**User is stuck mid-implementation:**
```
User: /orbit:explore add-auth-system
      The OAuth integration is more complex than expected

You: [reads change artifacts]

     You're on task 4: "Implement OAuth flow"

     Let me trace what's involved...

     [draws diagram, explores options, suggests paths]

     Want to update the design to reflect this?
     Or add a spike task to investigate?
```

**User wants to compare options:**
```
User: Should we use Postgres or SQLite?

You: Generic answer is boring. What's the context?

User: A CLI tool that tracks local dev environments

You: That changes everything.

     ┌─────────────────────────────────────────────────┐
     │          CLI TOOL DATA STORAGE                  │
     └─────────────────────────────────────────────────┘

     Key constraints:
     • No daemon running
     • Must work offline
     • Single user

                  SQLite          Postgres
     Deployment   embedded ✓      needs server ✗
     Offline      yes ✓           no ✗
     Single file  yes ✓           no ✗

     SQLite. Not even close.

     Unless... is there a sync component?
```

---

## Ending Discovery

There's no required ending. Discovery might:

- **Flow into a proposal**: "Ready to start? I can create a change proposal."
- **Result in artifact updates**: "Updated design.md with these decisions"
- **Just provide clarity**: User has what they need, moves on
- **Continue later**: "We can pick this up anytime"

When it feels like things are crystallizing, you might summarize:

```
## What We Figured Out

**The problem**: [crystallized understanding]

**The approach**: [if one emerged]

**Open questions**: [if any remain]

**Next steps** (if ready):
- Create a change proposal
- Keep exploring: just keep talking
```

But this summary is optional. Sometimes the thinking IS the value.

---

## Guardrails

- **Don't implement** - Never write code or implement features. Creating orbit artifacts is fine, writing application code is not.
- **Don't fake understanding** - If something is unclear, dig deeper
- **Don't rush** - Discovery is thinking time, not task time
- **Don't force structure** - Let patterns emerge naturally
- **Don't auto-capture** - Offer to save insights, don't just do it
- **Do visualize** - A good diagram is worth many paragraphs
- **Do explore the codebase** - Ground discussions in reality
- **Do question assumptions** - Including the user's and your own

# Orbit additions

The sections below describe orbit-specific additions on top of upstream's "stance, not workflow" character. The upstream content above is as `orbit-conventions`' `Generated-file disposition` records it; orbit layers capture affordances, an `explore.md` authoring convention, and three invocation modes that activate when the conversation produces material worth keeping.

## Four execution disciplines (epitome)

The four disciplines from `orbit-conventions`, embedded per body; detail lives where each fires.

- **Read-before-reference (authoring-time)**: before a captured artifact names a specific construct, read its actual definition; unverifiable → ask the user or leave a `@review:` marker instead of guessing.
- **Change completeness (modification-time)**: section moves in `explore.md` land whole (a resolved Open question MOVES to Decisions — never left in both); re-read the section after to confirm.
- **Pushback (review-time)**: when the conversation flags something as already-decided, verify against `explore.md` before treating it as new; don't re-litigate captured decisions.
- **No-chaining (turn boundary)**: invoke only the orbit workflow commands the user's message explicitly requests; completing a command ENDS the turn at the position readout + the engine's eligibility line — gate `passed` means *eligible*, not *commanded*.

## Three invocation modes

| Mode | Trigger | What happens |
|---|---|---|
| **A — Bare** | `/orbit:explore` with no argument and no crystallization trigger | Upstream behavior. Conversational think-mode, no file created, no staging directory. |
| **B — Named** | `/orbit:explore <name>` | Resolve the name by the re-entry table below (nine cells, four refused). **New** — no staging directory AND no active change of that name: scaffold the six sections AND the minimal `.openspec.yaml` (see below). **Resume** — `orbit/explore/<name>/explore.md` exists with the `exploring` token AND no active change of that name: read the existing file as authoritative; a pre-D2 staging directory lacking `.openspec.yaml` gains it on resume (add-only, citation still optional); a file lacking a `## Mechanism` section gains one (add-only). |
| **C — Crystallized** | Bare invocation that produces 2+ substantive decisions | Prompt the user: "We have enough material here to capture — what should we call this exploration?" On accept, transition to Mode B and back-fill what's been discussed (the minimal `.openspec.yaml` is written as in Mode B). On decline, continue Mode A and don't re-prompt this shape. |

### Re-entry resolution (Mode B) — one table

`/orbit:explore <name>` resolves the name against FOUR facts — a staging directory exists; it is concluded (per the status-header production below; defined only when the directory exists); an active change of that name exists; that change carries an `explore.md` (defined only when the change exists) — as ONE table, nine cells, four refused:

| staging dir | concluded | active change | change carries `explore.md` | resolution |
|---|---|---|---|---|
| no | — | no | — | Mode B new |
| yes | no | no | — | Mode B resume |
| yes | yes | no | — | state the conclusion and its `Re-entry:` trigger, ask nothing else; REOPEN only on the user's word |
| no | — | yes | yes | resume IN PLACE against `orbit/changes/<name>/explore.md`, say so, scaffold nothing |
| no | — | yes | no | Mode B new IN the change directory — the file is created beside the artifacts; no staging directory is scaffolded |
| yes | either | yes | either | REFUSED — second claim on one truth; name both paths and stop (neither resume nor scaffold) |

*Mirror of `orbit-explore-modifications`' "Re-entry resolution and the conclude verb" — that requirement owns this table; the generated-surface parity test holds this copy byte-equal to it (R-crc-14's mirror corollary).*

One edge the table's second fact implies: a staging directory WITHOUT `explore.md`, or whose header carries neither fixed token, resolves as not-concluded and resumes with the stub or header added (add-only) — never MALFORMED. The status-header production is read on the change-directory file too: a `concluded` header inside `orbit/changes/<name>/explore.md` (a name promoted without reopening) resolves as the third row — state the conclusion and its trigger, reopen only on the user's word — never as a silent resume.

### Minimal explore metadata (`.openspec.yaml`, D-arc Stage D2)

Mode B/C explorations carry `orbit/explore/<name>/.openspec.yaml` — the same metadata genre as
changes. Base fields: `schema: spec-driven` + `created: <YYYY-MM-DD>` (placeholders written via
the unchanged change-metadata helpers, whose validation requires a registered schema; both are
superseded at promotion, where `/orbit:propose`'s merge writes fresh
`schema`/`created`/`schema_version` — the placeholder never leaks into a change).

**Optional `architecture: {doc: <name>, stage: <id>}` citation**: when the exploration serves a
declared stage of an architecture doc (the name or the conversation indicates it — e.g. the
exploration was opened from a program stage's charter), OFFER to record the citation; on accept,
write it into the metadata. Otherwise omit it — a standalone exploration carries zero citation
ceremony. The citation makes the stage's computed state render `exploring` in
`orbit architecture status`; it carries forward into the change at promotion.

### What counts as a "substantive decision" for Mode C crystallization

A decision counts toward the 2+ threshold if it:

- (a) Resolves between two or more named alternatives (e.g., "go with X instead of Y")
- (b) Locks a name, structure, or format ("we'll call it Z", "the file will have these sections")
- (c) Supersedes an earlier choice ("change our mind on X, go with Y instead")

Does NOT count: exploratory thinking, speculation, "let me think about X", or restating something already established.

## explore.md six-section convention

When a named exploration exists (Mode B/C), `orbit/explore/<name>/explore.md` follows this structure — SIX sections in this order. The format is `orbit-conventions`' (its requirement keeps its historical title for delta identity; the format it specifies is six). The three productions in this section — the status header, the Decisions entry, the Mechanism entry — are MIRRORS of the productions `orbit-conventions` owns, carried here because a generated skill cannot resolve that spec at runtime; a parity test holds each byte-equal to its owner (R-crc-14's mirror corollary), and every other mention in this body points at them.

```markdown
> **Status**: exploring. Promoted to proposal/design/specs via /orbit:propose when decisions firm up.

# Exploration: <name>

## Premise
<the problem space; why this exploration; what we're trying to figure out>

## Mechanism
<one entry per live rule in Decisions, keyed by the rule's ID, in the entry grammar below: the domain as a table, the closure token, the residual slots iff BOUNDED, nine move lines; `### Case <n>` blocks hold the evidence the move lines cite>

## Decisions
<dated entries in the entry format below; each captures ONE claim, a brief rationale, and its `Kind:`>

## Open questions
<things we don't know yet; resolved later by moving to Decisions, deferred as @review: markers via /orbit:propose, or abandoned to Considered & out. EVERY entry carries the slot line `Standing recommendation: <the current leaning verbatim>` — or the literal `Standing recommendation: none yet` when no leaning exists; never an entry with the slot absent (D-arc Stage D5, leak-hardening layer 1)>

## Considered & out
<options that came up and got rejected, with brief rationale + date>

## References
<files, URLs, prior changes, prior conversations worth reading during artifact generation>
```

When creating a new file, all six sections are scaffolded (empty content under each heading). When resuming, read the existing file as authoritative; a file written before this format, with no `## Mechanism` section, is read and not rejected — the section is added on next touch (a format note, never a blocker).

### The status header — one production

The file's first non-blank line carries one of TWO fixed tokens, matched by this production:

```
^> \*\*Status\*\*: (exploring\.( .*)?|concluded \d{4}-\d{2}-\d{2}\.)$      the file's first non-blank line
```

*Mirror of `orbit-conventions`' `explore.md` format requirement (its retained title names the old section count; the format is six sections) — the owner of this production.*

- `> **Status**: exploring. …` — the working token; the rest of the line is free prose.
- `> **Status**: concluded <YYYY-MM-DD>.` — the ONLY other legal token, written by the conclude flow ("Concluding an exploration" below).

Any other first line is NEITHER token: the file resolves as not-concluded and the header is added on next touch (add-only) — never MALFORMED. A status line is a pointer, not an entry.

### Decisions entries — the ENTRY is the key

Each Decisions entry is a top-level list item whose opener is the ID slot — the opener every exploration on record already writes, formalized rather than replaced (zero migration). One production. A slot is matched anywhere within the lines that belong to the entry's list item — a lazy-continuation line or a nested bullet both qualify, which is what the optional bullet prefix admits; the ` — ` in the opener is the literal em-dash:

```
- **<YYYY-MM-DD> — <ID>: <title>** <prose…>            the opener; the ID slot; <ID> ::= D-[a-z0-9]+-[0-9]+, unique within the file
  Kind: rule | fact | scope                               ^\s*(?:[-*+]\s+)?Kind:\s*(rule|fact|scope)\s*$
  Disposition: live | superseded <ID or pointer> | assigned <stage-id>     same optional bullet prefix as Kind:
  Re-entry: <what would reopen it>                        concluded entries only; exactly one LIVE entry carries it
```

*Mirror of `orbit-conventions`' "Decision entry identity and classification" — the owner of this production.*

**One claim under obligation per entry.** A Decision is a RULE when it PRESCRIBES or CONSTRAINS how something must be done across a SET of situations — the test is "in which situations does this apply?", applied to the claim's NORMATIVE force, never to its grammar. A quantified EMPIRICAL claim ("heading count has never correlated with readiness under any conditions") has a logical domain and is a FACT: it describes one world and is falsifiable by evidence. A SCOPE choice (in / out / deferred) is one-off. The test applies PER CLAIM as an authoring rule: an entry carrying more than one claim under obligation is SPLIT by the author into entries with distinct IDs (the rule entry owes a Mechanism entry; the finding carries `Kind: fact`). There are no claim-level identifiers.

- `Kind: rule | fact | scope` — **absent means `rule`.** The demanding default turns an omission into a rule that owes a Mechanism entry (rendered as open by ID once a reader parses it) rather than an invisible escape; opting out is WRITTEN. A rule the author never entered at all remains outside every reader's sight — the stated residual, per `Mechanism entry grammar and accounted closure` (R-crc-10).
- `Disposition: live | superseded <ID or pointer> | assigned <stage-id>` — absent means `live`. ONE meaning for every entry: `live` says the claim STANDS; `superseded` and `assigned` say it does not, and point to what does. Two consequences: a RULE is IN the accounting obligation only while its Kind is rule (or absent) AND its Disposition is live (or absent); a CONCLUDED entry's `Re-entry:` slot is the live one only while its Disposition is live (or absent). Leaving the obligation is a NAMED act — an entry left `live` with a bare prose note ("overtaken", "moot") is still in it.

A Decisions entry without a well-formed ID is a format violation corrected on next touch.

### Mechanism entries — the grammar

The Mechanism section carries one entry per LIVE rule (`Kind:` rule or absent AND `Disposition:` live or absent), keyed by the rule's ID. The grammar, stated normatively so a parser can be written from it alone:

```
## Mechanism
### <ID> — <rule title>              an entry; ends at the next heading of level 1–3, or EOF
Domain: <the set, in one line>
| member | covered by |              the enumeration, as a table (R-crc-7: decision tables); at least one member row; cells follow GFM — `\|` is a literal pipe, never a separator
Closure: <TOKEN>[ — <justification>]   <TOKEN> ::= DERIVED | SOURCED | BOUNDED, matched from line start to the first ` — ` or end of line
Residual kind: <what lies outside>            required iff BOUNDED, forbidden otherwise
Residual method: <how a member would be found> required iff BOUNDED, forbidden otherwise
Moves:
- <MOVE>: applied — <what it found>   |   - <MOVE>: not applied — <reason>     (` — ` is the literal em-dash)
                                      nine lines, one per move, each move exactly once
### Case <n> — <title>               evidence, free-form, cited by move lines by name
```

*Mirror of `orbit-conventions`' "Mechanism entry grammar and accounted closure" — the owner of this grammar.*

Three H3 kinds under Mechanism: a heading beginning `D-` is an ENTRY; one beginning `Case` is a CASE; any other H3 is prose and is neither. Fenced content is never structure. The container is H3 rather than a list item because domains are TABLES and a table inside a list item is fragile.

**A grammar failure is MALFORMED, naming the line**: a malformed ID; a second entry with an ID already used (naming the second heading); an ORPHAN entry whose ID matches no Decisions entry (naming the heading — a key with no owner); a `Domain:` table with other than the two `member | covered by` columns, no separator row, or NO member rows — an enumeration of nothing is not an enumeration — (naming the table's first line); a missing or duplicated move line; an unknown `Closure:` token; a residual slot on a non-BOUNDED entry; a BOUNDED entry missing a slot. NOT malformed: an entry for a Decisions entry whose `Kind:` is fact or scope or whose `Disposition:` is superseded or assigned — history is permitted and sits outside the obligation. Nothing reads as legacy silently (the architecture parser's near-miss rule).

The engine judges FORM only: whether a live rule has an entry, whether it declares a token, whether the slots the token requires are present. Whether an enumeration is TRUE, whether a residual is honest, and whether a rule was written down at all are a reader's judgement — the deliverable is a RECORD, not a check (R-crc-10).

### Closure is ACCOUNTED, not CLOSED

The obligation is that no domain be open SILENTLY, and two outcomes discharge it:

| outcome | tokens | what it claims |
|---|---|---|
| **CLOSED** | DERIVED (generated by a structure whose parts are known, every part covered) · SOURCED (exhaustive over a set an authority defines — a type, a code branch set, a grep over a named file) | every member is covered, and the justification says why that is provable |
| **OPEN-DECLARED** | BOUNDED | the named members are covered, a residual REMAINS, and its shape is stated |

A BOUNDED residual names its KIND (what lies outside the named set) and its METHOD (how a member would be found), in the two slots. "There may be others" discharges nothing: it is the sentence the obligation exists to forbid, wearing the obligation's vocabulary. *"I can name no more"* is NOT a form — it is the state every failed enumeration on this program's record was in, and from the inside it is indistinguishable from closure. Classifying a record FALSIFIES an enumeration and never closes one.

**The tier difference is VISIBILITY, never BLOCKING.** An OPEN-DECLARED domain does not block readiness; its residual is SURFACED and TRAVELS rather than dying in the exploration. The two slots are the ORIGIN every downstream reader reads. Where it travels: into the requirement's own text as a named limit (the OWNER, because only spec text survives archive) and into `design.md`'s Risks as a pointer — a residual carried in design alone is lost at archive. The mechanisms that move it are OWNED elsewhere: `orbit-run-summary-emit`'s `Named-mode explore recommendation by maturity` surfaces it beside its rung, and `orbit-propose-modifications`' `Mechanism section consumption` carries it into spec text at promotion (see "Composition with /orbit:propose").

### The nine moves, applied per rule

A rule's Mechanism entry is the record of NINE MOVES applied to that rule, each a way a mechanism can be wrong:

| part of the mechanism | the way it goes wrong | move |
|---|---|---|
| the facts it cites | the fact is not true | **READ** |
| its input domain | a member it ranges over is unhandled | **ENUMERATE** |
| its own parts | two of them assume incompatible things | **COHERE** |
| its computation | wrong output on a member it does handle | **EXECUTE** |
| its purpose | it is correct and still misses a class of defect | **FALSIFY** |
| its context | it violates a standing ruling | **CONFORM** |
| its resources | it does not terminate, or does not fit | **FEASIBILITY** |
| its output's consumer | the output is correct and the mechanism consuming it breaks | **CONSUME** |
| its trigger | it is correct, complete, and nothing ever causes it to run | **INVOKE** |

*Mirror of `orbit-explore-modifications`' "Nine moves applied per rule in the Mechanism section" — the owner of this table.*

**The set is BOUNDED, declared in its own slots.** Residual kind: a further way a mechanism is wrong that none of the nine names. Residual method: classifying another record's CRITICALs against the table — the only method that has ever grown it (five to six on rc03a's record; six to eight on rc02's; eight to nine when a review pass found INVOKE in the first attempt's own evidence). Confidence about closure was wrong three times and every correction came from a record, never from further thought.

**How the set grows.** A defect that classifies to NO move is a finding about the SET: leave an `@review:` marker in the exploration that found it AND carry it into that change's review emit as a finding against `orbit-explore-modifications`' nine-moves requirement. Growing the set is a change to that requirement; nothing grows it silently.

**The boundary test**, because a dismissal branch with no test is an invitation: a candidate is IN when it names a way the mechanism ITSELF fails — its facts, domain, parts, computation, purpose, context, RESOURCES, consumer, or trigger (the vocabulary is the table's rows, all nine). A candidate is OUT when it concerns how the rule is PRESENTED or AUTHORED — medium choice (prose versus a slot) is the standing example. When the test does not decide, the candidate is IN: over-covering costs one disposition line, under-covering costs a review cycle.

READ is the read-before-reference discipline and ENUMERATE is the accounting obligation, both existing rulings made checkable where mechanism is AUTHORED. EXECUTE is NOT sufficient alone: an executed case demonstrates one path, and eleven of one stage's fifteen CRITICALs were READ, ENUMERATE or COHERE failures with zero EXECUTE failures.

### Exemplar — two conforming entries, one per closure outcome

Two entries of the `bounded-closure-semantics` change, verbatim — D-bcs-3 (CLOSED: SOURCED) and D-bcs-12 (OPEN-DECLARED: BOUNDED, both residual slots) — so the convention shows both shapes rather than describing them (the generated-surface test asserts every line against the grammar's productions, both branches; the engine's form parse accepts the same entries under the grammar `orbit-emit-composition`'s `The explore grammar has one source in code` carries):

```markdown
### D-bcs-3 — an open-declared domain is SURFACED, never BLOCKING
Domain: every surface an OPEN-DECLARED residual must reach
| member | covered by |
|---|---|
| the Mechanism entry (origin) | `Residual kind:` / `Residual method:` |
| proposal.md | not a carrier — states scope, not limits |
| design.md | a Risks entry naming the residual; POINTS to the spec row |
| specs/<capability>/spec.md | a named limit in the requirement's own text — the OWNER, because only spec text survives archive |
| tasks.md | not a carrier |
| the explore readout | rc13b's rung names the residual, never withholds on it (D-bcs-10) |
Closure: SOURCED — the change artifact set is the spec-driven schema's, plus the one readout that reads Mechanism
Moves:
- READ: applied — rc02's limit sits in `orbit-engine-gates`' requirement text, as the spec row says
- ENUMERATE: applied — this table; the 2026-09-15 draft named no members
- COHERE: applied — never-blocking here and never-withholding in rc13b are one predicate, not two
- EXECUTE: not applied — no residual has yet travelled under this rule; rc02's predates it
- FALSIFY: applied — a residual carried in design only would vanish at archive, because design is never synced; hence the spec row is the owner
- CONFORM: applied — R-crc-10, R-crc-13, R-crc-14 (spec owns, design points)
- FEASIBILITY: not applied — two lines per residual
- CONSUME: applied — rc13b reads the two slots; propose carries them into design and spec
- INVOKE: applied — fires at propose, when the Mechanism entry is consumed

### D-bcs-12 — the move set is NINE, and it is BOUNDED in its own slots
Domain: the ways a mechanism can be wrong, one per part of the mechanism
| member | covered by |
|---|---|
| the facts it cites | READ |
| its input domain | ENUMERATE |
| its own parts | COHERE |
| its computation | EXECUTE |
| its purpose | FALSIFY |
| its context | CONFORM |
| its resources | FEASIBILITY |
| its output's consumer | CONSUME |
| its trigger | INVOKE |
Closure: BOUNDED — the parts of a mechanism are not a closed structure; the set has grown three times and every growth came from a record
Residual kind: a further way a mechanism is wrong that none of the nine names
Residual method: classifying another record's CRITICALs against the table — the only method that has ever grown it (five to six on rc03a's record; six to eight on rc02's; eight to nine on the first attempt's own review trail)
Moves:
- READ: applied — the three growth events read from the archived first attempt (Cases 7 and 10) and its review trail
- ENUMERATE: applied — this table; the boundary test admits a candidate that names a way the mechanism ITSELF fails
- COHERE: applied — the residual's method is the boundary test run against a record, so the two slots and the growth path are one procedure
- EXECUTE: applied — the nine were run against every rule in this file: eight entries before this one, no move left without a disposition
- FALSIFY: applied — a defect that classifies to no move is a finding about the SET; the growth path exists for exactly that
- CONFORM: applied — R-crc-7 (a decision table), R-crc-10 (a record), R-crc-14 (the spec owns the table; the body mirrors it)
- FEASIBILITY: not applied — nine lines per rule, one each
- CONSUME: applied — rc13b's parser reads move lines by name and must know all nine; this entry is the BOUNDED shape its fixture must also parse
- INVOKE: applied — fires on every Mechanism entry, since each move line names a member
```

**Section-evolution rules**:

- **Resolving an Open question** → move the entry to Decisions with a dated rationale, as an entry with an ID opener and its `Kind:`; acknowledge in chat ("captured").
- **Rejecting a considered option** → move it to Considered & out with brief rationale + date.
- **New decision emerges** → append to Decisions proactively (with brief chat acknowledgment), with its ID opener and `Kind:`.
- **A rule is captured** → write its Mechanism entry IN THE SAME SITTING (domain table, closure token, residual slots iff BOUNDED, nine move lines) — or leave the entry with `Kind: rule` and no Mechanism entry as a VISIBLE open domain; never downgrade the Kind to escape the obligation. This is the one statement of that rule; the residency sweep points here.
- **A rule is replaced or handed to another stage** → its entry gains `Disposition: superseded <ID or pointer>` or `Disposition: assigned <stage-id>`.
- **A leaning emerges on an open question** (discussed but not yet a decision) → write it into that entry's `Standing recommendation:` slot verbatim — a pending leaning always has a file-resident home; `none yet` is only for questions with no leaning at all.
- **Reference cited** → append to References (offer first when in doubt).

### Concluding an exploration

An exploration MAY conclude in nothing, and the record says so in TWO engine-observable tokens — both written ONLY on the USER'S declared word inside a named session. Recommend, never infer: when you judge an exploration should stop and the user has not said so, recommend concluding and write nothing. Conclude is NOT a consent-marked seam — no gate, no prompt, no `consent` field on the explore emit — and there is no new command; the surface stays as it is.

The conclude verb, in this ORDER:

1. the boundary residency sweep (below, under "Run-summary emit");
2. ONE CONCLUDED Decisions entry — what was decided, WHY nothing is built — carrying `Kind: scope` and a `Re-entry: <what would reopen it>` slot (the owner of the trigger; exactly one LIVE entry carries the slot);
3. the status header flips to `> **Status**: concluded <YYYY-MM-DD>.` (the pointer; per the status-header production);
4. THEN the final boundary emit, whose `final_assessment` states the conclusion in the author's words. The emit's engine-computed counts describe the concluded file; its `next_recommended` is the Concluded rung's prose (`orbit-run-summary-emit`'s `Named-mode explore recommendation by maturity`).

Nothing is written to `.openspec.yaml`: the change-metadata helpers' schema STRIPS unknown keys at every level (measured, 2026-09-25), so a metadata token could not survive the body's own write path. The `architecture:` citation is KEPT unchanged — it is what locates the directory whose header a stage-state reader will read. The staging directory STAYS IN PLACE, trail and all: a conclusion carries a standing re-entry trigger (the program layer's Considered & out shape), and the orientation surface renders a workstream's next line from the trail in ITS directory — moving it would leave the conclusion with no surface to render on. Nothing relocates it to an archive directory or a dot-directory.

**Owned, since shipped**: the stage-state reader reads the header token from the staging directory the kept citation locates and observes a stage cited only by a concluded exploration as `concluded` (`orbit-architecture-engine`'s `Computed stage state with completion-as-ratification`); the orientation row's next line renders the concluded rung from the trail's terminal emit (`orbit-orientation`'s `Next-recommendation sourcing is time-shifted, never live`); and `/orbit:propose <name>` refuses a concluded exploration, naming its `Re-entry:` slot (`orbit-propose-modifications`' `Consume mode when staging directory exists`). None of the three is a limit of concluding; each is named here so a reader of the conclude flow knows who owns the behaviour the conclusion depends on.

**Reopening** is the inverse edit, on the user's word: the header returns to `exploring`; a dated Decisions entry records why (the trigger fired, or a new reason); the prior CONCLUDED entry gains `Disposition: superseded <the reopening entry's ID>`, so its `Re-entry:` slot is no longer the live one; then a boundary emit. **A second conclusion** writes a NEW CONCLUDED entry carrying the live `Re-entry:` slot; the earlier one stays as superseded history; the header token flips again — exactly one live entry carries the slot at every point in the cycle.

## Five capture types and where each lands

| Type | Trigger | Target file | Offer or auto? |
|---|---|---|---|
| **Decision** (Mode B/C only) | Explicit decision in named exploration | `orbit/explore/<name>/explore.md` Decisions | Auto-capture + brief chat acknowledgment ("captured") |
| **Convention** | "we always do X" / "let's standardize on…" | `<topic>_convention.md` at project root (e.g., `naming_convention.md`) | **Offer** — one-sentence offer naming the target file |
| **Perspective** | User describes a caller/client ("Claude Desktop calls our MCP server", "from the Swift host's POV") | `orbit/lenses/perspectives.md` | **Offer** |
| **Critical path** | User describes a critical user flow ("the typical user flow is…", "users typically…") | `orbit/lenses/critical-paths.md` | **Offer** |
| **Reference** | URL, file, prior change, prior conversation worth reading later | `explore.md` References section | **Offer** when in doubt; quick add when the relevance is obvious |

### Capture entry formats

The exact file formats — the four-section `<topic>_convention.md` shape (create-vs-append heuristic, contradiction handling) and the `orbit/lenses/perspectives.md` / `critical-paths.md` entry shapes — live in `references/capture-formats.md`; load it when writing an accepted capture.

## Offer-don't-auto rule

For **conventions, perspectives, critical paths, and references**: the command offers to capture; the user decides. **Decisions** in named explorations are the exception — they're proactively captured with brief acknowledgment.

**Offer phrasing**: pause briefly and emit a one-sentence offer naming the target file. Example: `That sounds like a convention. Capture in naming_convention.md?`

**Group offers when natural**: when multiple capture-worthy items of the same type emerge in close succession (e.g., three conventions in one paragraph), group them into a single offer rather than asking three times.

**User veto**: if the user says "don't capture that" or similar, the proposed capture is not written and the conversation continues unaffected.

## Decline tracking

Within a single conversation, track recent capture declines. If the user has declined a specific convention capture, **don't re-offer** that same convention later in the same conversation. (Tracking is per-conversation; declines don't persist across sessions.)

## Sibling captures supported

The staging directory `orbit/explore/<name>/` can hold additional files beyond `explore.md`:

- `orbit/explore/<name>/sketches/<sketch-name>.md` — design sketches that don't yet warrant being a Decision
- `orbit/explore/<name>/<draft-convention>.md` — draft convention files that aren't ready to live at project root

These sibling files persist alongside `explore.md` and move into `orbit/changes/<name>/` together when `/orbit:propose` consumes the exploration.

## Composition with `/orbit:propose`

When the user runs `/orbit:propose <name>` and `orbit/explore/<name>/explore.md` exists, propose switches to **consume mode**: reads `explore.md` as authoritative, prompts for Open question handling, generates `proposal.md` / `design.md` / `specs/` / `tasks.md`, and **moves** the staging directory to `orbit/changes/<name>/`. The exploration record persists as historical context alongside the generated artifacts.

This means: durable capture in explore → seamless promotion to formal change. The user doesn't re-type what was already discussed; the AI doesn't paraphrase what was already decided.

The Mechanism section travels with the file. A BOUNDED residual's two slots are carried at promotion into the requirement's own text (the owner) and into `design.md`'s Risks (a pointer) — that transfer is `orbit-propose-modifications`' `Mechanism section consumption` (Step 0c.6 of the propose body). A concluded exploration is REFUSED at propose and REOPENED here first (see "Concluding an exploration").

## Run-summary emit (named-mode only)

(Per `orbit-run-summary-emit`; composed and written via the engine emit surface, `orbit-emit-composition`.)

Named-mode `/orbit:explore <name>` emits TWICE per session shape (D-arc Stage D3): once at BEGIN and once at each conversation boundary.

**Boundary residency sweep — "no emit without sweep"** (D-arc Stage D5, leak-hardening layer 2; begin emits excepted — nothing has been discussed yet): before EVERY boundary emit, sweep the conversation since the last emit for decisions, leanings, rejections, and citations that are not yet file-resident, and write each into its slot — Decisions (with the entry's ID opener and `Kind:`) / a rule's Mechanism entry (its domain table, its closure token and residual slots, or a move's disposition) / an open question's `Standing recommendation:` / Considered & out / References — BEFORE invoking the emit. A rule whose domain, closure or a move disposition was settled in conversation and whose entry does not yet carry it is written into the entry before the emit; a rule left with no entry stays a visible open domain (per the "A rule is captured" section-evolution rule). The sweep rides this existing boundary trigger — no new prompt, no user-facing step — so the engine-computed attestation counts describe the SWEPT file, and `orbit-audit-drift`'s cross-check closes the loop.

Both emits fire the same invocation — compose the narrative payload (`final_assessment` + the required nullable `model`) into a temp file, then:

```bash
orbit emit explore --change <name> --payload <payload-file>
```

The ENGINE owns everything else: the spine, the trail path (`orbit/explore/<name>/.orbit-runs/explore-<TS>.json`), timestamp + collision handling, the decisions/open-questions counts read fresh from `explore.md`, and the maturity-graded `next_recommended` (per `orbit-run-summary-emit`'s maturity requirement, which owns the rungs and their inputs). Never hand-compose the JSON. Bare-mode `/orbit:explore` does NOT emit — see "Crystallization to named change" below.

### BEGIN emit (D-arc Stage D3 — mode-aware)

Fire the begin emit immediately after the staging scaffold + `.openspec.yaml` are written, so the trail records the workstream from minute zero (the `premised → exploring` transition). Mode B (new named exploration): the scaffold is empty, so the engine's counts render 0 and the recommendation renders Early; `final_assessment` records the scaffold + the citation decision (cited or declined). Mode C (crystallization): back-fill `explore.md` FIRST, then fire — the engine computes the BACK-FILLED counts, so the trail's first record states true on-disk state, never a knowingly-false zero; this begin emit IS the crystallization's first emit.

**No retro-fire**: resuming a pre-D3 staging dir that has no emits does NOT retroactively fire a begin emit (add-only, no backdating) — the next boundary emit covers it.

### Conversation boundary detection

Per `orbit-run-summary-emit`'s `Emit timing semantics` requirement, a conversation boundary for multi-turn conversational commands like `/orbit:explore` is EITHER:

1. **User explicitly signals stop or pause** — "stop", "pause", "that's it for now", "we'll come back to this later", or equivalent intent
2. **AI-initiated wrap** — AI says something like "I've captured everything; type `/orbit:propose <name>` when ready" or equivalent intent (an explicit suggestion of the next workflow step)

**Canonical orbit UX convention**: when handing control back to the user after substantive explore work, include an explicit wrap phrase suggesting the next step. This turns the handoff into a rule-2 signal and triggers the emit naturally without needing to predict future user behavior.

**NOT a boundary** (no emit): AI returning control mid-thought to ask a clarifying question; user tangent and return; AI tool-use sequences within a single turn.

### Bare-mode non-emission

Bare-mode `/orbit:explore` (no name) writes ZERO files — exploration without a name is pre-commitment, ephemeral thinking. Emitting before a name exists would pollute project scope and accidentally seed partial changes the user didn't intend to start.

### Crystallization to named change (bare-mode → named-mode transition)

When the user requests crystallization during a bare-mode explore (e.g., "save this as `<name>`", "let's give this a name and capture it", or equivalent intent), the AI **MUST surface an explicit warning describing the persistence consequences BEFORE creating any files**.

**Required warning content** — the warning MUST mention all 4 consequences:

1. A new directory `orbit/explore/<name>/` will be created with `explore.md` capturing decisions to date.
2. The first run-summary JSON (`orbit/explore/<name>/.orbit-runs/explore-<TS>.json`) will start the change's audit trail.
3. The change will become visible to any consumer that scans `orbit/explore/` (e.g., a downstream status reader). Note: upstream `orbit list` does NOT scan `orbit/explore/`; the change appears in `orbit list` only after `/orbit:propose` moves the staging directory to `orbit/changes/<name>/`.
4. Abandonment after this point requires formal archive/discard, not just deleting the directory once it's been moved to `orbit/changes/<name>/` by `/orbit:propose`; before promotion, an exploration that will build nothing is CONCLUDED in place (see "Concluding an exploration"), not deleted.

**Confirmation gate**: the AI MUST wait for explicit user confirmation before proceeding with file creation. Examples of confirmation: "yes", "go ahead", "create it", "do it". If the user expresses any hesitation or asks a clarifying question, treat as not-yet-confirmed and answer the question rather than proceed.

After confirmation: (1) create `orbit/explore/<name>/explore.md` (and the minimal `.openspec.yaml`, as in Mode B), back-filling Premise and Decisions with what's been discussed; (2) THEN fire the BEGIN emit per the mode-aware rules above — the engine computes the back-filled counts and a maturity-consistent recommendation.

This warning convention aligns with orbit's don't-auto-invoke-commands and inflection-points-surface-consequences conventions.

