---
title: "Linux — ghid desktop ilustrat"
sidebar_position: 7
---

import GuideScreenshot from '@site/src/components/GuideScreenshot';

# Linux — ghid desktop ilustrat

Urmează capturile numerotate pentru eSemnBun 0.2.6 pe Linux. Imaginile arată interfața GTK nativă, cu persoane fictive și documente de exemplu. Cercurile numerotate sunt adăugate în ghid; bannerul demo este ascuns numai în capturile izolate pentru documentație. Un rezultat de previzualizare nu dovedește o semnătură reală. Atinge imaginea pentru mărire și alege Mărime originală pentru detalii.

Instalează pachetul desktop pentru distribuția și arhitectura ta din [Descărcări](/downloads/), apoi deschide eSemnBun din meniul de aplicații. Pachetele desktop DEB/RPM/Flatpak deschid aplicația grafică; depozitele și arhivele CLI instalează instrumentele de terminal. Consultă [ghidul CLI Linux](./linux-cli.md) pentru terminal și MCP. Ubuntu 24.04/Fedora sunt platforme desktop acceptate; verifică cerințele pachetului. Ai nevoie de un act electronic acceptat și activ, PIN-ul corect pentru semnare, un cititor USB compatibil și adaptorul necesar. NFC nu este disponibil. Cheia privată rămâne pe card.

Sistemul necesită PC/SC și un driver CCID. Ubuntu: `sudo apt install pcscd libccid`. Fedora: `sudo dnf install pcsc-lite pcsc-lite-ccid`. Activează socketul cu `sudo systemctl enable --now pcscd.socket`. Rulează aplicația în sesiunea grafică; politica de acces prin SSH poate fi diferită.

## 1. Conectează cititorul

Conectează cititorul direct sau prin adaptorul USB potrivit. Detectarea cititorului și citirea certificatului nu cer PIN. O eroare a serviciului PC/SC diferă de un cititor deconectat.

<GuideScreenshot src="/img/guide/linux/ro/connect.png" alt="Conectează cititorul" steps={[{"text": "Deschide Semnează.", "x": 32, "y": 3}, {"text": "Conectează cititorul USB și citește mesajul.", "x": 50, "y": 28}]} />

## 2. Introdu cardul

Introdu actul electronic și așteaptă citirea certificatului. Verifică titularul și expirarea înainte de semnare. Nu reconecta repetat în timpul unei operații.

<GuideScreenshot src="/img/guide/linux/ro/empty.png" alt="Introdu cardul" steps={[{"text": "Introdu cardul și așteaptă titularul și expirarea.", "x": 50, "y": 28}]} />

## 3. Alege identitatea corectă

Dacă sunt mai multe carduri, selectează identitatea dorită în carusel. Ilustrația folosește datele certificatului și un avatar neutru, nu fotografia din act. Folosește reîmprospătarea pentru recitire când este necesar.

<GuideScreenshot src="/img/guide/linux/ro/cards.png" alt="Alege identitatea corectă" steps={[{"text": "Deschide Card.", "x": 68, "y": 3}, {"text": "Alege punctul cardului dorit sau derulează caruselul.", "x": 50, "y": 37}, {"text": "Inspectează certificatul public și cititorul.", "x": 57, "y": 65}]} />

## 4. Adaugă documentele lotului

Alege sau trage toate documentele în Semnează. Poți selecta mai multe fișiere. Verifică numele și elimină intrările nedorite înainte de autorizare. Tragerea depinde de managerul de fișiere; selectorul rămâne disponibil.

<GuideScreenshot src="/img/guide/linux/ro/sign.png" alt="Adaugă documentele lotului" steps={[{"text": "Deschide Semnează.", "x": 32, "y": 3}, {"text": "Alege fișierele sau trage-le în zona punctată.", "x": 48, "y": 77}, {"text": "Elimină un fișier nedorit din meniul rândului.", "x": 73, "y": 49}, {"text": "Alege Semnează după verificarea întregului lot.", "x": 91, "y": 95}]} />

