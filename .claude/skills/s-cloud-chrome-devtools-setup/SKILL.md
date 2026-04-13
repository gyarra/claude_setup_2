---
name: s-cloud-chrome-devtools-setup
description: Use when working in a cloud compute environment and needing Chrome DevTools MCP — installs Chromium, launches with remote debugging, configures proxy
---

# Cloud Chrome DevTools MCP Setup

Set up Chrome DevTools MCP in cloud/container environments. The browser must be launched fresh each session.

The project `.mcp.json` is already configured to connect to a local Chromium instance on port 9222.

## Step 1: Install Playwright's Chromium

```bash
npx playwright install chromium
```

Downloads to `~/.cache/ms-playwright/chromium-*/`. ~200MB, only needed once per environment.

## Step 2: Launch Chromium with Remote Debugging

```bash
~/.cache/ms-playwright/chromium-1194/chrome-linux/chrome \
  --headless --no-sandbox --remote-debugging-port=9222 &
```

The version directory (`chromium-1194`) may change. Check with `ls ~/.cache/ms-playwright/`.

### Proxy Configuration

Cloud environments with `HTTP_PROXY`/`HTTPS_PROXY` env vars need the proxy flag — Chromium does not honor these automatically:

```bash
~/.cache/ms-playwright/chromium-1194/chrome-linux/chrome \
  --headless --no-sandbox --remote-debugging-port=9222 \
  --proxy-server="$HTTPS_PROXY" &
```

## Step 3: Verify

```bash
curl -s http://127.0.0.1:9222/json/version
```

Should return JSON with `Browser`, `webSocketDebuggerUrl`, etc.

## Step 4: Start a New Claude Code Session

The Chrome DevTools MCP server loads at session startup from `.mcp.json`. You may need to approve the `chrome-devtools` MCP server when prompted.

## MCP Tools

```
mcp_chrome-devtoo_new_page              # Open a new browser tab
mcp_chrome-devtoo_navigate_page         # Navigate to a URL
mcp_chrome-devtoo_list_network_requests # List captured network requests (Fetch/XHR)
mcp_chrome-devtoo_get_network_request   # Inspect request headers and body
mcp_chrome-devtoo_take_screenshot       # Capture current page state
```

## Troubleshooting

| Problem | Fix |
|---------|-----|
| MCP server not available | Verify Chromium running: `curl -s http://127.0.0.1:9222/json/version` |
| `NS_ERROR_PROXY_CONNECTION_REFUSED` | Add `--proxy-server="$HTTPS_PROXY"` when launching |
| Chromium crashes on launch | Ensure `--no-sandbox` is included (required in containers) |
| Port 9222 already in use | `pkill -f 'chrome.*remote-debugging-port'` then re-launch |
