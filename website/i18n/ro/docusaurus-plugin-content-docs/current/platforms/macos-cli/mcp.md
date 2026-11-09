---
title: "Conectează un agent prin MCP — Mac · Linie de comandă (CLI)"
sidebar_label: "Conectează un agent prin MCP"
description: "Alege dosarele autorizate și configurează clientul MCP."
pagination_prev: "platforms/macos-cli/verification"
pagination_next: "platforms/macos-cli/approval"
---

import GuideScreenshot from '@site/src/components/GuideScreenshot';

# Conectează un agent prin MCP — Mac · Linie de comandă (CLI)

[Ghidurile platformei](../macos-cli.md) · [Instalare și conectarea cititorului](./setup.md)

Alege dosarele autorizate și configurează clientul MCP.

## Conectează un client MCP cu acces explicit

Configurează un client local compatibil cu protocolul folosind calea absolută a executabilului și un dosar autorizat ales de tine. Înlocuiește cu propriul dosar fizic existent. Rădăcinile declarate de client nu acordă acces. Legăturile simbolice, traversarea și fișierele speciale sunt respinse. Fără rădăcini ai doar descoperire. Helperul folosește stdio, nu un serviciu de semnare în rețea. Limita este8MiB; originalele XML necesită o rădăcină detașată explicită.

<GuideScreenshot src="/img/guide/macos-cli/ro/mcp.svg" alt="5. Conectează un client MCP cu acces explicit" caption="Exemplu ilustrativ de comandă. Copiază comenzile de mai jos și înlocuiește căile și numele cititorului." steps={[{"x": 3, "y": 58.5, "text": "Alege executabilul instalat și un dosar restrâns."}, {"text": "Descoperă funcțiile și cere verificare offline din client."}]} />

```sh
esemnbun-mcp --root documents=/Users/me/Documents/Signing
```

Începe cu `capabilities` și `verify_document`. Intrarea identifică `{rootId,relativePath}`; nu trimite PIN sau conținutul documentului ca argumente. Rezultatele includ metadate minime. Clientul poate trimite metadatele propriilor servicii externe. Consultă [configurarea și politica MCP](https://esemnbun.md/packages/mcp.md). [Configurări și abilități reutilizabile pentru zece agenți AI](https://esemnbun.md/docs/integrations/mcp-agents/) (în engleză).

```json
{
  "command": "/opt/homebrew/bin/esemnbun-mcp",
  "args": [
    "--root",
    "documents=/Users/me/Documents/Signing"
  ]
}
```

```json
{"input":{"rootId":"documents","relativePath":"Contract-semnat.pdf"}}
```
