---
name: s-code-review-checklist
description: Use when reviewing code for quality — shared checklist covering structure, correctness, async safety, Django, React/Next.js patterns
---

# Code Review Checklist

## Structure

**Remove unnecessary code:**
- Unused functions, dead branches, unused imports, unused state/props/variables
- Experimental scaffolding that can be deleted
- Premature abstractions (generic helpers used once)

**Simplify:**
- Flatten nested conditionals with early returns/guard clauses
- Replace multi-step logic with simpler built-ins
- Reduce moving parts without losing clarity
- Remove over-handled edge cases that don't exist in this app
- Check for built-in functions that replace hand-written code

**Small, focused units:**
- Functions over 40 lines → extract smaller functions
- Classes over 400 lines → extract smaller classes
- Each class with behavior in a separate file

**Reuse:**
- Repeated blocks across files → shared helpers/hooks/utilities
- Copy/pasted logic → small, clearly-named, domain-local helper
- Rule of thumb: reuse if repeated 2+ times AND non-trivial

## Correctness

- Walk through code paths — does the logic do what it claims?
- Edge cases that silently produce wrong results?
- Transient failures causing cached/stored bad state?
- Race conditions or stale data?

## Code Quality

- No commented-out code
- No debug prints / console logs
- No hardcoded values that should be settings/env/config
- Exceptions logged with context, not leaking secrets/PII
- New/changed behavior has tests (happy path + failure/edge case)
- No inline imports (all at top of file, except circular import avoidance)

## Async Safety

**Never use `asyncio.run()` directly** — use a helper that checks for existing event loops. `asyncio.run()` fails when called from an already-running event loop (Celery tasks, async tests).

**Sync calls inside `async def`:**
In `async def` methods, any sync I/O raises `SynchronousOnlyOperation`. Check for:
- Direct ORM calls: `Model.objects.create()`, `.save()`, `.filter()`, `.get()`, `.update()`, `.delete()`
- Sync helper methods that internally do DB work
- Any sync network/file I/O

Fix with `sync_to_async`:
```python
from asgiref.sync import sync_to_async

await sync_to_async(MyModel.objects.create)(
    name="Example", field="value"
)
```

## Django-Specific

**Queries:**
- No N+1 queries — use `select_related` / `prefetch_related` for related objects
- Don't evaluate querysets multiple times (`len(qs)` then iterate)

**Transactions:**
- Multi-step writes use `transaction.atomic`
- No external side-effects (network calls, Celery tasks) mid-transaction

**Migrations:**
- Model changes include migration files
- No direct database modifications outside migrations (functions, triggers, RLS → `migrations.RunSQL()`)

## Frontend (React/Next.js)

**Components:** Clear responsibilities (render vs fetch vs format). Shared patterns as components, shared data logic as hooks/helpers.

**State & effects:**
- `useEffect` dependencies correct (no stale closures)
- Hooks not called unconditionally when their data isn't needed
- Requests canceled/ignored when obsolete
- Loading/error/empty states handled

**Data flow:**
- Public pages use Server Components querying the database at render time
- Client Components call `/api/*` route handlers for write operations
- ISR/SSR error handling doesn't cache bad state (prefer throwing over returning empty data)
- Falsy checks don't treat `0` or `""` as missing

**Database query patterns (Must fix):**
- No bulk/unbounded frontend reads — flag any query without a narrow filter or with a large `.limit(...)`
- No "fetch all rows then aggregate in JS" — aggregation, counting, and multi-table joins must live in the database
- Push aggregation into stored procedures / RPCs called from the frontend

**Clean up:** Remove unused state/props/handlers. Simplify conditional rendering. Reuse formatting logic (dates, currency, labeling).

## Testing & Checks

- Run ALL checks for the ENTIRE application (both backend and frontend), not just the parts you changed
- ALL tests and checks must pass — fix every failure, even if it appears pre-existing
- Do NOT push a PR with any failing tests, lint errors, or type errors, even if the problem was created before work on this PR

## Issue Severity

- **Must fix**: correctness, security, async/sync issues, failing tests
- **Should fix**: maintainability, performance, repeated code, readability
- **Nice to have**: minor cleanup, naming tweaks