---
title: "Aprobă semnarea locală — Windows"
sidebar_label: "Aprobă semnarea locală"
description: "Pregătește un PDF și verifică cererea de aprobare în aplicație."
pagination_prev: "platforms/windows/browser"
pagination_next: "platforms/windows/help"
---

import GuideScreenshot from '@site/src/components/GuideScreenshot';

# Aprobă semnarea locală — Windows

[Ghidurile platformei](../windows.md) · [Instalare și conectarea cititorului](./setup.md) · [Conectează un agent prin MCP](../windows-cli/mcp.md)

Pregătește un PDF și verifică cererea de aprobare în aplicație.

Ilustrațiile folosesc date fictive. Urmează instrucțiunile în aplicația instalată.

## Aprobă cereri locale de semnare (MCP)

În **Setări → General**, derulează la **Avansat** și activează **Permite cereri locale de semnare (MCP)**. Copiază dosarul privat afișat sub comutator în configurația clientului MCP. Păstrează eSemnBun deschis și selectează cardul dorit. Opțiunea nu este disponibilă în modul demonstrativ.

```powershell
& "C:\Program Files\eSemnBun\bin\esemnbun.exe" mcp `
  --root "documents=C:\Users\me\Documents\Signing" `
  --broker-directory "C:\Users\me\AppData\Local\MoldSign\MCP"
```

Folosește dosarul afișat de instalarea ta, în locul exemplului de mai jos. Clientul poate pregăti un PDF prin `prepare_signing`, verifica starea prin `get_job` sau anula prin `cancel_job`. Examinează PDF-ul în previzualizarea nativă și alege Semnează numai dacă aprobi cererea; urmează autorizarea cu cardul. Un PIN salvat nu omite această aprobare. Anularea sau expirarea timpului nu dovedește că nu a fost creată o semnătură.

Captura folosește un profil demonstrativ izolat: calea este un exemplu, iar comutatorul MCP este dezactivat. Nu a fost executată nicio cerere MCP de semnare pentru această captură.


<GuideScreenshot src="/img/guide/windows/ro/lower.png" alt="Conexiune browser și cereri locale" steps={[{"x": 25, "y": 82, "text": "Găsește comutatorul MCP în Avansat. În afara modului demonstrativ, activează-l și copiază dosarul privat în configurația clientului."}, {"x": 48, "y": 92, "text": "Folosește dosarul afișat de instalarea ta, nu calea demonstrativă."}]} />
