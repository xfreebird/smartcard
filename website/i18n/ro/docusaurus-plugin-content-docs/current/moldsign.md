---
title: Semnătură electronică în Moldova — alternativă la MoldSign
description: Semnătură electronică cu cartea de identitate din Moldova. Instalează eSemnBun, alternativa gratuită la MoldSign, și semnează PDF-uri pe calculator sau telefon.
sidebar_label: Alternativă la MoldSign
---

# Semnătură electronică cu cartea de identitate: alternativă la MoldSign

**eSemnBun** este o aplicație gratuită, cu codul sursă deschis, pentru semnarea documentelor cu o carte de identitate electronică acceptată din Republica Moldova. O poți folosi pe calculator sau de pe telefon, cu un cititor USB compatibil și adaptorul potrivit.

Semnătura este creată cu cheia de pe card după autorizarea cu PIN-ul. Cheia privată rămâne pe cartea de identitate.

Semnătura leagă documentul de certificatul de semnare și permite detectarea modificărilor conținutului semnat. O imagine a semnăturii de mână sau o ștampilă vizibilă în PDF nu oferă singură această verificare criptografică. Consultă [semnarea și verificarea](./signing.md) pentru interpretarea rezultatului.

## Alege alternativa la MoldSign pentru dispozitivul tău

- [Alternativă MoldSign pentru Windows](./platforms/windows.md): instalare desktop, cititor USB și integrare cu browserul.
- [Alternativă MoldSign pentru Mac](./platforms/macos.md): ediții DMG și Mac App Store, cu instrumente CLI separate.
- [Alternativă MoldSign pentru Linux](./platforms/linux.md): aplicație GNOME, configurare PC/SC și linie de comandă.
- [MoldSign MCP pentru agenți AI](./mcp-moldsign.md): verificare locală și semnare PDF configurată explicit pe Windows, Mac și Linux.

Alege ediția din [Descărcări](/downloads/). Ghidul platformei precizează cerințele și funcțiile disponibile.

## Care este diferența dintre MoldSign, MSign și eSemnBun?

| Denumire | Ce reprezintă |
| --- | --- |
| MoldSign | Suita furnizorului: aplicația pentru calculator și serverul local de semnare |
| MSign | Serviciul de semnare de la [msign.gov.md](https://msign.gov.md/#/) |
| eSemnBun | Aplicație independentă pentru semnarea fișierelor și cereri locale compatibile |

eSemnBun este creat de Nicolae Ghimbovschi și nu este afiliat cu STISC. Nu emite certificate, nu activează cărți de identitate și nu înlocuiește furnizorul cardului. Acceptarea documentelor depinde de cerințele serviciului destinatar.

## De ce ai nevoie pentru semnare?

- Carte de identitate electronică acceptată, cu certificat de semnare activ.
- PIN-ul corect de semnare al cardului.
- Cititor USB compatibil, de exemplu bit4id miniLector POCKET EVO.
- Adaptor potrivit pentru calculator, iPhone, iPad sau Android.
- Conexiune la internet pentru marcarea temporală și serviciile de încredere online.

Începând cu eSemnBun 0.2.12, poți semna prin NFC pe iPhone și Android compatibile, cu un act electronic fără contact compatibil. Poți folosi și un cititor USB compatibil. Pentru NFC și USB ai nevoie de un certificat de semnare activ și de PIN-ul cardului.

## Cum semnezi un PDF cu cartea de identitate

1. Instalează eSemnBun pentru dispozitivul tău și deschide aplicația.
2. Alege NFC sau un cititor USB în **Semnează**. Pentru NFC, urmează instrucțiunile de scanare după confirmarea PIN-ului. Pentru USB, conectează cititorul, introdu cardul și verifică titularul selectat.
3. Verifică titularul, valabilitatea și cardul selectat.
4. Adaugă documentul PDF și alege **PAdES-T** pentru semnătură în interiorul PDF-ului.
5. Verifică cererea și autorizează semnarea cu PIN-ul.
6. Salvează sau distribuie fișierul rezultat. În **Verifică**, poți inspecta semnătura documentului.

Poți aproba o listă de documente într-un singur lot. Pentru XAdES detașat, păstrează documentul original împreună cu semnătura XML. Consultă [ghidul de semnare și verificare](./signing.md) pentru alegerea formatului.

## Semnătură electronică pe macOS, Windows și Linux

Ediția macOS de pe GitHub este semnată și notarizată și se instalează prin DMG. Ediția Mac App Store folosește un flux adaptat restricțiilor sistemului. Pentru Windows este disponibil instalatorul MSI; pentru Linux există aplicația nativă și utilitarul CLI.

[Ghidurile pe platforme](/docs/platforms) explică instalarea, salvarea rezultatelor, gestionarea PIN-urilor și configurarea cititorului.

## Pot semna de pe iPhone sau Android?

Da, cu o carte electronică acceptată, un cititor USB și adaptorul potrivit. Aplicațiile pentru iPhone, iPad și Android permit selectarea documentelor și distribuirea fișierelor semnate. Browserul din aplicație ajută la accesarea serviciilor care ascund autentificarea cu cartea de identitate în versiunea mobilă.

Acesta este un flux de semnare cu **cartea de identitate pe telefon**. Nu este serviciul de semnătură mobilă prin SIM al unui operator și nu îl activează.

## Cum folosești MSign și serviciile compatibile?

Pe calculator, activează conexiunea browser și păstrează aplicația pornită pe același dispozitiv ca browserul. Pe telefon sau în ediția Mac cu restricții de acces, folosește browserul din aplicație conform opțiunilor oferite. Verifică adresa serviciului și cererea înainte de autorizare.

Dacă MoldSign Server folosește deja porturile locale, rezolvă conflictul înainte de pornirea conexiunii eSemnBun. Vezi [ghidul pentru servicii web](./browser.md).

## Întrebări frecvente

### Pot semna cu orice carte de identitate?

Nu. Cardul trebuie să fie acceptat, să aibă un certificat de semnare activ și să fie folosit cu PIN-ul și cititorul potrivite. Aplicația nu emite și nu activează carduri.

### Pot semna fără cititor?

Începând cu eSemnBun 0.2.12, poți semna prin NFC pe iPhone și Android compatibile, cu un act electronic fără contact compatibil. Poți folosi și un cititor USB compatibil. Pentru NFC și USB ai nevoie de un certificat de semnare activ și de PIN-ul cardului.

### Cum verific o semnătură electronică?

Alege fișierul PDF sau XML în **Verifică**. Pentru XAdES detașat, furnizează și originalul. Examinează integritatea documentului, semnătura și informațiile certificatului. Verificarea offline nu stabilește singură starea curentă de revocare.

### Ce fac dacă PIN-ul este greșit?

Oprește încercările și verifică PIN-ul și cardul selectat. Încercările greșite repetate pot bloca cardul. Vezi [soluțiile pentru probleme frecvente](./troubleshooting.md).
