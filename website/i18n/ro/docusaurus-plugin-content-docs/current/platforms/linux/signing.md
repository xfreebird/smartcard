---
title: "Semnează documente — Linux"
sidebar_label: "Semnează documente"
description: "Adaugă fișiere, alege formatul și ștampila, aprobă și salvează rezultatul."
pagination_prev: "platforms/linux/setup"
pagination_next: "platforms/linux/verification"
---

import GuideScreenshot from '@site/src/components/GuideScreenshot';

# Semnează documente — Linux

[Ghidurile platformei](../linux.md) · [Instalare și conectarea cititorului](./setup.md)

Adaugă fișiere, alege formatul și ștampila, aprobă și salvează rezultatul.

Ilustrațiile folosesc date fictive. Urmează instrucțiunile în aplicația instalată.

## Adaugă documentele lotului

Alege sau trage toate documentele în Semnează. Poți selecta mai multe fișiere. Verifică numele și elimină intrările nedorite înainte de autorizare. Tragerea depinde de managerul de fișiere; selectorul rămâne disponibil.

<GuideScreenshot src="/img/guide/linux/ro/sign.png" alt="Adaugă documentele lotului" steps={[{"text": "Deschide Semnează.", "x": 32, "y": 3}, {"text": "Alege fișierele sau trage-le în zona punctată.", "x": 48, "y": 77}, {"text": "Elimină un fișier nedorit din meniul rândului.", "x": 73, "y": 49}, {"text": "Alege Semnează după verificarea întregului lot.", "x": 91, "y": 95}]} />

## Alege formatul semnăturii

Semnătura PDF este PAdES-T și rămâne în PDF. Semnătura XML este XAdES-BES; XML cu marcă temporală este XAdES-T; XML cu date de validare este XAdES-C. Formatele cu marcă temporală/date de stare necesită serviciile de rețea corespunzătoare. Păstrează XML-ul detașat cu originalul nemodificat.

<GuideScreenshot src="/img/guide/linux/ro/format.png" alt="Alege formatul semnăturii" steps={[{"text": "Deschide meniul cu trei puncte.", "x": 74, "y": 49}, {"text": "Alege formatul cerut de destinatar.", "x": 72, "y": 67}, {"text": "Elimină un fișier nedorit din același meniu.", "x": 73, "y": 87}]} />

## Plasează o ștampilă PDF opțională

Deschide meniul fișierului și alege Adaugă ștampilă. Ștampila vizibilă este opțională și nu înlocuiește semnătura criptografică. Nu acoperi conținutul important. PDF-ul exemplu este marcat explicit ca nesemnat.

<GuideScreenshot src="/img/guide/linux/ro/stamp.png" alt="Plasează o ștampilă PDF opțională" steps={[{"text": "Activează ștampila și alege paginile.", "x": 79, "y": 23}, {"text": "Trage/redimensionează ștampila în previzualizare.", "x": 22, "y": 53}, {"text": "Aplică plasarea sau anulează modificarea.", "x": 80, "y": 83}]} />

## Verifică și autorizează lotul

Folosește PIN-ul de semnare al cardului selectat, nu parola Linux. Verifică titularul și întregul lot. Un lot nou cere altă aprobare. Oprește-te după un PIN incorect și confirmă-l; încercările repetate pot bloca cardul. Dialogul de exemplu nu accesează seiful real și dezactivează memorarea.

<GuideScreenshot src="/img/guide/linux/ro/pin.png" alt="Verifică și autorizează lotul" steps={[{"text": "Verifică titularul și numele documentelor.", "x": 50, "y": 40}, {"text": "Introdu PIN-ul în câmpul protejat.", "x": 50, "y": 54}, {"text": "Alege Semnează; anulează o cerere neașteptată.", "x": 61, "y": 66}]} />

## Așteaptă semnarea și marca temporală

Lasă cititorul conectat până la rezultat. Marca temporală necesită rețea. Eroarea de rețea diferă de PIN incorect; citește mesajul înaintea altei cereri deliberate.

<GuideScreenshot src="/img/guide/linux/ro/progress.png" alt="Așteaptă semnarea și marca temporală" steps={[{"text": "Așteaptă etapele curente și rezultatul final.", "x": 57, "y": 86}]} />

## Găsește fișierul rezultat

Aplicația creează un rezultat separat, păstrând intrarea. Folosește rândul finalizat pentru deschidere/localizare. Păstrează originalul cu XML-ul detașat. Finalizarea ilustrată folosește un exemplu fictiv nesemnat.

<GuideScreenshot src="/img/guide/linux/ro/success.png" alt="Găsește fișierul rezultat" steps={[{"text": "Activează rezultatul finalizat pentru localizare/deschidere.", "x": 70, "y": 48}]} />

## Rezolvă eroarea unui document

Un lot poate conține rezultate și erori. Păstrează rezultatele finalizate, citește eroarea și corectează cauza înaintea unei noi cereri. PIN-ul nu este reîncercat automat, iar un fișier defect nu este reparat automat.

<GuideScreenshot src="/img/guide/linux/ro/failure.png" alt="Rezolvă eroarea unui document" steps={[{"text": "Citește eroarea fișierului înaintea altei cereri.", "x": 45, "y": 55}]} />
