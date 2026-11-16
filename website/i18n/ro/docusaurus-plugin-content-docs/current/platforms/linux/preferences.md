---
title: "Modifică setările — Linux"
sidebar_label: "Modifică setările"
description: "Gestionează limba, aspectul, PIN-urile salvate, pornirea și actualizările."
pagination_prev: "platforms/linux/browser"
pagination_next: "platforms/linux/approval"
---

import GuideScreenshot from '@site/src/components/GuideScreenshot';

# Modifică setările — Linux

[Ghidurile platformei](../linux.md) · [Instalare și conectarea cititorului](./setup.md)

Gestionează limba, aspectul, PIN-urile salvate, pornirea și actualizările.

## Alege limba și aspectul

Deschide Preferințe din meniul aplicației. Modul demonstrativ este sus. Consultă cardurile în Carduri și cititoare și gestionează copiile PIN în PIN-uri salvate.

Deschide meniul aplicației → Preferințe. Alege aspectul Sistem, Deschis sau Întunecat și limba Sistem, Română, English sau Русский. Modificările se aplică interfeței. Capturile folosesc traducerile native.

<GuideScreenshot src="/img/guide/linux/ro/settings-current.png" alt="Alege limba și aspectul" steps={[{"text": "Alege aspectul interfeței.", "x": 68, "y": 17}, {"text": "Alege limba interfeței.", "x": 68, "y": 54}]} />

## Gestionează PIN-urile și accesul site-urilor

PIN-urile sunt păstrate prin Secret Service/seiful sistemului. Dacă semnarea obișnuită oferă memorarea, salvează intenționat și deblochează seiful când se solicită. Dacă acesta este indisponibil/blocat, introdu PIN-ul pentru operația curentă. Ștergerea copiilor salvate nu schimbă și nu deblochează PIN-ul fizic. Activează conexiunea browser numai pentru fluxul dorit.

<GuideScreenshot src="/img/guide/linux/ro/saved-pins.png" alt="Deschide PIN-uri salvate în Preferințe pentru a gestiona copiile stocate pe acest dispozitiv." steps={[{"text": "Deschide PIN-uri salvate în Preferințe pentru a gestiona copiile stocate pe acest dispozitiv.", "x": 51, "y": 38}]} />

## Păstrează aplicația disponibilă în fundal

Derulează în Preferințe la opțiunile de fundal și pornire. Rularea în fundal păstrează conexiunea browser după închiderea ferestrei. Pornirea la autentificare activează detectarea în fundal. Afișarea la introducerea cardului funcționează cât aplicația rulează; nu este un serviciu separat permanent.

<GuideScreenshot src="/img/guide/linux/ro/background.png" alt="Păstrează aplicația disponibilă în fundal" steps={[{"text": "Alege rularea în fundal și pornirea dacă sunt necesare.", "x": 68, "y": 75}, {"text": "Alege dacă introducerea cardului deschide aplicația pornită.", "x": 68, "y": 89}]} />

## Găsește versiunea și actualizează sigur

Deschide meniul aplicației → Despre eSemnBun pentru versiune și site. Folosește verificarea actualizărilor când este disponibilă ori canalul original al pachetului. Instalează un pachet compatibil; verificarea nu înlocuiește aplicația automat. Pentru suport oferă versiunile și cititorul, niciodată PIN-ul.

<GuideScreenshot src="/img/guide/linux/ro/about.png" alt="Găsește versiunea și actualizează sigur" steps={[{"text": "Deschide Despre eSemnBun.", "x": 58, "y": 7}, {"text": "Citește versiunea și site-ul înainte de suport.", "x": 50, "y": 27}]} />

## Deschide ajutorul și comenzile aplicației

Meniul aplicației oferă Preferințe, Despre, Verifică actualizările și Ieșire. Pentru ajutor online deschide [depanarea](/docs/troubleshooting). Închiderea ferestrei poate lăsa aplicația în fundal; alege Ieșire pentru oprire. Pentru automatizare continuă cu ghidul CLI Linux.

<GuideScreenshot src="/img/guide/linux/ro/menu.png" alt="Deschide ajutorul și comenzile aplicației" steps={[{"text": "Deschide meniul aplicației.", "x": 89, "y": 3}, {"text": "Alege Preferințe, Ajutor, actualizare sau Ieșire.", "x": 89, "y": 14}]} />
