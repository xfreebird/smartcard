---
title: "MoldSign MCP — semnătură electronică pentru agenți AI"
description: "Folosește eSemnBun ca server MCP local pe Windows, Mac sau Linux. Verifică semnături PDF/XML și configurează semnarea cu cartea de identitate din Moldova."
sidebar_label: "MoldSign MCP"
---

# MoldSign MCP: semnătură electronică pentru agenți AI locali

**eSemnBun oferă un server local Model Context Protocol (MCP) pentru verificarea semnăturilor și, când este configurat explicit, semnarea PDF-urilor cu o carte de identitate electronică acceptată din Moldova.** Funcționează pe Windows, macOS și Linux. Este un proiect independent, nu un serviciu MCP oficial MoldSign sau STISC.

MCP conectează un agent la instrumentele instalate. Site-ul eSemnBun publică documentație și descărcări; nu oferă un serviciu de semnare la distanță. Procesul MCP rulează pe calculatorul care are acces la fișierele alese și, pentru semnare, la cititorul de carduri.

## Alege componenta potrivită

| Componentă | Rol |
| --- | --- |
| Aplicația desktop | Semnează și verifică documente prin interfața grafică |
| Conexiunea browser compatibilă cu MoldSign | Procesează cereri acceptate de la MSign și alte site-uri permise |
| Serverul MCP eSemnBun | Oferă clientului MCP instrumente locale configurate explicit, prin stdio |

Aceste interfețe sunt diferite. O conexiune browser funcțională nu configurează automat un agent, iar publicarea site-ului nu oferă agenților cloud acces la cititorul tău.

## Instalare pe Windows, Mac sau Linux

Începe de la [Descărcări](/downloads/) și urmează ghidul pachetului CLI instalat:

| Platformă | Comandă MCP | Configurare |
| --- | --- | --- |
| Windows | `esemnbun.exe mcp` | [Ghid MCP pentru Windows](./platforms/windows-cli/mcp.md) |
| Mac / macOS | `esemnbun-mcp` | [Ghid MCP pentru Mac](./platforms/macos-cli/mcp.md) |
| Linux | `esemnbun-mcp` | [Ghid MCP pentru Linux](./platforms/linux-cli/mcp.md) |

Folosește calea absolută către executabil și un dosar de intrare dedicat, existent. Aplicația Mac App Store necesită instalarea separată a CLI. SSH, WSL și containerele au propriul acces la fișiere și dispozitive.

[Ghidul de configurare a agenților](https://esemnbun.md/docs/integrations/mcp-agents/) (în engleză) include exemple pentru Claude, Codex, Cursor, GitHub Copilot, Gemini CLI și alți clienți, plus un pachet descărcabil. Exemplele nu confirmă testarea efectivă a conexiunii cu fiecare client. Alege un client compatibil cu reviziile de protocol din [contractul MCP](https://esemnbun.md/packages/mcp.md) (în engleză).

## Ce poate face agentul

| Instrument | Rol și condiție |
| --- | --- |
| `capabilities` | Descoperă dosarele autorizate, formatele și modurile de semnare disponibile |
| `verify_document` | Verifică semnături PDF sau XML în dosarul autorizat, fără acces la cititor sau rețea |
| `prepare_signing` | Pregătește semnarea unui PDF PAdES-T dacă aprobarea în aplicația nativă este configurată |
| `get_job`, `cancel_job` | Inspectează sau solicită anularea unei operații pe aceeași conexiune activă |
| `sign_document` | Semnează doar când operatorul a configurat explicit modul nesupravegheat |

Pentru verificare, folosește un fișier semnat fictiv din dosarul ales. Exemplu de date pentru instrument:

```json
{"input":{"rootId":"documents","relativePath":"Contract-signed.pdf"}}
```

Citește verdictul verificării, nu doar confirmarea executării apelului. Semnăturile XML detașate necesită documentele originale și un dosar pentru originale ales explicit. Verificarea offline nu stabilește starea curentă de revocare a certificatului.

## Semnare și confidențialitate

Semnarea necesită un card acceptat, un certificat de semnare activ, un cititor USB compatibil și autorizare. Cheia privată rămâne pe card. Configurarea implicită pentru verificare nu activează semnarea nesupravegheată.

Configurează separat aprobarea în aplicație sau semnarea nesupravegheată cu certificat fixat, conform ghidului platformei. Nu introduce PIN-ul cardului în chat, în argumentele instrumentelor sau în exemplele de configurare. Serverul returnează metadate minime despre verificare, nu conținutul documentului; clientul MCP poate trimite aceste metadate către propriile servicii externe.

## Documentație pentru agenți

Site-ul oferă un [index în text simplu](https://esemnbun.md/ro/llms.txt), o [referință combinată](https://esemnbun.md/ro/llms-full.txt) și un [catalog JSON](https://esemnbun.md/ro/discovery.json). Fișierele sunt generate din ghidurile publice și includ linkuri către paginile HTML pentru citare. Catalogul JSON descrie site-ul; nu este un serviciu MCP sau o comandă de instalare.

Pentru semnare obișnuită, începe cu [alternativa la MoldSign](./moldsign.md) sau [semnare și verificare](./signing.md).
