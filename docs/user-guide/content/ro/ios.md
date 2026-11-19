---
title: iPhone
---

import GuideScreenshot from '@site/src/components/GuideScreenshot';

# iPhone

Începând cu eSemnBun 0.2.12, poți semna prin NFC de pe un iPhone sau dispozitiv Android compatibil, cu un card fără contact compatibil. Poți folosi și un cititor USB compatibil. Ai nevoie de o carte de identitate electronică moldovenească activă, cu certificat de semnare valabil și PIN-ul de semnare. Instalează sau actualizează aplicația prin canalul dispozitivului din [Descărcări](/downloads).

Pentru USB, conectează cititorul cu [adaptorul](/devices) potrivit. Dispozitivele cu Lightning pot necesita un adaptor Lightning alimentat.

## Conectează cititorul și introdu cardul

Ai nevoie de o carte de identitate electronică moldovenească activă, cu certificat de semnare valabil și PIN-ul de semnare.

### Semnează prin NFC

Începând cu eSemnBun 0.2.12, poți semna prin NFC de pe un iPhone sau dispozitiv Android compatibil, cu un card fără contact compatibil. Poți folosi și un cititor USB compatibil. Alege **Cu telefonul · NFC** în **Semnează** și adaugă documentul. Apasă **Continuă**, verifică cererea și confirmă PIN-ul de semnare. Ține cardul lângă antena NFC a telefonului până când aplicația confirmă finalizarea.

<GuideScreenshot src="/img/guide/iphone/ro/nfc-sign.png" alt="Ecranul Semnează cu opțiunea NFC selectată" steps={[{"text": "Ecranul Semnează cu opțiunea NFC selectată", "x": 36, "y": 56}]} />

### Semnează cu un cititor USB

Pentru USB, conectează cititorul prin [adaptorul](/devices) potrivit, alege **Cu un cititor de carduri** în **Semnează** și introdu cardul. Dacă sunt mai multe carduri conectate, selectează titularul dorit înainte de a continua.

<GuideScreenshot src="/img/guide/iphone/ro/reader-sign.png" alt="Ecranul Semnează cu cititorul de carduri USB selectat" steps={[{"text": "Ecranul Semnează cu cititorul de carduri USB selectat", "x": 38, "y": 59}]} />

## Alege identitatea care va semna

Deschide **Setări → Carduri și cititoare** pentru a consulta un card conectat. În ecranul Semnează, butonul de informații din dreapta sus deschide detaliile cardului. Gestionează PIN-urile în **Setări → Carduri și PIN-uri salvate**. Cardul și PIN-ul memorate sunt comune pentru NFC și USB.

<GuideScreenshot src="/img/guide/iphone/ro/cards-current.png" alt="Consultă identitatea selectată înainte de semnare." steps={[{"text": "Consultă identitatea selectată înainte de semnare.", "x": 29, "y": 34}]} />

<GuideScreenshot src="/img/guide/iphone/ro/batch-current.png" alt="Verifică documentul ales înainte de a apăsa Continuă." steps={[{"text": "Verifică documentul ales înainte de a apăsa Continuă.", "x": 37, "y": 28}]} />

## Adaugă documente și alege formatul semnăturii

### Alege cum semnezi

Alege **Cu telefonul · NFC** în **Semnează** și adaugă documentul. Apasă **Continuă**, verifică cererea și confirmă PIN-ul de semnare. Ține cardul lângă antena NFC a telefonului până când aplicația confirmă finalizarea.

Pentru USB, conectează cititorul prin [adaptorul](/devices) potrivit, alege **Cu un cititor de carduri** în **Semnează** și introdu cardul. Dacă sunt mai multe carduri conectate, selectează titularul dorit înainte de a continua. Cu un cititor USB, lasă cititorul conectat și cardul introdus până se finalizează semnarea și aplicarea mărcii temporale.

Deschide Semnează și alege fișiere din Fișiere sau dintr-un furnizor cloud. Descarcă întâi documentele disponibile doar în cloud dacă accesul eșuează. Poți trimite fișiere și din meniul de partajare al altei aplicații către extensia eSemnBun. Extinde lista, verifică numele, elimină fișierele nedorite din opțiunile lor și alege formatul cerut. PDF-urile folosesc PAdES-T; celelalte fișiere folosesc XAdES. XML-ul detașat trebuie păstrat împreună cu originalul nemodificat. XAdES-BES nu are marcă temporală, T o adaugă, iar C include referințe la certificate și stare. XML-ul încorporat include conținutul original. Formatele cu marcă temporală necesită serviciile publice de încredere.

