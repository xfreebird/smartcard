---
title: "Primii pași — iPhone"
sidebar_label: "Primii pași"
description: "Instalează aplicația și configurează NFC sau un cititor USB."
pagination_prev: "platforms/ios"
pagination_next: "platforms/ios/signing"
---

import GuideScreenshot from '@site/src/components/GuideScreenshot';

# Primii pași — iPhone

[Ghidurile platformei](../ios.md)

Instalează aplicația și configurează NFC sau un cititor USB.

## Conectează cititorul și introdu cardul

Ai nevoie de o carte de identitate electronică moldovenească activă, cu certificat de semnare valabil și PIN-ul de semnare.

### Semnează prin NFC

Începând cu eSemnBun 0.2.12, poți semna prin NFC de pe un iPhone sau dispozitiv Android compatibil, cu un card fără contact compatibil. Poți folosi și un cititor USB compatibil. Alege **Cu telefonul · NFC** în **Semnează** și adaugă documentul. Apasă **Continuă**, verifică cererea și confirmă PIN-ul de semnare. Ține cardul lângă antena NFC a telefonului până când aplicația confirmă finalizarea.

<GuideScreenshot src="/img/guide/iphone/ro/nfc-sign.png" alt="Ecranul Semnează cu opțiunea NFC selectată" steps={[{"text": "Ecranul Semnează cu opțiunea NFC selectată", "x": 36, "y": 56}]} />

### Semnează cu un cititor USB

Pentru USB, conectează cititorul prin [adaptorul](/devices) potrivit, alege **Cu un cititor de carduri** în **Semnează** și introdu cardul. Dacă sunt mai multe carduri conectate, selectează titularul dorit înainte de a continua.

<GuideScreenshot src="/img/guide/iphone/ro/reader-sign.png" alt="Ecranul Semnează cu cititorul de carduri USB selectat" steps={[{"text": "Ecranul Semnează cu cititorul de carduri USB selectat", "x": 38, "y": 59}]} />

## Alege identitatea care va semna

Deschide **Setări → Carduri și cititoare** pentru a consulta un card conectat. În ecranul Semnează, butonul de informații din dreapta sus deschide detaliile cardului. Gestionează PIN-urile în **Setări → Carduri și PIN-uri salvate**. Cardul și PIN-ul memorate sunt comune pentru NFC și USB.

<GuideScreenshot src="/img/guide/iphone/ro/cards-current.png" alt="Consultă identitatea selectată înainte de semnare." steps={[{"text": "Consultă identitatea selectată înainte de semnare.", "x": 29, "y": 34}]} />

<GuideScreenshot src="/img/guide/iphone/ro/batch-current.png" alt="Verifică documentul ales înainte de a apăsa Continuă." steps={[{"text": "Verifică documentul ales înainte de a apăsa Continuă.", "x": 37, "y": 28}]} />

## Folosește o fereastră iPhone mai mică sau mai largă

În portret sunt folosite file compacte. Rotește telefonul sau extinde dispozitivul/fereastra acceptată pentru mai mult spațiu la card și fișiere. Derulează pentru opțiuni și verificarea PIN când tastatura reduce spațiul. Postura și rotația depind de iOS; o postură pliabilă nu este identică automat cu un telefon în peisaj.
