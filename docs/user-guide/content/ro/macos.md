---
title: "macOS — ghid ilustrat pentru desktop"
sidebar_position: 2
---

import GuideScreenshot from '@site/src/components/GuideScreenshot';

# macOS — ghid ilustrat pentru desktop

Pentru eSemnBun 0.2.12 pe macOS 15 sau mai nou. Urmează câte un obiectiv; numerele din imagini corespund instrucțiunilor de sub ele. Apasă imaginea pentru captura la dimensiune completă.

## Instalează aplicația și conectează cititorul

Deschide [Descărcări](/downloads/). Instalează ediția Mac App Store sau deschide DMG-ul pentru desktop și trage eSemnBun în Aplicații. Ejectează DMG-ul și pornește copia instalată. Arhiva TAR.GZ și Homebrew oferă instrumentele CLI/MCP; vezi [ghidul pentru terminal](./macos-cli.md).

Ai nevoie de macOS 15 sau mai nou, un cititor USB compatibil, un act electronic acceptat și activ și PIN-ul său de semnare. Folosește un adaptor USB-C adecvat, dacă este necesar. Semnarea prin NFC nu este disponibilă.

Atât ediția Mac App Store, cât și ediția independentă detectează cititoarele USB compatibile și cardurile introduse cât timp eSemnBun este pornit. Ediția Mac App Store permite și folosirea site-urilor compatibile într-un browser extern; Browser-ul integrat este opțional.

<GuideScreenshot src="/img/guide/macos/ro/connect.png" alt="Instalează aplicația și conectează cititorul" steps={[{"x": 5, "y": 7, "text": "Deschide Semnează în bara laterală."}, {"x": 59, "y": 17, "text": "Conectează cititorul USB. Ecranul se schimbă după detectarea lui."}]} />

## Introdu cardul

Certificatul se citește fără PIN. Așteaptă afișarea titularului și a expirării înainte de semnare. Cheia privată de semnare rămâne pe card.

<GuideScreenshot src="/img/guide/macos/ro/empty-reader.png" alt="Introdu cardul" steps={[{"x": 59, "y": 18, "text": "Introdu cardul în cititorul detectat și lasă-l conectat."}]} />

## Alege identitatea și verifică certificatul

Imaginea cardului folosește datele certificatului și un avatar neutru, nu fotografia citită din act. Pentru a reciti cardul, folosește butonul din dreapta sus sau meniul contextual al cardului. Nu porni o altă operațiune în timpul uneia active.

<GuideScreenshot src="/img/guide/macos/ro/cards-current.png" alt="Deschide Setări și alege Carduri și cititoare pentru a consulta titularul, certificatul și cititorul conectat." steps={[{"text": "Deschide Setări și alege Carduri și cititoare pentru a consulta titularul, certificatul și cititorul conectat.", "x": 25, "y": 42}, {"text": "Alege titularul dorit din carusel înainte de a semna."}]} />

## Adaugă documentele și alege formatul

Un PDF folosește în mod normal PAdES-T: semnătura rămâne în PDF. Alte fișiere folosesc de obicei XAdES-T detașat: păstrează XML-ul împreună cu originalul nemodificat. Folosește controlul de format al fișierului dacă destinatarul cere un alt format acceptat. Meniul rândului permite eliminarea unui fișier adăugat din greșeală.

<GuideScreenshot src="/img/guide/macos/ro/sign.png" alt="Adaugă documentele și alege formatul" steps={[{"x": 5, "y": 7, "text": "Deschide Semnează."}, {"x": 67, "y": 47, "text": "Alege fișiere sau trage-le în zona punctată. Adaugă întregul lot înainte de semnare."}, {"x": 40, "y": 41, "text": "Verifică numele și formatul fiecărui fișier. Controlul ștampilei PDF este lângă format."}, {"x": 92, "y": 96, "text": "Verifică cardul selectat, apoi apasă butonul flotant Semnează din dreapta jos sau ⌘Return. Butonul arată numărul documentelor și rămâne vizibil în timpul derulării."}]} />

## Aplică o ștampilă vizibilă pe PDF

Deschide controlul Ștampilă oprită/Editează ștampila al unui PDF din listă. Ștampila vizibilă este opțională și nu înlocuiește semnătura criptografică. Pentru un PDF cu mai multe pagini, selectează pagina în previzualizare.