<GuideScreenshot src="/img/guide/iphone/ro/sign.png" alt="Confirmă titularul selectat înainte de semnare." steps={[{"text": "Confirmă titularul selectat înainte de semnare.", "x": 45, "y": 28}, {"text": "Alege fișiere sau adaugă alte documente în listă.", "x": 50, "y": 69}, {"text": "Extinde lista și deschide opțiunile unui fișier pentru format, ștampilă sau eliminare.", "x": 78, "y": 53}, {"text": "Verifică întreaga listă, apoi apasă butonul flotant Semnează din partea de jos.", "x": 68, "y": 85.5}]} />

## Plasează o ștampilă vizibilă într-un PDF

Deschide opțiunile unui PDF și alege Adaugă/Editează ștampila. Ștampila vizibilă este opțională; dovada semnării rămâne semnătura criptografică. Evită acoperirea textului existent.

Textul ștampilei urmează limba aleasă în aplicație (română, engleză sau rusă).

<GuideScreenshot src="/img/guide/iphone/ro/stamp.png" alt="Trage ștampila pentru mutare și colțurile pentru redimensionare." steps={[{"text": "Trage ștampila pentru mutare și colțurile pentru redimensionare.", "x": 30, "y": 61}, {"text": "Alege pagina și modul Oprit, O pagină sau Toate paginile.", "x": 25, "y": 86}, {"text": "Opțional, aplică poziția tuturor PDF-urilor din listă, apoi apasă Aplică.", "x": 87, "y": 12}]} />

## Verifică cererea și autorizează semnarea

Pentru o cerere de pe un site, verifică originea și întreaga listă de documente înainte de acceptare. Anulează cererile neașteptate. Pentru un lot local, verifică lista și fereastra PIN. Fiecare lot nou necesită aprobare; sesiunea acoperă doar documentele afișate și cardul ales.

<GuideScreenshot src="/img/guide/iphone/ro/consent.png" alt="Verifică site-ul solicitant și operația dorită." steps={[{"text": "Verifică site-ul solicitant și operația dorită.", "x": 16, "y": 52}, {"text": "Verifică toate documentele; acceptă numai o cerere inițiată de tine.", "x": 86, "y": 91}]} />
<GuideScreenshot src="/img/guide/iphone/ro/pin.png" alt="Verifică titularul și numele fișierelor selectate." steps={[{"text": "Verifică titularul și numele fișierelor selectate.", "x": 49, "y": 23}, {"text": "Introdu PIN-ul QSCD corect în câmpul protejat.", "x": 8, "y": 34}, {"text": "Activează memorarea PIN-ului doar pe un dispozitiv personal de încredere; accesul ulterior cere autentificarea oferită de dispozitiv.", "x": 86, "y": 40}, {"text": "Apasă Semnează pentru autorizare sau Anulează pentru oprire.", "x": 88, "y": 63}]} />

## Așteaptă finalizarea și salvează rezultatul semnat

Pentru NFC, ține cardul lângă telefon până se încheie scanarea. Pentru USB, lasă cititorul conectat și cardul introdus până se finalizează semnarea și aplicarea mărcii temporale. Finalizarea este afișată separat de lista de intrare. Folosește acțiunea rezultatului sau deschide Documente, selectează fișierul finalizat și Partajează pentru salvare în Fișiere ori trimitere către altă aplicație. Trimite rezultatul semnat, nu sursa nesemnată; include originalul pentru XML detașat.

<GuideScreenshot src="/img/guide/iphone/ro/progress.png" alt="Așteaptă finalizarea etapei curente fără a scoate cardul." steps={[{"text": "Așteaptă finalizarea etapei curente fără a scoate cardul.", "x": 10, "y": 45}]} />
<GuideScreenshot src="/img/guide/iphone/ro/success.png" alt="Selectează fișierul finalizat pentru a-l deschide. Folosește Partajează de lângă nume pentru a trimite o copie." steps={[{"text": "Selectează fișierul finalizat pentru a-l deschide. Folosește Partajează de lângă nume pentru a trimite o copie.", "x": 39, "y": 29}]} />

