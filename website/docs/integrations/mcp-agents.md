---
title: Connect your AI agent
sidebar_label: AI agents and MCP
description: Configure ten local MCP clients with eSemnBun skills, workflows and a Claude Code plugin.
---

# Connect your AI agent

Use eSemnBun to verify document signatures or prepare a PDF for smartcard signing from your
agent. Start with offline verification; add native approval or unattended signing separately.

[Download configurations and skills for all ten clients](/downloads/esemnbun-agent-integrations.zip)

The pack includes macOS, Windows and Linux examples for **Claude Code, Claude Desktop,
Codex, Cursor, GitHub Copilot in VS Code, Gemini CLI, Windsurf/Cascade, Cline, Roo Code and
OpenCode**. These are ten widely used MCP-capable products/surfaces, not a measured popularity
ranking. Claude desktop and coding clients are listed separately because their setup differs.
Official configuration references were checked on **8 November 2026**. Templates are
schema-reviewed examples; connections to all ten installed clients have not been runtime-tested.

## Before connecting

1. Install the [desktop CLI for your platform](/downloads/). macOS/Linux use the separate
   `esemnbun-mcp` executable; Windows uses `esemnbun.exe mcp`. The macOS App Store app requires
   the separately installed CLI. A local MCP client must run on the computer with the files,
   credentials and reader. SSH, WSL, containers and cloud agents have their own filesystem and
   device access; a local configuration does not give them access to your computer.
2. Create a dedicated input folder and select its canonical physical path. Avoid symlink
   components. Replace every `me` and executable path in these examples. Homebrew on Intel
   macOS commonly uses `/usr/local/bin`; do not assume `/opt/homebrew/bin` exists. Check the
   executable installed by your package. Do not grant an entire home folder.
3. Merge only the `esemnbun` entry into the client's existing configuration. Keep other servers
   and settings. Copy the skill/rule/workflow indicated below into the workspace where you use
   that agent. Instructions teach the workflow; only the separate MCP configuration grants
   file access. Do not install both the plugin and a duplicate standalone server.
4. Reload the client, approve/trust the server configuration as required, list its tools and
   call `capabilities`. Verify a fictional signed fixture with `verify_document`. Expected
   input: `{"input":{"rootId":"documents","relativePath":"Contract-signed.pdf"}}`.
   Inspect the returned verification status, not merely whether the call succeeded.

