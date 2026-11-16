---
title: "Decriptează un fișier primit — Telefon Android"
sidebar_label: "Decriptează un fișier primit"
description: "Decriptează un fișier primit"
pagination_prev: "platforms/android/encrypt-password"
pagination_next: null
---

import GuideScreenshot from '@site/src/components/GuideScreenshot';

# Decriptează un fișier primit — Telefon Android

[Ghidurile platformei](../android.md) · [Primii pași](./setup.md)

Decriptează un fișier primit

## Decriptează un fișier primit

Deschide meniul **Mai multe** din bara de navigare și alege **Protejează fișiere**. Alege **Criptează** sau **Decriptează**, apoi un fișier accesibil.

Obține parola de la expeditor printr-un canal de încredere separat. Alege fișierul criptat, apoi introdu parola în câmpul cu contur **Parolă**. Nu ai nevoie de cititor, card sau PIN-ul cardului.

<GuideScreenshot src="/img/guide/android-phone/ro/protect-menu-light.png" alt="Deschide protecția fișierelor" steps={[{"x": 70, "y": 15, "text": "Deschide meniul de navigare și alege Protejează fișiere."}]} />

<GuideScreenshot src="/img/guide/android-phone/ro/protect-decrypt-light.png" alt="Decriptează un fișier primit" start={2} steps={[{"x": 27, "y": 20, "text": "Alege Decriptează și selectează fișierul criptat primit."}, {"x": 25, "y": 55, "text": "Introdu parola primită de la expeditor în câmpul Parolă."}, {"x": 50, "y": 88, "text": "Alege Decriptează. Rezultatul nou este salvat în Documente."}]} />

<GuideScreenshot src="/img/guide/android-phone/ro/protect-decrypt-complete-light.png" alt="Fișier decriptat salvat" start={5} steps={[{"x": 25, "y": 33, "text": "Verifică numele fișierului salvat. Rezultatul este deja în Documente."}, {"x": 25, "y": 83, "text": "Alege Salvează ca… numai dacă dorești și o copie în alt loc."}, {"x": 75, "y": 88, "text": "Alege Închide pentru a reveni în aplicație. Fișierul salvat rămâne în Documente."}]} />

Deschide și verifică rezultatul salvat înainte de utilizare. Criptarea compatibilă MoldSign nu autentifică conținutul: decriptarea reușită nu dovedește singură integritatea sau parola corectă.

Alege **Criptează** sau **Decriptează**. Rezultatul este salvat automat în spațiul privat al aplicației și apare în **Documente → Documente salvate**. Alege **Închide** la final sau **Salvează ca…** pentru a-l exporta prin selectorul de fișiere Android. Originalul este păstrat.

Documente salvate include fișiere semnate, criptate și decriptate. Identifică rezultatul după numele fișierului și eticheta operațiunii. Criptarea nu creează o semnătură digitală; fișierele criptate trebuie decriptate înainte de deschiderea sau verificarea conținutului.
