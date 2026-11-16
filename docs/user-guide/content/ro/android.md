---
title: Telefon Android
sidebar_position: 4
---

import GuideScreenshot from '@site/src/components/GuideScreenshot';

# Telefon Android

Începând cu eSemnBun 0.2.12, poți semna prin NFC de pe un iPhone sau dispozitiv Android compatibil, cu un card fără contact compatibil. Poți folosi și un cititor USB compatibil. Ai nevoie de o carte de identitate electronică moldovenească activă, cu certificat de semnare valabil și PIN-ul de semnare. Instalează sau actualizează aplicația prin canalul dispozitivului din [Descărcări](/downloads).

Cercurile numerotate indică comenzile din fiecare parcurs. Atinge o imagine pentru mărire.

Bara de jos deschide Semnează, Verifică, Documente, Browser și Setări. În peisaj larg, aplicația poate afișa navigarea laterală și cardul lângă fișiere. Ferestrele înguste păstrează navigarea compactă. Vezi [ghidul tabletei](./android-tablet.md) pentru spațiul extins.

## 1. Conectează cititorul și cardul

Ai nevoie de o carte de identitate electronică moldovenească activă, cu certificat de semnare valabil și PIN-ul de semnare.

### Semnează prin NFC

Începând cu eSemnBun 0.2.12, poți semna prin NFC de pe un iPhone sau dispozitiv Android compatibil, cu un card fără contact compatibil. Poți folosi și un cititor USB compatibil. Alege **Cu telefonul · NFC** în **Semnează** și adaugă documentul. Apasă **Continuă**, verifică cererea și confirmă PIN-ul de semnare. Ține cardul lângă antena NFC a dispozitivului până când aplicația confirmă finalizarea. Pe Android trebuie să activezi NFC.

<GuideScreenshot src="/img/guide/android-phone/ro/nfc-sign.png" alt="Ecranul Semnează cu opțiunea NFC selectată" steps={[{"text": "Ecranul Semnează cu opțiunea NFC selectată", "x": 29, "y": 53}]} />

### Semnează cu un cititor USB

Pentru USB, conectează cititorul prin [adaptorul](/devices) potrivit, alege **Cu un cititor de carduri** în **Semnează** și introdu cardul. Dacă sunt mai multe carduri conectate, selectează titularul dorit înainte de a continua.

<GuideScreenshot src="/img/guide/android-phone/ro/reader-sign.png" alt="Ecranul Semnează cu cititorul de carduri USB selectat" steps={[{"text": "Ecranul Semnează cu cititorul de carduri USB selectat", "x": 29, "y": 53}]} />

## 2. Adaugă fișiere și pregătește un lot

### Alege cum semnezi

Alege **Cu telefonul · NFC** în **Semnează** și adaugă documentul. Apasă **Continuă**, verifică cererea și confirmă PIN-ul de semnare. Ține cardul lângă antena NFC a dispozitivului până când aplicația confirmă finalizarea. Pe Android trebuie să activezi NFC.

Pentru USB, conectează cititorul prin [adaptorul](/devices) potrivit, alege **Cu un cititor de carduri** în **Semnează** și introdu cardul. Dacă sunt mai multe carduri conectate, selectează titularul dorit înainte de a continua. Cu un cititor USB, lasă cititorul conectat și cardul introdus până se finalizează semnarea și aplicarea mărcii temporale.

Păstrează cititorul conectat până apar toate rezultatele. Originalul rămâne separat de fișierul semnat. Poți distribui documente din Fișiere sau altă aplicație către eSemnBun.

