---
title: "Primii pași — Tabletă Android"
sidebar_label: "Primii pași"
description: "Instalează aplicația și configurează NFC sau un cititor USB."
pagination_prev: "platforms/android-tablet"
pagination_next: "platforms/android-tablet/signing"
---

import GuideScreenshot from '@site/src/components/GuideScreenshot';

# Primii pași — Tabletă Android

[Ghidurile platformei](../android-tablet.md)

Instalează aplicația și configurează NFC sau un cititor USB.

## Conectează cititorul și cardul

Ai nevoie de o carte de identitate electronică moldovenească activă, cu certificat de semnare valabil și PIN-ul de semnare.

### Semnează prin NFC

Începând cu eSemnBun 0.2.12, poți semna prin NFC de pe un iPhone sau dispozitiv Android compatibil, cu un card fără contact compatibil. Poți folosi și un cititor USB compatibil. Alege **Cu telefonul · NFC** în **Semnează** și adaugă documentul. Apasă **Continuă**, verifică cererea și confirmă PIN-ul de semnare. Ține cardul lângă antena NFC a dispozitivului până când aplicația confirmă finalizarea. Pe Android trebuie să activezi NFC.

<GuideScreenshot src="/img/guide/android-tablet/ro/nfc-sign.png" alt="Ecranul Semnează cu opțiunea NFC selectată" steps={[{"text": "Ecranul Semnează cu opțiunea NFC selectată", "x": 45, "y": 75}]} />

### Semnează cu un cititor USB

Pentru USB, conectează cititorul prin [adaptorul](/devices) potrivit, alege **Cu un cititor de carduri** în **Semnează** și introdu cardul. Dacă sunt mai multe carduri conectate, selectează titularul dorit înainte de a continua.

<GuideScreenshot src="/img/guide/android-tablet/ro/reader-sign.png" alt="Ecranul Semnează cu cititorul de carduri USB selectat" steps={[{"text": "Ecranul Semnează cu cititorul de carduri USB selectat", "x": 48, "y": 78}]} />

## Consultă sau recitește cardul

Deschide **Setări → Carduri și cititoare** pentru a consulta un card conectat. În ecranul Semnează, butonul de informații din dreapta sus deschide detaliile cardului. Gestionează PIN-urile în **Setări → PIN-uri salvate**. Cardul și PIN-ul memorate sunt comune pentru NFC și USB.