Textul ștampilei urmează limba aleasă în aplicație (română, engleză sau rusă).

<GuideScreenshot src="/img/guide/macos/ro/stamp.png" alt="Aplică o ștampilă vizibilă pe PDF" steps={[{"x": 95, "y": 6, "text": "Activează Ștampilă vizibilă."}, {"x": 12, "y": 50, "text": "Trage ștampila pentru poziționare și un colț pentru redimensionare."}, {"x": 94, "y": 29, "text": "Alege pagina selectată sau toate paginile; opțional, aplică setarea tuturor PDF-urilor din lot."}, {"x": 92, "y": 95, "text": "Alege Aplică pentru a reveni la lista de semnare."}]} />

## Autorizează lotul afișat

Folosește PIN-ul de semnare al cardului fizic selectat, nu parola de autentificare a Mac-ului. Oprește-te după un PIN incorect și verifică identitatea/PIN-ul înainte de o nouă încercare. Contorul încercărilor rămase protejează cardul. Un lot nou cere o nouă autorizare.

<GuideScreenshot src="/img/guide/macos/ro/pin.png" alt="Autorizează lotul afișat" steps={[{"x": 50, "y": 32, "text": "Verifică titularul și toate documentele afișate. Anulează dacă ceva nu corespunde."}, {"x": 50, "y": 60, "text": "Introdu PIN-ul cardului în câmpurile protejate."}, {"x": 78, "y": 85, "text": "Bifează Reține PIN-ul numai dacă dorești păstrarea lui în Portchei, cu deblocare prin autentificarea dispozitivului."}, {"x": 85, "y": 76, "text": "Alege Semnează după completarea PIN-ului; păstrează cititorul conectat până la final."}]} />

## Așteaptă semnarea și marca temporală

Lasă cititorul conectat în timpul semnării și obținerii mărcii temporale. Erorile de rețea/marcă temporală și fișierele nevalide diferă de un PIN incorect. Citește eroarea înainte de următorul pas.

<GuideScreenshot src="/img/guide/macos/ro/progress.png" alt="Așteaptă semnarea și marca temporală" steps={[{"x": 59, "y": 36, "text": "Așteaptă încheierea etapei curente."}]} />

## Găsește, previzualizează și partajează rezultatul

Ediția macOS independentă scrie de obicei un fișier nou lângă sursă, cu sufix de semnare, fără a suprascrie originalul. Ediția App Store folosește stocarea permisă și acțiunile explicite de export/partajare. Păstrează XML-ul detașat împreună cu originalul.

În versiunea 0.2.13 din Mac App Store poți alege un dosar în **Configurări → General → Documente** pentru copiile automate ale documentelor semnate. Alege dosarul în dialogul sistemului pentru a acorda acces.

<GuideScreenshot src="/img/guide/macos/ro/export-folder.png" alt="Alege un dosar pentru copiile automate ale documentelor semnate în ediția Mac App Store." steps={[{"text": "Alege un dosar pentru copiile automate ale documentelor semnate în ediția Mac App Store.", "x": 15, "y": 93}]} />

<GuideScreenshot src="/img/guide/macos/ro/success.png" alt="Alege Previzualizare lângă numele fișierului semnat. Comenzile alăturate salvează o copie, partajează documentul sau îl afișează în Finder." steps={[{"text": "Alege Previzualizare lângă numele fișierului semnat. Comenzile alăturate salvează o copie, partajează documentul sau îl afișează în Finder.", "x": 69, "y": 69}]} />

## Rezolvă o eroare de document

Un lot poate conține elemente reușite și eșuate. Păstrează rezultatele finalizate. Corectează fișierul sau conexiunea înainte de o nouă operațiune deliberată; PIN-ul nu se reîncearcă automat. Un PDF nevalid și nemodificat va eșua din nou.

<GuideScreenshot src="/img/guide/macos/ro/file-error.png" alt="Rezolvă o eroare de document" steps={[{"x": 42, "y": 41, "text": "Citește eroarea fișierului afectat; elimină-l din meniul rândului dacă este necesar."}]} />

## Verifică un PDF și fiecare semnătură

Verificarea nu cere cititor sau PIN. Ea verifică fișierul selectat, nu ștampila vizuală sau numele lui. Verificările offline nu stabilesc starea curentă de revocare a certificatului.

