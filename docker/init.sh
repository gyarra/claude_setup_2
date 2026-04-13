#!/bin/bash
set -euo pipefail

# Copy host config seeds into writable locations
rm -rf /home/claude/.claude
mkdir -p /home/claude/.claude
cp -a /tmp/.claude.seed/. /home/claude/.claude/
cp /tmp/.claude.json.seed /home/claude/.claude.json

# Inject Docker-specific MCP servers into .claude.json (merge, don't replace)
CLAUDE_JSON=/home/claude/.claude.json
MCP=/home/claude/mcp.json
if [ -f "$CLAUDE_JSON" ] && [ -f "$MCP" ]; then
  jq --slurpfile mcp "$MCP" '.mcpServers = ((.mcpServers // {}) + ($mcp[0].servers // {}))' "$CLAUDE_JSON" > "${CLAUDE_JSON}.tmp" \
    && mv "${CLAUDE_JSON}.tmp" "$CLAUDE_JSON"
fi

# Strip surrounding quotes from env vars.
# Docker --env-file preserves literal quotes (KEY="value" stores the quotes
# in the value). Next.js and Supabase reject quoted URLs/keys.
for var in NEXT_PUBLIC_SUPABASE_URL NEXT_PUBLIC_SUPABASE_ANON_KEY \
           SUPABASE_SERVICE_ROLE_KEY DATABASE_URL DJANGO_SECRET_KEY; do
  val="${!var:-}"
  if [[ "$val" == \"*\" ]]; then
    export "$var"="${val:1:-1}"
  fi
done

# Set git identity — replace with your own
git config --global user.email "[GIT_EMAIL]"
git config --global user.name "[GIT_NAME]"

# Configure git to use gh for HTTPS authentication.
# `git push` and `git pull` fail without credentials in Docker.
# Uses GitHub CLI's credential helper instead of embedding tokens in git config.
if command -v gh >/dev/null 2>&1; then
  if gh auth status >/dev/null 2>&1; then
    gh auth setup-git >/dev/null 2>&1 || true
  fi
fi

exec "$@"
