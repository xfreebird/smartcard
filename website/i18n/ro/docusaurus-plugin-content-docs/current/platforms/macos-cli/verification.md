---
title: "Verifică o semnătură — Mac · Linie de comandă (CLI)"
sidebar_label: "Verifică o semnătură"
description: "Verifică un PDF sau XML și inspectează semnatarul și certificatul."
pagination_prev: "platforms/macos-cli/signing"
pagination_next: "platforms/macos-cli/mcp"
---

import GuideScreenshot from '@site/src/components/GuideScreenshot';

# Verifică o semnătură — Mac · Linie de comandă (CLI)

[Ghidurile platformei](../macos-cli.md) · [Instalare și conectarea cititorului](./setup.md)

Verifică un PDF sau XML și inspectează semnatarul și certificatul.

## Verifică și interpretează rezultatul

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
