# Copilot Code Review Instructions

Review pull requests following the project guidelines below.

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

## Review Checklist

### Hard Rules (Backend - Python/Django)

These are blocking issues if violated:

- **NO inline imports** — All imports at top of file. The only exception is to avoid circular imports.
- **No default values in method parameters**
- **Never swallow exceptions** — Log errors properly, don't use bare `except:` or `except Exception: pass`
- **Use OOP** — Classes, not free functions; composition over inheritance
- **No synchronous calls in async code** — Use a safe async runner instead of `asyncio.run()`, use `sync_to_async` for ORM calls in async code
- **Database changes require migrations** — Never modify schema directly

### Size Limits (Blocking)

Applies to production code (not tests or fixtures). Flag as :red_circle: **Blocking**:

- **Functions over 40 lines** (excluding docstring) → must be decomposed into smaller named functions
- **Classes over 400 lines** → must extract a collaborator class.
- **Constructors with more than 4 injected dependencies** → signals the class is doing too much
- **Nesting depth beyond 3 levels** → flatten with guard clauses and early returns

### Single Responsibility (Blocking)

Flag as :red_circle: **Blocking** any change that violates Single Responsibility. Common patterns to catch:

- **Mixing parsing and persistence** — a method that parses data and also writes to the database. The parser should return a data structure; a separate method or service handles saving.
- **Mixing orchestration and implementation** — an orchestrator method that both sequences steps AND contains the low-level logic itself. Orchestrators should only call other methods.
- **"One more thing" appended to an existing method** — if an existing method does X and the PR adds Y to the bottom of it, Y should be its own method instead.
- **A new responsibility pushed into an already-loaded class** — if the PR adds a new area of responsibility to a class that already has one, the new responsibility should live in a new collaborator class.

### Correctness

- Does the logic actually do what the PR description claims?
- Are there edge cases where the code silently produces wrong results?
- Could transient failures (network, database) cause cached/stored bad state?
- Are there race conditions or stale data issues?

### Structure

**Unnecessary code:**
- Unused functions, dead branches, unused imports, unused state/props/variables
- Experimental scaffolding that can be deleted
- Premature abstractions (generic helpers used once)

**Simplify:**
- Flatten nested conditionals with early returns/guard clauses
- Replace multi-step logic with simpler built-ins
- Over-handled edge cases that don't exist in this app

**Reuse:**
- Repeated blocks across files that should be shared helpers/hooks/utilities
- Copy/pasted logic that could become a small, clearly-named helper

### Code Quality

- No commented-out code
- No debug prints / console logs
- No hardcoded values that should be settings/env/config

### Backend Conventions

- Use `from __future__ import annotations` at top of files
- Use `@dataclass` for DTOs and intermediate data structures
- Wrap multi-step operations in `@transaction.atomic`
- Centralize timezone operations — never call `datetime.datetime.now()` or `datetime.date.today()` directly

### Django Queries (Important)

Flag as :yellow_circle: **Important**:

- **N+1 queries** — a loop over a queryset that accesses a related field without `select_related()` / `prefetch_related()` on the original query. Every `obj.related.x` inside a loop is suspect.
- **Queryset evaluated multiple times** — e.g. `len(qs)` followed by iterating `qs`, or `if qs: for item in qs`. Evaluate once (convert to `list(qs)` or use `.count()` + separate iteration only when needed).
- **Missing `select_related` / `prefetch_related`** on querysets whose results are passed to templates or serializers that will touch related objects.

### Frontend ([FRONTEND_FRAMEWORK]/TypeScript)

- Component responsibilities are clear (render vs fetch vs format)
- `useEffect` dependencies correct (no stale closures)
- Hooks not called unconditionally when their data isn't needed
- Requests canceled/ignored when obsolete (avoid race conditions)
- Loading/error/empty states all exist and are handled
- Removed unused state, props, handlers
- ISR/SSR error handling doesn't cache bad state (prefer throwing over returning empty data)
- Falsy checks don't accidentally treat `0` or `""` as missing
- User-facing text: [USER_LANGUAGE]
- Admin dashboard text: English
- Use slugs for lookups and URLs, not names
- Reusable styles: use shared patterns instead of repeating utility classes

### Frontend Data Flow (Blocking)

Flag as :red_circle: **Blocking**:

- **Public pages must use Server Components** querying the database at render time. A public page that fetches data via `useEffect` + client-side calls should be a Server Component instead.
- **Writes must go through `/api/*` route handlers**, not direct database calls from Client Components. Client Components that insert/update/delete via the database client are a blocking issue — route them through a Route Handler that validates and performs the write server-side.

### Frontend Database Queries (Blocking)

Flag as :red_circle: **Blocking** any frontend database query that:

- Uses a large `.limit(...)` (e.g. `.limit(1000)`, `.limit(10000)`) to pull bulk table data
- Calls `.select(...)` without a narrowly-scoped filter (slug/id/date range)
- Fetches bulk data to compute something in JS that should be a database aggregation
- Performs aggregation, counting, or multi-table joins that should live in the database

**Required fix**: move the logic into a database function (RPC) defined in a Django migration via `migrations.RunSQL()`, and call it from the frontend. The function must return the already-shaped, minimal result.

### Testing Requirements

- New features require success AND failure tests
- Use pytest fixtures from `conftest.py`, not `Model.objects.create()`

## What NOT to Comment On

- Style preferences already handled by linters (ruff, eslint)
- Things that "look good" or "are correct"
- Positive observations about the code
- Formatting issues (handled by automated tools)

If the PR has no issues, approve with a brief summary.
