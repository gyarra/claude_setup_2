---
name: s-frontend-visual-review
description: Use when reviewing frontend work visually — after implementing UI changes, before pushing a PR, or when asked to check how a page looks and behaves. Drives a real browser via Playwright CLI (default) with Chrome DevTools MCP escalation for performance, accessibility, or network deep-dives.
---

# Frontend Visual Review

Review Pa' Cine frontend work by driving a real browser. This skill covers **what** to check and the Pa' Cine-specific conventions to enforce. It defers **how** to drive the browser to specialized skills.

---

## Pick the Tool First

Before touching the browser, invoke `s-browser-tools-router` to choose the right tool. The default for this skill is **Playwright CLI** — it's the most token-efficient and handles almost all visual/functional review. Escalate only when the task needs something Playwright CLI cannot do.

| Task | Tool | Skill to follow |
|------|------|-----------------|
| Navigate, snapshot, click, fill, check console/network list, screenshot, responsive check | Playwright CLI | `playwright-cli` |
| Lighthouse audit, Core Web Vitals (LCP/CLS/INP), performance traces, CPU flame charts | Chrome DevTools MCP | `chrome-devtools-mcp:debug-optimize-lcp`, `chrome-devtools-mcp:chrome-devtools` |
| Deep accessibility audit (WCAG, detailed a11y checks beyond the accessibility tree) | Chrome DevTools MCP | `chrome-devtools-mcp:a11y-debugging` |
| Network response **bodies/headers**, HAR export, WebSocket frame inspection | Chrome DevTools MCP | `chrome-devtools-mcp:chrome-devtools` |
| CSS cascade / computed styles / layout debugging | Chrome DevTools MCP | `chrome-devtools-mcp:troubleshooting` |
| Recording video of a bug repro, Playwright action trace, auth state reuse, multiple concurrent browsers | Playwright CLI | `playwright-cli` (see references: `video-recording.md`, `tracing.md`, `storage-state.md`, `session-management.md`) |

> **Rule of thumb**: Playwright CLI for *"does this work and look right?"*, Chrome DevTools for *"why is this slow/broken/inaccessible?"*.

---

## Prerequisites

### Dev server must be running
Use `s-run-dev-servers` if not already up. Frontend typically runs at `http://localhost:3000`.

### Playwright CLI installed
```bash
playwright-cli --version
```
If missing, see README: `npm install -g @playwright/cli@latest && playwright-cli install-browser && playwright-cli install --skills`.

### Chrome DevTools MCP (for performance/a11y escalation)
Provided by the `chrome-devtools-mcp` plugin. No project-level setup needed.

---

## Review Workflow (Playwright CLI default)

### Step 1: Figure out what to review

Derive routes from `git diff` — map changed files under `frontend/src/app/` to their URLs. If you changed `frontend/src/app/pelicula/[slug]/page.tsx`, review a real movie slug URL.

### Step 2: Navigate and snapshot

```bash
playwright-cli open http://localhost:3000/pelicula/[slug]
playwright-cli snapshot
```

