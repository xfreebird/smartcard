---
title: "macOS — ghid ilustrat pentru desktop"
sidebar_position: 2
---

import GuideScreenshot from '@site/src/components/GuideScreenshot';

# macOS — ghid ilustrat pentru desktop

Pentru eSemnBun 0.2.6 pe macOS 15 sau mai nou. Urmează câte un obiectiv; numerele din imagini corespund instrucțiunilor de sub ele. Apasă imaginea pentru captura la dimensiune completă. Ilustrațiile folosesc identități fictive și documente-model; nu dovedesc semnături reale sau tranzacții live cu servicii publice.

## Instalează aplicația și conectează cititorul

Deschide [Descărcări](/downloads/). Instalează ediția Mac App Store sau deschide DMG-ul pentru desktop și trage eSemnBun în Aplicații. Ejectează DMG-ul și pornește copia instalată. Arhiva TAR.GZ și Homebrew oferă instrumentele CLI/MCP; vezi [ghidul pentru terminal](./macos-cli.md).

Ai nevoie de macOS 15 sau mai nou, un cititor USB compatibil, un act electronic acceptat și activ și PIN-ul său de semnare. Folosește un adaptor USB-C adecvat, dacă este necesar. Semnarea prin NFC nu este disponibilă.

<GuideScreenshot src="/img/guide/macos/ro/connect.png" alt="Instalează aplicația și conectează cititorul" steps={[{"x": 8, "y": 11, "text": "Deschide Semnează în bara laterală."}, {"x": 60, "y": 26, "text": "Conectează cititorul USB. Ecranul se schimbă după detectarea lui."}]} />

## Introdu cardul

Certificatul se citește fără PIN. Așteaptă afișarea titularului și a expirării înainte de semnare. Cheia privată de semnare rămâne pe card.

<GuideScreenshot src="/img/guide/macos/ro/empty-reader.png" alt="Introdu cardul" steps={[{"x": 60, "y": 25, "text": "Introdu cardul în cititorul detectat și lasă-l conectat."}]} />

## Alege identitatea și verifică certificatul

Imaginea cardului folosește datele certificatului și un avatar neutru, nu fotografia citită din act. Pentru a reciti cardul, folosește butonul din dreapta sus sau meniul contextual al cardului. Nu porni o altă operațiune în timpul uneia active.

<GuideScreenshot src="/img/guide/macos/ro/cards.png" alt="Alege identitatea și verifică certificatul" steps={[{"x": 7, "y": 31, "text": "Deschide Card."}, {"x": 60, "y": 42, "text": "Dacă sunt mai multe carduri, glisează orizontal sau folosește săgețile caruselului pentru a selecta identitatea dorită."}, {"x": 82, "y": 57, "text": "Verifică titularul, emitentul, expirarea și cititorul în Certificatul de semnare."}]} />

## Adaugă documentele și alege formatul

Un PDF folosește în mod normal PAdES-T: semnătura rămâne în PDF. Alte fișiere folosesc de obicei XAdES-T detașat: păstrează XML-ul împreună cu originalul nemodificat. Folosește controlul de format al fișierului dacă destinatarul cere un alt format acceptat. Meniul rândului permite eliminarea unui fișier adăugat din greșeală.

<GuideScreenshot src="/img/guide/macos/ro/sign.png" alt="Adaugă documentele și alege formatul" steps={[{"x": 7, "y": 11, "text": "Deschide Semnează."}, {"x": 69, "y": 71, "text": "Alege fișiere sau trage-le în zona punctată. Adaugă întregul lot înainte de semnare."}, {"x": 36, "y": 53, "text": "Verifică numele și formatul fiecărui fișier. Controlul ștampilei PDF este lângă format."}, {"x": 92, "y": 3, "text": "Verifică cardul selectat, apoi alege Semnează. Butonul arată numărul documentelor."}]} />

## Aplică o ștampilă vizibilă pe PDF

Deschide controlul Ștampilă oprită/Editează ștampila al unui PDF din listă. Ștampila vizibilă este opțională și nu înlocuiește semnătura criptografică. Pentru un PDF cu mai multe pagini, selectează pagina în previzualizare.

Textul ștampilei urmează limba aleasă în aplicație (română, engleză sau rusă).

