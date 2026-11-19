---
title: "Decriptează un fișier primit — Tabletă Android"
sidebar_label: "Decriptează un fișier primit"
description: "Decriptează un fișier primit"
pagination_prev: "platforms/android-tablet/encrypt-password"
pagination_next: null
---

import GuideScreenshot from '@site/src/components/GuideScreenshot';

# Decriptează un fișier primit — Tabletă Android

[Ghidurile platformei](../android-tablet.md) · [Primii pași](./setup.md)

Decriptează un fișier primit

## Decriptează un fișier primit

Deschide **Documente**, apoi alege **Mai multe acțiuni → Protejează fișiere** în bara de sus. Alege **Criptează** sau **Decriptează**, apoi un fișier accesibil.

Pentru un fișier criptat cu parolă, cere parola expeditorului printr-un canal de încredere separat. Fișierul specifică dimensiunea cheii AES. Pentru fișierele RSA, conectează cardul care conține cheia de criptare a destinatarului, citește cardul și autorizează decriptarea cu PIN-ul său.

<GuideScreenshot src="/img/guide/android-tablet/ro/protect-menu-light.png" alt="Deschide protecția fișierelor" steps={[{"text": "Deschide meniul de navigare și alege Protejează fișiere.", "x": 89.3, "y": 13.6}]} />

<GuideScreenshot src="/img/guide/android-tablet/ro/protect-decrypt-light.png" alt="Decriptează un fișier primit" steps={[{"text": "Alege Decriptează și selectează fișierul criptat primit.", "x": 42.5, "y": 26.6}, {"text": "Introdu parola primită de la expeditor în câmpul Parolă.", "x": 30.6, "y": 42.1}, {"text": "Alege Decriptează. Rezultatul nou este salvat în Documente.", "x": 45.9, "y": 89.0}]} />

<GuideScreenshot src="/img/guide/android-tablet/ro/protect-rsa-decrypt-light.png" alt="Decriptează cu cardul destinatarului" steps={[{"text": "Selectează fișierul criptat. Aplicația identifică formatul cu certificat RSA.", "x": 29.6, "y": 36.8}, {"text": "Conectează cardul care conține cheia privată a destinatarului. Citește cardul, apoi autorizează decriptarea cu PIN-ul său.", "x": 36.6, "y": 46.0}]} />

<GuideScreenshot src="/img/guide/android-tablet/ro/protect-decrypt-complete-light.png" alt="Fișier decriptat salvat" steps={[{"text": "Verifică numele fișierului salvat. Rezultatul este deja în Documente.", "x": 29.6, "y": 27.9}, {"text": "Alege Salvează ca… numai dacă dorești și o copie în alt loc.", "x": 45.5, "y": 84.6}, {"text": "Alege Închide pentru a reveni în aplicație. Fișierul salvat rămâne în Documente.", "x": 46.8, "y": 89.0}]} />

Deschide și verifică rezultatul salvat înainte de utilizare. Criptarea compatibilă MoldSign nu autentifică conținutul: decriptarea reușită nu dovedește singură integritatea sau parola corectă.

Alege **Criptează** sau **Decriptează**. Rezultatul este salvat automat în spațiul privat al aplicației și apare în **Documente → Documente salvate**. Alege **Închide** la final sau **Salvează ca…** pentru a-l exporta prin selectorul de fișiere Android. Originalul este păstrat.

Documente salvate include fișiere semnate, criptate și decriptate. Identifică rezultatul după numele fișierului și eticheta operațiunii. Criptarea nu creează o semnătură digitală; fișierele criptate trebuie decriptate înainte de deschiderea sau verificarea conținutului.
