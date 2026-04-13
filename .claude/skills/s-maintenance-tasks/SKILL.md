---
name: s-maintenance-tasks
description: Use when doing periodic codebase maintenance — dependency cleanup, dead code removal, test coverage gaps, security audits, performance optimization, or logging review
---

# Code Audit Tasks

Periodic maintenance tasks for keeping the Pa' Cine codebase healthy. Each section has a specific prompt that can be given to Claude for execution.

When changing code in response to PR feedback, always make a new commit.

---

## Dependency Management

### A. Remove Unused Dependencies

**Backend (Python):**
```
Review backend/pyproject.toml dependencies and all Python files (excluding .venv). For each package, check:
1. Direct imports (import X, from X import Y)
2. Usage in settings.py or INSTALLED_APPS/MIDDLEWARE
3. Indirect usage by other packages (transitive deps that don't need explicit listing)

Common import name mismatches:
- beautifulsoup4 → bs4
- dj-database-url → dj_database_url
- django-cors-headers → corsheaders (in INSTALLED_APPS)
- python-dotenv → dotenv
- sentry-sdk → sentry_sdk
- logtail-python → logtail
- camoufox → camoufox.async_api (also check AsyncCamoufox usage)

Also check indirect usage (e.g., redis is required by celery as broker; amqp and python-dateutil are transitive deps of celery that don't need explicit listing).

Remove unused dependencies from pyproject.toml. Run `uv lock` then `uv sync`, then run pytest to verify.

If copilot-instructions.md references removed packages in the tech stack, update it too.
```

**Frontend (Node.js):**
```
Review frontend/package.json dependencies and devDependencies. For each package, search frontend/src/ and config files for imports. Pay attention to:
1. Do NOT remove shadcn UI components or their backing packages (Radix UI, react-day-picker, etc.) even if currently unused — they are kept for future use. Also check peer dependencies (e.g., react-day-picker requires date-fns).
2. Config-only packages (postcss, tailwindcss, eslint-config-next) won't appear in import searches
3. Packages used only in scripts or config
4. Starter template packages that were never used (e.g., stripe, framer-motion)

Remove unused packages with npm uninstall, then verify with npx tsc --noEmit and npm run build:local.
```

### B. Check for Outdated Dependencies with Security Issues

```
Backend:
- Install pip-audit if needed: uv pip install pip-audit
- Run: pip-audit
- Fix: uv lock --upgrade-package <package-name>, then uv sync

Frontend:
- Run: npm audit
- Fix: npm audit fix (handles most cases automatically)

After fixes, re-run the audit tool to verify 0 vulnerabilities remain.
```

### C. Check for Deprecated/Unmaintained Packages

```
Check if any dependencies are deprecated or no longer maintained:
- Search npm/PyPI for last release date and deprecation notices
- Look for packages with no updates in 2+ years
- Check for recommended replacements

Known items to watch:
- tailwindcss-animate: Deprecated by shadcn/ui in favor of tw-animate-css (migrate when upgrading to Tailwind v4)
- react-day-picker: v8 is archived, v9 is the maintained line (coordinate with shadcn Calendar component)
- class-variance-authority: Development stalled, monitor cva 1.0 beta

Replace deprecated packages where the migration is safe and straightforward. For breaking changes, document the replacement plan but don't migrate in this task.
```

### D. Verify Lock File Sync

```
Ensure lock files are synchronized with manifests:
- Backend: Run `uv lock --check` (exits 0 if in sync)
- Frontend: Run `npm ci` (fails if package-lock.json is out of sync with package.json)
```

---

## Automated Tests

### A. Identify Untested Code Paths

**Backend:**
```
Run pytest with coverage: cd backend && pytest --cov=. --cov-report=html
Review the coverage report and identify:
1. Files with less than 70% coverage
2. Critical business logic (services, tasks) that lacks tests
3. Error handling paths that aren't tested
4. Scraper parsing logic without HTML snapshot tests
Create a prioritized list of what needs tests most urgently.
```

### B. Add Missing Edge Case Tests

