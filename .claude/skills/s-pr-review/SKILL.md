---
name: s-pr-review
description: Use when asked to review a GitHub PR — posts inline comments and a summary directly to the PR using gh CLI
---

<!--
Usage:
claude --remote "Clone https://github.com/gyarra/cine_medallo_2.git, then read .claude/skills/s-pr-review/SKILL.md and review https://github.com/gyarra/cine_medallo_2/pull/209"
-->

# PR Review Instructions

## Output Rules

- ONLY report issues, questions, and observations that need attention
- Do NOT comment on positive changes or things done well
- Do NOT list things that "look good" or "are correct"
- Do NOT end with a positive summary of the PR
- If there are no issues, approve with a one-line summary
- Do NOT run tests, linting, or type checking — these are automated in CI

## Feedback Categories

For each issue: reference `file:line`, explain the problem, suggest a fix.

- :red_circle: **Blocking**: Must fix before merge (bugs, security issues, data loss)
- :yellow_circle: **Important**: Should fix (performance, maintainability, missing error handling)
- :green_circle: **Suggestion**: Nice to have improvements
- :bulb: **Question/Observation**: Clarification needed

## Review Process

### Step 1: Gather Context

Fetch PR metadata, diff, and the list of changed files using `gh`.
If `gh` fails with "none of the git remotes configured for this repository point to a known GitHub host", add `--repo gyarra/cine_medallo_2` to all `gh` commands.

### Step 2: Read project rules

Read `.github/copilot-instructions.md` in full. You will apply these rules systematically in the next steps.

### Step 3: Read every changed file in full

For each file in the PR, read the **entire file** (not just the diff hunks). You need the full context to understand how changes interact with surrounding code — callers, data flow, error handling paths, and existing patterns.

### Step 4: Run the Code Review Checklist

Read `.claude/skills/s-code-review-checklist/SKILL.md` and apply every check to the changed files. Do NOT use the Skill tool — just read the file and use it as a checklist.

Also check project rules from `copilot-instructions.md` against every changed file.

### Step 5: Post all findings to the PR

After completing the full review, post findings using `gh`. Include your name, date, and time in the review title.

Post inline comments on specific lines using the GitHub API:

```bash
COMMIT_SHA=$(gh api repos/gyarra/cine_medallo_2/pulls/<PR_NUMBER> --jq '.head.sha')

# Inline comment on a specific line
gh api -X POST "repos/gyarra/cine_medallo_2/pulls/<PR_NUMBER>/comments" \
  -f body="Comment text here" \
  -f commit_id="$COMMIT_SHA" \
  -f path="path/to/file.py" \
  -F line=42 \
  -f side="RIGHT"
```

Then post the overall review summary:

```bash
gh pr review <PR_NUMBER> --repo gyarra/cine_medallo_2 --comment --body "Review summary here"
```

Submission rules:
- Always use --comment (never --approve or --request-changes) — the GitHub token may belong to the PR author, which causes request-changes to fail after partially posting
- If submission fails, do NOT retry — the comments may have already been posted. Check the PR first before attempting again.

Notes on inline comments:
- `line` is the line number in the **new version** of the file (RIGHT side of the diff)
- `side`: `"RIGHT"` for new/changed lines, `"LEFT"` for removed lines
- The line must be part of the diff hunk — you cannot comment on unchanged lines outside diff hunks
- Use `-F` (not `-f`) for numeric parameters like `line`

**CRITICAL: Post each comment and the summary exactly ONCE. After posting the summary review, STOP immediately. Do not re-read this skill, do not re-run any steps, do not verify your comments by re-posting them. The review is complete.**

### Example Output

```markdown
## Code Review

### :red_circle: Blocking

**backend/movies_app/tasks/scrape_cine_colombia.py:45**
Missing exception handling — `run_async_safely()` not used, will fail in Celery event loop.
Suggested fix: ...

### :yellow_circle: Important

**frontend/src/app/movies/[id]/page.tsx:28**
Supabase query missing `.select()` column specification — over-fetching all columns.

### Summary

1 blocking issue, 1 important issue.
```
