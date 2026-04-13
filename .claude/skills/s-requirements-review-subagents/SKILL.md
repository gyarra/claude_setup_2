---
name: s-requirements-review-subagents
description: Use when peer-reviewing a requirements document (GitHub issue or file with Functional + Technical sections) before implementation. Runs a cross-model council — Gemini and Claude lenses — in parallel. Codex is off by default (author bias — it drafts Technical in `s-requirements-writing`). A moderator synthesizes findings by section and severity.
allowed-tools: Task, Read, Bash(gh issue view:*), Bash(gh issue view --repo:*)
---

# Requirements Review (Cross-Model Council)

Dispatches reviewers in parallel, then synthesizes their findings into a single verdict.

**Default lineup (3 parallel Task calls):**
- **Gemini** (`gemini-2.5-pro`) via `gemini-reviewer` subagent — read-only repo access
- **2 Claude lenses** (Task subagents) — no repo access, focused on document quality

**Opt-in:** **Codex** (`gpt-5.3-codex`) via `codex-reviewer` subagent — pass `--include-codex` only when Codex did NOT author the Technical section.

## Parameters

```
/s-requirements-review-subagents [--file <path>] [--issue <number>] [--include-codex] [--skip-gemini] [--skip-claude-lenses] [--codex-effort <low|medium|high|xhigh>] [--gemini-model <model>]
```

| Flag | Effect |
|------|--------|
| `--issue <N>` | Fetch issue body via `gh issue view <N> --repo gyarra/cine_medallo_2` |
| `--file <path>` | Read requirements from file |
| `--include-codex` | Add Codex to the council (only when Technical was NOT authored by Codex) |
| `--skip-gemini` | Drop Gemini. If no `--include-codex`, abort — lineup would be Claude-only (use `s-requirements-review-council` instead) |
| `--skip-claude-lenses` | Drop both Claude lenses |
| `--codex-effort` | Override Codex reasoning effort (default `high`) |
| `--gemini-model` | Override Gemini model (default `gemini-2.5-pro`) |

If neither `--file` nor `--issue`, treat positional args as inline requirements text.

Abort if fewer than 2 reviewers remain after applying flags.

---

## Step 1: Load the Requirements

1. `--issue <N>`: `gh issue view <N> --repo gyarra/cine_medallo_2` — capture body verbatim.
2. `--file <path>`: read the file.
3. Otherwise: use inline text.

Parse out `## Functional` and `## Technical`. Flag missing sections but continue. Store the full body — every reviewer gets the same text.

## Step 2: Dispatch All Reviewers in Parallel

**One assistant message, multiple `Task` tool calls.** Never sequential — wall time multiplies and independence is lost.

### 2a. Codex reviewer (only with `--include-codex`)

`subagent_type: codex-reviewer`
`description: "Codex requirements review"`

```
CWD: /Users/yarray/development/cine_medallo_2_wrapper/cine_medallo_2
EFFORT: <codex-effort, default "high">

You are reviewing a requirements document for the Pa' Cine project. You have read-only access to the repo. Use that access aggressively — verify claims against the actual code.

## Project Context

- "Pa' Cine" — movie showtime website for Colombia, canonical timezone America/Bogota
- Backend: Django 5.2 (Python 3.13), Celery, PostgreSQL (Supabase), Redis
- Frontend: Next.js, TypeScript, Tailwind, Supabase
- Code standards: ≤40-line functions, ≤400-line classes, ≤4-dep constructors, ≤3-level nesting, single responsibility
- Backend-first deployment rule: backend changes land before the frontend consumes them
- HTML scrapers preferred over API scrapers for new theater sources

## The Requirements Document

<paste full_body here>

## What to Review

### Functional section

1. **Completeness**: Are acceptance criteria concrete and testable? Are edge cases named?
2. **Clarity**: Are there ambiguous terms, undefined behaviors, or hand-waves?
3. **User impact**: Does the proposed behavior actually solve the stated problem?
4. **Pa' Cine edge cases**: timezone handling (Bogota vs UTC), stale scraper data, concurrent scraper runs, theater sync state.

### Technical section

1. **Does it match the actual code?** Open the files the spec references. Are the proposed changes realistic? Flag any "change X" that would require rewriting Y first.
2. **Scope accuracy**: Is the files/modules list complete? Use grep to find downstream consumers the spec missed.
3. **Data model design**: Are proposed fields the right shape? Are there existing models this should extend?
4. **Migration / backfill**: Does the spec account for existing rows?
5. **Concurrency and timezone correctness**: `timezone.now()` vs Bogota midnight, Celery parallelism, unique constraints.
6. **Testing gaps**: How will this be tested? Which test files need updating?
7. **Backend-first ordering**: Are subtasks ordered correctly if both backend and frontend are involved?

## Output Format

Group findings by severity: **Critical** (will cause failure or wrong data, include file:line), **Moderate** (design concerns, missing edge cases), **Minor** (nits), **Open Questions**. Cite the spec text and relevant file:line for each finding.
```

### 2b. Gemini reviewer

`subagent_type: gemini-reviewer`
`description: "Gemini requirements review"`

