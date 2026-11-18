---
title: "Linux — ghid desktop ilustrat"
sidebar_position: 7
---

import GuideScreenshot from '@site/src/components/GuideScreenshot';

# Linux — ghid desktop ilustrat

Urmează capturile numerotate pentru eSemnBun 0.2.13 pe Linux. Atinge imaginea pentru mărire și alege Mărime originală pentru detalii.

Instalează pachetul desktop pentru distribuția și arhitectura ta din [Descărcări](/downloads/), apoi deschide eSemnBun din meniul de aplicații. Pachetele desktop DEB/RPM/Flatpak deschid aplicația grafică; depozitele și arhivele CLI instalează instrumentele de terminal. Consultă [ghidul CLI Linux](./linux-cli.md) pentru terminal și MCP. Ubuntu 24.04/Fedora sunt platforme desktop acceptate; verifică cerințele pachetului. Ai nevoie de un act electronic acceptat și activ, PIN-ul corect pentru semnare, un cititor USB compatibil și adaptorul necesar. NFC nu este disponibil. Cheia privată rămâne pe card.

Sistemul necesită PC/SC și un driver CCID. Ubuntu: `sudo apt install pcscd libccid`. Fedora: `sudo dnf install pcsc-lite pcsc-lite-ccid`. Activează socketul cu `sudo systemctl enable --now pcscd.socket`. Rulează aplicația în sesiunea grafică; politica de acces prin SSH poate fi diferită.

## 1. Conectează cititorul

Conectează cititorul direct sau prin adaptorul USB potrivit. Detectarea cititorului și citirea certificatului nu cer PIN. O eroare a serviciului PC/SC diferă de un cititor deconectat.

<GuideScreenshot src="/img/guide/linux/ro/connect.png" alt="Conectează cititorul" steps={[{"text": "Deschide Semnează.", "x": 41, "y": 3}, {"text": "Conectează cititorul USB și citește mesajul.", "x": 50, "y": 23}]} />

## 2. Introdu cardul

Introdu actul electronic și așteaptă citirea certificatului. Verifică titularul și expirarea înainte de semnare. Nu reconecta repetat în timpul unei operații.

<GuideScreenshot src="/img/guide/linux/ro/empty.png" alt="Introdu cardul" steps={[{"text": "Introdu cardul și așteaptă titularul și expirarea.", "x": 50, "y": 26}]} />

## 3. Alege identitatea corectă

Dacă sunt mai multe carduri, selectează identitatea dorită în carusel. Ilustrația folosește datele certificatului și un avatar neutru, nu fotografia din act. Folosește reîmprospătarea pentru recitire când este necesar.

<GuideScreenshot src="/img/guide/linux/ro/cards-current.png" alt="Deschide Preferințe din meniul aplicației, apoi Carduri și cititoare." steps={[{"text": "Deschide Preferințe din meniul aplicației, apoi Carduri și cititoare.", "x": 50, "y": 27}, {"text": "Alege cardul dorit din carusel.", "x": 50, "y": 43}, {"text": "Derulează pentru a vedea certificatul și cititorul conectat.", "x": 47, "y": 76}]} />

## 4. Adaugă documentele lotului

Alege sau trage toate documentele în Semnează. Poți selecta mai multe fișiere. Verifică numele și elimină intrările nedorite înainte de autorizare. Tragerea depinde de managerul de fișiere; selectorul rămâne disponibil.

<GuideScreenshot src="/img/guide/linux/ro/sign.png" alt="Adaugă documentele lotului" steps={[{"text": "Deschide Semnează.", "x": 41, "y": 3}, {"text": "Alege fișierele sau trage-le în zona punctată.", "x": 50, "y": 76}, {"text": "Elimină un fișier nedorit din meniul rândului.", "x": 73, "y": 49}, {"text": "Alege Semnează după verificarea întregului lot.", "x": 91, "y": 95}]} />

## 5. Alege formatul semnăturii

Semnătura PDF este PAdES-T și rămâne în PDF. Semnătura XML este XAdES-BES; XML cu marcă temporală este XAdES-T; XML cu date de validare este XAdES-C. Formatele cu marcă temporală/date de stare necesită serviciile de rețea corespunzătoare. Păstrează XML-ul detașat cu originalul nemodificat.

