# Running Claude Code in Docker

Claude Code can be run inside a Docker container to give it an isolated, reproducible environment with all required tools pre-installed: Node.js, Python, `uv`, `gh`, Chromium (for browser-based frontend review), and Claude Code itself.

## Files

- `Dockerfile-claude` — the container image definition
- `docker/init.sh` — init script baked into the image and invoked by the `docker run` commands
- `docker/mcp.json` — MCP configuration baked into the image (tools and server settings)

## Build the Image

Run this once (and again whenever `Dockerfile-claude` changes):

```bash
docker build -f Dockerfile-claude -t claude-sandbox .
```

## Running a Container

Each container is fully isolated — no workspace mount, no access to your host filesystem. Claude clones the repo inside the container using the mounted `gh` credentials, does its work, and pushes to origin. When the container exits, nothing is left on the host.

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

The `--dangerously-skip-permissions` flag is safe here because the container is sandboxed — it can't access your host filesystem, other containers, or anything outside its own isolated environment.

### Running Multiple Containers in Parallel

You can spin up multiple containers working on different issues simultaneously. Each one clones the repo independently, creates its own feature branch, and pushes when done. They share nothing except the remote repository.

```bash
# Terminal 1 — issue #42
docker run -it --rm \
  -v ~/.claude:/tmp/.claude.seed:ro \
  -v ~/.claude.json:/tmp/.claude.json.seed:ro \
  -v ~/.config/gh:/home/claude/.config/gh:ro \
  --env-file backend/.env \
  --env-file frontend/.env.local \
  claude-sandbox \
  sh -c '/home/claude/init.sh claude --dangerously-skip-permissions \
    -p "Clone the repo, then implement issue #42 using s-ship-feature"'

# Terminal 2 — issue #43 (same command, different issue)
docker run -it --rm ...same flags... \
  sh -c '/home/claude/init.sh claude --dangerously-skip-permissions \
    -p "Clone the repo, then implement issue #43 using s-ship-feature"'
```


## How Startup Works

There is no entrypoint script. Docker runs the command you pass directly (e.g. `claude --dangerously-skip-permissions`).

### Chromium (on-demand)

Chromium is installed in the image but **not started at container startup**. When Claude needs browser-based testing, it launches Chromium itself via the Chrome DevTools MCP configuration in `docker/mcp.json`.

## Git Authentication

`init.sh` configures git to use the mounted `gh` credentials for HTTPS authentication via a Git credential helper that delegates to `gh auth`, so `git clone`, `git pull`, and `git push` all work without additional setup.

## Volumes Explained

| Volume | Purpose |
|--------|---------|
| `~/.claude:/tmp/.claude.seed:ro` | Claude settings seed — copied into the container at startup |
| `~/.claude.json:/tmp/.claude.json.seed:ro` | Claude config seed — same copy-on-start approach |
| `~/.config/gh:/home/claude/.config/gh:ro` | GitHub CLI credentials |

> **Note:** Host config is mounted read-only to `/tmp/` seed paths and copied at startup. This way multiple containers each get their own writable copies without conflicting.

## Environment Variables

Both `--env-file` flags are read by Docker from the **host** filesystem at container startup.

```
--env-file backend/.env         # Django settings, DB URL, API keys, etc.
--env-file frontend/.env.local  # Next.js public vars, API URLs, etc.
```

## What's Installed in the Image

| Tool | Purpose |
|------|---------|
| Node.js 20 | Runs Claude Code and frontend tooling |
| `@anthropic-ai/claude-code` | Claude Code CLI |
| `uv` | Python package manager for backend |
| `python3` | Required for Django backend commands |
| `gh` | GitHub CLI for PR creation, issue management |
| `git` | Version control |
| `jq` | JSON processing (used by hooks) |
| `chromium` | Headless browser for Chrome DevTools MCP |
| `curl` | HTTP requests |

## Initial instructions for Claude in Docker

Copy and paste the following into the Claude prompt after the container starts. Replace the repo URL and issue URL with the actual task.

---
### Session Start

You are running in a Docker container. It may not be configured perfectly. Follow these rules for the entire session:

**Track environment issues.** If anything is unclear, missing, or broken in the container environment (missing tools, wrong versions, permission errors, missing env vars, unexpected behavior), note it. If the issue blocks your work, stop and tell me immediately. If it doesn't block you but was confusing or required a workaround, keep a running list.

**Track skill issues.** `.claude/skills/s-ship-feature/SKILL.md` is a template skill that orchestrates other skills in sequence (requirements, planning, implementation, pre-push review, PR creation, and review rounds). As you follow each skill, note any confusing instructions, missing context, contradictions between skills, or steps that didn't work well. At session end, report specific suggestions for improving the skills — what was unclear, what should be added, and what should be removed or reworded.

Clone the repo:
```
gh repo clone [GITHUB_USER]/[REPO_NAME]
```

After the repo is checked out, use `.claude/skills/s-ship-feature/SKILL.md` to implement https://github.com/[GITHUB_USER]/[REPO_NAME]/issues/[ISSUE_NUMBER]

---
### Session End

Use the end-session skill (`/s-end-session`) to end the session.

Also report:
   - Every environment issue you encountered, even minor ones
   - What you did to work around each issue
   - Specific suggestions for updating `docs/claude-docker.md`, `Dockerfile-claude`, or `docker/init.sh` to prevent the issue in future sessions
