---
title: "Verifică o semnătură — Mac"
sidebar_label: "Verifică o semnătură"
description: "Verifică un PDF sau XML și inspectează semnatarul și certificatul."
pagination_prev: "platforms/macos/signing"
pagination_next: "platforms/macos/results"
---

import GuideScreenshot from '@site/src/components/GuideScreenshot';

# Verifică o semnătură — Mac

[Ghidurile platformei](../macos.md) · [Instalare și conectarea cititorului](./setup.md)

Verifică un PDF sau XML și inspectează semnatarul și certificatul.

## Verifică un PDF și fiecare semnătură

Verificarea nu cere cititor sau PIN. Ea verifică fișierul selectat, nu ștampila vizuală sau numele lui. Verificările offline nu stabilesc starea curentă de revocare a certificatului.

<GuideScreenshot src="/img/guide/macos/ro/verify.png" alt="Consultă întâi rezultatul pentru document. Deschide fiecare semnatar pentru a-i examina semnătura." steps={[{"text": "Consultă întâi rezultatul pentru document. Deschide fiecare semnatar pentru a-i examina semnătura.", "x": 37, "y": 46}]} />

## Citește integritatea, încrederea și detaliile certificatului

Semnătura criptografică validă, documentul intact, lanțul de încredere și marca temporală sunt verificări distincte. Derulează pentru toate câmpurile certificatului și detaliile tehnice. Numărul de înregistrare al emitentului nu este identificatorul personal al semnatarului.

<GuideScreenshot src="/img/guide/macos/ro/certificate.png" alt="Deschide Detaliile certificatului pentru a consulta certificatul public al semnatarului, emitentul și amprenta." steps={[{"text": "Deschide Detaliile certificatului pentru a consulta certificatul public al semnatarului, emitentul și amprenta.", "x": 40, "y": 45}]} />

<GuideScreenshot src="/img/guide/macos/ro/technical.png" alt="Deschide Detalii tehnice sub o semnătură pentru a citi raportul de verificare. Apasă din nou pe rând pentru a-l restrânge." steps={[{"text": "Deschide Detalii tehnice sub o semnătură pentru a citi raportul de verificare. Apasă din nou pe rând pentru a-l restrânge.", "x": 38, "y": 87}]} />

## Verifică XML-ul detașat cu originalul

Adaugă XML-ul în Verifică. Dacă amprenta documentului nu poate fi verificată, folosește acțiunea Alege originalele din rezultat. Selectează originalul exact și nemodificat, nu XML-ul semnat. Citește din nou rezultatul integrității. XML-ul singur poate fi insuficient pentru destinatar.

<GuideScreenshot src="/img/guide/macos/ro/verify-original.png" alt="Verifică XML-ul detașat cu originalul" steps={[{"x": 38, "y": 35, "text": "Adaugă semnătura XML detașată."}, {"x": 41, "y": 53, "text": "Citește rezultatul incomplet/original lipsă și furnizează originalul cerut."}]} />
