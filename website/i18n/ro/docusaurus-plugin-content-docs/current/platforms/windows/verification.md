---
title: "Verifică o semnătură — Windows"
sidebar_label: "Verifică o semnătură"
description: "Verifică un PDF sau XML și inspectează semnatarul și certificatul."
pagination_prev: "platforms/windows/signing"
pagination_next: "platforms/windows/documents"
---

import GuideScreenshot from '@site/src/components/GuideScreenshot';

# Verifică o semnătură — Windows

[Ghidurile platformei](../windows.md) · [Instalare și conectarea cititorului](./setup.md)

Verifică un PDF sau XML și inspectează semnatarul și certificatul.

Ilustrațiile folosesc date fictive. Urmează instrucțiunile în aplicația instalată.

## Verifică și consultă activitatea

Deschide **Verify (Verifică)** și alege sau plasează un PDF/XML semnat. O semnătură XML detașată necesită și documentul original. Consultă semnatarul, integritatea, lanțul de certificate și verificările disponibile ale mărcii temporale. Un nume de fișier sau o stare verde a cardului nu demonstrează validitatea semnăturii documentului.

**Documente → Istoric** înregistrează operațiunile recente și oferă acțiuni pentru fișierele disponibile. Ștergerea istoricului nu elimină documentele semnate propriu-zise.

### Alege documentul de verificat

<GuideScreenshot src="/img/guide/windows/ro/verify.png" alt="Alege documentul de verificat" steps={[{"x": 6, "y": 17, "text": "Deschide Verifică. Verificarea nu necesită card sau PIN."}, {"x": 60, "y": 28, "text": "Alege sau trage PDF-ul ori XML-ul semnat. Pentru XML detașat, furnizează originalele nemodificate la solicitare."}]} />

### Citește rezultatul verificării

<GuideScreenshot src="/img/guide/windows/ro/summary.png" alt="Citește rezultatul verificării" steps={[{"x": 37, "y": 40, "text": "Verifică rezultatul general, apoi autorul și momentul fiecărei semnături."}, {"x": 43, "y": 85, "text": "Citește separat integritatea, semnătura și încrederea. Derulează pentru limitele offline și detaliile certificatului."}]} />

### Examinează detaliile verificării

<GuideScreenshot src="/img/guide/windows/ro/results.png" alt="Examinează detaliile verificării" steps={[{"x": 60, "y": 14, "text": "Citește limitele verificării offline: încrederea în marca temporală și revocarea curentă pot rămâne neverificate."}, {"x": 60, "y": 23, "text": "Extinde detaliile certificatului și cele tehnice pentru semnatar, valabilitate și marcă temporală."}]} />
