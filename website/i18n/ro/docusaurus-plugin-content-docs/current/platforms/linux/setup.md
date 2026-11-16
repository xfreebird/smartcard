---
title: "Primii pași — Linux"
sidebar_label: "Primii pași"
description: "Instalează, conectează cititorul și alege cardul."
pagination_prev: "platforms/linux"
pagination_next: "platforms/linux/signing"
---

import GuideScreenshot from '@site/src/components/GuideScreenshot';

# Primii pași — Linux

[Ghidurile platformei](../linux.md)

Instalează, conectează cititorul și alege cardul.

## Conectează cititorul

Conectează cititorul direct sau prin adaptorul USB potrivit. Detectarea cititorului și citirea certificatului nu cer PIN. O eroare a serviciului PC/SC diferă de un cititor deconectat.

<GuideScreenshot src="/img/guide/linux/ro/connect.png" alt="Conectează cititorul" steps={[{"text": "Deschide Semnează.", "x": 41, "y": 3}, {"text": "Conectează cititorul USB și citește mesajul.", "x": 50, "y": 23}]} />

## Introdu cardul

Introdu actul electronic și așteaptă citirea certificatului. Verifică titularul și expirarea înainte de semnare. Nu reconecta repetat în timpul unei operații.

<GuideScreenshot src="/img/guide/linux/ro/empty.png" alt="Introdu cardul" steps={[{"text": "Introdu cardul și așteaptă titularul și expirarea.", "x": 50, "y": 26}]} />

## Alege identitatea corectă

Dacă sunt mai multe carduri, selectează identitatea dorită în carusel. Ilustrația folosește datele certificatului și un avatar neutru, nu fotografia din act. Folosește reîmprospătarea pentru recitire când este necesar.

<GuideScreenshot src="/img/guide/linux/ro/cards-current.png" alt="Deschide Preferințe din meniul aplicației, apoi Carduri și cititoare." steps={[{"text": "Deschide Preferințe din meniul aplicației, apoi Carduri și cititoare.", "x": 50, "y": 27}, {"text": "Alege cardul dorit din carusel.", "x": 50, "y": 43}, {"text": "Derulează pentru a vedea certificatul și cititorul conectat.", "x": 47, "y": 76}]} />
