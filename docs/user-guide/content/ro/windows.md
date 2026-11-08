---
title: Windows — aplicația desktop
sidebar_position: 6
---

import PlatformScreenshots from '@site/src/components/PlatformScreenshots';

# Aplicația desktop pentru Windows

Se aplică versiunii **eSemnBun 0.2.0**, Windows 10 **1809 sau ulterior** și Windows 11. Consultă [ghidul CLI pentru Windows](/docs/platforms/windows-cli/) pentru PowerShell și automatizare.

## Instalează ediția potrivită

Pentru instalare independentă folosește **MSI** din [GitHub Releases](https://github.com/xfreebird/smartcard/releases/latest) sau instalează [eSemnBun din Microsoft Store](https://apps.microsoft.com/detail/9pdpr6rnt42s?hl=en-US&gl=MD). Alege arhitectura corespunzătoare calculatorului tău din fișierele versiunii. Un MSIX de dezvoltare nesemnat poate necesita un certificat de semnare și nu înlocuiește MSI-ul public.

1. Rulează MSI-ul și finalizează instalarea sau instalează din magazin.
2. Deschide **eSemnBun** din Start. Fereastra principală apare la prima pornire.
3. Conectează cititorul. miniLector folosește driverul CCID și serviciul Smart Card din Windows.
4. Introdu cardul și așteaptă încărcarea certificatului. Verifică titularul și expirarea înainte de semnare.

Captura existentă arată interfața în engleză; aspectul ei urmează tema luminoasă sau întunecată a site-ului.

<PlatformScreenshots platform="windows" alt="Pagina de semnare Windows cu cardul deasupra zonei de plasare a documentelor" caption="Spațiul de lucru Windows în captura existentă în engleză, în tema site-ului." />

Mai multe carduri apar în caruselul orizontal. Selectează cardul centrat cu care intenționezi să semnezi. Ilustrația folosește datele certificatului și un avatar neutru, nu fotografia din actul de identitate.

## Semnează documente din aplicație sau Explorer

În **Sign (Semnează)**, trage documentele în zona cu contur întrerupt sau alege **Choose files… (Alege fișiere…)**. Dacă ediția instalată oferă integrare în meniul contextual Explorer, poți trimite și fișierele selectate din Explorer în eSemnBun.

1. Adaugă fișierele și verifică formatul afișat lângă fiecare.
2. Pentru PDF folosește **PAdES-T** ca să încorporezi semnătura în PDF. XAdES produce XML; XML-ul detașat trebuie păstrat împreună cu documentul original.
3. Confirmă identitatea selectată, alege **Sign (Semnează)** și verifică cererea de autorizare înainte să introduci PIN-ul cardului sau să autentifici o intrare salvată.
4. Ține cititorul conectat până la finalizare. Folosește acțiunile rezultatului pentru a deschide sau localiza fișierele produse.

Autorizarea lotului se aplică listei de documente aprobate și cardului selectat. Dacă un element eșuează, citește eroarea înainte de a reîncerca. Nu confunda rezultatele finalizate cu intrările nesemnate. Consultă [formatele de semnare și erorile](/docs/signing).

## Verifică și consultă activitatea

Deschide **Verify (Verifică)** și alege sau plasează un PDF/XML semnat. O semnătură XML detașată necesită și documentul original. Consultă semnatarul, integritatea, lanțul de certificate și verificările disponibile ale mărcii temporale. Un nume de fișier sau o stare verde a cardului nu demonstrează validitatea semnăturii documentului.

**Activity (Activitate)** înregistrează operațiunile recente și oferă acțiuni pentru fișierele disponibile. Ștergerea istoricului nu elimină documentele semnate propriu-zise.

## Configurări, PIN-uri și pictograma din zona de notificare

Configurările includ limba (română, engleză, rusă), aspectul, administrarea PIN-urilor salvate, preferințe de pornire și deschidere la conectarea cititorului, conexiunea cu browserul, modul demonstrativ și informații despre aplicație. Unele controale depind de distribuția instalată.

Un PIN salvat folosește facilitățile de securitate și autentificare Windows. Ștergerea lui elimină intrarea salvată de aplicație și nu modifică PIN-ul cardului fizic. Verifică cărui card îi aparține intrarea înainte de a o elimina.

Pictograma din zona de notificare oferă acces la aplicație și la acțiunile ei. Închiderea ferestrei principale poate lăsa eSemnBun pornit; folosește **Quit (Ieșire)** când vrei să îl oprești. În Configurări stabilește dacă se deschide la autentificare sau la introducerea unui cititor/card. Activează mai întâi opțiunea relevantă, apoi reconectează cititorul pentru a verifica comportamentul.

Modul demonstrativ necesită acceptare, arată carduri fictive și documente de exemplu și rămâne etichetat în utilizarea normală. Dezactivează-l pentru a reveni la cititorul tău. Secțiunea Despre arată pictograma, autorul, versiunea și site-ul.

## Folosește conexiunea cu browserul

Activează **Browser connection (Conexiune cu browserul)** în Configurări. Deschide un serviciu acceptat într-un browser pe același calculator Windows. Când sosește o cerere, verifică site-ul, fișierele și cardul selectat înainte de autorizare.

Dacă alt server MoldSign ocupă porturile, finalizează operațiunile active ale aplicației furnizorului și folosește acțiunea oferită pentru rezolvarea conflictului, dacă există. Un singur bridge poate folosi porturile 18480/18443 la un moment dat. Dacă browserul cere acces la rețeaua locală, acordă-l pentru serviciul dorit, ca să poată contacta bridge-ul local. Consultă [serviciile în browser](/docs/browser).

## Actualizează sau rezolvă o problemă

Instalările Microsoft Store se actualizează prin magazin. Versiunile independente oferă verificări de actualizare care deschid pagina de descărcare; instalează MSI-ul nou al versiunii.

| Simptom | Pasul următor |
| --- | --- |
| Cititorul lipsește | Verifică cititorul de carduri inteligente în Device Manager; reconectează-l și verifică serviciul Smart Card. |
| Certificatul nu se încarcă | Reintrodu cardul și lasă citirea să se încheie. |
| Identitate greșită | Selectează cardul dorit înainte de a introduce PIN-ul lui. |
| Portul browserului este ocupat | Oprește serverul concurent recunoscut, apoi reconectează. |
| PIN-ul salvat nu este disponibil | Introdu PIN-ul manual și verifică autentificarea/configurările Windows. |
| Documentul eșuează | Citește eroarea, păstrează sursa și corectează cauza înainte de a reîncerca. |

Oprește-te după un rezultat de PIN incorect și verifică PIN-ul, în loc să îl ghicești. Raportează versiunile aplicației și Windows, ediția MSI sau Store, arhitectura, modelul cititorului și pașii de reproducere. Consultă [depanarea](/docs/troubleshooting).
