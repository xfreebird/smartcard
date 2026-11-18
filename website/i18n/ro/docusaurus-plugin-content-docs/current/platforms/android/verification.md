---
title: "Verifică o semnătură — Telefon Android"
sidebar_label: "Verifică o semnătură"
description: "Verifică un PDF sau XML și inspectează semnatarul și certificatul."
pagination_prev: "platforms/android/signing"
pagination_next: "platforms/android/results"
---

import GuideScreenshot from '@site/src/components/GuideScreenshot';

# Verifică o semnătură — Telefon Android

[Ghidurile platformei](../android.md) · [Primii pași](./setup.md)

Verifică un PDF sau XML și inspectează semnatarul și certificatul.

## Verifică un document semnat

Verificarea nu necesită card sau PIN. Rezultatul verde privește verificările afișate, nu numele fișierului sau prezența ștampilei vizibile.

<GuideScreenshot src="/img/guide/android-phone/ro/verify-current.png" alt="Ecranul Verifică" steps={[{"text": "Alege un PDF sau XML semnat. Verifică verdictul, semnatarul și rezultatele verificărilor.", "x": 18.8, "y": 31.3}, {"text": "Extinde Detalii tehnice pentru a consulta raportul. Atinge din nou pentru a-l restrânge.", "x": 6.1, "y": 73.4}]} />

## Consultă certificatul și detaliile tehnice

O semnătură invalidă diferă de un lanț de încredere neconfirmat. Lipsa originalelor sau a informațiilor de încredere poate împiedica un verdict complet. Consultă verificările separate.

<GuideScreenshot src="/img/guide/android-phone/ro/certificate.png" alt="Consultă certificatul și detaliile tehnice" steps={[{"text": "Extinde Detalii certificat pentru titular, emitent, număr de serie, cheie publică și amprentă. Derulează dacă este necesar.", "x": 6.1, "y": 64.4}, {"text": "Extinde Detalii tehnice pentru verificările care susțin verdictul și restrânge secțiunea după consultare.", "x": 6.1, "y": 82.9}]} />

<GuideScreenshot src="/img/guide/android-phone/ro/verify-technical.png" alt="Detalii tehnice extinse" steps={[{"text": "În acest exemplu, liniile în engleză indică verificarea offline a amprentei documentului și a lanțului de certificate. Atinge din nou Detalii tehnice pentru a restrânge raportul.", "x": 6.1, "y": 73.4}]} />

## Furnizează originalul pentru XML detașat

XML-ul detașat conține o referință la document. Verificarea amprentei necesită octeții originali ai fișierului.

<GuideScreenshot src="/img/guide/android-phone/ro/original.png" alt="Furnizează originalul pentru XML detașat" steps={[{"text": "Atinge Alege documentul semnat și selectează originalul exact indicat în mesaj.", "x": 11.9, "y": 48.7}, {"text": "Așteaptă rezultatul actualizat. Un original modificat sau alt fișier nu va corespunde semnăturii. Distribuie XML-ul împreună cu originalul potrivit."}]} />
