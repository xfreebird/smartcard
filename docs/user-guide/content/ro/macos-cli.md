---
title: macOS CLI
---

import GuideScreenshot from '@site/src/components/GuideScreenshot';

# macOS — ghid pentru linia de comandă

Urmează exemplele numerotate pentru a atinge un scop concret. Comenzile rămân în engleză. Panourile ilustrează comenzi, nu o semnare reală cu un card. Doar rezultatele de capabilități și verificarea fișierului fără semnături au fost capturate local; nu a fost folosit niciun PIN, card sau furnizor de secrete real.

Pentru operațiuni cu cardul ai nevoie de un act electronic acceptat, PIN-ul corect, un cititor USB compatibil și adaptorul necesar. NFC nu este acceptat. Verificarea nu necesită cititor sau PIN. Păstrează originalele. Cheia privată rămâne pe card.

## 1. Instalează și descoperă funcțiile disponibile

Deschide [Descărcări](/downloads/) și alege platforma. Arhivele CLI conțin instrumentele de terminal și MCP; aplicația desktop se instalează separat. Folosește instrucțiunile pentru gestionarul de pachete, versiunea curentă și amprenta cheii. Localizează comanda și verifică funcțiile înainte de automatizare.

<GuideScreenshot src="/img/guide/macos-cli/ro/install.svg" alt="1. Instalează și descoperă funcțiile disponibile" caption="Exemplu ilustrativ de comandă. Copiază comenzile de mai jos și înlocuiește căile și numele cititorului." steps={[{"x": 3, "y": 23.8, "text": "Instalează prin canalul platformei ales."}, {"x": 3, "y": 83.2, "text": "Verifică funcțiile înainte de operațiuni cu cardul."}]} />

```sh
brew install xfreebird/utils/esemnbun-cli
command -v esemnbun
esemnbun capabilities --json
```

<GuideScreenshot src="/img/guide/macos-cli/ro/capability.svg" alt="ghid pentru linia de comandă" caption="Rezultat local capturat: funcțiile disponibile, fără acces la card." steps={[{"x": 3, "y": 5.1, "text": "Verifică funcțiile înainte de operațiuni cu cardul."}]} />

```sh
esemnbun capabilities --json
```

Versiunea locală capturată raportează MCP indisponibil în CLI normal; helperul separat esemnbun-mcp are propria descoperire. Verifică executabilele instalate.

## 2. Găsește cititorul și verifică certificatul

Conectează cititorul USB și introdu cardul. Listează cititoarele și citește certificatul fără PIN. Cu mai multe carduri, folosește numele exact al cititorului și verifică titularul înainte de semnare. Acestea sunt exemple; ghidul nu a accesat un cititor.

<GuideScreenshot src="/img/guide/macos-cli/ro/reader.svg" alt="2. Găsește cititorul și verifică certificatul" caption="Exemplu ilustrativ de comandă. Copiază comenzile de mai jos și înlocuiește căile și numele cititorului." steps={[{"x": 3, "y": 23.8, "text": "Listează cititoarele și prezența cardului."}, {"x": 3, "y": 53.5, "text": "Citește certificatul dorit; înlocuiește numele cititorului."}, {"x": 3, "y": 83.2, "text": "Calculează SHA-256 pentru certificatul exportat. Folosește cele 64 de cifre hexazecimale pentru semnarea nesupravegheată, nu SHA-1 afișat de cert."}]} />

```sh
esemnbun readers
esemnbun cert --reader "miniLector EVO" --out leaf.der
shasum -a 256 leaf.der
```

## 3. Semnează PDF sau creează o semnătură XML

PAdES-T include semnătura și marca temporală în PDF. Fără calea rezultatului se creează separat `-semnat.pdf`; rezultatele existente nu sunt suprascrise. XAdES folosește implicit XML detașat și SHA-256: păstrează originalul neschimbat împreună cu XML-ul. BES nu are marcă temporală, T are marcă temporală, C adaugă referințe de certificat/revocare. Folosește `--enveloping` doar dacă destinatarul cere originalul în XML. Formatele temporizate necesită rețea; C obține și referințe de stare.

