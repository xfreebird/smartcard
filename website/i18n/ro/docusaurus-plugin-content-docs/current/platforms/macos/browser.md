---
title: "Semnează pe site-uri — Mac"
sidebar_label: "Semnează pe site-uri"
description: "Conectează un serviciu, verifică cererile și gestionează sesiunile web."
pagination_prev: "platforms/macos/documents"
pagination_next: "platforms/macos/preferences"
---

import GuideScreenshot from '@site/src/components/GuideScreenshot';

# Semnează pe site-uri — Mac

[Ghidurile platformei](../macos.md) · [Instalare și conectarea cititorului](./setup.md)

Conectează un serviciu, verifică cererile și gestionează sesiunile web.

## Folosește un serviciu și gestionează marcajele

Deschide Browser din bara laterală. Introdu adresa HTTPS a unui serviciu de încredere și apasă săgeata; înapoi, înainte și reîncărcare rămân în bara de instrumente. Meniul de marcaje oferă serviciile salvate, Adaugă marcaj, Gestionează marcajele și curățarea datelor. În dialogul de mai jos introdu titlul, URL-ul și pictograma, apoi Salvează. Închide cu Gata și alege serviciul din meniul de marcaje.

<GuideScreenshot src="/img/guide/macos/ro/browser.png" alt="Folosește un serviciu și gestionează marcajele" steps={[{"x": 51, "y": 57, "text": "Introdu un titlu ușor de recunoscut."}, {"x": 48, "y": 60, "text": "Verifică adresa completă a site-ului și alege pictograma de dedesubt."}, {"x": 65, "y": 75, "text": "Alege Salvează după validarea titlului și URL-ului; Gata închide gestionarea."}]} />

## Verifică fiecare cerere de semnare de pe site

Navighează la autentificarea/semnarea cu act electronic a serviciului. Citește originea și întreaga listă de documente în eSemnBun. Nu aproba cereri neașteptate. Încrederea temporară în site este opțională și limitată; nu autorizează o listă necunoscută de documente viitoare. După aprobare, completează pasul PIN și revino la serviciu pentru rezultat.

<GuideScreenshot src="/img/guide/macos/ro/consent.png" alt="Verifică fiecare cerere de semnare de pe site" steps={[{"x": 51, "y": 16, "text": "Confirmă site-ul exact care cere semnătura."}, {"x": 49, "y": 44, "text": "Derulează toate documentele și confirmă cardul și formatul."}, {"x": 81, "y": 92, "text": "Alege Semnează numai pentru cererea așteptată sau Refuză pentru anulare."}]} />

## Configurările browserului și curățarea datelor

1. Deschide **Configurări → Conexiune cu browserul** și activează răspunsurile când ai nevoie de conexiunea locală. Atât ediția Mac App Store, cât și ediția independentă permit Browser-ul integrat și browserele externe compatibile.
2. Pentru un browser extern, lasă eSemnBun pornit pe același Mac, conectează cititorul USB, introdu cardul și așteaptă afișarea identității. Vizitează un site acceptat și acordă permisiunea de rețea locală cerută de browser pentru acel flux dorit. Verifică site-ul și identitatea selectată în eSemnBun înainte de a aproba o cerere.
3. Dacă MoldSign ocupă porturile, finalizează operațiunea sa și închide-l. Ediția independentă poate oferi o acțiune de închidere/reconectare; în ediția Mac App Store, închide tu aplicația care ocupă porturile, apoi reîncearcă conexiunea. Pentru un deținător necunoscut, rezolvă conflictul înainte de reîncercare. Nu ocoli avertismentele browserului privind certificatele.
4. În **Browser → meniul de marcaje → Șterge datele de navigare**, selectează memoria cache, cookie-urile și/sau istoricul și confirmă. Ștergerea cookie-urilor poate închide sesiunile. Documentele și PIN-urile salvate rămân.

Ștampilele PDF pentru browser au propria preferință în Conexiune cu browserul. Ediția independentă oferă și acces pentru clienți desktop vechi; activează-l numai pentru software-ul pe care vrei să-l folosești. Ediția Mac App Store nu acceptă cereri din browser care conțin căi arbitrare către fișiere locale. Vezi [ghidul browserului](/docs/browser).