<GuideScreenshot src="/img/guide/linux/ro/format.png" alt="Alege formatul semnăturii" steps={[{"text": "Deschide meniul cu trei puncte.", "x": 70, "y": 49}, {"text": "Alege formatul cerut de destinatar.", "x": 70, "y": 66}, {"text": "Elimină un fișier nedorit din același meniu.", "x": 73, "y": 87}]} />

## 6. Plasează o ștampilă PDF opțională

Deschide meniul fișierului și alege Adaugă ștampilă. Ștampila vizibilă este opțională și nu înlocuiește semnătura criptografică. Nu acoperi conținutul important. PDF-ul exemplu este marcat explicit ca nesemnat.

<GuideScreenshot src="/img/guide/linux/ro/stamp.png" alt="Plasează o ștampilă PDF opțională" steps={[{"text": "Activează ștampila și alege paginile.", "x": 79, "y": 23}, {"text": "Trage/redimensionează ștampila în previzualizare.", "x": 22, "y": 53}, {"text": "Aplică plasarea sau anulează modificarea.", "x": 80, "y": 83}]} />

## 7. Verifică și autorizează lotul

Folosește PIN-ul de semnare al cardului selectat, nu parola Linux. Verifică titularul și întregul lot. Un lot nou cere altă aprobare. Oprește-te după un PIN incorect și confirmă-l; încercările repetate pot bloca cardul. Dialogul de exemplu nu accesează seiful real și dezactivează memorarea.

<GuideScreenshot src="/img/guide/linux/ro/pin.png" alt="Verifică și autorizează lotul" steps={[{"text": "Verifică titularul și numele documentelor.", "x": 50, "y": 36}, {"text": "Introdu PIN-ul în câmpul protejat.", "x": 50, "y": 48}, {"text": "Alege Semnează; anulează o cerere neașteptată.", "x": 59, "y": 64}]} />

## 8. Așteaptă semnarea și marca temporală

Lasă cititorul conectat până la rezultat. Marca temporală necesită rețea. Eroarea de rețea diferă de PIN incorect; citește mesajul înaintea altei cereri deliberate.

<GuideScreenshot src="/img/guide/linux/ro/progress.png" alt="Așteaptă semnarea și marca temporală" steps={[{"text": "Așteaptă etapele curente și rezultatul final.", "x": 50, "y": 90}]} />

## 9. Găsește fișierul rezultat

Aplicația creează un rezultat separat, păstrând intrarea. Folosește rândul finalizat pentru deschidere/localizare. Păstrează originalul cu XML-ul detașat.

<GuideScreenshot src="/img/guide/linux/ro/success.png" alt="Găsește fișierul rezultat" steps={[{"text": "Deschide fișierul direct din rândul său.", "x": 72, "y": 52}, {"text": "Folosește butonul cu dosar pentru a localiza fișierul salvat.", "x": 80, "y": 52}]} />

## 10. Rezolvă eroarea unui document

Un lot poate conține rezultate și erori. Păstrează rezultatele finalizate, citește eroarea și corectează cauza înaintea unei noi cereri. PIN-ul nu este reîncercat automat, iar un fișier defect nu este reparat automat.

<GuideScreenshot src="/img/guide/linux/ro/failure.png" alt="Rezolvă eroarea unui document" steps={[{"text": "Citește eroarea fișierului înaintea altei cereri.", "x": 36, "y": 50}]} />

## 11. Verifică un PDF

Verificarea nu cere card sau PIN. Deschide Verifică și alege/trage PDF-ul sau XML-ul semnat. Sunt acceptate selecții multiple. Citește fiecare semnătură; numele și ștampila nu sunt dovezi. Verificarea offline nu stabilește revocarea curentă a certificatului.

<GuideScreenshot src="/img/guide/linux/ro/verify.png" alt="Verifică un PDF" steps={[{"text": "Deschide Verifică și alege fișierul semnat.", "x": 50, "y": 4}, {"text": "Citește verdictul și numărul semnăturilor.", "x": 50, "y": 28}, {"text": "Inspectează autorul, integritatea și încrederea.", "x": 27, "y": 47}]} />

