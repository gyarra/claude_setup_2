# AI Tooling Starter Kit

A ready-to-use scaffolding for AI-assisted development workflows with Claude Code, GitHub Copilot, and cross-model review (Codex, Gemini). Designed for Django + Next.js projects but adaptable to other stacks.

## What's Included

### `.claude/` — Claude Code Configuration

| Directory | Purpose |
|-----------|---------|
| `skills/` | 20 reusable skills covering the full development lifecycle: planning, implementation, code review, PR management, visual testing, documentation, and maintenance |
| `agents/` | Subagent definitions for cross-model review (Codex, Gemini) |
| `memory/` | Persistent memory system with index (`MEMORY.md`) and example entries |
| `settings.json` | Permission rules and session startup hooks |

**Key skills:**
- `s-ship-feature` — Orchestrates the full cycle: plan → implement → visual review → self-review → PR → remote review → feedback
- `s-plan-feature` — Requirements clarification and implementation planning
- `s-implement-plan` — Code through verification
- `s-pr-pre-push-review` — Self-review before pushing
- `s-pr-review` — Review a PR with inline comments
- `s-pr-respond-to-feedback` — Process and respond to review comments
- `s-frontend-visual-review` — Browser-based visual testing via Playwright/Chrome DevTools
- `s-requirements-review-council` — Multi-agent peer review using Claude subagents
- `s-requirements-review-subagents` — Cross-model review (Gemini + Claude)
- `playwright-cli` — Browser automation framework with 9 reference guides

### `.github/` — GitHub Integration

| File/Directory | Purpose |
|---------------|---------|
| `copilot-instructions.md` | Project-wide coding conventions (template with `[PLACEHOLDERS]`) |
| `copilot-review-instructions.md` | Code review checklist for Copilot and AI reviewers |
| `agents/pr_push_agent.md` | GitHub agent for PR workflow automation |
| `instructions/` | How-to guides for cloud tools (Chrome DevTools MCP, code review) |
| `workflows/` | CI/CD workflows: lint, typecheck, test, build, Claude review, Codex review |

### Root Files

| File | Purpose |
|------|---------|
| `CLAUDE.md` | Top-level instructions Claude reads at session start |
| `backend/CLAUDE.md` | Backend-specific session setup and conventions |
| `frontend/CLAUDE.md` | Frontend-specific session setup and conventions |
| `Dockerfile-claude` | Container image for isolated Claude Code sessions |
| `.mcp.json` | MCP server configuration (Chrome DevTools) |

### `docker/` — Container Support

| File | Purpose |
|------|---------|
| `init.sh` | Container initialization (config seeding, git auth, env var cleanup) |
| `mcp.json` | Docker-specific MCP configuration (headless Chromium) |

### `docs/` — Documentation

| File | Purpose |
|------|---------|
| `claude-docker.md` | Complete guide to running Claude Code in Docker (3 run modes, volumes, env vars) |
| `architecture.md` | System architecture template |
| `architecture_for_agents.md` | Architecture reference optimized for AI agent consumption |

## How to Use

### 1. Fork or copy this repo

```bash
gh repo clone gyarra/claude_setup_april_12 my-project-ai-setup
```

### 2. Find and replace placeholders

Search for `[PLACEHOLDER]` tokens throughout the codebase and replace with your project's values:

| Token | Replace with | Example |
|-------|-------------|---------|
| `[PROJECT_NAME]` | Your project name | `my-saas-app` |
| `[PROJECT_DESCRIPTION]` | One-line description | `SaaS platform for invoice management` |
| `[APP_NAME]` | Django app name | `invoices_app` |
| `[BACKEND_FRAMEWORK]` | Backend framework | `Django 5.2` |
| `[FRONTEND_FRAMEWORK]` | Frontend framework | `Next.js 15` |
| `[DATABASE_CLIENT]` | Database client | `Supabase` |
| `[USER_LANGUAGE]` | UI language | `English` |
| `[TIMEZONE]` | Project timezone | `America/New_York` |
| `[GIT_EMAIL]` | Git commit email | `user@example.com` |
| `[GIT_NAME]` | Git commit name | `Your Name` |
| `[GITHUB_USER]` | GitHub username | `myorg` |
| `[REPO_NAME]` | Repository name | `my-project` |

### 3. Customize for your stack

**Start with these files** (most impact, least effort):
1. `CLAUDE.md` — Set up your project overview and pre-commit checks
2. `.github/copilot-instructions.md` — Fill in your conventions, models, and services
3. `.claude/settings.json` — Adjust session hooks for your project's setup commands
4. `docker/init.sh` — Set your git identity

**Then adapt:**
- `backend/CLAUDE.md` and `frontend/CLAUDE.md` — Your directory structure
- `.github/copilot-review-instructions.md` — Your review priorities
- `docs/architecture_for_agents.md` — Your system's architecture

**Skills work out of the box** — the 20 skills in `.claude/skills/` are generic workflow orchestrators. They reference each other by name, so keep the `s-` prefix naming convention.

### 4. Add project-specific skills

Create new skills in `.claude/skills/` for domain-specific workflows. Follow the naming convention:
- `s-` prefix for all skills
- `s-pr-` prefix for PR-related skills
- Include a `description:` in the YAML frontmatter starting with "Use when..."

## Requirements

- [Claude Code](https://docs.anthropic.com/en/docs/claude-code) CLI installed
- GitHub CLI (`gh`) for issue/PR management
- Docker (optional, for containerized sessions)
- Node.js 20+ and Python 3.13+ (for the Django + Next.js stack)