<GuideScreenshot src="/img/guide/android-phone/ro/sign.png" alt="Adaugă fișiere și pregătește un lot" steps={[{"text": "Glisează la cardul dorit și verifică indicatorul Folosit pentru semnare.", "x": 9.1, "y": 19.5}, {"text": "Atinge Adaugă documente și selectează unul sau mai multe fișiere în selectorul sistemului. Descarcă mai întâi fișierele din cloud dacă nu sunt disponibile.", "x": 14.1, "y": 65.1}, {"text": "Extinde Arată fișierele pentru a verifica fiecare nume. Folosește meniul lotului pentru setări comune sau meniul rândului pentru un fișier.", "x": 13.6, "y": 58.5}, {"text": "Atinge Semnează după verificarea cardului și a întregii liste.", "x": 53, "y": 84}]} />

## 3. Alege semnătura PDF sau XML

Semnătura PDF (PAdES-T) este inclusă în PDF. XAdES creează XML: păstrează originalul împreună cu semnătura detașată. Formatele cu marcă temporală sau date de validare au nevoie de serviciile de încredere. Ștampila vizibilă este opțională și nu înlocuiește semnătura digitală.

<GuideScreenshot src="/img/guide/android-phone/ro/format.png" alt="Alege semnătura PDF sau XML" steps={[{"text": "Deschide meniul cu trei puncte al fișierului. Alege formatul semnăturii sau elimină fișierul adăugat greșit.", "x": 50.4, "y": 22.8}, {"text": "Pentru PDF, activează ștampila vizibilă dacă vrei să o poziționezi înainte de aprobare. Semnarea XML produce aici o semnătură detașată; păstrează originalul."}]} />

## 4. Poziționează ștampila vizibilă

Editorul de poziționare se deschide înainte de solicitarea PIN-ului, când ștampila este activată. Nu acoperi textul important.

Etichetele ștampilei urmează limba aplicației aleasă în setările General.

<GuideScreenshot src="/img/guide/android-phone/ro/stamp.png" alt="Poziționează ștampila vizibilă" steps={[{"text": "Trage ștampila pe pagină; ajustează dimensiunea cu mânerele din colțuri.", "x": 38, "y": 58}, {"text": "Folosește săgețile paginii, apoi alege O pagină, Toate paginile sau Oprit.", "x": 41.3, "y": 80.6}, {"text": "Alege dacă poziția se aplică tuturor PDF-urilor din lot și atinge Aplică. Anulează revine fără aprobarea semnării.", "x": 81.7, "y": 93.0}]} />

## 5. Verifică și autorizează

Verifică titularul, numele documentelor, formatul și site-ul solicitant, dacă apare. Versiunea Android actuală cere PIN-ul pentru fiecare aprobare nouă; salvarea PIN-ului nu este oferită. Nu trimite PIN-ul într-o cerere de suport.

<GuideScreenshot src="/img/guide/android-phone/ro/pin.png" alt="Verifică și autorizează" steps={[{"text": "Introdu PIN-ul de semnare al cardului selectat în câmpul protejat. Aprobarea acoperă numai cererea afișată.", "x": 6.8, "y": 55.7}, {"text": "Atinge Semnează. Păstrează aplicația și cititorul disponibile până se termină lotul. Anulează o cerere neașteptată.", "x": 67.6, "y": 64.9}]} />

## Urmărește progresul semnării

Cardul de progres arată etapa activă: conectare, autentificare, citirea certificatului, verificarea PIN-ului, semnare, marcă temporală, informații de revocare sau scrierea rezultatului. Unele etape pot dura cât răspunde serviciul extern.

<GuideScreenshot src="/img/guide/android-phone/ro/sign-progress.png" alt="Urmărește progresul semnării" steps={[{"text": "După aprobare, urmărește etapa și păstrează cititorul conectat. Așteaptă rezultatul final înainte de deschidere sau distribuire.", "x": 13.6, "y": 49.7}, {"text": "Dacă apare o eroare, urmează mesajul afișat. Nu introduce PIN-ul repetat și nu porni alt lot cât cererea actuală este activă."}]} />

## Rezolvă eroarea unui fișier

Eroarea aparține fișierului afectat. Verifică celelalte rânduri și rezultatele finalizate; o eroare nu înseamnă că toate documentele au eșuat. Exemplul arată o eroare a serviciului de marcă temporală pentru un fișier dintr-un lot mixt.

