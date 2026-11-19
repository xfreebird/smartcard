---
title: Tabletă Android
sidebar_position: 5
---

import GuideScreenshot from '@site/src/components/GuideScreenshot';

# Tabletă Android

Începând cu eSemnBun 0.2.12, poți semna prin NFC de pe un iPhone sau dispozitiv Android compatibil, cu un card fără contact compatibil. Poți folosi și un cititor USB compatibil. Ai nevoie de o carte de identitate electronică moldovenească activă, cu certificat de semnare valabil și PIN-ul de semnare. Instalează sau actualizează aplicația prin canalul dispozitivului din [Descărcări](/downloads).

Cercurile numerotate indică comenzile din fiecare parcurs. Atinge o imagine pentru mărire.

Fereastra largă a tabletei folosește navigarea în stânga și comenzile de semnare în conținut. Rotește în peisaj pentru mai mult spațiu. În ecran divizat sau fereastră îngustă, aplicația trece la navigare compactă; lărgește fereastra pentru revenire. Capturile sunt native de tabletă. Pentru navigarea compactă, vezi [ghidul telefonului](./android.md).

## 1. Conectează cititorul și cardul

Ai nevoie de o carte de identitate electronică moldovenească activă, cu certificat de semnare valabil și PIN-ul de semnare.

### Semnează prin NFC

Începând cu eSemnBun 0.2.12, poți semna prin NFC de pe un iPhone sau dispozitiv Android compatibil, cu un card fără contact compatibil. Poți folosi și un cititor USB compatibil. Alege **Cu telefonul · NFC** în **Semnează** și adaugă documentul. Apasă **Continuă**, verifică cererea și confirmă PIN-ul de semnare. Ține cardul lângă antena NFC a dispozitivului până când aplicația confirmă finalizarea. Pe Android trebuie să activezi NFC.

<GuideScreenshot src="/img/guide/android-tablet/ro/nfc-sign.png" alt="Ecranul Semnează cu opțiunea NFC selectată" steps={[{"text": "Ecranul Semnează cu opțiunea NFC selectată", "x": 45, "y": 75}]} />

### Semnează cu un cititor USB

Pentru USB, conectează cititorul prin [adaptorul](/devices) potrivit, alege **Cu un cititor de carduri** în **Semnează** și introdu cardul. Dacă sunt mai multe carduri conectate, selectează titularul dorit înainte de a continua.

<GuideScreenshot src="/img/guide/android-tablet/ro/reader-sign.png" alt="Ecranul Semnează cu cititorul de carduri USB selectat" steps={[{"text": "Ecranul Semnează cu cititorul de carduri USB selectat", "x": 48, "y": 78}]} />

## 2. Adaugă fișiere și pregătește un lot

### Alege cum semnezi

Alege **Cu telefonul · NFC** în **Semnează** și adaugă documentul. Apasă **Continuă**, verifică cererea și confirmă PIN-ul de semnare. Ține cardul lângă antena NFC a dispozitivului până când aplicația confirmă finalizarea. Pe Android trebuie să activezi NFC.

Pentru USB, conectează cititorul prin [adaptorul](/devices) potrivit, alege **Cu un cititor de carduri** în **Semnează** și introdu cardul. Dacă sunt mai multe carduri conectate, selectează titularul dorit înainte de a continua. Cu un cititor USB, lasă cititorul conectat și cardul introdus până se finalizează semnarea și aplicarea mărcii temporale.

Păstrează cititorul conectat până apar toate rezultatele. Originalul rămâne separat de fișierul semnat. Poți distribui documente din Fișiere sau altă aplicație către eSemnBun.

<GuideScreenshot src="/img/guide/android-tablet/ro/sign.png" alt="Adaugă fișiere și pregătește un lot" steps={[{"text": "Glisează la cardul dorit și verifică indicatorul Folosit pentru semnare.", "x": 17.3, "y": 18.4}, {"text": "Atinge Adaugă documente și selectează unul sau mai multe fișiere în selectorul sistemului. Descarcă mai întâi fișierele din cloud dacă nu sunt disponibile.", "x": 47.4, "y": 46.5}, {"text": "Verifică rândurile extinse ale documentelor. Deschide meniul fiecărui fișier pentru format, ștampilă sau eliminare."}, {"text": "Atinge Semnează după verificarea cardului și a întregii liste.", "x": 66, "y": 53.5}]} />