## 12. Inspectează certificatul și detaliile tehnice

Derulează rezultatul și extinde Detalii certificat și Detalii tehnice. Integritatea, semnătura criptografică, încrederea și marca temporală sunt verificări distincte. Datele organizației emitente nu sunt identificatorul personal al semnatarului.

<GuideScreenshot src="/img/guide/linux/ro/certificate.png" alt="Inspectează certificatul și detaliile tehnice" steps={[{"text": "Extinde detaliile tehnice pentru a vedea formatul și identificatorul semnăturii.", "x": 29, "y": 61}, {"text": "Consultă câmpurile semnăturii. Selectează din nou titlul pentru a restrânge detaliile.", "x": 29, "y": 76}]} />

## 13. Recunoaște un document modificat

Un rezultat invalid poate însemna că documentul nu mai corespunde conținutului semnat. Cere expeditorului copia intactă și verific-o. Redenumirea sau o ștampilă nouă nu repară semnătura.

<GuideScreenshot src="/img/guide/linux/ro/invalid.png" alt="Recunoaște un document modificat" steps={[{"text": "Citește verdictul invalid.", "x": 49, "y": 25}, {"text": "Inspectează verificarea nereușită.", "x": 47, "y": 70}]} />

## 14. Deosebește încrederea neconfirmată

Un lanț necunoscut/neconfirmat diferă de modificarea dovedită. Verifică separat integritatea și semnătura și aplică politica destinatarului pentru certificate.

<GuideScreenshot src="/img/guide/linux/ro/untrusted.png" alt="Deosebește încrederea neconfirmată" steps={[{"text": "Citește verdictul neconfirmat.", "x": 48, "y": 25}, {"text": "Inspectează separat lanțul de încredere.", "x": 70, "y": 86}]} />

## 15. Recunoaște un fișier nesemnat

Lipsa unei semnături recunoscute înseamnă că acest fișier nu are o semnătură verificabilă de aplicație. O imagine scanată sau o ștampilă nu o înlocuiește. Cere rezultatul electronic semnat.

<GuideScreenshot src="/img/guide/linux/ro/unsigned.png" alt="Recunoaște un fișier nesemnat" steps={[{"text": "Citește lipsa semnăturii înainte de a trimite fișierul ca semnat.", "x": 49, "y": 25}]} />

## 16. Verifică XML detașat cu originalul

Pentru XAdES detașat, pune originalul exact și nemodificat lângă XML, cu numele referit de semnătură, apoi alege XML-ul din nou în Verifică. Această versiune Linux nu are selector integrat pentru originale: relația este rezolvată din dosarul XML-ului. Lipsa originalului împiedică o concluzie completă asupra integrității.

<GuideScreenshot src="/img/guide/linux/ro/verify.png" alt="Verifică XML detașat cu originalul" steps={[{"text": "Păstrează XML-ul și originalul împreună, apoi verifică XML-ul din nou.", "x": 50, "y": 4}]} />

## 17. Găsește documentele semnate

Documente salvate conține rezultate semnate, criptate și decriptate. Selectează un fișier semnat pentru detaliile semnăturii. Un fișier criptat oferă decriptarea; conținutul criptat nu este trimis la verificarea semnăturii. Fișierele decriptate își păstrează tipul rezultatului și pot fi deschise sau exportate.

Documente conține colecția rezultatelor semnate și un Istoric separat al operațiilor. Intrările trimit la fișiere și nu înlocuiesc o copie de rezervă. Un fișier mutat trebuie selectat din nou la noua locație.

<GuideScreenshot src="/img/guide/linux/ro/documents.png" alt="Găsește documentele semnate" steps={[{"text": "Selectează numele fișierului pentru a-i examina semnăturile.", "x": 28, "y": 30}, {"text": "Deschide fișierul direct din rândul său.", "x": 67, "y": 30}, {"text": "Folosește butonul cu dosar pentru a localiza fișierul salvat.", "x": 76, "y": 30}]} />

## 18. Deschide detaliile semnării

Selectează numele unui fișier salvat pentru a-i verifica conținutul actual în fereastra de detalii. Exemplul folosește un semnatar fictiv și un certificat autosemnat, astfel că lanțul de încredere nu este confirmat. Poți deschide documentul sau dosarul său din partea de jos a ferestrei.

