---
name: s-pr-respond-to-feedback
description: Use when a PR has review comments to address — reads comments, posts numbered responses on GitHub, then waits for the user to specify which to fix
---

# Responding to PR Feedback

**REQUIRED BACKGROUND:** Use `superpowers:receiving-code-review` for guidance on processing feedback with technical rigor.

When asked to respond to PR feedback:

## Step 1: Read the PR Feedback

1. Get the PR number from the user (or infer from the current branch)
2. Fetch **both** inline comments and review summaries — feedback can appear in either:

```bash
# Get PR inline comments (review comments on specific lines)
# --paginate fetches all pages (default is 30 per page). Without it, comments beyond 30 are silently missed.
gh api repos/gyarra/cine_medallo_2/pulls/<PR_NUMBER>/comments --paginate --jq '.[] | {id: .id, path: .path, line: .line, body: .body, user: .user.login}'

# Get PR review summaries — these often contain substantive feedback items
# (e.g., a code review posted as a review body rather than inline comments).
# Filter to reviews with non-empty bodies.
gh api repos/gyarra/cine_medallo_2/pulls/<PR_NUMBER>/reviews --paginate --jq '.[] | select(.body != "") | {id: .id, body: .body, state: .state, user: .user.login}'
```

3. **Process both sources as feedback items.** Review summaries with substantive feedback (bullet points, specific issues, suggestions) should be numbered and responded to just like inline comments. Skip review bodies that are only automated summaries (e.g., Copilot's "Pull request overview" or Codex's "ℹ️ About Codex in GitHub").
4. Read each file referenced in the comments to understand the full context

## Step 2: Post Numbered Responses to Each Comment

For each comment, write a reply directly on the PR comment. Number every reply sequentially starting from 1.

### Response Format

Each reply must:
- Start with a sequential number (e.g., `**#1**`, `**#2**`)
- State whether you agree or disagree
- If you **agree**: briefly acknowledge and state the intended fix
- If you **disagree**: explain why with technical reasoning (reference code, constraints, or trade-offs)

### Posting Replies

Reply to inline review comments using the GitHub API:

```bash
# Reply to a specific review comment thread
gh api -X POST "repos/gyarra/cine_medallo_2/pulls/<PR_NUMBER>/comments/<COMMENT_ID>/replies" \
  -f body="**#1** — Agree. Will move the import to top of file."
```

For general review feedback (not tied to a specific line), post a PR comment:

```bash
gh pr comment <PR_NUMBER> --repo gyarra/cine_medallo_2 --body "Response text here"
```

### Example Replies

Agreeing:
```
**#1** — Agree. The exception handling is missing here and could crash on None. Will add a guard clause.
```

Disagreeing:
```
**#2** — Disagree. This inline import is intentional to avoid a circular dependency between `models/__init__.py` and `services/`. Moving it to the top causes an ImportError at startup.
```

## Step 3: Present Summary and Wait for User

After posting all responses, present a summary to the user in this format:

```
Posted replies to N comments on PR #<NUMBER>:

#1 — [file:line] Agree — missing exception handling
#2 — [file:line] Disagree — intentional inline import (circular dep)
#3 — [file:line] Agree — rename variable for clarity
...

Which should I fix? (e.g., "fix 1 and 3", "fix all", "skip 2")
```

**STOP. Wait for the user to respond.**

## Step 4: Implement the Fixes

Once the user specifies which items to fix:

1. Implement only the fixes the user approved (by number)
2. After each fix, run the relevant checks:
   ```bash
   # Backend
   cd backend && source .venv/bin/activate && ruff check . && pyright
   ```
   ```bash
   # Frontend
   cd frontend && npm run lint && npx tsc --noEmit
   ```
3. After all fixes are applied, run the full test suite for affected areas
4. Commit the changes with a message referencing the PR and item numbers (e.g., `Address PR #<NUMBER> feedback: items #1, #3`)
5. Push the branch: `git push`

## Step 5: Check for New Feedback

After pushing, check whether new comments or reviews have arrived:

```bash
# Check inline comments
gh api repos/gyarra/cine_medallo_2/pulls/<PR_NUMBER>/comments --paginate --jq '[.[] | select(.created_at > "<timestamp-of-last-check>")] | length'

# Check review summaries (may contain new feedback in the body)
gh api repos/gyarra/cine_medallo_2/pulls/<PR_NUMBER>/reviews --paginate --jq '[.[] | select(.submitted_at > "<timestamp-of-last-check>" and .body != "")] | length'
```

If new comments or reviews exist, return to Step 1 and run another round.