## 3. Alege semnătura PDF sau XML

Semnătura PDF (PAdES-T) este inclusă în PDF. XAdES creează XML: păstrează originalul împreună cu semnătura detașată. Formatele cu marcă temporală sau date de validare au nevoie de serviciile de încredere. Ștampila vizibilă este opțională și nu înlocuiește semnătura digitală.

<GuideScreenshot src="/img/guide/android-tablet/ro/format.png" alt="Alege semnătura PDF sau XML" steps={[{"text": "Deschide meniul cu trei puncte al fișierului. Alege formatul semnăturii sau elimină fișierul adăugat greșit.", "x": 84.9, "y": 30.4}, {"text": "Pentru PDF, activează ștampila vizibilă dacă vrei să o poziționezi înainte de aprobare. Semnarea XML produce aici o semnătură detașată; păstrează originalul."}]} />

## 4. Poziționează ștampila vizibilă

Editorul de poziționare se deschide înainte de solicitarea PIN-ului, când ștampila este activată. Nu acoperi textul important.

Etichetele ștampilei urmează limba aplicației aleasă în setările General.

<GuideScreenshot src="/img/guide/android-tablet/ro/stamp.png" alt="Poziționează ștampila vizibilă" steps={[{"text": "Trage ștampila pe pagină; ajustează dimensiunea cu mânerele din colțuri.", "x": 38, "y": 58}, {"text": "Folosește săgețile paginii, apoi alege O pagină, Toate paginile sau Oprit.", "x": 46.2, "y": 83.2}, {"text": "Alege dacă poziția se aplică tuturor PDF-urilor din lot și atinge Aplică. Anulează revine fără aprobarea semnării.", "x": 93.6, "y": 93.5}]} />

## 5. Verifică și autorizează

Verifică titularul, numele documentelor, formatul și site-ul solicitant, dacă apare. Poți reutiliza un PIN salvat pentru cardul selectat când este disponibilă autentificarea pe dispozitiv. Nu trimite PIN-ul într-o cerere de suport.

<GuideScreenshot src="/img/guide/android-tablet/ro/pin.png" alt="Verifică și autorizează" steps={[{"text": "Introdu PIN-ul de semnare al cardului selectat în câmpul protejat. Aprobarea acoperă numai cererea afișată.", "x": 31.8, "y": 54.8}, {"text": "Atinge Semnează. Păstrează aplicația și cititorul disponibile până se termină lotul. Anulează o cerere neașteptată.", "x": 58.4, "y": 62.5}]} />

## Urmărește progresul semnării

Cardul de progres arată etapa activă: conectare, autentificare, citirea certificatului, verificarea PIN-ului, semnare, marcă temporală, informații de revocare sau scrierea rezultatului. Unele etape pot dura cât răspunde serviciul extern.

<GuideScreenshot src="/img/guide/android-tablet/ro/sign-progress.png" alt="Urmărește progresul semnării" steps={[{"text": "După aprobare, urmărește etapa și păstrează cititorul conectat. Așteaptă rezultatul final înainte de deschidere sau distribuire.", "x": 8.0, "y": 45.5}, {"text": "Dacă apare o eroare, urmează mesajul afișat. Nu introduce PIN-ul repetat și nu porni alt lot cât cererea actuală este activă."}]} />

## Rezolvă eroarea unui fișier

Eroarea aparține fișierului afectat. Verifică celelalte rânduri și rezultatele finalizate; o eroare nu înseamnă că toate documentele au eșuat. Exemplul arată o eroare a serviciului de marcă temporală pentru un fișier dintr-un lot mixt.

<GuideScreenshot src="/img/guide/android-tablet/ro/sign-failure.png" alt="Rezolvă eroarea unui fișier" steps={[{"text": "Citește mesajul de sub fișier. Pentru rețea sau marca temporală, restabilește conexiunea ori așteaptă serviciul. Pentru un fișier ilizibil, folosește un original valid.", "x": 45.2, "y": 27.6}, {"text": "Păstrează rezultatele reușite, corectează cauza și pornește intenționat o nouă semnare doar pentru fișierele necesare. PIN-ul nu se reîncearcă automat; după avertizarea de PIN greșit, oprește-te și verifică titularul și PIN-ul înainte de altă încercare."}]} />

