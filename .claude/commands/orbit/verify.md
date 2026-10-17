---
name: "ORBIT: Verify"
description: Verify implementation matches change artifacts before archiving
category: Workflow
tags: [workflow, verify, experimental]
---

Verify a change: tasks complete, spec coverage, design adherence.

This command is a thin launcher: invoke the `orbit-verify-change` skill, passing along any arguments given with the command (e.g., `/orbit:verify <name>`). The skill carries the complete workflow instructions — upstream behavior plus orbit's additions. Do not improvise the workflow from this file; load the skill.