## Rezolvă o eroare la un document

Citește eroarea documentului afectat. Păstrează rezultatele deja finalizate și corectează fișierul ori conexiunea înainte de a porni intenționat un lot nou. PIN-ul nu este reîncercat automat. Dacă PIN-ul este greșit, oprește-te și confirmă PIN-ul și cardul selectat; trei încercări greșite pot bloca actul. Aplicația nu îl poate debloca. Reconectarea nu repară un PDF invalid.

<GuideScreenshot src="/img/guide/iphone/ro/file-error.png" alt="Citește eroarea documentului înainte de o nouă încercare." steps={[{"text": "Citește eroarea documentului înainte de o nouă încercare.", "x": 50, "y": 72}]} />

## Verifică un PDF semnat și certificatul său

Verificarea necesită fișierul, nu cititorul sau PIN-ul. În Verifică, alege PDF-ul ori XML-ul semnat. Extinde fiecare semnătură, apoi certificatul și detaliile tehnice. Verifică toate semnăturile unui document contrasemnat. Rezultatele offline separă integritatea, semnătura criptografică, încrederea în lanțul inclus și marca temporală; nu reprezintă verificarea revocării curente.

<GuideScreenshot src="/img/guide/iphone/ro/verify-current.png" alt="Ecranul Verifică" steps={[{"text": "Ecranul Verifică", "x": 50, "y": 86}]} />

<GuideScreenshot src="/img/guide/iphone/ro/verify.png" alt="Consultă întâi rezultatul pentru document. Deschide fiecare semnatar pentru a-i examina semnătura." steps={[{"text": "Consultă întâi rezultatul pentru document. Deschide fiecare semnatar pentru a-i examina semnătura.", "x": 32, "y": 37}, {"text": "Folosește Șterge rezultatele din bara de navigare pentru a goli sesiunea de verificare.", "x": 91, "y": 10}]} />
<GuideScreenshot src="/img/guide/iphone/ro/certificate.png" alt="Deschide Detaliile certificatului pentru a consulta certificatul public al semnatarului, emitentul și amprenta." steps={[{"text": "Deschide Detaliile certificatului pentru a consulta certificatul public al semnatarului, emitentul și amprenta.", "x": 39, "y": 51}]} />

<GuideScreenshot src="/img/guide/iphone/ro/technical.png" alt="Deschide Detalii tehnice sub o semnătură pentru a citi raportul de verificare. Apasă din nou pe rând pentru a-l restrânge." steps={[{"text": "Deschide Detalii tehnice sub o semnătură pentru a citi raportul de verificare. Apasă din nou pe rând pentru a-l restrânge.", "x": 33, "y": 65}]} />

## Furnizează originalul pentru XML detașat

Semnătura XML detașată nu poate confirma amprenta documentului până când originalul nemodificat este disponibil. În rezultatul incomplet, folosește Alege originalele și selectează fișierele corespunzătoare. Așteaptă actualizarea rezultatului. Alegerea altui fișier schimbă dovezile; lipsa originalului nu dovedește singură modificarea.

<GuideScreenshot src="/img/guide/iphone/ro/incomplete.png" alt="Citește ce original lipsește." steps={[{"text": "Citește ce original lipsește.", "x": 45, "y": 25}, {"text": "Alege originalele nemodificate și așteaptă actualizarea verificării.", "x": 46, "y": 44}]} />

## Înțelege un rezultat neașteptat

Invalid înseamnă că verificarea semnăturii sau integrității a eșuat. Încredere neconfirmată înseamnă că lanțul inclus nu este confirmat și diferă de modificarea dovedită. Nesemnat sau nerecunoscut înseamnă că nu a fost găsită o semnătură acceptată. Numele fișierului ori pictograma verde nu sunt dovezi. Un fișier inaccesibil este indisponibil, nu neapărat nesemnat.