<GuideScreenshot src="/img/guide/macos/ro/verify.png" alt="Consultă întâi rezultatul pentru document. Deschide fiecare semnatar pentru a-i examina semnătura." steps={[{"text": "Consultă întâi rezultatul pentru document. Deschide fiecare semnatar pentru a-i examina semnătura.", "x": 37, "y": 46}]} />

## Citește integritatea, încrederea și detaliile certificatului

Semnătura criptografică validă, documentul intact, lanțul de încredere și marca temporală sunt verificări distincte. Derulează pentru toate câmpurile certificatului și detaliile tehnice. Numărul de înregistrare al emitentului nu este identificatorul personal al semnatarului.

<GuideScreenshot src="/img/guide/macos/ro/certificate.png" alt="Deschide Detaliile certificatului pentru a consulta certificatul public al semnatarului, emitentul și amprenta." steps={[{"text": "Deschide Detaliile certificatului pentru a consulta certificatul public al semnatarului, emitentul și amprenta.", "x": 40, "y": 45}]} />

<GuideScreenshot src="/img/guide/macos/ro/technical.png" alt="Deschide Detalii tehnice sub o semnătură pentru a citi raportul de verificare. Apasă din nou pe rând pentru a-l restrânge." steps={[{"text": "Deschide Detalii tehnice sub o semnătură pentru a citi raportul de verificare. Apasă din nou pe rând pentru a-l restrânge.", "x": 38, "y": 87}]} />

## Verifică XML-ul detașat cu originalul

Adaugă XML-ul în Verifică. Dacă amprenta documentului nu poate fi verificată, folosește acțiunea Alege originalele din rezultat. Selectează originalul exact și nemodificat, nu XML-ul semnat. Citește din nou rezultatul integrității. XML-ul singur poate fi insuficient pentru destinatar.

<GuideScreenshot src="/img/guide/macos/ro/verify-original.png" alt="Verifică XML-ul detașat cu originalul" steps={[{"x": 38, "y": 35, "text": "Adaugă semnătura XML detașată."}, {"x": 41, "y": 53, "text": "Citește rezultatul incomplet/original lipsă și furnizează originalul cerut."}]} />

## Recunoaște o semnătură nevalidă sau un document modificat

Un rezultat nevalid nu se repară prin redenumire sau adăugarea unei ștampile. Cere expeditorului o copie semnată intactă și verific-o.

<GuideScreenshot src="/img/guide/macos/ro/verify-invalid.png" alt="Recunoaște o semnătură nevalidă sau un document modificat" steps={[{"x": 39, "y": 38, "text": "Citește starea nevalidă a documentului și extinde autorul pentru verificarea eșuată."}]} />

## Deosebește încrederea neconfirmată

Încrederea neconfirmată diferă de modificarea dovedită a documentului. Citește semnătura și lanțul de încredere și urmează politica destinatarului privind certificatele.

<GuideScreenshot src="/img/guide/macos/ro/verify-untrusted.png" alt="Deosebește încrederea neconfirmată" steps={[{"x": 54, "y": 40, "text": "Citește starea de încredere neconfirmată și extinde detaliile."}]} />

## Recunoaște un document nesemnat

Imaginea unei semnături sau ștampile nu dovedește o semnătură electronică. Dacă nu este recunoscută nicio semnătură, cere rezultatul semnat efectiv, nu o captură sau copie scanată.

<GuideScreenshot src="/img/guide/macos/ro/verify-unsigned.png" alt="Recunoaște un document nesemnat" steps={[{"x": 45, "y": 40, "text": "Verifică rezultatul fără semnătură înainte de a prezenta fișierul ca semnat."}]} />

## Găsește un document semnat salvat

Documente salvate conține rezultate semnate, criptate și decriptate. Selectează un fișier semnat pentru detaliile semnăturii. Un fișier criptat oferă decriptarea; conținutul criptat nu este trimis la verificarea semnăturii. Fișierele decriptate își păstrează tipul rezultatului și pot fi deschise sau exportate.

Documentele și Istoricul operațiunilor sunt colecții separate. Intrările indică fișiere; dacă un fișier a fost mutat sau eliminat, selectează-l din nou din noua locație pentru verificare.

