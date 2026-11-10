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

<GuideScreenshot src="/img/guide/linux/ro/documents.png" alt="Găsește documentele semnate" steps={[{"text": "Deschide Documente.", "x": 55, "y": 3}, {"text": "Alege rândul documentului salvat.", "x": 42, "y": 26}, {"text": "Folosește detaliile sau pictograma dosarului.", "x": 36, "y": 37}]} />

## Deschide detaliile semnării

Apasă rândul sau Detalii semnare pentru fereastra modală. Aceasta verifică fișierul curent fără să înlocuiască spațiul Verifică ori să adauge o operație în istoric. Exemplul chiar este nesemnat, astfel că mesajul de lipsă a semnăturii este corect. Închide fereastra pentru listă; pictograma dosarului localizează fișierul.

<GuideScreenshot src="/img/guide/linux/ro/details.png" alt="Deschide detaliile semnării" steps={[{"text": "Citește rezultatul nou în fereastra de detalii.", "x": 50, "y": 27}, {"text": "Închide fereastra pentru a reveni la listă.", "x": 73, "y": 12}]} />

## Golește istoricul păstrând documentele

Treci la Istoric, alege Golește lista și citește confirmarea. Eliminarea istoricului nu șterge fișierele sau colecția separată de documente semnate. Revino apoi la colecție.

<GuideScreenshot src="/img/guide/linux/ro/history.png" alt="Golește istoricul păstrând documentele" steps={[{"text": "Citește Istoric; Documente salvate revine la colecție.", "x": 17, "y": 10}, {"text": "Golește lista și confirmă eliminarea doar a istoricului.", "x": 79, "y": 20}]} />

<GuideScreenshot src="/img/guide/linux/ro/history-confirm.png" alt="Golește istoricul păstrând documentele" start={3} steps={[{"x": 57, "y": 57, "text": "Citește confirmarea pentru istoric, apoi alege Golește lista sau Anulează. Documentele semnate rămân disponibile."}]} />