## 5. Alege formatul semnăturii

Semnătura PDF este PAdES-T și rămâne în PDF. Semnătura XML este XAdES-BES; XML cu marcă temporală este XAdES-T; XML cu date de validare este XAdES-C. Formatele cu marcă temporală/date de stare necesită serviciile de rețea corespunzătoare. Păstrează XML-ul detașat cu originalul nemodificat.

<GuideScreenshot src="/img/guide/linux/ro/format.png" alt="Alege formatul semnăturii" steps={[{"text": "Deschide meniul cu trei puncte.", "x": 74, "y": 49}, {"text": "Alege formatul cerut de destinatar.", "x": 72, "y": 67}, {"text": "Elimină un fișier nedorit din același meniu.", "x": 73, "y": 87}]} />

## 6. Plasează o ștampilă PDF opțională

Deschide meniul fișierului și alege Adaugă ștampilă. Ștampila vizibilă este opțională și nu înlocuiește semnătura criptografică. Nu acoperi conținutul important. PDF-ul exemplu este marcat explicit ca nesemnat.

<GuideScreenshot src="/img/guide/linux/ro/stamp.png" alt="Plasează o ștampilă PDF opțională" steps={[{"text": "Activează ștampila și alege paginile.", "x": 79, "y": 23}, {"text": "Trage/redimensionează ștampila în previzualizare.", "x": 22, "y": 53}, {"text": "Aplică plasarea sau anulează modificarea.", "x": 80, "y": 83}]} />

## 7. Verifică și autorizează lotul

Folosește PIN-ul de semnare al cardului selectat, nu parola Linux. Verifică titularul și întregul lot. Un lot nou cere altă aprobare. Oprește-te după un PIN incorect și confirmă-l; încercările repetate pot bloca cardul. Dialogul de exemplu nu accesează seiful real și dezactivează memorarea.

<GuideScreenshot src="/img/guide/linux/ro/pin.png" alt="Verifică și autorizează lotul" steps={[{"text": "Verifică titularul și numele documentelor.", "x": 50, "y": 40}, {"text": "Introdu PIN-ul în câmpul protejat.", "x": 50, "y": 54}, {"text": "Alege Semnează; anulează o cerere neașteptată.", "x": 61, "y": 66}]} />

## 8. Așteaptă semnarea și marca temporală

Lasă cititorul conectat până la rezultat. Marca temporală necesită rețea. Eroarea de rețea diferă de PIN incorect; citește mesajul înaintea altei cereri deliberate.

<GuideScreenshot src="/img/guide/linux/ro/progress.png" alt="Așteaptă semnarea și marca temporală" steps={[{"text": "Așteaptă etapele curente și rezultatul final.", "x": 57, "y": 86}]} />

## 9. Găsește fișierul rezultat

Aplicația creează un rezultat separat, păstrând intrarea. Folosește rândul finalizat pentru deschidere/localizare. Păstrează originalul cu XML-ul detașat. Finalizarea ilustrată folosește un exemplu fictiv nesemnat.

<GuideScreenshot src="/img/guide/linux/ro/success.png" alt="Găsește fișierul rezultat" steps={[{"text": "Activează rezultatul finalizat pentru localizare/deschidere.", "x": 70, "y": 48}]} />

## 10. Rezolvă eroarea unui document

Un lot poate conține rezultate și erori. Păstrează rezultatele finalizate, citește eroarea și corectează cauza înaintea unei noi cereri. PIN-ul nu este reîncercat automat, iar un fișier defect nu este reparat automat.

<GuideScreenshot src="/img/guide/linux/ro/failure.png" alt="Rezolvă eroarea unui document" steps={[{"text": "Citește eroarea fișierului înaintea altei cereri.", "x": 45, "y": 55}]} />

## 11. Verifică un PDF

