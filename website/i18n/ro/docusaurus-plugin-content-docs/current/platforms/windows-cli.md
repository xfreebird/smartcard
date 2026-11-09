---
title: "Windows · Linie de comandă (CLI) — ghiduri"
sidebar_label: "Windows · Linie de comandă (CLI)"
hide_table_of_contents: true
pagination_prev: null
pagination_next: "platforms/windows-cli/setup"
---

import GuideDirectory from '@site/src/components/GuideDirectory';
import GuideAnchorRedirect from '@site/src/components/GuideAnchorRedirect';

# Windows · Linie de comandă (CLI) — ghiduri

Alege ce vrei să faci. Fiecare activitate are un ghid ilustrat separat.

<GuideDirectory platform="windows-cli" />
<GuideAnchorRedirect platform="windows-cli" />

## Înainte de a începe

Urmează exemplele numerotate pentru a atinge un scop concret. Comenzile rămân în engleză. Panourile ilustrează comenzi, nu o semnare reală cu un card. Doar rezultatele de capabilități și verificarea fișierului fără semnături au fost capturate local; nu a fost folosit niciun PIN, card sau furnizor de secrete real.

Pentru operațiuni cu cardul ai nevoie de un act electronic acceptat, PIN-ul corect, un cititor USB compatibil și adaptorul necesar. NFC nu este acceptat. Verificarea nu necesită cititor sau PIN. Păstrează originalele. Cheia privată rămâne pe card.

:::info
CLI Windows acceptă momentan help, capabilities, readers, cert, sign-hex, mcp, encrypt, decrypt, encryption-certs și remove-file. Comenzile normale sign/xades/verify/server/cms-for-hash nu sunt implementate. Pentru documente folosește aplicația desktop sau instrumentele MCP configurate separat pentru verificare/semnare nesupravegheată. Activează cererile locale în Configurări Windows și configurează --broker-directory pentru aprobare. Nu presupune paritate cu macOS/Linux.
:::
