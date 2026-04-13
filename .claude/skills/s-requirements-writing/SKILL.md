---
name: s-requirements-writing
description: Use when starting new work, picking up an existing task, or when requirements need to be captured or updated in GitHub Issues
---

# GitHub Issues for Work Tracking

## Overview

Track all non-trivial work in GitHub Issues. Issues serve as the source of truth for what's being built and why — write them before starting, update them during implementation, and keep them current as requirements evolve.

## When to Use

- Starting new work that spans more than a single quick fix
- User mentions a task, feature, or bug that doesn't have an issue yet
- Picking up work that may already have an issue
- Requirements changed during implementation and the issue is stale

## The Requirements Workflow (Full Picture)

Writing requirements is a multi-step collaboration between the user, Claude, and Codex. Each step has a clear handoff. Do NOT skip ahead — the human review gates exist for a reason.

```
1. User drafts functional requirements (rough, as much detail as they have)
   ↓
2. Claude refines the functional requirements
   ↓
3. ⏸  HUMAN REVIEW — user reviews and requests changes if needed
   ↓
4. Claude delegates writing the technical requirements to Codex (read-only repo access)
   ↓
5. ⏸  HUMAN REVIEW — user reviews technical and requests changes if needed
   ↓
6. Optional: invoke s-requirements-review-subagents for cross-model verification
   ↓
7. Issue is ready for planning / implementation
```

**Critical rule:** Claude writes Functional. Codex writes Technical. Never blur this — Claude's strength is structured prose and user-centric framing; Codex's strength is grounded code references after grepping the actual repo. The wrong agent on the wrong section produces worse output AND wastes the human review steps.

## Step 1: User Drafts Functional Requirements

The user comes to you with a rough description of what they want to build. It may be a paragraph, a bulleted list, or a few sentences. Treat it as raw input — your job is to refine it, not to immediately commit to a technical approach.

## Step 2: Claude Refines the Functional Requirements

You write the `## Functional` section. Do NOT write the Technical section yet — that comes later, from Codex.

The Functional section answers WHAT and WHY, never HOW. It should be readable by someone who has never opened the codebase.

```markdown
## Functional

**Problem:** One-paragraph statement of the user pain this solves.

**Goal:** What "done" looks like from the user's perspective. Concrete, observable.

**User-facing behavior:**
- Happy path: what the user sees when things work
- Error states: what they see when things fail
- Empty states, loading states, permission-denied states
- Edge cases: timezone boundaries, concurrent users, stale data, missing inputs

**Acceptance criteria:** Testable bullets. "User sees movies faster" is not testable. "First showtime appears within 2 seconds on a fresh page load" is.

**Out of scope:** What this issue explicitly does NOT cover. Adjacent features that might tempt scope creep.

**Success metrics (if applicable):** How we'll know it actually worked after shipping.
```

### What to think about while writing Functional

- **Pa' Cine timezone is America/Bogota.** Any time-of-day behavior must say so explicitly. "Today's showtimes" is ambiguous — at 11pm Bogota, "today" in UTC is already tomorrow.
- **Scrapers run on a schedule, not on demand.** If the feature depends on data freshness, name the staleness window the user accepts.
- **Mobile-first.** If layout matters, specify mobile and desktop separately.
- **Spanish vs English copy.** Pa' Cine ships in Spanish to end users. Note any user-visible text the issue introduces.

After drafting, **STOP**. Do not write Technical. Do not invoke Codex. Output the Functional section to the user and explicitly say:

> Here's the refined Functional section. Please review and let me know if anything should change. Once you're happy with it, I'll have Codex draft the Technical section.

## Step 3: Human Review Gate (Functional)

Wait for the user. They will either approve or request changes.

- **If they request changes:** revise the Functional section in place and ask again. Loop until they approve.
- **If they approve:** proceed to Step 4.

Do NOT proceed without explicit approval. The whole point of this gate is to lock the "what" before anyone debates the "how" — if you start technical drafting on shaky functional requirements, both halves will need rework.

## Step 4: Claude Delegates Technical Writing to Codex

Codex writes the `## Technical` section. Codex has read-only repo access via its sandbox, so it can grep, read files, and ground its proposals in the real code. Claude does not draft Technical from imagination — that's how you get specs that reference functions that no longer exist.

**REQUIRED SUB-SKILL:** Use the `skill-codex:codex` skill to learn the current `codex exec` flags. Do NOT hardcode model names or flags from this file — the plugin auto-updates and is the source of truth.

