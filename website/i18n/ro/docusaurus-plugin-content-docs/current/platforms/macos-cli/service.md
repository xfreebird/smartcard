---
title: "Pornește serviciul pentru browser — Mac · Linie de comandă (CLI)"
sidebar_label: "Pornește serviciul pentru browser"
description: "Pornește și oprește conexiunea locală sau serviciul utilizatorului."
pagination_prev: "platforms/macos-cli/unattended"
pagination_next: "platforms/macos-cli/encrypt-password"
---

import GuideScreenshot from '@site/src/components/GuideScreenshot';

# Pornește serviciul pentru browser — Mac · Linie de comandă (CLI)

[Ghidurile platformei](../macos-cli.md) · [Instalare și conectarea cititorului](./setup.md)

Pornește și oprește conexiunea locală sau serviciul utilizatorului.

Ilustrațiile folosesc date fictive. Urmează instrucțiunile în aplicația instalată.

## Rulează conexiunea locală cu browserul

Rulează bridge-ul în prim-plan cât timp folosești site-ul pe același calculator. Implicit: HTTP18480 și HTTPS18443 pe loopback. Nu porni simultan bridge-ul GUI sau MoldSign pe aceleași porturi. Oprește cu Ctrl+C. Pachetul necesită identitatea HTTPS localhost. Pentru dialoguri native de acord/PIN folosește aplicația desktop.

<GuideScreenshot src="/img/guide/macos-cli/ro/service.svg" alt="8. Rulează conexiunea locală cu browserul" caption="Exemplu ilustrativ de comandă. Copiază comenzile de mai jos și înlocuiește căile și numele cititorului." steps={[{"x": 3, "y": 33.8, "text": "Pornește bridge-ul local pentru browser."}, {"x": 3, "y": 76.1, "text": "Oprește cu Ctrl+C la final."}]} />

```sh
esemnbun server
# Ctrl+C
```

---

Referință avansată: macOS/Linux oferă și `sign-hex <digestinfo_hex>`, `cms-for-hash <sha256_hex>`; Windows doar sign-hex. Sunt primitive pentru dezvoltatori, nu semnare de documente. Pentru suport trimite versiunea aplicației/sistemului, comanda fără secrete, codul și un exemplu fictiv. Nu atașa PIN sau documente confidențiale.

<!-- file-protection-guides -->