<GuideScreenshot src="/img/guide/linux/ro/details.png" alt="Deschide detaliile semnării" steps={[{"text": "Citește rezultatul verificării și verifică semnatarul.", "x": 37, "y": 34}, {"text": "Deschide documentul sau afișează-l în dosarul său.", "x": 65, "y": 79}]} />

## 19. Golește istoricul păstrând documentele

Treci la Istoric, alege Golește lista și citește confirmarea. Eliminarea istoricului nu șterge fișierele sau colecția separată de documente semnate. Revino apoi la colecție.

<GuideScreenshot src="/img/guide/linux/ro/history.png" alt="Golește istoricul păstrând documentele" steps={[{"text": "Citește Istoric; Documente salvate revine la colecție.", "x": 14, "y": 11}, {"text": "Golește lista și confirmă eliminarea doar a istoricului.", "x": 73, "y": 20}]} />

<GuideScreenshot src="/img/guide/linux/ro/history-confirm.png" alt="Golește istoricul păstrând documentele" start={3} steps={[{"x": 57, "y": 57, "text": "Citește confirmarea pentru istoric, apoi alege Golește lista sau Anulează. Documentele semnate rămân disponibile."}]} />

## 20. Alege limba și aspectul

Deschide Preferințe din meniul aplicației. Modul demonstrativ este sus. Consultă cardurile în Carduri și cititoare și gestionează copiile PIN în PIN-uri salvate.

Deschide meniul aplicației → Preferințe. Alege aspectul Sistem, Deschis sau Întunecat și limba Sistem, Română, English sau Русский. Modificările se aplică interfeței. Capturile folosesc traducerile native.

<GuideScreenshot src="/img/guide/linux/ro/settings-current.png" alt="Alege limba și aspectul" steps={[{"text": "Alege aspectul interfeței.", "x": 68, "y": 17}, {"text": "Alege limba interfeței.", "x": 68, "y": 54}]} />

## 21. Gestionează PIN-urile și accesul site-urilor

PIN-urile sunt păstrate prin Secret Service/seiful sistemului. Dacă semnarea obișnuită oferă memorarea, salvează intenționat și deblochează seiful când se solicită. Dacă acesta este indisponibil/blocat, introdu PIN-ul pentru operația curentă. Ștergerea copiilor salvate nu schimbă și nu deblochează PIN-ul fizic. Activează conexiunea browser numai pentru fluxul dorit.

<GuideScreenshot src="/img/guide/linux/ro/saved-pins.png" alt="Deschide PIN-uri salvate în Preferințe pentru a gestiona copiile stocate pe acest dispozitiv." steps={[{"text": "Deschide PIN-uri salvate în Preferințe pentru a gestiona copiile stocate pe acest dispozitiv.", "x": 51, "y": 38}]} />

## 22. Păstrează aplicația disponibilă în fundal

Derulează în Preferințe la opțiunile de fundal și pornire. Rularea în fundal păstrează conexiunea browser după închiderea ferestrei. Pornirea la autentificare activează detectarea în fundal. Afișarea la introducerea cardului funcționează cât aplicația rulează; nu este un serviciu separat permanent.

<GuideScreenshot src="/img/guide/linux/ro/background.png" alt="Păstrează aplicația disponibilă în fundal" steps={[{"text": "Alege rularea în fundal și pornirea dacă sunt necesare.", "x": 68, "y": 75}, {"text": "Alege dacă introducerea cardului deschide aplicația pornită.", "x": 68, "y": 89}]} />

## 23. Găsește versiunea și actualizează sigur

Deschide meniul aplicației → Despre eSemnBun pentru versiune și site. Folosește verificarea actualizărilor când este disponibilă ori canalul original al pachetului. Instalează un pachet compatibil; verificarea nu înlocuiește aplicația automat. Pentru suport oferă versiunile și cititorul, niciodată PIN-ul.

<GuideScreenshot src="/img/guide/linux/ro/about.png" alt="Găsește versiunea și actualizează sigur" steps={[{"text": "Deschide Despre eSemnBun.", "x": 58, "y": 7}, {"text": "Citește versiunea și site-ul înainte de suport.", "x": 50, "y": 27}]} />

