---
name: s-update-documentation
description: Use when completing work that introduced new files, patterns, or conventions, or when doing a periodic documentation consistency audit
---

# Update Documentation

Audit project documentation to ensure it reflects the current state of the codebase.

## When to Use

- After completing work that changed files, patterns, conventions, or architecture
- Periodic consistency audit
- When you suspect docs reference removed or renamed things

## Documents to Review

Read every document in these locations. Do not skip any.

### Primary Agent Instructions
- `.github/copilot-instructions.md` — primary project instructions for all agents
- `.github/copilot-review-instructions.md` — code review checklist for GitHub Copilot PR reviews
- `CLAUDE.md` (root) — session setup, pre-commit checks, environment notes
- `backend/CLAUDE.md` — backend session setup, key directories, testing notes

### Skills
- `.claude/skills/*/SKILL.md` — all skill files
- `docs/available_skills.md` — skill catalog and usage guide

### Memory
- `.claude/memory/MEMORY.md` — memory index
- `.claude/memory/*.md` — individual memory files (user, feedback, project, reference)

### Architecture and Reference Docs
- `docs/*.md` — architecture diagrams, guides, reference docs (excluding subdirectories)
- `docs/claude-docker.md` — Docker setup for running Claude Code in containers
- README.md
- frontend/README.md

## Documents to Ignore

Do not review these documents
### Requirements
- `docs/requirements/*.md` — old style requirements that will probably be deleted
- `docs/requirements/old_requirements/` — archived requirements


### Instructions
- `.github/instructions/` — Legacy instructions, some being migrated to skills

### Proposals
- `docs/proposals/` — design proposals

## Post-Work Review

After completing a task, check each document for:

1. **New files or directories** — mentioned in copilot-instructions or CLAUDE.md?
2. **New patterns or conventions** — documented in copilot-instructions?
3. **New models or schema changes** — reflected in architecture docs?
4. **New admin pages** — listed in the admin dashboard section of copilot-instructions?
5. **Changed behavior** — does any doc describe the old behavior?
6. **New or renamed skills** — update `docs/available_skills.md` (see Skill List Maintenance below)
7. **Memory accuracy** — do any memories in `.claude/memory/` reference files, patterns, or decisions that are now outdated? Update or remove stale memories.

Make the minimum edits needed. Do not rewrite docs that are already correct.

## Periodic Audit

For deeper review, verify docs against the actual codebase:

### Consistency Checks
- Do `CLAUDE.md` and `copilot-instructions.md` agree? (They should complement, not contradict)
- Do skills reference files and patterns that still exist?

### Accuracy Checks
- **Directory listings**: glob for mentioned directories and confirm they exist
- **Key files**: confirm referenced file paths exist
- **Stack versions**: check `package.json` and `pyproject.toml` for actual versions
- **Admin pages**: compare documented pages against `frontend/src/app/admin/`
- **Models**: compare documented models against `backend/movies_app/models/`
- **Services**: compare documented services against `backend/movies_app/services/`
- **Management commands**: compare against `backend/movies_app/management/commands/`

### Redundancy Checks

Each fact should live in **one** authoritative place. When the same information appears in 3+ files, consolidate: keep the authoritative version, replace duplicates with a pointer.

- **Pre-commit commands**: defined in `copilot-instructions.md`. `CLAUDE.md` can repeat for session setup. Skills should say "run pre-commit checks" not list every command.
- **Conventions and rules**: define once in `copilot-instructions.md`. Skills should reference, not restate.

### Skill List Maintenance

Compare `docs/available_skills.md` against the actual skills on disk:

1. **Project skills**: glob `.claude/skills/*/SKILL.md` and compare against the "Project Skills" section
2. **Added skills**: any skill directory not listed in the doc → add it to the appropriate category
3. **Removed skills**: any skill listed in the doc but missing from disk → remove from doc
4. **Renamed skills**: check that skill names and descriptions match their SKILL.md frontmatter
5. **Plugin skills**: only update if the user asks — these change with plugin updates and don't need routine auditing

### Memory Checks
- Read `.claude/memory/MEMORY.md` and each referenced memory file
- Do any memories reference files, functions, or patterns that no longer exist? Update or remove them.
- Do any project memories describe decisions or states that have changed? Update them.
- Are there new learnings from this session that should be saved as memories? (feedback, project context, references)

### Staleness Checks
- References to removed files, renamed patterns, or deprecated approaches
- "TODO" or "out of scope" notes that are no longer accurate
- Requirements in `old_requirements/` that are still referenced as active

## Output

After reviewing, report:
1. **Changes made** — each file edited and what changed
2. **Issues found but not fixed** — anything needing user input
3. **No changes needed** — confirm if docs are already accurate