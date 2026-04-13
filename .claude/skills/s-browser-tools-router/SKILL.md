---
name: s-browser-tools-router
description: Decides which browser tool to use — Playwright CLI, Playwright MCP, or Chrome DevTools — based on the task at hand. Use this skill BEFORE starting any browser automation, frontend testing, web debugging, performance profiling, network inspection, site analysis, scraping recon, or accessibility auditing. Triggers on any mention of testing a web page, debugging frontend issues, inspecting network traffic, measuring performance, running Lighthouse, analyzing a website's structure, building a scraper, checking console errors, profiling memory, or automating browser interactions. Even if the user just says "test my app" or "check this page" or "debug the UI" — use this skill first to pick the right tool. Also triggers when the user mentions playwright, devtools, or browser automation without specifying which tool to use.
---

# Browser Tools Router

Pick the right browser tool for the job. Read this skill first, select the tool, then follow the instructions for that tool.

## The Three Tools

### Playwright CLI (`@playwright/cli`)
- **What it is**: Shell commands for browser automation. Token-efficient — saves snapshots to disk instead of injecting them into context.
- **Install**: `npm install -g @playwright/cli@latest && playwright-cli install-browser && playwright-cli install --skills`
- **Key commands**: `playwright-cli open`, `snapshot`, `click e15`, `fill e3 "text"`, `screenshot`, `console`, `network`, `close`
- **Context cost**: ~27,000 tokens for a typical multi-step session (vs ~114,000 for MCP)

### Playwright MCP (`@playwright/mcp`)
- **What it is**: MCP server exposing Playwright as structured tools. Returns full accessibility trees and page state inline.
- **Install**: `claude mcp add playwright npx @playwright/mcp@latest`
- **Key tools**: `browser_navigate`, `browser_click`, `browser_snapshot`, `browser_type`
- **Context cost**: High. Full schema loaded on connection + verbose responses every call.

### Chrome DevTools (`chrome-devtools-mcp`)
- **What it is**: Full Chrome DevTools Protocol access — performance traces, Lighthouse, network detail, memory profiling, accessibility audits, JS debugging.
- **Install**: `claude mcp add chrome-devtools --scope user npx chrome-devtools-mcp@latest` or install as plugin: `/plugin marketplace add ChromeDevTools/chrome-devtools-mcp`
- **Key capabilities**: Performance traces, Lighthouse audits, Core Web Vitals, network request/response bodies, console with source-mapped stacks, memory snapshots, device emulation, HAR export
- **Context cost**: Moderate to high depending on tool used.

> **Note on Claude Chrome Integration (beta):** Claude Code has a native Chrome bridge (`claude --chrome` or `/chrome`) that shares your browser login state. However, Chrome DevTools MCP can also connect to your running Chrome instance (via remote debugging port or Chrome 144+ automatic connection), providing the same auth-sharing benefit plus full profiling and debugging. Use Chrome DevTools instead.

---

## Decision Tree

Follow this top-to-bottom. Stop at the first match.

### 1. What are you trying to do?

**Performance profiling, Lighthouse, Core Web Vitals, or load time analysis?**
→ **Chrome DevTools**
Playwright CLI has no performance profiling. Only DevTools can record CPU flame charts, run Lighthouse, measure LCP/CLS/INP, or capture performance traces.

**Network deep-dive — need response bodies, headers, timing waterfall, or HAR export?**
→ **Chrome DevTools**
Playwright CLI `network` gives you a request list (URL, status, method). DevTools gives you full request/response headers, response bodies, timing breakdown (DNS, TCP, TLS, TTFB), and initiator chains.

**Memory profiling — heap snapshots, allocation timelines, leak detection?**
→ **Chrome DevTools**
No equivalent in Playwright CLI or MCP.

**CSS debugging — inspecting cascade, specificity, computed styles, box model?**
→ **Chrome DevTools** (or manual browser DevTools)
Playwright CLI `snapshot` gives you the accessibility tree. `eval` can query computed styles via JS. But interactive CSS cascade inspection is DevTools-only.