```
Review existing tests. For each test file, identify edge cases that aren't covered:
- Null/undefined/None inputs
- Empty arrays/strings
- Boundary conditions (0, -1, max values)
- Error conditions and exception handling
- Scraper edge cases (missing fields, unexpected HTML structure)
Add tests for the most critical missing edge cases.
```

### C. Remove Redundant or Flaky Tests

```
Analyze the test suite for:
1. Tests that test the same thing multiple times
2. Tests that are overly broad or test implementation details
3. Tests that mock so much they don't test real behavior
Propose which tests to remove or refactor.
```

### D. Fix Slow Tests

```
Run the test suite with timing: pytest --durations=20
Identify the slowest tests and check:
1. Are there unnecessary database operations that could use fixtures?
2. Are there tests doing redundant setup that could share fixtures?
Fix or propose fixes for the slowest tests.
```

---

## Dead Code Removal

### A. Find and Remove Unused Functions/Classes

**Backend:**
```
Search the backend for functions, classes, and methods that are defined but never called or referenced. Exclude test files from the "usage" search but include them in the "definition" search. Remove unused code after confirming it's not used dynamically (e.g., Celery tasks registered by name, management commands).
```

**Frontend:**
```
Search the frontend for exported functions, components, and utilities that are never imported elsewhere. Check for:
- Unused utility functions
- Unused TypeScript types/interfaces
- Unused constants
List and remove confirmed dead code.

Do not remove components under ui/ or other library code.
```

### B. Clean Up Commented-Out Code

```
Search the entire codebase for large blocks of commented-out code (3+ consecutive commented lines that appear to be code, not documentation). Remove them — git preserves history. Keep only legitimate documentation comments.
```

### C. Remove Unused Imports

**Backend:**
```
Run ruff check . --select=F401 in the backend directory. Remove all unused imports. Run ruff check . again to confirm.
```

**Frontend:**
```
Run npm run lint with unused import rules. Remove all unused imports. Run npm run lint to verify.
```

---

## Code Structure Review

### A. Remove and Simplify

```
Review changed files for structural issues:

Remove unnecessary code:
- Unused functions, dead branches, unused imports, unused state/props/variables
- Experimental scaffolding that can be deleted
- Premature abstractions (generic helpers used once)

Simplify:
- Flatten nested conditionals with early returns/guard clauses
- Replace multi-step logic with simpler built-ins
- Remove over-handled edge cases that don't exist in this app
- Check for built-in functions that replace hand-written code

Small focused units:
- Functions over 50 lines: extract into smaller, focused functions
- Classes over 500 lines: extract into smaller, focused classes
- Each class with behavior should be in a separate file
```

### B. Reuse Repeated Code

```
Search for duplicated code patterns:
1. Similar functions that could be consolidated
2. Repeated conditional logic
3. Copy-pasted code blocks with minor variations

Rule of thumb: If logic repeats 2+ times and it's non-trivial, reuse it. If it's trivial, duplication may be fine.

Ensure the abstraction is small, named clearly, and local to the domain — not a generic junk drawer.
```

### C. Fix Type Safety Issues

**Backend:**
```
Run pyright on the backend codebase. Address type errors in priority order:
1. Any types that should be more specific
2. Missing return type annotations on public functions
3. Incompatible type assignments
4. Missing parameter type annotations
Fix issues and re-run pyright until clean.
```

**Frontend:**
```
Run npx tsc --noEmit on the frontend. Address TypeScript errors:
1. Implicit any types
2. Possible null/undefined access
3. Type mismatches
4. Missing type definitions
Fix issues until compilation succeeds with no errors.
```

### D. Improve Error Handling

**Backend:**
```
Review error handling in the backend:
1. Find bare except clauses and make them specific
2. Identify places where errors are silently swallowed (violates project rules)
3. Ensure errors are logged with sufficient context
4. Verify sensitive information isn't leaked in error messages
5. Verify all errors are sent to Sentry
Fix the most critical error handling issues.
```