<GuideScreenshot src="/img/guide/android-phone/ro/sign-failure.png" alt="Rezolvă eroarea unui fișier" steps={[{"text": "Citește mesajul de sub fișier. Pentru rețea sau marca temporală, restabilește conexiunea ori așteaptă serviciul. Pentru un fișier ilizibil, folosește un original valid.", "x": 5.8, "y": 73.2}, {"text": "Păstrează rezultatele reușite, corectează cauza și pornește intenționat o nouă semnare doar pentru fișierele necesare. PIN-ul nu se reîncearcă automat; după avertizarea de PIN greșit, oprește-te și verifică titularul și PIN-ul înainte de altă încercare."}]} />

## 6. Deschide, salvează sau distribuie rezultatul

Pe Android 10 și ulterior, rezultatele obișnuite se salvează în Downloads/eSemnBun. Pentru XAdES detașat, păstrează XML-ul și originalul. Dacă un fișier eșuează, citește eroarea și verifică rezultatele finalizate înainte de un nou lot.

<GuideScreenshot src="/img/guide/android-phone/ro/results.png" alt="Deschide, salvează sau distribuie rezultatul" steps={[{"text": "Atinge Deschide lângă fișierul finalizat pentru a-l deschide într-o aplicație compatibilă.", "x": 63.5, "y": 61.6}, {"text": "În Fișiere → Documente salvate, meniul fișierului oferă Deschide, Verifică, Distribuie sau Salvează ca… când fișierul permite accesul prin furnizor. Salvează ca permite alegerea altei destinații."}, {"text": "Șterge rezultatele ascunde lista de finalizare. Fișierele salvate rămân în Fișiere."}]} />

## 7. Verifică un document semnat

Verificarea nu necesită card sau PIN. Rezultatul verde privește verificările afișate, nu numele fișierului sau prezența ștampilei vizibile.

<GuideScreenshot src="/img/guide/android-phone/ro/verify-current.png" alt="Ecranul Verifică" steps={[{"text": "Ecranul Verifică", "x": 47, "y": 21}]} />

## Înțelege semnătura invalidă

Invalid înseamnă că verificarea integrității ori a semnăturii criptografice a eșuat. Documentul poate fi modificat sau semnătura deteriorată/incorectă. Ștampila vizibilă, numele cunoscut ori autorul nu schimbă verdictul.

<GuideScreenshot src="/img/guide/android-phone/ro/verify-invalid.png" alt="Înțelege semnătura invalidă" steps={[{"text": "Citește Semnătură invalidă și verificarea eșuată. Nu considera această copie verificată.", "x": 18.5, "y": 51.1}, {"text": "Extinde Detalii tehnice, compară cu rezultatul semnat original al expeditorului și cere o copie intactă dacă este necesar. Verifică fiecare semnătură dacă sunt mai multe."}]} />

## Înțelege lanțul de încredere neconfirmat

Nu poate fi confirmată diferă de Semnătură invalidă. În exemplu, semnătura și integritatea trec verificarea, dar certificatul nu aparține lanțului MDQSign recunoscut. Lipsa originalelor poate produce tot un rezultat neconfirmat, cu altă explicație.

<GuideScreenshot src="/img/guide/android-phone/ro/verify-unconfirmed.png" alt="Înțelege lanțul de încredere neconfirmat" steps={[{"text": "Citește motivul de sub Nu poate fi confirmată și verifică separat Integritate, Semnătură și Lanț de încredere.", "x": 18.5, "y": 51.1}, {"text": "Consultă certificatul pentru titular și emitent. Confirmă nivelul de încredere necesar cu expeditorul sau serviciul destinatar. Verificarea offline a integrității nu stabilește starea curentă a revocării și nu garantează acceptarea juridică."}]} />

## Recunoaște un fișier nesemnat sau neacceptat

