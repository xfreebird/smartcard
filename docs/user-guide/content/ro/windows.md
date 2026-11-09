---
title: Windows — aplicația desktop
sidebar_position: 6
---

import GuideScreenshot from '@site/src/components/GuideScreenshot';

# Aplicația desktop pentru Windows

Se aplică versiunii **eSemnBun 0.2.6**, Windows 10 **1809 sau ulterior** și Windows 11. Consultă [ghidul CLI pentru Windows](/docs/platforms/windows-cli/) pentru PowerShell și automatizare.

## Instalează ediția potrivită

Pentru instalare independentă folosește **MSI** din [GitHub Releases](https://github.com/xfreebird/smartcard/releases/latest) sau instalează [eSemnBun din Microsoft Store](https://apps.microsoft.com/detail/9pdpr6rnt42s?hl=en-US&gl=MD). Alege arhitectura corespunzătoare calculatorului tău din fișierele versiunii. Un MSIX de dezvoltare nesemnat poate necesita un certificat de semnare și nu înlocuiește MSI-ul public.

1. Rulează MSI-ul și finalizează instalarea sau instalează din magazin.
2. Deschide **eSemnBun** din Start. Fereastra principală apare la prima pornire.
3. Conectează cititorul. miniLector folosește driverul CCID și serviciul Smart Card din Windows.
4. Introdu cardul și așteaptă încărcarea certificatului. Verifică titularul și expirarea înainte de semnare.





Mai multe carduri apar în caruselul orizontal. Selectează cardul centrat cu care intenționezi să semnezi. Ilustrația folosește datele certificatului și un avatar neutru, nu fotografia din actul de identitate.

### Alege și examinează cardul

<GuideScreenshot src="/img/guide/windows/ro/card.png" alt="Alege și examinează cardul" steps={[{"x": 6, "y": 26, "text": "Deschide Card după conectarea cititorului și introducerea cardului."}, {"x": 60, "y": 31, "text": "Verifică titularul și expirarea; alege cardul dorit din carusel."}, {"x": 51, "y": 58, "text": "Examinează certificatul și cititorul înainte de semnare."}]} />

## Semnează documente din aplicație sau Explorer

În **Sign (Semnează)**, trage documentele în zona cu contur întrerupt sau alege **Choose files… (Alege fișiere…)**. Dacă ediția instalată oferă integrare în meniul contextual Explorer, poți trimite și fișierele selectate din Explorer în eSemnBun.

1. Adaugă fișierele și verifică formatul afișat lângă fiecare.
2. Pentru PDF folosește **PAdES-T** ca să încorporezi semnătura în PDF. XAdES produce XML; XML-ul detașat trebuie păstrat împreună cu documentul original.
3. Confirmă identitatea selectată, alege **Sign (Semnează)** și verifică cererea de autorizare înainte să introduci PIN-ul cardului sau să autentifici o intrare salvată.
4. Ține cititorul conectat până la finalizare. Folosește acțiunile rezultatului pentru a deschide sau localiza fișierele produse.

Autorizarea lotului se aplică listei de documente aprobate și cardului selectat. Dacă un element eșuează, citește eroarea înainte de a reîncerca. Nu confunda rezultatele finalizate cu intrările nesemnate. Consultă [formatele de semnare și erorile](/docs/signing).

### Pregătește lotul de semnare

<GuideScreenshot src="/img/guide/windows/ro/queue.png" alt="Pregătește lotul de semnare" steps={[{"x": 90, "y": 68, "text": "Alege fișierele sau trage-le în zona punctată."}, {"x": 34, "y": 50, "text": "Verifică formatul; folosește Ștampilă dezactivată pentru o ștampilă PDF opțională."}, {"x": 88, "y": 95, "text": "Verifică cardul selectat și alege Semnează pentru lotul afișat."}]} />

### Poziționează ștampila PDF vizibilă

<GuideScreenshot src="/img/guide/windows/ro/stamp.png" alt="Poziționează ștampila PDF vizibilă" steps={[{"x": 19, "y": 85, "text": "Mută și redimensionează ștampila în previzualizarea PDF. Textul urmează limba aplicației."}, {"x": 69, "y": 34, "text": "Alege pagina selectată sau toate paginile; opțional, aplică poziția tuturor PDF-urilor din listă."}, {"x": 93, "y": 95, "text": "Alege Aplică pentru a salva poziția înainte de semnare."}]} />

### Verifică autorizarea semnării

<GuideScreenshot src="/img/guide/windows/ro/pin.png" alt="Verifică autorizarea semnării" steps={[{"x": 50, "y": 42, "text": "Verifică identitatea selectată și lista completă de documente."}, {"x": 50, "y": 63, "text": "Introdu PIN-ul de semnare al cardului fizic doar după verificarea cererii. Nu ghici și nu repeta automat."}]} />

### Găsește rezultatele finalizate

<GuideScreenshot src="/img/guide/windows/ro/success.png" alt="Găsește rezultatele finalizate" steps={[{"x": 90, "y": 23, "text": "Examinează fiecare rând finalizat și folosește acțiunea de deschidere sau afișare."}, {"x": 44, "y": 23, "text": "Păstrează XML-ul detașat cu originalul nemodificat. Rezultatele ilustrate sunt fictive."}]} />

## Verifică și consultă activitatea

Deschide **Verify (Verifică)** și alege sau plasează un PDF/XML semnat. O semnătură XML detașată necesită și documentul original. Consultă semnatarul, integritatea, lanțul de certificate și verificările disponibile ale mărcii temporale. Un nume de fișier sau o stare verde a cardului nu demonstrează validitatea semnăturii documentului.

**Documente → Istoric** înregistrează operațiunile recente și oferă acțiuni pentru fișierele disponibile. Ștergerea istoricului nu elimină documentele semnate propriu-zise.

### Alege documentul de verificat

<GuideScreenshot src="/img/guide/windows/ro/verify.png" alt="Alege documentul de verificat" steps={[{"x": 6, "y": 17, "text": "Deschide Verifică. Verificarea nu necesită card sau PIN."}, {"x": 60, "y": 28, "text": "Alege sau trage PDF-ul ori XML-ul semnat. Pentru XML detașat, furnizează originalele nemodificate la solicitare."}]} />

### Citește rezultatul verificării

<GuideScreenshot src="/img/guide/windows/ro/summary.png" alt="Citește rezultatul verificării" steps={[{"x": 37, "y": 40, "text": "Verifică rezultatul general, apoi autorul și momentul fiecărei semnături."}, {"x": 43, "y": 85, "text": "Citește separat integritatea, semnătura și încrederea. Derulează pentru limitele offline și detaliile certificatului."}]} />

### Examinează detaliile verificării

<GuideScreenshot src="/img/guide/windows/ro/results.png" alt="Examinează detaliile verificării" steps={[{"x": 60, "y": 14, "text": "Citește limitele verificării offline: încrederea în marca temporală și revocarea curentă pot rămâne neverificate."}, {"x": 60, "y": 23, "text": "Extinde detaliile certificatului și cele tehnice pentru semnatar, valabilitate și marcă temporală."}]} />

## Configurări, PIN-uri și pictograma din zona de notificare

Configurările includ limba (română, engleză, rusă), aspectul, administrarea PIN-urilor salvate, preferințe de pornire și deschidere la conectarea cititorului, conexiunea cu browserul, modul demonstrativ și informații despre aplicație. Unele controale depind de distribuția instalată.

Un PIN salvat folosește facilitățile de securitate și autentificare Windows. Ștergerea lui elimină intrarea salvată de aplicație și nu modifică PIN-ul cardului fizic. Verifică cărui card îi aparține intrarea înainte de a o elimina.

Pictograma din zona de notificare oferă acces la aplicație și la acțiunile ei. Închiderea ferestrei principale poate lăsa eSemnBun pornit; folosește **Quit (Ieșire)** când vrei să îl oprești. În Configurări stabilește dacă se deschide la autentificare sau la introducerea unui cititor/card. Activează mai întâi opțiunea relevantă, apoi reconectează cititorul pentru a verifica comportamentul.

Modul demonstrativ necesită acceptare, arată carduri fictive și documente de exemplu și rămâne etichetat în utilizarea normală. Dezactivează-l pentru a reveni la cititorul tău. Secțiunea Despre arată pictograma, autorul, versiunea și site-ul.

### Schimbă limba și aspectul

<GuideScreenshot src="/img/guide/windows/ro/settings.png" alt="Schimbă limba și aspectul" steps={[{"x": 7, "y": 96, "text": "Deschide Setări."}, {"x": 28, "y": 88, "text": "Alege limba și aspectul aplicației."}]} />

### Conexiune browser și cereri locale

<GuideScreenshot src="/img/guide/windows/ro/lower.png" alt="Conexiune browser și cereri locale" steps={[{"x": 25, "y": 24, "text": "Activează Conexiune browser pentru site-ul dorit pe acest computer."}, {"x": 25, "y": 36, "text": "Opțional, activează ștampilele vizibile pentru cererile din browser; alege poziția o dată pentru fiecare lot."}]} />

### Găsește versiunea instalată

<GuideScreenshot src="/img/guide/windows/ro/about.png" alt="Găsește versiunea instalată" steps={[{"x": 61, "y": 35, "text": "Deschide Despre în Setări și notează versiunea instalată când raportezi o problemă."}]} />

## Folosește conexiunea cu browserul

Activează **Browser connection (Conexiune cu browserul)** în Configurări. Deschide un serviciu acceptat într-un browser pe același calculator Windows. Când sosește o cerere, verifică site-ul, fișierele și cardul selectat înainte de autorizare.

Dacă alt server MoldSign ocupă porturile, finalizează operațiunile active ale aplicației furnizorului și folosește acțiunea oferită pentru rezolvarea conflictului, dacă există. Un singur bridge poate folosi porturile 18480/18443 la un moment dat. Dacă browserul cere acces la rețeaua locală, acordă-l pentru serviciul dorit, ca să poată contacta bridge-ul local. Consultă [serviciile în browser](/docs/browser).


<GuideScreenshot src="/img/guide/windows/ro/lower.png" alt="Browser connection" steps={[{"x": 25.5, "y": 23.7, "text": "Activează Conexiunea browser doar când folosești un site compatibil."}, {"x": 25.5, "y": 36, "text": "Opțional, activează ștampilele pentru browser și verifică poziția înainte de semnare."}]} />

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

### Acționează când cititorul nu este detectat

<GuideScreenshot src="/img/guide/windows/ro/none.png" alt="Acționează când cititorul nu este detectat" steps={[{"x": 60, "y": 34, "text": "Citește îndrumările de conectare, reconectează cititorul USB și introdu cardul."}, {"x": 88, "y": 13, "text": "Recitește cardul după corectarea conexiunii. La o eroare PIN oprește-te; nu încerca să ghicești."}]} />

## Găsește și deschide documentele salvate
Deschide Documente și selectează lista documentelor semnate. Alege un element pentru detaliile semnării, apoi folosește acțiunile de deschidere sau afișare. Comută la istoric pentru operațiile recente. Golirea istoricului păstrează biblioteca independentă de documente semnate și nu șterge fișierele semnate.

### Găsește documentele semnate

<GuideScreenshot src="/img/guide/windows/ro/documents.png" alt="Găsește documentele semnate" steps={[{"x": 51, "y": 18, "text": "Deschide Documente și selectează lista documentelor semnate."}, {"x": 33, "y": 31, "text": "Alege un document salvat pentru a deschide detaliile semnării."}]} />

### Examinează un document salvat

<GuideScreenshot src="/img/guide/windows/ro/details.png" alt="Examinează un document salvat" steps={[{"x": 51, "y": 45, "text": "Verifică informațiile de semnare înainte de a deschide sau distribui fișierul."}]} />

## Aprobă cereri locale de semnare (MCP)

În **Setări → General**, derulează la **Avansat** și activează **Permite cereri locale de semnare (MCP)**. Copiază dosarul privat afișat sub comutator în configurația clientului MCP. Păstrează eSemnBun deschis și selectează cardul dorit. Opțiunea nu este disponibilă în modul demonstrativ.

```powershell
& "C:\Program Files\eSemnBun\bin\esemnbun.exe" mcp `
  --root "documents=C:\Users\me\Documents\Signing" `
  --broker-directory "C:\Users\me\AppData\Local\MoldSign\MCP"
```

Folosește dosarul afișat de instalarea ta, în locul exemplului de mai jos. Clientul poate pregăti un PDF prin `prepare_signing`, verifica starea prin `get_job` sau anula prin `cancel_job`. Examinează PDF-ul în previzualizarea nativă și alege Semnează numai dacă aprobi cererea; urmează autorizarea cu cardul. Un PIN salvat nu omite această aprobare. Anularea sau expirarea timpului nu dovedește că nu a fost creată o semnătură.

Captura folosește un profil demonstrativ izolat: calea este un exemplu, iar comutatorul MCP este dezactivat. Nu a fost executată nicio cerere MCP de semnare pentru această captură.


<GuideScreenshot src="/img/guide/windows/ro/lower.png" alt="Conexiune browser și cereri locale" steps={[{"x": 25, "y": 82, "text": "Găsește comutatorul MCP în Avansat. În afara modului demonstrativ, activează-l și copiază dosarul privat în configurația clientului."}, {"x": 48, "y": 92, "text": "Folosește dosarul afișat de instalarea ta, nu calea demonstrativă."}]} />

<!-- file-protection-guides -->


## Criptează un fișier cu parolă

Deschide Documente → Protejează fișiere. Alege un fișier accesibil; derulează formularul la nevoie. Ghidurile descriu noua funcție de protecție, care poate lipsi încă din versiunea instalată din magazin.

Nu ai nevoie de card. Creează o parolă pentru fișier și transmite-o destinatarului printr-un canal de încredere separat. Nu este PIN-ul cardului. Criptarea creează un rezultat separat; păstrează originalul până verifici rezultatul.

<GuideScreenshot src="/img/guide/windows/ro/protect-password-light.png" alt="Criptează un fișier cu parolă" caption="Date fictive. Înainte de finalizare." steps={[{"x": 40, "y": 15, "text": "Alege Criptează."}, {"x": 35, "y": 27, "text": "Alege fișierul sursă."}, {"x": 40, "y": 58, "text": "Alege Parolă, introdu o parolă nouă și repet-o în câmpul de confirmare."}, {"x": 40, "y": 94, "text": "Alege Criptează, apoi salvează fișierul criptat nou."}]} />


## Criptează pentru titularul unui certificat

Deschide Documente → Protejează fișiere. Alege un fișier accesibil; derulează formularul la nevoie. Ghidurile descriu noua funcție de protecție, care poate lipsi încă din versiunea instalată din magazin.

Cere destinatarului certificatul public de criptare (.cer/.der), exportat conform ghidului următor. Confirmă amprenta cu titularul printr-un canal de încredere. Un certificat doar pentru semnare nu este suficient. Pentru criptare ai nevoie de certificatul public, nu de cardul, cheia privată sau PIN-ul destinatarului.

<GuideScreenshot src="/img/guide/windows/ro/protect-certificate-light.png" alt="Criptează pentru titularul unui certificat" caption="Date fictive. Înainte de finalizare." steps={[{"x": 40, "y": 15, "text": "Alege Criptează."}, {"x": 35, "y": 27, "text": "Alege fișierul sursă."}, {"x": 40, "y": 42, "text": "Alege Certificat/card."}, {"x": 37, "y": 54, "text": "Alege fișierul certificatului destinatarului."}, {"x": 40, "y": 94, "text": "Alege Criptează, apoi salvează fișierul criptat nou."}]} />


## Decriptează un fișier primit

Deschide Documente → Protejează fișiere. Alege un fișier accesibil; derulează formularul la nevoie. Ghidurile descriu noua funcție de protecție, care poate lipsi încă din versiunea instalată din magazin.

Întreabă expeditorul ce metodă a folosit. Pentru fișiere cu parolă, obține parola separat. Pentru fișiere cu certificat, conectează cardul corespunzător și cititorul compatibil; ai nevoie de cheia de criptare și PIN. Alt card sau un card doar pentru semnare nu poate decripta fișierul.

<GuideScreenshot src="/img/guide/windows/ro/protect-decrypt-light.png" alt="Decriptează un fișier primit" caption="Date fictive. Înainte de finalizare." steps={[{"x": 40, "y": 25, "text": "Alege Decriptează și selectează fișierul criptat primit."}, {"x": 40, "y": 60, "text": "Alege Parolă și introdu parola primită de la expeditor."}, {"x": 40, "y": 88, "text": "Alege Decriptează și salvează rezultatul cu un nume nou."}]} />

Pentru decriptare cu cardul: alege Certificat/card, apoi Citește cardul meu. Selectează identitatea de criptare corespunzătoare, verifică detaliile, introdu PIN-ul și alege Decriptează. Salvează cu un nume nou. Dacă nu apare o identitate compatibilă, cere o copie criptată cu parolă. Oprește-te după o eroare PIN; nu reîncerca automat.

Deschide și verifică rezultatul salvat înainte de utilizare. Criptarea compatibilă MoldSign nu autentifică conținutul: decriptarea reușită nu dovedește singură integritatea sau parola corectă.


## Distribuie certificatul tău de criptare

Deschide Documente → Protejează fișiere. Alege un fișier accesibil; derulează formularul la nevoie. Ghidurile descriu noua funcție de protecție, care poate lipsi încă din versiunea instalată din magazin.

Conectează cardul și cititorul USB compatibil. Exportul certificatului public nu necesită document sau PIN. Cardul trebuie să ofere o identitate de criptare; certificatul obișnuit de semnare nu îl înlocuiește.

<GuideScreenshot src="/img/guide/windows/ro/protect-certificate-light.png" alt="Criptează pentru titularul unui certificat" caption="Date fictive. Înainte de finalizare." steps={[{"x": 40, "y": 42, "text": "Alege Certificat/card."}, {"x": 37, "y": 61, "text": "Alege Citește cardul meu; derulează la nevoie."}]} />

După citire, selectează identitatea dorită și extinde Detalii certificat. Alege Exportă certificatul de criptare, salvează fișierul .cer și transmite-l expeditorului. Compară amprenta separat. Se exportă numai certificatul public; cheia privată rămâne pe card. Captura arată ecranul inițial, înainte de citire.


## Elimină un fișier local

Deschide Documente → Protejează fișiere. Alege un fișier accesibil; derulează formularul la nevoie. Ghidurile descriu noua funcție de protecție, care poate lipsi încă din versiunea instalată din magazin.

Doar pe desktop. Operațiunea elimină definitiv un fișier local obișnuit acceptat, după confirmare. Nu garantează ștergerea de pe SSD, din instantanee, copii de rezervă sau alte copii. Locațiile neacceptate și legăturile sunt refuzate. Furnizorii de documente mobili nu acceptă operațiunea.

<GuideScreenshot src="/img/guide/windows/ro/protect-remove-light.png" alt="Elimină un fișier local" caption="Date fictive. Înainte de finalizare." steps={[{"x": 40, "y": 28, "text": "Alege Elimină fișierul."}, {"x": 35, "y": 40, "text": "Selectează exact fișierul de eliminat și citește avertismentul."}, {"x": 40, "y": 78, "text": "Confirmă eliminarea numai după verificarea numelui. Apoi alege Elimină fișierul și confirmă solicitarea afișată."}]} />
