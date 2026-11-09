---
title: "Distribuie certificatul tău de criptare — Mac · Linie de comandă (CLI)"
sidebar_label: "Distribuie certificatul tău de criptare"
description: "Distribuie certificatul tău de criptare"
pagination_prev: "platforms/macos-cli/decrypt-file"
pagination_next: "platforms/macos-cli/remove-file"
---

import GuideScreenshot from '@site/src/components/GuideScreenshot';

# Distribuie certificatul tău de criptare — Mac · Linie de comandă (CLI)

[Ghidurile platformei](../macos-cli.md) · [Instalare și conectarea cititorului](./setup.md)

Distribuie certificatul tău de criptare

Ilustrațiile folosesc date fictive. Urmează instrucțiunile în aplicația instalată.

## Distribuie certificatul tău de criptare

Conectează cardul și cititorul USB compatibil. Exportul certificatului public nu necesită document sau PIN. Cardul trebuie să ofere o identitate de criptare; certificatul obișnuit de semnare nu îl înlocuiește.

Exemplu ilustrativ de comandă — operațiunea nu a fost executată.

<GuideScreenshot src="/img/guide/macos-cli/ro/protect-export.svg" alt="Distribuie certificatul tău de criptare" steps={[{"x": 20, "y": 25, "text": "Rulează comanda cu propriile fișiere. Folosește o cale nouă pentru rezultat. Introdu secretele numai în solicitarea ascunsă; înlocuiește SHA256 cu amprenta completă a certificatului de criptare."}]} />

```sh
esemnbun encryption-certs
esemnbun encryption-certs --card SHA256 --out recipient.cer
```

Distribuie numai recipient.cer; exportul nu cere PIN și nu exportă cheia privată.