<GuideScreenshot src="/img/guide/iphone/ro/invalid.png" alt="Citește verificările eșuate și cere expeditorului fișierul semnat corect sau originalul nemodificat." steps={[{"text": "Citește verificările eșuate și cere expeditorului fișierul semnat corect sau originalul nemodificat.", "x": 43, "y": 25}]} />
<GuideScreenshot src="/img/guide/iphone/ro/untrusted.png" alt="Citește avertismentul de încredere separat de integritate și semnătură." steps={[{"text": "Citește avertismentul de încredere separat de integritate și semnătură.", "x": 49, "y": 27}]} />
<GuideScreenshot src="/img/guide/iphone/ro/unsigned.png" alt="Confirmă că ai ales rezultatul semnat și verifică dacă există o semnătură acceptată." steps={[{"text": "Confirmă că ai ales rezultatul semnat și verifică dacă există o semnătură acceptată.", "x": 47, "y": 27}]} />

## Găsește un document și deschide detaliile semnării

Documente salvate conține rezultate semnate, criptate și decriptate. Selectează un fișier semnat pentru detaliile semnăturii. Un fișier criptat oferă decriptarea; conținutul criptat nu este trimis la verificarea semnăturii. Fișierele decriptate își păstrează tipul rezultatului și pot fi deschise sau exportate.

Deschide Documente și selectează un element salvat. Fereastra detaliilor folosește aceeași prezentare ca Verifică și nu înlocuiește spațiul de verificare curent. Previzualizare deschide conținutul; Partajează exportă fișierul ales. Dacă fișierul a fost mutat sau nu poate fi citit, selectează-l din locația reală.

<GuideScreenshot src="/img/guide/iphone/ro/documents.png" alt="Selectează numele unui fișier pentru a-i examina semnăturile. Folosește acțiunile de lângă nume pentru a-l previzualiza sau partaja." steps={[{"text": "Selectează numele unui fișier pentru a-i examina semnăturile. Folosește acțiunile de lângă nume pentru a-l previzualiza sau partaja.", "x": 35, "y": 40}]} />
<GuideScreenshot src="/img/guide/iphone/ro/details.png" alt="Deschide rândul unui semnatar pentru a vedea verificările. Sub raport poți alege Previzualizare sau Partajează." steps={[{"text": "Deschide rândul unui semnatar pentru a vedea verificările. Sub raport poți alege Previzualizare sau Partajează.", "x": 32.6, "y": 51.3}]} />

## Șterge istoricul păstrând documentele salvate

În Documente, treci la Istoric, alege Șterge lista și confirmă. Sunt eliminate operațiile recente, nu fișierele semnate sau colecția Documente. Revino la Documente pentru rezultatele păstrate. Șterge un fișier exportat din Fișiere sau din furnizorul său de stocare.

<GuideScreenshot src="/img/guide/iphone/ro/history.png" alt="În Istoric găsești numele fișierului, rezultatul și data. Deschide Documente salvate pentru a folosi fișierul rezultat." steps={[{"text": "În Istoric găsești numele fișierului, rezultatul și data. Deschide Documente salvate pentru a folosi fișierul rezultat.", "x": 72, "y": 29}]} />

## Autentifică-te sau semnează pe un site

Deschide Browser, folosește Deschide o adresă ori un serviciu salvat și navighează la autentificarea sau semnarea cu act electronic. Browserul solicită prezentarea desktop pentru fluxurile compatibile de autentificare. Păstrează eSemnBun în prim-plan; conexiunea mobilă se oprește în fundal. Verifică serviciul și cererea înainte de aprobare. Ilustrația păstrează rețeaua și hardware-ul inactive, deci comenzile de navigare pot fi dezactivate.

<GuideScreenshot src="/img/guide/iphone/ro/browser.png" alt="Deschide Browser și verifică starea conexiunii." steps={[{"text": "Deschide Browser și verifică starea conexiunii.", "x": 8, "y": 15}, {"text": "Folosește comanda pentru adresă ca să introduci URL-ul serviciului.", "x": 88, "y": 9}, {"text": "Deschide Servicii/Semne de carte pentru adresele salvate.", "x": 77, "y": 9}, {"text": "Folosește înapoi, înainte și reîncărcare în timpul navigării.", "x": 18, "y": 87}]} />

În Setări → Browser, deschide Autentificare pentru a alege NFC sau un cititor de carduri. Eticheta arată metoda curentă.

