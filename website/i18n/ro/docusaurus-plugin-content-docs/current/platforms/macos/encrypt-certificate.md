---
title: "Criptează pentru titularul unui certificat — Mac"
sidebar_label: "Criptează pentru titularul unui certificat"
description: "Criptează pentru titularul unui certificat"
pagination_prev: "platforms/macos/encrypt-password"
pagination_next: "platforms/macos/decrypt-file"
---

import GuideScreenshot from '@site/src/components/GuideScreenshot';

# Criptează pentru titularul unui certificat — Mac

[Ghidurile platformei](../macos.md) · [Instalare și conectarea cititorului](./setup.md)

Criptează pentru titularul unui certificat

Ilustrațiile folosesc date fictive. Urmează instrucțiunile în aplicația instalată.

## Criptează pentru titularul unui certificat

Deschide Documente → Protejează fișiere. Alege un fișier accesibil; derulează formularul la nevoie. Ghidurile descriu noua funcție de protecție, care poate lipsi încă din versiunea instalată din magazin.

Cere destinatarului certificatul public de criptare (.cer/.der), exportat conform ghidului următor. Confirmă amprenta cu titularul printr-un canal de încredere. Un certificat doar pentru semnare nu este suficient. Pentru criptare ai nevoie de certificatul public, nu de cardul, cheia privată sau PIN-ul destinatarului.

<GuideScreenshot src="/img/guide/macos/ro/protect-certificate-light.png" alt="Criptează pentru titularul unui certificat" caption="Date fictive. Înainte de finalizare." steps={[{"x": 44, "y": 17, "text": "Alege Criptează."}, {"x": 35, "y": 33, "text": "Alege fișierul sursă."}, {"x": 67, "y": 48, "text": "Alege Certificat/card."}, {"x": 38, "y": 59, "text": "Alege fișierul certificatului destinatarului."}, {"x": 50, "y": 81, "text": "Alege Criptează, apoi salvează fișierul criptat nou."}]} />
