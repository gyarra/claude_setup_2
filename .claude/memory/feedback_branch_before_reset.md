---
name: Create feature branch BEFORE resetting main
description: When user asks to move commits off main, create the feature branch first so it captures current HEAD, then reset main
type: feedback
---

When the user says something like "create a feature branch for these changes and reset main to <SHA>", the correct order is:

1. **First**: `git checkout -b feature/<name>` — this captures the current commits including any ahead of <SHA>
2. **Then**: `git checkout main && git reset --hard <SHA>`

**Why:** On 2026-04-07 I did this backwards — reset main first, which orphaned two commits (the commits were still reachable by SHA but not by any branch). Then when I created the feature branch from main's new position, the branch was missing those commits. Recovery required `git reset --hard <orphaned-sha>` on the feature branch, which worked but was risky. The user had to stop me multiple times to prevent losing work.

**How to apply:** Whenever the task involves "moving" or "separating" commits between branches, think through the order of operations before acting. Branch-first, reset-second. If you've already reset, check `git reflog` or remember the SHAs before taking any further destructive action.