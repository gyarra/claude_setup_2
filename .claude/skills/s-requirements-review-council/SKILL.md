---
name: s-requirements-review-council
description: Use when peer-reviewing a document, skill file, RFC, or PRD — or when stress-testing a technical approach or strategic decision — using parallel Claude subagents with focused lenses and a moderator synthesis. Three modes — doc-review (default, for documents), review (for technical approaches), debate (for strategic decisions). No external models, no repo access. For requirements review with cross-model coverage and codebase access, use s-requirements-review-subagents instead.
allowed-tools: Task, Read, Bash(gh issue view:*), Bash(wc:*)
---

# Council Review

Runs a structured multi-agent council using parallel `Task` subagents (`general-purpose`). Each subagent is a single lens (or a single persona). Nobody sees anyone else's work until Round 2. A moderator synthesizes the full transcript at the end.

The value is **forced focus**, not model diversity. A single reviewer asked to evaluate "everything" spreads attention thin. Parallel lenses each do their one job well, and because Round 1 is isolated, they can't drift toward consensus before they've formed independent views.

**Three modes:**

- **`--mode doc-review`** (default) — peer-review a written document (requirements, plan, skill, spec, RFC, PRD) for quality, completeness, clarity. *"Is this ready to ship?"*
- **`--mode review`** — examine a technical approach through different lenses. *"Is this approach sound? What are we missing?"*
- **`--mode debate`** — personas with different value systems argue a strategic question. *"Should we do X?"*

## When NOT to use

- **Requirements documents where repo claims matter** → use `s-requirements-review-subagents` (cross-model with read-only repo access) instead, or in addition.
- **Code review of PRs** → use `s-pr-review` or `pr-review-toolkit:review-pr`.
- **Single cross-model sanity check** → use `s-requirements-review-codex`.
- **Documents > ~320k characters** → abort and chunk the document first (see Hard Rules).

## How this complements siblings

- **`s-requirements-review-codex`** — one external model (Codex), full repo access, faster and cheaper.
- **`s-requirements-review-subagents`** — cross-model council (Gemini + Claude lenses, optional Codex) for requirements with repo access. Use when technical claims need to be verified against actual code. *(This skill may be renamed; check the description in `.claude/skills/` if the name changes.)*
- **`s-requirements-review-council`** (this skill) — Claude-only council, multi-mode, no repo access. Use for self-contained documents, strategic debates, or when the subject isn't code-grounded.

Use in combination: run `s-requirements-review-subagents` for ground-truth codebase checks on requirements, then run this skill in `doc-review` mode to stress-test the document's clarity and structure.

---

## Hard Rules

These apply to every invocation, every mode. Violations break the skill.

### 1. Placeholder substitution

The prompt templates below contain placeholders wrapped in `<<...>>`, e.g. `<<DOCUMENT_TEXT>>`, `<<LENS_NAME>>`, `<<OTHER_REVIEWS>>`. Before dispatching any Task subagent, you **must** replace every `<<PLACEHOLDER>>` (including the angle brackets) with the real content. Never leave `<<...>>` literal in what you send to a subagent. If you can't fill a placeholder, abort and tell the user what's missing.

### 2. Input size guardrail

After loading the primary input in Step 1, check its character count:

- **≤ 80,000 chars** — proceed normally.
- **80,000 – 320,000 chars** — warn the user: *"Input is ~N chars (~M tokens). Large inputs degrade review quality. Continue, chunk, or summarize first?"* Wait for confirmation before dispatching subagents.
- **> 320,000 chars** — abort. Tell the user: *"Input exceeds the hard limit. Extract the section you want reviewed, or summarize first, then re-invoke."*

Use `wc -c "<file>"` for a quick character count on `--file`, or `echo "<text>" | wc -c` for inline/issue body text.

### 3. Response language

All subagents respond in **English**, regardless of the document's language. Pa' Cine's user-facing text is Spanish, but code review is developer-facing and English throughout. Include `Respond in English.` in every subagent prompt.

### 4. Parallel dispatch

