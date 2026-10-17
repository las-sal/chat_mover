---
name: "ORBIT: Apply"
description: Implement tasks from an orbit change (Experimental)
category: Workflow
tags: [workflow, artifacts, experimental]
---

Implement tasks from a change.

This command is a thin launcher: invoke the `orbit-apply-change` skill, passing along any arguments given with the command (e.g., `/orbit:apply <change-name>`). The skill carries the complete workflow instructions — upstream behavior plus orbit's additions. Do not improvise the workflow from this file; load the skill.
