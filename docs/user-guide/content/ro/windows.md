---
title: Windows — aplicația desktop
sidebar_position: 6
---

import GuideScreenshot from '@site/src/components/GuideScreenshot';

# Aplicația desktop pentru Windows

Se aplică versiunii **eSemnBun 0.2.13**, Windows 10 **1809 sau ulterior** și Windows 11. Consultă [ghidul CLI pentru Windows](/docs/platforms/windows-cli/) pentru PowerShell și automatizare.

## Instalează ediția potrivită

Pentru instalare independentă folosește **MSI** din [GitHub Releases](https://github.com/xfreebird/smartcard/releases/latest) sau instalează [eSemnBun din Microsoft Store](https://apps.microsoft.com/detail/9pdpr6rnt42s?hl=en-US&gl=MD). Alege arhitectura corespunzătoare calculatorului tău din fișierele versiunii. Un MSIX de dezvoltare nesemnat poate necesita un certificat de semnare și nu înlocuiește MSI-ul public.

1. Rulează MSI-ul și finalizează instalarea sau instalează din magazin.
2. Deschide **eSemnBun** din Start. Fereastra principală apare la prima pornire.
3. Conectează cititorul. miniLector folosește driverul CCID și serviciul Smart Card din Windows.
4. Introdu cardul și așteaptă încărcarea certificatului. Verifică titularul și expirarea înainte de semnare.





Mai multe carduri apar în caruselul orizontal. Selectează cardul centrat cu care intenționezi să semnezi. Ilustrația folosește datele certificatului și un avatar neutru, nu fotografia din actul de identitate.

### Alege și examinează cardul

<GuideScreenshot src="/img/guide/windows/ro/cards-current.png" alt="Deschide Setări și alege Carduri și cititoare pentru a consulta titularul, certificatul și cititorul conectat." steps={[{"text": "Deschide Setări și alege Carduri și cititoare pentru a consulta titularul, certificatul și cititorul conectat.", "x": 49, "y": 42}, {"text": "Alege titularul dorit din carusel înainte de a semna."}]} />

## Semnează documente din aplicație sau Explorer

În **Sign (Semnează)**, trage documentele în zona cu contur întrerupt sau alege **Choose files… (Alege fișiere…)**. Dacă ediția instalată oferă integrare în meniul contextual Explorer, poți trimite și fișierele selectate din Explorer în eSemnBun.

1. Adaugă fișierele și verifică formatul afișat lângă fiecare.
2. Pentru PDF folosește **PAdES-T** ca să încorporezi semnătura în PDF. XAdES produce XML; XML-ul detașat trebuie păstrat împreună cu documentul original.
3. Confirmă identitatea selectată, alege **Sign (Semnează)** și verifică cererea de autorizare înainte să introduci PIN-ul cardului sau să autentifici o intrare salvată.
4. Ține cititorul conectat până la finalizare. Folosește acțiunile rezultatului pentru a deschide sau localiza fișierele produse.

Autorizarea lotului se aplică listei de documente aprobate și cardului selectat. Dacă un element eșuează, citește eroarea înainte de a reîncerca. Nu confunda rezultatele finalizate cu intrările nesemnate. Consultă [formatele de semnare și erorile](/docs/signing).

### Pregătește lotul de semnare

<GuideScreenshot src="/img/guide/windows/ro/queue.png" alt="Pregătește lotul de semnare" steps={[{"x": 90.59, "y": 68.575, "text": "Alege fișierele sau trage-le în zona punctată."}, {"x": 33.764, "y": 50.393, "text": "Verifică formatul; folosește Ștampilă dezactivată pentru o ștampilă PDF opțională."}, {"x": 88.561, "y": 95.847, "text": "Verifică cardul selectat și alege Semnează pentru lotul afișat."}]} />

### Poziționează ștampila PDF vizibilă

<GuideScreenshot src="/img/guide/windows/ro/stamp.png" alt="Poziționează ștampila PDF vizibilă" steps={[{"x": 18.542, "y": 85.746, "text": "Mută și redimensionează ștampila în previzualizarea PDF. Textul urmează limba aplicației."}, {"x": 69.28, "y": 34.231, "text": "Alege pagina selectată sau toate paginile; opțional, aplică poziția tuturor PDF-urilor din listă."}, {"x": 93.635, "y": 95.847, "text": "Alege Aplică pentru a salva poziția înainte de semnare."}]} />

### Verifică autorizarea semnării

<GuideScreenshot src="/img/guide/windows/ro/pin.png" alt="Verifică autorizarea semnării" steps={[{"x": 50, "y": 42.693, "text": "Verifică identitatea selectată și lista completă de documente."}, {"x": 50, "y": 64.165, "text": "Introdu PIN-ul de semnare al cardului fizic doar după verificarea cererii. Nu ghici și nu repeta automat."}]} />

### Găsește rezultatele finalizate

<GuideScreenshot src="/img/guide/windows/ro/success.png" alt="Găsește rezultatele finalizate" steps={[{"text": "Deschide fișierul direct din rândul său.", "x": 80, "y": 22}, {"text": "Folosește butonul cu dosar pentru a localiza fișierul salvat.", "x": 90, "y": 22}]} />

## Verifică și consultă activitatea

Deschide **Verify (Verifică)** și alege sau plasează un PDF/XML semnat. O semnătură XML detașată necesită și documentul original. Consultă semnatarul, integritatea, lanțul de certificate și verificările disponibile ale mărcii temporale. Un nume de fișier sau o stare verde a cardului nu demonstrează validitatea semnăturii documentului.

**Documente → Istoric** înregistrează operațiunile recente și oferă acțiuni pentru fișierele disponibile. Ștergerea istoricului nu elimină documentele semnate propriu-zise.

### Alege documentul de verificat

<GuideScreenshot src="/img/guide/windows/ro/verify.png" alt="Alege documentul de verificat" steps={[{"x": 5.351, "y": 17.059, "text": "Deschide Verifică. Verificarea nu necesită card sau PIN."}, {"x": 60.148, "y": 28.171, "text": "Alege sau trage PDF-ul ori XML-ul semnat. Pentru XML detașat, furnizează originalele nemodificate la solicitare."}]} />

### Citește rezultatul verificării

<GuideScreenshot src="/img/guide/windows/ro/summary.png" alt="Citește rezultatul verificării" steps={[{"x": 36.808, "y": 40.292, "text": "Verifică rezultatul general, apoi autorul și momentul fiecărei semnături."}, {"x": 42.897, "y": 85.746, "text": "Citește separat integritatea, semnătura și încrederea. Derulează pentru limitele offline și detaliile certificatului."}]} />

### Examinează detaliile verificării

<GuideScreenshot src="/img/guide/windows/ro/results.png" alt="Examinează detaliile verificării" steps={[{"text": "Extinde detaliile tehnice pentru a vedea formatul și identificatorul semnăturii.", "x": 44, "y": 48}, {"text": "Consultă câmpurile semnăturii. Selectează din nou titlul pentru a restrânge detaliile.", "x": 49, "y": 66}]} />

## Configurări, PIN-uri și pictograma din zona de notificare

Deschide Setări. Modul demonstrativ este sus. Alege categoria pentru carduri, PIN-uri salvate, limbă sau aspect.

Configurările includ limba (română, engleză, rusă), aspectul, administrarea PIN-urilor salvate, preferințe de pornire și deschidere la conectarea cititorului, conexiunea cu browserul, modul demonstrativ și informații despre aplicație. Unele controale depind de distribuția instalată.

Un PIN salvat folosește facilitățile de securitate și autentificare Windows. Ștergerea lui elimină intrarea salvată de aplicație și nu modifică PIN-ul cardului fizic. Verifică cărui card îi aparține intrarea înainte de a o elimina.

Pictograma din zona de notificare oferă acces la aplicație și la acțiunile ei. Închiderea ferestrei principale poate lăsa eSemnBun pornit; folosește **Quit (Ieșire)** când vrei să îl oprești. În Configurări stabilește dacă se deschide la autentificare sau la introducerea unui cititor/card. Activează mai întâi opțiunea relevantă, apoi reconectează cititorul pentru a verifica comportamentul.

Modul demonstrativ necesită acceptare, arată carduri fictive și documente de exemplu și rămâne etichetat în utilizarea normală. Dezactivează-l pentru a reveni la cititorul tău. Secțiunea Despre arată pictograma, autorul, versiunea și site-ul.

### Schimbă limba și aspectul

<GuideScreenshot src="/img/guide/windows/ro/settings-current.png" alt="Deschide Setări. Modul demonstrativ este sus. Alege categoria pentru carduri, PIN-uri salvate, limbă sau aspect." steps={[{"text": "Deschide Setări. Modul demonstrativ este sus. Alege categoria pentru carduri, PIN-uri salvate, limbă sau aspect.", "x": 32, "y": 18}]} />

### Conexiune browser și cereri locale

<GuideScreenshot src="/img/guide/windows/ro/lower.png" alt="Conexiune browser și cereri locale" steps={[{"x": 24.631, "y": 24.13, "text": "Activează Conexiune browser pentru site-ul dorit pe acest computer."}, {"x": 24.631, "y": 36.251, "text": "Opțional, activează ștampilele vizibile pentru cererile din browser; alege poziția o dată pentru fiecare lot."}]} />

### Găsește versiunea instalată

<GuideScreenshot src="/img/guide/windows/ro/about.png" alt="Găsește versiunea instalată" steps={[{"x": 61.162, "y": 35.241, "text": "Deschide Despre în Setări și notează versiunea instalată când raportezi o problemă."}]} />

## Folosește conexiunea cu browserul

Activează **Browser connection (Conexiune cu browserul)** în Configurări. Deschide un serviciu acceptat într-un browser pe același calculator Windows. Când sosește o cerere, verifică site-ul, fișierele și cardul selectat înainte de autorizare.

Dacă alt server MoldSign ocupă porturile, finalizează operațiunile active ale aplicației furnizorului și folosește acțiunea oferită pentru rezolvarea conflictului, dacă există. Un singur bridge poate folosi porturile 18480/18443 la un moment dat. Dacă browserul cere acces la rețeaua locală, acordă-l pentru serviciul dorit, ca să poată contacta bridge-ul local. Consultă [serviciile în browser](/docs/browser).


<GuideScreenshot src="/img/guide/windows/ro/lower.png" alt="Browser connection" steps={[{"x": 25.138, "y": 23.827, "text": "Activează Conexiunea browser doar când folosești un site compatibil."}, {"x": 25.138, "y": 36.251, "text": "Opțional, activează ștampilele pentru browser și verifică poziția înainte de semnare."}]} />

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

<GuideScreenshot src="/img/guide/windows/ro/none.png" alt="Acționează când cititorul nu este detectat" steps={[{"x": 60.148, "y": 34.231, "text": "Citește îndrumările de conectare, reconectează cititorul USB și introdu cardul."}, {"x": 88.561, "y": 13.019, "text": "Recitește cardul după corectarea conexiunii. La o eroare PIN oprește-te; nu încerca să ghicești."}]} />

## Găsește și deschide documentele salvate

Documente salvate conține rezultate semnate, criptate și decriptate. Selectează un fișier semnat pentru detaliile semnăturii. Un fișier criptat oferă decriptarea; conținutul criptat nu este trimis la verificarea semnăturii. Fișierele decriptate își păstrează tipul rezultatului și pot fi deschise sau exportate.

Selectează numele unui fișier pentru detaliile semnării. Butoanele de pe rând deschid fișierul sau afișează dosarul său. Meniul rândului oferă verificarea și protejarea fișierului. Istoricul afișează operațiile recente. Golirea istoricului păstrează fișierele salvate.

### Găsește documentele semnate

<GuideScreenshot src="/img/guide/windows/ro/documents.png" alt="Găsește documentele semnate" steps={[{"text": "Selectează numele fișierului pentru a-i examina semnăturile.", "x": 38, "y": 24}, {"text": "Deschide fișierul direct din rândul său.", "x": 85, "y": 25}, {"text": "Folosește butonul cu dosar pentru a localiza fișierul salvat.", "x": 91, "y": 25}]} />

### Examinează un document salvat

<GuideScreenshot src="/img/guide/windows/ro/details.png" alt="Examinează un document salvat" steps={[{"text": "Citește rezultatul verificării și verifică semnatarul.", "x": 42, "y": 28}, {"text": "Deschide documentul sau afișează-l în dosarul său.", "x": 47, "y": 22}]} />

## Aprobă cereri locale de semnare (MCP)

În **Setări → General**, derulează la **Avansat** și activează **Permite cereri locale de semnare (MCP)**. Copiază dosarul privat afișat sub comutator în configurația clientului MCP. Păstrează eSemnBun deschis și selectează cardul dorit. Opțiunea nu este disponibilă în modul demonstrativ.

```powershell
& "C:\Program Files\eSemnBun\bin\esemnbun.exe" mcp `
  --root "documents=C:\Users\me\Documents\Signing" `
  --broker-directory "C:\Users\me\AppData\Local\MoldSign\MCP"
```

Folosește dosarul afișat de instalarea ta, în locul exemplului de mai jos. Clientul poate pregăti un PDF prin `prepare_signing`, verifica starea prin `get_job` sau anula prin `cancel_job`. Examinează PDF-ul în previzualizarea nativă și alege Semnează numai dacă aprobi cererea; urmează autorizarea cu cardul. Un PIN salvat nu omite această aprobare. Anularea sau expirarea timpului nu dovedește că nu a fost creată o semnătură.

Captura folosește un profil demonstrativ izolat: calea este un exemplu, iar comutatorul MCP este dezactivat. Nu a fost executată nicio cerere MCP de semnare pentru această captură.


<GuideScreenshot src="/img/guide/windows/ro/lower.png" alt="Conexiune browser și cereri locale" steps={[{"x": 24.631, "y": 82.716, "text": "Găsește comutatorul MCP în Avansat. În afara modului demonstrativ, activează-l și copiază dosarul privat în configurația clientului."}, {"x": 47.97, "y": 92.817, "text": "Folosește dosarul afișat de instalarea ta, nu calea demonstrativă."}]} />

<!-- file-protection-guides -->


## Criptează un fișier cu parolă

Deschide **Protejează fișiere** în partea de jos a barei de navigare și alege **Criptează**, **Decriptează** sau **Elimină fișierul**. Alege un fișier accesibil; derulează formularul la nevoie.

Nu ai nevoie de card. Creează o parolă pentru fișier și transmite-o destinatarului printr-un canal de încredere separat. Nu este PIN-ul cardului. Criptarea creează un rezultat separat; păstrează originalul până verifici rezultatul.

Alege **Parolă** și selectează AES-128, AES-192 sau AES-256. Opțiunea implicită este AES-256. Pentru a cripta pentru un destinatar, alege **Certificat RSA** și selectează certificatul său public de criptare (.cer sau .der). Implicit, folosește un certificat destinat criptării. **Compatibilitate cu cheia publică a cardului** permite explicit cheia RSA publică a cardului. Exportul sau criptarea reușită nu dovedesc că acel card poate decripta; cardul corespunzător trebuie să permită operația necesară cu cheia privată.

<GuideScreenshot src="/img/guide/windows/ro/protect-password-light.png" alt="Criptează un fișier cu parolă" steps={[{"text": "Alege fișierul de criptat.", "x": 36, "y": 29}, {"text": "Selectează AES-128, AES-192 sau AES-256. Opțiunea implicită este AES-256.", "x": 59, "y": 50}, {"text": "Introdu și confirmă o parolă nouă pentru fișier.", "x": 41, "y": 62}, {"text": "Alege Criptează, apoi salvează copia criptată.", "x": 41, "y": 88}]} />

<GuideScreenshot src="/img/guide/windows/ro/protect-certificate-light.png" alt="Criptează pentru un destinatar RSA" steps={[{"text": "Alege Certificat RSA.", "x": 46.7, "y": 41.1}, {"text": "Alege certificatul public de criptare al destinatarului.", "x": 40.0, "y": 59.5}, {"text": "Pentru a cripta pentru propriul card, conectează cititorul și citește certificatul său de criptare.", "x": 36.6, "y": 64.8}, {"text": "Folosește Compatibilitate cu cheia publică a cardului doar când fluxul cere cheia RSA publică a cardului.", "x": 42.3, "y": 45.8}]} />

Alege **Criptează** sau **Decriptează**, apoi **Salvează o copie** și alege un loc nou pentru rezultat. După salvare, fișierul apare în **Documente → Documente salvate**. Alege **Închide** pentru a închide operațiunea finalizată. Originalul este păstrat.

Documente salvate include fișiere semnate, criptate și decriptate. Identifică rezultatul după numele fișierului și eticheta operațiunii. Criptarea nu creează o semnătură digitală; fișierele criptate trebuie decriptate înainte de deschiderea sau verificarea conținutului.


## Decriptează un fișier primit

Deschide **Protejează fișiere** în partea de jos a barei de navigare și alege **Criptează**, **Decriptează** sau **Elimină fișierul**. Alege un fișier accesibil; derulează formularul la nevoie.

Pentru un fișier criptat cu parolă, cere parola expeditorului printr-un canal de încredere separat. Fișierul specifică dimensiunea cheii AES. Pentru fișierele RSA, conectează cardul care conține cheia de criptare a destinatarului, citește cardul și autorizează decriptarea cu PIN-ul său.

<GuideScreenshot src="/img/guide/windows/ro/protect-decrypt-light.png" alt="Decriptează un fișier primit" steps={[{"text": "Alege fișierul criptat. Conținutul său determină metoda de decriptare.", "x": 33, "y": 33}, {"text": "Pentru un fișier criptat cu parolă, introdu parola primită de la expeditor.", "x": 40, "y": 60}, {"text": "Alege Decriptează și salvează rezultatul într-un fișier nou.", "x": 39, "y": 84}]} />

<GuideScreenshot src="/img/guide/windows/ro/protect-rsa-decrypt-light.png" alt="Pentru un fișier RSA, conectează cititorul și cardul destinatarului, apoi alege Citește cardul meu. Autorizează cu PIN-ul cardului." steps={[{"text": "Pentru un fișier RSA, conectează cititorul și cardul destinatarului, apoi alege Citește cardul meu. Autorizează cu PIN-ul cardului.", "x": 38.0, "y": 61.4}]} />

Deschide și verifică rezultatul salvat înainte de utilizare. Criptarea compatibilă MoldSign nu autentifică conținutul: decriptarea reușită nu dovedește singură integritatea sau parola corectă.

Alege **Criptează** sau **Decriptează**, apoi **Salvează o copie** și alege un loc nou pentru rezultat. După salvare, fișierul apare în **Documente → Documente salvate**. Alege **Închide** pentru a închide operațiunea finalizată. Originalul este păstrat.

Documente salvate include fișiere semnate, criptate și decriptate. Identifică rezultatul după numele fișierului și eticheta operațiunii. Criptarea nu creează o semnătură digitală; fișierele criptate trebuie decriptate înainte de deschiderea sau verificarea conținutului.


## Elimină un fișier local

Deschide **Protejează fișiere** în partea de jos a barei de navigare și alege **Criptează**, **Decriptează** sau **Elimină fișierul**. Alege un fișier accesibil; derulează formularul la nevoie.

Doar pe desktop. Operațiunea elimină definitiv un fișier local obișnuit acceptat, după confirmare. Nu garantează ștergerea de pe SSD, din instantanee, copii de rezervă sau alte copii. Locațiile neacceptate și legăturile sunt refuzate. Furnizorii de documente mobili nu acceptă operațiunea.

<GuideScreenshot src="/img/guide/windows/ro/protect-remove-light.png" alt="Elimină un fișier local" steps={[{"text": "Alege fișierul și citește numele acestuia și avertismentul de ștergere.", "x": 33, "y": 43}, {"text": "Confirmă ștergerea doar după ce ai verificat fișierul selectat.", "x": 38, "y": 61}, {"text": "Alege Elimină fișierul pentru a finaliza operația.", "x": 39, "y": 74}]} />
