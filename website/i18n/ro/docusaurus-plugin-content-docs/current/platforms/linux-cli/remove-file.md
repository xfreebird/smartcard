---
title: "Elimină un fișier local — Linux · Linie de comandă (CLI)"
sidebar_label: "Elimină un fișier local"
description: "Elimină un fișier local"
pagination_prev: "platforms/linux-cli/share-certificate"
pagination_next: null
---

import GuideScreenshot from '@site/src/components/GuideScreenshot';

# Elimină un fișier local — Linux · Linie de comandă (CLI)

[Ghidurile platformei](../linux-cli.md) · [Instalare și conectarea cititorului](./setup.md)

Elimină un fișier local

Ilustrațiile folosesc date fictive. Urmează instrucțiunile în aplicația instalată.

## Elimină un fișier local

Doar pe desktop. Operațiunea elimină definitiv un fișier local obișnuit acceptat, după confirmare. Nu garantează ștergerea de pe SSD, din instantanee, copii de rezervă sau alte copii. Locațiile neacceptate și legăturile sunt refuzate. Furnizorii de documente mobili nu acceptă operațiunea.

Exemplu ilustrativ de comandă — operațiunea nu a fost executată.

<GuideScreenshot src="/img/guide/linux-cli/ro/protect-remove.svg" alt="Elimină un fișier local" steps={[{"x": 20, "y": 25, "text": "Rulează comanda cu propriile fișiere. Folosește o cale nouă pentru rezultat. Introdu secretele numai în solicitarea ascunsă; înlocuiește SHA256 cu amprenta completă a certificatului de criptare."}]} />

```sh
esemnbun remove-file disposable-copy.pdf --confirm-removal
```
