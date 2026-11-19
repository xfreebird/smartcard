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

Pentru un fișier criptat cu parolă, cere parola expeditorului printr-un canal de încredere separat. Fișierul specifică dimensiunea cheii AES. Pentru fișierele RSA, conectează cardul care conține cheia de criptare a destinatarului, citește cardul și autorizează decriptarea cu PIN-ul său.

<GuideScreenshot src="/img/guide/windows/ro/protect-decrypt-light.png" alt="Decriptează un fișier primit" steps={[{"text": "Alege fișierul criptat. Conținutul său determină metoda de decriptare.", "x": 33, "y": 33}, {"text": "Pentru un fișier criptat cu parolă, introdu parola primită de la expeditor.", "x": 40, "y": 60}, {"text": "Alege Decriptează și salvează rezultatul într-un fișier nou.", "x": 39, "y": 84}]} />

<GuideScreenshot src="/img/guide/windows/ro/protect-rsa-decrypt-light.png" alt="Pentru un fișier RSA, conectează cititorul și cardul destinatarului, apoi alege Citește cardul meu. Autorizează cu PIN-ul cardului." steps={[{"text": "Pentru un fișier RSA, conectează cititorul și cardul destinatarului, apoi alege Citește cardul meu. Autorizează cu PIN-ul cardului.", "x": 38.0, "y": 61.4}]} />

Deschide și verifică rezultatul salvat înainte de utilizare. Criptarea compatibilă MoldSign nu autentifică conținutul: decriptarea reușită nu dovedește singură integritatea sau parola corectă.

Alege **Criptează** sau **Decriptează**, apoi **Salvează o copie** și alege un loc nou pentru rezultat. După salvare, fișierul apare în **Documente → Documente salvate**. Alege **Închide** pentru a închide operațiunea finalizată. Originalul este păstrat.

Documente salvate include fișiere semnate, criptate și decriptate. Identifică rezultatul după numele fișierului și eticheta operațiunii. Criptarea nu creează o semnătură digitală; fișierele criptate trebuie decriptate înainte de deschiderea sau verificarea conținutului.
