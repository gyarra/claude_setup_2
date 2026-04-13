# CLAUDE.md

You MUST read [.github/copilot-instructions.md](.github/copilot-instructions.md) BEFORE starting any work.

## Project Overview

[PROJECT_DESCRIPTION]

Two main components:
- **backend/** - Django backend (Python 3.13, [ADDITIONAL_BACKEND_DEPS])
- **frontend/** - Next.js frontend (TypeScript, [ADDITIONAL_FRONTEND_DEPS])

## Backend Session Setup (REQUIRED)

**At the start of every new session**, set up or activate the virtual environment:

```bash
cd backend
if [[ ! -f .venv/bin/activate ]]; then ./scripts/setup.sh; fi
source .venv/bin/activate
```

## Backend Pre-Commit Checks (REQUIRED)

**Before committing any backend code**, run all checks from the `backend/` directory:

```bash
cd backend
source .venv/bin/activate
ruff check .
pyright
python manage.py check
python manage.py makemigrations --check --dry-run
pytest
```

## Frontend Pre-Commit Checks (REQUIRED)

**Before committing any frontend code**, run all checks from the `frontend/` directory:

```bash
cd frontend
npm run lint
npx tsc --noEmit
npm run build:local
```

Do NOT commit code that fails any of these checks.

## Memory

Save memories to `.claude/memory/` in the repo. The index file is `.claude/memory/MEMORY.md`.