<GuideScreenshot src="/img/guide/macos-cli/ro/sign.svg" alt="3. Semnează PDF sau creează o semnătură XML" caption="Exemplu ilustrativ de comandă. Copiază comenzile de mai jos și înlocuiește căile și numele cititorului." steps={[{"x": 3, "y": 23.8, "text": "Pornește semnarea PDF și răspunde la solicitarea PIN fără afișare."}, {"x": 3, "y": 53.5, "text": "Creează nivelul XML cerut de destinatar."}, {"x": 3, "y": 83.2, "text": "Include originalul în XML doar la nevoie; păstrează originalele detașate."}]} />

```sh
esemnbun sign Contract.pdf Contract-semnat.pdf
esemnbun xades XAdES-T Declaration.txt Declaration.xml
esemnbun xades XAdES-BES Declaration.txt Embedded.xml --enveloping
```

Introdu PIN-ul doar în solicitarea fără afișare sau printr-un mecanism de intrare securizat cu `--pin-stdin`. Ordinea este stdin, `MSIGN_PIN`, apoi solicitarea. Nu pune PIN-ul în argumente, capturi, scripturi sau jurnale. După un PIN greșit oprește-te și verifică; nu reîncerca automat.

```sh
esemnbun sign Contract.pdf Contract-semnat.pdf --pin-stdin
```

## 4. Verifică și interpretează rezultatul

Alege PDF-ul sau XML-ul semnat. Pentru XML detașat, indică dosarul cu originalele neschimbate. Verificarea este offline: integritatea, semnătura și lanțul încorporat nu stabilesc starea curentă de revocare. `ok:true` înseamnă executare reușită, nu semnătură validă. Lipsa semnăturilor recunoscute nu este o verificare reușită a unui document semnat.

<GuideScreenshot src="/img/guide/macos-cli/ro/verify.svg" alt="4. Verifică și interpretează rezultatul" caption="Exemplu ilustrativ de comandă. Copiază comenzile de mai jos și înlocuiește căile și numele cititorului." steps={[{"x": 3, "y": 23.8, "text": "Verifică PDF sau XML cu dosarul originalelor."}, {"x": 3, "y": 83.2, "text": "Pentru automatizare citește status din JSON, nu doar ok."}]} />

```sh
esemnbun verify Contract-semnat.pdf
esemnbun verify Declaration.xml /home/me/Originals
esemnbun verify --json Contract-semnat.pdf
```

<GuideScreenshot src="/img/guide/macos-cli/ro/unsigned.svg" alt="ghid pentru linia de comandă" steps={[{"x": 3, "y": 16.7, "text": "Pentru automatizare citește status din JSON, nu doar ok."}]} />

```sh
esemnbun verify --json unsigned.pdf
```

`valid` și `unconfirmed` au cod0; al doilea lasă încrederea neconfirmată. `invalid`, `incomplete` și `no_recognized_signature` au cod2. Lipsa originalelor indică rezultat incomplet, nu dovada modificării. Cod1: utilizare/intrare; 3: PIN greșit; 4: PIN blocat; 5: lipsă cititor/card; 6: eroare de rețea la serviciile de încredere. Oprește-te după erori PIN; aplicația nu deblochează cardul.

## 5. Conectează un client MCP cu acces explicit

Configurează un client local compatibil cu protocolul folosind calea absolută a executabilului și un dosar autorizat ales de tine. Înlocuiește cu propriul dosar fizic existent. Rădăcinile declarate de client nu acordă acces. Legăturile simbolice, traversarea și fișierele speciale sunt respinse. Fără rădăcini ai doar descoperire. Helperul folosește stdio, nu un serviciu de semnare în rețea. Limita este8MiB; originalele XML necesită o rădăcină detașată explicită.

<GuideScreenshot src="/img/guide/macos-cli/ro/mcp.svg" alt="5. Conectează un client MCP cu acces explicit" caption="Exemplu ilustrativ de comandă. Copiază comenzile de mai jos și înlocuiește căile și numele cititorului." steps={[{"x": 3, "y": 58.5, "text": "Alege executabilul instalat și un dosar restrâns."}, {"text": "Descoperă funcțiile și cere verificare offline din client."}]} />

