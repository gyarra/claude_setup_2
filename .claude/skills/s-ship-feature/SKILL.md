---
name: s-ship-feature
description: Use when starting work on a feature and wanting to take it all the way to a merged PR — orchestrates implementation through review rounds
---

# Ship Feature — Full Development Lifecycle

Orchestrates the complete feature development cycle. Each step invokes a dedicated skill. Follow the steps in order. Do not skip steps.

**At the very start, output this state tracker and update it (checking boxes) as each step completes:**

```
SHIP FEATURE STATE
[ ] Step 1: Plan
[ ] Step 2: Implement
[ ] Step 3: Frontend Visual Review
[ ] Step 4: Pre-Push Review
[ ] Step 5: Push + PR
[ ] Step 6: Remote Review
[ ] Step 7: PR Feedback
[ ] Step 8: Report
```

## Step 1: Plan the Feature

1.1 Invoke the `s-plan-feature` skill (requirements, clarification, implementation plan).
1.2 Output the gate check:

```
STEP 1 GATE CHECK
[ ] GitHub issue read and requirements clarified with user
[ ] Implementation plan posted to the issue and approved by user
Proceeding to Step 2: YES/NO
```

**Do not proceed until all boxes are checked and the answer is YES.**

## Step 2: Implement the Plan

2.1 Invoke the `s-implement-plan` skill (coding, testing, verification).
2.2 Output the gate check:

```
STEP 2 GATE CHECK
[ ] Implementation plan tasks are all complete
[ ] All backend checks pass (ruff, pyright, manage.py check, migrations, pytest)
[ ] All frontend checks pass (lint, tsc, build) — or no frontend code changed
Proceeding to Step 3: YES/NO
```

**Do not proceed until all boxes are checked and the answer is YES.**

## Step 3: Frontend Visual Review

3.1 Run `git diff --name-only HEAD~1` and list every changed file.
3.2 Check if any path starts with `frontend/` — output YES or NO.
3.3 If YES: invoke `s-run-dev-servers` (if servers aren't running), then invoke `s-frontend-visual-review`. If NO: skip to 3.4.
3.4 Output: `STEP 3 COMPLETE — frontend review: [done|skipped (no frontend files)]`

**Do not output the Step 3 completion marker until 3.1–3.3 are done.**

**Required if ANY file under `frontend/` was created or modified.** This includes CSS, config, components, pages, layouts, and dependencies. There are no exceptions for "small" or "trivial" changes.

Then output the gate check:

```
STEP 3 GATE CHECK
[ ] Listed all changed files from git diff
[ ] Determined whether frontend/ files changed: YES/NO
[ ] If YES: visual review complete with no console errors, broken layouts, or failing interactions
Proceeding to Step 4: YES/NO
```

**Do not proceed until all boxes are checked and the answer is YES.**

## Step 4: Pre-Push Self-Review

4.1 Invoke the `s-pr-pre-push-review` skill.
4.2 Wait for the self-review to complete — all findings must be resolved and all checks must pass.
4.3 Output: `STEP 4 COMPLETE — self-review passed, all checks green`

**Do not output the Step 4 completion marker until 4.1–4.2 are done.**

Then output the gate check:

```
STEP 4 GATE CHECK
[ ] s-pr-pre-push-review skill was invoked and completed
[ ] All code review findings are resolved
[ ] Documentation updated (if applicable)
[ ] Final check run passed with zero failures
Proceeding to Step 5: YES/NO
```

**Do not proceed until all boxes are checked and the answer is YES.**

## Step 5: Push and Create the PR

```bash
git push -u origin HEAD
gh pr create --title "<feature title>" --body "<summary>"
```

Copy the PR URL — you'll need it in the next step.

## Step 6: Launch Remote Code Review

Start a remote Claude session to review the PR:

```bash
claude --remote "Clone https://github.com/gyarra/cine_medallo_2.git, then read .claude/skills/s-pr-review/SKILL.md and review PR: <PR_URL>"
```

Then wait **5 minutes** for automated reviewers to finish posting their comments before moving to the next step.

## Step 7: Respond to PR Feedback (up to 3 rounds)

Invoke the `s-pr-respond-to-feedback` skill with the PR number.

This covers: reading all review comments, posting numbered agree/disagree responses, waiting for user approval of which items to fix, implementing fixes, running checks, and pushing the updated branch.

**Repeat this step for each new round of feedback. Stop after 3 rounds total, even if feedback remains.**

Never merge your own PR.

## Step 8: Completion Report

After all steps are done, present a summary report to the user:

```markdown
## Ship Feature Report: [Feature Name]

### Step 1: Planning
- GitHub issue: #<number>
- Requirements clarified: list
- Implementation plan approved: yes/no

### Step 2: Implementation
- Files created: list
- Files modified: list
- Tests added: count and brief description

### Step 3: Frontend Visual Review
- Pages reviewed: list of URLs (or "N/A — no files under frontend/ changed")
- Issues found and fixed: list (or "None")

### Step 4: Pre-Push Self-Review
- Code review findings fixed: list (or "None")
- Documentation updated: list of files (or "None")

### Step 5: PR
- PR: #<number> — <URL>
- Commits: count

### Step 6: Remote Code Review
- Reviewer comments received: count

### Step 7: PR Feedback
- Rounds completed: N
- Items fixed: list by number
- Items declined: list by number (with reason)
- Remaining: list (if stopped at 3 rounds)
```

---

## Quick Reference

| Step | Skill | Blocks on |
|------|-------|-----------|
| 1 | `s-plan-feature` | Plan approved by user |
| 2 | `s-implement-plan` | All checks pass, plan complete |
| 3 | `s-frontend-visual-review` | No console errors or broken UI |
| 4 | `s-pr-pre-push-review` | All checks pass, docs updated |
| 5 | Push + PR | — |
| 6 | Remote review + wait | 5 min for automated reviewers |
| 7 | `s-pr-respond-to-feedback` | User approves items; max 3 rounds |
| 8 | Completion report | — |
