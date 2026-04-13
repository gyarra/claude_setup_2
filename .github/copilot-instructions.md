# Copilot Instructions

## Project Overview

[PROJECT_DESCRIPTION]

## Architecture

```
[PROJECT_NAME]/
├── .github/             # Copilot instructions and GitHub config
├── backend/             # [BACKEND_FRAMEWORK] backend ([BACKEND_LANGUAGE])
│   ├── config/          # Project settings
│   ├── [APP_NAME]/      # Core app
│   │   ├── models/      # [MODEL_EXAMPLE_1], [MODEL_EXAMPLE_2], [ERROR_MODEL], etc.
│   │   ├── services/    # [SERVICE_EXAMPLE_1], [SERVICE_EXAMPLE_2]
│   │   ├── tasks/       # Background tasks
│   │   ├── management/  # Management commands
│   │   └── utils/       #
│   ├── scripts/         # Setup and utility scripts
│   └── seed_data/       # Seed data files
├── frontend/            # [FRONTEND_FRAMEWORK] frontend ([FRONTEND_LANGUAGE])
│   ├── src/app/         # App Router pages and API routes
│   │   ├── admin/       # Admin dashboard pages
│   │   ├── api/         # API routes (Route Handlers)
│   │   └── layout.tsx   # Root layout
│   ├── src/components/
│   └── src/lib/         # [DATABASE_CLIENT] client, type definitions
└── docs/                # Requirements and documentation
```

### Architecture Notes

* The backend does not expose an API. The frontend accesses the database directly via [DATABASE_CLIENT].
- Admin dashboard is in frontend code (not backend admin)

---

# Git and workflow guidelines

- Create feature branches from `main` for new work (e.g., `git checkout -b feature/my-new-feature`).
    - Do not work directly on `main`.
    - Feature branches should start with `feature/` prefix.
- Do not commit until the user tells you to commit code.
- Never push to github unless the user explicitly tells you to push.
- When fixing PR feedback, always create a new commit rather than amending or squashing. This preserves the history of changes and feedback.
- Communicate with the user about design decisions and trade-offs before implementation.
- Communicate with the user about requirements decisions before implementation and after implementation.


## Copilot-instructions updates
Update this file when:
- You discover a solution that future agents would also get stuck on
- You find incorrect information that needs correction


---


# Frontend ([FRONTEND_FRAMEWORK])

## Tech Stack
- **Framework**: [FRONTEND_FRAMEWORK]
- **Styling**: [CSS_FRAMEWORK]
- **Database**: [DATABASE_CLIENT] ([DATABASE_TYPE])
- **UI Components**: [UI_COMPONENT_LIBRARY]


## Before Committing


Always run these before committing and fix any issues:
```bash
cd frontend
[FRONTEND_LINT_COMMAND]
[FRONTEND_TYPECHECK_COMMAND]
[FRONTEND_BUILD_COMMAND]
```

## Key Files
- `src/lib/[DATABASE_CLIENT_FILE]` - Database client and type definitions


## Conventions
- User-facing text: [USER_LANGUAGE]
- Admin dashboard: English
- Use slugs for lookups and URLs (e.g., `/items/my-item-slug`), not names
- Timestamps use [TIMEZONE] context
- Reusable styles: use `@apply` in CSS instead of repeating utility classes

---

# Backend ([BACKEND_FRAMEWORK])

## Tech Stack
[BACKEND_FRAMEWORK] · [TASK_QUEUE] · [DATABASE_CLIENT] ([DATABASE_TYPE]) · [CACHE_BACKEND] · [BACKEND_LANGUAGE]

## Essential Commands
```bash
cd backend
./scripts/setup.sh   # First-time setup
source .venv/bin/activate
[BACKEND_LINT_COMMAND]
[BACKEND_TYPECHECK_COMMAND]
[BACKEND_TEST_COMMAND]
```

## Hard Rules

* Clear, high quality code is more important than speed of implementation. Take the time to do it right.
* Use OOP—classes, not free functions; composition over inheritance
* No default values in method parameters
* Never swallow exceptions—log errors properly
* **NO inline imports**—all imports at top of file. The only exception is to avoid circular imports.
* Avoid synchronous calls in asynchronous code (use await for all I/O operations)
* Run pre-commit checks (see Testing section) before committing
* Generate migrations before pushing a PR
* If blocked, ask user—don't claim work complete when blocked

## Code Architecture

### Size Limits

These limits apply to production code (not test fixtures or data).

* **Functions: 40 lines max** (excluding docstring). If a function exceeds this, decompose it into smaller functions with clear names.
* **Classes: 400 lines max.** If a class exceeds this, extract a collaborator class that handles a distinct responsibility. Excluded from the class size limit: management commands (`commands/`) and task classes (`tasks/`). These classes are inherently large due to domain-specific logic, but their individual methods must still respect the function size limit.
* **Constructor dependencies: 4 max.** More than 4 injected dependencies signals the class is doing too much.
* **Nesting depth: 3 levels max.** Use guard clauses and early returns to flatten conditional logic.

