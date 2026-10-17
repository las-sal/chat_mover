---
name: "ORBIT: Review"
description: Editorial review of a change (proposal/system mode) or an architecture doc (architecture mode)
category: Workflow
tags: [workflow, review, orbit]
---

Run an editorial review of a change — proposal mode (pre-apply, 9 passes) or system mode (post-apply, verify-change + 6 system-wide passes) — or of an architecture doc (--as architecture: 6 passes, no gate).

This command is a thin launcher: invoke the `orbit-review` skill, passing along any arguments given with the command (e.g., `/orbit:review [<change-name-or-doc-name>] [--as proposal|system|architecture] [flags]`). The skill carries the complete workflow instructions — upstream behavior plus orbit's additions. Do not improvise the workflow from this file; load the skill.