Recommended defaults for technical drafting:
- **Model:** `gpt-5.3-codex`
- **Reasoning effort:** `high` (this is a drafting task, not a quick lookup — pay for thoroughness)
- **Sandbox:** `read-only`
- **Working directory:** repo root

### Crafting the Codex prompt

The prompt must be self-contained. Codex starts cold — it has no memory of your conversation with the user. Include:

1. **The full Functional section verbatim**, exactly as the user approved it.
2. **The Pa' Cine project context** (stack, timezone, code standards).
3. **The Technical section template** (see below) with explicit instructions on every required subsection.
4. **Instruction to grep/read the actual code** before proposing changes. Tell Codex its value is grounding, not invention.
5. **Instruction to flag uncertainty** rather than guess. If a file doesn't exist where the spec expects, say so.

Example prompt shape:

```
codex exec --skip-git-repo-check \
  -m gpt-5.3-codex \
  --config model_reasoning_effort=high \
  --sandbox read-only \
  "$(cat <<'PROMPT'
You are drafting the Technical section of a requirements document for the Pa' Cine project. You have read-only access to the repo at the current working directory. USE that access — grep for the modules the spec touches, read the files you'll be modifying, and ground every proposal in the actual code.

## Project Context

- "Pa' Cine" — movie showtime website for Colombia, canonical timezone America/Bogota
- Backend: Django 5.2 (Python 3.13), Celery, PostgreSQL (Supabase), Redis
- Frontend: Next.js, TypeScript, Tailwind, Supabase
- Code standards: ≤40-line functions, ≤400-line classes, ≤4-dep constructors, ≤3-level nesting, single responsibility
- Backend-first deployment rule: backend changes land before the frontend consumes them
- HTML scrapers preferred over API scrapers for new theater sources

## The Approved Functional Requirements

<paste full Functional section here, verbatim>

## Your Task

Draft the Technical section for this requirements document, following the template below. Do not modify the Functional section — only draft Technical.

[paste the full template from "Technical Section Template" below]
PROMPT
)" 2>/dev/null
```

Capture Codex's output. Do not paraphrase it. If it cited files and line numbers, those must survive into the final issue body — they're the whole reason you used Codex.

### Technical Section Template

The Technical section Codex produces should follow this shape:

```markdown
## Technical

### Approach

One-paragraph summary of the implementation strategy. Name the architectural pattern, the main module(s) being touched, and any non-obvious trade-offs.

### Data model changes

If new fields, tables, or migrations are needed, list them here with column types, constraints, and indexes. If none, write "None."

For each new field: state whether existing rows need backfilling, and how.

### API / interface changes

New endpoints, modified endpoints, signature changes to internal functions that have multiple callers. If none, write "None."

### Concurrency, timezone, and edge case considerations

Pa' Cine has known footguns:
- `timezone.now().date()` rolls over at UTC midnight, not Bogota midnight
- Celery scraper tasks can run concurrently against the same theater
- Unique constraints on `(scope_field, date)` already create an implicit index — adding an explicit one is redundant
- Scraper data freshness windows vary by chain

Address each one that could affect this feature, even if the answer is "not applicable."

### Testing strategy

Which test files will gain new tests. What kinds of tests (unit, integration, snapshot). What edge cases the tests must cover. Reference existing test patterns in the repo.

### Rollout / migration

If existing data needs migration, backfill, or feature-flagging, describe the order of operations. If none, write "Standard deploy, no special rollout."

### Files to be modified

A complete list of every file that will be touched, with a one-line description of WHAT changes in that file. This is the most important subsection — it forces grounded scoping and makes PR boundaries obvious.

Format:

| File | Change |
|------|--------|
| `backend/movies_app/models/showtime.py` | Add `is_preview` boolean field, update `__str__` |
| `backend/movies_app/migrations/0042_showtime_is_preview.py` | New migration (auto-generated) |
| `backend/movies_app/serializers/showtime.py` | Expose `is_preview` in API response |
| `backend/movies_app/tests/test_showtime_model.py` | Add test for default value and string repr |
| `frontend/src/app/movies/[slug]/page.tsx` | Show "Preview" badge when `is_preview` is true |

If the file doesn't exist yet, mark it as `(NEW)`. If you're uncertain whether a file needs touching, mark it as `(maybe)` and explain why in the description.
```

### What to think about while reviewing Codex's draft

Before pasting Codex's output into the issue, sanity-check it:

