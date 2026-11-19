---
title: "Verifică o semnătură — iPad"
sidebar_label: "Verifică o semnătură"
description: "Verifică un PDF sau XML și inspectează semnatarul și certificatul."
pagination_prev: "platforms/ipad/signing"
pagination_next: "platforms/ipad/results"
---

import GuideScreenshot from '@site/src/components/GuideScreenshot';

# Verifică o semnătură — iPad

[Ghidurile platformei](../ipad.md) · [Instalare și conectarea cititorului](./setup.md)

Verifică un PDF sau XML și inspectează semnatarul și certificatul.

## Verifică un PDF semnat și certificatul său

Verificarea necesită fișierul, nu cititorul sau PIN-ul. În Verifică, alege PDF-ul ori XML-ul semnat. Extinde fiecare semnătură, apoi certificatul și detaliile tehnice. Verifică toate semnăturile unui document contrasemnat. Rezultatele offline separă integritatea, semnătura criptografică, încrederea în lanțul inclus și marca temporală; nu reprezintă verificarea revocării curente.

<GuideScreenshot src="/img/guide/ipad/ro/verify-current.png" alt="Ecranul Verifică" steps={[{"text": "Ecranul Verifică", "x": 50, "y": 95}]} />

<GuideScreenshot src="/img/guide/ipad/ro/verify.png" alt="Consultă întâi rezultatul pentru document. Deschide fiecare semnatar pentru a-i examina semnătura." steps={[{"text": "Consultă întâi rezultatul pentru document. Deschide fiecare semnatar pentru a-i examina semnătura.", "x": 19, "y": 38}, {"text": "Folosește Șterge rezultatele din bara de navigare pentru a goli sesiunea de verificare.", "x": 96, "y": 6.8}]} />
<GuideScreenshot src="/img/guide/ipad/ro/certificate.png" alt="Deschide Detaliile certificatului pentru a consulta certificatul public al semnatarului, emitentul și amprenta." steps={[{"text": "Deschide Detaliile certificatului pentru a consulta certificatul public al semnatarului, emitentul și amprenta.", "x": 23, "y": 53}]} />

<GuideScreenshot src="/img/guide/ipad/ro/technical.png" alt="Deschide Detalii tehnice sub o semnătură pentru a citi raportul de verificare. Apasă din nou pe rând pentru a-l restrânge." steps={[{"text": "Deschide Detalii tehnice sub o semnătură pentru a citi raportul de verificare. Apasă din nou pe rând pentru a-l restrânge.", "x": 19, "y": 58}]} />

## Furnizează originalul pentru XML detașat

Semnătura XML detașată nu poate confirma amprenta documentului până când originalul nemodificat este disponibil. În rezultatul incomplet, folosește Alege originalele și selectează fișierele corespunzătoare. Așteaptă actualizarea rezultatului. Alegerea altui fișier schimbă dovezile; lipsa originalului nu dovedește singură modificarea.

<GuideScreenshot src="/img/guide/ipad/ro/incomplete.png" alt="Citește ce original lipsește." caption="Captură iPad nativă în portret; spațiul liber ori împrejurimile ferestrei au fost decupate pentru lizibilitate." steps={[{"text": "Citește ce original lipsește.", "x": 25, "y": 24}, {"text": "Alege originalele nemodificate și așteaptă actualizarea verificării.", "x": 26, "y": 40}]} />
