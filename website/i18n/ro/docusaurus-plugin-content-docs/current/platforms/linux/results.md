---
title: "Înțelege rezultatele verificării — Linux"
sidebar_label: "Înțelege rezultatele verificării"
description: "Deosebește semnăturile invalide, încrederea neconfirmată și fișierele nesemnate."
pagination_prev: "platforms/linux/verification"
pagination_next: "platforms/linux/documents"
---

import GuideScreenshot from '@site/src/components/GuideScreenshot';

# Înțelege rezultatele verificării — Linux

[Ghidurile platformei](../linux.md) · [Instalare și conectarea cititorului](./setup.md)

Deosebește semnăturile invalide, încrederea neconfirmată și fișierele nesemnate.

Ilustrațiile folosesc date fictive. Urmează instrucțiunile în aplicația instalată.

## Recunoaște un document modificat

Un rezultat invalid poate însemna că documentul nu mai corespunde conținutului semnat. Cere expeditorului copia intactă și verific-o. Redenumirea sau o ștampilă nouă nu repară semnătura.

<GuideScreenshot src="/img/guide/linux/ro/invalid.png" alt="Recunoaște un document modificat" steps={[{"text": "Citește verdictul invalid.", "x": 49, "y": 25}, {"text": "Inspectează verificarea nereușită.", "x": 47, "y": 70}]} />

## Deosebește încrederea neconfirmată

Un lanț necunoscut/neconfirmat diferă de modificarea dovedită. Verifică separat integritatea și semnătura și aplică politica destinatarului pentru certificate.

<GuideScreenshot src="/img/guide/linux/ro/untrusted.png" alt="Deosebește încrederea neconfirmată" steps={[{"text": "Citește verdictul neconfirmat.", "x": 48, "y": 25}, {"text": "Inspectează separat lanțul de încredere.", "x": 70, "y": 86}]} />

## Recunoaște un fișier nesemnat

Lipsa unei semnături recunoscute înseamnă că acest fișier nu are o semnătură verificabilă de aplicație. O imagine scanată sau o ștampilă nu o înlocuiește. Cere rezultatul electronic semnat.

<GuideScreenshot src="/img/guide/linux/ro/unsigned.png" alt="Recunoaște un fișier nesemnat" steps={[{"text": "Citește lipsa semnăturii înainte de a trimite fișierul ca semnat.", "x": 50, "y": 26}]} />