Nicio semnătură înseamnă că aplicația nu a găsit în fișier o semnătură pe care o poate citi. Poate fi originalul nesemnat ori un format neacceptat. O imagine a semnăturii nu este semnătură electronică.

<GuideScreenshot src="/img/guide/android-phone/ro/verify-none.png" alt="Recunoaște un fișier nesemnat sau neacceptat" steps={[{"text": "Citește Nicio semnătură și verifică dacă ai selectat PDF-ul semnat final sau semnătura XML, nu originalul nesemnat.", "x": 18.5, "y": 51.1}, {"text": "Alege rezultatul semnat corect și verifică din nou. Cere expeditorului o semnătură PDF/XML acceptată dacă rezultatul rămâne neschimbat.", "x": 34.4, "y": 29.4}]} />

## 8. Consultă certificatul și detaliile tehnice

O semnătură invalidă diferă de un lanț de încredere neconfirmat. Lipsa originalelor sau a informațiilor de încredere poate împiedica un verdict complet. Consultă verificările separate.

<GuideScreenshot src="/img/guide/android-phone/ro/certificate.png" alt="Consultă certificatul și detaliile tehnice" steps={[{"text": "Extinde Detalii certificat pentru titular, emitent, număr de serie, cheie publică și amprentă. Derulează dacă este necesar.", "x": 36.1, "y": 61.9}, {"text": "Extinde Detalii tehnice pentru verificările care susțin verdictul și restrânge secțiunea după consultare.", "x": 34.3, "y": 82.9}]} />

## 9. Furnizează originalul pentru XML detașat

XML-ul detașat conține o referință la document. Verificarea amprentei necesită octeții originali ai fișierului.

<GuideScreenshot src="/img/guide/android-phone/ro/original.png" alt="Furnizează originalul pentru XML detașat" steps={[{"text": "Atinge Alege documentul semnat și selectează originalul exact indicat în mesaj.", "x": 11.6, "y": 68.4}, {"text": "Așteaptă rezultatul actualizat. Un original modificat sau alt fișier nu va corespunde semnăturii. Distribuie XML-ul împreună cu originalul potrivit."}]} />

## 10. Găsește documentele semnate

Documente salvate conține rezultate semnate, criptate și decriptate. Selectează un fișier semnat pentru detaliile semnăturii. Un fișier criptat oferă decriptarea; conținutul criptat nu este trimis la verificarea semnăturii. Fișierele decriptate își păstrează tipul rezultatului și pot fi deschise sau exportate.

Fișiere conține biblioteca rezultatelor semnate și un istoric separat. Intrarea din bibliotecă este o referință la fișier, nu o copie de siguranță.

<GuideScreenshot src="/img/guide/android-phone/ro/documents.png" alt="Găsește documentele semnate" steps={[{"text": "Deschide Fișiere și selectează Documente salvate.", "x": 5.8, "y": 16.6}, {"text": "Atinge rândul unui document pentru fereastra cu detaliile semnăturii. Aplicația verifică din nou fișierul actual.", "x": 15.5, "y": 29.1}]} />

## 11. Consultă detaliile fără a pierde lista

Verdictul din fereastră este o verificare actuală, nu doar eticheta istorică „semnat”. Un fișier indisponibil afișează o eroare de acces; selectează din nou un fișier mutat în Verifică.

<GuideScreenshot src="/img/guide/android-phone/ro/details.png" alt="Consultă detaliile fără a pierde lista" steps={[{"text": "Verifică verdictul și extinde certificatul sau detaliile tehnice, ca în Verifică. Furnizează originalul dacă XML-ul detașat îl solicită.", "x": 36.1, "y": 72.9}, {"text": "Atinge Închide pentru a reveni la aceeași listă de documente.", "x": 76.1, "y": 20.5}]} />

## 12. Curăță istoricul păstrând documentele

Istoricul listează operațiile cu documente și cererile site-urilor. Curățarea lui nu golește Documente salvate și nu șterge fișierele de pe dispozitiv.

