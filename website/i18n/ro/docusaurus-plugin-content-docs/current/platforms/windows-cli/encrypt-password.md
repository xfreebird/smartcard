---
title: "Criptează un fișier cu parolă — Windows · Linie de comandă (CLI)"
sidebar_label: "Criptează un fișier cu parolă"
description: "Criptează un fișier cu parolă"
pagination_prev: "platforms/windows-cli/unattended"
pagination_next: "platforms/windows-cli/encrypt-certificate"
---

import GuideScreenshot from '@site/src/components/GuideScreenshot';

# Criptează un fișier cu parolă — Windows · Linie de comandă (CLI)

[Ghidurile platformei](../windows-cli.md) · [Instalare și conectarea cititorului](./setup.md)

Criptează un fișier cu parolă

Ilustrațiile folosesc date fictive. Urmează instrucțiunile în aplicația instalată.

## Criptează un fișier cu parolă

Nu ai nevoie de card. Creează o parolă pentru fișier și transmite-o destinatarului printr-un canal de încredere separat. Nu este PIN-ul cardului. Criptarea creează un rezultat separat; păstrează originalul până verifici rezultatul.

Exemplu ilustrativ de comandă — operațiunea nu a fost executată.

<GuideScreenshot src="/img/guide/windows-cli/ro/protect-password.svg" alt="Criptează un fișier cu parolă" steps={[{"x": 20, "y": 25, "text": "Rulează comanda cu propriile fișiere. Folosește o cale nouă pentru rezultat. Introdu secretele numai în solicitarea ascunsă; înlocuiește SHA256 cu amprenta completă a certificatului de criptare."}]} />

```sh
esemnbun encrypt Contract.pdf Contract.enc
```
