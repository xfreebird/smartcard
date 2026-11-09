---
title: "Configurează semnarea nesupravegheată — Mac · Linie de comandă (CLI)"
sidebar_label: "Configurează semnarea nesupravegheată"
description: "Fixează certificatul, alege sursa secretului și restricționează rezultatele."
pagination_prev: "platforms/macos-cli/approval"
pagination_next: "platforms/macos-cli/service"
---

import GuideScreenshot from '@site/src/components/GuideScreenshot';

# Configurează semnarea nesupravegheată — Mac · Linie de comandă (CLI)

[Ghidurile platformei](../macos-cli.md) · [Instalare și conectarea cititorului](./setup.md) · [Conectează un agent prin MCP](./mcp.md)

Fixează certificatul, alege sursa secretului și restricționează rezultatele.

## Configurează semnarea nesupravegheată explicită

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