**Frontend:**
```
Review error handling in the frontend:
1. Check that API calls have proper error handling
2. Verify error boundaries exist for critical UI sections
3. Verify that all errors are communicated to the user as toast messages
4. Check loading and error states in data fetching
Implement missing error handling.
```

### E. Extract Reusable CSS Classes

```
Search frontend/src/ for repeated Tailwind utility class patterns (3+ utilities used together in 3+ places). Extract into @apply classes in globals.css.

Focus on: button patterns, card/container patterns, typography combinations, layout patterns.
Follow the project convention of using @apply in CSS.
```

---

## Async Safety

### A. Audit asyncio.run() Usage

```
Search the backend for any direct use of asyncio.run(). Every instance must use run_async_safely() instead:

# ❌ Wrong
def download_page(url: str) -> str:
    return asyncio.run(_fetch_page_async(url))

# ✅ Correct
from movies_app.tasks.download_utilities import run_async_safely

def download_page(url: str) -> str:
    return run_async_safely(_fetch_page_async(url))

asyncio.run() fails when called from an already-running event loop (Celery tasks, async tests).
```

### B. Audit Sync Calls in Async Code

```
Search for all `async def` methods in the backend. Inside each, check for sync I/O:
- Direct ORM calls: Model.objects.create(), .save(), .filter(), .get(), .update(), .delete()
- Sync helper methods that internally do DB work
- Any sync network/file I/O

Fix with sync_to_async:
    from asgiref.sync import sync_to_async

    await sync_to_async(OperationalIssue.objects.create)(
        name="Issue", task="task", error_message="err"
    )
```

### C. Audit Camoufox Usage

```
Search for AsyncCamoufox usage. Every instance must use both browser and context options:

from movies_app.tasks.download_utilities import get_browser_options, get_context_options

async with AsyncCamoufox(**get_browser_options()) as browser:
    context = await browser.new_context(**get_context_options())
    page = await context.new_page()

Check:
- No direct AsyncCamoufox() without get_browser_options()
- No new_context() without get_context_options()
```

---

## Django-Specific

### A. Query Optimization

```
Review database queries in the backend:
1. Find N+1 query patterns (queries in loops)
2. Identify missing select_related/prefetch_related
3. Look for queries that could benefit from indexes
4. Find large queries that should be paginated
5. Don't evaluate querysets multiple times accidentally (e.g., len(qs) then iterate)
Implement the most impactful optimizations.
```

### B. Transaction Safety

```
Review multi-step write operations:
1. Multi-step writes that must succeed/fail together should use transaction.atomic
2. External side-effects (network calls, Celery tasks) should not be performed mid-transaction unless intentional
```

### C. Migration Safety

```
Review migrations:
1. Model changes include migration files
2. No direct database modifications outside of migrations (functions, triggers, RLS policies all go through migrations.RunSQL())
```

---

## Supabase Functions

### A. Review and Optimize Supabase Functions

```
Review all SQL functions defined in Supabase (check migrations in backend/movies_app/migrations/ for RunSQL operations, and query Supabase directly via MCP for existing functions).

For each function:
1. Is it still called? Search for its name in backend/ and frontend/ code.
2. Could it be simplified or optimized?
3. Are there missing indexes that would improve its performance?

Remove dead functions via a new migration. Optimize where beneficial.
```

---

## Security

### A. Security Code Review

```
Backend:
- SQL injection: Check for raw SQL queries, ensure parameterized queries
- Authentication: Verify admin pages check session + admin status
- Secrets: Ensure no hardcoded credentials or API keys
- Input validation: Check that user input is validated
- RLS: Verify RLS policies are appropriate for each table

Frontend:
- XSS: Check for dangerouslySetInnerHTML usage
- Sensitive data: Ensure tokens aren't logged or exposed
- Auth: Admin pages check session + admin status before rendering

List findings with severity levels and fix critical issues.
```

### B. Review Environment Variables and Secrets

```
Audit environment variable usage:
1. Check that .env files are in .gitignore
2. Verify no secrets are committed in git history
3. Ensure all required env vars are documented
4. Check that sensitive env vars aren't logged
```

