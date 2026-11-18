---
title: "Decriptează un fișier primit — Linux"
sidebar_label: "Decriptează un fișier primit"
description: "Decriptează un fișier primit"
pagination_prev: "platforms/linux/encrypt-password"
pagination_next: "platforms/linux/remove-file"
---

import GuideScreenshot from '@site/src/components/GuideScreenshot';

# Decriptează un fișier primit — Linux

[Ghidurile platformei](../linux.md) · [Instalare și conectarea cititorului](./setup.md)

Decriptează un fișier primit

## Decriptează un fișier primit

Deschide meniul principal din antetul ferestrei, apoi **Protejează fișiere → Criptează**, **Decriptează** sau **Elimină fișierul**. Alege un fișier accesibil; derulează formularul la nevoie.

Pentru un fișier criptat cu parolă, cere parola expeditorului printr-un canal de încredere separat. Fișierul specifică dimensiunea cheii AES. Pentru fișierele RSA, conectează cardul care conține cheia de criptare a destinatarului, citește cardul și autorizează decriptarea cu PIN-ul său.

<GuideScreenshot src="/img/guide/linux/ro/protect-decrypt-light.png" alt="Decriptează un fișier primit" steps={[{"text": "Alege fișierul criptat. Conținutul său determină metoda de decriptare.", "x": 50, "y": 29}, {"text": "Pentru un fișier criptat cu parolă, introdu parola primită de la expeditor.", "x": 30, "y": 61}, {"text": "Alege Decriptează și salvează rezultatul într-un fișier nou.", "x": 50, "y": 91}]} />

Deschide și verifică rezultatul salvat înainte de utilizare. Criptarea compatibilă MoldSign nu autentifică conținutul: decriptarea reușită nu dovedește singură integritatea sau parola corectă.

Alege **Criptează** sau **Decriptează**, apoi **Salvează o copie** și alege un loc nou pentru rezultat. După salvare, fișierul apare în **Documente → Documente salvate**. Folosește butonul de închidere din antetul ferestrei la final. Originalul este păstrat.

Documente salvate include fișiere semnate, criptate și decriptate. Identifică rezultatul după numele fișierului și eticheta operațiunii. Criptarea nu creează o semnătură digitală; fișierele criptate trebuie decriptate înainte de deschiderea sau verificarea conținutului.
