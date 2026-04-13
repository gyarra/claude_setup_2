# Backend CLAUDE.md

## Session Setup

```bash
cd backend
if [[ ! -f .venv/bin/activate ]]; then ./scripts/setup.sh; fi
source .venv/bin/activate
```

## Pre-Commit Checks

```bash
ruff check .
pyright
python manage.py check
python manage.py makemigrations --check --dry-run
pytest
```

## Key Directories

- `config/` — Django project settings (`settings.py`, `settings_test.py`)
- `[APP_NAME]/models/` — Database models
- `[APP_NAME]/services/` — Business logic services
- `[APP_NAME]/tasks/` — Background tasks (Celery)
- `[APP_NAME]/management/commands/` — Management commands
- `[APP_NAME]/utils/` — Utility functions
- `scripts/` — Setup and utility scripts

## Testing

- Run tests with `pytest -v <file> -k <name>` (NOT `python -m pytest`)
- Tests use `settings_test.py`, not `settings.py`
- Fixtures in `conftest.py` — use fixtures, not `Model.objects.create()`
