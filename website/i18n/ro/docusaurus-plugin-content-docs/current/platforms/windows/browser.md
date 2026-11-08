---
title: "Semnează pe site-uri — Windows"
sidebar_label: "Semnează pe site-uri"
description: "Conectează un serviciu, verifică cererile și gestionează sesiunile web."
pagination_prev: "platforms/windows/preferences"
pagination_next: "platforms/windows/help"
---

import GuideScreenshot from '@site/src/components/GuideScreenshot';

# Semnează pe site-uri — Windows

[Ghidurile platformei](../windows.md) · [Instalare și conectarea cititorului](./setup.md)

Conectează un serviciu, verifică cererile și gestionează sesiunile web.

Ilustrațiile folosesc date fictive. Urmează instrucțiunile în aplicația instalată.

## Folosește conexiunea cu browserul

Activează **Browser connection (Conexiune cu browserul)** în Configurări. Deschide un serviciu acceptat într-un browser pe același calculator Windows. Când sosește o cerere, verifică site-ul, fișierele și cardul selectat înainte de autorizare.

Dacă alt server MoldSign ocupă porturile, finalizează operațiunile active ale aplicației furnizorului și folosește acțiunea oferită pentru rezolvarea conflictului, dacă există. Un singur bridge poate folosi porturile 18480/18443 la un moment dat. Dacă browserul cere acces la rețeaua locală, acordă-l pentru serviciul dorit, ca să poată contacta bridge-ul local. Consultă [serviciile în browser](/docs/browser).

### Gestionează PIN-urile salvate și conexiunea browserului

<GuideScreenshot src="/img/guide/windows/ro/lower.png" alt="Gestionează PIN-urile salvate și conexiunea browserului" steps={[{"x": 27, "y": 21, "text": "Verifică preferințele PIN salvate. Ștergerea unei intrări din aplicație nu schimbă PIN-ul cardului."}, {"x": 27, "y": 44, "text": "Activează Conexiune browser și deschide serviciul dorit în browser pe acest computer. Verifică fiecare cerere de semnare."}]} />
