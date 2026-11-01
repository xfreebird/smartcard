---
title: Politica de confidențialitate
---
# Politica de confidențialitate

În vigoare: 1 noiembrie 2026. Dezvoltator: Nicolae Ghimbovschi, Republica Moldova. Contact: nicolae.ghimbovschi@gmail.com.

eSemnBun permite semnarea și verificarea documentelor cu certificatul de pe cartea de identitate electronică. Nu are conturi proprii, publicitate sau urmărire între aplicații.

## Date prelucrate pe dispozitiv

Aplicația citește certificatul (nume, număr, emitent, valabilitate) pentru afișare și semnare. Nu îl trimite dezvoltatorului. Documentele sunt prelucrate local pentru calcularea și verificarea semnăturilor. Copiile semnate sunt salvate lângă original, unde este permis, sau în spațiul aplicației; exportarea și distribuirea folosesc destinațiile alese de tine.

PIN-ul este trimis cardului prin canalul criptat pentru a autoriza cheia. Dacă alegi memorarea, este păstrat în mecanismul securizat al platformei (Keychain, Android Keystore, stocarea de acreditări Windows sau GNOME Keyring), legat de card. Protecția și confirmările diferă între platforme. Poți șterge intrările din setări. Datele biometrice sunt gestionate de sistem; aplicația nu le primește.

Lista de activitate (nume de fișiere, date, rezultate) și setările rămân local. Browserul integrat păstrează cookie-uri, cache și date de site prin WebView. Poți șterge separat datele browserului și istoricul. Ștergerea cookie-urilor poate încheia sesiunile, dar nu șterge documentele sau PIN-urile salvate.

## Conexiuni de rețea

Marcarea temporală trimite un hash criptografic al semnăturii către serviciul public de timp (tsp.pki.gov.md). Verificările OCSP/CRL folosesc identificatori de certificate și liste publice de revocare. Aceste solicitări nu trimit conținutul documentului. Operatorii de rețea pot vedea datele conexiunii, precum adresa IP.

Site-urile deschise în browser au propriile politici. Dacă încarci un document pe un site, site-ul îl primește. Semnarea din browser returnează rezultatul autorizat site-ului solicitant. Nu există garanția acceptării documentului pentru orice scop administrativ sau juridic.

Versiunea curentă nu include raportare Sentry, publicitate sau analiză de utilizare către dezvoltator. Rapoartele trimise de tine prin e-mail sau GitHub conțin datele pe care alegi să le comunici; serviciile respective au propriile politici. Rapoarte autorizate din versiuni anterioare pot rămâne la fostul furnizor de diagnosticare; contactează dezvoltatorul pentru acces sau ștergere.

## Păstrare și control

Șterge PIN-urile salvate, activitatea și datele browserului folosind controalele aplicației. Dezinstalarea și copiile de rezervă diferă între sisteme; nu presupune că dezinstalarea șterge acreditările sau documentele externe. Fișierele rămân unde le-ai salvat sau distribuit.

Aplicația se adresează adulților care dețin o carte de identitate electronică. Pentru întrebări sau solicitări privind datele, contactează dezvoltatorul; pentru serviciile publice sau site-uri, contactează operatorul lor. Drepturile aplicabile depind de locul și circumstanțele tale. Politica va fi actualizată dacă se modifică prelucrarea datelor.

## Acest site

Site-ul static este găzduit de GitHub Pages. GitHub prelucrează informații de conexiune conform propriei [politici de confidențialitate](https://docs.github.com/en/site-policy/privacy-policies/github-privacy-statement). Nu adăugăm cookie-uri de analiză sau publicitate. Magazinele și legăturile externe au propriile politici.
