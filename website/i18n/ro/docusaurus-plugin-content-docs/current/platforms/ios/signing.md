---
title: "Semnează documente — iPhone"
sidebar_label: "Semnează documente"
description: "Adaugă fișiere, alege formatul și ștampila, aprobă și salvează rezultatul."
pagination_prev: "platforms/ios/setup"
pagination_next: "platforms/ios/verification"
---

import GuideScreenshot from '@site/src/components/GuideScreenshot';

# Semnează documente — iPhone

[Ghidurile platformei](../ios.md) · [Instalare și conectarea cititorului](./setup.md)

Adaugă fișiere, alege formatul și ștampila, aprobă și salvează rezultatul.

## Adaugă documente și alege formatul semnăturii

Deschide Semnează și alege fișiere din Fișiere sau dintr-un furnizor cloud. Descarcă întâi documentele disponibile doar în cloud dacă accesul eșuează. Poți trimite fișiere și din meniul de partajare al altei aplicații către extensia eSemnBun. Extinde lista, verifică numele, elimină fișierele nedorite din opțiunile lor și alege formatul cerut. PDF-urile folosesc PAdES-T; celelalte fișiere folosesc XAdES. XML-ul detașat trebuie păstrat împreună cu originalul nemodificat. XAdES-BES nu are marcă temporală, T o adaugă, iar C include referințe la certificate și stare. XML-ul încorporat include conținutul original. Formatele cu marcă temporală necesită serviciile publice de încredere.

<GuideScreenshot src="/img/guide/iphone/ro/sign.png" alt="Confirmă titularul selectat înainte de semnare." steps={[{"text": "Confirmă titularul selectat înainte de semnare.", "x": 31, "y": 27}, {"text": "Alege fișiere sau adaugă alte documente în listă.", "x": 29, "y": 69}, {"text": "Extinde lista și deschide opțiunile unui fișier pentru format, ștampilă sau eliminare.", "x": 78, "y": 53}, {"text": "Apasă Semnează numai după verificarea întregii liste.", "x": 78, "y": 9}]} />

## Plasează o ștampilă vizibilă într-un PDF

Deschide opțiunile unui PDF și alege Adaugă/Editează ștampila. Ștampila vizibilă este opțională; dovada semnării rămâne semnătura criptografică. Evită acoperirea textului existent.

Textul ștampilei urmează limba aleasă în aplicație (română, engleză sau rusă).

<GuideScreenshot src="/img/guide/iphone/ro/stamp.png" alt="Trage ștampila pentru mutare și colțurile pentru redimensionare." steps={[{"text": "Trage ștampila pentru mutare și colțurile pentru redimensionare.", "x": 30, "y": 61}, {"text": "Alege pagina și modul Oprit, O pagină sau Toate paginile.", "x": 25, "y": 86}, {"text": "Opțional, aplică poziția tuturor PDF-urilor din listă, apoi apasă Aplică.", "x": 87, "y": 12}]} />

## Verifică cererea și autorizează semnarea

Pentru o cerere de pe un site, verifică originea și întreaga listă de documente înainte de acceptare. Anulează cererile neașteptate. Pentru un lot local, verifică lista și fereastra PIN. Fiecare lot nou necesită aprobare; sesiunea acoperă doar documentele afișate și cardul ales.

<GuideScreenshot src="/img/guide/iphone/ro/consent.png" alt="Verifică site-ul solicitant și operația dorită." steps={[{"text": "Verifică site-ul solicitant și operația dorită.", "x": 16, "y": 52}, {"text": "Verifică toate documentele; acceptă numai o cerere inițiată de tine.", "x": 86, "y": 91}]} />
<GuideScreenshot src="/img/guide/iphone/ro/pin.png" alt="Verifică titularul și numele fișierelor selectate." steps={[{"text": "Verifică titularul și numele fișierelor selectate.", "x": 49, "y": 23}, {"text": "Introdu PIN-ul QSCD corect în câmpul protejat.", "x": 8, "y": 34}, {"text": "Activează memorarea PIN-ului doar pe un dispozitiv personal de încredere; accesul ulterior cere autentificarea oferită de dispozitiv.", "x": 86, "y": 40}, {"text": "Apasă Semnează pentru autorizare sau Anulează pentru oprire.", "x": 88, "y": 63}]} />

## Așteaptă finalizarea și salvează rezultatul semnat

Păstrează cititorul și cardul conectate pe durata semnării și a obținerii mărcii temporale. Finalizarea este afișată separat de lista de intrare. Folosește acțiunea rezultatului sau deschide Documente, selectează fișierul finalizat și Partajează pentru salvare în Fișiere ori trimitere către altă aplicație. Trimite rezultatul semnat, nu sursa nesemnată; include originalul pentru XML detașat.

<GuideScreenshot src="/img/guide/iphone/ro/progress.png" alt="Așteaptă finalizarea etapei curente fără a scoate cardul." steps={[{"text": "Așteaptă finalizarea etapei curente fără a scoate cardul.", "x": 10, "y": 45}]} />
<GuideScreenshot src="/img/guide/iphone/ro/success.png" alt="Verifică finalizarea și numele rezultatului înainte de deschidere sau partajare." steps={[{"text": "Verifică finalizarea și numele rezultatului înainte de deschidere sau partajare.", "x": 35, "y": 49}]} />

## Rezolvă o eroare la un document

Citește eroarea documentului afectat. Păstrează rezultatele deja finalizate și corectează fișierul ori conexiunea înainte de a porni intenționat un lot nou. PIN-ul nu este reîncercat automat. Dacă PIN-ul este greșit, oprește-te și confirmă PIN-ul și cardul selectat; trei încercări greșite pot bloca actul. Aplicația nu îl poate debloca. Reconectarea nu repară un PDF invalid.

<GuideScreenshot src="/img/guide/iphone/ro/file-error.png" alt="Citește eroarea documentului înainte de o nouă încercare." steps={[{"text": "Citește eroarea documentului înainte de o nouă încercare.", "x": 50, "y": 72}]} />
