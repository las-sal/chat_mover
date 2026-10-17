---
name: "ORBIT: Address Reviews"
description: "Resolve @review: markers or review findings with pushback discipline"
category: Workflow
tags: [workflow, review, orbit]
---

Resolve `@review:` markers or review findings (via `--from-file`, or discovered from a change's outstanding passes) by walking each through pushback → classify → fix → ripple-cascade → remove-marker.

This command is a thin launcher: invoke the `orbit-address-reviews` skill, passing along any arguments given with the command (e.g., `/orbit:address-reviews [<change-or-scope>] [--from-file <path>] [--batch] [--no-cascade]`). The skill carries the complete workflow instructions — upstream behavior plus orbit's additions. Do not improvise the workflow from this file; load the skill.
