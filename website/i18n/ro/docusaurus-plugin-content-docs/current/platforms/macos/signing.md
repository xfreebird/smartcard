---
title: "Semnează documente — Mac"
sidebar_label: "Semnează documente"
description: "Adaugă fișiere, alege formatul și ștampila, aprobă și salvează rezultatul."
pagination_prev: "platforms/macos/setup"
pagination_next: "platforms/macos/verification"
---

import GuideScreenshot from '@site/src/components/GuideScreenshot';

# Semnează documente — Mac

[Ghidurile platformei](../macos.md) · [Instalare și conectarea cititorului](./setup.md)

Adaugă fișiere, alege formatul și ștampila, aprobă și salvează rezultatul.

## Adaugă documentele și alege formatul

Un PDF folosește în mod normal PAdES-T: semnătura rămâne în PDF. Alte fișiere folosesc de obicei XAdES-T detașat: păstrează XML-ul împreună cu originalul nemodificat. Folosește controlul de format al fișierului dacă destinatarul cere un alt format acceptat. Meniul rândului permite eliminarea unui fișier adăugat din greșeală.

<GuideScreenshot src="/img/guide/macos/ro/sign.png" alt="Adaugă documentele și alege formatul" steps={[{"x": 8, "y": 9, "text": "Deschide Semnează."}, {"x": 67, "y": 73, "text": "Alege fișiere sau trage-le în zona punctată. Adaugă întregul lot înainte de semnare."}, {"x": 45, "y": 54, "text": "Verifică numele și formatul fiecărui fișier. Controlul ștampilei PDF este lângă format."}, {"x": 90, "y": 95, "text": "Verifică cardul selectat, apoi apasă butonul flotant Semnează din dreapta jos sau ⌘Return. Butonul arată numărul documentelor și rămâne vizibil în timpul derulării."}]} />

## Aplică o ștampilă vizibilă pe PDF

Deschide controlul Ștampilă oprită/Editează ștampila al unui PDF din listă. Ștampila vizibilă este opțională și nu înlocuiește semnătura criptografică. Pentru un PDF cu mai multe pagini, selectează pagina în previzualizare.

Textul ștampilei urmează limba aleasă în aplicație (română, engleză sau rusă).

<GuideScreenshot src="/img/guide/macos/ro/stamp.png" alt="Aplică o ștampilă vizibilă pe PDF" steps={[{"x": 94, "y": 6, "text": "Activează Ștampilă vizibilă."}, {"x": 11, "y": 49, "text": "Trage ștampila pentru poziționare și un colț pentru redimensionare."}, {"x": 94, "y": 28, "text": "Alege pagina selectată sau toate paginile; opțional, aplică setarea tuturor PDF-urilor din lot."}, {"x": 92, "y": 95, "text": "Alege Aplică pentru a reveni la lista de semnare."}]} />

## Autorizează lotul afișat

Folosește PIN-ul de semnare al cardului fizic selectat, nu parola de autentificare a Mac-ului. Oprește-te după un PIN incorect și verifică identitatea/PIN-ul înainte de o nouă încercare. Contorul încercărilor rămase protejează cardul. Un lot nou cere o nouă autorizare.

<GuideScreenshot src="/img/guide/macos/ro/pin.png" alt="Autorizează lotul afișat" steps={[{"x": 49, "y": 28, "text": "Verifică titularul și toate documentele afișate. Anulează dacă ceva nu corespunde."}, {"x": 49, "y": 51, "text": "Introdu PIN-ul cardului în câmpurile protejate."}, {"x": 49, "y": 62, "text": "Bifează Reține PIN-ul numai dacă dorești păstrarea lui în Portchei, cu deblocare prin autentificarea dispozitivului."}, {"x": 85, "y": 76, "text": "Alege Semnează după completarea PIN-ului; păstrează cititorul conectat până la final."}]} />

## Așteaptă semnarea și marca temporală

Lasă cititorul conectat în timpul semnării și obținerii mărcii temporale. Erorile de rețea/marcă temporală și fișierele nevalide diferă de un PIN incorect. Citește eroarea înainte de următorul pas.

<GuideScreenshot src="/img/guide/macos/ro/progress.png" alt="Așteaptă semnarea și marca temporală" steps={[{"x": 50, "y": 45, "text": "Așteaptă încheierea etapei curente."}]} />

## Găsește, previzualizează și partajează rezultatul

Ediția macOS independentă scrie de obicei un fișier nou lângă sursă, cu sufix de semnare, fără a suprascrie originalul. Ediția App Store folosește stocarea permisă și acțiunile explicite de export/partajare. Păstrează XML-ul detașat împreună cu originalul.

<GuideScreenshot src="/img/guide/macos/ro/success.png" alt="Găsește, previzualizează și partajează rezultatul" steps={[{"x": 80, "y": 53, "text": "Apasă rândul finalizat sau Arată în Finder pentru a găsi rezultatul."}, {"x": 90, "y": 53, "text": "Folosește Previzualizare pentru a inspecta rezultatul. Folosește Partajează pentru PDF-ul semnat și alege destinația."}]} />

## Rezolvă o eroare de document

Un lot poate conține elemente reușite și eșuate. Păstrează rezultatele finalizate. Corectează fișierul sau conexiunea înainte de o nouă operațiune deliberată; PIN-ul nu se reîncearcă automat. Un PDF nevalid și nemodificat va eșua din nou.

<GuideScreenshot src="/img/guide/macos/ro/file-error.png" alt="Rezolvă o eroare de document" steps={[{"x": 50, "y": 56, "text": "Citește eroarea fișierului afectat; elimină-l din meniul rândului dacă este necesar."}]} />
