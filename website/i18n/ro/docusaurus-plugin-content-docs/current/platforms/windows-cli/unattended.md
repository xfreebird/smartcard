---
title: "Configurează semnarea nesupravegheată — Windows · Linie de comandă (CLI)"
sidebar_label: "Configurează semnarea nesupravegheată"
description: "Fixează certificatul, alege sursa secretului și restricționează rezultatele."
pagination_prev: "platforms/windows-cli/mcp"
pagination_next: "platforms/windows-cli/encrypt-password"
---

import GuideScreenshot from '@site/src/components/GuideScreenshot';

# Configurează semnarea nesupravegheată — Windows · Linie de comandă (CLI)

[Ghidurile platformei](../windows-cli.md) · [Instalare și conectarea cititorului](./setup.md) · [Conectează un agent prin MCP](./mcp.md)

Fixează certificatul, alege sursa secretului și restricționează rezultatele.

Ilustrațiile folosesc date fictive. Urmează instrucțiunile în aplicația instalată.

## Configurează semnarea nesupravegheată explicită

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

macOS: `keychain:service:account`, `env:ESEMNBUN_AUTOMATION_PIN` sau `onepassword:op://Vault/Item/field`. Linux: `secret-service:service:account`, mediu sau1Password. Windows: `credential:eSemnBun-Automation`, mediu sau1Password cu o cale absolută op.exe. Intrarea Keychain/Credential Manager se pregătește separat; seiful biometric al aplicației rămâne protejat. Autentifică1Password în afara MCP.

Înlocuiește `<CERTIFICATE_SHA256>` cu64cifre hexazecimale exacte înainte de executare. Dosarul rezultat trebuie să existe; macOS/Linux cer proprietar curent și0700. ACL Windows permite doar contul tău, SYSTEM și Administrators.

Înainte de semnare se creează `.unattended-signing-lock` în dosarul rezultatelor. PIN-ul greșit, întreruperea sau o eroare incertă păstrează marcajul și blochează o nouă încercare automată. Verifică rezultatele și cardul, clarifică situația, apoi elimină marcajul și repornește doar când este corect. Nu automatiza ștergerea/reîncercarea. Anularea sau expirarea nu demonstrează că nu s-a semnat.

---

Referință avansată: macOS/Linux oferă și `sign-hex <digestinfo_hex>`, `cms-for-hash <sha256_hex>`; Windows doar sign-hex. Sunt primitive pentru dezvoltatori, nu semnare de documente. Pentru suport trimite versiunea aplicației/sistemului, comanda fără secrete, codul și un exemplu fictiv. Nu atașa PIN sau documente confidențiale.

<!-- file-protection-guides -->
