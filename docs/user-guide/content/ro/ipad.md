---
title: iPad
---

import GuideScreenshot from '@site/src/components/GuideScreenshot';

# iPad

Urmează cercurile numerotate pentru fiecare obiectiv. Ghidurile descriu funcțiile aplicației 0.2.6; capturile folosesc identități fictive și documente de exemplu într-un mediu izolat. Nu reprezintă semnături reale și nu conțin un PIN real. Atinge imaginea pentru a o mări.

Instalează eSemnBun prin canalul Apple disponibil din [Descărcări](/downloads), apoi deschide aplicația instalată. Ai nevoie de un act electronic activ acceptat, PIN-ul corect de semnare, un cititor cu fir compatibil și [adaptorul](/devices) potrivit. Dispozitivele USB-C necesită o conexiune USB adecvată; pentru Lightning poate fi necesar un adaptor alimentat. Semnarea prin NFC nu este disponibilă.

## Conectează cititorul și introdu cardul

Certificatul de semnare este citit fără PIN. Mesajul despre cititorul gol indică un cititor detectat, dar fără un card pregătit. Așteaptă afișarea titularului și a valabilității înainte de semnare.

<GuideScreenshot src="/img/guide/ipad/ro/connect.png" alt="Conectează cititorul USB prin adaptorul potrivit." caption="Captură iPad nativă în portret; spațiul liber ori împrejurimile ferestrei au fost decupate pentru lizibilitate." steps={[{"text": "Conectează cititorul USB prin adaptorul potrivit.", "x": 10.0, "y": 55.2}]} />
<GuideScreenshot src="/img/guide/ipad/ro/empty-reader.png" alt="Introdu cardul când aplicația indică un cititor gol." caption="Captură iPad nativă în portret; spațiul liber ori împrejurimile ferestrei au fost decupate pentru lizibilitate." steps={[{"text": "Introdu cardul când aplicația indică un cititor gol.", "x": 10.0, "y": 58.6}]} />

## Alege identitatea care va semna

Dacă sunt conectate mai multe carduri, glisează caruselul pentru a centra titularul dorit. Cardul selectat este folosit la operație. Deschide Card pentru certificat sau pentru recitire după reconectare. Portretul neutru este o ilustrație, nu fotografia citită din act.

<GuideScreenshot src="/img/guide/ipad/ro/cards.png" alt="Glisează caruselul pentru a alege titularul dorit." caption="Captură iPad nativă în portret; spațiul liber ori împrejurimile ferestrei au fost decupate pentru lizibilitate." steps={[{"text": "Glisează caruselul pentru a alege titularul dorit.", "x": 20.0, "y": 42.9}, {"text": "Deschide Card pentru certificat și cititor; folosește meniul filelor dacă această filă este ascunsă.", "x": 73.0, "y": 11.9}]} />
<GuideScreenshot src="/img/guide/ipad/ro/card.png" alt="Verifică titularul, valabilitatea certificatului și cititorul." steps={[{"text": "Verifică titularul, valabilitatea certificatului și cititorul.", "x": 7, "y": 37}, {"text": "Recitește după corectarea conexiunii; ștergerea PIN-ului salvat nu schimbă PIN-ul cardului.", "x": 95, "y": 5}]} />

## Adaugă documente și alege formatul semnăturii

Deschide Semnează și alege fișiere din Fișiere sau dintr-un furnizor cloud. Descarcă întâi documentele disponibile doar în cloud dacă accesul eșuează. Poți trimite fișiere și din meniul de partajare al altei aplicații către extensia eSemnBun. Extinde lista, verifică numele, elimină fișierele nedorite din opțiunile lor și alege formatul cerut. PDF-urile folosesc PAdES-T; celelalte fișiere folosesc XAdES. XML-ul detașat trebuie păstrat împreună cu originalul nemodificat. XAdES-BES nu are marcă temporală, T o adaugă, iar C include referințe la certificate și stare. XML-ul încorporat include conținutul original. Formatele cu marcă temporală necesită serviciile publice de încredere.

<GuideScreenshot src="/img/guide/ipad/ro/sign.png" alt="Confirmă titularul selectat înainte de semnare." caption="Captură iPad nativă în portret; spațiul liber ori împrejurimile ferestrei au fost decupate pentru lizibilitate." steps={[{"text": "Confirmă titularul selectat înainte de semnare.", "x": 12.0, "y": 37.5}, {"text": "Alege fișiere sau adaugă alte documente în listă.", "x": 79.0, "y": 75.0}, {"text": "Extinde lista și deschide opțiunile unui fișier pentru format, ștampilă sau eliminare.", "x": 93.0, "y": 40.0}, {"text": "Apasă Semnează numai după verificarea întregii liste.", "x": 10.0, "y": 70.0}]} />

