---
title: "Decriptează un fișier primit — Mac"
sidebar_label: "Decriptează un fișier primit"
description: "Decriptează un fișier primit"
pagination_prev: "platforms/macos/encrypt-certificate"
pagination_next: "platforms/macos/share-certificate"
---

import GuideScreenshot from '@site/src/components/GuideScreenshot';

# Decriptează un fișier primit — Mac

[Ghidurile platformei](../macos.md) · [Instalare și conectarea cititorului](./setup.md)

Decriptează un fișier primit

## Decriptează un fișier primit

Deschide Documente → Protejează fișiere. Alege un fișier accesibil; derulează formularul la nevoie. Ghidurile descriu noua funcție de protecție, care poate lipsi încă din versiunea instalată din magazin.

Întreabă expeditorul ce metodă a folosit. Pentru fișiere cu parolă, obține parola separat. Pentru fișiere cu certificat, conectează cardul corespunzător și cititorul compatibil; ai nevoie de cheia de criptare și PIN. Alt card sau un card doar pentru semnare nu poate decripta fișierul.

<GuideScreenshot src="/img/guide/macos/ro/protect-decrypt-light.png" alt="Decriptează un fișier primit" steps={[{"x": 56, "y": 17, "text": "Alege Decriptează și selectează fișierul criptat primit."}, {"x": 35, "y": 59, "text": "Alege Parolă și introdu parola primită de la expeditor."}, {"x": 50, "y": 81, "text": "Alege Decriptează și salvează rezultatul cu un nume nou."}]} />

Pentru decriptare cu cardul: alege Certificat/card, apoi Citește cardul meu. Selectează identitatea de criptare corespunzătoare, verifică detaliile, introdu PIN-ul și alege Decriptează. Salvează cu un nume nou. Dacă nu apare o identitate compatibilă, cere o copie criptată cu parolă. Oprește-te după o eroare PIN; nu reîncerca automat.

Deschide și verifică rezultatul salvat înainte de utilizare. Criptarea compatibilă MoldSign nu autentifică conținutul: decriptarea reușită nu dovedește singură integritatea sau parola corectă.