The server supports **2026-07-28** and the explicit **2025-11-25** initialization adapter.
A host pinned to an older revision cannot connect. Update it or use a compatible client;
these templates do not turn unsupported revisions into supported ones. Keep each signing job
on the same live server connection. See the [full protocol and security policy](https://esemnbun.md/packages/mcp.md).

## Export a configuration for your own paths

From a checkout of [the repository](https://github.com/xfreebird/smartcard):

```sh
python3 scripts/agents/export_integrations.py \
  --client cursor --platform macos \
  --command /opt/homebrew/bin/esemnbun-mcp \
  --root /Users/me/Documents/Signing \
  --output /Users/me/Desktop/esemnbun-cursor-config
```

For Linux choose `--platform linux` and your installed helper and input paths. On Windows:

```powershell
python scripts/agents/export_integrations.py `
  --client vscode --platform windows `
  --command 'C:\Program Files\eSemnBun\bin\esemnbun.exe' `
  --root 'C:\Users\me\Documents\Signing' `
  --output 'C:\Users\me\Desktop\esemnbun-vscode-config'
```

The output folder must be new. The exporter does not install anything, start signing, validate
local paths/permissions or set a PIN. It exports configuration and instructions to inspect and
merge. The downloadable ZIP contains equivalent examples for all three platforms. Claude
Desktop availability depends on its vendor-supported OS; a Linux example does not establish
that a supported Claude Desktop Linux build is available.

## Client configurations

Examples below use macOS paths. The ZIP/exporter provides the Windows `mcp` subcommand,
Windows JSON escaping, and Linux equivalents. Configuration locations are client-specific.

### 1. Claude Code

Merge into project `.mcp.json`, or use `claude mcp add --transport stdio esemnbun -- /absolute/path/esemnbun-mcp --root documents=/absolute/input`. Copy the exported `.claude/skills/esemnbun-documents/` folder into your project. Run `/mcp` to inspect the connection.

```json
{
  "mcpServers": {
    "esemnbun": {
      "command": "/opt/homebrew/bin/esemnbun-mcp",
      "args": [
        "--root",
        "documents=/Users/me/Documents/Signing"
      ]
    }
  }
}
```

[Official MCP setup](https://code.claude.com/docs/en/mcp) · [Instructions format](https://code.claude.com/docs/en/skills)

### 2. Claude Desktop

Open **Settings → Developer → Edit Config**. Merge into the file it opens: typically `~/Library/Application Support/Claude/claude_desktop_config.json` on macOS or `%APPDATA%\Claude\claude_desktop_config.json` on Windows. Restart the app. Paste `esemnbun-instructions.md` into Project instructions, or attach it to the conversation; the file is not automatically loaded as a local skill.

```json
{
  "mcpServers": {
    "esemnbun": {
      "command": "/opt/homebrew/bin/esemnbun-mcp",
      "args": [
        "--root",
        "documents=/Users/me/Documents/Signing"
      ]
    }
  }
}
```

[Official MCP setup](https://modelcontextprotocol.io/docs/develop/connect-local-servers)

### 3. Codex (CLI, desktop and IDE)

Merge this table into `~/.codex/config.toml`, or trusted-project `.codex/config.toml`. Copy the exported skill to `.agents/skills/esemnbun-documents/` in your workspace. Run `codex mcp list` and `/mcp` to check it. Local desktop, CLI and IDE surfaces share the host configuration; a web/cloud session does not automatically acquire local access.

```toml
[mcp_servers.esemnbun]
command = "/opt/homebrew/bin/esemnbun-mcp"
args = ["--root", "documents=/Users/me/Documents/Signing"]
```

[Official MCP setup](https://learn.chatgpt.com/docs/extend/mcp?surface=cli) · [Instructions format](https://learn.chatgpt.com/docs/build-skills)

### 4. Cursor

Merge into `.cursor/mcp.json` for this project, or `~/.cursor/mcp.json` for personal use. Copy `.cursor/skills/esemnbun-documents/` into your project. Check the server in MCP settings and use Agent mode.

```json
{
  "mcpServers": {
    "esemnbun": {
      "command": "/opt/homebrew/bin/esemnbun-mcp",
      "args": [
        "--root",
        "documents=/Users/me/Documents/Signing"
      ]
    }
  }
}
```

[Official MCP setup](https://cursor.com/docs/mcp) · [Instructions format](https://cursor.com/docs/skills)

### 5. GitHub Copilot in VS Code

Merge into `.vscode/mcp.json`, whose top-level key is `servers`, not `mcpServers`. Alternatively run **MCP: Open User Configuration**. Copy the skill into `.github/skills/esemnbun-documents/`. Start the server from its configuration, trust it when prompted, and select its tools in Copilot Agent chat.

```json
{
  "servers": {
    "esemnbun": {
      "type": "stdio",
      "command": "/opt/homebrew/bin/esemnbun-mcp",
      "args": [
        "--root",
        "documents=/Users/me/Documents/Signing"
      ]
    }
  }
}
```

[Official MCP setup](https://code.visualstudio.com/docs/agent-customization/mcp-servers) · [Instructions format](https://code.visualstudio.com/docs/agent-customization/agent-skills)

### 6. Gemini CLI

Merge into `.gemini/settings.json` for the workspace or `~/.gemini/settings.json`. Copy `.gemini/skills/esemnbun-documents/` into your workspace. Use `/mcp` and `/skills list` to check discovery. The template keeps `trust: false`; it does not bypass tool confirmation.

```json
{
  "mcpServers": {
    "esemnbun": {
      "command": "/opt/homebrew/bin/esemnbun-mcp",
      "args": [
        "--root",
        "documents=/Users/me/Documents/Signing"
      ],
      "trust": false
    }
  }
}
```

[Official MCP setup](https://geminicli.com/docs/tools/mcp-server/) · [Instructions format](https://geminicli.com/docs/cli/skills/)

### 7. Windsurf / Cascade

Use **Open MCP config file** in your installed Cascade client and merge there. Current Cortex-managed configurations use `~/.config/devin/mcp_config.json` (or `%APPDATA%\devin\mcp_config.json`); legacy editor discovery can use `~/.codeium/windsurf/mcp_config.json`. Use the file the app opens. Copy `.windsurf/workflows/esemnbun-documents.md` into your workspace and invoke `/esemnbun-documents` in Cascade. Windsurf documentation now lives under Devin; this adapter targets Cascade, not a cloud Devin session.

```json
{
  "mcpServers": {
    "esemnbun": {
      "command": "/opt/homebrew/bin/esemnbun-mcp",
      "args": [
        "--root",
        "documents=/Users/me/Documents/Signing"
      ]
    }
  }
}
```

[Official MCP setup](https://docs.devin.ai/windsurf/plugins/cascade/mcp) · [Instructions format](https://docs.devin.ai/windsurf/plugins/cascade/workflows)

### 8. Cline

Open **MCP Servers → Configure MCP Servers** and merge into `cline_mcp_settings.json`. Copy `.clinerules/esemnbun-documents.md` into your workspace and enable that rule. The template has an empty `autoApprove` list; retain review of signing tools.

```json
{
  "mcpServers": {
    "esemnbun": {
      "command": "/opt/homebrew/bin/esemnbun-mcp",
      "args": [
        "--root",
        "documents=/Users/me/Documents/Signing"
      ],
      "disabled": false,
      "autoApprove": []
    }
  }
}
```

[Official MCP setup](https://docs.cline.bot/mcp/mcp-overview) · [Instructions format](https://docs.cline.bot/customization/cline-rules)

### 9. Roo Code

Merge into project `.roo/mcp.json`, or open **MCP → Edit Global Config** and merge into the selected `mcp_settings.json`. Copy `.roo/rules/esemnbun-documents.md` into the workspace. The empty `alwaysAllow` list retains tool review. This adapter uses documented rules rather than requiring a particular skill-enabled Roo release.

```json
{
  "mcpServers": {
    "esemnbun": {
      "command": "/opt/homebrew/bin/esemnbun-mcp",
      "args": [
        "--root",
        "documents=/Users/me/Documents/Signing"
      ],
      "disabled": false,
      "alwaysAllow": []
    }
  }
}
```

[Official MCP setup](https://roocodeinc.github.io/Roo-Code/features/mcp/using-mcp-in-roo/) · [Instructions format](https://roocodeinc.github.io/Roo-Code/features/custom-instructions/)

### 10. OpenCode

Merge into `opencode.json` or `opencode.jsonc`. Current documentation nests servers under `mcp.servers`; older OpenCode versions use a different shape. Update the client or adapt to its documented schema. Copy `.opencode/skills/esemnbun-documents/` into the project. Run `opencode mcp list`. The example selects the implemented modern protocol explicitly.

```json
{
  "mcp": {
    "servers": {
      "esemnbun": {
        "type": "local",
        "command": [
          "/opt/homebrew/bin/esemnbun-mcp",
          "--root",
          "documents=/Users/me/Documents/Signing"
        ],
        "protocol": "2026-07-28"
      }
    }
  }
}
```

[Official MCP setup](https://opencode.ai/docs/mcp-servers/) · [Instructions format](https://opencode.ai/docs/skills/)

## Use the Claude Code plugin

The ZIP/export includes `claude-code/<platform>/plugin/`, containing a plugin manifest,
MCP configuration and document skill. Customize its executable and root paths, then load
that folder locally:

```sh
claude --plugin-dir /absolute/path/to/plugin
```

Use `/mcp` to confirm `esemnbun` and invoke the skill `/esemnbun:esemnbun-documents`.
Choose either this plugin or the standalone configuration/skill. The plugin contains no
binary download, credential, hook or unattended-signing opt-in. It is a local package,
not a marketplace listing or certification. [Official plugin layout](https://code.claude.com/docs/en/plugins-reference).
For the other clients use the supplied native skill, rule, workflow or project instructions;
plugin formats are not interchangeable.

## Add desktop approval when you need signing

1. In the standalone desktop app, enable local agent signing requests and keep the app running.
2. Copy the private broker directory displayed by the app. On export add
   `--broker-directory /absolute/private/broker` (quote Windows paths).
   It must already exist with the app's required ownership/permissions and subdirectories.
3. In the agent ask: **“Prepare documents/Contract.pdf for my approval in eSemnBun.”**
   It calls `prepare_signing`, then checks `get_job`. Review the PDF and certificate in the
   native app and enter the PIN there. The agent never receives the PIN.
4. A completed job returns a broker output reference and hashes. Retrieve the output within
   24 hours. Approval expires after five minutes. A pending job is not a signed document.
   Cancellation cannot undo a signature already in progress. After reconciling failures,
   create a fresh request only when appropriate.

macOS App Store users keep the separately installed CLI fallback; do not assume the Store app
has the standalone broker. Installed Windows aliases, Flatpak access, native approval and
physical-card/provider behavior need validation on the target installation.

## Unattended automation and privacy

The supplied configurations enable **verification only**. The exporter can add an existing
foreground broker but cannot enable unattended mode. An operator can separately configure
certificate-pinned unattended signing with a private output directory and a credential-provider
reference as described in the [MCP contract](https://esemnbun.md/packages/mcp.md). The skill supports an already
configured `sign_document` tool when the user's request authorizes that signing operation.

Use Keychain on macOS, Credential Manager on Windows, Secret Service on Linux, or the supported
1Password/environment provider. Never put PIN values in MCP JSON/TOML, tool arguments, skills,
chat, source control or logs. The helper reads the provider itself. Discovery and verification
do not access credentials. Keep host tool permissions enabled; a skill is not an authorization
boundary. Metadata returned by MCP can still be sent to the agent provider.

A wrong PIN, process crash or uncertain signing outcome leaves a persistent lock. Stop and
reconcile the card/output state; never automatically remove the lock or retry signing. Do not
expose this stdio helper through an unauthenticated network proxy to make a cloud client fit.
Web-only clients need a separately designed authenticated local-device integration, which this
pack does not provide.

## Check the connection

| Symptom | Next step |
| --- | --- |
| No tools / executable not found | Check absolute installed path on the agent's execution machine, then restart/reload. |
| Initialization rejected | Check the client negotiates 2025-11-25 or 2026-07-28; an older client revision is unsupported. |
| Root rejected / file not found | Select an existing physical folder without symlink ancestors and a relative filename beneath it. No client root grant expands access. |
| Verification reports incomplete | Read missing-original/chain checks; offline verification is not current revocation checking. |
| Signing unavailable | Inspect capabilities; check desktop opt-in, private broker path and app process. |
| Job missing after reconnect | Jobs belong to the original helper process. Inspect the native outcome; do not blindly resubmit. |
| Signing timeout / persistent lock | Reconcile output and card state with the operator before another attempt. |

Validation here covers exported schemas, path escaping, package contents, conservative defaults
and preservation of existing configuration. It does not establish live compatibility with every
client version, store-installed helper, credential provider or physical card.
