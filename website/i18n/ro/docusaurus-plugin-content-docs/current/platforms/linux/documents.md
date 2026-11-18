---
title: "Găsește documentele salvate — Linux"
sidebar_label: "Găsește documentele salvate"
description: "Deschide detaliile semnării, distribuie fișierele și golește istoricul recent."
pagination_prev: "platforms/linux/results"
pagination_next: "platforms/linux/browser"
---

import GuideScreenshot from '@site/src/components/GuideScreenshot';

# Găsește documentele salvate — Linux

[Ghidurile platformei](../linux.md) · [Instalare și conectarea cititorului](./setup.md)

Deschide detaliile semnării, distribuie fișierele și golește istoricul recent.

## Găsește documentele semnate

Documente salvate conține rezultate semnate, criptate și decriptate. Selectează un fișier semnat pentru detaliile semnăturii. Un fișier criptat oferă decriptarea; conținutul criptat nu este trimis la verificarea semnăturii. Fișierele decriptate își păstrează tipul rezultatului și pot fi deschise sau exportate.

Documente conține colecția rezultatelor semnate și un Istoric separat al operațiilor. Intrările trimit la fișiere și nu înlocuiesc o copie de rezervă. Un fișier mutat trebuie selectat din nou la noua locație.

<GuideScreenshot src="/img/guide/linux/ro/documents.png" alt="Găsește documentele semnate" steps={[{"text": "Selectează numele fișierului pentru a-i examina semnăturile.", "x": 28, "y": 30}, {"text": "Deschide fișierul direct din rândul său.", "x": 67, "y": 30}, {"text": "Folosește butonul cu dosar pentru a localiza fișierul salvat.", "x": 76, "y": 30}]} />

## Deschide detaliile semnării

Selectează numele unui fișier salvat pentru a-i verifica conținutul actual în fereastra de detalii. Exemplul folosește un semnatar fictiv și un certificat autosemnat, astfel că lanțul de încredere nu este confirmat. Poți deschide documentul sau dosarul său din partea de jos a ferestrei.

<GuideScreenshot src="/img/guide/linux/ro/details.png" alt="Deschide detaliile semnării" steps={[{"text": "Citește rezultatul verificării și verifică semnatarul.", "x": 37, "y": 34}, {"text": "Deschide documentul sau afișează-l în dosarul său.", "x": 65, "y": 79}]} />

## Golește istoricul păstrând documentele

Treci la Istoric, alege Golește lista și citește confirmarea. Eliminarea istoricului nu șterge fișierele sau colecția separată de documente semnate. Revino apoi la colecție.

<GuideScreenshot src="/img/guide/linux/ro/history.png" alt="Golește istoricul păstrând documentele" steps={[{"text": "Citește Istoric; Documente salvate revine la colecție.", "x": 14, "y": 11}, {"text": "Golește lista și confirmă eliminarea doar a istoricului.", "x": 73, "y": 20}]} />

<GuideScreenshot src="/img/guide/linux/ro/history-confirm.png" alt="Golește istoricul păstrând documentele" start={3} steps={[{"x": 57, "y": 57, "text": "Citește confirmarea pentru istoric, apoi alege Golește lista sau Anulează. Documentele semnate rămân disponibile."}]} />