Verificarea nu cere card sau PIN. Deschide Verifică și alege/trage PDF-ul sau XML-ul semnat. Sunt acceptate selecții multiple. Citește fiecare semnătură; numele și ștampila nu sunt dovezi. Verificarea offline nu stabilește revocarea curentă a certificatului.

<GuideScreenshot src="/img/guide/linux/ro/verify.png" alt="Verifică un PDF" steps={[{"text": "Deschide Verifică și alege fișierul semnat.", "x": 44, "y": 3}, {"text": "Citește verdictul și numărul semnăturilor.", "x": 50, "y": 25}, {"text": "Inspectează autorul, integritatea și încrederea.", "x": 50, "y": 71}]} />

## 12. Inspectează certificatul și detaliile tehnice

Derulează rezultatul și extinde Detalii certificat și Detalii tehnice. Integritatea, semnătura criptografică, încrederea și marca temporală sunt verificări distincte. Datele organizației emitente nu sunt identificatorul personal al semnatarului.

<GuideScreenshot src="/img/guide/linux/ro/certificate.png" alt="Inspectează certificatul și detaliile tehnice" steps={[{"text": "Extinde detaliile certificatului și verifică subiectul/emitentul/cheia.", "x": 75, "y": 41}, {"text": "Extinde detaliile tehnice pentru format și identificator.", "x": 75, "y": 91}]} />

## 13. Recunoaște un document modificat

Un rezultat invalid poate însemna că documentul nu mai corespunde conținutului semnat. Cere expeditorului copia intactă și verific-o. Redenumirea sau o ștampilă nouă nu repară semnătura.

<GuideScreenshot src="/img/guide/linux/ro/invalid.png" alt="Recunoaște un document modificat" steps={[{"text": "Citește verdictul invalid.", "x": 49, "y": 25}, {"text": "Inspectează verificarea nereușită.", "x": 47, "y": 70}]} />

## 14. Deosebește încrederea neconfirmată

Un lanț necunoscut/neconfirmat diferă de modificarea dovedită. Verifică separat integritatea și semnătura și aplică politica destinatarului pentru certificate.

<GuideScreenshot src="/img/guide/linux/ro/untrusted.png" alt="Deosebește încrederea neconfirmată" steps={[{"text": "Citește verdictul neconfirmat.", "x": 48, "y": 25}, {"text": "Inspectează separat lanțul de încredere.", "x": 70, "y": 86}]} />

## 15. Recunoaște un fișier nesemnat

Lipsa unei semnături recunoscute înseamnă că acest fișier nu are o semnătură verificabilă de aplicație. O imagine scanată sau o ștampilă nu o înlocuiește. Cere rezultatul electronic semnat.

<GuideScreenshot src="/img/guide/linux/ro/unsigned.png" alt="Recunoaște un fișier nesemnat" steps={[{"text": "Citește lipsa semnăturii înainte de a trimite fișierul ca semnat.", "x": 50, "y": 26}]} />

## 16. Verifică XML detașat cu originalul

Pentru XAdES detașat, pune originalul exact și nemodificat lângă XML, cu numele referit de semnătură, apoi alege XML-ul din nou în Verifică. Această versiune Linux nu are selector integrat pentru originale: relația este rezolvată din dosarul XML-ului. Lipsa originalului împiedică o concluzie completă asupra integrității.

<GuideScreenshot src="/img/guide/linux/ro/format.png" alt="Verifică XML detașat cu originalul" steps={[{"text": "Păstrează XML-ul și originalul împreună, apoi verifică XML-ul din nou.", "x": 73, "y": 67}]} />

## 17. Găsește documentele semnate

Documente conține colecția rezultatelor semnate și un Istoric separat al operațiilor. Intrările trimit la fișiere și nu înlocuiesc o copie de rezervă. Un fișier mutat trebuie selectat din nou la noua locație.

