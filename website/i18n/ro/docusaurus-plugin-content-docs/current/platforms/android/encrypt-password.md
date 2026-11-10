---
title: "Criptează un fișier cu parolă — Telefon Android"
sidebar_label: "Criptează un fișier cu parolă"
description: "Criptează un fișier cu parolă"
pagination_prev: "platforms/android/help"
pagination_next: "platforms/android/decrypt-file"
---

import GuideScreenshot from '@site/src/components/GuideScreenshot';

# Criptează un fișier cu parolă — Telefon Android

[Ghidurile platformei](../android.md) · [Instalare și conectarea cititorului](./setup.md)

Criptează un fișier cu parolă

## Criptează un fișier cu parolă

Deschide meniul **Mai multe** din bara de navigare și alege **Protejează fișiere**. Alege **Criptează** sau **Decriptează**, apoi un fișier accesibil.

Nu ai nevoie de card. Creează o parolă pentru fișier și transmite-o destinatarului printr-un canal de încredere separat. Nu este PIN-ul cardului. Criptarea creează un rezultat separat; păstrează originalul până verifici rezultatul.

Protecția fișierelor folosește o parolă. Protecția prin certificat/card nu este disponibilă pentru cartea de identitate moldovenească: certificatul de semnare nu poate decripta fișiere. Dacă ai primit un fișier criptat cu certificat, cere o copie criptată cu parolă.

<GuideScreenshot src="/img/guide/android-phone/ro/protect-menu-light.png" alt="Deschide protecția fișierelor" steps={[{"x": 70, "y": 15, "text": "Deschide meniul de navigare și alege Protejează fișiere."}]} />

<GuideScreenshot src="/img/guide/android-phone/ro/protect-password-light.png" alt="Criptează un fișier cu parolă" start={2} steps={[{"x": 27, "y": 20, "text": "Alege Criptează."}, {"x": 30, "y": 31, "text": "Alege fișierul sursă."}, {"x": 25, "y": 55, "text": "Introdu o parolă nouă în Parolă, apoi repet-o în Confirmă parola."}, {"x": 50, "y": 88, "text": "Alege Criptează. Copia criptată este salvată în Documente."}]} />

<GuideScreenshot src="/img/guide/android-phone/ro/protect-complete-light.png" alt="Fișier criptat salvat" start={6} steps={[{"x": 25, "y": 33, "text": "Verifică numele fișierului salvat. Rezultatul este deja în Documente."}, {"x": 25, "y": 83, "text": "Alege Salvează ca… numai dacă dorești și o copie în alt loc."}, {"x": 75, "y": 88, "text": "Alege Închide pentru a reveni în aplicație. Fișierul salvat rămâne în Documente."}]} />

Alege **Criptează** sau **Decriptează**. Rezultatul este salvat automat în spațiul privat al aplicației și apare în **Documente → Documente salvate**. Alege **Închide** la final sau **Salvează ca…** pentru a-l exporta prin selectorul de fișiere Android. Originalul este păstrat.

Documente salvate include fișiere semnate, criptate și decriptate. Identifică rezultatul după numele fișierului și eticheta operațiunii. Criptarea nu creează o semnătură digitală; fișierele criptate trebuie decriptate înainte de deschiderea sau verificarea conținutului.