<GuideScreenshot src="/img/guide/macos/ro/stamp.png" alt="Aplică o ștampilă vizibilă pe PDF" steps={[{"x": 83, "y": 17, "text": "Activează Ștampilă vizibilă."}, {"x": 21, "y": 49, "text": "Trage ștampila pentru poziționare și un colț pentru redimensionare."}, {"x": 83, "y": 34, "text": "Alege pagina selectată sau toate paginile; opțional, aplică setarea tuturor PDF-urilor din lot."}, {"x": 81, "y": 84, "text": "Alege Aplică pentru a reveni la lista de semnare."}]} />

## Autorizează lotul afișat

Folosește PIN-ul de semnare al cardului fizic selectat, nu parola de autentificare a Mac-ului. Oprește-te după un PIN incorect și verifică identitatea/PIN-ul înainte de o nouă încercare. Contorul încercărilor rămase protejează cardul. Un lot nou cere o nouă autorizare.

<GuideScreenshot src="/img/guide/macos/ro/pin.png" alt="Autorizează lotul afișat" steps={[{"x": 49, "y": 28, "text": "Verifică titularul și toate documentele afișate. Anulează dacă ceva nu corespunde."}, {"x": 49, "y": 51, "text": "Introdu PIN-ul cardului în câmpurile protejate."}, {"x": 49, "y": 62, "text": "Bifează Reține PIN-ul numai dacă dorești păstrarea lui în Portchei, cu deblocare prin autentificarea dispozitivului."}, {"x": 85, "y": 76, "text": "Alege Semnează după completarea PIN-ului; păstrează cititorul conectat până la final."}]} />

## Așteaptă semnarea și marca temporală

Lasă cititorul conectat în timpul semnării și obținerii mărcii temporale. Erorile de rețea/marcă temporală și fișierele nevalide diferă de un PIN incorect. Citește eroarea înainte de următorul pas.

<GuideScreenshot src="/img/guide/macos/ro/progress.png" alt="Așteaptă semnarea și marca temporală" steps={[{"x": 60, "y": 42, "text": "Așteaptă încheierea etapei curente."}]} />

## Găsește, previzualizează și partajează rezultatul

Ilustrațiile folosesc fișiere fictive; etichetele demonstrative nu apar în rezultatul obișnuit al unei semnări reale. Ediția macOS independentă scrie de obicei un fișier nou lângă sursă, cu sufix de semnare, fără a suprascrie originalul. Ediția App Store folosește stocarea permisă și acțiunile explicite de export/partajare. Păstrează XML-ul detașat împreună cu originalul.

<GuideScreenshot src="/img/guide/macos/ro/success.png" alt="Găsește, previzualizează și partajează rezultatul" steps={[{"x": 80, "y": 53, "text": "Apasă rândul finalizat sau Arată în Finder pentru a găsi rezultatul."}, {"x": 90, "y": 53, "text": "Folosește Previzualizare pentru a inspecta rezultatul. Folosește Partajează pentru PDF-ul semnat și alege destinația."}]} />

## Rezolvă o eroare de document

Un lot poate conține elemente reușite și eșuate. Păstrează rezultatele finalizate. Corectează fișierul sau conexiunea înainte de o nouă operațiune deliberată; PIN-ul nu se reîncearcă automat. Un PDF nevalid și nemodificat va eșua din nou.

<GuideScreenshot src="/img/guide/macos/ro/file-error.png" alt="Rezolvă o eroare de document" steps={[{"x": 57, "y": 54, "text": "Citește eroarea fișierului afectat; elimină-l din meniul rândului dacă este necesar."}]} />

## Verifică un PDF și fiecare semnătură

Verificarea nu cere cititor sau PIN. Ea verifică fișierul selectat, nu ștampila vizuală sau numele lui. Verificările offline nu stabilesc starea curentă de revocare a certificatului.

<GuideScreenshot src="/img/guide/macos/ro/verify.png" alt="Verifică un PDF și fiecare semnătură" steps={[{"x": 7, "y": 15, "text": "Deschide Verifică."}, {"x": 58, "y": 10, "text": "Alege fișierele semnate sau trage-le în zona punctată."}, {"x": 32, "y": 35, "text": "Extinde fiecare rând Autor, inclusiv semnăturile suplimentare ale aceluiași document."}, {"x": 35, "y": 17, "text": "Folosește Șterge rezultatele înaintea unei verificări separate."}]} />

## Citește integritatea, încrederea și detaliile certificatului

Semnătura criptografică validă, documentul intact, lanțul de încredere și marca temporală sunt verificări distincte. Derulează pentru toate câmpurile certificatului și detaliile tehnice. Numărul de înregistrare al emitentului nu este identificatorul personal al semnatarului.

