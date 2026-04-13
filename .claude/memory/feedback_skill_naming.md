---
name: feedback-skill-naming
description: Project skills use s- prefix; PR-related skills use s-pr- prefix; descriptions start with "Use when..."
type: feedback
---

All project-specific skills use the `s-` prefix (e.g., `s-code-review-checklist`, `s-run-dev-servers`).
PR-related skills use `s-pr-` prefix (e.g., `s-pr-review`, `s-pr-pre-push-review`, `s-pr-respond-to-feedback`).
Skill descriptions must start with "Use when..." and describe triggering conditions only — never summarize the skill's workflow.

**Why:** Gabriel reorganized all skills for consistency. The `s-` prefix distinguishes project skills from plugin skills. The "Use when..." convention follows the writing-skills guide to prevent Claude from using the description as a shortcut instead of reading the full skill.

**How to apply:** When creating or editing any project skill, follow this naming and description pattern.
