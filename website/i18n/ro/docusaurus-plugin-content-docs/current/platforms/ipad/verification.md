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

<GuideScreenshot src="/img/guide/ipad/ro/verify-current.png" alt="Ecranul Verifică" steps={[{"text": "Ecranul Verifică"}]} />
<GuideScreenshot src="/img/guide/ipad/ro/certificate.png" alt="Derulează semnătura extinsă la detaliile certificatului, apoi analizează identitatea, valabilitatea și amprenta separat de integritatea documentului." steps={[{"text": "Derulează semnătura extinsă la detaliile certificatului, apoi analizează identitatea, valabilitatea și amprenta separat de integritatea documentului.", "x": 13, "y": 59}]} />

## Furnizează originalul pentru XML detașat

Semnătura XML detașată nu poate confirma amprenta documentului până când originalul nemodificat este disponibil. În rezultatul incomplet, folosește Alege originalele și selectează fișierele corespunzătoare. Așteaptă actualizarea rezultatului. Alegerea altui fișier schimbă dovezile; lipsa originalului nu dovedește singură modificarea.

<GuideScreenshot src="/img/guide/ipad/ro/incomplete.png" alt="Citește ce original lipsește." caption="Captură iPad nativă în portret; spațiul liber ori împrejurimile ferestrei au fost decupate pentru lizibilitate." steps={[{"text": "Citește ce original lipsește.", "x": 20.0, "y": 66.0}, {"text": "Alege originalele nemodificate și așteaptă actualizarea verificării.", "x": 10.0, "y": 70.0}]} />
