---
name: s-requirements-review-codex
description: Use when the user wants Codex (OpenAI) to review a requirements document or GitHub issue before committing to implementation
---

# Review Requirements with Codex

Delegate a requirements/spec review to Codex (via the `skill-codex:codex` plugin) so a second AI with different training can stress-test the spec against the actual codebase before work begins.

## When to Use

- After writing or updating a GitHub issue with functional/technical sections (see `s-requirements-writing`).
- Before breaking a large task into sub-issues or a plan.
- Anytime the user explicitly asks "have Codex review this" or similar.

## Prerequisites

- The `skill-codex:codex` plugin must be installed (it ships the canonical guidance for current flags, models, and resume syntax).
- `codex` CLI available on `PATH`. Verify with `codex --version`.
- The requirements must exist somewhere concrete to reference (a GitHub issue, a plan file, or inline text the user provides).

## Step 1: Invoke the Codex Plugin Skill

**REQUIRED SUB-SKILL:** Use the `skill-codex:codex` skill (via the Skill tool) to learn the current command flags, model names, and resume syntax. Do not hardcode model names or flags — always re-read the plugin skill at invocation time. The plugin auto-updates when OpenAI renames models or Codex adds flags, so trusting it is safer than trusting any command shape baked into this file.

## Step 2: Load the Requirements

- If reviewing a GitHub issue: `gh issue view <NUMBER> --repo <owner>/<repo>`
- If reviewing a plan file: read the file
- If reviewing inline text: use what the user provided

Capture the full text verbatim — you will paste it into the Codex prompt so Codex doesn't have to guess.

## Step 3: Ask Model and Reasoning Effort

Per the `skill-codex:codex` skill, ask the user (single `AskUserQuestion` with two questions) which model and reasoning effort to use. Recommended defaults for a requirements review:

- **Model:** `gpt-5.3-codex` (standard Codex model)
- **Reasoning:** `high` (thorough analysis without the extra latency of `xhigh`)

## Step 4: Run Codex in Read-Only Mode

Requirements reviews never need write access. Always use `--sandbox read-only`. Let Codex explore the repo from the current working directory so its feedback is grounded in the actual code, not the spec's description of it.

Command shape (adjust flags per the plugin skill's current guidance):

```bash
codex exec --skip-git-repo-check \
  -m <model> \
  --config model_reasoning_effort="<effort>" \
  --sandbox read-only \
  "<review prompt with full spec inline>" 2>/dev/null
```

## Step 5: Craft the Review Prompt

Ask Codex to evaluate the spec along these dimensions:

1. **Correctness and completeness** of the logic and classification rules
2. **Data model design** — are the proposed fields/columns the right shape? Alternatives?
3. **Edge cases not covered** — state transitions, timezones, stale flags, concurrent updates
4. **Impact on existing code** — which files/modules actually need to change, and is that scope captured in the spec?
5. **Migration / backfill strategy** for existing data
6. **Frontend implications** (if applicable) — tab/route/component changes
7. **Anything missing or ambiguous** — open questions the spec fails to answer

Include the **full issue text inline** in the prompt so Codex has the exact wording. Tell Codex it has read-only access to the repo and to reference specific files/lines in its feedback.

Project context to include in the prompt:
- Backend: Django (Python 3.13), Celery, PostgreSQL, Redis
- Frontend: Next.js, TypeScript, Tailwind, Supabase
- Project name: "Pa' Cine" — movie showtime website for Colombia

## Step 6: Summarize for the User

Codex output can be long. Summarize it by severity (Critical / High / Medium / Open questions), grouping related findings. Use clickable markdown links for any file:line references (e.g. `[file.py:42](backend/file.py#L42)`).

## Step 7: Critical Evaluation

Per the `skill-codex:codex` skill's guidance: treat Codex as a peer, not an authority. Flag disagreements where Codex is likely wrong (outdated knowledge, misread of the codebase) and state your reasoning. Let the user decide which feedback to act on.

## Step 8: Offer Follow-Ups

After summarizing, ask the user whether to:

- Update the issue body to incorporate accepted feedback
- Create sub-issues for each major finding or deferred concern
- Resume the Codex session (`echo "..." | codex exec --skip-git-repo-check resume --last 2>/dev/null`) for a follow-up question
- Skip straight to planning with `superpowers:writing-plans`

## Out of Scope

- Implementation changes. Codex runs in `read-only` mode for this skill. If the user wants Codex to make changes, switch to `workspace-write` and use the `skill-codex:codex` skill directly — not this skill.
- Reviewing code diffs or PRs. For code review use `s-pr-review` or `pr-review-toolkit:review-pr`.