<GuideScreenshot src="/img/guide/macos/ro/documents.png" alt="Selectează numele unui fișier pentru a-i examina semnăturile. Folosește acțiunile de lângă nume pentru a-l previzualiza sau partaja." steps={[{"text": "Selectează numele unui fișier pentru a-i examina semnăturile. Folosește acțiunile de lângă nume pentru a-l previzualiza sau partaja.", "x": 86, "y": 21}]} />

## Inspectează și transmite un document salvat

Fereastra cu detalii folosește aceeași prezentare ca Verifică. Inspectarea unui document salvat nu înlocuiește fișierele din spațiul Verifică. Previzualizarea arată fișierul, fără a fi o validare de securitate separată.

<GuideScreenshot src="/img/guide/macos/ro/details.png" alt="Deschide rândul unui semnatar pentru a vedea verificările. Sub raport poți alege Previzualizare sau Partajează." steps={[{"text": "Deschide rândul unui semnatar pentru a vedea verificările. Sub raport poți alege Previzualizare sau Partajează.", "x": 16, "y": 71}]} />

## Curăță istoricul păstrând documentele

Apasă coșul, citește confirmarea și confirmă numai dacă dorești ștergerea listei de operațiuni. Acțiunea nu șterge fișierele semnate și nici colecția separată de Documente salvate. Revino la Documente salvate pentru a folosi rezultatele salvate.

<GuideScreenshot src="/img/guide/macos/ro/history.png" alt="În Istoric găsești numele fișierului, rezultatul și data. Deschide Documente salvate pentru a folosi fișierul rezultat." steps={[{"text": "În Istoric găsești numele fișierului, rezultatul și data. Deschide Documente salvate pentru a folosi fișierul rezultat.", "x": 42, "y": 11}]} />

## Folosește un serviciu și gestionează marcajele

Deschide Browser din bara laterală. Introdu adresa HTTPS a unui serviciu de încredere și apasă săgeata; înapoi, înainte și reîncărcare rămân în bara de instrumente. Meniul de marcaje oferă serviciile salvate, Adaugă marcaj, Gestionează marcajele și curățarea datelor. În dialogul de mai jos introdu titlul, URL-ul și pictograma, apoi Salvează. Închide cu Gata și alege serviciul din meniul de marcaje.

<GuideScreenshot src="/img/guide/macos/ro/browser.png" alt="Folosește un serviciu și gestionează marcajele" steps={[{"x": 51, "y": 57, "text": "Introdu un titlu ușor de recunoscut."}, {"x": 48, "y": 60, "text": "Verifică adresa completă a site-ului și alege pictograma de dedesubt."}, {"x": 65, "y": 75, "text": "Alege Salvează după validarea titlului și URL-ului; Gata închide gestionarea."}]} />

## Verifică fiecare cerere de semnare de pe site

Navighează la autentificarea/semnarea cu act electronic a serviciului. Citește originea și întreaga listă de documente în eSemnBun. Nu aproba cereri neașteptate. Încrederea temporară în site este opțională și limitată; nu autorizează o listă necunoscută de documente viitoare. După aprobare, completează pasul PIN și revino la serviciu pentru rezultat.

<GuideScreenshot src="/img/guide/macos/ro/consent.png" alt="Verifică fiecare cerere de semnare de pe site" steps={[{"x": 51, "y": 16, "text": "Confirmă site-ul exact care cere semnătura."}, {"x": 49, "y": 44, "text": "Derulează toate documentele și confirmă cardul și formatul."}, {"x": 81, "y": 92, "text": "Alege Semnează numai pentru cererea așteptată sau Refuză pentru anulare."}]} />

## Configurează limba, aspectul și descoperirea în sistem

Deschide Setări. Modul demonstrativ este sus. Alege categoria pentru carduri, PIN-uri salvate, limbă sau aspect.

Pentru descoperirea Spotlight/Siri activează Găsește documentele semnate în Siri și Spotlight. Sunt expuse numai numele și datele PDF/XML-urilor semnate, lizibile și deținute de aplicație. Conținutul, identitatea din certificat și PIN-ul nu sunt indexate. În ediția independentă, fișierele arbitrare de lângă originale nu sunt eligibile; sunt eligibile numai importurile deținute de aplicație. Dezactivează opțiunea pentru eliminarea indexului.

