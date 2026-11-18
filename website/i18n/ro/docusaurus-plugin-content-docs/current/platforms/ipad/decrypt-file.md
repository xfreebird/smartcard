---
title: "Decriptează un fișier primit — iPad"
sidebar_label: "Decriptează un fișier primit"
description: "Decriptează un fișier primit"
pagination_prev: "platforms/ipad/encrypt-password"
pagination_next: null
---

import GuideScreenshot from '@site/src/components/GuideScreenshot';

# Decriptează un fișier primit — iPad

[Ghidurile platformei](../ipad.md) · [Instalare și conectarea cititorului](./setup.md)

Decriptează un fișier primit

## Decriptează un fișier primit

În **Documente**, alege **Protejează fișiere** din bara de instrumente. Dacă spațiul este limitat, găsești opțiunea în meniul Mai multe (…). În formular, alege **Criptează** sau **Decriptează**, apoi un fișier accesibil.

Pentru un fișier criptat cu parolă, cere parola expeditorului printr-un canal de încredere separat. Fișierul specifică dimensiunea cheii AES. Pentru fișierele RSA, în versiunea 0.2.13 conectează cardul care conține cheia de criptare a destinatarului, citește cardul și autorizează decriptarea cu PIN-ul său.

<GuideScreenshot src="/img/guide/ipad/ro/documents-protection-light.png" alt="Deschide meniul Mai multe (…) și alege Protejează fișiere." steps={[{"text": "Deschide meniul Mai multe (…) și alege Protejează fișiere.", "x": 74, "y": 15}]} />

<GuideScreenshot src="/img/guide/ipad/ro/protect-decrypt-light.png" alt="Selectează fișierul criptat. Când apare Parolă, introdu parola primită separat de la expeditor și apasă Decriptează." steps={[{"text": "Selectează fișierul criptat. Când apare Parolă, introdu parola primită separat de la expeditor și apasă Decriptează.", "x": 81, "y": 52}]} />

<GuideScreenshot src="/img/guide/ipad/ro/protect-rsa-decrypt.png" alt="Pentru un fișier RSA, conectează cititorul și cardul destinatarului, apoi alege Citește cardul meu. Autorizează cu PIN-ul cardului." steps={[{"text": "Pentru un fișier RSA, conectează cititorul și cardul destinatarului, apoi alege Citește cardul meu. Autorizează cu PIN-ul cardului.", "x": 30, "y": 61}]} />

<GuideScreenshot src="/img/guide/ipad/ro/protect-decrypt-complete-light.png" alt="Rezultatul este salvat în Documente. Alege Salvează o copie pentru export sau Gata pentru a reveni." steps={[{"text": "Rezultatul este salvat în Documente. Alege Salvează o copie pentru export sau Gata pentru a reveni.", "x": 50, "y": 62}]} />

Deschide și verifică rezultatul salvat înainte de utilizare. Criptarea compatibilă MoldSign nu autentifică conținutul: decriptarea reușită nu dovedește singură integritatea sau parola corectă.

Alege **Criptează** sau **Decriptează**. Rezultatul nou este salvat automat în **Documente → Documente salvate**. Alege **Gata** pentru a reveni sau **Salvează o copie** pentru a-l exporta în Fișiere ori în alt loc. Originalul este păstrat.

Documente salvate include fișiere semnate, criptate și decriptate. Identifică rezultatul după numele fișierului și eticheta operațiunii. Criptarea nu creează o semnătură digitală; fișierele criptate trebuie decriptate înainte de deschiderea sau verificarea conținutului.
