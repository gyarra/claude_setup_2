---
name: s-pr-pre-push-review
description: Use when about to push code, create a PR, or when asked to self-review changes before submitting
---

# Pre-Push Self-Review

Review your own changes and fix issues before submitting. Also clean up preexisting problems in files you touched.

## Step 1: Identify What to Review

Review all commits on the current feature branch since `main`:
```bash
git log main..HEAD --oneline
git diff main...HEAD --name-only
```
Read every changed file in full — not just the diff hunks.

## Step 2: Refactor

If backend Python files were changed, invoke the `s-python-refactor` skill on each changed file to identify and fix SRP violations, deduplication opportunities, and Pythonic improvements.

## Step 3: Run the Code Review Checklist

Read `.claude/skills/s-code-review-checklist/SKILL.md` and apply every check to the changed files.

## Step 4: Documentation

Invoke the `s-update-documentation` skill in post-work mode to update any documentation affected by your changes.

## Step 5: Final Verification

```bash
# Backend
cd backend
source .venv/bin/activate
ruff check .
pyright
python manage.py check
python manage.py makemigrations --check --dry-run
pytest
```

```bash
# Frontend
cd frontend
npm run lint
npx tsc --noEmit
npm run build:local
```

- Run ALL checks for the ENTIRE application (both backend and frontend), not just the parts you changed
- ALL tests and checks must pass — fix every failure, even if it appears pre-existing
- Do NOT push a PR with any failing tests, lint errors, or type errors
- No secrets in code or config

## Step 6: Commit and Create PR

Once all checks pass:

1. **If on main, create a feature branch first:**
```bash
git checkout -b feature/<descriptive-name>
```

2. **Stage only your own changes.** The user may have made changes to other files — do not stage or commit those. Use `git diff --name-only` to review all modified files. Stage files individually by name:
```bash
git add <file1> <file2> ...
```

3. **Commit and push:**
```bash
git commit -m "<clear commit message>"
git push -u origin HEAD
```

4. **Create a PR** if one doesn't exist yet:
```bash
gh pr create --title "<feature title>" --body "<summary of changes>"
```

5. **Clean up** generated files that shouldn't exist: `django.log`, `django_errors.log`.
