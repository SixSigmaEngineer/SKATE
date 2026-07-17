# Connect SKATE memory to Codex and ChatGPT Work

SKATE includes a real, read-only Model Context Protocol server. It exposes governed workshop memory without giving an agent unrestricted file-system access.

## What the server enforces

- Inactive notes are excluded.
- Inactive sessions are excluded.
- Search results are bounded to a maximum of 20 notes.
- Full-note reads are capped at 12,000 characters.
- Relationship tracing is capped at three hops and 50 links.
- Every tool is marked read-only, non-destructive, idempotent, and closed-world.
- The server never returns `settings.json`, API keys, logs, or arbitrary local files.

## Available tools

| Tool | Use |
|---|---|
| `server_info` | Inspect server, vault, governance, and retrieval status |
| `list_active_sessions` | List the active workshop memories available to an agent |
| `search_memory` | Retrieve bounded Top-K evidence across the vault or one session |
| `get_memory_object` | Read one complete active memory object by its ID |
| `get_session_context` | Retrieve themes, type counts, and a bounded session evidence set |
| `trace_evidence` | Follow typed supporting, conflicting, causal, and reference links |
| `get_grind_outputs` | Retrieve the latest saved GPT-5.6 GRIND run or a local preview |
| `search` | ChatGPT-compatible knowledge search wrapper |
| `fetch` | ChatGPT-compatible full-document fetch wrapper |

## Local Codex and ChatGPT desktop setup

### Installed application

The Windows installer includes `SKATE-MCP.exe`; users do not need Python or a
separate MCP download. The visible installer option **Connect SKATE memory to
Codex and ChatGPT desktop** runs the one-time registration step when selected.
It can also be run later by opening `Configure SKATE MCP for Codex.bat` in the
SKATE installation folder. Registration requires the Codex CLI to be available;
if it is not, add `SKATE-MCP.exe --transport stdio` from the desktop MCP settings.

The installer places an `installed.marker` beside the executables, so both
`SKATE.exe` and `SKATE-MCP.exe` use the same vault under the current user's
Documents folder.

### Source checkout

The easiest option is to double-click:

```text
Configure SKATE MCP for Codex.bat
```

The script registers SKATE as a local STDIO server. Restart the ChatGPT desktop app, Codex CLI, or Codex IDE extension afterward, then type `/mcp` to inspect the connection.

The equivalent command is:

```powershell
codex mcp add skate -- "C:\path\to\SKATE\.venv\Scripts\python.exe" "C:\path\to\SKATE\mcp_server\server.py" --transport stdio
```

You can also add it in the desktop UI:

1. Open **Settings**, then **MCP servers**.
2. Select **Add server**.
3. Name it `skate` and choose **STDIO**.
4. Command: the full path to `.venv\Scripts\python.exe`.
5. Arguments: the full path to `mcp_server\server.py`, followed by `--transport` and `stdio`.
6. Save and restart the desktop app.

Codex clients share MCP configuration through `~/.codex/config.toml`. A manual entry looks like this:

```toml
[mcp_servers.skate]
command = "C:\\path\\to\\SKATE\\.venv\\Scripts\\python.exe"
args = ["C:\\path\\to\\SKATE\\mcp_server\\server.py", "--transport", "stdio"]
cwd = "C:\\path\\to\\SKATE"
startup_timeout_sec = 20
tool_timeout_sec = 60
```

## ChatGPT Work on the web

ChatGPT web cannot start a local STDIO process or read the local Codex configuration. It needs a remote MCP endpoint. Do not expose SKATE's unauthenticated local endpoint directly to the public internet.

For local development:

1. Double-click **`Start SKATE MCP HTTP.bat`**.
2. Confirm the private endpoint is running at `http://127.0.0.1:8766/mcp`.
3. Create an OpenAI Secure MCP Tunnel that forwards to that private endpoint.
4. Enable developer mode in ChatGPT if your account/workspace permits it.
5. Create a developer-mode plugin/app and select the tunnel endpoint.
6. Confirm that ChatGPT discovers the nine read-only SKATE tools.

For a permanent deployment, host the Streamable HTTP endpoint behind HTTPS and add OAuth or bearer-token authentication before connecting it to a workspace. Authentication and multi-user vault isolation are deployment work; the hackathon server is intentionally bound only to `127.0.0.1`.

## Local HTTP testing

Run:

```powershell
Start SKATE MCP HTTP.bat
```

Then point MCP Inspector at:

```text
http://127.0.0.1:8766/mcp
```

STDIO and Streamable HTTP use the same tools and governance rules.

## Demo prompts

Try these after connecting Codex:

```text
Use SKATE to list my active workshop sessions. Do not inspect files directly.
```

```text
Search SKATE for evidence that Harborlight families repeat information during handoffs. Report the retrieval mode, estimated context reduction, and the source memory IDs.
```

```text
Trace the evidence around the repeated-story problem. Separate observations, pains, open questions, and actions, and name any typed relationships.
```

```text
Retrieve the latest GRIND outputs for the Harborlight service-access session and turn the strongest How-Might-We prompt into a small experiment.
```

## Privacy note

Using MCP does not upload the full vault by default. The client receives only the tool result it requested. When a cloud-hosted model calls SKATE through a remote connector or tunnel, the returned evidence is sent to that model and is subject to the applicable account, workspace, and service data controls.
