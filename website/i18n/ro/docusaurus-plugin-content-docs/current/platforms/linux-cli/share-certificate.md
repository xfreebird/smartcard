---
title: "Distribuie certificatul tău de criptare — Linux · Linie de comandă (CLI)"
sidebar_label: "Distribuie certificatul tău de criptare"
description: "Distribuie certificatul tău de criptare"
pagination_prev: "platforms/linux-cli/decrypt-file"
pagination_next: "platforms/linux-cli/remove-file"
---

import GuideScreenshot from '@site/src/components/GuideScreenshot';

# Distribuie certificatul tău de criptare — Linux · Linie de comandă (CLI)

[Ghidurile platformei](../linux-cli.md) · [Instalare și conectarea cititorului](./setup.md)

Distribuie certificatul tău de criptare

## Distribuie certificatul tău de criptare

Cartea de identitate moldovenească nu oferă cheia de criptare necesară acestor comenzi pentru certificat/card. Folosește criptarea cu parolă pentru acest card. Comenzile CLI pentru certificate rămân disponibile pentru certificate și dispozitive de criptare compatibile; un certificat doar pentru semnare nu este potrivit.

Conectează cardul și cititorul USB compatibil. Exportul certificatului public nu necesită document sau PIN. Cardul trebuie să ofere o identitate de criptare; certificatul obișnuit de semnare nu îl înlocuiește.

Exemplu ilustrativ de comandă — operațiunea nu a fost executată.

<GuideScreenshot src="/img/guide/linux-cli/ro/protect-export.svg" alt="Distribuie certificatul tău de criptare" steps={[{"x": 20, "y": 25, "text": "Rulează comanda cu propriile fișiere. Folosește o cale nouă pentru rezultat. Introdu secretele numai în solicitarea ascunsă; înlocuiește SHA256 cu amprenta completă a certificatului de criptare."}]} />

```sh
esemnbun encryption-certs
esemnbun encryption-certs --card SHA256 --out recipient.cer
```

Distribuie numai recipient.cer; exportul nu cere PIN și nu exportă cheia privată.