**Accessibility audit (WCAG compliance, a11y validation)?**
→ **Chrome DevTools**
Can run Lighthouse accessibility audits and detailed a11y checks. Playwright CLI has no built-in accessibility auditing.

**WebSocket or EventSource frame inspection (e.g. Supabase Realtime)?**
→ **Chrome DevTools**
Playwright CLI shows that a WS connection exists but cannot inspect individual frames.

**Automated flow testing — clicking, filling forms, navigating, asserting outcomes?**
→ **Playwright CLI**
Most token-efficient. Runs via bash. Agent stays focused. Use `snapshot` → read refs → `click`/`fill`/`press`. Handles 90% of "does this flow work?" testing.

**Test generation — recording interactions into Playwright test files?**
→ **Playwright CLI**
Has `--codegen` support and test generation references. DevTools doesn't generate Playwright tests.

**Exploratory testing on an unknown page where you don't know the structure?**
→ **Playwright MCP**
MCP returns the full accessibility tree inline so the agent can reason about page structure, self-correct, and adapt. Worth the token cost when the agent genuinely needs to figure out what's on the page.

**Testing an app you're already logged into?**
→ **Chrome DevTools**
Connect DevTools MCP to your running Chrome instance (Chrome 144+ automatic connection, or `--remote-debugging-port=9222`). This shares your existing login state and gives you full DevTools capabilities — no need to handle auth programmatically.

**Site analysis for scraper development — finding API endpoints, auth patterns, data structures?**
→ **Chrome DevTools** (network inspection) + **Playwright CLI** (navigation and snapshotting)
Use DevTools to inspect network traffic and find the underlying APIs. Use Playwright CLI to navigate and snapshot page structure.

**Request mocking or route interception during testing?**
→ **Playwright CLI**
`playwright-cli route "**/*.jpg" --status=404` or `--body='{"mock": true}'`. DevTools can also intercept but Playwright's is more ergonomic for testing. See `references/request-mocking.md` in the playwright-cli skill.

**Recording a reproducible video of a flow (bug repro, demo, regression evidence)?**
→ **Playwright CLI**
`video-start video.webm` → interact → `video-stop`. Supports chapter markers via `video-chapter "Title" --description="..." --duration=2000`. DevTools has no equivalent video capture.

**Capturing a Playwright action trace for later replay in the trace viewer?**
→ **Playwright CLI**
`tracing-start` / `tracing-stop` emits a Playwright `.zip` trace viewable in `npx playwright show-trace`. Different from Chrome DevTools performance traces — this captures actions, DOM snapshots, and network for step-through debugging. See `references/tracing.md`.

**Reusing auth state across test runs (login once, replay many times)?**
→ **Playwright CLI**
`state-save auth.json` after login → `state-load auth.json` in subsequent sessions. Pairs well with `-s=mysession` named sessions for persistent profiles. See `references/storage-state.md`.

**Running multiple browsers concurrently (e.g. two users in a chat, parallel flows)?**
→ **Playwright CLI**
Named sessions: `playwright-cli -s=alice open` and `playwright-cli -s=bob open` run independently. `playwright-cli list` / `close-all` manage them. MCP is single-session.

**Piping browser data into other tools (jq, diff, scripts)?**
→ **Playwright CLI**
Global `--raw` flag strips snapshot/status noise: `playwright-cli --raw eval "..." | jq ...`, `playwright-cli --raw snapshot > before.yml`, `TOKEN=$(playwright-cli --raw cookie-get session_id)`. Only Playwright CLI has this.

### 2. Combination Patterns

Some tasks benefit from using multiple tools in sequence:

**Frontend regression testing (comprehensive)**
1. Playwright CLI — automate the flows, take screenshots, check console errors
2. Chrome DevTools — run Lighthouse on key pages, measure Core Web Vitals