<GuideScreenshot src="/img/guide/macos/ro/settings.png" alt="Alege limba interfeței." steps={[{"text": "Alege limba interfeței.", "x": 87, "y": 61}, {"text": "Alege aspectul aplicației.", "x": 88, "y": 69}, {"text": "Poți activa descoperirea documentelor semnate în Siri și Spotlight.", "x": 86, "y": 85}]} />

<GuideScreenshot src="/img/guide/macos/ro/saved-cards.png" alt="În Setări vezi cardurile salvate chiar și după deconectarea cititorului. Uită cardul elimină identitatea și PIN-ul ei salvat de pe acest dispozitiv." steps={[{"text": "În Setări vezi cardurile salvate chiar și după deconectarea cititorului. Uită cardul elimină identitatea și PIN-ul ei salvat de pe acest dispozitiv.", "x": 87, "y": 37}]} />

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
2. Instalează/configurează [instrumentele CLI/MCP macOS](./macos-cli.md), alege explicit directoarele de intrare de încredere și configurează directorul privat de aprobare descris acolo.
3. Cere clientului să pregătească un PDF. Verifică previzualizarea nativă, numele/amprenta fișierului și cardul selectat în eSemnBun. Aprobă numai documentul dorit sau anulează.
4. Completează pasul PIN protejat. Clientul urmărește operațiunea și preia rezultatul final. Un rezultat în așteptare/necunoscut nu autorizează o nouă semnare.
5. Dezactivează Automatizarea locală la final pentru a respinge cererile în așteptare.

Comutatorul este vizibil în captura General de mai sus. Capturile nu ilustrează o semnătură reală prin broker sau preluarea nesupravegheată a acreditărilor. MCP nesupravegheat este o politică CLI separată și explicită, nu ocolirea ferestrei de aprobare.

## Configurările browserului și curățarea datelor

1. Deschide **Configurări → Conexiune cu browserul** și activează răspunsurile când ai nevoie de conexiunea locală. Atât ediția Mac App Store, cât și ediția independentă permit Browser-ul integrat și browserele externe compatibile.
2. Pentru un browser extern, lasă eSemnBun pornit pe același Mac, conectează cititorul USB, introdu cardul și așteaptă afișarea identității. Vizitează un site acceptat și acordă permisiunea de rețea locală cerută de browser pentru acel flux dorit. Verifică site-ul și identitatea selectată în eSemnBun înainte de a aproba o cerere.
3. Dacă MoldSign ocupă porturile, finalizează operațiunea sa și închide-l. Ediția independentă poate oferi o acțiune de închidere/reconectare; în ediția Mac App Store, închide tu aplicația care ocupă porturile, apoi reîncearcă conexiunea. Pentru un deținător necunoscut, rezolvă conflictul înainte de reîncercare. Nu ocoli avertismentele browserului privind certificatele.
4. În **Browser → meniul de marcaje → Șterge datele de navigare**, selectează memoria cache, cookie-urile și/sau istoricul și confirmă. Ștergerea cookie-urilor poate închide sesiunile. Documentele și PIN-urile salvate rămân.

Ștampilele PDF pentru browser au propria preferință în Conexiune cu browserul. Ediția independentă oferă și acces pentru clienți desktop vechi; activează-l numai pentru software-ul pe care vrei să-l folosești. Ediția Mac App Store nu acceptă cereri din browser care conțin căi arbitrare către fișiere locale. Vezi [ghidul browserului](/docs/browser).

## Bara de meniu, pornirea, actualizările și ajutorul

1. Apasă pictograma eSemnBun din bara de meniu pentru fereastra principală, Configurări sau Despre. Închiderea ferestrei poate lăsa aplicația activă; alege **Ieșire** pentru oprire.
2. În **Configurări → General**, derulează la opțiunile de pornire. Activează **Pornește la autentificare** dacă dorești. Aprobările macOS sunt în **Configurări sistem → General → Elemente de autentificare**.
3. În ediția independentă, activează **Deschide aplicația la conectarea cititorului sau introducerea cardului** la prima lansare sau în **Configurări → General** și aprobă elementul de fundal în configurările sistemului dacă macOS o cere. Un utilitar separat deschide apoi eSemnBun la introducerea cardului, chiar și după ieșire. Ediția Mac App Store nu poate face acest lucru: fereastra se deschide la introducerea cardului doar cât timp eSemnBun rulează în bara de meniu. După ieșire, redeschide aplicația manual sau alege **Pornește la autentificare** pentru ca ea să ruleze după ce te autentifici.
4. Pentru ediția independentă, folosește **Caută actualizări** și instalează DMG-ul nou. Copiile App Store se actualizează prin magazin. Păstrează același canal de distribuție.
5. În **Despre eSemnBun** găsești versiunea instalată; folosește Ajutor sau [Suport](/support), indicând versiunile aplicației/macOS, cititorul/adaptorul și pașii de reproducere. Nu trimite PIN-ul.

