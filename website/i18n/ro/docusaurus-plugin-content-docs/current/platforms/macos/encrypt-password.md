---
title: "Criptează un fișier cu parolă — Mac"
sidebar_label: "Criptează un fișier cu parolă"
description: "Criptează un fișier cu parolă"
pagination_prev: "platforms/macos/help"
pagination_next: "platforms/macos/decrypt-file"
---

import GuideScreenshot from '@site/src/components/GuideScreenshot';

# Criptează un fișier cu parolă — Mac

[Ghidurile platformei](../macos.md) · [Instalare și conectarea cititorului](./setup.md)

Criptează un fișier cu parolă

## Criptează un fișier cu parolă

În **Documente**, alege **Protejează fișiere** din bara de instrumente. În formular, alege **Criptează** sau **Decriptează**, apoi un fișier accesibil.

Nu ai nevoie de card. Creează o parolă pentru fișier și transmite-o destinatarului printr-un canal de încredere separat. Nu este PIN-ul cardului. Criptarea creează un rezultat separat; păstrează originalul până verifici rezultatul.

În versiunea 0.2.13, alege **Parolă** și selectează AES-128, AES-192 sau AES-256. Opțiunea implicită este AES-256. Pentru a cripta pentru un destinatar, alege **Certificat RSA** și selectează certificatul său public de criptare (.cer sau .der). Certificatul de semnare al cărții de identitate moldovenești nu poate decripta aceste fișiere.

<GuideScreenshot src="/img/guide/macos/ro/documents-protection-light.png" alt="În Documente, deschide Protejează fișiere din bara de instrumente apăsând scutul." steps={[{"text": "În Documente, deschide Protejează fișiere din bara de instrumente apăsând scutul.", "x": 89, "y": 11}]} />

<GuideScreenshot src="/img/guide/macos/ro/protect-password-light.png" alt="Selectează fișierul sursă și Parolă. Alege dimensiunea cheii AES, introdu și confirmă parola, apoi apasă Criptează." steps={[{"text": "Selectează fișierul sursă și Parolă. Alege dimensiunea cheii AES, introdu și confirmă parola, apoi apasă Criptează.", "x": 83, "y": 57}]} />

<GuideScreenshot src="/img/guide/macos/ro/protect-certificate-light.png" alt="Alege Certificat RSA, apoi selectează certificatul public de criptare al destinatarului. Criptarea nu cere PIN-ul destinatarului." steps={[{"text": "Alege Certificat RSA, apoi selectează certificatul public de criptare al destinatarului. Criptarea nu cere PIN-ul destinatarului.", "x": 32, "y": 64}]} />

<GuideScreenshot src="/img/guide/macos/ro/protect-complete-light.png" alt="Rezultatul este salvat în Documente. Alege Salvează o copie pentru export sau Gata pentru a reveni." steps={[{"text": "Rezultatul este salvat în Documente. Alege Salvează o copie pentru export sau Gata pentru a reveni.", "x": 52, "y": 66}]} />

Alege **Criptează** sau **Decriptează**. Rezultatul nou este salvat automat în **Documente → Documente salvate**. Alege **Gata** pentru a reveni sau **Salvează o copie** pentru a-l exporta în Fișiere ori în alt loc. Originalul este păstrat.

Documente salvate include fișiere semnate, criptate și decriptate. Identifică rezultatul după numele fișierului și eticheta operațiunii. Criptarea nu creează o semnătură digitală; fișierele criptate trebuie decriptate înainte de deschiderea sau verificarea conținutului.
