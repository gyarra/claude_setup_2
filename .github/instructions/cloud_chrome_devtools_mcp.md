# Chrome DevTools MCP Setup

Set up Chrome DevTools MCP to inspect network requests and APIs used by cinema websites. This is useful for discovering REST API endpoints to build API-based scrapers.

## When to Use

- Discovering API endpoints on cinema websites (check Network tab for XHR/Fetch requests)
- Inspecting request/response payloads, headers, and authentication
- Debugging scraper issues by observing actual browser network traffic

## Prerequisites

The project `.mcp.json` is already configured to connect to a local Chromium instance on port 9222. You just need to install and launch the browser.

## Setup Steps

### 1. Install Playwright's Bundled Chromium

```bash
npx playwright install chromium
```

This downloads Chromium to `~/.cache/ms-playwright/chromium-*/`. It's ~200MB and only needed once per environment.

### 2. Launch Chromium with Remote Debugging

```bash
~/.cache/ms-playwright/chromium-1194/chrome-linux/chrome \
  --headless --no-sandbox --remote-debugging-port=9222 &
```

**Note:** The version directory (`chromium-1194`) may change after updates. Check with:

```bash
ls ~/.cache/ms-playwright/
```

### 3. Verify the Browser is Running

```bash
curl -s http://127.0.0.1:9222/json/version
```

You should see a JSON response with `Browser`, `webSocketDebuggerUrl`, etc.

### 4. Start a New Claude Code Session

The Chrome DevTools MCP server is configured in `.mcp.json` and loads at session startup. You may need to approve the `chrome-devtools` MCP server when prompted.

## Proxy Configuration

In cloud/container environments with an HTTP proxy (`HTTP_PROXY`/`HTTPS_PROXY` env vars), Chromium launched this way does **not** automatically use the proxy. If you need outbound access through a proxy, add the flag:

```bash
~/.cache/ms-playwright/chromium-1194/chrome-linux/chrome \
  --headless --no-sandbox --remote-debugging-port=9222 \
  --proxy-server="$HTTPS_PROXY" &
```

## Usage with MCP Tools

Once the session starts with the MCP server connected, use the Chrome DevTools tools:

```
mcp_chrome-devtoo_new_page              # Open a new browser tab
mcp_chrome-devtoo_navigate_page         # Navigate to a URL
mcp_chrome-devtoo_list_network_requests # List captured network requests (filter by Fetch/XHR)
mcp_chrome-devtoo_get_network_request   # Inspect a specific request's headers and body
mcp_chrome-devtoo_take_screenshot       # Capture the current page state
```

## Troubleshooting

**MCP server not available after session start:**
- Verify Chromium is running: `curl -s http://127.0.0.1:9222/json/version`
- If not running, launch it (step 2) and start a new session

**`NS_ERROR_PROXY_CONNECTION_REFUSED` or network errors:**
- Add `--proxy-server="$HTTPS_PROXY"` when launching Chromium (see Proxy Configuration above)
- Verify the proxy works: `curl -I https://cinepolis.com.co/`

**Chromium crashes on launch:**
- Ensure `--no-sandbox` is included (required in container environments)
- Check logs: `cat /tmp/chrome-debug.log` (if launched with `&>/tmp/chrome-debug.log`)

**Port 9222 already in use:**
- Kill existing instances: `pkill -f 'chrome.*remote-debugging-port'`
- Re-launch Chromium
