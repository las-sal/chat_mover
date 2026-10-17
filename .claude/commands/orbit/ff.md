---
name: "ORBIT: Fast Forward"
description: Create a change and generate all artifacts needed for implementation in one go
category: Workflow
tags: [workflow, artifacts, experimental]
---

Fast-forward: create all artifacts for a change in one go.

This command is a thin launcher: invoke the `orbit-ff-change` skill, passing along any arguments given with the command (e.g., `/orbit:ff <name>`). The skill carries the complete workflow instructions — upstream behavior plus orbit's additions. Do not improvise the workflow from this file; load the skill.