<GuideScreenshot src="/img/guide/macos/ro/certificate.png" alt="Citește integritatea, încrederea și detaliile certificatului" steps={[{"x": 32, "y": 35, "text": "Extinde semnătura pentru semnatar, ora semnării și marca temporală."}, {"x": 34, "y": 57, "text": "Citește fiecare verificare de integritate, semnătură și lanț de încredere."}, {"x": 34, "y": 68, "text": "Extinde Detaliile certificatului și verifică subiectul, emitentul și cheia."}]} />

## Verifică XML-ul detașat cu originalul

Adaugă XML-ul în Verifică. Dacă amprenta documentului nu poate fi verificată, folosește acțiunea Alege originalele din rezultat. Selectează originalul exact și nemodificat, nu XML-ul semnat. Citește din nou rezultatul integrității. XML-ul singur poate fi insuficient pentru destinatar.

<GuideScreenshot src="/img/guide/macos/ro/verify-original.png" alt="Verifică XML-ul detașat cu originalul" steps={[{"x": 58, "y": 10, "text": "Adaugă semnătura XML detașată."}, {"x": 42, "y": 39, "text": "Citește rezultatul incomplet/original lipsă și furnizează originalul cerut."}]} />

## Recunoaște o semnătură nevalidă sau un document modificat

Un rezultat nevalid nu se repară prin redenumire sau adăugarea unei ștampile. Cere expeditorului o copie semnată intactă și verific-o.

<GuideScreenshot src="/img/guide/macos/ro/verify-invalid.png" alt="Recunoaște o semnătură nevalidă sau un document modificat" steps={[{"x": 43, "y": 27, "text": "Citește starea nevalidă a documentului și extinde autorul pentru verificarea eșuată."}]} />

## Deosebește încrederea neconfirmată

Încrederea neconfirmată diferă de modificarea dovedită a documentului. Citește semnătura și lanțul de încredere și urmează politica destinatarului privind certificatele.

<GuideScreenshot src="/img/guide/macos/ro/verify-untrusted.png" alt="Deosebește încrederea neconfirmată" steps={[{"x": 43, "y": 27, "text": "Citește starea de încredere neconfirmată și extinde detaliile."}]} />

## Recunoaște un document nesemnat

Imaginea unei semnături sau ștampile nu dovedește o semnătură electronică. Dacă nu este recunoscută nicio semnătură, cere rezultatul semnat efectiv, nu o captură sau copie scanată.

<GuideScreenshot src="/img/guide/macos/ro/verify-unsigned.png" alt="Recunoaște un document nesemnat" steps={[{"x": 43, "y": 27, "text": "Verifică rezultatul fără semnătură înainte de a prezenta fișierul ca semnat."}]} />

## Găsește un document semnat salvat

Documentele și Istoricul operațiunilor sunt colecții separate. Intrările indică fișiere; dacă un fișier a fost mutat sau eliminat, selectează-l din nou din noua locație pentru verificare.

<GuideScreenshot src="/img/guide/macos/ro/documents.png" alt="Găsește un document semnat salvat" steps={[{"x": 8, "y": 19, "text": "Deschide Documente și alege Documente semnate."}, {"x": 79, "y": 3, "text": "Folosește Caută documente pentru filtrare după nume."}, {"x": 45, "y": 15, "text": "Apasă rândul documentului pentru fereastra modală cu detaliile semnării."}]} />

## Inspectează și transmite un document salvat

Fereastra cu detalii folosește aceeași prezentare ca Verifică. Inspectarea unui document salvat nu înlocuiește fișierele din spațiul Verifică. Previzualizarea arată fișierul, fără a fi o validare de securitate separată.

<GuideScreenshot src="/img/guide/macos/ro/details.png" alt="Inspectează și transmite un document salvat" steps={[{"x": 31, "y": 48, "text": "Extinde autorul pentru semnătură și certificat."}, {"x": 32, "y": 60, "text": "Alege Previzualizare pentru a citi fișierul."}, {"x": 42, "y": 60, "text": "Alege Partajează pentru exportul/trimiterea rezultatului semnat."}, {"x": 54, "y": 60, "text": "Alege Arată în Finder pentru localizare; Gata închide fereastra."}]} />

## Curăță istoricul păstrând documentele

Apasă coșul, citește confirmarea și confirmă numai dacă dorești ștergerea listei de operațiuni. Acțiunea nu șterge fișierele semnate și nici colecția separată de Documente semnate. Revino la Documente semnate pentru a folosi rezultatele salvate.

