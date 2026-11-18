---
title: "Criptează un fișier cu parolă — Windows"
sidebar_label: "Criptează un fișier cu parolă"
description: "Criptează un fișier cu parolă"
pagination_prev: "platforms/windows/help"
pagination_next: "platforms/windows/decrypt-file"
---

import GuideScreenshot from '@site/src/components/GuideScreenshot';

# Criptează un fișier cu parolă — Windows

[Ghidurile platformei](../windows.md) · [Instalare și conectarea cititorului](./setup.md)

Criptează un fișier cu parolă

## Criptează un fișier cu parolă

Deschide **Protejează fișiere** în partea de jos a barei de navigare și alege **Criptează**, **Decriptează** sau **Elimină fișierul**. Alege un fișier accesibil; derulează formularul la nevoie.

Nu ai nevoie de card. Creează o parolă pentru fișier și transmite-o destinatarului printr-un canal de încredere separat. Nu este PIN-ul cardului. Criptarea creează un rezultat separat; păstrează originalul până verifici rezultatul.

Alege **Parolă** și selectează AES-128, AES-192 sau AES-256. Opțiunea implicită este AES-256. Pentru a cripta pentru un destinatar, alege **Certificat RSA** și selectează certificatul său public de criptare (.cer sau .der). Certificatul de semnare al cărții de identitate moldovenești nu poate decripta aceste fișiere.

<GuideScreenshot src="/img/guide/windows/ro/protect-password-light.png" alt="Criptează un fișier cu parolă" steps={[{"text": "Alege fișierul de criptat.", "x": 36, "y": 29}, {"text": "Selectează AES-128, AES-192 sau AES-256. Opțiunea implicită este AES-256.", "x": 59, "y": 50}, {"text": "Introdu și confirmă o parolă nouă pentru fișier.", "x": 41, "y": 62}, {"text": "Alege Criptează, apoi salvează copia criptată.", "x": 41, "y": 88}]} />

<GuideScreenshot src="/img/guide/windows/ro/protect-certificate-light.png" alt="Criptează pentru un destinatar RSA" steps={[{"text": "Alege Certificat RSA.", "x": 48, "y": 45}, {"text": "Alege certificatul public de criptare al destinatarului.", "x": 40, "y": 55}, {"text": "Pentru a cripta pentru propriul card, conectează cititorul și citește certificatul său de criptare.", "x": 36, "y": 60}]} />

Alege **Criptează** sau **Decriptează**, apoi **Salvează o copie** și alege un loc nou pentru rezultat. După salvare, fișierul apare în **Documente → Documente salvate**. Alege **Închide** pentru a închide operațiunea finalizată. Originalul este păstrat.

Documente salvate include fișiere semnate, criptate și decriptate. Identifică rezultatul după numele fișierului și eticheta operațiunii. Criptarea nu creează o semnătură digitală; fișierele criptate trebuie decriptate înainte de deschiderea sau verificarea conținutului.