- **Did Codex actually grep the repo?** If the Files section says things like "the showtime model" without a path, Codex didn't read the code. Re-prompt with stronger instructions.
- **Are the file paths real?** Spot-check 2-3 paths with a quick `ls` or `find`. Hallucinated paths are rare with Codex but not zero.
- **Does the Files table align with the Subtasks?** Each subtask should map to a coherent slice of the Files table. If subtask 1 touches files A, B, C and subtask 2 touches B, D, E, you have a coupling problem — flag it.
- **Did Codex address the timezone/concurrency footguns?** If the section is silent, that's a red flag for a feature that touches data.

## Step 5: Human Review Gate (Technical)

Output Codex's Technical section to the user and explicitly say:

> Here's Codex's draft of the Technical section. Please review — pay special attention to the "Files to be modified" table and the data model changes. Let me know if anything should change.

Wait for explicit approval. If they request changes, you can either:
- Revise the Technical section directly (for small wording or structural fixes), or
- Re-invoke Codex with the user's feedback in the prompt (for substantive changes that need re-grounding in the code).

## Step 6: Optional Council Review

After both Functional and Technical are approved, ask the user:

> The requirements are ready. Would you like to run `s-requirements-review-subagents` for a cross-model verification pass before committing to implementation? It dispatches Gemini and Claude lenses in parallel against the full doc and produces a synthesized verdict. Recommended for high-stakes or wide-blast-radius features; skippable for small changes.

**If yes:** invoke `s-requirements-review-subagents`. The council will NOT use Codex as a reviewer (Codex authored the Technical section, so author bias would taint its review). It will use Gemini + Claude lenses.

**If no:** proceed.

## Step 7: Breaking Down Tasks

Add subtask checkboxes after Functional and Technical are approved. Each subtask should map to **one PR** and follow these rules:

- **One PR per subtask.** Don't bundle.
- **A PR should touch no more than 10 files. Ideally fewer.** If a subtask's slice of the "Files to be modified" table exceeds 10 files, split the subtask into multiple PRs.
- **Backend before frontend.** When a feature spans backend and frontend, the backend subtask comes first. The Django backend and Next.js frontend deploy independently — backend changes (models, migrations, Celery tasks) must land before the frontend consumes them.
- **Specific labels.** "Backend: Add scraper for X with snapshot tests" — not "Backend work."

```markdown
## Subtasks

- [ ] Backend: Add new scraper for CinePlex theaters with HTML snapshot tests (5 files)
- [ ] Backend: Wire scraper into Celery beat schedule (2 files)
- [ ] Frontend: Build theater detail page showing showtimes grouped by movie (8 files)
```

Annotating the file count next to each subtask makes the 10-file rule self-enforcing — if you can't write a number, you don't know your scope yet.

**If a task is very large** (more than 3-4 subtasks, or subtasks that themselves exceed 10 files), break it into separate linked issues instead. Each issue gets its own Functional/Technical sections and its own set of PRs. Link them with "Part of #N" in the body.

**Planning complex tasks.** For tasks that need a detailed implementation plan beyond what fits in the issue's Technical section, **REQUIRED SUB-SKILL:** Use `superpowers:writing-plans` to create a step-by-step plan after the issue is written.

## Step 8: Creating the Issue

```bash
gh issue create --title "Title" --body "$(cat <<'EOF'
## Functional

...

## Technical

...

## Subtasks

- [ ] ...
EOF
)"
```

Use the issue number returned by `gh issue create` for any subsequent updates or council review invocations.

## During Work

### Loading Context

When the user asks to start work on something, ask if there's an existing GitHub issue for it. If so, read the issue first:

```bash
gh issue view <NUMBER>
```

### Updating Issues

As work progresses, update the issue with:
- Status updates (what's done, what's in progress, what's blocked)
- Decisions made or requirements that changed during implementation
- Useful notes for future reference (gotchas, dependencies, things tried and abandoned)

```bash
gh issue comment <NUMBER> --body "Status update text"
```

### Completing Subtasks

Check off subtask checkboxes as they're completed by editing the issue body.

### Keeping Requirements Current

If requirements evolve significantly during implementation, revise the Functional/Technical sections in the issue body to keep them accurate — the issue should always reflect current truth, not just the original plan.

When revising Technical mid-implementation, you can re-invoke Codex against the updated Functional section (Step 4 again) for a fresh grounded draft. Don't paper over drift in the issue body.

```bash
gh issue edit <NUMBER> --body "$(cat <<'EOF'
Updated body with revised requirements
EOF
)"
```