<GuideScreenshot src="/img/guide/android-phone/ro/history.png" alt="Curăță istoricul păstrând documentele" steps={[{"text": "Alege Istoric în Fișiere și consultă operațiile recente.", "x": 46.8, "y": 16.6}, {"text": "Atinge Șterge lista și confirmă, apoi revino la Documente salvate pentru rezultate.", "x": 72.2, "y": 23.6}]} />

## 13. Semnează pe un site

Folosește doar un serviciu cu adresă și cerere cunoscute. Aplicația este independentă de Guvernul Republicii Moldova; sursele oficiale sunt în Browser și Despre. Aspectul site-urilor poate varia.

<GuideScreenshot src="/img/guide/android-phone/ro/browser.png" alt="Semnează pe un site" steps={[{"text": "Deschide Browser și activează Conexiunea cu browserul pentru un serviciu în browserul extern al aceluiași dispozitiv. Permite notificările când se solicită.", "x": 15.5, "y": 52.9}, {"text": "Alternativ, atinge Deschide în browserul aplicației. Introdu adresa sau alege serviciul din Servicii. Browserul integrat folosește afișarea desktop pentru autentificarea compatibilă.", "x": 24.0, "y": 77.7}, {"text": "Activează ștampilele vizibile pentru site-uri dacă este necesar. Verifică în fiecare aprobare cardul și site-ul solicitant, apoi introdu PIN-ul.", "x": 5.8, "y": 39.5}]} />

## Folosește comenzile browserului și serviciile

Aceste ecrane nu conțin conturi autentificate sau date personale. Conectează cititorul înainte de o cerere reală de identificare.

<GuideScreenshot src="/img/guide/android-phone/ro/browser-menu.png" alt="Folosește comenzile browserului și serviciile" steps={[{"text": "Folosește Servicii pentru un serviciu predefinit sau un marcaj salvat.", "x": 50.8, "y": 37.3}, {"text": "Închide meniul, introdu o adresă HTTPS completă și atinge Accesează. Folosește Înapoi, Înainte și Reîncarcă; Închide revine la ecranul Browser."}]} />

## Adaugă un marcaj util

Deschide Servicii → Adaugă marcaj. Folosește numai o adresă cunoscută. Titlul și pictograma ajută la identificarea serviciului.

<GuideScreenshot src="/img/guide/android-phone/ro/bookmark.png" alt="Adaugă un marcaj util" steps={[{"text": "Introdu titlul și adresa serviciului.", "x": 18.8, "y": 35.2}, {"text": "Alege pictograma, apoi Salvează. Anulează păstrează marcajele existente.", "x": 14.9, "y": 49.1}]} />

## Editează sau elimină marcaje

Deschide Servicii → Gestionează marcajele. Modificările privesc scurtăturile salvate, nu cardul sau documentele semnate.

<GuideScreenshot src="/img/guide/android-phone/ro/bookmarks.png" alt="Editează sau elimină marcaje" steps={[{"text": "Atinge rândul unui marcaj pentru titlu, adresă sau pictogramă și salvează."}, {"text": "Folosește coșul pentru eliminare sau Adaugă marcaj pentru un marcaj nou. Închide revine la navigare.", "x": 55.4, "y": 67.2}]} />

## Resetează sesiunea unui site

Deschide Servicii → Șterge datele de navigare. Ștergerea cookie-urilor te deconectează. Cookie-urile sau istoricul închid pagina curentă; documentele aplicației rămân salvate.

<GuideScreenshot src="/img/guide/android-phone/ro/browser-data.png" alt="Resetează sesiunea unui site" steps={[{"text": "Selectează cache, cookie-uri și/sau istoricul browserului, după necesitate.", "x": 20.8, "y": 53.2}, {"text": "Atinge Șterge datele selectate sau Anulează pentru păstrarea sesiunii.", "x": 43.4, "y": 65.6}]} />

## 14. Consultă sau recitește cardul

