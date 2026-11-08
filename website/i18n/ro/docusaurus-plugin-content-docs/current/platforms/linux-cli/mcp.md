---
title: "Conectează un agent prin MCP — Linux · Linie de comandă (CLI)"
sidebar_label: "Conectează un agent prin MCP"
description: "Alege dosarele autorizate și configurează clientul MCP."
pagination_prev: "platforms/linux-cli/verification"
pagination_next: "platforms/linux-cli/unattended"
---

import GuideScreenshot from '@site/src/components/GuideScreenshot';

# Conectează un agent prin MCP — Linux · Linie de comandă (CLI)

[Ghidurile platformei](../linux-cli.md) · [Instalare și conectarea cititorului](./setup.md)

Alege dosarele autorizate și configurează clientul MCP.

Ilustrațiile folosesc date fictive. Urmează instrucțiunile în aplicația instalată.

## Conectează un client MCP cu acces explicit

Configurează un client local compatibil cu protocolul folosind calea absolută a executabilului și un dosar autorizat ales de tine. Înlocuiește cu propriul dosar fizic existent. Rădăcinile declarate de client nu acordă acces. Legăturile simbolice, traversarea și fișierele speciale sunt respinse. Fără rădăcini ai doar descoperire. Helperul folosește stdio, nu un serviciu de semnare în rețea. Limita este8MiB; originalele XML necesită o rădăcină detașată explicită.

<GuideScreenshot src="/img/guide/linux-cli/ro/mcp.svg" alt="5. Conectează un client MCP cu acces explicit" caption="Exemplu ilustrativ de comandă. Copiază comenzile de mai jos și înlocuiește căile și numele cititorului." steps={[{"x": 3, "y": 58.5, "text": "Alege executabilul instalat și un dosar restrâns."}, {"text": "Descoperă funcțiile și cere verificare offline din client."}]} />

```sh
esemnbun-mcp --root documents=/home/me/Documents/Signing
```

Începe cu `capabilities` și `verify_document`. Intrarea identifică `{rootId,relativePath}`; nu trimite PIN sau conținutul documentului ca argumente. Rezultatele includ metadate minime. Clientul poate trimite metadatele propriilor servicii externe. Consultă [configurarea și politica MCP](https://esemnbun.md/packages/mcp.md). [Configurări și abilități reutilizabile pentru zece agenți AI](https://esemnbun.md/docs/integrations/mcp-agents/) (în engleză).

```json
{
  "command": "/usr/bin/esemnbun-mcp",
  "args": [
    "--root",
    "documents=/home/me/Documents/Signing"
  ]
}
```

```json
{"input":{"rootId":"documents","relativePath":"Contract-semnat.pdf"}}
```

### Activează semnarea cu aprobare în aplicație

Activează cererile locale de semnare în aplicația GNOME și păstreaz-o pornită. Adaugă dosarul privat afișat în Preferințe la comanda helperului de mai jos. Folosește dosarul tău real; captura arată un dosar izolat. Apelează `prepare_signing`, examinează PDF-ul în aplicație, aprobă explicit și introdu PIN-ul acolo, apoi folosește `get_job` pentru rezultat. `cancel_job` solicită anularea; anularea sau expirarea nu dovedește că nu s-a creat o semnătură. PIN-ul nu se transmite în argumentele MCP. Acest flux cu aprobare pentru fiecare document este separat de semnarea nesupravegheată de mai jos.

```sh
esemnbun-mcp \
  --root documents=/home/me/Documents/Signing \
  --broker-directory "$HOME/.local/share/eSemnBun/AgentBroker"
```

<GuideScreenshot src="/img/guide/linux/ro/settings.png" alt="Activează semnarea cu aprobare în aplicație" caption="Captură nativă a preferințelor cu date fictive. Opțiunea este dezactivată în această sesiune izolată; nu s-a efectuat aprobarea MCP sau semnarea reală cu un card." steps={[{"x": 71, "y": 26, "text": "Activează cererile locale de semnare în aplicația desktop; fiecare PDF necesită verificare și aprobare."}, {"x": 50, "y": 27.4, "text": "Copiază dosarul privat afișat de propria instalare în configurarea de pornire MCP."}]} />
