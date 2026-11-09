---
title: "Decriptează un fișier primit — Mac · Linie de comandă (CLI)"
sidebar_label: "Decriptează un fișier primit"
description: "Decriptează un fișier primit"
pagination_prev: "platforms/macos-cli/encrypt-certificate"
pagination_next: "platforms/macos-cli/share-certificate"
---

import GuideScreenshot from '@site/src/components/GuideScreenshot';

# Decriptează un fișier primit — Mac · Linie de comandă (CLI)

[Ghidurile platformei](../macos-cli.md) · [Instalare și conectarea cititorului](./setup.md)

Decriptează un fișier primit

Ilustrațiile folosesc date fictive. Urmează instrucțiunile în aplicația instalată.

## Decriptează un fișier primit

Întreabă expeditorul ce metodă a folosit. Pentru fișiere cu parolă, obține parola separat. Pentru fișiere cu certificat, conectează cardul corespunzător și cititorul compatibil; ai nevoie de cheia de criptare și PIN. Alt card sau un card doar pentru semnare nu poate decripta fișierul.

Exemplu ilustrativ de comandă — operațiunea nu a fost executată.

<GuideScreenshot src="/img/guide/macos-cli/ro/protect-decrypt.svg" alt="Decriptează un fișier primit" steps={[{"x": 20, "y": 25, "text": "Rulează comanda cu propriile fișiere. Folosește o cale nouă pentru rezultat. Introdu secretele numai în solicitarea ascunsă; înlocuiește SHA256 cu amprenta completă a certificatului de criptare."}]} />

```sh
esemnbun decrypt Contract.enc Contract-opened.pdf
esemnbun encryption-certs
esemnbun decrypt Contract.enc Contract-opened.pdf --card SHA256
```

Deschide și verifică rezultatul salvat înainte de utilizare. Criptarea compatibilă MoldSign nu autentifică conținutul: decriptarea reușită nu dovedește singură integritatea sau parola corectă.
