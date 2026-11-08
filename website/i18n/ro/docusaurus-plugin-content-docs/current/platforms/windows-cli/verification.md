---
title: "Verifică prin MCP — Windows · Linie de comandă (CLI)"
sidebar_label: "Verifică prin MCP"
description: "Verifică un PDF sau XML și inspectează semnatarul și certificatul."
pagination_prev: "platforms/windows-cli/setup"
pagination_next: "platforms/windows-cli/mcp"
---

import GuideScreenshot from '@site/src/components/GuideScreenshot';

# Verifică prin MCP — Windows · Linie de comandă (CLI)

[Ghidurile platformei](../windows-cli.md) · [Instalare și conectarea cititorului](./setup.md)

Verifică un PDF sau XML și inspectează semnatarul și certificatul.

Ilustrațiile folosesc date fictive. Urmează instrucțiunile în aplicația instalată.

## Verifică și interpretează rezultatul

Verificarea offline pe Windows este oferită de MCP verify_document, nu de comanda normală verify. Configurează o rădăcină explicită și intrarea `{rootId,relativePath}`; citește integritatea, semnătura și lanțul. Originalele lipsă necesită rădăcina detașată explicită. Nu se folosește cititor/PIN și nu se verifică revocarea curentă.

<GuideScreenshot src="/img/guide/windows-cli/ro/verification.svg" alt="ghid pentru linia de comandă" caption="Exemplu ilustrativ de comandă. Copiază comenzile de mai jos și înlocuiește căile și numele cititorului." steps={[{"x": 3, "y": 18.3, "text": "Pornește serverul MCP cu dosarul pe care l-ai ales."}, {"x": 3, "y": 41.2, "text": "În clientul MCP, alege instrumentul verify_document."}, {"x": 3, "y": 64.1, "text": "Furnizează această intrare și examinează integritatea, semnătura și lanțul. Este un exemplu, nu un rezultat capturat."}]} />

```powershell
esemnbun mcp --root "documents=C:\Users\me\Documents\Signing"
```

```json
{"input":{"rootId":"documents","relativePath":"Contract-semnat.pdf"}}
```
