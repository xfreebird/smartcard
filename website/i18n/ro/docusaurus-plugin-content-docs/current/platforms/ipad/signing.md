---
title: "Semnează documente — iPad"
sidebar_label: "Semnează documente"
description: "Adaugă fișiere, alege formatul și ștampila, aprobă și salvează rezultatul."
pagination_prev: "platforms/ipad/setup"
pagination_next: "platforms/ipad/verification"
---

import GuideScreenshot from '@site/src/components/GuideScreenshot';

# Semnează documente — iPad

[Ghidurile platformei](../ipad.md) · [Instalare și conectarea cititorului](./setup.md)

Adaugă fișiere, alege formatul și ștampila, aprobă și salvează rezultatul.

## Adaugă documente și alege formatul semnăturii

### Alege cum semnezi

Pentru USB, conectează cititorul prin [adaptorul](/devices) potrivit, alege **Cu un cititor de carduri** în **Semnează** și introdu cardul. Dacă sunt mai multe carduri conectate, selectează titularul dorit înainte de a continua. Cu un cititor USB, lasă cititorul conectat și cardul introdus până se finalizează semnarea și aplicarea mărcii temporale.

Deschide Semnează și alege fișiere din Fișiere sau dintr-un furnizor cloud. Descarcă întâi documentele disponibile doar în cloud dacă accesul eșuează. Poți trimite fișiere și din meniul de partajare al altei aplicații către extensia eSemnBun. Extinde lista, verifică numele, elimină fișierele nedorite din opțiunile lor și alege formatul cerut. PDF-urile folosesc PAdES-T; celelalte fișiere folosesc XAdES. XML-ul detașat trebuie păstrat împreună cu originalul nemodificat. XAdES-BES nu are marcă temporală, T o adaugă, iar C include referințe la certificate și stare. XML-ul încorporat include conținutul original. Formatele cu marcă temporală necesită serviciile publice de încredere.

<GuideScreenshot src="/img/guide/ipad/ro/sign.png" alt="Confirmă titularul selectat înainte de semnare." steps={[{"text": "Confirmă titularul selectat înainte de semnare.", "x": 20, "y": 16}, {"text": "Alege fișiere sau adaugă alte documente în listă.", "x": 85, "y": 30}, {"text": "Deschide opțiunile unui fișier pentru format, ștampilă sau eliminare.", "x": 93, "y": 16}, {"text": "Verifică întreaga listă, apoi apasă butonul flotant Semnează din partea de jos.", "x": 85, "y": 95}]} />

## Plasează o ștampilă vizibilă într-un PDF

Deschide opțiunile unui PDF și alege Adaugă/Editează ștampila. Ștampila vizibilă este opțională; dovada semnării rămâne semnătura criptografică. Evită acoperirea textului existent.

Textul ștampilei urmează limba aleasă în aplicație (română, engleză sau rusă).

<GuideScreenshot src="/img/guide/ipad/ro/stamp.png" alt="Trage ștampila pentru mutare și colțurile pentru redimensionare." steps={[{"text": "Trage ștampila pentru mutare și colțurile pentru redimensionare.", "x": 42, "y": 55}, {"text": "Alege pagina și modul Oprit, O pagină sau Toate paginile.", "x": 25, "y": 70}, {"text": "Opțional, aplică poziția tuturor PDF-urilor din listă, apoi apasă Aplică.", "x": 79, "y": 26}]} />

## Verifică cererea și autorizează semnarea

Pentru o cerere de pe un site, verifică originea și întreaga listă de documente înainte de acceptare. Anulează cererile neașteptate. Pentru un lot local, verifică lista și fereastra PIN. Fiecare lot nou necesită aprobare; sesiunea acoperă doar documentele afișate și cardul ales.

<GuideScreenshot src="/img/guide/ipad/ro/consent.png" alt="Verifică site-ul solicitant și operația dorită." steps={[{"text": "Verifică site-ul solicitant și operația dorită.", "x": 20, "y": 50}, {"text": "Verifică toate documentele; acceptă numai o cerere inițiată de tine.", "x": 79, "y": 74}]} />
<GuideScreenshot src="/img/guide/ipad/ro/pin.png" alt="Verifică titularul și numele fișierelor selectate." steps={[{"text": "Verifică titularul și numele fișierelor selectate.", "x": 50, "y": 21}, {"text": "Introdu PIN-ul QSCD corect în câmpul protejat.", "x": 30, "y": 28}, {"text": "Activează memorarea PIN-ului doar pe un dispozitiv personal de încredere; accesul ulterior cere autentificarea oferită de dispozitiv.", "x": 73, "y": 32.5}, {"text": "Apasă Semnează pentru autorizare sau Anulează pentru oprire.", "x": 94, "y": 70}]} />

## Așteaptă finalizarea și salvează rezultatul semnat

Păstrează cititorul și cardul conectate pe durata semnării și a obținerii mărcii temporale. Finalizarea este afișată separat de lista de intrare. Folosește acțiunea rezultatului sau deschide Documente, selectează fișierul finalizat și Partajează pentru salvare în Fișiere ori trimitere către altă aplicație. Trimite rezultatul semnat, nu sursa nesemnată; include originalul pentru XML detașat.

<GuideScreenshot src="/img/guide/ipad/ro/progress.png" alt="Așteaptă finalizarea etapei curente fără a scoate cardul." steps={[{"text": "Așteaptă finalizarea etapei curente fără a scoate cardul.", "x": 9, "y": 26.5}]} />
<GuideScreenshot src="/img/guide/ipad/ro/success.png" alt="Verifică finalizarea și numele rezultatului înainte de deschidere sau partajare." steps={[{"text": "Verifică finalizarea și numele rezultatului înainte de deschidere sau partajare.", "x": 9, "y": 29}]} />

## Rezolvă o eroare la un document

Citește eroarea documentului afectat. Păstrează rezultatele deja finalizate și corectează fișierul ori conexiunea înainte de a porni intenționat un lot nou. PIN-ul nu este reîncercat automat. Dacă PIN-ul este greșit, oprește-te și confirmă PIN-ul și cardul selectat; trei încercări greșite pot bloca actul. Aplicația nu îl poate debloca. Reconectarea nu repară un PDF invalid.

<GuideScreenshot src="/img/guide/ipad/ro/file-error.png" alt="Citește eroarea documentului înainte de o nouă încercare." steps={[{"text": "Citește eroarea documentului înainte de o nouă încercare.", "x": 47, "y": 19}]} />