Deschide **Setări → Carduri și cititoare** pentru a consulta un card conectat. În ecranul Semnează, butonul de informații din dreapta sus deschide detaliile cardului. Gestionează PIN-urile în **Setări → PIN-uri salvate**. Cardul și PIN-ul memorate sunt comune pentru NFC și USB.

## 15. Limbă, aspect, demonstrație și suport

Deschide **Setări** pentru a găsi Modul demonstrativ în partea de sus, apoi cardurile, PIN-urile salvate, limba și aspectul. Modul demonstrativ folosește date fictive și nu produce semnături valide.

Deschide **Setări → Carduri și cititoare** pentru a consulta un card conectat. În ecranul Semnează, butonul de informații din dreapta sus deschide detaliile cardului. Gestionează PIN-urile în **Setări → PIN-uri salvate**. Cardul și PIN-ul memorate sunt comune pentru NFC și USB.

Alege româna, engleza, rusa sau limba sistemului și aspectul Luminos, Întunecat sau Sistem. În Despre găsești versiunea instalată și legăturile de asistență. Activează ștampila PDF din browser dacă vrei o marcă vizibilă pentru solicitările acceptate.

<GuideScreenshot src="/img/guide/android-phone/ro/cards-current.png" alt="Carduri și cititoare în Setări" steps={[{"text": "Carduri și cititoare în Setări", "x": 29, "y": 34}]} />

Ștergerea unui PIN salvat elimină copia de pe acest dispozitiv. PIN-ul cardului nu se schimbă și cardul nu se deblochează.

## Rezolvarea problemelor

| Problemă | Ce poți face |
| --- | --- |
| Cititorul lipsește | Verifică suportul OTG/USB host, adaptorul și cablul; reconectează și permite accesul USB. |
| Card gol sau ilizibil | Reintrodu cardul, așteaptă și folosește Recitește după pregătirea cititorului. |
| PIN greșit sau avertizare de încercări | Oprește-te și verifică cardul și PIN-ul. Încercările repetate pot bloca cardul. |
| Eroare de rețea sau marcă temporală | Verifică conexiunea și eroarea serviciului, apoi rezultatele finalizate înainte de reluare. |
| Fișier mutat sau doar în cloud | Descarcă-l local și selectează-l din nou în Verifică. |
| Probleme la autentificare/descărcare web | Verifică adresa și conexiunea. Descărcările autentificate pot necesita browser extern. |

Pentru explicația rezultatelor, vezi [Semnare și verificare](/docs/signing). Pentru cititoare și adaptoare, vezi [Dispozitive](/devices).

<!-- file-protection-guides -->

Dacă sesiunea NFC se întrerupe, ține cardul lângă antenă până se închide fereastra de scanare. Verifică cardul și PIN-ul selectate înainte de a reîncerca după un PIN greșit. Poți alege un cititor USB compatibil în Semnează.

## Criptează un fișier cu parolă

Deschide meniul **Mai multe** din bara de navigare și alege **Protejează fișiere**. Alege **Criptează** sau **Decriptează**, apoi un fișier accesibil.

Nu ai nevoie de card. Creează o parolă pentru fișier și transmite-o destinatarului printr-un canal de încredere separat. Nu este PIN-ul cardului. Criptarea creează un rezultat separat; păstrează originalul până verifici rezultatul.

Protecția fișierelor folosește o parolă. Protecția prin certificat/card nu este disponibilă pentru cartea de identitate moldovenească: certificatul de semnare nu poate decripta fișiere. Dacă ai primit un fișier criptat cu certificat, cere o copie criptată cu parolă.

<GuideScreenshot src="/img/guide/android-phone/ro/protect-menu-light.png" alt="Deschide protecția fișierelor" steps={[{"x": 70, "y": 15, "text": "Deschide meniul de navigare și alege Protejează fișiere."}]} />