<GuideScreenshot src="/img/guide/macos/ro/onboarding.png" alt="Alege dacă aplicația pornește la autentificare sau se deschide la conectarea cititorului ori introducerea cardului. Poți schimba opțiunile mai târziu." steps={[{"text": "Alege dacă aplicația pornește la autentificare sau se deschide la conectarea cititorului ori introducerea cardului. Poți schimba opțiunile mai târziu.", "x": 36, "y": 55}]} />

<GuideScreenshot src="/img/guide/macos/ro/menu-bar.png" alt="Deschide eSemnBun din bara de meniu pentru a verifica starea cardului și a accesa documentele recente." steps={[{"text": "Deschide eSemnBun din bara de meniu pentru a verifica starea cardului și a accesa documentele recente.", "x": 23, "y": 55}]} />

Modul demonstrativ normal este o opțiune intenționată în Configurări, cu date fictive și avertisment vizibil; nu produce semnături electronice valide.

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

<!-- file-protection-guides -->


## Criptează un fișier cu parolă

În **Documente**, alege **Protejează fișiere** din bara de instrumente. În formular, alege **Criptează** sau **Decriptează**, apoi un fișier accesibil.

Nu ai nevoie de card. Creează o parolă pentru fișier și transmite-o destinatarului printr-un canal de încredere separat. Nu este PIN-ul cardului. Criptarea creează un rezultat separat; păstrează originalul până verifici rezultatul.

În versiunea 0.2.13, alege **Parolă** și selectează AES-128, AES-192 sau AES-256. Opțiunea implicită este AES-256. Pentru a cripta pentru un destinatar, alege **Certificat RSA** și selectează certificatul său public de criptare (.cer sau .der). Implicit, folosește un certificat destinat criptării. **Compatibilitate cu cheia publică a cardului** permite explicit cheia RSA publică a cardului. Exportul sau criptarea reușită nu dovedesc că acel card poate decripta; cardul corespunzător trebuie să permită operația necesară cu cheia privată.

<GuideScreenshot src="/img/guide/macos/ro/documents-protection-light.png" alt="În Documente, deschide Protejează fișiere din bara de instrumente apăsând scutul." steps={[{"text": "În Documente, deschide Protejează fișiere din bara de instrumente apăsând scutul.", "x": 89, "y": 11}]} />

<GuideScreenshot src="/img/guide/macos/ro/protect-password-light.png" alt="Selectează fișierul sursă și Parolă. Alege dimensiunea cheii AES, introdu și confirmă parola, apoi apasă Criptează." steps={[{"text": "Selectează fișierul sursă și Parolă. Alege dimensiunea cheii AES, introdu și confirmă parola, apoi apasă Criptează.", "x": 83, "y": 57}]} />

<GuideScreenshot src="/img/guide/macos/ro/protect-certificate-light.png" alt="Alege Certificat RSA, apoi selectează certificatul public de criptare al destinatarului. Criptarea nu cere PIN-ul destinatarului." steps={[{"text": "Alege Certificat RSA, apoi selectează certificatul public de criptare al destinatarului. Criptarea nu cere PIN-ul destinatarului.", "x": 29.2, "y": 60.7}, {"text": "Folosește Compatibilitate cu cheia publică a cardului doar când fluxul cere cheia RSA publică a cardului.", "x": 30.8, "y": 49.1}]} />

<GuideScreenshot src="/img/guide/macos/ro/protect-complete-light.png" alt="Rezultatul este salvat în Documente. Alege Salvează o copie pentru export sau Gata pentru a reveni." steps={[{"text": "Rezultatul este salvat în Documente. Alege Salvează o copie pentru export sau Gata pentru a reveni.", "x": 52, "y": 66}]} />