## 6. Deschide, salvează sau distribuie rezultatul

Pe Android 10 și ulterior, rezultatele obișnuite se salvează în Downloads/eSemnBun. Pentru XAdES detașat, păstrează XML-ul și originalul. Dacă un fișier eșuează, citește eroarea și verifică rezultatele finalizate înainte de un nou lot.

<GuideScreenshot src="/img/guide/android-tablet/ro/results.png" alt="Deschide, salvează sau distribuie rezultatul" steps={[{"text": "Atinge numele unui fișier finalizat pentru a-l deschide.", "x": 37.0, "y": 23.3}, {"text": "Atinge pictograma Distribuie de lângă nume pentru a trimite o copie.", "x": 65.5, "y": 23.3}, {"text": "Alege Vezi în Documente pentru a deschide biblioteca.", "x": 48.5, "y": 42.9}]} />

## 7. Verifică un document semnat

Verificarea nu necesită card sau PIN. Rezultatul verde privește verificările afișate, nu numele fișierului sau prezența ștampilei vizibile.

<GuideScreenshot src="/img/guide/android-tablet/ro/verify-current.png" alt="Ecranul Verifică" steps={[{"text": "Alege un PDF sau XML semnat. Verifică verdictul, semnatarul și rezultatele verificărilor.", "x": 3.0, "y": 18.9}, {"text": "Extinde Detalii tehnice pentru a consulta raportul. Atinge din nou pentru a-l restrânge.", "x": 53.0, "y": 49.5}, {"text": "Folosește butonul de jos pentru a alege alt document semnat.", "x": 53.0, "y": 93.5}, {"text": "Folosește Șterge rezultatele din bara de navigare pentru a goli sesiunea de verificare.", "x": 97.5, "y": 5.1}]} />

## Înțelege semnătura invalidă

Invalid înseamnă că verificarea integrității ori a semnăturii criptografice a eșuat. Documentul poate fi modificat sau semnătura deteriorată/incorectă. Ștampila vizibilă, numele cunoscut ori autorul nu schimbă verdictul.

<GuideScreenshot src="/img/guide/android-tablet/ro/verify-invalid.png" alt="Înțelege semnătura invalidă" steps={[{"text": "Citește Semnătură invalidă și verificarea eșuată. Nu considera această copie verificată.", "x": 3.0, "y": 18.9}, {"text": "Extinde Detalii tehnice, compară cu rezultatul semnat original al expeditorului și cere o copie intactă dacă este necesar. Verifică fiecare semnătură dacă sunt mai multe.", "x": 53.0, "y": 47.6}]} />

## Înțelege lanțul de încredere neconfirmat

Nu poate fi confirmată diferă de Semnătură invalidă. În exemplu, semnătura și integritatea trec verificarea, dar certificatul nu aparține lanțului MDQSign recunoscut. Lipsa originalelor poate produce tot un rezultat neconfirmat, cu altă explicație.

<GuideScreenshot src="/img/guide/android-tablet/ro/verify-unconfirmed.png" alt="Înțelege lanțul de încredere neconfirmat" steps={[{"text": "Citește motivul de sub Nu poate fi confirmată și verifică separat Integritate, Semnătură și Lanț de încredere.", "x": 3.0, "y": 18.9}, {"text": "Consultă certificatul pentru titular și emitent. Confirmă nivelul de încredere necesar cu expeditorul sau serviciul destinatar. Verificarea offline a integrității nu stabilește starea curentă a revocării și nu garantează acceptarea juridică.", "x": 53.0, "y": 41.7}]} />

## Recunoaște un fișier nesemnat sau neacceptat

Nicio semnătură înseamnă că aplicația nu a găsit în fișier o semnătură pe care o poate citi. Poate fi originalul nesemnat ori un format neacceptat. O imagine a semnăturii nu este semnătură electronică.

<GuideScreenshot src="/img/guide/android-tablet/ro/verify-none.png" alt="Recunoaște un fișier nesemnat sau neacceptat" steps={[{"text": "Citește Nicio semnătură și verifică dacă ai selectat PDF-ul semnat final sau semnătura XML, nu originalul nesemnat.", "x": 3.0, "y": 18.9}, {"text": "Alege rezultatul semnat corect și verifică din nou. Cere expeditorului o semnătură PDF/XML acceptată dacă rezultatul rămâne neschimbat.", "x": 53.0, "y": 93.5}]} />

