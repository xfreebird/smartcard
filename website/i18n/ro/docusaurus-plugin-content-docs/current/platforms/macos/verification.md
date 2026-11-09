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

<GuideScreenshot src="/img/guide/macos/ro/verify.png" alt="Verifică un PDF și fiecare semnătură" steps={[{"x": 7, "y": 15, "text": "Deschide Verifică."}, {"x": 58, "y": 10, "text": "Alege fișierele semnate sau trage-le în zona punctată."}, {"x": 32, "y": 35, "text": "Extinde fiecare rând Autor, inclusiv semnăturile suplimentare ale aceluiași document."}, {"x": 35, "y": 17, "text": "Folosește Șterge rezultatele înaintea unei verificări separate."}]} />

## Citește integritatea, încrederea și detaliile certificatului

Semnătura criptografică validă, documentul intact, lanțul de încredere și marca temporală sunt verificări distincte. Derulează pentru toate câmpurile certificatului și detaliile tehnice. Numărul de înregistrare al emitentului nu este identificatorul personal al semnatarului.

<GuideScreenshot src="/img/guide/macos/ro/certificate.png" alt="Citește integritatea, încrederea și detaliile certificatului" steps={[{"x": 32, "y": 35, "text": "Extinde semnătura pentru semnatar, ora semnării și marca temporală."}, {"x": 34, "y": 57, "text": "Citește fiecare verificare de integritate, semnătură și lanț de încredere."}, {"x": 34, "y": 68, "text": "Extinde Detaliile certificatului și verifică subiectul, emitentul și cheia."}]} />

## Verifică XML-ul detașat cu originalul

Adaugă XML-ul în Verifică. Dacă amprenta documentului nu poate fi verificată, folosește acțiunea Alege originalele din rezultat. Selectează originalul exact și nemodificat, nu XML-ul semnat. Citește din nou rezultatul integrității. XML-ul singur poate fi insuficient pentru destinatar.

<GuideScreenshot src="/img/guide/macos/ro/verify-original.png" alt="Verifică XML-ul detașat cu originalul" steps={[{"x": 58, "y": 10, "text": "Adaugă semnătura XML detașată."}, {"x": 42, "y": 39, "text": "Citește rezultatul incomplet/original lipsă și furnizează originalul cerut."}]} />
