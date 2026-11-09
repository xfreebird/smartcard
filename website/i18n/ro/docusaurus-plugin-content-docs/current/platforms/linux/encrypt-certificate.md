---
title: "Criptează pentru titularul unui certificat — Linux"
sidebar_label: "Criptează pentru titularul unui certificat"
description: "Criptează pentru titularul unui certificat"
pagination_prev: "platforms/linux/encrypt-password"
pagination_next: "platforms/linux/decrypt-file"
---

import GuideScreenshot from '@site/src/components/GuideScreenshot';

# Criptează pentru titularul unui certificat — Linux

[Ghidurile platformei](../linux.md) · [Instalare și conectarea cititorului](./setup.md)

Criptează pentru titularul unui certificat

Ilustrațiile folosesc date fictive. Urmează instrucțiunile în aplicația instalată.

## Criptează pentru titularul unui certificat

Deschide Documente → Protejează fișiere. Alege un fișier accesibil; derulează formularul la nevoie. Ghidurile descriu noua funcție de protecție, care poate lipsi încă din versiunea instalată din magazin.

Cere destinatarului certificatul public de criptare (.cer/.der), exportat conform ghidului următor. Confirmă amprenta cu titularul printr-un canal de încredere. Un certificat doar pentru semnare nu este suficient. Pentru criptare ai nevoie de certificatul public, nu de cardul, cheia privată sau PIN-ul destinatarului.

<GuideScreenshot src="/img/guide/linux/ro/protect-certificate-light.png" alt="Criptează pentru titularul unui certificat" caption="Date fictive. Înainte de finalizare." steps={[{"x": 26.9, "y": 16.3, "text": "Alege Criptează."}, {"x": 32.2, "y": 33.3, "text": "Alege fișierul sursă."}, {"x": 28.7, "y": 47.3, "text": "Alege Certificat/card."}, {"x": 41.1, "y": 61.2, "text": "Alege fișierul certificatului destinatarului."}, {"x": 50.0, "y": 89.1, "text": "Alege Criptează, apoi salvează fișierul criptat nou."}]} />