<GuideScreenshot src="/img/guide/iphone/ro/browser-authentication.png" alt="În Setări → Browser, deschide Autentificare pentru a alege NFC sau un cititor de carduri. Eticheta arată metoda curentă." caption="Captură nativă iPhone, focalizată pe autentificarea în browser." steps={[{"text": "În Setări → Browser, deschide Autentificare pentru a alege NFC sau un cititor de carduri. Eticheta arată metoda curentă.", "x": 83, "y": 71}]} />

Pentru un semn de carte, deschide Servicii/Semne de carte → Adaugă, setează titlul, URL-ul și pictograma, apoi salvează. Gestionarea permite editarea sau eliminarea. Pentru resetarea sesiunii, deschide Șterge datele browserului, alege cache, cookie-uri și/sau istoric și confirmă. Ștergerea cookie-urilor te poate deconecta, dar nu șterge Documente ori PIN-urile salvate. Erorile site-ului necesită asistența serviciului, nu încercări repetate ale PIN-ului.

## Schimbă limba, aspectul și confidențialitatea

Deschide **Setări** pentru a găsi Modul demonstrativ în partea de sus, apoi cardurile, PIN-urile salvate, limba și aspectul. Modul demonstrativ folosește date fictive și nu produce semnături valide.

Deschide **Setări → Carduri și cititoare** pentru a consulta un card conectat. În ecranul Semnează, butonul de informații din dreapta sus deschide detaliile cardului. Gestionează PIN-urile în **Setări → Carduri și PIN-uri salvate**. Cardul și PIN-ul memorate sunt comune pentru NFC și USB.

Alege româna, engleza, rusa sau limba sistemului și aspectul Luminos, Întunecat sau Sistem. În Despre găsești versiunea instalată și legăturile de asistență. Activează ștampila PDF din browser dacă vrei o marcă vizibilă pentru solicitările acceptate.

<GuideScreenshot src="/img/guide/iphone/ro/cards-current.png" alt="Carduri și cititoare în Setări" steps={[{"text": "Carduri și cititoare în Setări", "x": 29, "y": 34}]} />

<GuideScreenshot src="/img/guide/iphone/ro/saved-cards.png" alt="În Setări vezi cardurile salvate chiar și după deconectarea cititorului. Uită cardul elimină identitatea și PIN-ul ei salvat de pe acest dispozitiv." steps={[{"text": "În Setări vezi cardurile salvate chiar și după deconectarea cititorului. Uită cardul elimină identitatea și PIN-ul ei salvat de pe acest dispozitiv.", "x": 28, "y": 35}]} />

Ștergerea unui PIN salvat elimină copia de pe acest dispozitiv. PIN-ul cardului nu se schimbă și cardul nu se deblochează.

## Folosește Scurtături, Siri, Spotlight și Handoff

În aplicația Apple Scurtături, creează o scurtătură, adaugă o acțiune, caută eSemnBun și alege Deschide Documente, Pregătește PDF pentru semnare ori Verifică PDF. Oferă un PDF acțiunilor de pregătire/verificare. Pregătirea deschide aplicația cu PDF-ul în listă; verifici și aprobi semnarea în prim-plan. Verificarea returnează rezultatul offline și deschide detaliile. Limita PDF este 32 MiB. Rulează scurtătura din aplicație ori printr-o expresie Siri disponibilă; Siri nu primește PIN-ul cardului.


1. Deschide Scurtături, adaugă o acțiune și caută eSemnBun.
2. Alege Deschide Documente, Pregătește PDF pentru semnare ori Verifică PDF; oferă un PDF când este cerut.
3. Rulează scurtătura. Verifică lista pregătită ori rezultatul offline în eSemnBun; semnarea necesită în continuare aprobarea ta.