Round 1 subagents **must** be launched in a single assistant message with multiple `Task` tool calls. Same for Round 2. Sequential dispatch defeats the core design — wall time balloons and groupthink risk appears. This is the single highest-value rule in the skill.

### 5. Round 1 isolation

Round 1 subagents must not see each other's output. They receive only their lens/persona description + the document. Round 2 subagents and the moderator are the only participants who see the full Round 1 transcript.

### 6. No manufactured disagreement

Round 2 prompts explicitly tell reviewers not to invent corrections. A lens with nothing new to add should say so — padding Round 2 with invented objections degrades the synthesis.

### 7. No external tools in subagents

Subagents must not use `Read`, `Grep`, `Glob`, `Bash`, or any file/codebase tool. The document under review must be self-contained. Every subagent prompt includes this restriction explicitly. If the document requires codebase verification, the user should run `s-requirements-review-subagents` instead (or in addition).

---

## Parameters

```
/s-requirements-review-council <inline topic or description> [--mode doc-review|review|debate] [--file <path>] [--issue <N>] [--lenses "..."] [--personas "..."]
```

- `--mode` — `doc-review` (default), `review`, or `debate`.
- `--file` — Path to a text file to use as the primary input. Read once in Step 1.
- `--issue` — GitHub issue number in `gyarra/cine_medallo_2`. Runs `gh issue view <N>` and uses the body.
- `--lenses` — Override default lenses (doc-review or review mode). **Format: `"Name: description; Name: description"` — semicolon between entries, colon between name and description.** Semicolons avoid the comma ambiguity of descriptions that contain commas.
- `--personas` — Override default personas (debate mode only). Same semicolon format.

Inline text is treated as the topic when no `--file` or `--issue` is given. If both a file/issue and inline text are provided, the inline text becomes supplementary instructions (e.g., *"focus on the data model section"*).

**Examples:**

```
# Peer-review a requirements doc
/s-requirements-review-council --file docs/requirements/sitemap.md

# Peer-review a GitHub issue
/s-requirements-review-council --issue 211

# Peer-review a skill file (auto-detects and uses skill review lenses)
/s-requirements-review-council --file .claude/skills/s-requirements-review-council/SKILL.md

# Stress-test a technical approach
/s-requirements-review-council --mode review "Cache Supabase theater queries in Redis with a 5-minute TTL."

# Debate a strategic decision
/s-requirements-review-council --mode debate "Should we migrate from Camoufox to Playwright for HTML scrapers?"

# Custom lenses
/s-requirements-review-council --file docs/requirements/new_scraper.md \
  --lenses "Scraper reliability: focus on anti-bot evasion, rate limiting, failure modes; Data freshness: focus on scraping cadence, staleness, cache invalidation"
```

---

## Step 1 — Parse args and load context

1. Extract `--mode`, `--file`, `--issue`, `--lenses`, `--personas` flags and capture the remaining text as the inline topic.
2. Load the primary input (priority order):
   - If `--file` is set, read it with the Read tool.
   - Else if `--issue` is set, run `gh issue view <N> --repo gyarra/cine_medallo_2` and capture the body.
   - Else use the inline text.
   - If a file/issue AND inline text are both present, treat inline as supplementary instructions.
