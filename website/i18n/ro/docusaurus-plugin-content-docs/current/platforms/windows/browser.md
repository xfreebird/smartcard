---
title: "Semnează pe site-uri — Windows"
sidebar_label: "Semnează pe site-uri"
description: "Conectează un serviciu, verifică cererile și gestionează sesiunile web."
pagination_prev: "platforms/windows/preferences"
pagination_next: "platforms/windows/approval"
---

import GuideScreenshot from '@site/src/components/GuideScreenshot';

# Semnează pe site-uri — Windows

[Ghidurile platformei](../windows.md) · [Instalare și conectarea cititorului](./setup.md)

Conectează un serviciu, verifică cererile și gestionează sesiunile web.

## Folosește conexiunea cu browserul

Activează **Browser connection (Conexiune cu browserul)** în Configurări. Deschide un serviciu acceptat într-un browser pe același calculator Windows. Când sosește o cerere, verifică site-ul, fișierele și cardul selectat înainte de autorizare.

Dacă alt server MoldSign ocupă porturile, finalizează operațiunile active ale aplicației furnizorului și folosește acțiunea oferită pentru rezolvarea conflictului, dacă există. Un singur bridge poate folosi porturile 18480/18443 la un moment dat. Dacă browserul cere acces la rețeaua locală, acordă-l pentru serviciul dorit, ca să poată contacta bridge-ul local. Consultă [serviciile în browser](/docs/browser).


<GuideScreenshot src="/img/guide/windows/ro/lower.png" alt="Browser connection" steps={[{"x": 25.5, "y": 23.7, "text": "Activează Conexiunea browser doar când folosești un site compatibil."}, {"x": 25.5, "y": 36, "text": "Opțional, activează ștampilele pentru browser și verifică poziția înainte de semnare."}]} />