## 8. Consultă certificatul și detaliile tehnice

O semnătură invalidă diferă de un lanț de încredere neconfirmat. Lipsa originalelor sau a informațiilor de încredere poate împiedica un verdict complet. Consultă verificările separate.

<GuideScreenshot src="/img/guide/android-tablet/ro/certificate.png" alt="Consultă certificatul și detaliile tehnice" steps={[{"text": "Extinde Detalii certificat pentru titular, emitent, număr de serie, cheie publică și amprentă. Derulează dacă este necesar.", "x": 53.0, "y": 43.5}, {"text": "Extinde Detalii tehnice pentru verificările care susțin verdictul și restrânge secțiunea după consultare.", "x": 53.0, "y": 58.9}]} />

<GuideScreenshot src="/img/guide/android-tablet/ro/verify-technical.png" alt="Detalii tehnice extinse" steps={[{"text": "În acest exemplu, liniile în engleză indică verificarea offline a amprentei documentului și a lanțului de certificate. Atinge din nou Detalii tehnice pentru a restrânge raportul.", "x": 38.4, "y": 54.5}]} />

## 9. Furnizează originalul pentru XML detașat

XML-ul detașat conține o referință la document. Verificarea amprentei necesită octeții originali ai fișierului.

<GuideScreenshot src="/img/guide/android-tablet/ro/original.png" alt="Furnizează originalul pentru XML detașat" steps={[{"text": "Atinge Alege documentul semnat și selectează originalul exact indicat în mesaj.", "x": 3.0, "y": 35.3}, {"text": "Așteaptă rezultatul actualizat. Un original modificat sau alt fișier nu va corespunde semnăturii. Distribuie XML-ul împreună cu originalul potrivit."}]} />

## 10. Găsește documentele semnate

Documente salvate conține rezultate semnate, criptate și decriptate. Selectează un fișier semnat pentru detaliile semnăturii. Un fișier criptat oferă decriptarea; conținutul criptat nu este trimis la verificarea semnăturii. Fișierele decriptate își păstrează tipul rezultatului și pot fi deschise sau exportate.

Documente conține biblioteca rezultatelor semnate și un istoric separat. Intrarea din bibliotecă este o referință la fișier, nu o copie de siguranță.

<GuideScreenshot src="/img/guide/android-tablet/ro/documents.png" alt="Găsește documentele semnate" steps={[{"text": "Atinge numele fișierului pentru detaliile semnăturii.", "x": 34.5, "y": 20.7}, {"text": "Alege Distribuie direct pe rândul fișierului sau deschide Mai multe acțiuni pentru a deschide, verifica, cripta ori salva o copie.", "x": 65.3, "y": 21.6}]} />

## 11. Consultă detaliile fără a pierde lista

Verdictul din fereastră este o verificare actuală, nu doar eticheta istorică „semnat”. Un fișier indisponibil afișează o eroare de acces; selectează din nou un fișier mutat în Verifică.

<GuideScreenshot src="/img/guide/android-tablet/ro/details.png" alt="Consultă detaliile fără a pierde lista" steps={[{"text": "Citește rezultatul verificării și extinde Detalii tehnice pentru a vedea verificările.", "x": 29.1, "y": 65.4}, {"text": "Sub rezultat poți deschide sau distribui fișierul. Atinge Închide pentru a reveni la listă.", "x": 31.2, "y": 73.5}]} />

## 12. Curăță istoricul păstrând documentele

Istoricul listează operațiile cu documente și cererile site-urilor. Curățarea lui nu golește Documente salvate și nu șterge fișierele de pe dispozitiv.

<GuideScreenshot src="/img/guide/android-tablet/ro/history.png" alt="Curăță istoricul păstrând documentele" steps={[{"text": "Alege Istoric pentru a vedea numele fișierului, rezultatul și data fiecărei operații.", "x": 42.4, "y": 14.7}, {"text": "Șterge lista de activități pentru a curăța istoricul și a păstra documentele salvate.", "x": 69.3, "y": 14.7}]} />

## 13. Semnează pe un site

