---
title: "Folosește Scurtături și automatizări — Mac"
sidebar_label: "Folosește Scurtături și automatizări"
description: "Configurează Siri, Spotlight, Handoff și aprobarea disponibilă pe dispozitiv."
pagination_prev: "platforms/macos/preferences"
pagination_next: "platforms/macos/help"
---



# Folosește Scurtături și automatizări — Mac

[Ghidurile platformei](../macos.md) · [Instalare și conectarea cititorului](./setup.md)

Configurează Siri, Spotlight, Handoff și aprobarea disponibilă pe dispozitiv.

## Folosește Scurtături și Siri

1. Deschide aplicația Apple **Scurtături** și creează o scurtătură. Caută acțiunile **eSemnBun**.
2. Adaugă **Deschide documentele**, **Pregătește PDF pentru semnare** sau **Verifică PDF**. Acțiunile de fișier acceptă PDF-uri de maximum 32 MiB.
3. Rulează scurtătura și verifică ecranul eSemnBun deschis în prim-plan. Pregătirea nu semnează: conectează cardul potrivit și finalizează personal aprobarea Semnează/PIN.
4. Alege un nume ușor de reținut și invocă scurtătura prin Siri dacă limba și configurarea sistemului permit. Citește rezultatul complet al verificării în aplicație, inclusiv limitele de încredere.

Sugestiile sistemului, prezentarea nouă Siri pentru căutare/deschidere și limbile disponibile depind de macOS/SDK și de configurarea Siri. Invocarea live Siri nu este ilustrată și nu este declarată validată aici. Nicio scurtătură nu semnează în tăcere, nu schimbă PIN-ul și nu aprobă cereri de site.

## Găsește documente cu Spotlight și continuă cu Handoff

1. Activează descoperirea în General, ca mai sus. Semnează un PDF/XML eligibil, deținut de aplicație, și păstrează-l lizibil.
2. Deschide Spotlight cu **⌘Spațiu**, caută numele fișierului și selectează rezultatul eSemnBun. Aplicația deschide detaliile documentului salvat, dacă intrarea rămâne eligibilă.
3. Pentru continuare pe alt dispozitiv Apple, folosește același Cont Apple și activează Bluetooth, Wi-Fi și Handoff pe ambele. Deschide Documente în eSemnBun și folosește intrarea Handoff a sistemului pe celălalt dispozitiv.
4. Handoff reia **numai navigarea către Documente**. Nu copiază fișierul, nu transferă PIN-ul și nu continuă o semnătură în așteptare. Transferă fișierul separat prin metoda aleasă, dacă este necesar.

Indexarea Spotlight este opțională și limitată; un fișier scris lângă sursă de ediția independentă nu este automat eligibil.

## Aprobă o cerere locală de automatizare

Ediția macOS independentă oferă un broker de aprobare în prim-plan. Ediția App Store nu include acest broker.

1. În **Configurări → General → Automatizare locală**, activează **Permite cereri de semnare de la clienți locali** numai pentru un client pe care dorești să-l folosești.
2. Instalează/configurează [instrumentele CLI/MCP macOS](../macos-cli.md), alege explicit directoarele de intrare de încredere și configurează directorul privat de aprobare descris acolo.
3. Cere clientului să pregătească un PDF. Verifică previzualizarea nativă, numele/amprenta fișierului și cardul selectat în eSemnBun. Aprobă numai documentul dorit sau anulează.
4. Completează pasul PIN protejat. Clientul urmărește operațiunea și preia rezultatul final. Un rezultat în așteptare/necunoscut nu autorizează o nouă semnare.
5. Dezactivează Automatizarea locală la final pentru a respinge cererile în așteptare.

Comutatorul este vizibil în captura General de mai sus. Capturile nu ilustrează o semnătură reală prin broker sau preluarea nesupravegheată a acreditărilor. MCP nesupravegheat este o politică CLI separată și explicită, nu ocolirea ferestrei de aprobare.