Alege **Criptează** sau **Decriptează**. Rezultatul nou este salvat automat în **Documente → Documente salvate**. Alege **Gata** pentru a reveni sau **Salvează o copie** pentru a-l exporta în Fișiere ori în alt loc. Originalul este păstrat.

Documente salvate include fișiere semnate, criptate și decriptate. Identifică rezultatul după numele fișierului și eticheta operațiunii. Criptarea nu creează o semnătură digitală; fișierele criptate trebuie decriptate înainte de deschiderea sau verificarea conținutului.


## Decriptează un fișier primit

În **Documente**, alege **Protejează fișiere** din bara de instrumente. În formular, alege **Criptează** sau **Decriptează**, apoi un fișier accesibil.

Pentru un fișier criptat cu parolă, cere parola expeditorului printr-un canal de încredere separat. Fișierul specifică dimensiunea cheii AES. Pentru fișierele RSA, în versiunea 0.2.13 conectează cardul care conține cheia de criptare a destinatarului, citește cardul și autorizează decriptarea cu PIN-ul său.

<GuideScreenshot src="/img/guide/macos/ro/documents-protection-light.png" alt="În Documente, deschide Protejează fișiere din bara de instrumente apăsând scutul." steps={[{"text": "În Documente, deschide Protejează fișiere din bara de instrumente apăsând scutul.", "x": 89, "y": 11}]} />

<GuideScreenshot src="/img/guide/macos/ro/protect-decrypt-light.png" alt="Selectează fișierul criptat. Când apare Parolă, introdu parola primită separat de la expeditor și apasă Decriptează." steps={[{"text": "Selectează fișierul criptat. Când apare Parolă, introdu parola primită separat de la expeditor și apasă Decriptează.", "x": 92, "y": 50}]} />

<GuideScreenshot src="/img/guide/macos/ro/protect-rsa-decrypt.png" alt="Pentru un fișier RSA, conectează cititorul și cardul destinatarului, apoi alege Citește cardul meu. Autorizează cu PIN-ul cardului." steps={[{"text": "Pentru un fișier RSA, conectează cititorul și cardul destinatarului, apoi alege Citește cardul meu. Autorizează cu PIN-ul cardului.", "x": 21.2, "y": 60.1}]} />

<GuideScreenshot src="/img/guide/macos/ro/protect-decrypt-complete-light.png" alt="Rezultatul este salvat în Documente. Alege Salvează o copie pentru export sau Gata pentru a reveni." steps={[{"text": "Rezultatul este salvat în Documente. Alege Salvează o copie pentru export sau Gata pentru a reveni.", "x": 50, "y": 66}]} />

Deschide și verifică rezultatul salvat înainte de utilizare. Criptarea compatibilă MoldSign nu autentifică conținutul: decriptarea reușită nu dovedește singură integritatea sau parola corectă.

Alege **Criptează** sau **Decriptează**. Rezultatul nou este salvat automat în **Documente → Documente salvate**. Alege **Gata** pentru a reveni sau **Salvează o copie** pentru a-l exporta în Fișiere ori în alt loc. Originalul este păstrat.

Documente salvate include fișiere semnate, criptate și decriptate. Identifică rezultatul după numele fișierului și eticheta operațiunii. Criptarea nu creează o semnătură digitală; fișierele criptate trebuie decriptate înainte de deschiderea sau verificarea conținutului.


## Elimină un fișier local

În **Documente**, alege **Protejează fișiere** din bara de instrumente. Alege **Elimină fișierul** și selectează fișierul de eliminat.

Doar pe desktop. Operațiunea elimină definitiv un fișier local obișnuit acceptat, după confirmare. Nu garantează ștergerea de pe SSD, din instantanee, copii de rezervă sau alte copii. Locațiile neacceptate și legăturile sunt refuzate. Furnizorii de documente mobili nu acceptă operațiunea.

<GuideScreenshot src="/img/guide/macos/ro/protect-remove-light.png" alt="Verifică numele exact înainte să alegi Elimină fișierul. Aplicația îți cere confirmarea înainte de eliminare." steps={[{"text": "Verifică numele exact înainte să alegi Elimină fișierul. Aplicația îți cere confirmarea înainte de eliminare.", "x": 50, "y": 86}]} />
