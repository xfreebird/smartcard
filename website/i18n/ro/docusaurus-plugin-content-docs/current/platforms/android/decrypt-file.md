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

Deschide **Fișiere**, apoi alege **Mai multe acțiuni → Protejează fișiere** în bara de sus. Alege **Criptează** sau **Decriptează**, apoi un fișier accesibil.

Pentru un fișier criptat cu parolă, cere parola expeditorului printr-un canal de încredere separat. Fișierul specifică dimensiunea cheii AES. Pentru fișierele RSA, conectează cardul care conține cheia de criptare a destinatarului, citește cardul și autorizează decriptarea cu PIN-ul său.

<GuideScreenshot src="/img/guide/android-phone/ro/protect-menu-light.png" alt="Deschide protecția fișierelor" steps={[{"text": "Deschide meniul de navigare și alege Protejează fișiere.", "x": 65.0, "y": 15.3}]} />

<GuideScreenshot src="/img/guide/android-phone/ro/protect-decrypt-light.png" alt="Decriptează un fișier primit" steps={[{"text": "Alege Decriptează și selectează fișierul criptat primit.", "x": 26.5, "y": 30.5}, {"text": "Introdu parola primită de la expeditor în câmpul Parolă.", "x": 11.0, "y": 49.2}, {"text": "Alege Decriptează. Rezultatul nou este salvat în Documente.", "x": 39.3, "y": 88.1}]} />

<GuideScreenshot src="/img/guide/android-phone/ro/protect-rsa-decrypt-light.png" alt="Decriptează cu cardul destinatarului" steps={[{"text": "Selectează fișierul criptat. Aplicația identifică formatul cu certificat RSA.", "x": 7.1, "y": 42.9}, {"text": "Conectează cardul care conține cheia privată a destinatarului. Citește cardul, apoi autorizează decriptarea cu PIN-ul său.", "x": 28.9, "y": 57.3}]} />

<GuideScreenshot src="/img/guide/android-phone/ro/protect-decrypt-complete-light.png" alt="Fișier decriptat salvat" steps={[{"text": "Verifică numele fișierului salvat. Rezultatul este deja în Documente.", "x": 7.1, "y": 32.0}, {"text": "Alege Salvează ca… numai dacă dorești și o copie în alt loc.", "x": 38.2, "y": 82.9}, {"text": "Alege Închide pentru a reveni în aplicație. Fișierul salvat rămâne în Documente.", "x": 42.7, "y": 88.1}]} />

Deschide și verifică rezultatul salvat înainte de utilizare. Criptarea compatibilă MoldSign nu autentifică conținutul: decriptarea reușită nu dovedește singură integritatea sau parola corectă.

Alege **Criptează** sau **Decriptează**. Rezultatul este salvat automat în spațiul privat al aplicației și apare în **Documente → Documente salvate**. Alege **Închide** la final sau **Salvează ca…** pentru a-l exporta prin selectorul de fișiere Android. Originalul este păstrat.

Documente salvate include fișiere semnate, criptate și decriptate. Identifică rezultatul după numele fișierului și eticheta operațiunii. Criptarea nu creează o semnătură digitală; fișierele criptate trebuie decriptate înainte de deschiderea sau verificarea conținutului.