When adding new logic, check whether the target function or class is already near its limit. If it is, extract first, then add.

### Single Responsibility

Every class and function should have one reason to change. Common violations to avoid:

* **Don't mix parsing and persistence.** A method that parses data should return a data structure. A separate method or service should handle saving to the database.
* **Don't mix orchestration and implementation.** An orchestrator method calls other methods in sequence. It should not contain the low-level logic itself.
* **Don't add "one more thing" to an existing method.** If a method does X and you need to also do Y, extract Y into its own method. Do not append Y to the bottom of the X method.

### Dependency Management

* **Inject dependencies through the constructor**, not by importing and instantiating them inside methods. This makes classes testable and their dependencies explicit.
* **Depend on the narrowest interface you need.** If a method only needs a specific service, accept that service, not the entire orchestrator.
* **Keep the dependency graph shallow.** If class A depends on B depends on C depends on D, consider whether A should depend on C or D directly instead of reaching through B.

### When Modifying Existing Code

Before adding code to an existing function or class, ask:

1. **Does this belong here?** If the new logic serves a different purpose than the existing code, it belongs in a new function or class.
2. **Will this push the function/class over its size limit?** If yes, extract existing logic first to make room.
3. **Am I increasing this class's number of responsibilities?** If yes, extract a new collaborator class instead.

## Typing Conventions

* Use `from __future__ import annotations` at top of files
* Use `TYPE_CHECKING` block to avoid circular imports:
  ```python
  from typing import TYPE_CHECKING
  if TYPE_CHECKING:
      from [APP_NAME].services.[SERVICE_NAME] import [SERVICE_CLASS]
  ```
* Use `@dataclass` for DTOs and intermediate data structures
* Return type hints should be included in all functions, even if the return type is None

## Comments and Docstrings

* Short methods under 10 lines should not need a docstring
* Medium length methods (10 to 50 lines) should have a docstring describing the overall purpose and any non-obvious behavior
* Long methods (>50 lines) must be decomposed into smaller methods (see Size Limits above). If decomposition is genuinely not possible, they must have a docstring and inline comments explaining the logic
* Write additional comments only for non-obvious behavior or important constraints
* Do not describe what the code does; describe why if unclear
* Logger statements ending in "\n\n" are fine to keep log separation clear
* Python classes with functions should have docstrings of 5 to 20 lines describing their purpose and any important details about usage or behavior
* Return type should be commented


## Async/Sync Best Practices

Some tasks use async code for browser automation or I/O. Follow these rules to avoid runtime errors:

### Use `run_async_safely()` Instead of `asyncio.run()`

**NEVER** use `asyncio.run()` directly. It fails when called from an already-running event loop:
```python
# BAD - will fail with "RuntimeError: This event loop is already running"
def download_page(url: str) -> str:
    return asyncio.run(_fetch_page_async(url))

# GOOD - handles both sync and async contexts
from [APP_NAME].utils import run_async_safely

def download_page(url: str) -> str:
    return run_async_safely(_fetch_page_async(url))
```

### Why This Matters

- Task queue workers may run in contexts with existing event loops
- Async tests use `@pytest.mark.asyncio` which creates an event loop
- `run_async_safely()` uses `asyncio.run()` when no loop is running, or runs the coroutine in a separate thread with its own event loop when one already exists

### Testing Async Code

Add async safety tests to catch `asyncio.run()` usage. Example test pattern:
```python
@pytest.mark.django_db
class TestAsyncSyncSafety:
    async def test_download_can_be_called_from_async_context(self):
        """Catches asyncio.run() bug - would fail with 'event loop already running'."""
        from unittest.mock import patch, AsyncMock

        with patch.object(
            MyClass,
            "_async_method",
            new_callable=AsyncMock,
            return_value="<html></html>",
        ):
            # This should NOT raise RuntimeError
            result = MyClass.download_method("https://example.com")
            assert result == "<html></html>"
```

### Django ORM in Async Context

When calling Django ORM operations from async functions, use `sync_to_async`:
```python
from asgiref.sync import sync_to_async

# Inside an async function:
await sync_to_async([ERROR_MODEL].objects.create)(
    name="Issue Name",
    task=TASK_NAME,
    error_message=str(e),
)
```

## Management Commands

Located in `[APP_NAME]/management/commands/`:
- **Include verbose docstrings** with usage examples at the top of command files

---

## Testing

Pre-commit checks:
```bash
[BACKEND_LINT_COMMAND]
[BACKEND_TYPECHECK_COMMAND]
[BACKEND_MANAGE_CHECK_COMMAND]
[BACKEND_MIGRATION_CHECK_COMMAND]
[BACKEND_TEST_COMMAND]
```

* Use pytest fixtures from `conftest.py`—not `Model.objects.create()`
* Run tests with `pytest -v <file> -k <name>` (NOT `python -m pytest`)
* Run the associated management command to manually verify before completing work
* New features require success and failure tests
* Write integration tests in addition to unit tests for complex logic
* Tests use settings_test.py, not the standard settings.py

## Error Handling

