---
title: "Modifică setările — Mac"
sidebar_label: "Modifică setările"
description: "Gestionează limba, aspectul, PIN-urile salvate, pornirea și actualizările."
pagination_prev: "platforms/macos/browser"
pagination_next: "platforms/macos/automation"
---

import GuideScreenshot from '@site/src/components/GuideScreenshot';

# Modifică setările — Mac

[Ghidurile platformei](../macos.md) · [Instalare și conectarea cititorului](./setup.md)

Gestionează limba, aspectul, PIN-urile salvate, pornirea și actualizările.

## Configurează limba, aspectul și descoperirea în sistem

Deschide Setări. Modul demonstrativ este sus. Alege categoria pentru carduri, PIN-uri salvate, limbă sau aspect.

Pentru descoperirea Spotlight/Siri activează Găsește documentele semnate în Siri și Spotlight. Sunt expuse numai numele și datele PDF/XML-urilor semnate, lizibile și deținute de aplicație. Conținutul, identitatea din certificat și PIN-ul nu sunt indexate. În ediția independentă, fișierele arbitrare de lângă originale nu sunt eligibile; sunt eligibile numai importurile deținute de aplicație. Dezactivează opțiunea pentru eliminarea indexului.

<GuideScreenshot src="/img/guide/macos/ro/settings.png" alt="Alege limba interfeței." steps={[{"text": "Alege limba interfeței.", "x": 87, "y": 61}, {"text": "Alege aspectul aplicației.", "x": 88, "y": 69}, {"text": "Poți activa descoperirea documentelor semnate în Siri și Spotlight.", "x": 86, "y": 85}]} />

<GuideScreenshot src="/img/guide/macos/ro/saved-cards.png" alt="În Setări vezi cardurile salvate chiar și după deconectarea cititorului. Uită cardul elimină identitatea și PIN-ul ei salvat de pe acest dispozitiv." steps={[{"text": "În Setări vezi cardurile salvate chiar și după deconectarea cititorului. Uită cardul elimină identitatea și PIN-ul ei salvat de pe acest dispozitiv.", "x": 87, "y": 37}]} />

## Bara de meniu, pornirea, actualizările și ajutorul

1. Apasă pictograma eSemnBun din bara de meniu pentru fereastra principală, Configurări sau Despre. Închiderea ferestrei poate lăsa aplicația activă; alege **Ieșire** pentru oprire.
2. În **Configurări → General**, derulează la opțiunile de pornire. Activează **Pornește la autentificare** dacă dorești. Aprobările macOS sunt în **Configurări sistem → General → Elemente de autentificare**.
3. În versiunea 0.2.13, ambele ediții oferă un utilitar de fundal opțional la prima lansare și în **Configurări → General**. Activează **Deschide aplicația la conectarea cititorului sau introducerea cardului** și aprobă elementul de fundal în configurările sistemului dacă macOS o cere. Cu utilitarul activ, introducerea cardului poate redeschide aplicația după ieșire. În versiunea 0.2.12 din Mac App Store, eSemnBun trebuie să ruleze în bara de meniu pentru a deschide fereastra la introducerea cardului.
4. Pentru ediția independentă, folosește **Caută actualizări** și instalează DMG-ul nou. Copiile App Store se actualizează prin magazin. Păstrează același canal de distribuție.
5. În **Despre eSemnBun** găsești versiunea instalată; folosește Ajutor sau [Suport](/support), indicând versiunile aplicației/macOS, cititorul/adaptorul și pașii de reproducere. Nu trimite PIN-ul.

<GuideScreenshot src="/img/guide/macos/ro/onboarding.png" alt="Alege dacă aplicația pornește la autentificare sau se deschide la conectarea cititorului ori introducerea cardului. Poți schimba opțiunile mai târziu." steps={[{"text": "Alege dacă aplicația pornește la autentificare sau se deschide la conectarea cititorului ori introducerea cardului. Poți schimba opțiunile mai târziu.", "x": 36, "y": 55}]} />

<GuideScreenshot src="/img/guide/macos/ro/menu-bar.png" alt="Deschide eSemnBun din bara de meniu pentru a verifica starea cardului și a accesa documentele recente." steps={[{"text": "Deschide eSemnBun din bara de meniu pentru a verifica starea cardului și a accesa documentele recente.", "x": 23, "y": 55}]} />

Modul demonstrativ normal este o opțiune intenționată în Configurări, cu date fictive și avertisment vizibil; nu produce semnături electronice valide.
