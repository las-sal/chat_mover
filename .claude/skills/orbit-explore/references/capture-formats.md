# Reference: capture entry formats

Loaded when writing an accepted convention / perspective / critical-path capture (D5 body-economy pass; content moved from the body verbatim).

### Convention capture format

When a convention capture is accepted and writing to `<topic>_convention.md`, the file follows a four-section structured format (created on first write, appended on subsequent):

```markdown
# <Topic> Convention

## Purpose
<why this convention exists>

## Rules
- <rule 1>
- <rule 2>

## Examples
<concrete examples showing the rule in practice>

## Exceptions
<known cases where the rule doesn't apply, with rationale>
```

Heuristic for new file vs append: if user mentions a topic and `<topic>_convention.md` already exists, **target the existing file**. Only when no matching topic file exists is a new file proposed.

**Convention update on contradiction**: when the user's statement contradicts an existing rule, surface the contradiction (don't silently overwrite) and offer to update, supersede, or leave the existing rule. The user decides.

### Perspective / critical-path entry shapes

`orbit/lenses/perspectives.md` entries:

```markdown
## <Perspective name>

**Surfaces**: <capability names this perspective interacts with>

**Description**: <who this caller is, what they want>

**Typical call patterns**: <how they exercise the surface>
```

`orbit/lenses/critical-paths.md` entries:

```markdown
## <Flow name>

**Description**: <what the user is trying to do>

**Touchpoints**: <capabilities / tools / surfaces involved, in order>

**Expected behavior**: <what should happen end-to-end>
```