## Plasează o ștampilă vizibilă într-un PDF

Deschide opțiunile unui PDF și alege Adaugă/Editează ștampila. Ștampila vizibilă este opțională; dovada semnării rămâne semnătura criptografică. Evită acoperirea textului existent.

<GuideScreenshot src="/img/guide/ipad/ro/stamp.png" alt="Trage ștampila pentru mutare și colțurile pentru redimensionare." caption="Captură iPad nativă în portret; spațiul liber ori împrejurimile ferestrei au fost decupate pentru lizibilitate." steps={[{"text": "Trage ștampila pentru mutare și colțurile pentru redimensionare.", "x": 38.6, "y": 56.1}, {"text": "Alege pagina și modul Oprit, O pagină sau Toate paginile.", "x": 14.3, "y": 82.5}, {"text": "Opțional, aplică poziția tuturor PDF-urilor din listă, apoi apasă Aplică.", "x": 91.4, "y": 5.3}]} />

## Verifică cererea și autorizează semnarea

Pentru o cerere de pe un site, verifică originea și întreaga listă de documente înainte de acceptare. Anulează cererile neașteptate. Pentru un lot local, verifică lista și fereastra PIN. Fiecare lot nou necesită aprobare; sesiunea acoperă doar documentele afișate și cardul ales.

<GuideScreenshot src="/img/guide/ipad/ro/consent.png" alt="Verifică site-ul solicitant și operația dorită." caption="Captură iPad nativă în portret; spațiul liber ori împrejurimile ferestrei au fost decupate pentru lizibilitate." steps={[{"text": "Verifică site-ul solicitant și operația dorită.", "x": 7.1, "y": 12.5}, {"text": "Verifică toate documentele; acceptă numai o cerere inițiată de tine.", "x": 91.4, "y": 87.5}]} />
<GuideScreenshot src="/img/guide/ipad/ro/pin.png" alt="Verifică titularul și numele fișierelor selectate." steps={[{"text": "Verifică titularul și numele fișierelor selectate.", "x": 50, "y": 19}, {"text": "Introdu PIN-ul QSCD corect în câmpul protejat.", "x": 30, "y": 27}, {"text": "Activează memorarea PIN-ului doar pe un dispozitiv personal de încredere; accesul ulterior cere autentificarea oferită de dispozitiv.", "x": 73, "y": 31}, {"text": "Apasă Semnează pentru autorizare sau Anulează pentru oprire.", "x": 94, "y": 70}]} />

## Așteaptă finalizarea și salvează rezultatul semnat

Păstrează cititorul și cardul conectate pe durata semnării și a obținerii mărcii temporale. Finalizarea este afișată separat de lista de intrare. Folosește acțiunea rezultatului sau deschide Documente, selectează fișierul finalizat și Partajează pentru salvare în Fișiere ori trimitere către altă aplicație. Trimite rezultatul semnat, nu sursa nesemnată; include originalul pentru XML detașat.

<GuideScreenshot src="/img/guide/ipad/ro/progress.png" alt="Așteaptă finalizarea etapei curente fără a scoate cardul." caption="Captură iPad nativă în portret; spațiul liber ori împrejurimile ferestrei au fost decupate pentru lizibilitate." steps={[{"text": "Așteaptă finalizarea etapei curente fără a scoate cardul.", "x": 9.0, "y": 82.5}]} />
<GuideScreenshot src="/img/guide/ipad/ro/success.png" alt="Verifică finalizarea și numele rezultatului înainte de deschidere sau partajare." caption="Captură iPad nativă în portret; spațiul liber ori împrejurimile ferestrei au fost decupate pentru lizibilitate." steps={[{"text": "Verifică finalizarea și numele rezultatului înainte de deschidere sau partajare.", "x": 9.0, "y": 41.4}]} />

## Rezolvă o eroare la un document

Citește eroarea documentului afectat. Păstrează rezultatele deja finalizate și corectează fișierul ori conexiunea înainte de a porni intenționat un lot nou. PIN-ul nu este reîncercat automat. Dacă PIN-ul este greșit, oprește-te și confirmă PIN-ul și cardul selectat; trei încercări greșite pot bloca actul. Aplicația nu îl poate debloca. Reconectarea nu repară un PDF invalid.

