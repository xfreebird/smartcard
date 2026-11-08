---
title: "Primii pași — Windows · Linie de comandă (CLI)"
sidebar_label: "Primii pași"
description: "Instalează, conectează cititorul și alege cardul."
pagination_prev: "platforms/windows-cli"
pagination_next: "platforms/windows-cli/verification"
---

import GuideScreenshot from '@site/src/components/GuideScreenshot';

# Primii pași — Windows · Linie de comandă (CLI)

[Ghidurile platformei](../windows-cli.md)

Instalează, conectează cititorul și alege cardul.

Ilustrațiile folosesc date fictive. Urmează instrucțiunile în aplicația instalată.

## Instalează și descoperă funcțiile disponibile

Deschide [Descărcări](/downloads/) și alege platforma. Arhivele CLI conțin instrumentele de terminal și MCP; aplicația desktop se instalează separat. Folosește instrucțiunile pentru gestionarul de pachete, versiunea curentă și amprenta cheii. Localizează comanda și verifică funcțiile înainte de automatizare.

<GuideScreenshot src="/img/guide/windows-cli/ro/install.svg" alt="1. Instalează și descoperă funcțiile disponibile" caption="Exemplu ilustrativ de comandă. Copiază comenzile de mai jos și înlocuiește căile și numele cititorului." steps={[{"x": 3, "y": 30.6, "text": "Instalează prin canalul platformei ales."}, {"x": 3, "y": 78.3, "text": "Verifică funcțiile înainte de operațiuni cu cardul."}]} />

```powershell
scoop bucket add esemnbun https://github.com/xfreebird/homebrew-utils
scoop install esemnbun/esemnbun-cli
Get-Command esemnbun
esemnbun capabilities --json
```

Pentru Chocolatey, descarcă .nupkg într-un dosar gol, apoi execută:

```powershell
choco install esemnbun-cli --source . --yes
```

## Găsește cititorul și verifică certificatul

Conectează cititorul USB și introdu cardul. Listează cititoarele și citește certificatul fără PIN. Cu mai multe carduri, folosește numele exact al cititorului și verifică titularul înainte de semnare. Acestea sunt exemple; ghidul nu a accesat un cititor.

<GuideScreenshot src="/img/guide/windows-cli/ro/reader.svg" alt="2. Găsește cititorul și verifică certificatul" caption="Exemplu ilustrativ de comandă. Copiază comenzile de mai jos și înlocuiește căile și numele cititorului." steps={[{"x": 3, "y": 23.8, "text": "Listează cititoarele și prezența cardului."}, {"x": 3, "y": 53.5, "text": "Citește certificatul dorit; înlocuiește numele cititorului."}, {"x": 3, "y": 83.2, "text": "Calculează SHA-256 pentru certificatul exportat. Folosește cele 64 de cifre hexazecimale pentru semnarea nesupravegheată, nu SHA-1 afișat de cert."}]} />

```powershell
esemnbun readers
esemnbun cert --reader "miniLector EVO" --out leaf.der
Get-FileHash leaf.der -Algorithm SHA256
```