## 24. Deschide ajutorul și comenzile aplicației

Meniul aplicației oferă Preferințe, Despre, Verifică actualizările și Ieșire. Pentru ajutor online deschide [depanarea](/docs/troubleshooting). Închiderea ferestrei poate lăsa aplicația în fundal; alege Ieșire pentru oprire. Pentru automatizare continuă cu ghidul CLI Linux.

<GuideScreenshot src="/img/guide/linux/ro/menu.png" alt="Deschide ajutorul și comenzile aplicației" steps={[{"text": "Deschide meniul aplicației.", "x": 89, "y": 3}, {"text": "Alege Preferințe, Ajutor, actualizare sau Ieșire.", "x": 89, "y": 14}]} />

## 25. Aprobă o cerere locală de semnare MCP

În Preferințe, activează cererile locale de semnare doar dacă intenționezi să folosești un client MCP. Copiază dosarul privat afișat în configurarea helperului. Păstrează aplicația desktop pornită. Fiecare cerere deschide PDF-ul pregătit pentru examinare: verifică documentul, cardul și operația, aprobă explicit, apoi introdu PIN-ul în dialogul nativ. Un PIN salvat nu înlocuiește aprobarea. Anulează cererile neașteptate.

<GuideScreenshot src="/img/guide/linux/ro/settings.png" alt="Aprobă o cerere locală de semnare MCP" steps={[{"x": 68, "y": 84, "text": "Activează cererile locale de semnare în aplicația desktop; fiecare PDF necesită verificare și aprobare."}, {"x": 43, "y": 86, "text": "Copiază dosarul privat afișat de propria instalare în configurarea de pornire MCP."}]} />


## Folosește site-urile în browserul tău

Linux folosește un browser extern; nu include browserul integrat și managerul de marcaje Apple/Android. În Preferințe activează conexiunea și deschide serviciul acceptat pe același calculator. Păstrează aplicația pornită. Verifică adresa solicitantului, documentele, cardul și operația în dialogul de consimțământ/PIN. Ștampilele pentru site-uri sunt opționale. Permite accesul MoldSign Desktop numai pentru clientul dorit. Identitatea HTTPS inclusă este folosită automat; Import înlocuiește deliberat identitatea. Nu ignora avertismentele certificatului browserului. Dacă altă aplicație ocupă porturile, finalizează operația ei și rezolvă conflictul. Marcajele, cookie-urile și istoricul de navigare aparțin browserului extern. Consimțământul site-ului, citirea seifului și finalizarea pe portal nu sunt demonstrate de capturile izolate.

## Rezolvă problemele în siguranță

Fără cititor: verifică PC/SC, CCID, cablul și adaptorul. Cititor gol: introdu cardul și așteaptă. Titular greșit: alege cardul înainte de PIN. PIN incorect/blocat: oprește-te și contactează furnizorul când este necesar; aplicația nu îl poate debloca. Fișier indisponibil: selectează fișierul curent. Original lipsă: restabilește originalul nemodificat lângă XML. Pentru suport folosește exemple fictive și nu trimite PIN, documente confidențiale sau datele complete ale actului.

<!-- file-protection-guides -->


## Criptează un fișier cu parolă

Deschide meniul principal din antetul ferestrei, apoi **Protejează fișiere → Criptează**, **Decriptează** sau **Elimină fișierul**. Alege un fișier accesibil; derulează formularul la nevoie.

Nu ai nevoie de card. Creează o parolă pentru fișier și transmite-o destinatarului printr-un canal de încredere separat. Nu este PIN-ul cardului. Criptarea creează un rezultat separat; păstrează originalul până verifici rezultatul.

Alege **Parolă** și selectează AES-128, AES-192 sau AES-256. Opțiunea implicită este AES-256. Pentru a cripta pentru un destinatar, alege **Certificat RSA** și selectează certificatul său public de criptare (.cer sau .der). Certificatul de semnare al cărții de identitate moldovenești nu poate decripta aceste fișiere.

