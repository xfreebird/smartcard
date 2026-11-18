---
title: "Alternativă MoldSign pentru Linux — semnătură electronică"
description: "Semnătură electronică pe Linux cu eSemnBun și cartea de identitate din Moldova. Aplicație GNOME, cititor PC/SC, verificare PDF, browser și CLI/MCP."
sidebar_label: "Linux"
hide_table_of_contents: true
pagination_prev: null
pagination_next: "platforms/linux/setup"
---

import GuideDirectory from '@site/src/components/GuideDirectory';
import GuideAnchorRedirect from '@site/src/components/GuideAnchorRedirect';

# Alternativă MoldSign pentru Linux — semnătură electronică

**eSemnBun este o alternativă independentă la MoldSign pentru Linux.** Aplicația nativă GNOME semnează PDF și XAdES cu o carte de identitate electronică acceptată și un cititor USB, verifică fișiere și procesează cereri web compatibile. Pachetele desktop DEB, RPM și Flatpak diferă de [instrumentele Linux CLI și MCP](./linux-cli.md). Accesul la cititor necesită serviciul PC/SC și driverul CCID. eSemnBun nu este afiliat cu STISC.

Alege ce vrei să faci. Fiecare activitate are un ghid ilustrat separat.

<GuideDirectory platform="linux" />
<GuideAnchorRedirect platform="linux" />

## Înainte de a începe

Urmează capturile numerotate pentru eSemnBun 0.2.13 pe Linux. Atinge imaginea pentru mărire și alege Mărime originală pentru detalii.

Instalează pachetul desktop pentru distribuția și arhitectura ta din [Descărcări](/downloads/), apoi deschide eSemnBun din meniul de aplicații. Pachetele desktop DEB/RPM/Flatpak deschid aplicația grafică; depozitele și arhivele CLI instalează instrumentele de terminal. Consultă [ghidul CLI Linux](./linux-cli.md) pentru terminal și MCP. Ubuntu 24.04/Fedora sunt platforme desktop acceptate; verifică cerințele pachetului. Ai nevoie de un act electronic acceptat și activ, PIN-ul corect pentru semnare, un cititor USB compatibil și adaptorul necesar. NFC nu este disponibil. Cheia privată rămâne pe card.

Sistemul necesită PC/SC și un driver CCID. Ubuntu: `sudo apt install pcscd libccid`. Fedora: `sudo dnf install pcsc-lite pcsc-lite-ccid`. Activează socketul cu `sudo systemctl enable --now pcscd.socket`. Rulează aplicația în sesiunea grafică; politica de acces prin SSH poate fi diferită.
