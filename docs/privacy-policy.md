# eSemnBun Privacy Policy

**Effective date:** 25 October 2026
**Developer:** Nicolae Ghimbovschi, Republic of Moldova
**Contact:** [your contact email]

eSemnBun lets you sign and verify documents with the qualified certificate on your Moldovan electronic identity card,
on macOS, Windows, Linux, iOS and Android. This policy explains what information the app handles and where it goes.

## Summary

- eSemnBun has **no user accounts, no analytics, no advertising and no tracking**, and contains no third-party SDKs.
- **Your documents never leave your device.** Signing happens on your device and on your ID card.
- The developer **does not receive or store any of your data**.
- To make signatures legally valid, the app contacts Moldova's public trust services (timestamping and
  certificate-status checks). These requests contain hashes and certificate identifiers, never your documents.

## Information the app processes on your device

| Information | Why | Where it stays |
|---|---|---|
| The certificate on your ID card (your name, certificate number, issuer, validity) | To show which card is inserted and to create signatures | Read from the card when needed; not sent to the developer |
| Your PIN | To unlock the signing key on your card | Sent only to your ID card over the card's encrypted channel. If you choose "remember PIN", it is kept in your operating system's secure credential store (Apple Keychain, Android Keystore, Windows Credential Locker or GNOME Keyring), protected by your device lock or biometrics where the platform supports this, and tied to that card. You can delete it at any time in the app. |
| Documents you sign or verify | To compute and check signatures | Processed locally. Signed copies are saved next to the original (or in the app's folder on iOS). |
| Activity list (file names, dates, results) | So you can find recent documents | Stored only on your device; you can clear it at any time |
| Settings | Your preferences | Stored only on your device |

Biometric checks (Face ID, Touch ID, Windows Hello) are performed by your operating system; the app never receives
biometric data.

## Information sent over the network

The app connects only to the following services, and only when needed:

- **Timestamp authority** (`tsp.pki.gov.md`, Moldovan public-key infrastructure): when a signature includes a
  timestamp, the app sends a cryptographic hash (SHA-256) of the signature value. The document and its contents are
  not sent.
- **Certificate status (OCSP) and revocation lists (CRL)** (`mdqsign.ocsp.pki.md`, `pki.md`): for signature formats
  that embed validation data, the app asks whether a certificate is still valid. The OCSP request contains the
  certificate's serial number and identifiers of its issuer. Revocation lists are public files that are downloaded.
- **Browser connection (optional)**: the app can run a local service on your own device (`127.0.0.1`, not reachable
  from other devices) so that government e-signature websites such as msign.gov.md can ask for a signature. Only
  websites on the official MoldSign allow-list are accepted. Before every signature the app shows which website is
  asking and what will be signed. The resulting signature is returned only to that website, after your
  confirmation. You can switch this feature off in the app.
- **In-app browser (iOS)**: opens msign.gov.md so the browser connection works on iPhone and iPad. That website's own
  privacy policy applies to what you do there.

These services are operated by Moldovan public institutions, and their privacy policies apply to the requests they
receive. The developer does not operate them and receives nothing from them.

## What we do not do

- We do not collect, sell or share personal information.
- We do not use analytics, advertising identifiers or crash-reporting SDKs. If you have enabled crash reporting in
  your operating system, Apple, Google or Microsoft may receive crash reports under their own policies.
- We do not access your contacts, photos, location, camera or microphone.

## Permissions

- **USB / smart-card access**: to talk to your card reader.
- **Network**: for the timestamp and certificate-status services above, and for the optional local browser
  connection.
- **Notifications** (Android): to show the status of the browser connection.
- **Face ID / Touch ID / Windows Hello**: only if you choose to remember your PIN, to unlock it.

## Data retention and deletion

All data the app stores stays on your device. Deleting the remembered PIN, clearing the activity list, or uninstalling
the app removes it. Signed documents remain wherever you saved them.

## Children

eSemnBun is a tool for adults who hold a Moldovan electronic identity card and is not directed at children.

## Your rights

Because the developer does not receive personal data, there is nothing for us to access, correct or delete on our
side. Questions about how the public trust services process requests should go to their operator. You can still
contact us at the address above with any question about this policy. Moldova's personal data protection law
(Law No. 133/2011) and, where applicable, the EU General Data Protection Regulation apply to this policy.

## Changes

If the app's handling of information changes, we will update this policy and its effective date before releasing that
version.