<GuideScreenshot src="/img/guide/linux/ro/protect-password-light.png" alt="Criptează un fișier cu parolă" steps={[{"text": "Alege fișierul de criptat.", "x": 50, "y": 29}, {"text": "Selectează AES-128, AES-192 sau AES-256. Opțiunea implicită este AES-256.", "x": 45, "y": 56}, {"text": "Introdu și confirmă o parolă nouă pentru fișier.", "x": 31, "y": 68}, {"text": "Alege Criptează, apoi salvează copia criptată.", "x": 50, "y": 91}]} />

<GuideScreenshot src="/img/guide/linux/ro/protect-certificate-light.png" alt="Criptează pentru un destinatar RSA" steps={[{"text": "Alege Certificat RSA.", "x": 44, "y": 46}, {"text": "Alege certificatul public de criptare al destinatarului.", "x": 50, "y": 58}, {"text": "Pentru a cripta pentru propriul card, conectează cititorul și citește certificatul său de criptare.", "x": 50, "y": 65}]} />

Alege **Criptează** sau **Decriptează**, apoi **Salvează o copie** și alege un loc nou pentru rezultat. După salvare, fișierul apare în **Documente → Documente salvate**. Folosește butonul de închidere din antetul ferestrei la final. Originalul este păstrat.

Documente salvate include fișiere semnate, criptate și decriptate. Identifică rezultatul după numele fișierului și eticheta operațiunii. Criptarea nu creează o semnătură digitală; fișierele criptate trebuie decriptate înainte de deschiderea sau verificarea conținutului.


## Decriptează un fișier primit

Deschide meniul principal din antetul ferestrei, apoi **Protejează fișiere → Criptează**, **Decriptează** sau **Elimină fișierul**. Alege un fișier accesibil; derulează formularul la nevoie.

Pentru un fișier criptat cu parolă, cere parola expeditorului printr-un canal de încredere separat. Fișierul specifică dimensiunea cheii AES. Pentru fișierele RSA, conectează cardul care conține cheia de criptare a destinatarului, citește cardul și autorizează decriptarea cu PIN-ul său.

<GuideScreenshot src="/img/guide/linux/ro/protect-decrypt-light.png" alt="Decriptează un fișier primit" steps={[{"text": "Alege fișierul criptat. Conținutul său determină metoda de decriptare.", "x": 50, "y": 29}, {"text": "Pentru un fișier criptat cu parolă, introdu parola primită de la expeditor.", "x": 30, "y": 61}, {"text": "Alege Decriptează și salvează rezultatul într-un fișier nou.", "x": 50, "y": 91}]} />

Deschide și verifică rezultatul salvat înainte de utilizare. Criptarea compatibilă MoldSign nu autentifică conținutul: decriptarea reușită nu dovedește singură integritatea sau parola corectă.

Alege **Criptează** sau **Decriptează**, apoi **Salvează o copie** și alege un loc nou pentru rezultat. După salvare, fișierul apare în **Documente → Documente salvate**. Folosește butonul de închidere din antetul ferestrei la final. Originalul este păstrat.

Documente salvate include fișiere semnate, criptate și decriptate. Identifică rezultatul după numele fișierului și eticheta operațiunii. Criptarea nu creează o semnătură digitală; fișierele criptate trebuie decriptate înainte de deschiderea sau verificarea conținutului.


## Elimină un fișier local

Deschide meniul principal din antetul ferestrei, apoi **Protejează fișiere → Criptează**, **Decriptează** sau **Elimină fișierul**. Alege un fișier accesibil; derulează formularul la nevoie.

Doar pe desktop. Operațiunea elimină definitiv un fișier local obișnuit acceptat, după confirmare. Nu garantează ștergerea de pe SSD, din instantanee, copii de rezervă sau alte copii. Locațiile neacceptate și legăturile sunt refuzate. Furnizorii de documente mobili nu acceptă operațiunea.

<GuideScreenshot src="/img/guide/linux/ro/protect-remove-light.png" alt="Elimină un fișier local" steps={[{"text": "Alege fișierul și citește numele acestuia și avertismentul de ștergere.", "x": 50, "y": 29}, {"text": "Confirmă ștergerea doar după ce ai verificat fișierul selectat.", "x": 36, "y": 85}, {"text": "Alege Elimină fișierul pentru a finaliza operația.", "x": 50, "y": 91}]} />
