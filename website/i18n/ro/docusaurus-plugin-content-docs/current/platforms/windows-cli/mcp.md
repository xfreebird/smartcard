---
title: "Conectează un agent prin MCP — Windows · Linie de comandă (CLI)"
sidebar_label: "Conectează un agent prin MCP"
description: "Alege dosarele autorizate și configurează clientul MCP."
pagination_prev: "platforms/windows-cli/verification"
pagination_next: "platforms/windows-cli/unattended"
---

import GuideScreenshot from '@site/src/components/GuideScreenshot';

# Conectează un agent prin MCP — Windows · Linie de comandă (CLI)

[Ghidurile platformei](../windows-cli.md) · [Instalare și conectarea cititorului](./setup.md)

Alege dosarele autorizate și configurează clientul MCP.

Ilustrațiile folosesc date fictive. Urmează instrucțiunile în aplicația instalată.

## Conectează un client MCP cu acces explicit

Configurează un client local compatibil cu protocolul folosind calea absolută a executabilului și un dosar autorizat ales de tine. Înlocuiește cu propriul dosar fizic existent. Rădăcinile declarate de client nu acordă acces. Legăturile simbolice, traversarea și fișierele speciale sunt respinse. Fără rădăcini ai doar descoperire. Helperul folosește stdio, nu un serviciu de semnare în rețea. Limita este8MiB; originalele XML necesită o rădăcină detașată explicită.

<GuideScreenshot src="/img/guide/windows-cli/ro/mcp.svg" alt="5. Conectează un client MCP cu acces explicit" caption="Exemplu ilustrativ de comandă. Copiază comenzile de mai jos și înlocuiește căile și numele cititorului." steps={[{"x": 3, "y": 58.5, "text": "Alege executabilul instalat și un dosar restrâns."}, {"text": "Descoperă funcțiile și cere verificare offline din client."}]} />

```powershell
esemnbun mcp --root "documents=C:\Users\me\Documents\Signing"
```

Începe cu `capabilities` și `verify_document`. Intrarea identifică `{rootId,relativePath}`; nu trimite PIN sau conținutul documentului ca argumente. Rezultatele includ metadate minime. Clientul poate trimite metadatele propriilor servicii externe. Consultă [configurarea și politica MCP](https://esemnbun.md/packages/mcp.md).

```json
{
  "command": "C:\\Program Files\\eSemnBun\\bin\\esemnbun.exe",
  "args": [
    "mcp",
    "--root",
    "documents=C:\\Users\\me\\Documents\\Signing"
  ]
}
```

```json
{"input":{"rootId":"documents","relativePath":"Contract-semnat.pdf"}}
```
