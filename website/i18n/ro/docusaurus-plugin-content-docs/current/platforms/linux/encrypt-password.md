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

Protecția fișierelor folosește o parolă. Protecția prin certificat/card nu este disponibilă pentru cartea de identitate moldovenească: certificatul de semnare nu poate decripta fișiere. Dacă ai primit un fișier criptat cu certificat, cere o copie criptată cu parolă.

<GuideScreenshot src="/img/guide/linux/ro/protect-password-light.png" alt="Criptează un fișier cu parolă" steps={[{"x": 27, "y": 17, "text": "Alege Criptează."}, {"x": 30, "y": 31, "text": "Alege fișierul sursă."}, {"x": 30, "y": 58, "text": "Introdu o parolă nouă în Parolă, apoi repet-o în Confirmă parola."}, {"x": 50, "y": 91, "text": "Alege Criptează, apoi salvează fișierul criptat nou."}]} />

Alege **Criptează** sau **Decriptează**, apoi **Salvează o copie** și alege un loc nou pentru rezultat. După salvare, fișierul apare în **Documente → Documente salvate**. Folosește butonul de închidere din antetul ferestrei la final. Originalul este păstrat.

Documente salvate include fișiere semnate, criptate și decriptate. Identifică rezultatul după numele fișierului și eticheta operațiunii. Criptarea nu creează o semnătură digitală; fișierele criptate trebuie decriptate înainte de deschiderea sau verificarea conținutului.