<GuideScreenshot src="/img/guide/ipad/ro/file-error.png" alt="Citește eroarea documentului înainte de o nouă încercare." caption="Captură iPad nativă în portret; spațiul liber ori împrejurimile ferestrei au fost decupate pentru lizibilitate." steps={[{"text": "Citește eroarea documentului înainte de o nouă încercare.", "x": 47.0, "y": 43.2}]} />

## Verifică un PDF semnat și certificatul său

Verificarea necesită fișierul, nu cititorul sau PIN-ul. În Verifică, alege PDF-ul ori XML-ul semnat. Extinde fiecare semnătură, apoi certificatul și detaliile tehnice. Verifică toate semnăturile unui document contrasemnat. Rezultatele offline separă integritatea, semnătura criptografică, încrederea în lanțul inclus și marca temporală; nu reprezintă verificarea revocării curente.

<GuideScreenshot src="/img/guide/ipad/ro/verify.png" alt="Deschide Verifică și adaugă documentul semnat." caption="Captură iPad nativă în portret; spațiul liber ori împrejurimile ferestrei au fost decupate pentru lizibilitate." steps={[{"text": "Deschide Verifică și adaugă documentul semnat.", "x": 37.0, "y": 36.6}, {"text": "Extinde rândul semnăturii pentru rezultat și semnatar.", "x": 11.0, "y": 80.5}]} />
<GuideScreenshot src="/img/guide/ipad/ro/certificate.png" alt="Derulează semnătura extinsă la detaliile certificatului, apoi analizează identitatea, valabilitatea și amprenta separat de integritatea documentului." steps={[{"text": "Derulează semnătura extinsă la detaliile certificatului, apoi analizează identitatea, valabilitatea și amprenta separat de integritatea documentului.", "x": 13, "y": 59}]} />

## Furnizează originalul pentru XML detașat

Semnătura XML detașată nu poate confirma amprenta documentului până când originalul nemodificat este disponibil. În rezultatul incomplet, folosește Alege originalele și selectează fișierele corespunzătoare. Așteaptă actualizarea rezultatului. Alegerea altui fișier schimbă dovezile; lipsa originalului nu dovedește singură modificarea.

<GuideScreenshot src="/img/guide/ipad/ro/incomplete.png" alt="Citește ce original lipsește." caption="Captură iPad nativă în portret; spațiul liber ori împrejurimile ferestrei au fost decupate pentru lizibilitate." steps={[{"text": "Citește ce original lipsește.", "x": 20.0, "y": 66.0}, {"text": "Alege originalele nemodificate și așteaptă actualizarea verificării.", "x": 10.0, "y": 70.0}]} />

## Înțelege un rezultat neașteptat

Invalid înseamnă că verificarea semnăturii sau integrității a eșuat. Încredere neconfirmată înseamnă că lanțul inclus nu este confirmat și diferă de modificarea dovedită. Nesemnat sau nerecunoscut înseamnă că nu a fost găsită o semnătură acceptată. Numele fișierului ori pictograma verde nu sunt dovezi. Un fișier inaccesibil este indisponibil, nu neapărat nesemnat.

<GuideScreenshot src="/img/guide/ipad/ro/invalid.png" alt="Citește verificările eșuate și cere expeditorului fișierul semnat corect sau originalul nemodificat." caption="Captură iPad nativă în portret; spațiul liber ori împrejurimile ferestrei au fost decupate pentru lizibilitate." steps={[{"text": "Citește verificările eșuate și cere expeditorului fișierul semnat corect sau originalul nemodificat.", "x": 13.0, "y": 65.9}]} />
<GuideScreenshot src="/img/guide/ipad/ro/untrusted.png" alt="Citește avertismentul de încredere separat de integritate și semnătură." caption="Captură iPad nativă în portret; spațiul liber ori împrejurimile ferestrei au fost decupate pentru lizibilitate." steps={[{"text": "Citește avertismentul de încredere separat de integritate și semnătură.", "x": 13.0, "y": 65.9}]} />
<GuideScreenshot src="/img/guide/ipad/ro/unsigned.png" alt="Confirmă că ai ales rezultatul semnat și verifică dacă există o semnătură acceptată." caption="Captură iPad nativă în portret; spațiul liber ori împrejurimile ferestrei au fost decupate pentru lizibilitate." steps={[{"text": "Confirmă că ai ales rezultatul semnat și verifică dacă există o semnătură acceptată.", "x": 13.0, "y": 73.0}]} />

## Găsește un document și deschide detaliile semnării

