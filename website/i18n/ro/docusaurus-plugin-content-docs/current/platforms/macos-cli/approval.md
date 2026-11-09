---
title: "Aprobă semnarea locală — Mac · Linie de comandă (CLI)"
sidebar_label: "Aprobă semnarea locală"
description: "Pregătește un PDF și verifică cererea de aprobare în aplicație."
pagination_prev: "platforms/macos-cli/mcp"
pagination_next: "platforms/macos-cli/unattended"
---

import GuideScreenshot from '@site/src/components/GuideScreenshot';

# Aprobă semnarea locală — Mac · Linie de comandă (CLI)

[Ghidurile platformei](../macos-cli.md) · [Instalare și conectarea cititorului](./setup.md) · [Conectează un agent prin MCP](./mcp.md)

Pregătește un PDF și verifică cererea de aprobare în aplicație.

## Cere semnare cu aprobare pe Mac

Activează brokerul de aprobare în Configurări pe Mac și folosește dosarul privat configurat. Aplicația și helperul trebuie să ruleze pentru același utilizator. Dosarul și subdosarele requests/responses/outputs trebuie să existe cu permisiuni0700. Pornește helperul cu acel dosar. Din client cere prepare_signing pentru PDF, verifică certificatul/documentul în aplicație, aprobă cu PIN, urmărește get_job și preia rezultatul. cancel_job cere anulare, dar nu anulează o semnătură deja creată. Cererile expiră după5minute, rezultatele se păstrează24ore. Ține aplicația pornită. Windows și Linux oferă și ele aprobare desktop cu dosarul privat al platformei; validează versiunea instalată.

<GuideScreenshot src="/img/guide/macos-cli/ro/broker.svg" alt="6. Cere semnare cu aprobare pe Mac" caption="Exemplu ilustrativ de comandă. Copiază comenzile de mai jos și înlocuiește căile și numele cititorului." steps={[{"x": 3, "y": 33.8, "text": "Activează brokerul pe Mac și folosește dosarul privat afișat."}, {"x": 3, "y": 76.1, "text": "Pregătește cererea în client și aprobă în aplicație."}]} />

```sh
esemnbun-mcp --root documents=/Users/me/Documents/Signing \
  --broker-directory /Users/me/PrivateBroker
```