```sh
esemnbun-mcp --root documents=/Users/me/Documents/Signing
```

Începe cu `capabilities` și `verify_document`. Intrarea identifică `{rootId,relativePath}`; nu trimite PIN sau conținutul documentului ca argumente. Rezultatele includ metadate minime. Clientul poate trimite metadatele propriilor servicii externe. Consultă [configurarea și politica MCP](https://esemnbun.md/packages/mcp.md). [Configurări și abilități reutilizabile pentru zece agenți AI](https://esemnbun.md/docs/integrations/mcp-agents/) (în engleză).

```json
{
  "command": "/opt/homebrew/bin/esemnbun-mcp",
  "args": [
    "--root",
    "documents=/Users/me/Documents/Signing"
  ]
}
```

```json
{"input":{"rootId":"documents","relativePath":"Contract-semnat.pdf"}}
```

## 6. Cere semnare cu aprobare pe Mac

Activează brokerul de aprobare în Configurări pe Mac și folosește dosarul privat configurat. Aplicația și helperul trebuie să ruleze pentru același utilizator. Dosarul și subdosarele requests/responses/outputs trebuie să existe cu permisiuni0700. Pornește helperul cu acel dosar. Din client cere prepare_signing pentru PDF, verifică certificatul/documentul în aplicație, aprobă cu PIN, urmărește get_job și preia rezultatul. cancel_job cere anulare, dar nu anulează o semnătură deja creată. Cererile expiră după5minute, rezultatele se păstrează24ore. Ține aplicația pornită. Windows și Linux oferă și ele aprobare desktop cu dosarul privat al platformei; validează versiunea instalată.

<GuideScreenshot src="/img/guide/macos-cli/ro/broker.svg" alt="6. Cere semnare cu aprobare pe Mac" caption="Exemplu ilustrativ de comandă. Copiază comenzile de mai jos și înlocuiește căile și numele cititorului." steps={[{"x": 3, "y": 33.8, "text": "Activează brokerul pe Mac și folosește dosarul privat afișat."}, {"x": 3, "y": 76.1, "text": "Pregătește cererea în client și aprobă în aplicație."}]} />

```sh
esemnbun-mcp --root documents=/Users/me/Documents/Signing \
  --broker-directory /Users/me/PrivateBroker
```

## 7. Configurează semnarea nesupravegheată explicită

Această opțiune avansată semnează fără dialog per document. Pregătește separat secretele, fixează amprenta SHA-256 DER exactă a certificatului și creează un dosar privat pentru rezultate. Folosește referințe către furnizori, nu valori PIN. Certificatul este verificat înainte de citirea secretului sau VERIFY. Validează cardul și furnizorul în instalarea ta înainte de producție.

<GuideScreenshot src="/img/guide/macos-cli/ro/unattended.svg" alt="7. Configurează semnarea nesupravegheată explicită" caption="Exemplu ilustrativ de comandă. Copiază comenzile de mai jos și înlocuiește căile și numele cititorului." steps={[{"x": 3, "y": 27.4, "text": "Configurează intrarea restrânsă și dosarul privat de rezultate."}, {"x": 3, "y": 80.6, "text": "Fixează certificatul exact și alege referința secretului."}]} />

```sh
esemnbun-mcp \
  --root documents=/Users/me/Documents/Signing \
  --allow-unattended-signing \
  --signing-certificate-sha256 <CERTIFICATE_SHA256> \
  --signing-output-directory /Users/me/PrivateOutput \
  --pin-source keychain:service:account
```

macOS: `keychain:service:account`, `env:ESEMNBUN_AUTOMATION_PIN` sau `onepassword:op://Vault/Item/field`. Linux: `secret-service:service:account`, mediu sau1Password. Windows: `credential:eSemnBun-Automation`, mediu sau1Password cu o cale absolută op.exe. Intrarea Keychain/Credential Manager se pregătește separat; seiful biometric al aplicației rămâne protejat. Autentifică1Password în afara MCP.

Înlocuiește `<CERTIFICATE_SHA256>` cu64cifre hexazecimale exacte înainte de executare. Dosarul rezultat trebuie să existe; macOS/Linux cer proprietar curent și0700. ACL Windows permite doar contul tău, SYSTEM și Administrators.

Înainte de semnare se creează `.unattended-signing-lock` în dosarul rezultatelor. PIN-ul greșit, întreruperea sau o eroare incertă păstrează marcajul și blochează o nouă încercare automată. Verifică rezultatele și cardul, clarifică situația, apoi elimină marcajul și repornește doar când este corect. Nu automatiza ștergerea/reîncercarea. Anularea sau expirarea nu demonstrează că nu s-a semnat.

## 8. Rulează conexiunea locală cu browserul

Rulează bridge-ul în prim-plan cât timp folosești site-ul pe același calculator. Implicit: HTTP18480 și HTTPS18443 pe loopback. Nu porni simultan bridge-ul GUI sau MoldSign pe aceleași porturi. Oprește cu Ctrl+C. Pachetul necesită identitatea HTTPS localhost. Pentru dialoguri native de acord/PIN folosește aplicația desktop.

<GuideScreenshot src="/img/guide/macos-cli/ro/service.svg" alt="8. Rulează conexiunea locală cu browserul" caption="Exemplu ilustrativ de comandă. Copiază comenzile de mai jos și înlocuiește căile și numele cititorului." steps={[{"x": 3, "y": 33.8, "text": "Pornește bridge-ul local pentru browser."}, {"x": 3, "y": 76.1, "text": "Oprește cu Ctrl+C la final."}]} />

```sh
esemnbun server
# Ctrl+C
```

---

Referință avansată: macOS/Linux oferă și `sign-hex <digestinfo_hex>`, `cms-for-hash <sha256_hex>`; Windows doar sign-hex. Sunt primitive pentru dezvoltatori, nu semnare de documente. Pentru suport trimite versiunea aplicației/sistemului, comanda fără secrete, codul și un exemplu fictiv. Nu atașa PIN sau documente confidențiale.

<!-- file-protection-guides -->


## Criptează un fișier cu parolă

Nu ai nevoie de card. Creează o parolă pentru fișier și transmite-o destinatarului printr-un canal de încredere separat. Nu este PIN-ul cardului. Criptarea creează un rezultat separat; păstrează originalul până verifici rezultatul.

Exemplu ilustrativ de comandă — operațiunea nu a fost executată.

<GuideScreenshot src="/img/guide/macos-cli/ro/protect-password.svg" alt="Criptează un fișier cu parolă" steps={[{"x": 20, "y": 25, "text": "Rulează comanda cu propriile fișiere. Folosește o cale nouă pentru rezultat. Introdu secretele numai în solicitarea ascunsă; înlocuiește SHA256 cu amprenta completă a certificatului de criptare."}]} />

```sh
esemnbun encrypt Contract.pdf Contract.enc
```


## Criptează pentru titularul unui certificat

Implicit, comenzile pentru certificat/card folosesc un certificat de criptare. Adaugă `--card-public-key` doar pentru fluxul explicit de compatibilitate cu cheia publică a cardului. Criptarea sau exportul reușit al certificatului nu dovedesc suportul pentru decriptare: cardul corespunzător trebuie să permită operația necesară cu cheia privată.

Cere destinatarului certificatul public de criptare (.cer/.der), exportat conform ghidului următor. Confirmă amprenta cu titularul printr-un canal de încredere. Un certificat doar pentru semnare nu este suficient. Pentru criptare ai nevoie de certificatul public, nu de cardul, cheia privată sau PIN-ul destinatarului.

Exemplu ilustrativ de comandă — operațiunea nu a fost executată.

<GuideScreenshot src="/img/guide/macos-cli/ro/protect-certificate.svg" alt="Criptează pentru titularul unui certificat" steps={[{"x": 20, "y": 25, "text": "Rulează comanda cu propriile fișiere. Folosește o cale nouă pentru rezultat. Introdu secretele numai în solicitarea ascunsă; înlocuiește SHA256 cu amprenta completă a certificatului de criptare."}]} />

```sh
esemnbun encrypt Contract.pdf Contract.enc --certificate recipient.cer
```


## Decriptează un fișier primit

Implicit, comenzile pentru certificat/card folosesc un certificat de criptare. Adaugă `--card-public-key` doar pentru fluxul explicit de compatibilitate cu cheia publică a cardului. Criptarea sau exportul reușit al certificatului nu dovedesc suportul pentru decriptare: cardul corespunzător trebuie să permită operația necesară cu cheia privată.

Întreabă expeditorul ce metodă a folosit. Pentru fișiere cu parolă, obține parola separat. Pentru fișiere cu certificat, conectează cardul corespunzător și cititorul compatibil; ai nevoie de cheia de criptare și PIN. Alt card sau un card doar pentru semnare nu poate decripta fișierul.

Exemplu ilustrativ de comandă — operațiunea nu a fost executată.

<GuideScreenshot src="/img/guide/macos-cli/ro/protect-decrypt.svg" alt="Decriptează un fișier primit" steps={[{"x": 20, "y": 25, "text": "Rulează comanda cu propriile fișiere. Folosește o cale nouă pentru rezultat. Introdu secretele numai în solicitarea ascunsă; înlocuiește SHA256 cu amprenta completă a certificatului de criptare."}]} />

```sh
esemnbun decrypt Contract.enc Contract-opened.pdf
esemnbun encryption-certs
esemnbun decrypt Contract.enc Contract-opened.pdf --card SHA256
```

Deschide și verifică rezultatul salvat înainte de utilizare. Criptarea compatibilă MoldSign nu autentifică conținutul: decriptarea reușită nu dovedește singură integritatea sau parola corectă.


## Distribuie certificatul tău de criptare

Implicit, comenzile pentru certificat/card folosesc un certificat de criptare. Adaugă `--card-public-key` doar pentru fluxul explicit de compatibilitate cu cheia publică a cardului. Criptarea sau exportul reușit al certificatului nu dovedesc suportul pentru decriptare: cardul corespunzător trebuie să permită operația necesară cu cheia privată.

Conectează cardul și cititorul USB compatibil. Exportul certificatului public nu necesită document sau PIN. Cardul trebuie să ofere o identitate de criptare; certificatul obișnuit de semnare nu îl înlocuiește.

Exemplu ilustrativ de comandă — operațiunea nu a fost executată.

<GuideScreenshot src="/img/guide/macos-cli/ro/protect-export.svg" alt="Distribuie certificatul tău de criptare" steps={[{"x": 20, "y": 25, "text": "Rulează comanda cu propriile fișiere. Folosește o cale nouă pentru rezultat. Introdu secretele numai în solicitarea ascunsă; înlocuiește SHA256 cu amprenta completă a certificatului de criptare."}]} />

```sh
esemnbun encryption-certs
esemnbun encryption-certs --card SHA256 --out recipient.cer
```

Distribuie numai recipient.cer; exportul nu cere PIN și nu exportă cheia privată.


## Elimină un fișier local

Doar pe desktop. Operațiunea elimină definitiv un fișier local obișnuit acceptat, după confirmare. Nu garantează ștergerea de pe SSD, din instantanee, copii de rezervă sau alte copii. Locațiile neacceptate și legăturile sunt refuzate. Furnizorii de documente mobili nu acceptă operațiunea.

Exemplu ilustrativ de comandă — operațiunea nu a fost executată.

<GuideScreenshot src="/img/guide/macos-cli/ro/protect-remove.svg" alt="Elimină un fișier local" steps={[{"x": 20, "y": 25, "text": "Rulează comanda cu propriile fișiere. Folosește o cale nouă pentru rezultat. Introdu secretele numai în solicitarea ascunsă; înlocuiește SHA256 cu amprenta completă a certificatului de criptare."}]} />

```sh
esemnbun remove-file disposable-copy.pdf --confirm-removal
```
