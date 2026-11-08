---
title: "Rezolvă o problemă — Windows"
sidebar_label: "Rezolvă o problemă"
description: "Rezolvă în siguranță problemele de cititor, PIN, document și conexiune."
pagination_prev: "platforms/windows/browser"
pagination_next: null
---

import GuideScreenshot from '@site/src/components/GuideScreenshot';

# Rezolvă o problemă — Windows

[Ghidurile platformei](../windows.md) · [Instalare și conectarea cititorului](./setup.md)

Rezolvă în siguranță problemele de cititor, PIN, document și conexiune.

Ilustrațiile folosesc date fictive. Urmează instrucțiunile în aplicația instalată.

## Actualizează sau rezolvă o problemă

Instalările Microsoft Store se actualizează prin magazin. Versiunile independente oferă verificări de actualizare care deschid pagina de descărcare; instalează MSI-ul nou al versiunii.

| Simptom | Pasul următor |
| --- | --- |
| Cititorul lipsește | Verifică cititorul de carduri inteligente în Device Manager; reconectează-l și verifică serviciul Smart Card. |
| Certificatul nu se încarcă | Reintrodu cardul și lasă citirea să se încheie. |
| Identitate greșită | Selectează cardul dorit înainte de a introduce PIN-ul lui. |
| Portul browserului este ocupat | Oprește serverul concurent recunoscut, apoi reconectează. |
| PIN-ul salvat nu este disponibil | Introdu PIN-ul manual și verifică autentificarea/configurările Windows. |
| Documentul eșuează | Citește eroarea, păstrează sursa și corectează cauza înainte de a reîncerca. |

Oprește-te după un rezultat de PIN incorect și verifică PIN-ul, în loc să îl ghicești. Raportează versiunile aplicației și Windows, ediția MSI sau Store, arhitectura, modelul cititorului și pașii de reproducere. Consultă [depanarea](/docs/troubleshooting).

### Acționează când cititorul nu este detectat

<GuideScreenshot src="/img/guide/windows/ro/none.png" alt="Acționează când cititorul nu este detectat" steps={[{"x": 60, "y": 34, "text": "Citește îndrumările de conectare, reconectează cititorul USB și introdu cardul."}, {"x": 88, "y": 13, "text": "Recitește cardul după corectarea conexiunii. La o eroare PIN oprește-te; nu încerca să ghicești."}]} />
