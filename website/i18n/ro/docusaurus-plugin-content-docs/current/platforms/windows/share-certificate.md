---
title: "Distribuie certificatul tău de criptare — Windows"
sidebar_label: "Distribuie certificatul tău de criptare"
description: "Distribuie certificatul tău de criptare"
pagination_prev: "platforms/windows/decrypt-file"
pagination_next: "platforms/windows/remove-file"
---

import GuideScreenshot from '@site/src/components/GuideScreenshot';

# Distribuie certificatul tău de criptare — Windows

[Ghidurile platformei](../windows.md) · [Instalare și conectarea cititorului](./setup.md)

Distribuie certificatul tău de criptare

Ilustrațiile folosesc date fictive. Urmează instrucțiunile în aplicația instalată.

## Distribuie certificatul tău de criptare

Deschide Documente → Protejează fișiere. Alege un fișier accesibil; derulează formularul la nevoie. Ghidurile descriu noua funcție de protecție, care poate lipsi încă din versiunea instalată din magazin.

Conectează cardul și cititorul USB compatibil. Exportul certificatului public nu necesită document sau PIN. Cardul trebuie să ofere o identitate de criptare; certificatul obișnuit de semnare nu îl înlocuiește.

<GuideScreenshot src="/img/guide/windows/ro/protect-certificate-light.png" alt="Criptează pentru titularul unui certificat" caption="Interfață nativă în română; date fictive. Înainte de finalizare." steps={[{"x": 40, "y": 42, "text": "Alege Certificat/card."}, {"x": 37, "y": 61, "text": "Alege Citește cardul meu; derulează la nevoie."}]} />

După citire, selectează identitatea dorită și extinde Detalii certificat. Alege Exportă certificatul de criptare, salvează fișierul .cer și transmite-l expeditorului. Compară amprenta separat. Se exportă numai certificatul public; cheia privată rămâne pe card. Captura arată ecranul inițial, înainte de citire.