Folosește doar un serviciu cu adresă și cerere cunoscute. Aplicația este independentă de Guvernul Republicii Moldova; sursele oficiale sunt în Browser și Despre. Aspectul site-urilor poate varia.

<GuideScreenshot src="/img/guide/android-tablet/ro/browser.png" alt="Semnează pe un site" steps={[{"text": "Pe dispozitivele compatibile, deschide Autentificare pentru a alege NFC sau un cititor de carduri.", "x": 38.6, "y": 11.5}, {"text": "Deschide Browser și activează Conexiunea cu browserul pentru un serviciu în browserul extern al aceluiași dispozitiv. Permite notificările când se solicită.", "x": 40.7, "y": 20.1}, {"text": "Alternativ, atinge Deschide în browserul aplicației. Introdu adresa sau alege serviciul din Servicii. Browserul integrat folosește afișarea desktop pentru autentificarea compatibilă.", "x": 53.0, "y": 38.8}, {"text": "Activează ștampilele vizibile pentru site-uri dacă este necesar. Verifică în fiecare aprobare cardul și site-ul solicitant, apoi introdu PIN-ul."}]} />

<GuideScreenshot src="/img/guide/android-tablet/ro/browser-authentication.png" alt="Pe dispozitivele compatibile, deschide Autentificare pentru a alege NFC sau un cititor de carduri." steps={[{"text": "Alege NFC sau Cititor de carduri. Rândul albastru este selectat.", "x": 35.5, "y": 53.1}, {"text": "Alege un card cunoscut și verifică numărul său de serie.", "x": 37.9, "y": 69.1}, {"text": "Folosește Citește cardul NFC pentru a identifica alt card. Acest pas nu cere PIN-ul.", "x": 51.0, "y": 77.1}]} />

## Folosește comenzile browserului și serviciile

Aceste ecrane nu conțin conturi autentificate sau date personale. Conectează cititorul înainte de o cerere reală de identificare.

<GuideScreenshot src="/img/guide/android-tablet/ro/browser-menu.png" alt="Folosește comenzile browserului și serviciile" steps={[{"text": "Folosește Servicii pentru un serviciu predefinit sau un marcaj salvat.", "x": 17.5, "y": 31.9}, {"text": "Închide meniul, introdu o adresă HTTPS completă și atinge Accesează. Folosește Înapoi, Înainte și Reîncarcă; Închide revine la ecranul Browser."}]} />

## Adaugă un marcaj util

Deschide Servicii → Adaugă marcaj. Folosește numai o adresă cunoscută. Titlul și pictograma ajută la identificarea serviciului.

<GuideScreenshot src="/img/guide/android-tablet/ro/bookmark.png" alt="Adaugă un marcaj util" steps={[{"text": "Introdu titlul și adresa serviciului.", "x": 33.0, "y": 38.8}, {"text": "Alege pictograma, apoi Salvează. Anulează păstrează marcajele existente.", "x": 32.0, "y": 50.3}]} />

## Editează sau elimină marcaje

Deschide Servicii → Gestionează marcajele. Modificările privesc scurtăturile salvate, nu cardul sau documentele semnate.

<GuideScreenshot src="/img/guide/android-tablet/ro/bookmarks.png" alt="Editează sau elimină marcaje" steps={[{"text": "Atinge rândul unui marcaj pentru titlu, adresă sau pictogramă și salvează."}, {"text": "Folosește coșul pentru eliminare sau Adaugă marcaj pentru un marcaj nou. Închide revine la navigare.", "x": 57.1, "y": 67.0}]} />

## Resetează sesiunea unui site

Deschide Servicii → Șterge datele de navigare. Ștergerea cookie-urilor te deconectează. Cookie-urile sau istoricul închid pagina curentă; documentele aplicației rămân salvate.

<GuideScreenshot src="/img/guide/android-tablet/ro/browser-data.png" alt="Resetează sesiunea unui site" steps={[{"text": "Selectează cache, cookie-uri și/sau istoricul browserului, după necesitate.", "x": 33.5, "y": 50.4}, {"text": "Atinge Șterge datele selectate sau Anulează pentru păstrarea sesiunii.", "x": 53.7, "y": 60.6}]} />

## 14. Consultă sau recitește cardul