Pentru căutare, activează Găsește documentele semnate în Siri și Spotlight din Setări, finalizează un PDF/XML semnat deținut de aplicație și caută numele în Spotlight. Indexul opțional expune numele și datele, nu conținutul, PIN-ul ori identitatea certificatului. Schemele sistem Open/Search necesită funcțiile OS/SDK acceptate; sugestiile depind de dispozitiv, limbă și configurare. Cu Handoff activ pe dispozitive Apple compatibile, deschide Documente pe unul și continuă de pe celălalt. Handoff reia navigarea către Documente; nu transferă PDF-ul, PIN-ul sau sesiunea cardului. Verifică disponibilitatea Siri, Spotlight și Handoff în versiunea instalată; capturile arată comenzile aplicației, nu un rezultat real între dispozitive.
<GuideScreenshot src="/img/guide/iphone/ro/settings.png" alt="Activează descoperirea doar dacă dorești ca numele și datele documentelor semnate să fie disponibile în Siri și Spotlight." steps={[{"text": "Activează descoperirea doar dacă dorești ca numele și datele documentelor semnate să fie disponibile în Siri și Spotlight.", "x": 85, "y": 62.5}, {"text": "După crearea unui document semnat deținut de aplicație, caută numele în Spotlight și deschide rezultatul."}, {"text": "Pentru Handoff, deschide Documente pe un dispozitiv compatibil și continuă pe celălalt."}]} />

## Folosește o fereastră iPhone mai mică sau mai largă

În portret sunt folosite file compacte. Rotește telefonul sau extinde dispozitivul/fereastra acceptată pentru mai mult spațiu la card și fișiere. Derulează pentru opțiuni și verificarea PIN când tastatura reduce spațiul. Postura și rotația depind de iOS; o postură pliabilă nu este identică automat cu un telefon în peisaj.

## Cere ajutor fără a trimite secrete

Fără cititor: verifică firul, adaptorul și alimentarea. Cititor gol: reintrodu cardul și așteaptă. Eroare repetată a cardului: oprește operația înainte de reconectare. PIN blocat: contactează furnizorul oficial. Pentru [asistență](/support), include versiunile aplicației/iOS, modelele cititorului și adaptorului și pașii cu un exemplu fictiv. Nu trimite PIN-ul, date private de identitate sau documente confidențiale.

Dacă sesiunea NFC se întrerupe, ține cardul lângă antenă până se închide fereastra de scanare. Verifică cardul și PIN-ul selectate înainte de a reîncerca după un PIN greșit. Poți alege un cititor USB compatibil în Semnează.

## Alte ghiduri

[iPhone](./ios.md) · [iPad](./ipad.md) · [macOS](./macos.md) · [Android](./android.md) · [Linux](./linux.md)

<!-- file-protection-guides -->


## Criptează un fișier cu parolă

În **Documente**, apasă scutul **Protejează fișiere** din bara de instrumente. În formular, alege **Criptează** sau **Decriptează**, apoi un fișier accesibil.

Nu ai nevoie de card. Creează o parolă pentru fișier și transmite-o destinatarului printr-un canal de încredere separat. Nu este PIN-ul cardului. Criptarea creează un rezultat separat; păstrează originalul până verifici rezultatul.

În versiunea 0.2.13, alege **Parolă** și selectează AES-128, AES-192 sau AES-256. Opțiunea implicită este AES-256. Pentru a cripta pentru un destinatar, alege **Certificat RSA** și selectează certificatul său public de criptare (.cer sau .der). Implicit, folosește un certificat destinat criptării. **Compatibilitate cu cheia publică a cardului** permite explicit cheia RSA publică a cardului. Exportul sau criptarea reușită nu dovedesc că acel card poate decripta; cardul corespunzător trebuie să permită operația necesară cu cheia privată.

<GuideScreenshot src="/img/guide/iphone/ro/documents-protection-light.png" alt="În Documente, deschide Protejează fișiere din bara de instrumente apăsând scutul." steps={[{"text": "În Documente, deschide Protejează fișiere din bara de instrumente apăsând scutul.", "x": 90, "y": 10}]} />

<GuideScreenshot src="/img/guide/iphone/ro/protect-password-light.png" alt="Selectează fișierul sursă și Parolă. Alege dimensiunea cheii AES, introdu și confirmă parola, apoi apasă Criptează." steps={[{"text": "Selectează fișierul sursă și Parolă. Alege dimensiunea cheii AES, introdu și confirmă parola, apoi apasă Criptează.", "x": 81, "y": 55}]} />

