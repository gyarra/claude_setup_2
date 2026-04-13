---
name: Settings file placement
description: Rules for what goes in settings.json (shared) vs settings.local.json (personal)
type: feedback
---

Only machine-specific settings go in `settings.local.json`. Everything else goes in `settings.json`.

**`settings.local.json`** (gitignored) — only for:
- Absolute paths referencing the local machine (`/Users/yarray/...`)
- Model preference
- Denied MCP servers (personal preference)
- MCP server enablement config
- Environment variables for local debugging

**`settings.json`** (committed) — everything else:
- All bash command permissions (git, npm, pytest, ruff, etc.)
- MCP tool permissions (Sentry, Supabase, Chrome DevTools, Playwright)
- Skill permissions
- WebFetch, WebSearch
- git commit/push ask permissions
- SessionStart hooks
- Project-level file edit/write permissions using relative paths

**Why:** User wants settings.local.json to be minimal — only things that literally reference the local machine. All portable permissions belong in the shared file.

**How to apply:** Before putting something in settings.local.json, ask: "Does this contain an absolute path to this specific machine?" If no, it goes in settings.json.
