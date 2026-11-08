---
title: "Verifică o semnătură — Telefon Android"
sidebar_label: "Verifică o semnătură"
description: "Verifică un PDF sau XML și inspectează semnatarul și certificatul."
pagination_prev: "platforms/android/signing"
pagination_next: "platforms/android/results"
---

import GuideScreenshot from '@site/src/components/GuideScreenshot';

# Verifică o semnătură — Telefon Android

[Ghidurile platformei](../android.md) · [Instalare și conectarea cititorului](./setup.md)

Verifică un PDF sau XML și inspectează semnatarul și certificatul.

Ilustrațiile folosesc date fictive. Urmează instrucțiunile în aplicația instalată.

## Verifică un document semnat

Verificarea nu necesită card sau PIN. Rezultatul verde privește verificările afișate, nu numele fișierului sau prezența ștampilei vizibile.

<GuideScreenshot src="/img/guide/android-phone/ro/verify.png" alt="Verifică un document semnat" steps={[{"text": "Deschide Verifică, alege PDF-ul sau XML-ul semnat și așteaptă rezultatul. Folosește selectorul sistemului pentru fișiere din alte aplicații sau furnizori.", "x": 34.4, "y": 29.3}, {"text": "Citește verdictul și, pentru fiecare semnătură, autorul, data, marca temporală, integritatea și lanțul de încredere.", "x": 18.5, "y": 51.0}, {"text": "Elimină intrarea cu × pentru a-i șterge rezultatul sau curăță toate rezultatele înainte de o verificare nouă.", "x": 80.5, "y": 41.6}]} />

## Consultă certificatul și detaliile tehnice

O semnătură invalidă diferă de un lanț de încredere neconfirmat. Lipsa originalelor sau a informațiilor de încredere poate împiedica un verdict complet. Consultă verificările separate.

<GuideScreenshot src="/img/guide/android-phone/ro/certificate.png" alt="Consultă certificatul și detaliile tehnice" steps={[{"text": "Extinde Detalii certificat pentru titular, emitent, număr de serie, cheie publică și amprentă. Derulează dacă este necesar.", "x": 36.1, "y": 61.9}, {"text": "Extinde Detalii tehnice pentru verificările care susțin verdictul și restrânge secțiunea după consultare.", "x": 34.3, "y": 82.9}]} />

## Furnizează originalul pentru XML detașat

XML-ul detașat conține o referință la document. Verificarea amprentei necesită octeții originali ai fișierului.

<GuideScreenshot src="/img/guide/android-phone/ro/original.png" alt="Furnizează originalul pentru XML detașat" steps={[{"text": "Atinge Alege documentul semnat și selectează originalul exact indicat în mesaj.", "x": 11.6, "y": 68.4}, {"text": "Așteaptă rezultatul actualizat. Un original modificat sau alt fișier nu va corespunde semnăturii. Distribuie XML-ul împreună cu originalul potrivit."}]} />