<GuideScreenshot src="/img/guide/android-phone/ro/protect-password-light.png" alt="Criptează un fișier cu parolă" start={2} steps={[{"x": 27, "y": 20, "text": "Alege Criptează."}, {"x": 30, "y": 31, "text": "Alege fișierul sursă."}, {"x": 25, "y": 55, "text": "Introdu o parolă nouă în Parolă, apoi repet-o în Confirmă parola."}, {"x": 50, "y": 88, "text": "Alege Criptează. Copia criptată este salvată în Documente."}]} />

<GuideScreenshot src="/img/guide/android-phone/ro/protect-complete-light.png" alt="Fișier criptat salvat" start={6} steps={[{"x": 25, "y": 33, "text": "Verifică numele fișierului salvat. Rezultatul este deja în Documente."}, {"x": 25, "y": 83, "text": "Alege Salvează ca… numai dacă dorești și o copie în alt loc."}, {"x": 75, "y": 88, "text": "Alege Închide pentru a reveni în aplicație. Fișierul salvat rămâne în Documente."}]} />

Alege **Criptează** sau **Decriptează**. Rezultatul este salvat automat în spațiul privat al aplicației și apare în **Documente → Documente salvate**. Alege **Închide** la final sau **Salvează ca…** pentru a-l exporta prin selectorul de fișiere Android. Originalul este păstrat.

Documente salvate include fișiere semnate, criptate și decriptate. Identifică rezultatul după numele fișierului și eticheta operațiunii. Criptarea nu creează o semnătură digitală; fișierele criptate trebuie decriptate înainte de deschiderea sau verificarea conținutului.


## Decriptează un fișier primit

Deschide meniul **Mai multe** din bara de navigare și alege **Protejează fișiere**. Alege **Criptează** sau **Decriptează**, apoi un fișier accesibil.

Obține parola de la expeditor printr-un canal de încredere separat. Alege fișierul criptat, apoi introdu parola în câmpul cu contur **Parolă**. Nu ai nevoie de cititor, card sau PIN-ul cardului.

<GuideScreenshot src="/img/guide/android-phone/ro/protect-menu-light.png" alt="Deschide protecția fișierelor" steps={[{"x": 70, "y": 15, "text": "Deschide meniul de navigare și alege Protejează fișiere."}]} />

<GuideScreenshot src="/img/guide/android-phone/ro/protect-decrypt-light.png" alt="Decriptează un fișier primit" start={2} steps={[{"x": 27, "y": 20, "text": "Alege Decriptează și selectează fișierul criptat primit."}, {"x": 25, "y": 55, "text": "Introdu parola primită de la expeditor în câmpul Parolă."}, {"x": 50, "y": 88, "text": "Alege Decriptează. Rezultatul nou este salvat în Documente."}]} />

<GuideScreenshot src="/img/guide/android-phone/ro/protect-decrypt-complete-light.png" alt="Fișier decriptat salvat" start={5} steps={[{"x": 25, "y": 33, "text": "Verifică numele fișierului salvat. Rezultatul este deja în Documente."}, {"x": 25, "y": 83, "text": "Alege Salvează ca… numai dacă dorești și o copie în alt loc."}, {"x": 75, "y": 88, "text": "Alege Închide pentru a reveni în aplicație. Fișierul salvat rămâne în Documente."}]} />

Deschide și verifică rezultatul salvat înainte de utilizare. Criptarea compatibilă MoldSign nu autentifică conținutul: decriptarea reușită nu dovedește singură integritatea sau parola corectă.

Alege **Criptează** sau **Decriptează**. Rezultatul este salvat automat în spațiul privat al aplicației și apare în **Documente → Documente salvate**. Alege **Închide** la final sau **Salvează ca…** pentru a-l exporta prin selectorul de fișiere Android. Originalul este păstrat.

Documente salvate include fișiere semnate, criptate și decriptate. Identifică rezultatul după numele fișierului și eticheta operațiunii. Criptarea nu creează o semnătură digitală; fișierele criptate trebuie decriptate înainte de deschiderea sau verificarea conținutului.
