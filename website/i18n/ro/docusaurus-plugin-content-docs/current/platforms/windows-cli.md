---
title: Windows CLI
---

import GuideScreenshot from '@site/src/components/GuideScreenshot';

# Windows — ghid pentru linia de comandă

Urmează exemplele numerotate pentru a atinge un scop concret. Comenzile rămân în engleză. Panourile ilustrează comenzi, nu o semnare reală cu un card. Doar rezultatele de capabilități și verificarea fișierului fără semnături au fost capturate local; nu a fost folosit niciun PIN, card sau furnizor de secrete real.

Pentru operațiuni cu cardul ai nevoie de un act electronic acceptat, PIN-ul corect, un cititor USB compatibil și adaptorul necesar. NFC nu este acceptat. Verificarea nu necesită cititor sau PIN. Păstrează originalele. Cheia privată rămâne pe card.

:::info
CLI Windows acceptă momentan help, capabilities, readers, cert, sign-hex și mcp. Comenzile normale sign/xades/verify/server/cms-for-hash nu sunt implementate. Pentru documente folosește aplicația desktop sau instrumentele MCP configurate separat pentru verificare/semnare nesupravegheată. MCP Windows nu are broker desktop de aprobare. Nu presupune paritate cu macOS/Linux.
:::

## 1. Instalează și descoperă funcțiile disponibile

Deschide [Descărcări](/downloads/) și alege platforma. Arhivele CLI conțin instrumentele de terminal și MCP; aplicația desktop se instalează separat. Folosește instrucțiunile pentru gestionarul de pachete, versiunea curentă și amprenta cheii. Localizează comanda și verifică funcțiile înainte de automatizare.

<GuideScreenshot src="/img/guide/windows-cli/ro/install.svg" alt="1. Instalează și descoperă funcțiile disponibile" caption="Exemplu ilustrativ de comandă. Copiază comenzile de mai jos și înlocuiește căile și numele cititorului." steps={[{"x": 3, "y": 30.6, "text": "Instalează prin canalul platformei ales."}, {"x": 3, "y": 78.3, "text": "Verifică funcțiile înainte de operațiuni cu cardul."}]} />

```powershell
scoop bucket add esemnbun https://github.com/xfreebird/homebrew-utils
scoop install esemnbun/esemnbun-cli
Get-Command esemnbun
esemnbun capabilities --json
```

Pentru Chocolatey, descarcă .nupkg într-un dosar gol, apoi execută:

```powershell
choco install esemnbun-cli --source . --yes
```

## 2. Găsește cititorul și verifică certificatul

Conectează cititorul USB și introdu cardul. Listează cititoarele și citește certificatul fără PIN. Cu mai multe carduri, folosește numele exact al cititorului și verifică titularul înainte de semnare. Acestea sunt exemple; ghidul nu a accesat un cititor.

<GuideScreenshot src="/img/guide/windows-cli/ro/reader.svg" alt="2. Găsește cititorul și verifică certificatul" caption="Exemplu ilustrativ de comandă. Copiază comenzile de mai jos și înlocuiește căile și numele cititorului." steps={[{"x": 3, "y": 47.7, "text": "Listează cititoarele și prezența cardului."}, {"x": 3, "y": 66.2, "text": "Citește certificatul dorit; înlocuiește numele cititorului."}]} />

```powershell
esemnbun readers
esemnbun cert --reader "miniLector EVO" --out leaf.der
```

## 3. Verifică și interpretează rezultatul

Verificarea offline pe Windows este oferită de MCP verify_document, nu de comanda normală verify. Configurează o rădăcină explicită și intrarea `{rootId,relativePath}`; citește integritatea, semnătura și lanțul. Originalele lipsă necesită rădăcina detașată explicită. Nu se folosește cititor/PIN și nu se verifică revocarea curentă.

## 4. Conectează un client MCP cu acces explicit

Configurează un client local compatibil cu protocolul folosind calea absolută a executabilului și un dosar autorizat ales de tine. Înlocuiește cu propriul dosar fizic existent. Rădăcinile declarate de client nu acordă acces. Legăturile simbolice, traversarea și fișierele speciale sunt respinse. Fără rădăcini ai doar descoperire. Helperul folosește stdio, nu un serviciu de semnare în rețea. Limita este8MiB; originalele XML necesită o rădăcină detașată explicită.