<GuideScreenshot src="/img/guide/linux/ro/documents.png" alt="Găsește documentele semnate" steps={[{"text": "Deschide Documente.", "x": 55, "y": 3}, {"text": "Alege rândul documentului salvat.", "x": 42, "y": 26}, {"text": "Folosește detaliile sau pictograma dosarului.", "x": 36, "y": 37}]} />

## 18. Deschide detaliile semnării

Apasă rândul sau Detalii semnare pentru fereastra modală. Aceasta verifică fișierul curent fără să înlocuiască spațiul Verifică ori să adauge o operație în istoric. Exemplul chiar este nesemnat, astfel că mesajul de lipsă a semnăturii este corect. Închide fereastra pentru listă; pictograma dosarului localizează fișierul.

<GuideScreenshot src="/img/guide/linux/ro/details.png" alt="Deschide detaliile semnării" steps={[{"text": "Citește rezultatul nou în fereastra de detalii.", "x": 50, "y": 27}, {"text": "Închide fereastra pentru a reveni la listă.", "x": 73, "y": 12}]} />

## 19. Golește istoricul păstrând documentele

Treci la Istoric, alege Golește lista și citește confirmarea. Eliminarea istoricului nu șterge fișierele sau colecția separată de documente semnate. Revino apoi la colecție.

<GuideScreenshot src="/img/guide/linux/ro/history.png" alt="Golește istoricul păstrând documentele" steps={[{"text": "Citește Istoric; Documente semnate revine la colecție.", "x": 17, "y": 10}, {"text": "Golește lista și confirmă eliminarea doar a istoricului.", "x": 79, "y": 20}]} />

<GuideScreenshot src="/img/guide/linux/ro/history-confirm.png" alt="Golește istoricul păstrând documentele" start={3} steps={[{"x": 57, "y": 57, "text": "Citește confirmarea pentru istoric, apoi alege Golește lista sau Anulează. Documentele semnate rămân disponibile."}]} />

## 20. Alege limba și aspectul

Deschide meniul aplicației → Preferințe. Alege aspectul Sistem, Deschis sau Întunecat și limba Sistem, Română, English sau Русский. Modificările se aplică interfeței. Capturile folosesc traducerile native.

<GuideScreenshot src="/img/guide/linux/ro/settings.png" alt="Alege limba și aspectul" steps={[{"text": "Alege aspectul interfeței.", "x": 69, "y": 41}, {"text": "Alege limba interfeței.", "x": 69, "y": 48}]} />

## 21. Gestionează PIN-urile și accesul site-urilor

PIN-urile sunt păstrate prin Secret Service/seiful sistemului. Dacă semnarea obișnuită oferă memorarea, salvează intenționat și deblochează seiful când se solicită. Dacă acesta este indisponibil/blocat, introdu PIN-ul pentru operația curentă. Ștergerea copiilor salvate nu schimbă și nu deblochează PIN-ul fizic. Activează conexiunea browser numai pentru fluxul dorit.

<GuideScreenshot src="/img/guide/linux/ro/settings.png" alt="Gestionează PIN-urile și accesul site-urilor" steps={[{"text": "Șterge copiile PIN numai dacă vrei să le introduci din nou.", "x": 68, "y": 65}, {"text": "Activează conexiunea numai pentru serviciul dorit.", "x": 69, "y": 85}]} />

## 22. Păstrează aplicația disponibilă în fundal

Derulează în Preferințe la opțiunile de fundal și pornire. Rularea în fundal păstrează conexiunea browser după închiderea ferestrei. Pornirea la autentificare activează detectarea în fundal. Afișarea la introducerea cardului funcționează cât aplicația rulează; nu este un serviciu separat permanent.

<GuideScreenshot src="/img/guide/linux/ro/background.png" alt="Păstrează aplicația disponibilă în fundal" steps={[{"text": "Alege rularea în fundal și pornirea dacă sunt necesare.", "x": 70, "y": 75}, {"text": "Alege dacă introducerea cardului deschide aplicația pornită.", "x": 70, "y": 90}]} />

