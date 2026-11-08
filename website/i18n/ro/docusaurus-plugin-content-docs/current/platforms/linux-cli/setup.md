---
title: "Primii pași — Linux · Linie de comandă (CLI)"
sidebar_label: "Primii pași"
description: "Instalează, conectează cititorul și alege cardul."
pagination_prev: "platforms/linux-cli"
pagination_next: "platforms/linux-cli/signing"
---

import GuideScreenshot from '@site/src/components/GuideScreenshot';

# Primii pași — Linux · Linie de comandă (CLI)

[Ghidurile platformei](../linux-cli.md)

Instalează, conectează cititorul și alege cardul.

Ilustrațiile folosesc date fictive. Urmează instrucțiunile în aplicația instalată.

## Instalează și descoperă funcțiile disponibile

Deschide [Descărcări](/downloads/) și alege platforma. Arhivele CLI conțin instrumentele de terminal și MCP; aplicația desktop se instalează separat. Folosește instrucțiunile pentru gestionarul de pachete, versiunea curentă și amprenta cheii. Localizează comanda și verifică funcțiile înainte de automatizare.

Pe Ubuntu instalează `pcscd libccid`; pe Fedora `pcsc-lite pcsc-lite-ccid`. Activează `pcscd.socket`. Accesul PC/SC prin SSH poate diferi de sesiunea locală. Pachetul CLI nu instalează fereastra GNOME. Arhiva folosește glibc/OpenSSL/libcurl/PCSC, nu Alpine/musl.

Configurează depozitul APT semnat din Descărcări înainte de apt install. Pe Fedora folosește dnf.

<GuideScreenshot src="/img/guide/linux-cli/ro/install.svg" alt="1. Instalează și descoperă funcțiile disponibile" caption="Exemplu ilustrativ de comandă. Copiază comenzile de mai jos și înlocuiește căile și numele cititorului." steps={[{"x": 3, "y": 23.8, "text": "Instalează prin canalul platformei ales."}, {"x": 3, "y": 83.2, "text": "Verifică funcțiile înainte de operațiuni cu cardul."}]} />

```sh
sudo apt install esemnbun-cli
command -v esemnbun
esemnbun capabilities --json
```

## Găsește cititorul și verifică certificatul

Conectează cititorul USB și introdu cardul. Listează cititoarele și citește certificatul fără PIN. Cu mai multe carduri, folosește numele exact al cititorului și verifică titularul înainte de semnare. Acestea sunt exemple; ghidul nu a accesat un cititor.

<GuideScreenshot src="/img/guide/linux-cli/ro/reader.svg" alt="2. Găsește cititorul și verifică certificatul" caption="Exemplu ilustrativ de comandă. Copiază comenzile de mai jos și înlocuiește căile și numele cititorului." steps={[{"x": 3, "y": 23.8, "text": "Listează cititoarele și prezența cardului."}, {"x": 3, "y": 53.5, "text": "Citește certificatul dorit; înlocuiește numele cititorului."}, {"x": 3, "y": 83.2, "text": "Calculează SHA-256 pentru certificatul exportat. Folosește cele 64 de cifre hexazecimale pentru semnarea nesupravegheată, nu SHA-1 afișat de cert."}]} />

```sh
esemnbun readers
esemnbun cert --reader "miniLector EVO" --out leaf.der
sha256sum leaf.der
```
