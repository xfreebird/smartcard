# eSemnBun agent integration pack

User setup and official sources: [Connect your AI agent](../../website/docs/integrations/mcp-agents.md).
The shared [document skill](skills/esemnbun-documents/SKILL.md) is the source for all client
instructions. It is a user-facing signing/verification skill, separate from repository
maintenance skills under `.agents/skills/`.

`scripts/agents/export_integrations.py` exports MCP configuration fragments plus a native
skill, rule, workflow or instruction file for ten clients on three desktop platforms.
Claude Code additionally gets a local plugin containing its MCP configuration and skill.
No binaries, credentials, hooks or automatic signing permissions are bundled. Inspect and merge
exports into existing settings; do not replace personal configuration files wholesale.
The exporter requires a new destination directory and never installs or launches clients.
Downloaded examples use fictional paths that must be customized.

After modifying the shared skill or exporter, regenerate the checked-in public ZIP:

```sh
python3 scripts/agents/export_integrations.py \
  --archive website/static/downloads/esemnbun-agent-integrations.zip
python3 -m unittest discover -s scripts/agents -p 'test_*.py' -v
```

The ZIP has deterministic file order, timestamps and permissions. Focused checks cover all
30 client/platform combinations, Windows argument escaping, explicit broker selection,
conservative unattended/approval defaults, existing-directory refusal and archive freshness.
They do not establish end-to-end client compatibility or real-card signing.

When changing vendor configuration shapes, verify the official sources linked in the guide.
When changing tool names, inputs or lifecycle, reconcile the shared skill with `spec/mcp.md`
and the actual Swift/Windows server contracts. Update the guide, pack and `PLAN.md` together.
Do not install these exports into the maintainer's personal agent settings as part of packaging.
