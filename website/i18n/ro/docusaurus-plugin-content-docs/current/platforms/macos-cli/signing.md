---
title: "Semnează documente — Mac · Linie de comandă (CLI)"
sidebar_label: "Semnează documente"
description: "Adaugă fișiere, alege formatul și ștampila, aprobă și salvează rezultatul."
pagination_prev: "platforms/macos-cli/setup"
pagination_next: "platforms/macos-cli/verification"
---

import GuideScreenshot from '@site/src/components/GuideScreenshot';

# Semnează documente — Mac · Linie de comandă (CLI)

[Ghidurile platformei](../macos-cli.md) · [Instalare și conectarea cititorului](./setup.md)

Adaugă fișiere, alege formatul și ștampila, aprobă și salvează rezultatul.

## Semnează PDF sau creează o semnătură XML

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
