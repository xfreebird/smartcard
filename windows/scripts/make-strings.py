#!/usr/bin/env python3
"""Generates src/MoldSign.App/Strings/{ro-RO,en-US}/Resources.resw from the one table below (docs/10 §5 copy).

    python3 windows/scripts/make-strings.py [output Strings directory]

ro-RO is the default language, en-US the fallback; both files always get identical keys. Plain keys are read in
code (Loc.Get / Loc.Format); "Uid.Property" keys are applied by x:Uid in XAML (attached properties use the
"[using:Namespace]Owner.Property" form).
"""
import os
import sys
from xml.sax.saxutils import escape

out = sys.argv[1] if len(sys.argv) > 1 else os.path.join(
    os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "src", "MoldSign.App", "Strings")
S = [
 # key, ro, en
 ("Status_NoReader", "Conectează cititorul", "Connect the reader"),
 ("Status_Empty", "Introdu cardul în cititor", "Insert the card"),
 ("Status_Ready", "Card pregătit", "Card ready"),
 ("Status_Reading", "Se citește cardul…", "Reading the card…"),
 ("Card_PinForgotten", "PIN-ul salvat a fost șters.", "The saved PIN was deleted."),
 ("Drop_Title", "Trage documentele aici", "Drop documents here"),
 ("Drop_Subtitle", "sau alege fișiere", "or choose files"),
 ("Action_Sign", "Semnează", "Sign"),
 ("Action_Verify", "Verifică", "Verify"),
 ("Action_Countersign", "Contrasemnează", "Counter-sign"),
 ("Action_Cancel", "Anulează", "Cancel"),
 ("Sign_ButtonCount", "Semnează {0} documente", "Sign {0} documents"),
 ("Sign_Done", "Documente semnate: {0}", "Documents signed: {0}"),
 ("Pin_Title", "PIN QSCD", "QSCD PIN"),
 ("Pin_For", "pentru {0}", "for {0}"),
 ("Pin_Remember", "Ține minte PIN-ul (Windows Hello)", "Remember PIN (Windows Hello)"),
 ("Pin_Attempts", "Încercări rămase: {0}", "Attempts left: {0}"),
 ("Consent_Title", "{0} solicită o semnătură", "{0} requests a signature"),
 ("Consent_Trust", "Ai încredere în site 10 minute", "Trust this site for 10 minutes"),
 ("Consent_HelloReason", "Semnează cu PIN-ul salvat pentru {0}", "Sign with the saved PIN for {0}"),
 ("Consent_HelloBrowser", "{0} solicită semnarea cu {1}: {2} · {3}", "{0} requests signing as {1}: {2} · {3}"),
 ("Verdict_Valid", "Semnătură validă", "Valid signature"),
 ("Verdict_Invalid", "Semnătură invalidă", "Invalid signature"),
 ("Verdict_Unknown", "Nu poate fi confirmată", "Cannot be confirmed"),
 ("Verdict_Unsigned", "Nu s-au găsit semnături", "No signatures found"),
 ("Verify_SignatureCount", "Semnături: {0}", "Signatures: {0}"),
 ("Verify_Signature", "Semnătura {0}", "Signature {0}"),
 ("Verify_Signer", "Semnatar", "Signer"),
 ("Verify_SigningTime", "Semnat la", "Signed at"),
 ("Verify_Timestamp", "Marcă temporală", "Timestamp"),
 ("Verify_NoTimestamp", "Fără marcă temporală", "No timestamp"),
 ("Verify_Level", "Nivel", "Level"),
 ("Verify_Integrity", "Integritatea documentului", "Document integrity"),
 ("Verify_IntegrityGood", "Conținutul verificat corespunde celui semnat.", "The verified content matches the signed content."),
 ("Verify_IntegrityBad", "Conținutul diferă sau lipsesc documentele originale ale semnăturii detașate.", "The content differs or the original detached documents are missing."),
 ("Verify_Crypto", "Semnătura criptografică", "Cryptographic signature"),
 ("Verify_CryptoGood", "Semnătura RSA corespunde certificatului.", "The RSA signature matches the certificate."),
 ("Verify_CryptoBad", "Semnătura criptografică nu a putut fi confirmată.", "The cryptographic signature could not be confirmed."),
 ("Verify_Chain", "Lanț de încredere", "Trust chain"),
 ("Verify_ChainGood", "Lanțul certificatului este valid până la mdtrustca.", "The certificate chain is valid up to mdtrustca."),
 ("Verify_ChainBad", "Lanț necunoscut, incomplet sau certificat expirat.", "Unknown or incomplete chain, or an expired certificate."),
 ("Verify_Imprint", "Amprenta mărcii temporale", "Timestamp imprint"),
 ("Verify_ImprintGood", "Marca temporală acoperă această semnătură.", "The timestamp covers this signature."),
 ("Verify_ImprintBad", "Amprenta mărcii temporale nu corespunde semnăturii.", "The timestamp imprint does not match the signature."),
 ("Verify_Limits", "Limitele verificării offline", "Offline verification limits"),
 ("Verify_TsaNotChecked", "Semnătura TSA și lanțul său de încredere nu au fost verificate.", "The TSA signature and its trust chain have not been verified."),
 ("Verify_RevocationNotChecked", "Starea de revocare nu a fost verificată.", "Revocation status has not been checked."),
 ("Verify_Details", "Detalii tehnice", "Technical details"),
 ("Verify_Format", "Format", "Format"),
 ("Verify_Identifier", "Identificator", "Identifier"),
 ("Verify_TsaSignature", "Semnătura și lanțul TSA", "TSA signature and chain"),
 ("Verify_Revocation", "Revocare (CRL / OCSP)", "Revocation (CRL / OCSP)"),
 ("Verify_Notes", "Observații", "Notes"),
 ("Verify_Checked", "Verificat", "Checked"),
 ("Verify_NotChecked", "Nu a fost verificat", "Not checked"),
 ("Verify_Unavailable", "Nedisponibil", "Unavailable"),
 ("Verify_Failed", "Documentul nu a putut fi verificat.", "The document could not be verified."),
 ("VerifyReveal.Content", "Arată în Explorer", "Show in Explorer"),
 ("VerifyChecking.Text", "Se verifică…", "Verifying…"),
 ("VerifyDetachedHint.Text", "Pentru o semnătură detașată, adaugă documentele originale pentru verificarea integrității.", "For a detached signature, add the original documents to verify content integrity."),
 ("VerifyAddDocuments.Content", "Alege documentele semnate…", "Choose the signed documents…"),
 ("Bridge_On", "Conexiune browser activă", "Browser connection on"),
 ("Bridge_Off", "Conexiune browser oprită", "Browser connection off"),
 ("Bridge_IdentityMissing", "Lipsește localhost.p12. Importă identitatea HTTPS din MoldSign Desktop în Setări.", "localhost.p12 is missing. Import the MoldSign Desktop HTTPS identity in Settings."),
 ("Bridge_IdentityInvalid", "Identitatea HTTPS nu poate fi citită sau a expirat. Importă localhost.p12 din MoldSign Desktop.", "The HTTPS identity cannot be read or has expired. Import localhost.p12 from MoldSign Desktop."),
 ("Bridge_IdentityImported", "Identitate HTTPS importată", "HTTPS identity imported"),
 ("Bridge_Error", "Conexiunea browser nu a pornit: {0}", "Browser connection could not start: {0}"),
 ("SettingsImportIdentity.Content", "Importă identitatea HTTPS (localhost.p12)…", "Import HTTPS identity (localhost.p12)…"),
 ("Error_FileSelection", "Fișierele nu au putut fi deschise: {0}", "Could not open files: {0}"),
 ("Error_PickerWindow", "Deschide fereastra aplicației și încearcă din nou.", "Open the app window and try again."),
 ("Bridge_PortBusy", "Portul {0} este ocupat (probabil de MoldSign (Java)). Închide-l și repornește conexiunea.", "Port {0} is in use (probably by MoldSign (Java)). Close it and restart the connection."),
 ("Activity_Signed", "Semnat", "Signed"),
 ("Activity_Verified", "Verificat", "Verified"),
 ("Activity_BridgeRequest", "Cerere {0}", "Request from {0}"),
 ("Error_NoCard", "Introdu cardul", "Insert the card"),
 ("Error_WrongPin", "PIN greșit. Nu se reîncearcă automat.", "Wrong PIN. Not retried automatically."),
 ("Error_PinBlocked", "PIN blocat. Deblochează-l la CEV", "PIN blocked. Unblock it at CEV"),
 ("Error_CardStuck", "Scoate și reintrodu cardul", "Remove and re-insert the card"),
 ("Error_SmOutOfSync", "Legătura cu cardul s-a pierdut. Încearcă din nou.", "Lost the connection to the card. Try again."),
 ("Error_Network", "Serviciul de marcă temporală nu răspunde. Încearcă din nou.", "The timestamp service is not responding. Try again."),
 ("Error_Generic", "Cardul nu a răspuns cum trebuie. Încearcă din nou.", "The card did not answer as expected. Try again."),
 ("Error_NotImplemented", "Funcția nu este încă disponibilă pe Windows (WIN-01).", "Not available on Windows yet (WIN-01)."),
 ("Tray_OpenWindow", "Deschide fereastra", "Open window"),
 ("Tray_Quit", "Ieșire", "Quit"),
 ("Settings_AllowedSites", "{0} site-uri permise (lista furnizorului)", "{0} allowed sites (vendor list)"),
 ("Settings_StartupManaged", "Setat de administrator pentru toți utilizatorii (instalarea MSI)", "Set by your administrator for all users (MSI install)"),
 ("Settings_StartupDisabledByUser", "Oprit din Setări › Aplicații › Pornire; activează-l de acolo", "Turned off in Settings › Apps › Startup; turn it on there"),
 # Status light (docs/10 §0.1): tooltip, tray tooltip and Narrator text
 ("Light_Idle", "Conectează cititorul", "Connect the reader"),
 ("Light_Reader", "Cititor conectat · introdu cardul", "Reader connected · insert the card"),
 ("Light_Reading", "Se citește cardul…", "Reading the card…"),
 ("Light_Ready", "Card pregătit · {0}", "Card ready · {0}"),
 ("Light_ReadyMany", "Card pregătit · {0} · {1} carduri", "Card ready · {0} · {1} cards"),
 ("Light_Busy", "Se semnează…", "Signing…"),
 ("Info_NoReaderTitle", "Niciun cititor conectat", "No reader connected"),
 ("Info_CardErrorTitle", "Cardul nu poate semna acum", "The card cannot sign right now"),
 # Card wallet (docs/10 §0.2)
 ("Wallet_InsertTitle", "Introdu cardul", "Insert the card"),
 ("Wallet_ConnectTitle", "Conectează cititorul", "Connect the reader"),
 ("Wallet_ConnectMessage", "Conectează cititorul de carduri la un port USB.", "Plug the card reader into a USB port."),
 ("Wallet_MuteTitle", "Cardul nu răspunde", "The card does not respond"),
 ("Wallet_CardName", "{0}, card de identitate, valabil până la {1}, {2} din {3}", "{0}, identity card, valid until {1}, {2} of {3}"),
 ("Wallet_CardReadingName", "Card în {0}, se citește, {1} din {2}", "Card in {0}, reading, {1} of {2}"),
 ("Wallet_CardErrorName", "Card în {0}: {1}, {2} din {3}", "Card in {0}: {1}, {2} of {3}"),
 ("Error_CardChanged", "Cardul din cititor s-a schimbat. Verifică titularul și semnează din nou.", "The card in the reader changed. Check the holder and sign again."),
 ("Wallet_CardInReader", "Card în {0}", "Card in {0}"),
 ("Wallet_StatusReady", "Pregătit pentru semnare", "Ready to sign"),
 ("Wallet_Reread", "Recitește cardul", "Read the card again"),
 ("Wallet_RereadAll", "Recitește cardurile", "Read the cards again"),
 ("Wallet_DisclosureName", "Alege cardul ({0} carduri)", "Choose the card ({0} cards)"),
 ("Wallet_UsedForSigning", "Folosit pentru semnare", "Used for signing"),
 ("Wallet_SignWith", "Semnează cu {0}", "Sign with {0}"),
 ("Tray_Connected", "Card conectat · {0}", "Card connected · {0}"),
 ("Tray_ConnectedNoHolder", "Card conectat", "Card connected"),
 ("Tray_None", "Niciun card conectat", "No card connected"),
 ("Activity_ClearTitle", "Golești lista activității?", "Clear the activity list?"),
 ("Activity_ClearMessage", "Intrările dispar din listă. Documentele semnate rămân pe disc.", "The entries are removed from the list. Signed documents stay on disk."),
 ("Activity_ClearConfirm", "Golește", "Clear"),
 # StepProgress (docs/10 §3)
 ("Step_Connecting", "Conectare la card…", "Connecting to the card…"),
 ("Step_Authenticating", "Sesiune securizată cu cardul…", "Opening a secure session…"),
 ("Step_ReadingCertificate", "Se citește certificatul…", "Reading the certificate…"),
 ("Step_VerifyingPin", "Se verifică PIN-ul…", "Checking the PIN…"),
 ("Step_Signing", "Se semnează…", "Signing…"),
 ("Step_Timestamping", "Marcă temporală…", "Timestamping…"),
 ("Step_Revocation", "Se verifică revocarea…", "Checking revocation…"),
 ("Step_Writing", "Se salvează…", "Saving…"),
 ("Step_Done", "Gata", "Done"),
 # x:Uid (Key.Property)
 ("DropTitle.Text", "Trage documentele aici", "Drop documents here"),
 ("DropBrowse.Content", "Alege fișiere…", "Choose files…"),
 ("DropHint.Text", "PDF → PAdES · altele → XAdES", "PDF → PAdES · others → XAdES"),
 ("NavSign.Content", "Semnează", "Sign"),
 ("NavVerify.Content", "Verifică", "Verify"),
 ("NavActivity.Content", "Activitate", "Activity"),
 ("NavCard.Content", "Card", "Card"),
 ("FlyoutSign.Content", "Semnează…", "Sign…"),
 ("FlyoutVerify.Content", "Verifică…", "Verify…"),
 ("RecentHeader.Text", "RECENTE", "RECENT"),
 ("RecentEmpty.Text", "Nicio activitate încă", "No activity yet"),
 ("BridgeLabel.Text", "Conexiune browser", "Browser connection"),
 ("TrayOpenWindow.Content", "Deschide eSemnBun", "Open eSemnBun"),
 ("TrayQuit.Content", "Ieșire", "Quit"),
 ("SignPageTitle.Text", "Semnează", "Sign"),
 ("SignAdvanced.Header", "Opțiuni avansate", "Advanced options"),
 ("SignPdfFormat.Text", "PDF → PAdES-T (cerut de msign.gov.md); XAdES produce un fișier .xml separat", "PDF → PAdES-T (required by msign.gov.md); XAdES writes a separate .xml file"),
 ("SignPackaging.Header", "Ambalare XAdES", "XAdES packaging"),
 ("SignAlgorithm.Text", "Algoritm: SHA-256", "Algorithm: SHA-256"),
 ("VerifyPageTitle.Text", "Verifică", "Verify"),
 ("VerifyHint.Text", "PDF semnat (PAdES) sau semnătură .xml (XAdES); pentru o semnătură detașată alege și fișierele semnate.", "Signed PDF (PAdES) or .xml signature (XAdES); for a detached signature, also choose the signed files."),
 ("ActivityPageTitle.Text", "Activitate", "Activity"),
 ("CardPageTitle.Text", "Card", "Card"),
 ("CardIssuer.Text", "Emitent", "Issuer"),
 ("CardValidity.Text", "Valabil", "Valid"),
 ("CardSerial.Text", "Număr de serie", "Serial number"),
 ("CardSha1.Text", "SHA-1", "SHA-1"),
 ("CardReader.Text", "Cititor", "Reader"),
 ("CardRereadLabel.Text", "Recitește cardul", "Read the card again"),
 ("CardHolder.Text", "Titular", "Holder"),
 ("CardRememberPin.Header", "Ține minte PIN-ul (Windows Hello)", "Remember PIN (Windows Hello)"),
 ("CardForgetPin.Content", "Șterge PIN-ul salvat", "Delete the saved PIN"),
 ("CardTipsHeader.Text", "DACĂ CARDUL NU RĂSPUNDE", "IF THE CARD DOES NOT RESPOND"),
 ("CardTips.Text", "Scoate cardul și reintrodu-l. Conectează cititorul direct la computer, fără hub. PIN-ul nu se încearcă niciodată automat după o greșeală.", "Remove the card and insert it again. Plug the reader straight into the computer, without a hub. The PIN is never retried automatically after a mistake."),
 ("SettingsPageTitle.Text", "Setări", "Settings"),
 ("SettingsGeneral.Text", "GENERAL", "GENERAL"),
 ("SettingsStartAtLogin.Header", "Pornește la autentificare", "Start at sign-in"),
 ("SettingsReaderToasts.Header", "Notificări la conectarea cititorului", "Notify when the reader connects"),
 ("SettingsLanguage.Header", "Limba", "Language"),
 ("SettingsBridge.Text", "CONEXIUNE BROWSER", "BROWSER CONNECTION"),
 ("SettingsBridgeToggle.Header", "Conexiune browser (compatibilă MoldSign Server)", "Browser connection (MoldSign Server compatible)"),
 ("SettingsAdvanced.Text", "AVANSAT", "ADVANCED"),
 ("StatusInfoReread.Content", "Recitește cardul", "Read the card again"),
 ("DropTitleCompact.Text", "Trage aici alte documente", "Drop more documents here"),
 ("DropBrowseCompact.Content", "Alege fișiere…", "Choose files…"),
 ("RecentClear.Content", "Golește lista", "Clear list"),
 ("RecentDocsEmpty.Text", "Niciun document recent", "No recent documents"),
 ("ActivityClearLabel.Text", "Golește lista", "Clear list"),
 # Narrator labels of icon-only controls (attached property syntax)
 ("FlyoutSettings.[using:Microsoft.UI.Xaml.Automation]AutomationProperties.Name", "Setări", "Settings"),
 ("BridgeToggle.[using:Microsoft.UI.Xaml.Automation]AutomationProperties.Name", "Conexiune browser", "Browser connection"),
 ("FileFormat.[using:Microsoft.UI.Xaml.Automation]AutomationProperties.Name", "Format semnătură", "Signature format"),
 ("ActivityList.[using:Microsoft.UI.Xaml.Automation]AutomationProperties.Name", "Activitate", "Activity"),
 ("FileRemove.[using:Microsoft.UI.Xaml.Automation]AutomationProperties.Name", "Elimină", "Remove"),
 ("FlyoutSettings.[using:Microsoft.UI.Xaml.Controls]ToolTipService.ToolTip", "Setări", "Settings"),
 ("FlyoutReread.[using:Microsoft.UI.Xaml.Automation]AutomationProperties.Name", "Recitește cardul", "Read the card again"),
 ("FlyoutReread.[using:Microsoft.UI.Xaml.Controls]ToolTipService.ToolTip", "Recitește cardul", "Read the card again"),
 ("RecentList.[using:Microsoft.UI.Xaml.Automation]AutomationProperties.Name", "Recente", "Recent"),
 ("SignFileList.[using:Microsoft.UI.Xaml.Automation]AutomationProperties.Name", "Documente de semnat", "Documents to sign"),
]
keys = [k for k, _, _ in S]
assert len(keys) == len(set(keys)), "duplicate keys"
HEADER = """<?xml version="1.0" encoding="utf-8"?>
<!-- Generated from one table (ro-RO is the default language, en-US the fallback); keep both files' keys identical. -->
<root>
  <resheader name="resmimetype">
    <value>text/microsoft-resx</value>
  </resheader>
  <resheader name="version">
    <value>2.0</value>
  </resheader>
  <resheader name="reader">
    <value>System.Resources.ResXResourceReader, System.Windows.Forms, Version=4.0.0.0, Culture=neutral, PublicKeyToken=b77a5c561934e089</value>
  </resheader>
  <resheader name="writer">
    <value>System.Resources.ResXResourceWriter, System.Windows.Forms, Version=4.0.0.0, Culture=neutral, PublicKeyToken=b77a5c561934e089</value>
  </resheader>
"""
for lang, idx in (("ro-RO", 1), ("en-US", 2)):
    d = os.path.join(out, lang)
    os.makedirs(d, exist_ok=True)
    with open(os.path.join(d, "Resources.resw"), "w", encoding="utf-8", newline="\n") as f:
        f.write(HEADER)
        for row in S:
            f.write(f'  <data name="{escape(row[0])}" xml:space="preserve">\n    <value>{escape(row[idx])}</value>\n  </data>\n')
        f.write("</root>\n")
print(len(S), "keys")
