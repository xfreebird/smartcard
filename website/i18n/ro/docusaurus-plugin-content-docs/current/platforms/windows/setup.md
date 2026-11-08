---
title: "Primii pași — Referință desktop Windows"
sidebar_label: "Primii pași"
description: "Instalează, conectează cititorul și alege cardul."
pagination_prev: "platforms/windows"
pagination_next: "platforms/windows/signing"
---

import PlatformScreenshots from '@site/src/components/PlatformScreenshots';

# Primii pași — Referință desktop Windows

[Ghidurile platformei](../windows.md)

Instalează, conectează cititorul și alege cardul.

## Instalează ediția potrivită

Pentru instalare independentă folosește **MSI** din [GitHub Releases](https://github.com/xfreebird/smartcard/releases/latest) sau instalează [eSemnBun din Microsoft Store](https://apps.microsoft.com/detail/9pdpr6rnt42s?hl=en-US&gl=MD). Alege arhitectura corespunzătoare calculatorului tău din fișierele versiunii. Un MSIX de dezvoltare nesemnat poate necesita un certificat de semnare și nu înlocuiește MSI-ul public.

1. Rulează MSI-ul și finalizează instalarea sau instalează din magazin.
2. Deschide **eSemnBun** din Start. Fereastra principală apare la prima pornire.
3. Conectează cititorul. miniLector folosește driverul CCID și serviciul Smart Card din Windows.
4. Introdu cardul și așteaptă încărcarea certificatului. Verifică titularul și expirarea înainte de semnare.

Captura existentă arată interfața în engleză; aspectul ei urmează tema luminoasă sau întunecată a site-ului.

<PlatformScreenshots platform="windows" alt="Pagina de semnare Windows cu cardul deasupra zonei de plasare a documentelor" caption="Spațiul de lucru Windows în captura existentă în engleză, în tema site-ului." />

Mai multe carduri apar în caruselul orizontal. Selectează cardul centrat cu care intenționezi să semnezi. Ilustrația folosește datele certificatului și un avatar neutru, nu fotografia din actul de identitate.
