---
title: "Verifică o semnătură — iPhone"
sidebar_label: "Verifică o semnătură"
description: "Verifică un PDF sau XML și inspectează semnatarul și certificatul."
pagination_prev: "platforms/ios/signing"
pagination_next: "platforms/ios/results"
---

import GuideScreenshot from '@site/src/components/GuideScreenshot';

# Verifică o semnătură — iPhone

[Ghidurile platformei](../ios.md) · [Instalare și conectarea cititorului](./setup.md)

Verifică un PDF sau XML și inspectează semnatarul și certificatul.

## Verifică un PDF semnat și certificatul său

Verificarea necesită fișierul, nu cititorul sau PIN-ul. În Verifică, alege PDF-ul ori XML-ul semnat. Extinde fiecare semnătură, apoi certificatul și detaliile tehnice. Verifică toate semnăturile unui document contrasemnat. Rezultatele offline separă integritatea, semnătura criptografică, încrederea în lanțul inclus și marca temporală; nu reprezintă verificarea revocării curente.

<GuideScreenshot src="/img/guide/iphone/ro/verify-current.png" alt="Ecranul Verifică" steps={[{"text": "Ecranul Verifică"}]} />
<GuideScreenshot src="/img/guide/iphone/ro/certificate.png" alt="Derulează semnătura extinsă la detaliile certificatului, apoi analizează identitatea, valabilitatea și amprenta separat de integritatea documentului." steps={[{"text": "Derulează semnătura extinsă la detaliile certificatului, apoi analizează identitatea, valabilitatea și amprenta separat de integritatea documentului.", "x": 9, "y": 87}]} />

## Furnizează originalul pentru XML detașat

Semnătura XML detașată nu poate confirma amprenta documentului până când originalul nemodificat este disponibil. În rezultatul incomplet, folosește Alege originalele și selectează fișierele corespunzătoare. Așteaptă actualizarea rezultatului. Alegerea altui fișier schimbă dovezile; lipsa originalului nu dovedește singură modificarea.

<GuideScreenshot src="/img/guide/iphone/ro/incomplete.png" alt="Citește ce original lipsește." steps={[{"text": "Citește ce original lipsește.", "x": 8, "y": 50}, {"text": "Alege originalele nemodificate și așteaptă actualizarea verificării.", "x": 8, "y": 55}]} />