Deschide **Setări → Carduri și cititoare** pentru a consulta un card conectat. În ecranul Semnează, butonul de informații din dreapta sus deschide detaliile cardului. Gestionează PIN-urile în **Setări → Carduri și PIN-uri salvate**. Cardul și PIN-ul memorate sunt comune pentru NFC și USB.

## 15. Limbă, aspect, demonstrație și suport

Deschide **Setări** pentru a găsi Modul demonstrativ în partea de sus, apoi cardurile, PIN-urile salvate, limba și aspectul. Modul demonstrativ folosește date fictive și nu produce semnături valide.

Deschide **Setări → Carduri și cititoare** pentru a consulta un card conectat. În ecranul Semnează, butonul de informații din dreapta sus deschide detaliile cardului. Gestionează PIN-urile în **Setări → Carduri și PIN-uri salvate**. Cardul și PIN-ul memorate sunt comune pentru NFC și USB.

Alege româna, engleza, rusa sau limba sistemului și aspectul Luminos, Întunecat sau Sistem. În Despre găsești versiunea instalată și legăturile de asistență. Activează ștampila PDF din browser dacă vrei o marcă vizibilă pentru solicitările acceptate.

<GuideScreenshot src="/img/guide/android-tablet/ro/cards-current.png" alt="Carduri și cititoare în Setări" steps={[{"text": "Carduri și cititoare în Setări", "x": 36.3, "y": 29.5}]} />

În Setări → Carduri și PIN-uri salvate găsești și cardurile deconectate. Uită cardul elimină identitatea și eventualul PIN salvat pe acest dispozitiv, atât pentru USB, cât și pentru NFC. PIN-ul de pe card rămâne același.

<GuideScreenshot src="/img/guide/android-tablet/ro/saved-cards.png" alt="Carduri și PIN-uri salvate" steps={[{"text": "Alege Uită cardul și confirmă numele cardului.", "x": 59.1, "y": 55.4}]} />

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

Deschide **Documente**, apoi alege **Mai multe acțiuni → Protejează fișiere** în bara de sus. Alege **Criptează** sau **Decriptează**, apoi un fișier accesibil.

Nu ai nevoie de card. Creează o parolă pentru fișier și transmite-o destinatarului printr-un canal de încredere separat. Nu este PIN-ul cardului. Criptarea creează un rezultat separat; păstrează originalul până verifici rezultatul.

În eSemnBun 0.2.13 sau mai nou, alege **Parolă** și selectează AES-128, AES-192 sau AES-256. Opțiunea implicită este AES-256. Pentru a cripta pentru un destinatar, alege **Certificat RSA** și selectează certificatul său public de criptare (.cer sau .der). Implicit, folosește un certificat destinat criptării. **Compatibilitate cu cheia publică a cardului** permite explicit cheia RSA publică a cardului. Exportul sau criptarea reușită nu dovedesc că acel card poate decripta; cardul corespunzător trebuie să permită operația necesară cu cheia privată.

<GuideScreenshot src="/img/guide/android-tablet/ro/protect-menu-light.png" alt="Deschide protecția fișierelor" steps={[{"text": "Deschide meniul de navigare și alege Protejează fișiere.", "x": 89.3, "y": 13.6}]} />

<GuideScreenshot src="/img/guide/android-tablet/ro/protect-password-light.png" alt="Criptează un fișier cu parolă" steps={[{"text": "Alege Criptează și selectează fișierul sursă.", "x": 45.7, "y": 26.6}, {"text": "Alege Parolă și dimensiunea cheii AES. Inițial este selectat AES-256.", "x": 60.0, "y": 43.5}, {"text": "Introdu și confirmă parola fișierului, apoi alege Criptează.", "x": 30.6, "y": 57.0}]} />

<GuideScreenshot src="/img/guide/android-tablet/ro/protect-certificate-light.png" alt="Criptează pentru un destinatar RSA" steps={[{"text": "Pentru un destinatar cu o cheie de criptare RSA, alege Certificat RSA.", "x": 59.3, "y": 31.8}, {"text": "Selectează certificatul public .cer sau .der al destinatarului. Pentru propriul card, conectează cititorul și alege Citește cardul meu.", "x": 39.2, "y": 45.6}, {"text": "Folosește Compatibilitate cu cheia publică a cardului doar când fluxul cere cheia RSA publică a cardului.", "x": 48.4, "y": 37.3}]} />