```
CWD: /Users/yarray/development/cine_medallo_2_wrapper/cine_medallo_2
MODEL: <gemini-model, default "gemini-2.5-pro">

You are reviewing a requirements document for the Pa' Cine project. You have read-only repo access. Read the files the spec references — verify claims against the real code.

## Project Context

- "Pa' Cine" — movie showtime website for Colombia, canonical timezone America/Bogota
- Backend: Django 5.2 (Python 3.13), Celery, PostgreSQL (Supabase), Redis
- Frontend: Next.js, TypeScript, Tailwind, Supabase
- Code standards: ≤40-line functions, ≤400-line classes, ≤4-dep constructors, ≤3-level nesting
- Backend-first deployment rule: backend changes land before the frontend consumes them
- HTML scrapers preferred over API scrapers for new theater sources

## The Requirements Document

<paste full_body here>

## What to Review

### Functional section

Focus on user impact, acceptance criteria specificity, and missing edge cases. What behaviors are ambiguous? What failure modes are unspecified?

### Technical section

For each file, module, or API the spec mentions:

1. **Verify it exists** and is structured the way the spec assumes.
2. **Check for hidden dependencies** — does changing module A break module B?
3. **Evaluate data model changes** against the current schema. Are there existing fields that already serve this purpose?
4. **Spot optimization opportunities** — redundant queries, N+1 patterns, missing indexes.
5. **Spot architectural smells** — tight coupling, leaky abstractions, misplaced responsibilities.

## Output Format

Group findings by severity: **Critical** (will cause failure or wrong data, include file:line), **Moderate** (design concerns, alternatives worth considering), **Minor** (nits), **Open Questions**. Cite spec text and relevant file:line for each finding.
```

### 2c. Claude lens — Functional Clarity

`subagent_type: general-purpose`
`description: "Claude lens: Functional clarity"`

```
You are an independent reviewer. Your ONLY lens is **Functional Clarity & Acceptance Criteria**. Do not evaluate technical design or implementation feasibility.

Read the `## Functional` section and evaluate:

1. **Are acceptance criteria concrete and testable?** "User sees movies faster" is not testable. "First meaningful paint under 2s on 3G" is.
2. **Is every user-facing behavior specified?** Happy path, error states, empty states, loading states.
3. **Are edge cases named?** Missing, stale, duplicated, or boundary inputs.
4. **Is the problem statement clear?** Can you restate the user pain in one sentence?
5. **Is there ambiguous language?** Words like "fast", "clean", "better", "properly" are red flags unless defined.
6. **Does Functional contradict itself** or imply behaviors Technical doesn't support?

## The Requirements Document

<paste full_body here>

## Output Format

**Critical**: Ambiguities that make it impossible to know when the feature is "done". **Moderate**: Missing edge cases, vague language. **Minor**: Wording clarifications. Cite the exact phrase for each finding.
```

### 2d. Claude lens — Completeness & Gaps

`subagent_type: general-purpose`
`description: "Claude lens: Completeness & gaps"`

```
You are an independent reviewer. Your ONLY lens is **Completeness & Gaps** across both Functional and Technical sections. Look for what's MISSING.

Evaluate:

1. **Unstated assumptions?** What must a developer figure out that the spec should answer?
2. **Scope boundary clear?** What's in, what's out? Adjacent features that need touching but aren't mentioned?
3. **Success metrics defined?** How will we know it worked after shipping?
4. **Rollout considered?** Migration, backfills, feature flags, rollback plan?
5. **Non-functional requirements?** Performance, security, accessibility, observability.
6. **Testing strategy?** Unit, integration, manual steps.
7. **Dependencies named?** External services, blocked-by relationships.
8. **Functional-Technical connection complete?** Does every acceptance criterion have a Technical plan? Does every Technical change serve a Functional goal?

## The Requirements Document

<paste full_body here>

## Output Format

**Critical**: Gaps that will cause re-planning mid-implementation. **Moderate**: Gaps causing rework or ambiguity. **Minor**: Nice-to-haves. **Open Questions**: Questions the spec should answer before work starts. Cite the section (Functional, Technical, or "missing entirely") for each finding.
```

## Step 3: Collect Outputs

Codex wraps output in `<CODEX_OUTPUT>` + `<CODEX_META>`. Gemini wraps in `<GEMINI_OUTPUT>` + `<GEMINI_META>`. Claude lenses return plain Markdown.

If a reviewer returns `<CODEX_ERROR>` or `<GEMINI_ERROR>`, note it in the final report and continue with remaining reviewers. Do not retry.

## Step 4: Moderator Synthesis

Read all outputs and produce:

```markdown
# Council Verdict: <title or issue ref>

**Reviewers:** <list with model names>
**Skipped:** <skipped via flags, if any>
**Failed:** <errored reviewers with summary, if any>

---

## Verdict

One of: **Ready to implement** / **Needs revision** / **Not ready — major rework**.

One paragraph explaining why.

---

## Critical Issues

For each issue flagged Critical by ANY reviewer:

- **[Finding]** — Flagged by: <reviewer names>
  - Evidence: <spec text or file:line>
  - Consensus: <do reviewers agree?>
  - Recommended action: <what to do>

---

## Moderate Issues

Same format as Critical.

---

## Minor Issues

Bulleted list, grouped by similarity.

---

## Open Questions

Questions the spec should answer before implementation.

---

## Points of Disagreement

Where reviewers contradicted each other. Present both sides — do not pick a winner.

---

## Revision Checklist

- [ ] <specific edit>
- [ ] <specific edit>
```

### Synthesis rules

1. **Attribute findings.** Name which reviewer(s) flagged each Critical/Moderate issue. Consensus (2+) carries more weight.
2. **Preserve file:line citations** from Codex/Gemini as clickable links: `[file.py:42](backend/file.py#L42)`.
3. **Surface contradictions** in "Points of Disagreement" — don't silently pick a side.
4. **Flag suspect findings.** If a reviewer seems wrong (hallucinated file, misread spec), state your reasoning. The user decides.
5. **Keep it scannable.** Critical + Verdict should take 60 seconds to read.

## Step 5: Offer Follow-Ups

Ask the user whether to:
- Update the issue body with accepted feedback
- Re-run a specific reviewer with different parameters
- Proceed to planning with `superpowers:writing-plans`
- Open sub-issues for deferred concerns
- Do nothing

Never make changes automatically.
