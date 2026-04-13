---
name: feedback-checklist-as-file-read
description: The code review checklist skill should be read as a file, not invoked via the Skill tool — it's a reference checklist, not a workflow
type: feedback
---

`s-code-review-checklist` should be referenced with "Read `.claude/skills/s-code-review-checklist/SKILL.md`" — not "Invoke the skill." It's a checklist to apply, not a workflow to run.

**Why:** Gabriel standardized this across s-pr-pre-push-review and s-pr-review for consistency. The checklist is a passive reference, not an active skill with steps.

**How to apply:** When other skills reference the code review checklist, use "Read the file" language, not "Invoke/Use the skill."
