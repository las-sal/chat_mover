# External Review: single-chat-move (iteration 1)

**Reviewer**: GPT-6
**Date**: 2026-10-17

## CRITICAL

None.

## WARNING

### Outside-home projects have no defined target path
**File**: orbit/changes/single-chat-move/design.md:49
**Description**: Projects outside `$HOME` are explicitly accepted with `--skip-code`, but task 2.2 computes their target path using a home-relative suffix that does not exist. For `/opt/work/app`, the artifacts do not establish the target project path, target slug, or resume directory. Define the mapping for this accepted input, add an explicit destination argument, or reject outside-home projects consistently even with `--skip-code`. Add a scenario covering the chosen behavior.

### Staging needs an explicit symlink policy
**File**: orbit/changes/single-chat-move/design.md:36
**Description**: The rewrite walks every staged file, but the artifacts do not define how symbolic links are handled. A symlink in `memory/` or a sidecar can survive staging and point back into the source tree. Opening that staged path for rewriting could modify its referent on the source, violating the source-untouched guarantee. Preserving the link without rewriting can instead leave an unusable source-machine path on the target. Specify whether links are rejected, preserved, or materialized safely, including directory links and links outside the selected tree. Add a fixture verifying that rewriting cannot modify a source referent.

### The no-overwrite contract contradicts the settings update
**File**: orbit/changes/single-chat-move/specs/chat-move/spec.md:75
**Description**: The requirement prohibits overwriting *any* existing target file, while the retention requirement at line 86 and design D7 require replacing an existing `settings.json` when its cleanup window is low. An existing `{"cleanupPeriodDays":30}` makes these requirements mutually exclusive. State the settings update as an explicit, narrowly scoped exception in the spec, proposal, and design. Clarify that preserving existing chat, file-history, and code contents remains mandatory.

### A fixed 365-day retention window does not protect every moved session
**File**: orbit/changes/single-chat-move/design.md:52
**Description**: The proposal promises to prevent moved sessions from being purged as old, but the prescribed guard only raises the cleanup window to 365 days. A session last modified 500 days before migration remains older than that window immediately after transfer. Define whether all selected session ages must be protected; if so, derive a sufficient window from the oldest selected session and specify its safety margin. Otherwise, narrow the promise and warn explicitly when selected sessions exceed the configured window. Add an old-session fixture to verification.

## SUGGESTION

### Verification does not cover both targets’ dry-run exit criterion
**File**: orbit/changes/single-chat-move/tasks.md:29
**Description**: Architecture line 59 requires a dry run against each target, but task 5.3 only names Fedora. Add a Mac mini dry-run check, including confirmation that neither machine is changed.

## Blocks

None.

## Direction

**Disposition**: hold

The transfer approach is plausible, but destination mapping and source-file safety need explicit decisions before implementation. The target safety contract also needs to reconcile the settings exception and define how retention protects older sessions. Resolving these points will give an implementer a consistent contract to follow.

## Notes

Strict validation passed, and no `@review:` markers were found in the change artifacts. The repository contains no archived `orbit/specs` baseline, project orientation files, root convention files, or named review lenses. Cross-document checks therefore used the architecture document and seed script. This review evaluated the proposal contract; the new script does not yet exist.