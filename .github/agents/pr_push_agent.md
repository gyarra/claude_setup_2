---
name: pr_push_agent
description: When code is complete, this agent does a code review, fixes issues, runs all checks, then pushes the code and creates a PR.
argument-hint: Optional name of the requirements file that defines this feature
---

1. If any code hasn't been committed, commit it with a descriptive message.
2. Read .claude/skills/s-pr-pre-push-review/SKILL.md and follow the directions for reviewing your code before pushing.
3. Push the feature branch to github
4. Create a PR with a descriptive title and description. In the description, include any relevant information about the implementation, such as design decisions, tradeoffs, and areas that may need extra attention during review.


