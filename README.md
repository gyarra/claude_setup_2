# AI Tooling Starter Kit

A ready-to-use scaffolding for AI-assisted development workflows with Claude Code, GitHub Copilot, and cross-model review (Codex, Gemini). Designed for Django + Next.js projects but adaptable to other stacks.

## What's Included

### `.claude/` — Claude Code Configuration

| Directory | Purpose |
|-----------|---------|
| `skills/` | 20 reusable skills covering the full development lifecycle: planning, implementation, code review, PR management, visual testing, documentation, and maintenance |
| `agents/` | Subagent definitions for cross-model review — see [Cross-Model Review Agents](#cross-model-review-agents) |
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

See [Running Claude Code in Docker](#running-claude-code-in-docker) below for the full setup guide.

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

## Running Claude Code in Docker

Docker lets you run Claude Code in fully isolated containers. Each container gets its own filesystem, git working tree, and environment — so **multiple containers can work on different features simultaneously**, each on its own branch, without interfering with each other or your local workspace.

### Why Docker?

- **Isolation** — Containers can't touch your host filesystem (unless you mount it). Since they're sandboxed, you can safely run Claude with `--dangerously-skip-permissions`, letting it execute commands without interactive approval prompts. This enables fully autonomous workflows: point a container at a GitHub issue and let it plan, implement, test, and open a PR without intervention.
- **Parallelism** — Spin up 3 containers working on 3 different issues at the same time. Each clones the repo independently, creates its own feature branch, and pushes when done. They share nothing except the remote repository.
- **Reproducibility** — Every container starts from the same image with identical tools and versions. No "works on my machine" issues.

### Quick Start

Build the image once:

```bash
docker build -f Dockerfile-claude -t claude-sandbox .
```

Run an isolated session (the container clones the repo, does its work, and pushes):

```bash
docker run -it --rm \
  -v ~/.claude:/tmp/.claude.seed:ro \
  -v ~/.claude.json:/tmp/.claude.json.seed:ro \
  -v ~/.config/gh:/home/claude/.config/gh:ro \
  --env-file backend/.env \
  --env-file frontend/.env.local \
  claude-sandbox \
  sh -c '/home/claude/init.sh claude --dangerously-skip-permissions'
```

### Running Multiple Containers in Parallel

Each container is fully independent. To work on three issues simultaneously:

```bash
# Terminal 1 — working on issue #42
docker run -it --rm \
  -v ~/.claude:/tmp/.claude.seed:ro \
  -v ~/.claude.json:/tmp/.claude.json.seed:ro \
  -v ~/.config/gh:/home/claude/.config/gh:ro \
  --env-file backend/.env \
  --env-file frontend/.env.local \
  claude-sandbox \
  sh -c '/home/claude/init.sh claude --dangerously-skip-permissions \
    -p "Clone the repo, then implement issue #42 using s-ship-feature"'

# Terminal 2 — working on issue #43
docker run -it --rm \
  -v ~/.claude:/tmp/.claude.seed:ro \
  ...same flags... \
  sh -c '/home/claude/init.sh claude --dangerously-skip-permissions \
    -p "Clone the repo, then implement issue #43 using s-ship-feature"'

# Terminal 3 — working on issue #44
docker run -it --rm \
  ...same pattern...
```

Each container will:
1. Clone the repo fresh from GitHub
2. Create its own feature branch
3. Implement, test, and push
4. Open a PR

No conflicts — they're completely isolated from each other.

### Run Modes

| Mode | When to use | Host impact |
|------|------------|-------------|
| **Isolated** (no mount) | Autonomous tasks — "implement this issue and open a PR" | None — container clones and pushes independently |
| **Shared workspace** (`-v $(pwd):/workspace`) | Interactive/collaborative work where you want to see changes live | Direct — changes appear on your host immediately |
| **Git worktree** (`-v ../worktree:/workspace`) | Autonomous tasks without cloning, using your local git history | Minimal — separate branch directory, main tree untouched |

See [`docs/claude-docker.md`](docs/claude-docker.md) for detailed volume mounts, environment variables, and troubleshooting.

## Cross-Model Review Agents

The `.claude/agents/` directory contains two subagent definitions that Claude can invoke during code review to get a second opinion from a different AI model:

- **`codex-reviewer.md`** — Sends code to OpenAI's Codex for an independent review. Claude spawns this as a read-only subprocess, collects the feedback, and incorporates it into its own review.
- **`gemini-reviewer.md`** — Same pattern but using Google's Gemini. Requires a `GEMINI_API_KEY` environment variable.

These are used by the `s-requirements-review-subagents` and `s-requirements-review-council` skills to get cross-model perspectives on requirements and implementation plans. Claude orchestrates the review — the subagents only read code and return feedback; they never write files or execute commands.

## Requirements

- [Claude Code](https://docs.anthropic.com/en/docs/claude-code) CLI installed
- GitHub CLI (`gh`) for issue/PR management
- Docker (optional but recommended for isolated/parallel sessions)
- Node.js 20+ and Python 3.13+ (for the Django + Next.js stack)