3. **Apply the size guardrail** (see Hard Rule #2). Use `wc -c` for a quick character count. Warn or abort as specified.
4. Parse `--lenses` / `--personas` by splitting on `;`, then each entry on the first `:`. Trim whitespace. Descriptions may contain colons and commas — only the first `:` per entry is the name/description separator.
5. Pick the council members (see Step 2).
6. Echo to the user before dispatching anything:
   - Mode
   - Input source (file path, issue number, or "inline")
   - Input size (char count)
   - Council members (lens/persona names)

If `--file` points at a binary or unreadable file, report the error and stop — don't fall back to inline text without explicit user confirmation.

## Step 2 — Select council members

**Doc-review mode:**
- Custom `--lenses` if provided, else:
- **Skill review lenses** if the input is detected as a skill file (any of: YAML front matter contains `allowed-tools:`, filename contains `skill`, or path is under `.claude/skills/`).
- Otherwise the **default doc-review lenses**.

**Review mode:** Custom `--lenses` if provided, else the **default review lenses**.

**Debate mode:** Custom `--personas` if provided, else the **default debate personas**.

See the reference tables at the end of this file for default sets.

## Step 3 — Round 1 (parallel, independent)

Launch one Task subagent per lens/persona **in a single assistant message with multiple `Task` tool calls**. Each subagent gets its own focused prompt (see mode-specific templates below). Each prompt must include:

- The lens/persona name + focus description
- The Pa' Cine project context block
- The full document (with `<<DOCUMENT_TEXT>>` substituted)
- The required response format
- "Respond in English."
- "Do not use Read, Grep, Glob, Bash, or any file/codebase tool. Work only from the text in this prompt."

Collect all responses. If a subagent returns empty, errors out, or is obviously off-topic: retry that one subagent once with a clarifying instruction. If it still fails, note it in the Reviewer Status section of the final report and continue with the rest. If fewer than 2 reviewers produced valid output after retries, **abort** — a council of one is not a council.

## Step 4 — Round 2 (parallel, cross-check)

Launch one Task subagent per lens/persona **in a single assistant message with multiple `Task` tool calls**. Each subagent receives its own Round 1 response plus all other reviewers' Round 1 responses (with the "Don't manufacture disagreement" instruction).

Skip Round 2 entirely for any reviewer that failed in Round 1 — its output doesn't exist to cross-check.

## Step 5 — Moderator synthesis

Launch a single moderator Task subagent with the full Round 1 + Round 2 transcript. The moderator produces the final verdict (see mode-specific moderator prompts below).

If the moderator returns a diplomatic or evasive synthesis, re-invoke with the instruction: *"Be direct. Name the strongest tension. Do not soften."*

## Step 6 — Present the full session

Output in this order:

1. **Mode** + input source + council members + input size
2. **Reviewer Status** — any failures, with error notes
3. **Round 1** — each reviewer's full response (labelled by lens/persona)
4. **Round 2** — each reviewer's cross-check (labelled)
5. **Moderator Synthesis**

Do not summarize or truncate Round 1 / Round 2 content — the user needs the raw transcript to judge quality.

---

## MODE: DOC-REVIEW

### Round 1 prompt template

```
You are a peer reviewer on an LLM council. Your ONLY lens is: <<LENS_NAME>>
Your focus: <<LENS_DESCRIPTION>>

Stay strictly within your lens. Do not comment on concerns outside your focus area.

## Project Context
Pa' Cine is a movie showtime website for Colombia. Backend: Django 5.2 / Celery / PostgreSQL (Supabase) / Python 3.13. Frontend: Next.js 15 / TypeScript / Tailwind / Supabase. The backend does not expose an API — the frontend queries Supabase directly. User-facing text is in Spanish; admin dashboard is in English.

## Document to Review
Document type: <<DOC_TYPE>>

<<DOCUMENT_TEXT>>

## Response Format

**Summary judgment**: One sentence — ready to ship / needs revision / needs major rework — from your lens only.

**Issues found**: Bullet list. Each item must cite a specific section, sentence, or line number from the document. Mark severity: critical / moderate / minor.

**What's missing**: Specific things the document should include but doesn't, from your lens.

**Strongest aspect**: One thing the document does well from your lens — only include if genuine, otherwise write "none notable".

## Rules
- Respond in English.
- Do not use Read, Grep, Glob, Bash, or any file/codebase tool. Work only from the text above.
- Every finding must be traceable to a specific quote or section of the document. Vague concerns are not acceptable.
```

### Round 2 prompt template

```
You are a peer reviewer on an LLM council. Your lens is: <<LENS_NAME>>

## Your Round 1 Analysis
<<OWN_ROUND_1>>

## Other Reviewers' Round 1 Analyses
<<OTHER_ROUND_1_LABELLED>>

## Your Task
Cross-check the other reviewers' findings through your lens:
- Do any of their issues have implications you didn't flag?
- Did anyone flag something in your area that you missed?
- Are any of their concerns overstated or incorrect from your lens's perspective?
- Do issues from different lenses combine to reveal a larger structural problem?

## Response Format

**Additions**: New issues your lens sees based on what others raised — or "none".

**Corrections**: Anything another reviewer got wrong from your lens's perspective — or "none".

**Compounding risks**: Issues that combine across lenses to create larger document problems — or "none".

## Rules
- Respond in English.
- Do not manufacture disagreement. If you have nothing genuine to add or correct, write "none". Invented objections degrade review quality.
- Do not use Read, Grep, Glob, Bash, or any file/codebase tool.
```

### Moderator prompt template

```
You are a neutral moderator synthesizing a multi-lens peer review of a <<DOC_TYPE>>. Your job is to give the author a clear, actionable review. Do not be diplomatic. Do not soften findings for comfort.

## Full Review Transcript
<<FULL_TRANSCRIPT>>

## Write the synthesis in this format:

## Peer Review: <<DOCUMENT_TITLE>>

### Verdict
One of: **Ship as-is** / **Ship with minor fixes** / **Revise and re-review** / **Major rework needed**. One sentence justification.

### Critical issues (must fix)
Numbered list. Each item: what's wrong, where (section/line), which lens flagged it, what "fixed" looks like.

### Moderate issues (should fix)
Same format.

### Minor issues (nice to fix)
Same format, grouped if similar.

### Structural feedback
Patterns across the review — organization, flow, consistency — not individual issues.

### What works well
Only if genuine. Specific sections or decisions reviewers called out as strong.

### Suggested revision checklist
Concrete ordered checklist the author can work through to address the findings, ordered by priority.

## Rules
- Respond in English.
- Cite specific sections/lines from the document for every Critical and Moderate finding.
- If reviewers contradicted each other, surface both sides — don't pick a winner silently.
```

---

## MODE: REVIEW

### Round 1 prompt template

```
You are a reviewer on an LLM council. Your ONLY lens is: <<LENS_NAME>>
Your focus: <<LENS_DESCRIPTION>>

Stay strictly within your lens. Do not comment on concerns outside your focus area.

## Project Context
Pa' Cine is a movie showtime website for Colombia. Backend: Django 5.2 / Celery / PostgreSQL (Supabase) / Python 3.13. Frontend: Next.js 15 / TypeScript / Tailwind / Supabase. Operational issues are logged to the `OperationalIssue` model. Scrapers run on Celery. The frontend queries Supabase directly — there is no Django REST API.

## Approach to Review
<<DOCUMENT_TEXT>>

## Response Format

**Summary judgment**: One sentence — sound / has issues / fundamentally flawed — from your lens only.

**Issues found**: Bullet list. Specific and concrete. Mark severity: critical / moderate / minor.

**Assumptions being made**: What must be true for this approach to work, from your lens.

**What's missing**: Specific things not addressed that should be.

## Rules
- Respond in English.
- Do not use Read, Grep, Glob, Bash, or any file/codebase tool. Work only from the text above.
- No vague concerns. Every finding must be concrete and specific.
- Do not praise what works unless directly relevant to a risk you're flagging.
```

### Round 2 prompt template

Same as doc-review Round 2 template above. Substitute `<<LENS_NAME>>`, `<<OWN_ROUND_1>>`, `<<OTHER_ROUND_1_LABELLED>>`.

### Moderator prompt template

```
You are a neutral technical moderator synthesizing an independent multi-lens review. Give the team a clear, actionable picture of risks. Do not be diplomatic.

## Full Review Transcript
<<FULL_TRANSCRIPT>>

## Write the synthesis in this format:

## Review Summary: <<TOPIC>>

### Overall assessment
One sentence: ready to proceed / proceed with changes / do not proceed — with the primary reason.

### Critical issues (must fix before proceeding)
Bullet list. Specific. Which lens flagged each.

### Moderate issues (should address, won't block)
Same format.

### Compounding risks
Issues that individually seem minor but combine into something bigger.

### What the approach gets right
Only if genuine.

### Recommended next steps
Concrete list: what to change, clarify, or validate. Reference Pa' Cine skills where appropriate (e.g., "run `s-pr-pre-push-review` before pushing", "use `s-requirements-review-codex` to cross-check against the codebase").

## Rules
- Respond in English.
- Surface contradictions rather than silently picking a winner.
```

---

## MODE: DEBATE

### Round 1 prompt template

```
You are: <<PERSONA_NAME>>
Character: <<PERSONA_DESCRIPTION>>

## Project Context
Pa' Cine is a movie showtime website for Colombia — Django backend, Next.js frontend, scrapers for multiple cinema chains. Internal tool, sole developer, no external customers.

## Question
<<DOCUMENT_TEXT>>

## Your Task
You are on a council debating this question. Argue purely from your character's point of view. Do not hedge. Do not try to represent other perspectives. Hold your position firmly.

## Response Format

**Position**: One sentence stance — for, against, or conditional (with clear condition).

**Reasoning**: 3-5 bullet points grounded in your character's values.

**Key concern**: The one thing you predict others will get wrong or overlook.

## Rules
- Respond in English.
- Stay in character.
- Do not use Read, Grep, Glob, Bash, or any file/codebase tool.
```

### Round 2 prompt template

```
You are: <<PERSONA_NAME>>
Character: <<PERSONA_DESCRIPTION>>

## Your Round 1 Position
<<OWN_ROUND_1>>

## Other Council Members' Positions
<<OTHER_ROUND_1_LABELLED>>

## Your Task
Write your rebuttal. Stay in character. Be direct — push back on specific points by name. Only shift your position if a specific argument would genuinely move someone like you.

## Response Format

**Updated position**: Same or refined — one sentence.

**Rebuttal**: 2-4 bullets responding to specific things others said, by name.

**What would change my mind**: One sentence — be honest and specific.

## Rules
- Respond in English.
- Do not manufacture new disagreements. If someone made a point you actually accept, say so.
- Stay in character.
```

### Moderator prompt template

```
You are a neutral technical moderator. Synthesize the debate below. Do not give a diplomatic non-answer. Be direct about what the council concluded and where they didn't.

## Full Debate Transcript
<<FULL_TRANSCRIPT>>

## Write the synthesis in this format:

## Council Verdict: <<TOPIC>>

### Points of genuine consensus
What everyone actually agreed on, despite different values.

### Core unresolved tension
The fundamental disagreement that wasn't resolved — one sharp sentence, not softened.

### Strongest argument FOR
Best argument in favor, with the persona who made it.

### Strongest argument AGAINST
Best argument against, with the persona who made it.

### Recommended path
Concrete recommendation a team could act on. If "it depends", give the exact decision tree — what condition maps to what choice.

### What the council left unanswered
1-3 specific questions that would need to be answered before deciding.

## Rules
- Respond in English.
- Name the tension. Do not soften it for comfort.
```

---

## Default lens and persona sets

### Default doc-review lenses

| Lens | Focus |
|---|---|
| Completeness & Gaps | Does the document cover everything it needs to? Missing sections, undefined terms, unstated dependencies, scenarios not addressed, missing success/acceptance criteria, absent failure modes/rollback plans. |
| Clarity & Ambiguity | Could two engineers reach different interpretations? Are requirements specific and testable, or vague? Weasel words ("should", "ideally", "as needed"). Logical structure and navigability. |
| Feasibility & Risk | Is this buildable on Pa' Cine's stack (Django + Celery + Next.js + Supabase)? Hidden technical risks, unrealistic scope, dependencies on external systems, blockers to execution. |
| Consistency & Contradictions | Does the document contradict itself? Do sections make conflicting assumptions? Are naming/terminology/formatting consistent? Do referenced items (other docs, APIs, models) actually exist? |

### Skill review lenses (auto-detected)

Used automatically when the input is detected as a Claude Code skill file. Replaces the default doc-review lenses.

| Lens | Focus |
|---|---|
| Prompt Effectiveness | Will Claude actually follow these instructions reliably? Are instructions specific enough for consistent output? Where is the model likely to hallucinate or misinterpret? Does the `description` follow Pa' Cine's "Use when..." convention and include matcher triggers? |
| Completeness & Edge Cases | Does the skill handle input variations? Error paths, fallback behaviors, parameter interactions, sensible defaults, explicit failure modes ("## If a step fails"). |
| Usability & Ergonomics | Easy to invoke correctly on first try? Intuitive parameter names? Useful output without post-processing? Examples per mode/feature? |
| Structural Quality | File organization, YAML front matter correctness, minimal `allowed-tools`, duplication with other Pa' Cine skills, naming conventions (`s-` / `s-pr-`). |

### Default review lenses

| Lens | Focus |
|---|---|
| Correctness & Edge Cases | Does the approach work? What inputs, states, or sequences could break it? What assumptions may not hold? |
| Operational Risk | What happens when this fails in production? How observable via BetterStack / Sentry / `OperationalIssue`? How reversible? What's the blast radius? |
| Developer Experience & Maintainability | Will the team understand this in 6 months? Does it fit Pa' Cine patterns (OOP services, constructor-injected dependencies, 40-line functions, 400-line classes)? Accidental complexity or hidden coupling? |
| Product & User Impact | Does this actually solve the user problem? Simpler alternatives? What does failure look like from the user's perspective? |

### Default debate personas

| Name | Character |
|---|---|
| Principal Engineer | Battle-hardened, has seen systems fail at scale. Values correctness, long-term operational cost, maintainability. Deeply skeptical of hype. Will not budge on "what happens when this breaks at 3am?" Does not care about delivery speed. |
| Staff Engineer | Pragmatic, focused on developer experience and cross-team impact. Cares whether the solution fits the humans who maintain it. Skeptical of both over-engineering and under-investing in abstractions. Does not care about business metrics. |
| Startup Founder | Has shipped 0-to-1 under extreme pressure. Values speed, simplicity, reversibility. Actively hostile to over-engineering. Does not care about long-term maintainability if the project won't exist to need it. |
| Product Manager | Anchors everything in user outcomes and business impact. Willing to kill technically elegant solutions that don't map to a user problem. Does not care about implementation details, only outcomes and measurability. |

---

## If a step fails

- **`--file` missing or unreadable** — report the error and stop. Do not fall back to inline text without explicit user confirmation.
- **`gh issue view` fails** — report the error, suggest `gh auth status`, and stop.
- **Input exceeds size guardrail** — warn or abort per Hard Rule #2. Do not try to truncate silently.
- **A Round 1 subagent returns empty, off-topic, or errors** — retry just that one subagent once with a clarifying instruction. If it still fails, note it in the Reviewer Status section of the final report and continue Round 2 with the remaining reviewers. If fewer than 2 reviewers have valid Round 1 output after retries, abort — a council of one is not a council.
- **Round 2 subagent fails after its Round 1 succeeded** — skip that reviewer's Round 2 output; moderator proceeds with partial data and notes the gap.
- **Moderator output is diplomatic or evasive** — re-invoke the moderator with: *"Be direct. Name the strongest tension. Do not soften."*

## Notes

- The single highest-value rule: **Round 1 and Round 2 subagents must each be dispatched in a single parallel Task call.** Sequential dispatch defeats the skill.
- Subagents have no repo access by design. The document must be self-contained. If reviewers need codebase verification, use `s-requirements-review-subagents` (or in addition).
- `--lenses` overrides defaults for both `doc-review` and `review` modes. `--personas` overrides defaults for `debate` mode only.
- When both `--file` and inline text are provided, inline text becomes supplementary instructions, not the primary input.
- Read the primary input **once** in Step 1 and paste it into every subagent prompt — do not have each subagent re-read the file.