<GuideScreenshot src="/img/guide/windows-cli/ro/mcp.svg" alt="5. Conectează un client MCP cu acces explicit" caption="Exemplu ilustrativ de comandă. Copiază comenzile de mai jos și înlocuiește căile și numele cititorului." steps={[{"x": 3, "y": 58.5, "text": "Alege executabilul instalat și un dosar restrâns."}, {"text": "Descoperă funcțiile și cere verificare offline din client."}]} />

```powershell
esemnbun mcp --root "documents=C:\Users\me\Documents\Signing"
```

Începe cu `capabilities` și `verify_document`. Intrarea identifică `{rootId,relativePath}`; nu trimite PIN sau conținutul documentului ca argumente. Rezultatele includ metadate minime. Clientul poate trimite metadatele propriilor servicii externe. Consultă [configurarea și politica MCP](https://esemnbun.md/packages/mcp.md).

```json
{
  "command": "C:\\Program Files\\eSemnBun\\bin\\esemnbun.exe",
  "args": [
    "mcp",
    "--root",
    "documents=C:\\Users\\me\\Documents\\Signing"
  ]
}
```

```json
{"input":{"rootId":"documents","relativePath":"Contract-semnat.pdf"}}
```

## 5. Configurează semnarea nesupravegheată explicită

Această opțiune avansată semnează fără dialog per document. Pregătește separat secretele, fixează amprenta SHA-256 DER exactă a certificatului și creează un dosar privat pentru rezultate. Folosește referințe către furnizori, nu valori PIN. Certificatul este verificat înainte de citirea secretului sau VERIFY. Validează cardul și furnizorul în instalarea ta înainte de producție.

<GuideScreenshot src="/img/guide/windows-cli/ro/unattended.svg" alt="7. Configurează semnarea nesupravegheată explicită" caption="Exemplu ilustrativ de comandă. Copiază comenzile de mai jos și înlocuiește căile și numele cititorului." steps={[{"x": 3, "y": 27.4, "text": "Configurează intrarea restrânsă și dosarul privat de rezultate."}, {"x": 3, "y": 80.6, "text": "Fixează certificatul exact și alege referința secretului."}]} />

```powershell
esemnbun mcp `
  --root "documents=C:\Users\me\Documents\Signing" `
  --allow-unattended-signing `
  --signing-certificate-sha256 <CERTIFICATE_SHA256> `
  --signing-output-directory C:\Users\me\PrivateOutput `
  --pin-source credential:eSemnBun-Automation
```

macOS: `keychain:service:account`, `env:ESEMNBUN_AUTOMATION_PIN` sau `onepassword:op://Vault/Item/field`. Linux: mediu sau1Password. Windows: `credential:eSemnBun-Automation`, mediu sau1Password cu o cale absolută op.exe. Intrarea Keychain/Credential Manager se pregătește separat; seiful biometric al aplicației rămâne protejat. Autentifică1Password în afara MCP.

Înlocuiește `<CERTIFICATE_SHA256>` cu64cifre hexazecimale exacte înainte de executare. Dosarul rezultat trebuie să existe; macOS/Linux cer proprietar curent și0700. ACL Windows permite doar contul tău, SYSTEM și Administrators.

Înainte de semnare se creează `.unattended-signing-lock` în dosarul rezultatelor. PIN-ul greșit, întreruperea sau o eroare incertă păstrează marcajul și blochează o nouă încercare automată. Verifică rezultatele și cardul, clarifică situația, apoi elimină marcajul și repornește doar când este corect. Nu automatiza ștergerea/reîncercarea. Anularea sau expirarea nu demonstrează că nu s-a semnat.

---

Referință avansată: macOS/Linux oferă și `sign-hex <digestinfo_hex>`, `cms-for-hash <sha256_hex>`; Windows doar sign-hex. Sunt primitive pentru dezvoltatori, nu semnare de documente. Pentru suport trimite versiunea aplicației/sistemului, comanda fără secrete, codul și un exemplu fictiv. Nu atașa PIN sau documente confidențiale.