---

## Performance

### A. Frontend Bundle Analysis

```
Analyze the frontend bundle size:
1. Run npm run build:local and check output sizes
2. Identify large dependencies that could be lazy-loaded
3. Look for duplicate packages in the bundle
4. Identify code that could be split into separate chunks
Propose and implement optimizations for the largest wins.
```

### B. Supabase Query Optimization

```
Review Supabase queries in the frontend:
1. Check for over-fetching (selecting more columns than needed)
2. Identify queries that could benefit from client-side caching
3. Look for multiple sequential queries that could be combined
4. Check for missing .select() column specifications
5. Verify pagination is used for large result sets
Propose optimizations for slow or heavy queries.
```

---

## Logging and Monitoring

### A. Review Logging Coverage

```
Backend:
1. Are service methods logging key operations?
2. Are Celery tasks logging start/end and key steps?
3. Are scraper runs logging enough context to debug failures?
4. Are external API calls (TMDB) logged with timing?
5. Are operational issues being logged to the OperationalIssue model?

Remove logging that is noisy or not useful.
```

### B. Review Sentry Issues

```
Use the Sentry MCP tools to review current issues:
1. Unresolved issues sorted by frequency and impact
2. New issues introduced recently
3. Recurring issues that were previously resolved
4. Error patterns that suggest systemic problems
Prioritize findings and propose fixes.
```

---

## Frontend Checks

### A. Component and State Review

```
Review frontend components:
- Component responsibilities are clear (render vs fetch vs format)
- useEffect dependencies correct (no stale closures)
- Requests canceled/ignored when obsolete (avoid race conditions)
- Loading/error/empty states all exist and are handled
- Removed unused state, props, handlers
- Falsy checks don't accidentally treat 0 or "" as missing
```

---

## Configuration and Settings

### A. Review Settings Files

```
Backend:
- backend/config/settings.py (and settings_test.py)
- Are there insecure defaults (DEBUG=True, ALLOWED_HOSTS=['*'])?
- Are there deprecated Django settings?
- Are middleware and installed apps in the right order?

Frontend:
- frontend/next.config.ts, tsconfig.json, tailwind config
- Are there unused or conflicting configuration options?
```

### B. Lint and Format

```
Backend:
- Run ruff format . to format Python code
- Run ruff check . --fix to auto-fix linting issues

Frontend:
- Run npm run lint -- --fix to auto-fix issues

Commit formatting changes separately from logic changes.
```

---

## Content Review

### A. Search for Typos in User-Facing Content

```
Search frontend/src/ for user-facing strings. User-facing text should be in Spanish. Check for:
1. Spelling errors (Spanish)
2. Grammar issues
3. Inconsistent terminology
4. Placeholder text left from development ("Lorem ipsum", "TODO", "FIXME")
5. Admin dashboard text should be in English
Fix any issues found.
```

---

## Documentation

### A. Update Stale Documentation

Run the `s-update-documentation` skill for a full documentation audit.

### B. Add Missing Docstrings

```
Find public functions and classes lacking docstrings in the backend.

Focus on:
- Service classes and their methods
- Celery task functions
- Model methods with non-obvious behavior
- Management commands (include verbose docstrings with usage examples)

Follow project conventions:
- Short methods under 10 lines: no docstring needed
- Medium methods (10-50 lines): docstring describing purpose and non-obvious behavior
- Long methods (>50 lines): should be decomposed; if not possible, docstring + inline comments
- Python classes with behavior: docstrings of 5-20 lines
- Describe why, not what
```

---

## Tasks to Develop

These are maintenance tasks that need to be written as full audit prompts above:

- Update class diagrams for models
- Review overall structure and suggest refactorings
- Suggest frontend components that should be extracted
- Deprecated calls to library functions
- Review the logs on BetterStack for warnings and errors and write a report
- General code review of individual files and specific sections of the code
- Add integration tests for complex multi-step logic
- Fix slow tests (verify sleep calls are mocked out)
- Are there any areas in the code or queries that use UTC instead of Colombia time?
