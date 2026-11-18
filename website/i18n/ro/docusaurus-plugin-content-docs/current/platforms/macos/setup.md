---
title: "Primii pași — Mac"
sidebar_label: "Primii pași"
description: "Instalează, conectează cititorul și alege cardul."
pagination_prev: "platforms/macos"
pagination_next: "platforms/macos/signing"
---

import GuideScreenshot from '@site/src/components/GuideScreenshot';

# Primii pași — Mac

[Ghidurile platformei](../macos.md)

Instalează, conectează cititorul și alege cardul.

## Instalează aplicația și conectează cititorul

Deschide [Descărcări](/downloads/). Instalează ediția Mac App Store sau deschide DMG-ul pentru desktop și trage eSemnBun în Aplicații. Ejectează DMG-ul și pornește copia instalată. Arhiva TAR.GZ și Homebrew oferă instrumentele CLI/MCP; vezi [ghidul pentru terminal](../macos-cli.md).

Ai nevoie de macOS 15 sau mai nou, un cititor USB compatibil, un act electronic acceptat și activ și PIN-ul său de semnare. Folosește un adaptor USB-C adecvat, dacă este necesar. Semnarea prin NFC nu este disponibilă.

Atât ediția Mac App Store, cât și ediția independentă detectează cititoarele USB compatibile și cardurile introduse cât timp eSemnBun este pornit. Ediția Mac App Store permite și folosirea site-urilor compatibile într-un browser extern; Browser-ul integrat este opțional.

<GuideScreenshot src="/img/guide/macos/ro/connect.png" alt="Instalează aplicația și conectează cititorul" steps={[{"x": 5, "y": 7, "text": "Deschide Semnează în bara laterală."}, {"x": 59, "y": 17, "text": "Conectează cititorul USB. Ecranul se schimbă după detectarea lui."}]} />

## Introdu cardul

Certificatul se citește fără PIN. Așteaptă afișarea titularului și a expirării înainte de semnare. Cheia privată de semnare rămâne pe card.

<GuideScreenshot src="/img/guide/macos/ro/empty-reader.png" alt="Introdu cardul" steps={[{"x": 59, "y": 18, "text": "Introdu cardul în cititorul detectat și lasă-l conectat."}]} />

## Alege identitatea și verifică certificatul

Imaginea cardului folosește datele certificatului și un avatar neutru, nu fotografia citită din act. Pentru a reciti cardul, folosește butonul din dreapta sus sau meniul contextual al cardului. Nu porni o altă operațiune în timpul uneia active.

<GuideScreenshot src="/img/guide/macos/ro/cards-current.png" alt="Deschide Setări și alege Carduri și cititoare pentru a consulta titularul, certificatul și cititorul conectat." steps={[{"text": "Deschide Setări și alege Carduri și cititoare pentru a consulta titularul, certificatul și cititorul conectat.", "x": 25, "y": 42}, {"text": "Alege titularul dorit din carusel înainte de a semna."}]} />