<GuideScreenshot src="/img/guide/macos/ro/history.png" alt="Curăță istoricul păstrând documentele" steps={[{"x": 64, "y": 8, "text": "În Documente, selectează Istoric."}, {"x": 73, "y": 8, "text": "Apasă coșul și confirmă curățarea exclusivă a istoricului."}, {"x": 51, "y": 8, "text": "Revino la Documente semnate; colecția salvată rămâne disponibilă."}]} />

## Folosește un serviciu și gestionează marcajele

Deschide Browser din bara laterală. Introdu adresa HTTPS a unui serviciu de încredere și apasă săgeata; înapoi, înainte și reîncărcare rămân în bara de instrumente. Meniul de marcaje oferă serviciile salvate, Adaugă marcaj, Gestionează marcajele și curățarea datelor. În dialogul de mai jos introdu titlul, URL-ul și pictograma, apoi Salvează. Închide cu Gata și alege serviciul din meniul de marcaje.

<GuideScreenshot src="/img/guide/macos/ro/browser.png" alt="Folosește un serviciu și gestionează marcajele" steps={[{"x": 45, "y": 58, "text": "Introdu un titlu ușor de recunoscut."}, {"x": 47, "y": 63, "text": "Verifică adresa completă a site-ului și alege pictograma de dedesubt."}, {"x": 68, "y": 82, "text": "Alege Salvează după validarea titlului și URL-ului; Gata închide gestionarea."}]} />

## Verifică fiecare cerere de semnare de pe site

Navighează la autentificarea/semnarea cu act electronic a serviciului. Citește originea și întreaga listă de documente în eSemnBun. Nu aproba cereri neașteptate. Încrederea temporară în site este opțională și limitată; nu autorizează o listă necunoscută de documente viitoare. După aprobare, completează pasul PIN și revino la serviciu pentru rezultat.

<GuideScreenshot src="/img/guide/macos/ro/consent.png" alt="Verifică fiecare cerere de semnare de pe site" steps={[{"x": 51, "y": 16, "text": "Confirmă site-ul exact care cere semnătura."}, {"x": 49, "y": 44, "text": "Derulează toate documentele și confirmă cardul și formatul."}, {"x": 81, "y": 92, "text": "Alege Semnează numai pentru cererea așteptată sau Refuză pentru anulare."}]} />

## Configurează limba, aspectul și descoperirea în sistem

Deschide eSemnBun → Configurări (⌘,). General oferă română, engleză, rusă și limba sistemului, plus aspect luminos, întunecat sau de sistem. PIN-urile salvate au o filă separată. Ștergerea unei intrări elimină numai copia salvată; nu schimbă PIN-ul cardului fizic.

Pentru descoperirea Spotlight/Siri activează Găsește documentele semnate în Siri și Spotlight. Sunt expuse numai numele și datele PDF/XML-urilor semnate, lizibile și deținute de aplicație. Conținutul, identitatea din certificat și PIN-ul nu sunt indexate. În ediția independentă, fișierele arbitrare de lângă originale nu sunt eligibile; sunt eligibile numai importurile deținute de aplicație. Dezactivează opțiunea pentru eliminarea indexului.

<GuideScreenshot src="/img/guide/macos/ro/settings.png" alt="Configurează limba, aspectul și descoperirea în sistem" steps={[{"x": 83, "y": 24, "text": "Alege limba interfeței."}, {"x": 83, "y": 32, "text": "Alege Luminos, Întunecat sau Sistem."}, {"x": 90, "y": 41, "text": "Activează descoperirea documentelor dacă dorești numele eligibile în Siri/Spotlight."}, {"x": 32, "y": 8, "text": "Deschide PIN-uri salvate pentru a vedea sau șterge intrările fără afișarea valorilor PIN."}, {"x": 91, "y": 68, "text": "Activează cererile locale doar pentru conectarea unui client MCP; fiecare cerere necesită verificarea PDF și aprobare."}]} />

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

Indexarea Spotlight este opțională și limitată; un fișier scris lângă sursă de ediția independentă nu este automat eligibil. Capturile fictive nu demonstrează comportamentul Handoff/Spotlight între dispozitive.

## Aprobă o cerere locală de automatizare

Ediția macOS independentă oferă un broker de aprobare în prim-plan. Ediția App Store nu include acest broker.

