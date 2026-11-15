---
title: "Semnează documente — Windows"
sidebar_label: "Semnează documente"
description: "Adaugă fișiere, alege formatul și ștampila, aprobă și salvează rezultatul."
pagination_prev: "platforms/windows/setup"
pagination_next: "platforms/windows/verification"
---

import GuideScreenshot from '@site/src/components/GuideScreenshot';

# Semnează documente — Windows

[Ghidurile platformei](../windows.md) · [Instalare și conectarea cititorului](./setup.md)

Adaugă fișiere, alege formatul și ștampila, aprobă și salvează rezultatul.

## Semnează documente din aplicație sau Explorer

În **Sign (Semnează)**, trage documentele în zona cu contur întrerupt sau alege **Choose files… (Alege fișiere…)**. Dacă ediția instalată oferă integrare în meniul contextual Explorer, poți trimite și fișierele selectate din Explorer în eSemnBun.

1. Adaugă fișierele și verifică formatul afișat lângă fiecare.
2. Pentru PDF folosește **PAdES-T** ca să încorporezi semnătura în PDF. XAdES produce XML; XML-ul detașat trebuie păstrat împreună cu documentul original.
3. Confirmă identitatea selectată, alege **Sign (Semnează)** și verifică cererea de autorizare înainte să introduci PIN-ul cardului sau să autentifici o intrare salvată.
4. Ține cititorul conectat până la finalizare. Folosește acțiunile rezultatului pentru a deschide sau localiza fișierele produse.

Autorizarea lotului se aplică listei de documente aprobate și cardului selectat. Dacă un element eșuează, citește eroarea înainte de a reîncerca. Nu confunda rezultatele finalizate cu intrările nesemnate. Consultă [formatele de semnare și erorile](/docs/signing).

### Pregătește lotul de semnare

<GuideScreenshot src="/img/guide/windows/ro/queue.png" alt="Pregătește lotul de semnare" steps={[{"x": 90.59, "y": 68.575, "text": "Alege fișierele sau trage-le în zona punctată."}, {"x": 33.764, "y": 50.393, "text": "Verifică formatul; folosește Ștampilă dezactivată pentru o ștampilă PDF opțională."}, {"x": 88.561, "y": 95.847, "text": "Verifică cardul selectat și alege Semnează pentru lotul afișat."}]} />

### Poziționează ștampila PDF vizibilă

<GuideScreenshot src="/img/guide/windows/ro/stamp.png" alt="Poziționează ștampila PDF vizibilă" steps={[{"x": 18.542, "y": 85.746, "text": "Mută și redimensionează ștampila în previzualizarea PDF. Textul urmează limba aplicației."}, {"x": 69.28, "y": 34.231, "text": "Alege pagina selectată sau toate paginile; opțional, aplică poziția tuturor PDF-urilor din listă."}, {"x": 93.635, "y": 95.847, "text": "Alege Aplică pentru a salva poziția înainte de semnare."}]} />

### Verifică autorizarea semnării

<GuideScreenshot src="/img/guide/windows/ro/pin.png" alt="Verifică autorizarea semnării" steps={[{"x": 50, "y": 42.693, "text": "Verifică identitatea selectată și lista completă de documente."}, {"x": 50, "y": 64.165, "text": "Introdu PIN-ul de semnare al cardului fizic doar după verificarea cererii. Nu ghici și nu repeta automat."}]} />

### Găsește rezultatele finalizate

<GuideScreenshot src="/img/guide/windows/ro/success.png" alt="Găsește rezultatele finalizate" steps={[{"x": 90.59, "y": 23.12, "text": "Examinează fiecare rând finalizat și folosește acțiunea de deschidere sau afișare."}, {"x": 43.911, "y": 23.12, "text": "Păstrează XML-ul detașat cu originalul nemodificat."}]} />