Deschide Documente și selectează un element salvat. Fereastra detaliilor folosește aceeași prezentare ca Verifică și nu înlocuiește spațiul de verificare curent. Previzualizare deschide conținutul; Partajează exportă fișierul ales. Dacă fișierul a fost mutat sau nu poate fi citit, selectează-l din locația reală.

<GuideScreenshot src="/img/guide/ipad/ro/documents.png" alt="Deschide Documente și selectează fișierul dorit." caption="Captură iPad nativă în portret; spațiul liber ori împrejurimile ferestrei au fost decupate pentru lizibilitate." steps={[{"text": "Deschide Documente și selectează fișierul dorit.", "x": 7.0, "y": 51.2}, {"text": "Folosește căutarea pentru restrângerea listei.", "x": 97.0, "y": 11.6}]} />
<GuideScreenshot src="/img/guide/ipad/ro/details.png" alt="Verifică detaliile semnării documentului." caption="Captură iPad nativă în portret; spațiul liber ori împrejurimile ferestrei au fost decupate pentru lizibilitate." steps={[{"text": "Verifică detaliile semnării documentului.", "x": 10.0, "y": 52.9}, {"text": "Alege Previzualizare pentru citire sau Partajează pentru salvare/trimitere.", "x": 5.7, "y": 79.4}, {"text": "Apasă Gata pentru revenirea la bibliotecă.", "x": 92.9, "y": 11.8}]} />

## Șterge istoricul păstrând documentele salvate

În Documente, treci la Istoric, alege Șterge lista și confirmă. Sunt eliminate operațiile recente, nu fișierele semnate sau colecția Documente. Revino la Documente pentru rezultatele păstrate. Șterge un fișier exportat din Fișiere sau din furnizorul său de stocare.

<GuideScreenshot src="/img/guide/ipad/ro/history.png" alt="Comută între Documente și Istoric." caption="Captură iPad nativă în portret; spațiul liber ori împrejurimile ferestrei au fost decupate pentru lizibilitate." steps={[{"text": "Comută între Documente și Istoric.", "x": 74.0, "y": 32.6}, {"text": "Șterge istoricul doar dacă dorești eliminarea înregistrărilor recente.", "x": 91.0, "y": 11.6}]} />

## Autentifică-te sau semnează pe un site

Deschide Browser, folosește Deschide o adresă ori un serviciu salvat și navighează la autentificarea sau semnarea cu act electronic. Browserul solicită prezentarea desktop pentru fluxurile compatibile de autentificare. Păstrează eSemnBun în prim-plan; conexiunea mobilă se oprește în fundal. Verifică serviciul și cererea înainte de aprobare. Ilustrația păstrează rețeaua și hardware-ul inactive, deci comenzile de navigare pot fi dezactivate.

<GuideScreenshot src="/img/guide/ipad/ro/browser.png" alt="Deschide Browser și verifică starea conexiunii." steps={[{"text": "Deschide Browser și verifică starea conexiunii.", "x": 5, "y": 8}, {"text": "Folosește comanda pentru adresă ca să introduci URL-ul serviciului.", "x": 97, "y": 5}, {"text": "Deschide Servicii/Semne de carte pentru adresele salvate.", "x": 91, "y": 5}, {"text": "Folosește înapoi, înainte și reîncărcare în timpul navigării.", "x": 6, "y": 97}]} />

Pentru un semn de carte, deschide Servicii/Semne de carte → Adaugă, setează titlul, URL-ul și pictograma, apoi salvează. Gestionarea permite editarea sau eliminarea. Pentru resetarea sesiunii, deschide Șterge datele browserului, alege cache, cookie-uri și/sau istoric și confirmă. Ștergerea cookie-urilor te poate deconecta, dar nu șterge Documente ori PIN-urile salvate. Erorile site-ului necesită asistența serviciului, nu încercări repetate ale PIN-ului.

## Schimbă limba, aspectul și confidențialitatea

Deschide Card, apoi Setări. Alege Română, English, Русский ori Sistem și tema Luminoasă, Întunecată ori Sistem. Activează ștampilele PDF din browser doar dacă le dorești pentru cererile acceptate. Modul demonstrativ obișnuit este etichetat intenționat și nu produce semnături reale. Despre afișează versiunea și informațiile utile. Actualizările vin prin canalul Apple folosit la instalare.

