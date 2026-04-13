---
name: s-plan-feature
description: Use when starting a new feature — reads requirements, clarifies with the user, and produces an implementation plan on the GitHub issue
---

# Plan Feature — Requirements Through Implementation Plan

Guides the planning phase before any code is written. Produces a reviewed implementation plan posted to the GitHub issue.

**At the very start, output this state tracker and update it (checking boxes) as each step completes:**

```
PLAN FEATURE STATE
[ ] Step 1: Read Requirements
[ ] Step 2: Clarify Before Coding
[ ] Step 3: Create Implementation Plan
```

## Step 1: Read Requirements

1.1 Read the GitHub issue for the feature (`gh issue view <NUMBER>`).
1.2 Identify ambiguities, missing details, or conflicting constraints.
1.3 List all external dependencies (APIs, services, models).
1.4 Check whether the issue has subtasks (checkboxes in the body). **If it does**, ask the user whether this plan should cover only the next unchecked subtask or all remaining subtasks. Record the decision — it determines the scope of everything in Steps 2 and 3. If the issue has no subtasks, skip this.
1.5 Output: `STEP 1 COMPLETE — issue #<number> read, <N> ambiguities found, <N> dependencies identified, scope: <next subtask | all remaining subtasks | whole issue>`

**Do not output the completion marker until 1.1–1.4 are done.**

If no issue exists, invoke the `s-requirements-writing` skill to create one first, then return to 1.1.

Then output the gate check:

```
STEP 1 GATE CHECK
[ ] GitHub issue has been read
[ ] Ambiguities and missing details are listed
[ ] External dependencies are identified
[ ] If subtasks exist, user has chosen whether to plan one or all
Proceeding to Step 2: YES/NO
```

## Step 2: Clarify Before Coding

**STOP. Do not write implementation code yet.**

2.1 Present questions to the user covering:
   - Unclear acceptance criteria
   - Edge cases not addressed
   - Integration points with existing code
   - Suggestions for improving the functionality
2.2 Wait for user responses.
2.3 Update the GitHub issue with clarifications (edit the body to keep requirements current).
2.4 Output: `STEP 2 COMPLETE — <N> questions answered, issue updated`

**Do not output the completion marker until 2.1–2.3 are done.**

Then output the gate check:

```
STEP 2 GATE CHECK
[ ] Questions were presented to the user
[ ] User responded to all questions
[ ] GitHub issue body updated with clarifications
Proceeding to Step 3: YES/NO
```

## Step 3: Create Implementation Plan

**REQUIRED SUB-SKILL:** Use `superpowers:writing-plans` for complex features (3+ subtasks or significant architectural decisions).

3.1 Write the implementation plan following the format below.
3.2 Count the files under **Files to Create** + **Files to Modify**. **If the count exceeds 8**, stop and recommend splitting this plan into separate subtasks — each one a future PR that edits or creates at most 8 files. Propose a concrete split to the user (which files go in which PR) and get their confirmation before continuing. If the split produces new subtasks that don't yet exist on the issue, add them to the issue body. Then either narrow this plan to one of the new subtasks or return to Step 1 to pick one.
3.3 Post the plan as a subtask/comment on the GitHub issue.
3.4 Wait for user feedback on the plan.
3.5 Output: `STEP 3 COMPLETE — plan posted to issue #<number>, user approved`

**Do not output the completion marker until 3.1–3.4 are done.**

### PR Size Limit

**Each PR must edit or create no more than 8 files.** This keeps PRs reviewable and focused. If a single logical unit of work genuinely requires more than 8 files, that is a signal the unit is too large and should be broken into subtasks — not a signal to waive the limit. Count tests and migrations against the 8.

### Implementation Plan Format

```markdown
## Implementation Plan

### Summary
One paragraph describing what will be built.

### Files to Create
- path/to/new_file.py: purpose

### Files to Modify
- path/to/existing.py: what changes

### Database Changes
- New models or fields
- Migration requirements

### External API Calls
- Endpoint, method, expected response

### Task Sequence
1. Step with acceptance criteria
2. Step with acceptance criteria

### Test Plan
- Unit tests: list scenarios
- Integration tests: list scenarios

### Diagrams
- For complex features: Create Mermaid diagram in `docs/diagrams/`
- If modifying existing flows: List diagrams to update

### Open Questions
- Any remaining uncertainties
```

Then output the final gate check:

```
STEP 3 GATE CHECK
[ ] Implementation plan follows the required format
[ ] File count (created + modified) is ≤ 8, or the plan has been split
[ ] Plan is posted on the GitHub issue
[ ] User has reviewed and approved the plan
Planning complete: YES/NO
```

**Planning is done. To implement, invoke the `s-implement-plan` skill.**
