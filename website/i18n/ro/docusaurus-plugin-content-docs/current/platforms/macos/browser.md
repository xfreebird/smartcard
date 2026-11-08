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

Ilustrațiile folosesc date fictive. Urmează instrucțiunile în aplicația instalată.

## Folosește un serviciu și gestionează marcajele

Deschide Browser din bara laterală. Introdu adresa HTTPS a unui serviciu de încredere și apasă săgeata; înapoi, înainte și reîncărcare rămân în bara de instrumente. Meniul de marcaje oferă serviciile salvate, Adaugă marcaj, Gestionează marcajele și curățarea datelor. În dialogul de mai jos introdu titlul, URL-ul și pictograma, apoi Salvează. Închide cu Gata și alege serviciul din meniul de marcaje.

<GuideScreenshot src="/img/guide/macos/ro/browser.png" alt="Folosește un serviciu și gestionează marcajele" steps={[{"x": 45, "y": 58, "text": "Introdu un titlu ușor de recunoscut."}, {"x": 47, "y": 63, "text": "Verifică adresa completă a site-ului și alege pictograma de dedesubt."}, {"x": 68, "y": 82, "text": "Alege Salvează după validarea titlului și URL-ului; Gata închide gestionarea."}]} />

## Verifică fiecare cerere de semnare de pe site

Navighează la autentificarea/semnarea cu act electronic a serviciului. Citește originea și întreaga listă de documente în eSemnBun. Nu aproba cereri neașteptate. Încrederea temporară în site este opțională și limitată; nu autorizează o listă necunoscută de documente viitoare. După aprobare, completează pasul PIN și revino la serviciu pentru rezultat.

<GuideScreenshot src="/img/guide/macos/ro/consent.png" alt="Verifică fiecare cerere de semnare de pe site" steps={[{"x": 51, "y": 16, "text": "Confirmă site-ul exact care cere semnătura."}, {"x": 49, "y": 44, "text": "Derulează toate documentele și confirmă cardul și formatul."}, {"x": 81, "y": 92, "text": "Alege Semnează numai pentru cererea așteptată sau Refuză pentru anulare."}]} />

## Configurările browserului și curățarea datelor

1. Deschide **Configurări → Conexiune cu browserul**. Activează răspunsurile numai când ai nevoie de conexiunea locală; Browser-ul integrat este fluxul principal al ediției Store.
2. În ediția independentă, pentru browser extern vizitează un site acceptat pe același Mac, cu eSemnBun pornit. Acordă permisiunea de rețea locală cerută de browser pentru acel flux dorit.
3. Dacă MoldSign recunoscut ocupă porturile, finalizează operațiunea sa, apoi folosește acțiunea oferită de închidere/reconectare. Pentru un deținător necunoscut, rezolvă conflictul înainte de reîncercare. Nu ocoli avertismentele browserului privind certificatele.
4. În **Browser → meniul de marcaje → Șterge datele de navigare**, selectează memoria cache, cookie-urile și/sau istoricul și confirmă. Ștergerea cookie-urilor poate închide sesiunile. Documentele și PIN-urile salvate rămân.

Ștampilele PDF pentru browser și accesul pentru clienți desktop vechi au preferințe separate în Conexiune cu browserul. Activează accesul vechi numai pentru software-ul pe care vrei să-l folosești. Vezi [ghidul browserului](/docs/browser).
