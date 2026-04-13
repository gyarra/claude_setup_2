---
name: s-end-session
description: Use when ending a session or wrapping up work — saves memories, updates issues, and summarizes progress
---

# End Session

Run this checklist before ending a session to avoid lost work and preserve context.

## Step 1: Save Memories

Review the session for anything worth remembering in future conversations. Check each category:

- **User preferences**: Did the user correct your approach or confirm a non-obvious choice?
- **Project context**: Were any decisions made about architecture, priorities, or deadlines?
- **References**: Were any external resources mentioned (dashboards, docs, channels)?

Save relevant memories to `.claude/memory/` in the repo (not the per-user auto-memory path) so they are shared across all environments — local, Docker, and cloud. The index file is `.claude/memory/MEMORY.md`. Do NOT save things that are already in CLAUDE.md, derivable from code, or only useful within this session.

If nothing is worth saving, say so — don't force memories.

## Step 2: Update GitHub Issues

If the session worked on a specific GitHub issue:

```bash
gh issue comment <ISSUE_NUMBER> --repo gyarra/cine_medallo_2 --body "Progress update: <what was done>. Remaining: <what's left>."
```

Skip this step if no issue was being tracked, or if the work was fully completed and the issue will be closed via PR.

## Step 3: Session Summary

Present a brief summary to the user:

```
Session summary:
- Accomplished: <what was done>
- Remaining: <what's left, if anything>
- Branch: <current branch name>
- Git state: <clean / N uncommitted files / N unpushed commits>
```