## 23. Găsește versiunea și actualizează sigur

Deschide Preferințe → Despre eSemnBun pentru versiune și site. Folosește verificarea actualizărilor când este disponibilă ori canalul original al pachetului. Instalează un pachet compatibil; verificarea nu înlocuiește aplicația automat. Pentru suport oferă versiunile și cititorul, niciodată PIN-ul.

<GuideScreenshot src="/img/guide/linux/ro/about.png" alt="Găsește versiunea și actualizează sigur" steps={[{"text": "Deschide Despre eSemnBun.", "x": 58, "y": 7}, {"text": "Citește versiunea și site-ul înainte de suport.", "x": 50, "y": 27}]} />

## 24. Deschide ajutorul și comenzile aplicației

Meniul aplicației oferă Preferințe, Despre, Verifică actualizările și Ieșire. Pentru ajutor online deschide [depanarea](/docs/troubleshooting). Închiderea ferestrei poate lăsa aplicația în fundal; alege Ieșire pentru oprire. Pentru automatizare continuă cu ghidul CLI Linux.

<GuideScreenshot src="/img/guide/linux/ro/menu.png" alt="Deschide ajutorul și comenzile aplicației" steps={[{"text": "Deschide meniul aplicației."}, {"text": "Alege Preferințe, Ajutor, actualizare sau Ieșire.", "x": 87, "y": 35}]} />


## 25. Aprobă o cerere locală de semnare MCP

În Preferințe, activează cererile locale de semnare doar dacă intenționezi să folosești un client MCP. Copiază dosarul privat afișat în configurarea helperului. Păstrează aplicația desktop pornită. Fiecare cerere deschide PDF-ul pregătit pentru examinare: verifică documentul, cardul și operația, aprobă explicit, apoi introdu PIN-ul în dialogul nativ. Un PIN salvat nu înlocuiește aprobarea. Anulează cererile neașteptate.

<GuideScreenshot src="/img/guide/linux/ro/settings.png" alt="Aprobă o cerere locală de semnare MCP" caption="Captură nativă a preferințelor cu date fictive. Opțiunea este dezactivată în această sesiune izolată; nu s-a efectuat aprobarea MCP sau semnarea reală cu un card." steps={[{"x": 71, "y": 26, "text": "Activează cererile locale de semnare în aplicația desktop; fiecare PDF necesită verificare și aprobare."}, {"x": 50, "y": 27.4, "text": "Copiază dosarul privat afișat de propria instalare în configurarea de pornire MCP."}]} />


## Folosește site-urile în browserul tău

Linux folosește un browser extern; nu include browserul integrat și managerul de marcaje Apple/Android. În Preferințe activează conexiunea și deschide serviciul acceptat pe același calculator. Păstrează aplicația pornită. Verifică adresa solicitantului, documentele, cardul și operația în dialogul de consimțământ/PIN. Ștampilele pentru site-uri sunt opționale. Permite accesul MoldSign Desktop numai pentru clientul dorit. Identitatea HTTPS inclusă este folosită automat; Import înlocuiește deliberat identitatea. Nu ignora avertismentele certificatului browserului. Dacă altă aplicație ocupă porturile, finalizează operația ei și rezolvă conflictul. Marcajele, cookie-urile și istoricul de navigare aparțin browserului extern. Consimțământul site-ului, citirea seifului și finalizarea pe portal nu sunt demonstrate de capturile izolate.

## Rezolvă problemele în siguranță

Fără cititor: verifică PC/SC, CCID, cablul și adaptorul. Cititor gol: introdu cardul și așteaptă. Titular greșit: alege cardul înainte de PIN. PIN incorect/blocat: oprește-te și contactează furnizorul când este necesar; aplicația nu îl poate debloca. Fișier indisponibil: selectează fișierul curent. Original lipsă: restabilește originalul nemodificat lângă XML. Pentru suport folosește exemple fictive și nu trimite PIN, documente confidențiale sau datele complete ale actului.
