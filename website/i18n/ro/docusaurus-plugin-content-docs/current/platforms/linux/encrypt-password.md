---
title: "Criptează un fișier cu parolă — Linux"
sidebar_label: "Criptează un fișier cu parolă"
description: "Criptează un fișier cu parolă"
pagination_prev: "platforms/linux/help"
pagination_next: "platforms/linux/decrypt-file"
---

import GuideScreenshot from '@site/src/components/GuideScreenshot';

# Criptează un fișier cu parolă — Linux

[Ghidurile platformei](../linux.md) · [Instalare și conectarea cititorului](./setup.md)

Criptează un fișier cu parolă

## Criptează un fișier cu parolă

Deschide meniul principal din antetul ferestrei, apoi **Protejează fișiere → Criptează**, **Decriptează** sau **Elimină fișierul**. Alege un fișier accesibil; derulează formularul la nevoie.

Nu ai nevoie de card. Creează o parolă pentru fișier și transmite-o destinatarului printr-un canal de încredere separat. Nu este PIN-ul cardului. Criptarea creează un rezultat separat; păstrează originalul până verifici rezultatul.

Alege **Parolă** și selectează AES-128, AES-192 sau AES-256. Opțiunea implicită este AES-256. Pentru a cripta pentru un destinatar, alege **Certificat RSA** și selectează certificatul său public de criptare (.cer sau .der). Implicit, folosește un certificat destinat criptării. **Compatibilitate cu cheia publică a cardului** permite explicit cheia RSA publică a cardului. Exportul sau criptarea reușită nu dovedesc că acel card poate decripta; cardul corespunzător trebuie să permită operația necesară cu cheia privată.

<GuideScreenshot src="/img/guide/linux/ro/protect-password-light.png" alt="Criptează un fișier cu parolă" steps={[{"text": "Alege fișierul de criptat.", "x": 50, "y": 29}, {"text": "Selectează AES-128, AES-192 sau AES-256. Opțiunea implicită este AES-256.", "x": 45, "y": 56}, {"text": "Introdu și confirmă o parolă nouă pentru fișier.", "x": 31, "y": 68}, {"text": "Alege Criptează, apoi salvează copia criptată.", "x": 50, "y": 91}]} />

<GuideScreenshot src="/img/guide/linux/ro/protect-certificate-light.png" alt="Criptează pentru un destinatar RSA" steps={[{"text": "Alege Certificat RSA.", "x": 40.1, "y": 44.3}, {"text": "Alege certificatul public de criptare al destinatarului.", "x": 50.0, "y": 58.6}, {"text": "Pentru a cripta pentru propriul card, conectează cititorul și citește certificatul său de criptare.", "x": 50.0, "y": 64.0}, {"text": "Folosește Compatibilitate cu cheia publică a cardului doar când fluxul cere cheia RSA publică a cardului.", "x": 40.6, "y": 53.4}]} />

Alege **Criptează** sau **Decriptează**, apoi **Salvează o copie** și alege un loc nou pentru rezultat. După salvare, fișierul apare în **Documente → Documente salvate**. Folosește butonul de închidere din antetul ferestrei la final. Originalul este păstrat.

Documente salvate include fișiere semnate, criptate și decriptate. Identifică rezultatul după numele fișierului și eticheta operațiunii. Criptarea nu creează o semnătură digitală; fișierele criptate trebuie decriptate înainte de deschiderea sau verificarea conținutului.
