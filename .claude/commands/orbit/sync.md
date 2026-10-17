---
name: "ORBIT: Sync"
description: Sync delta specs from a change to main specs
category: Workflow
tags: [workflow, specs, experimental]
---

Sync delta specs from a change into main specs without archiving.

This command is a thin launcher: invoke the `orbit-sync-specs` skill, passing along any arguments given with the command (e.g., `/orbit:sync <name>`). The skill carries the complete workflow instructions — upstream behavior plus orbit's additions. Do not improvise the workflow from this file; load the skill.