**Debugging a failing API call**
1. Chrome DevTools — inspect the request/response to understand what's happening at the HTTP level
2. Playwright CLI — reproduce the flow that triggers the failure, automate the repro

**Pre-launch QA**
1. Playwright CLI — run all critical user flows
2. Chrome DevTools — Lighthouse audit (performance + accessibility + SEO), device emulation for mobile
3. Playwright CLI — screenshot key pages at different breakpoints

**Building a scraper for an external site**
1. Chrome DevTools — inspect network tab to find API endpoints, check auth headers, examine response payloads
2. Playwright CLI — navigate the site, snapshot the DOM structure, test selectors
3. Playwright CLI `--raw eval` — extract structured data to verify your approach

### 3. Tiebreakers

If still unsure:
- **Default to Playwright CLI** for anything interaction-based. It's the most token-efficient and handles the majority of tasks.
- **Escalate to Chrome DevTools** when you need to understand *why* something is broken (not just *that* it's broken).
- **Use Playwright MCP only** when persistent browser state across many turns and deep page reasoning are essential. In most cases, Playwright CLI + snapshots is sufficient.
- **Avoid using both Playwright CLI and MCP in the same session** — they can conflict on browser instances.

---

## Quick Reference: Capability Matrix

| Capability                        | PW CLI | PW MCP | DevTools |
|-----------------------------------|--------|--------|----------|
| Navigate / click / fill / type    | ✅     | ✅     | ✅       |
| Screenshot                        | ✅     | ✅     | ✅       |
| Accessibility snapshot            | ✅     | ✅     | ✅       |
| Console messages                  | ✅     | ✅     | ✅       |
| Network request list              | ✅     | ✅     | ✅       |
| Network response bodies/headers   | ❌     | ❌     | ✅       |
| Request mocking                   | ✅     | ✅     | ✅       |
| Cookie/localStorage/sessionStorage| ✅     | ✅     | ✅       |
| JS evaluation                     | ✅     | ✅     | ✅       |
| Performance traces / flame charts | ❌     | ❌     | ✅       |
| Lighthouse audits                 | ❌     | ❌     | ✅       |
| Core Web Vitals (LCP/CLS/INP)    | ❌     | ❌     | ✅       |
| Memory profiling                  | ❌     | ❌     | ✅       |
| CSS cascade inspection            | ❌     | ❌     | ✅       |
| WebSocket frame inspection        | ❌     | ❌     | ✅       |
| Device emulation                  | ❌     | ❌     | ✅       |
| HAR export                        | ❌     | ❌     | ✅       |
| Test generation                   | ✅     | ❌     | ❌       |
| Tracing (Playwright traces)       | ✅     | ❌     | ❌       |
| Video recording                   | ✅     | ❌     | ❌       |
| Multi-tab management              | ✅     | ✅     | ✅       |
| Token efficiency                  | ⭐⭐⭐ | ⭐     | ⭐⭐     |
| Persistent page reasoning         | ❌     | ✅     | ✅       |
| Auth (use existing login)         | ❌     | ❌     | ✅       |

---

## After Selecting a Tool

- **Playwright CLI**: Invoke the `playwright-cli` skill for the full command reference. Key workflow: `open` → `snapshot` → interact using refs (`e3`, `e15`, etc.) → `snapshot` to verify → `close`. Reference files in the skill cover deeper topics: `references/playwright-tests.md`, `request-mocking.md`, `tracing.md`, `video-recording.md`, `storage-state.md`, `session-management.md`, `test-generation.md`, `element-attributes.md`, `running-code.md`. Use `--raw` when piping into other tools.
- **Playwright MCP**: The agent will see available tools after MCP connection. Start with `browser_navigate`.
- **Chrome DevTools**: Use the DevTools MCP tools or CLI. For performance, ask for a Lighthouse audit or performance trace. For network, ask to capture network traffic. To use existing auth, connect to your running Chrome instance.