<GuideScreenshot src="/img/guide/ipad/ro/settings.png" alt="Alege limba interfeței și tema." caption="Captură iPad nativă în portret; spațiul liber ori împrejurimile ferestrei au fost decupate pentru lizibilitate." steps={[{"text": "Alege limba interfeței și tema.", "x": 5.7, "y": 26.3}, {"text": "Verifică opțiunile pentru ștampilă în browser și descoperirea documentelor.", "x": 90.0, "y": 70.2}, {"text": "Folosește Despre pentru versiune și Gata pentru închiderea setărilor.", "x": 92.9, "y": 5.3}]} />

Pentru un PIN memorat, deschide Card pentru identitatea respectivă și Șterge PIN-ul salvat când opțiunea este disponibilă. Memorarea folosește seiful protejat al platformei și autentificarea dispozitivului; ștergerea copiei nu schimbă și nu deblochează PIN-ul fizic. Un alt card necesită propriul PIN.

## Folosește Scurtături, Siri, Spotlight și Handoff

În aplicația Apple Scurtături, creează o scurtătură, adaugă o acțiune, caută eSemnBun și alege Deschide Documente, Pregătește PDF pentru semnare ori Verifică PDF. Oferă un PDF acțiunilor de pregătire/verificare. Pregătirea deschide aplicația cu PDF-ul în listă; verifici și aprobi semnarea în prim-plan. Verificarea returnează rezultatul offline și deschide detaliile. Limita PDF este 32 MiB. Rulează scurtătura din aplicație ori printr-o expresie Siri disponibilă; Siri nu primește PIN-ul cardului.


1. Deschide Scurtături, adaugă o acțiune și caută eSemnBun.
2. Alege Deschide Documente, Pregătește PDF pentru semnare ori Verifică PDF; oferă un PDF când este cerut.
3. Rulează scurtătura. Verifică lista pregătită ori rezultatul offline în eSemnBun; semnarea necesită în continuare aprobarea ta.

Pentru căutare, activează Găsește documentele semnate în Siri și Spotlight din Setări, finalizează un PDF/XML semnat deținut de aplicație și caută numele în Spotlight. Indexul opțional expune numele și datele, nu conținutul, PIN-ul ori identitatea certificatului. Schemele sistem Open/Search necesită funcțiile OS/SDK acceptate; sugestiile depind de dispozitiv, limbă și configurare. Cu Handoff activ pe dispozitive Apple compatibile, deschide Documente pe unul și continuă de pe celălalt. Handoff reia navigarea către Documente; nu transferă PDF-ul, PIN-ul sau sesiunea cardului. Verifică disponibilitatea Siri, Spotlight și Handoff în versiunea instalată; capturile arată comenzile aplicației, nu un rezultat real între dispozitive.
<GuideScreenshot src="/img/guide/ipad/ro/settings.png" alt="Activează descoperirea doar dacă dorești ca numele și datele documentelor semnate să fie disponibile în Siri și Spotlight." caption="Captură iPad nativă în portret; spațiul liber ori împrejurimile ferestrei au fost decupate pentru lizibilitate." steps={[{"text": "Activează descoperirea doar dacă dorești ca numele și datele documentelor semnate să fie disponibile în Siri și Spotlight.", "x": 90.0, "y": 70.2}, {"text": "După crearea unui document semnat deținut de aplicație, caută numele în Spotlight și deschide rezultatul."}, {"text": "Pentru Handoff, deschide Documente pe un dispozitiv compatibil și continuă pe celălalt."}]} />

## Folosește ferestrele iPad și Fișiere alături de semnare

Ghidul folosește capturi iPad native, nu imagini de telefon mărite. Aspectul urmează lățimea ferestrei. Într-o fereastră largă, cardul și comenzile fișierelor pot rămâne vizibile împreună; într-una îngustă, navigarea devine compactă. Deschide Fișiere alături de eSemnBun și alege sau trage documentele unde sistemul permite. Mărește fereastra ori derulează dacă o comandă este ascunsă. Păstrează aplicația activă pentru cererile web. Capturile arată fereastra portret nativă, nu verificarea tuturor gesturilor de multitasking.


## Cere ajutor fără a trimite secrete

Fără cititor: verifică firul, adaptorul și alimentarea. Cititor gol: reintrodu cardul și așteaptă. Eroare repetată a cardului: oprește operația înainte de reconectare. PIN blocat: contactează furnizorul oficial. Pentru [asistență](/support), include versiunile aplicației/iOS, modelele cititorului și adaptorului și pașii cu un exemplu fictiv. Nu trimite PIN-ul, date private de identitate sau documente confidențiale.


## Alte ghiduri

[iPhone](./ios.md) · [iPad](./ipad.md) · [macOS](./macos.md) · [Android](./android.md) · [Linux](./linux.md)
