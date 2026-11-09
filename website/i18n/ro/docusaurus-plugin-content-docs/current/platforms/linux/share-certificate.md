---
title: "Distribuie certificatul tău de criptare — Linux"
sidebar_label: "Distribuie certificatul tău de criptare"
description: "Distribuie certificatul tău de criptare"
pagination_prev: "platforms/linux/decrypt-file"
pagination_next: "platforms/linux/remove-file"
---

import GuideScreenshot from '@site/src/components/GuideScreenshot';

# Distribuie certificatul tău de criptare — Linux

[Ghidurile platformei](../linux.md) · [Instalare și conectarea cititorului](./setup.md)

Distribuie certificatul tău de criptare

## Distribuie certificatul tău de criptare

Deschide Documente → Protejează fișiere. Alege un fișier accesibil; derulează formularul la nevoie. Ghidurile descriu noua funcție de protecție, care poate lipsi încă din versiunea instalată din magazin.

Conectează cardul și cititorul USB compatibil. Exportul certificatului public nu necesită document sau PIN. Cardul trebuie să ofere o identitate de criptare; certificatul obișnuit de semnare nu îl înlocuiește.

<GuideScreenshot src="/img/guide/linux/ro/protect-certificate-light.png" alt="Criptează pentru titularul unui certificat" steps={[{"x": 28.7, "y": 47.3, "text": "Alege Certificat/card."}, {"x": 41.1, "y": 69.0, "text": "Alege Citește cardul meu; derulează la nevoie."}]} />

După citire, selectează identitatea dorită și extinde Detalii certificat. Alege Exportă certificatul de criptare, salvează fișierul .cer și transmite-l expeditorului. Compară amprenta separat. Se exportă numai certificatul public; cheia privată rămâne pe card. Captura arată ecranul inițial, înainte de citire.
