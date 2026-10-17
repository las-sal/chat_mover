---
name: "ORBIT: Audit Drift"
description: Project-wide scan for drift between captured knowledge and reality
category: Workflow
tags: [workflow, audit, orbit]
---

Scan the project for drift between captured knowledge and reality across four categories: vocabulary residue, lens staleness, cross-doc consistency, archive coherence.

This command is a thin launcher: invoke the `orbit-audit-drift` skill, passing along any arguments given with the command (e.g., `/orbit:audit-drift [<change-name>] [--fast|--full] [--focus <area>] [--since <ref>]`). The skill carries the complete workflow instructions — upstream behavior plus orbit's additions. Do not improvise the workflow from this file; load the skill.