<GuideScreenshot src="/img/guide/iphone/ro/protect-certificate-light.png" alt="Alege Certificat RSA, apoi selectează certificatul public de criptare al destinatarului. Criptarea nu cere PIN-ul destinatarului." steps={[{"text": "Alege Certificat RSA, apoi selectează certificatul public de criptare al destinatarului. Criptarea nu cere PIN-ul destinatarului.", "x": 42.1, "y": 71.4}, {"text": "Folosește Compatibilitate cu cheia publică a cardului doar când fluxul cere cheia RSA publică a cardului.", "x": 38.0, "y": 55.0}]} />

<GuideScreenshot src="/img/guide/iphone/ro/protect-complete-light.png" alt="Rezultatul este salvat în Documente. Alege Salvează o copie pentru export sau Gata pentru a reveni." steps={[{"text": "Rezultatul este salvat în Documente. Alege Salvează o copie pentru export sau Gata pentru a reveni.", "x": 50, "y": 68}]} />

Alege **Criptează** sau **Decriptează**. Rezultatul nou este salvat automat în **Documente → Documente salvate**. Alege **Gata** pentru a reveni sau **Salvează o copie** pentru a-l exporta în Fișiere ori în alt loc. Originalul este păstrat.

Documente salvate include fișiere semnate, criptate și decriptate. Identifică rezultatul după numele fișierului și eticheta operațiunii. Criptarea nu creează o semnătură digitală; fișierele criptate trebuie decriptate înainte de deschiderea sau verificarea conținutului.


## Decriptează un fișier primit

În **Documente**, apasă scutul **Protejează fișiere** din bara de instrumente. În formular, alege **Criptează** sau **Decriptează**, apoi un fișier accesibil.

Pentru un fișier criptat cu parolă, cere parola expeditorului printr-un canal de încredere separat. Fișierul specifică dimensiunea cheii AES. Pentru fișierele RSA, în versiunea 0.2.13 conectează cardul care conține cheia de criptare a destinatarului, citește cardul și autorizează decriptarea cu PIN-ul său.

<GuideScreenshot src="/img/guide/iphone/ro/documents-protection-light.png" alt="În Documente, deschide Protejează fișiere din bara de instrumente apăsând scutul." steps={[{"text": "În Documente, deschide Protejează fișiere din bara de instrumente apăsând scutul.", "x": 90, "y": 10}]} />

<GuideScreenshot src="/img/guide/iphone/ro/protect-decrypt-light.png" alt="Selectează fișierul criptat. Când apare Parolă, introdu parola primită separat de la expeditor și apasă Decriptează." steps={[{"text": "Selectează fișierul criptat. Când apare Parolă, introdu parola primită separat de la expeditor și apasă Decriptează.", "x": 86, "y": 48}]} />

<GuideScreenshot src="/img/guide/iphone/ro/protect-rsa-decrypt.png" alt="Pentru un fișier RSA, conectează cititorul și cardul destinatarului, apoi alege Citește cardul meu. Autorizează cu PIN-ul cardului." steps={[{"text": "Pentru un fișier RSA, conectează cititorul și cardul destinatarului, apoi alege Citește cardul meu. Autorizează cu PIN-ul cardului.", "x": 35.5, "y": 70.6}]} />

<GuideScreenshot src="/img/guide/iphone/ro/protect-decrypt-complete-light.png" alt="Rezultatul este salvat în Documente. Alege Salvează o copie pentru export sau Gata pentru a reveni." steps={[{"text": "Rezultatul este salvat în Documente. Alege Salvează o copie pentru export sau Gata pentru a reveni.", "x": 50, "y": 68}]} />

Deschide și verifică rezultatul salvat înainte de utilizare. Criptarea compatibilă MoldSign nu autentifică conținutul: decriptarea reușită nu dovedește singură integritatea sau parola corectă.

Alege **Criptează** sau **Decriptează**. Rezultatul nou este salvat automat în **Documente → Documente salvate**. Alege **Gata** pentru a reveni sau **Salvează o copie** pentru a-l exporta în Fișiere ori în alt loc. Originalul este păstrat.

Documente salvate include fișiere semnate, criptate și decriptate. Identifică rezultatul după numele fișierului și eticheta operațiunii. Criptarea nu creează o semnătură digitală; fișierele criptate trebuie decriptate înainte de deschiderea sau verificarea conținutului.
