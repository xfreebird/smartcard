---
title: "Decriptează un fișier primit — iPhone"
sidebar_label: "Decriptează un fișier primit"
description: "Decriptează un fișier primit"
pagination_prev: "platforms/ios/encrypt-password"
pagination_next: null
---

import GuideScreenshot from '@site/src/components/GuideScreenshot';

# Decriptează un fișier primit — iPhone

[Ghidurile platformei](../ios.md) · [Primii pași](./setup.md)

Decriptează un fișier primit

## Decriptează un fișier primit

În **Documente**, apasă scutul **Protejează fișiere** din bara de instrumente. În formular, alege **Criptează** sau **Decriptează**, apoi un fișier accesibil.

Pentru un fișier criptat cu parolă, cere parola expeditorului printr-un canal de încredere separat. Fișierul specifică dimensiunea cheii AES. Pentru fișierele RSA, în versiunea 0.2.13 conectează cardul care conține cheia de criptare a destinatarului, citește cardul și autorizează decriptarea cu PIN-ul său.

<GuideScreenshot src="/img/guide/iphone/ro/documents-protection-light.png" alt="În Documente, deschide Protejează fișiere din bara de instrumente apăsând scutul." steps={[{"text": "În Documente, deschide Protejează fișiere din bara de instrumente apăsând scutul.", "x": 90, "y": 10}]} />

<GuideScreenshot src="/img/guide/iphone/ro/protect-decrypt-light.png" alt="Selectează fișierul criptat. Când apare Parolă, introdu parola primită separat de la expeditor și apasă Decriptează." steps={[{"text": "Selectează fișierul criptat. Când apare Parolă, introdu parola primită separat de la expeditor și apasă Decriptează.", "x": 86, "y": 48}]} />

<GuideScreenshot src="/img/guide/iphone/ro/protect-rsa-decrypt.png" alt="Pentru un fișier RSA, conectează cititorul și cardul destinatarului, apoi alege Citește cardul meu. Autorizează cu PIN-ul cardului." steps={[{"text": "Pentru un fișier RSA, conectează cititorul și cardul destinatarului, apoi alege Citește cardul meu. Autorizează cu PIN-ul cardului.", "x": 35.5, "y": 70.6}]} />

<GuideScreenshot src="/img/guide/iphone/ro/protect-decrypt-complete-light.png" alt="Rezultatul este salvat în Documente. Alege Salvează o copie pentru export sau Gata pentru a reveni." steps={[{"text": "Rezultatul este salvat în Documente. Alege Salvează o copie pentru export sau Gata pentru a reveni.", "x": 50, "y": 68}]} />

Deschide și verifică rezultatul salvat înainte de utilizare. Criptarea compatibilă MoldSign nu autentifică conținutul: decriptarea reușită nu dovedește singură integritatea sau parola corectă.

Alege **Criptează** sau **Decriptează**. Rezultatul nou este salvat automat în **Documente → Documente salvate**. Alege **Gata** pentru a reveni sau **Salvează o copie** pentru a-l exporta în Fișiere ori în alt loc. Originalul este păstrat.

Documente salvate include fișiere semnate, criptate și decriptate. Identifică rezultatul după numele fișierului și eticheta operațiunii. Criptarea nu creează o semnătură digitală; fișierele criptate trebuie decriptate înainte de deschiderea sau verificarea conținutului.
