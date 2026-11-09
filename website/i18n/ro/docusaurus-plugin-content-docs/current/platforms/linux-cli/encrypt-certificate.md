---
title: "Criptează pentru titularul unui certificat — Linux · Linie de comandă (CLI)"
sidebar_label: "Criptează pentru titularul unui certificat"
description: "Criptează pentru titularul unui certificat"
pagination_prev: "platforms/linux-cli/encrypt-password"
pagination_next: "platforms/linux-cli/decrypt-file"
---

import GuideScreenshot from '@site/src/components/GuideScreenshot';

# Criptează pentru titularul unui certificat — Linux · Linie de comandă (CLI)

[Ghidurile platformei](../linux-cli.md) · [Instalare și conectarea cititorului](./setup.md)

Criptează pentru titularul unui certificat

## Criptează pentru titularul unui certificat

Cere destinatarului certificatul public de criptare (.cer/.der), exportat conform ghidului următor. Confirmă amprenta cu titularul printr-un canal de încredere. Un certificat doar pentru semnare nu este suficient. Pentru criptare ai nevoie de certificatul public, nu de cardul, cheia privată sau PIN-ul destinatarului.

Exemplu ilustrativ de comandă — operațiunea nu a fost executată.

<GuideScreenshot src="/img/guide/linux-cli/ro/protect-certificate.svg" alt="Criptează pentru titularul unui certificat" steps={[{"x": 20, "y": 25, "text": "Rulează comanda cu propriile fișiere. Folosește o cale nouă pentru rezultat. Introdu secretele numai în solicitarea ascunsă; înlocuiește SHA256 cu amprenta completă a certificatului de criptare."}]} />

```sh
esemnbun encrypt Contract.pdf Contract.enc --certificate recipient.cer
```