<GuideScreenshot src="/img/guide/android-tablet/ro/protect-complete-light.png" alt="Fișier criptat salvat" steps={[{"text": "Verifică numele fișierului salvat. Rezultatul este deja în Documente.", "x": 29.6, "y": 27.9}, {"text": "Alege Salvează ca… numai dacă dorești și o copie în alt loc.", "x": 45.5, "y": 84.6}, {"text": "Alege Închide pentru a reveni în aplicație. Fișierul salvat rămâne în Documente.", "x": 46.8, "y": 89.0}]} />

Alege **Criptează** sau **Decriptează**. Rezultatul este salvat automat în spațiul privat al aplicației și apare în **Documente → Documente salvate**. Alege **Închide** la final sau **Salvează ca…** pentru a-l exporta prin selectorul de fișiere Android. Originalul este păstrat.

Documente salvate include fișiere semnate, criptate și decriptate. Identifică rezultatul după numele fișierului și eticheta operațiunii. Criptarea nu creează o semnătură digitală; fișierele criptate trebuie decriptate înainte de deschiderea sau verificarea conținutului.


## Decriptează un fișier primit

Deschide **Documente**, apoi alege **Mai multe acțiuni → Protejează fișiere** în bara de sus. Alege **Criptează** sau **Decriptează**, apoi un fișier accesibil.

Pentru un fișier criptat cu parolă, cere parola expeditorului printr-un canal de încredere separat. Fișierul specifică dimensiunea cheii AES. Pentru fișierele RSA, conectează cardul care conține cheia de criptare a destinatarului, citește cardul și autorizează decriptarea cu PIN-ul său.

<GuideScreenshot src="/img/guide/android-tablet/ro/protect-menu-light.png" alt="Deschide protecția fișierelor" steps={[{"text": "Deschide meniul de navigare și alege Protejează fișiere.", "x": 89.3, "y": 13.6}]} />

<GuideScreenshot src="/img/guide/android-tablet/ro/protect-decrypt-light.png" alt="Decriptează un fișier primit" steps={[{"text": "Alege Decriptează și selectează fișierul criptat primit.", "x": 42.5, "y": 26.6}, {"text": "Introdu parola primită de la expeditor în câmpul Parolă.", "x": 30.6, "y": 42.1}, {"text": "Alege Decriptează. Rezultatul nou este salvat în Documente.", "x": 45.9, "y": 89.0}]} />

<GuideScreenshot src="/img/guide/android-tablet/ro/protect-rsa-decrypt-light.png" alt="Decriptează cu cardul destinatarului" steps={[{"text": "Selectează fișierul criptat. Aplicația identifică formatul cu certificat RSA.", "x": 29.6, "y": 36.8}, {"text": "Conectează cardul care conține cheia privată a destinatarului. Citește cardul, apoi autorizează decriptarea cu PIN-ul său.", "x": 36.6, "y": 46.0}]} />

<GuideScreenshot src="/img/guide/android-tablet/ro/protect-decrypt-complete-light.png" alt="Fișier decriptat salvat" steps={[{"text": "Verifică numele fișierului salvat. Rezultatul este deja în Documente.", "x": 29.6, "y": 27.9}, {"text": "Alege Salvează ca… numai dacă dorești și o copie în alt loc.", "x": 45.5, "y": 84.6}, {"text": "Alege Închide pentru a reveni în aplicație. Fișierul salvat rămâne în Documente.", "x": 46.8, "y": 89.0}]} />

Deschide și verifică rezultatul salvat înainte de utilizare. Criptarea compatibilă MoldSign nu autentifică conținutul: decriptarea reușită nu dovedește singură integritatea sau parola corectă.

Alege **Criptează** sau **Decriptează**. Rezultatul este salvat automat în spațiul privat al aplicației și apare în **Documente → Documente salvate**. Alege **Închide** la final sau **Salvează ca…** pentru a-l exporta prin selectorul de fișiere Android. Originalul este păstrat.

Documente salvate include fișiere semnate, criptate și decriptate. Identifică rezultatul după numele fișierului și eticheta operațiunii. Criptarea nu creează o semnătură digitală; fișierele criptate trebuie decriptate înainte de deschiderea sau verificarea conținutului.