1. În **Configurări → General → Automatizare locală**, activează **Permite cereri de semnare de la clienți locali** numai pentru un client pe care dorești să-l folosești.
2. Instalează/configurează [instrumentele CLI/MCP macOS](./macos-cli.md), alege explicit directoarele de intrare de încredere și configurează directorul privat de aprobare descris acolo.
3. Cere clientului să pregătească un PDF. Verifică previzualizarea nativă, numele/amprenta fișierului și cardul selectat în eSemnBun. Aprobă numai documentul dorit sau anulează.
4. Completează pasul PIN protejat. Clientul urmărește operațiunea și preia rezultatul final. Un rezultat în așteptare/necunoscut nu autorizează o nouă semnare.
5. Dezactivează Automatizarea locală la final pentru a respinge cererile în așteptare.

Comutatorul este vizibil în captura General de mai sus. Capturile nu ilustrează o semnătură reală prin broker sau preluarea nesupravegheată a acreditărilor. MCP nesupravegheat este o politică CLI separată și explicită, nu ocolirea ferestrei de aprobare.

## Configurările browserului și curățarea datelor

1. Deschide **Configurări → Conexiune cu browserul**. Activează răspunsurile numai când ai nevoie de conexiunea locală; Browser-ul integrat este fluxul principal al ediției Store.
2. În ediția independentă, pentru browser extern vizitează un site acceptat pe același Mac, cu eSemnBun pornit. Acordă permisiunea de rețea locală cerută de browser pentru acel flux dorit.
3. Dacă MoldSign recunoscut ocupă porturile, finalizează operațiunea sa, apoi folosește acțiunea oferită de închidere/reconectare. Pentru un deținător necunoscut, rezolvă conflictul înainte de reîncercare. Nu ocoli avertismentele browserului privind certificatele.
4. În **Browser → meniul de marcaje → Șterge datele de navigare**, selectează memoria cache, cookie-urile și/sau istoricul și confirmă. Ștergerea cookie-urilor poate închide sesiunile. Documentele și PIN-urile salvate rămân.

Ștampilele PDF pentru browser și accesul pentru clienți desktop vechi au preferințe separate în Conexiune cu browserul. Activează accesul vechi numai pentru software-ul pe care vrei să-l folosești. Vezi [ghidul browserului](/docs/browser).

## Bara de meniu, pornirea, actualizările și ajutorul

1. Apasă pictograma eSemnBun din bara de meniu pentru fereastra principală, Configurări sau Despre. Închiderea ferestrei poate lăsa aplicația activă; alege **Ieșire** pentru oprire.
2. În **Configurări → General**, derulează la opțiunile de pornire. Activează **Pornește la autentificare** dacă dorești. Aprobările macOS sunt în **Configurări sistem → General → Elemente de autentificare**.
3. Ediția independentă are un ajutor opțional pentru inserarea cititorului/cardului, care poate porni aplicația după închidere. Activează-l și aprobă elementul de fundal dacă este cerut. Ediția Store oferă deschiderea ferestrei la inserare cât timp aplicația este pornită.
4. Pentru ediția independentă, folosește **Caută actualizări** și instalează DMG-ul nou. Copiile App Store se actualizează prin magazin. Păstrează același canal de distribuție.
5. În **Despre eSemnBun** găsești versiunea instalată; folosește Ajutor sau [Suport](/support), indicând versiunile aplicației/macOS, cititorul/adaptorul și pașii de reproducere. Nu trimite PIN-ul.

Modul demonstrativ normal este o opțiune intenționată în Configurări, cu date fictive și avertisment vizibil; nu produce semnături electronice valide. Captura pentru documentație ascunde bannerul numai în scenarii Debug izolate.

## Rezolvă problemele în siguranță

| Ce vezi | Acțiunea următoare |
| --- | --- |
| Niciun cititor | Reconectează cititorul/adaptorul compatibil; încearcă USB direct. |
| Cititor detectat, fără card | Introdu/reintrodu cardul și așteaptă certificatul. |
| Eroare de citire | Reintrodu cardul și citește eroarea înaintea altei operațiuni. |
| Titular greșit | Selectează cardul corect înainte de PIN. |
| PIN incorect / puține încercări | Oprește-te și confirmă PIN-ul; încercările repetate pot bloca cardul. |
| Fișier mutat / indisponibil | Selectează noua locație; lipsa fișierului nu este semnătură nevalidă. |
| Ediția Store nu scrie lângă sursă | Folosește destinația Export/Partajare. |
| Niciun rezultat Spotlight | Verifică activarea, apartenența la aplicație, accesul și timpul de indexare. |

Pentru automatizare în terminal, instalare prin manager de pachete și politici nesupravegheate, continuă cu [ghidul CLI macOS](./macos-cli.md).
