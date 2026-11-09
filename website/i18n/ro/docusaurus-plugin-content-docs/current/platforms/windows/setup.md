---
title: "Primii pași — Windows"
sidebar_label: "Primii pași"
description: "Instalează, conectează cititorul și alege cardul."
pagination_prev: "platforms/windows"
pagination_next: "platforms/windows/signing"
---

import GuideScreenshot from '@site/src/components/GuideScreenshot';

# Primii pași — Windows

[Ghidurile platformei](../windows.md)

Instalează, conectează cititorul și alege cardul.

## Instalează ediția potrivită

Pentru instalare independentă folosește **MSI** din [GitHub Releases](https://github.com/xfreebird/smartcard/releases/latest) sau instalează [eSemnBun din Microsoft Store](https://apps.microsoft.com/detail/9pdpr6rnt42s?hl=en-US&gl=MD). Alege arhitectura corespunzătoare calculatorului tău din fișierele versiunii. Un MSIX de dezvoltare nesemnat poate necesita un certificat de semnare și nu înlocuiește MSI-ul public.

1. Rulează MSI-ul și finalizează instalarea sau instalează din magazin.
2. Deschide **eSemnBun** din Start. Fereastra principală apare la prima pornire.
3. Conectează cititorul. miniLector folosește driverul CCID și serviciul Smart Card din Windows.
4. Introdu cardul și așteaptă încărcarea certificatului. Verifică titularul și expirarea înainte de semnare.





Mai multe carduri apar în caruselul orizontal. Selectează cardul centrat cu care intenționezi să semnezi. Ilustrația folosește datele certificatului și un avatar neutru, nu fotografia din actul de identitate.

### Alege și examinează cardul

<GuideScreenshot src="/img/guide/windows/ro/card.png" alt="Alege și examinează cardul" steps={[{"x": 6, "y": 26, "text": "Deschide Card după conectarea cititorului și introducerea cardului."}, {"x": 60, "y": 31, "text": "Verifică titularul și expirarea; alege cardul dorit din carusel."}, {"x": 51, "y": 58, "text": "Examinează certificatul și cititorul înainte de semnare."}]} />