Review the accessibility tree snapshot for:
- **Expected structure**: headings, sections, interactive elements all present
- **Real data rendering**: no `undefined`, `null`, empty strings, or placeholder values leaking through
- **Proper ARIA roles**: buttons are buttons, links are links
- **Alt text on images, labels on form inputs**
- **User-facing text is in Spanish** (Pa' Cine convention; admin UI in English)

### Step 3: Visual screenshot

```bash
playwright-cli screenshot --filename=desktop.png
```

Check:
- Spacing, alignment, no element overlap
- Colors consistent with the **zinc / red / amber / blue flat design** system
- Heading hierarchy is readable
- Empty states are handled gracefully (no raw "no data" dumps)
- No broken posters or theater logos (Supabase Storage URL freshness)

### Step 4: Responsive check

```bash
playwright-cli resize 375 812
playwright-cli screenshot --filename=mobile.png
playwright-cli resize 1280 800
```

Check: layout stacks cleanly on mobile, no horizontal overflow, touch targets ≥ 44px.

### Step 5: Console errors

```bash
playwright-cli console
```

**Any console error is a finding.** Don't treat warnings as noise. Common sources in this stack:
- React hydration mismatches (Server vs. Client Component divergence)
- Failed Supabase queries (RLS blocking, wrong `.select()` columns, missing env vars)
- Missing `key` props in list renders
- Next.js router warnings

### Step 6: Network request list

```bash
playwright-cli network
```

Check for:
- Failed Supabase queries (4xx/5xx)
- Queries that look slow or duplicated
- Missing expected requests (a component that should query but isn't)

> **Note**: Playwright CLI shows the request list only. For **response bodies, headers, timing waterfalls, or HAR export**, escalate to Chrome DevTools MCP (`chrome-devtools-mcp:chrome-devtools` skill).

### Step 7: Interaction testing

Use refs from the snapshot (`e3`, `e15`, etc.) or semantic locators.

**Forms:**
```bash
playwright-cli snapshot                    # find refs
playwright-cli fill e3 "valid value"
playwright-cli click e7                    # submit
playwright-cli snapshot                    # verify success state
```
Verify: validation fires, success feedback appears, error states render.

**Navigation:** click through main navigation, snapshot after each click to verify route loads.

**Dynamic UI:** open dropdowns/modals/tooltips, snapshot to verify rendering.

**Authenticated pages** (`/admin/*`):
1. Navigate to `/auth/login`.
2. Fill credentials, click login, wait for redirect.
3. Save the session for later runs: `playwright-cli state-save tests/.auth/admin.json`.
4. Re-use via `playwright-cli open --config=...` or `state-load` in subsequent sessions.
5. Verify the admin layout gate blocks unauthenticated access (open a fresh session without loaded state, hit an `/admin/*` URL, expect redirect).

### Step 8: Close

```bash
playwright-cli close
```

---

## Escalation Patterns

### Page is slow → Chrome DevTools MCP

Switch to `chrome-devtools-mcp:debug-optimize-lcp` for:
- Lighthouse audit with Core Web Vitals (LCP, CLS, INP)
- CPU flame charts to find render bottlenecks
- Network waterfall with timing breakdowns
- Identifying which resource is blocking the largest contentful paint

### Accessibility concern beyond the snapshot → Chrome DevTools MCP

Playwright CLI's snapshot gives you the accessibility tree structure. For real WCAG validation, contrast checks, focus order problems, or screen-reader nuances, switch to `chrome-devtools-mcp:a11y-debugging`.

### Supabase query failing and you need the response body → Chrome DevTools MCP

Playwright CLI `network` tells you a request failed. To see the actual Postgres error message in the response body, switch to `chrome-devtools-mcp:chrome-devtools` and capture the response.

### Bug repro for an issue report → Playwright CLI video

```bash
playwright-cli video-start repro.webm
# ...reproduce the bug...
playwright-cli video-stop
```
Attach `repro.webm` to the issue. See `playwright-cli` skill `references/video-recording.md` for chapter markers.

### Need to save a Playwright trace for step-through debugging → Playwright CLI tracing

```bash
playwright-cli tracing-start
# ...perform the flow...
playwright-cli tracing-stop
# view with: npx playwright show-trace trace.zip
```
See `references/tracing.md` in the playwright-cli skill.

---

## Review Report Format

```markdown
## Frontend Review: [Page/Feature Name]

**URL**: http://localhost:3000/...
**Branch**: feature/...
**Tools used**: Playwright CLI [+ Chrome DevTools MCP if escalated]

### Visual
- [ ] Desktop layout correct (1280x800)
- [ ] Mobile layout correct (375x812)
- [ ] Colors match zinc/red/amber/blue flat design system
- [ ] Empty / loading / error states handled
- [ ] No broken images or posters
- [ ] User-facing text in Spanish (admin UI in English)

### Console
- [ ] No errors
- [ ] No unhandled warnings

### Network
- [ ] All Supabase queries succeed
- [ ] No obviously slow queries
- [ ] No duplicate or missing requests

### Interactions
- [ ] Forms validate and submit correctly
- [ ] Navigation routes correctly
- [ ] Dynamic UI elements open/close properly
- [ ] Auth gates block unauthenticated access to `/admin/*`

### Performance (if escalated)
- [ ] LCP < 2.5s
- [ ] CLS < 0.1
- [ ] No critical Lighthouse warnings

### Accessibility (if escalated)
- [ ] No critical WCAG violations
- [ ] Focus order sensible
- [ ] Color contrast passes

### Issues Found
1. **[critical|major|minor]** — Description — evidence (screenshot path / console output / trace link) — suggested fix

### Passed
- What was confirmed working
```

---

## Common Findings

| Symptom | Likely Cause |
|---------|-------------|
| Blank page, no errors | Missing `"use client"` on a component using hooks |
| Hydration mismatch warning | Server/client render different content (dates, auth state) |
| Supabase query returns empty | Wrong table name, RLS policy blocking, missing `.select()` columns |
| Layout broken on mobile only | Missing responsive classes, fixed widths instead of flex/grid |
| Flash of unstyled content | Font loading issue; missing `next/font` setup |
| Console error about missing key | List rendering without `key` prop |
| Admin page shows unauthorized | Not logged in, or user not in `admin_users` table |
| Images not loading | Supabase Storage URL expired, or TMDB poster path incorrect |
| Playwright can't find element | Element not in accessibility tree — add `role` or `data-testid` |
| LCP > 4s | Large hero image not optimized, render-blocking script, slow Supabase query on initial render |
| CLS > 0.25 | Images without dimensions, fonts causing reflow, late-injected ads/banners |

---

## Rules

- **Always start with `s-browser-tools-router`.** Don't default to MCP out of habit. Playwright CLI handles most tasks with a fraction of the token cost.
- **Use semantic locators** (`getByRole`, `getByLabel`, `getByText`) or snapshot refs. Avoid raw CSS selectors — they break on refactors.
- **Never use `waitForTimeout`.** If you're waiting, wait for a condition (URL, selector, load state), not a duration.
- **Always check console errors.** Even if the page looks fine visually.
- **Don't skip mobile.** Resize to 375x812 every review — it's the most common miss.
- **Report with evidence.** Screenshots, console output, network dumps — not just "looks wrong."
- **Escalate to Chrome DevTools MCP** when you need to understand *why* something is slow/broken, not just *that* it is.
- **If you find a bug during review, capture a video or trace** so the fix PR has the repro attached.
