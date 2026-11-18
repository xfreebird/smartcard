---
title: "Verifică o semnătură — Linux"
sidebar_label: "Verifică o semnătură"
description: "Verifică un PDF sau XML și inspectează semnatarul și certificatul."
pagination_prev: "platforms/linux/signing"
pagination_next: "platforms/linux/results"
---

import GuideScreenshot from '@site/src/components/GuideScreenshot';

# Verifică o semnătură — Linux

[Ghidurile platformei](../linux.md) · [Instalare și conectarea cititorului](./setup.md)

Verifică un PDF sau XML și inspectează semnatarul și certificatul.

## Verifică un PDF

Verificarea nu cere card sau PIN. Deschide Verifică și alege/trage PDF-ul sau XML-ul semnat. Sunt acceptate selecții multiple. Citește fiecare semnătură; numele și ștampila nu sunt dovezi. Verificarea offline nu stabilește revocarea curentă a certificatului.

<GuideScreenshot src="/img/guide/linux/ro/verify.png" alt="Verifică un PDF" steps={[{"text": "Deschide Verifică și alege fișierul semnat.", "x": 50, "y": 4}, {"text": "Citește verdictul și numărul semnăturilor.", "x": 50, "y": 28}, {"text": "Inspectează autorul, integritatea și încrederea.", "x": 27, "y": 47}]} />

## Inspectează certificatul și detaliile tehnice

Derulează rezultatul și extinde Detalii certificat și Detalii tehnice. Integritatea, semnătura criptografică, încrederea și marca temporală sunt verificări distincte. Datele organizației emitente nu sunt identificatorul personal al semnatarului.

<GuideScreenshot src="/img/guide/linux/ro/certificate.png" alt="Inspectează certificatul și detaliile tehnice" steps={[{"text": "Extinde detaliile tehnice pentru a vedea formatul și identificatorul semnăturii.", "x": 29, "y": 61}, {"text": "Consultă câmpurile semnăturii. Selectează din nou titlul pentru a restrânge detaliile.", "x": 29, "y": 76}]} />

## Verifică XML detașat cu originalul

Pentru XAdES detașat, pune originalul exact și nemodificat lângă XML, cu numele referit de semnătură, apoi alege XML-ul din nou în Verifică. Această versiune Linux nu are selector integrat pentru originale: relația este rezolvată din dosarul XML-ului. Lipsa originalului împiedică o concluzie completă asupra integrității.

<GuideScreenshot src="/img/guide/linux/ro/verify.png" alt="Verifică XML detașat cu originalul" steps={[{"text": "Păstrează XML-ul și originalul împreună, apoi verifică XML-ul din nou.", "x": 50, "y": 4}]} />
