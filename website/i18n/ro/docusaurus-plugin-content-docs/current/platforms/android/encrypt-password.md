---
title: "Criptează un fișier cu parolă — Telefon Android"
sidebar_label: "Criptează un fișier cu parolă"
description: "Criptează un fișier cu parolă"
pagination_prev: "platforms/android/help"
pagination_next: "platforms/android/decrypt-file"
---

import GuideScreenshot from '@site/src/components/GuideScreenshot';

# Criptează un fișier cu parolă — Telefon Android

[Ghidurile platformei](../android.md) · [Primii pași](./setup.md)

Criptează un fișier cu parolă

## Criptează un fișier cu parolă

Deschide **Fișiere**, apoi alege **Mai multe acțiuni → Protejează fișiere** în bara de sus. Alege **Criptează** sau **Decriptează**, apoi un fișier accesibil.

Nu ai nevoie de card. Creează o parolă pentru fișier și transmite-o destinatarului printr-un canal de încredere separat. Nu este PIN-ul cardului. Criptarea creează un rezultat separat; păstrează originalul până verifici rezultatul.

În eSemnBun 0.2.13 sau mai nou, alege **Parolă** și selectează AES-128, AES-192 sau AES-256. Opțiunea implicită este AES-256. Pentru a cripta pentru un destinatar, alege **Certificat RSA** și selectează certificatul său public de criptare (.cer sau .der). Certificatul de semnare al cărții de identitate moldovenești nu poate decripta aceste fișiere.

<GuideScreenshot src="/img/guide/android-phone/ro/protect-menu-light.png" alt="Deschide protecția fișierelor" steps={[{"text": "Deschide meniul de navigare și alege Protejează fișiere.", "x": 65.0, "y": 15.3}]} />

<GuideScreenshot src="/img/guide/android-phone/ro/protect-password-light.png" alt="Criptează un fișier cu parolă" steps={[{"text": "Alege Criptează și selectează fișierul sursă.", "x": 38.8, "y": 30.5}, {"text": "Alege Parolă și dimensiunea cheii AES. Inițial este selectat AES-256.", "x": 72.8, "y": 51.0}, {"text": "Introdu și confirmă parola fișierului, apoi alege Criptează.", "x": 11.0, "y": 67.2}]} />

<GuideScreenshot src="/img/guide/android-phone/ro/protect-certificate-light.png" alt="Criptează pentru un destinatar RSA" steps={[{"text": "Pentru un destinatar cu o cheie de criptare RSA, alege Certificat RSA.", "x": 58.1, "y": 40.9}, {"text": "Selectează certificatul public .cer sau .der al destinatarului. Pentru propriul card, conectează cititorul și alege Citește cardul meu.", "x": 12.9, "y": 53.2}]} />

<GuideScreenshot src="/img/guide/android-phone/ro/protect-complete-light.png" alt="Fișier criptat salvat" steps={[{"text": "Verifică numele fișierului salvat. Rezultatul este deja în Documente.", "x": 7.1, "y": 32.0}, {"text": "Alege Salvează ca… numai dacă dorești și o copie în alt loc.", "x": 38.2, "y": 82.9}, {"text": "Alege Închide pentru a reveni în aplicație. Fișierul salvat rămâne în Documente.", "x": 42.7, "y": 88.1}]} />

Alege **Criptează** sau **Decriptează**. Rezultatul este salvat automat în spațiul privat al aplicației și apare în **Documente → Documente salvate**. Alege **Închide** la final sau **Salvează ca…** pentru a-l exporta prin selectorul de fișiere Android. Originalul este păstrat.

Documente salvate include fișiere semnate, criptate și decriptate. Identifică rezultatul după numele fișierului și eticheta operațiunii. Criptarea nu creează o semnătură digitală; fișierele criptate trebuie decriptate înainte de deschiderea sau verificarea conținutului.
