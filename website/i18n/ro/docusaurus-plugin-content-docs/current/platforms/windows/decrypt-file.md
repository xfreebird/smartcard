---
title: "Decriptează un fișier primit — Windows"
sidebar_label: "Decriptează un fișier primit"
description: "Decriptează un fișier primit"
pagination_prev: "platforms/windows/encrypt-password"
pagination_next: "platforms/windows/remove-file"
---

import GuideScreenshot from '@site/src/components/GuideScreenshot';

# Decriptează un fișier primit — Windows

[Ghidurile platformei](../windows.md) · [Instalare și conectarea cititorului](./setup.md)

Decriptează un fișier primit

## Decriptează un fișier primit

Deschide **Protejează fișiere** în partea de jos a barei de navigare și alege **Criptează**, **Decriptează** sau **Elimină fișierul**. Alege un fișier accesibil; derulează formularul la nevoie.

Obține parola de la expeditor printr-un canal de încredere separat. Alege fișierul criptat, apoi introdu parola în câmpul cu contur **Parolă**. Nu ai nevoie de cititor, card sau PIN-ul cardului.

<GuideScreenshot src="/img/guide/windows/ro/protect-decrypt-light.png" alt="Decriptează un fișier primit" steps={[{"x": 39.852, "y": 24.163, "text": "Alege Decriptează și selectează fișierul criptat primit."}, {"x": 39.852, "y": 56.568, "text": "Introdu parola primită de la expeditor în câmpul Parolă."}, {"x": 39.852, "y": 86.948, "text": "Alege Decriptează și salvează rezultatul cu un nume nou."}]} />

Deschide și verifică rezultatul salvat înainte de utilizare. Criptarea compatibilă MoldSign nu autentifică conținutul: decriptarea reușită nu dovedește singură integritatea sau parola corectă.

Alege **Criptează** sau **Decriptează**, apoi **Salvează o copie** și alege un loc nou pentru rezultat. După salvare, fișierul apare în **Documente → Documente salvate**. Alege **Închide** pentru a închide operațiunea finalizată. Originalul este păstrat.

Documente salvate include fișiere semnate, criptate și decriptate. Identifică rezultatul după numele fișierului și eticheta operațiunii. Criptarea nu creează o semnătură digitală; fișierele criptate trebuie decriptate înainte de deschiderea sau verificarea conținutului.