* Fail fast—only catch exceptions if recovery is possible
* Let unexpected exceptions propagate (don't silently handle)
* Only check for None if it's expected; crash on unexpected None
* Always log when catching exceptions
* Log operational issues to `[ERROR_MODEL]` model:
  ```python
  [ERROR_MODEL].objects.create(
      name="Descriptive Name",
      task=TASK_NAME,
      error_message=str(e),
      traceback=traceback.format_exc(),
      context={"key": "value"},
      severity=[ERROR_MODEL].Severity.ERROR,  # or WARNING, INFO
  )
  ```

---

# Database

* Use `select_related()` and `prefetch_related()`
* Wrap multi-step operations in `@transaction.atomic`
* All timestamps stored as timezone-aware datetimes (UTC)
* Use underscore_case for table names (e.g., `[APP_NAME]_[TABLE_NAME]`, not `[APP_NAME]_[tablename]`)
* [TIMEZONE]: Use `TimeService` from `[APP_NAME].services.time_service` — never call `datetime.datetime.now()` or `datetime.date.today()` directly for local time. Use `TimeService.get_local_date()`, `TimeService.get_local_now()`, etc. In tests, mock `TimeService.get_local_now()` or `TimeService.get_local_date()` instead of patching `datetime`.

### Key Database Tables
- `[APP_NAME]_[TABLE_1]` - [TABLE_1_DESCRIPTION]
- `[APP_NAME]_[TABLE_2]` - [TABLE_2_DESCRIPTION]
- `[APP_NAME]_[TABLE_3]` - [TABLE_3_DESCRIPTION]

### Frontend Database Access ([DATABASE_CLIENT])

The frontend talks to [DATABASE_CLIENT] directly. Query patterns matter because every row crosses the network to the user's browser (or to a serverless function) on every request.

* **Never fetch unbounded or bulk table data from the frontend.** Do not write queries like `.select("*").limit(10000)` or `.select(...)` without a narrowly-scoped filter. There is no legitimate frontend use case for fetching all rows.
* **Push aggregation and bulk reads into the database.** If a page needs data derived from many rows (sitemaps, counts, summaries, joins across large tables), write a database function (RPC) in a migration and call it from the frontend. The function should return the already-shaped, minimal result.
* **Always filter by a bounded key** (slug, id, date range, category) when querying. Pagination/limits are a safety net, not a substitute for filters.

### Migrations

* **Never modify the database directly**—all changes must be in a migration
* This includes adding functions, triggers, RLS policies, or any schema changes
* All migrations live in the backend directory (`backend/[APP_NAME]/migrations/`)
* Do not add migrations in frontend code
* Generate model migrations with the appropriate migration command
* For raw SQL (functions, RLS), use raw SQL migrations

---

# Admin Dashboard (Frontend)

Located at `/admin` in the frontend (not backend admin).

* Focus on functionality, not styling
* Text in English

## Security Model

* Authentication uses [AUTH_PROVIDER]
* Authorization checks the `admin_users` table to verify if a user is an admin
* Row Level Security (RLS) is **disabled** on admin-facing tables
* The frontend uses the [DATABASE_CLIENT] anon key, but admin pages check session + admin status before rendering
* For local development, set `NEXT_PUBLIC_DISABLE_ADMIN_AUTH=true` to bypass auth checks

## Adding New Admin Pages

1. Create the page directory in `frontend/src/app/admin/<page-name>/` with a `page.tsx`
2. The admin `layout.tsx` provides consistent styling and auth protection
3. **Add a link in the sidebar**: Edit `frontend/src/components/AdminSidebar.tsx` and add to `navItems` array
4. Optionally add a card on the dashboard index page (`frontend/src/app/admin/page.tsx`)

---

# MCP Tools

MCP (Model Context Protocol) tools are available for enhanced development assistance.

## Available Tools

* **[DATABASE_CLIENT] MCP** - Database queries, schema inspection, migrations
* **Sentry MCP** - Error tracking, issue analysis
* **Playwright CLI** - Browser driver for frontend verification
* **Chrome DevTools MCP** - Performance (Lighthouse, Core Web Vitals), accessibility audits, and network inspection

## Usage Guidelines

* Use [DATABASE_CLIENT] MCP for exploring database schema and running read queries
* Do not use MCP tools to directly modify production data—use migrations instead
* Sentry MCP is useful for investigating production errors and their context

---

# Additional information

## Command Line Conventions

Run commands separately (not with `&&`). Combined commands fail auto-allow:
**NOT CORRECT:**
```bash
source .venv/bin/activate && pytest [APP_NAME]/tests/test_models.py
```

**CORRECT:**
```bash
source .venv/bin/activate
pytest [APP_NAME]/tests/test_models.py
```

## Documentation

Do not add large amounts of code to files under /docs when you can point to a file to emulate.


## Platform

* No external customers. Internal tool—no backwards compatibility concerns. Delete deprecated code immediately.
* Development on **[DEVELOPMENT_OS]**
* Backend code runs on [PRODUCTION_BACKEND_PLATFORM] in production
* Frontend code runs in [PRODUCTION_FRONTEND_PLATFORM] in production
