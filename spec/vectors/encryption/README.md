# Synthetic encryption compatibility fixtures

All identities and secrets here are test-only. `test-private-key.pk8` is an intentionally public synthetic RSA key, not a user/card credential. Never import it into a real identity store.

- AES: installed MoldSign Desktop 2.0 EncryptCMSSymmetricWorker output, read back by DecryptCMSSymmetricWorker. Password `Test-șț-🔐-2026`, key sizes 128/192/256, plaintext lengths 0/1/15/16/17/1024, byte(i * 37).
- Legacy CMS: vendor 3DES, MD5/DES and RC2-40 output at the same sizes, password `Legacy-Test-2026`; read-only support.
- Certificate CMS: vendor-shipped IAIK streaming BER with AES-128/RSA PKCS#1 v1.5 and the fictional recipient certificate. This software oracle does not exercise vendor trust UI or physical card transport.
- `extended-sm.json`: independently generated AES/CMAC secure-message vectors for extended APDUs with 0/257/513-byte payloads; no real PIN or session keys.
- `test-signing-only.der`: fictional RSA-2048 leaf certificate with critical Non Repudiation usage and no keyEncipherment, using the same intentionally public `test-private-key.pk8`. Swift/Kotlin/C# policy regressions share it: default purpose checks reject it; explicit card public-key compatibility can round-trip with the fixture key. This is not evidence of any real card's decipher capability.

Regenerate that certificate with OpenSSL (the key is already public test data):

```sh
openssl req -new -x509 -key spec/vectors/encryption/test-private-key.pk8 -keyform DER \
  -subj '/CN=TEST PUBLIC KEY COMPATIBILITY' -days 3650 -sha256 -set_serial 0x123456 \
  -addext keyUsage=critical,nonRepudiation -addext basicConstraints=critical,CA:FALSE \
  -outform DER -out spec/vectors/encryption/test-signing-only.der
```

Generators: `scripts/compatibility/MoldSignEncryptionOracle.java`, `MoldSignCMSOracle.java`, and `extended_sm_vectors.py`. Java oracles require a locally installed vendor suite; proprietary libraries are not copied into the repo. Native tests may export files to an existing directory through `MSIGN_ENCRYPTION_ORACLE_OUTPUT`, then the Java `verify DIRECTORY` commands independently decrypt them. Copy the public fixture certificate/key and plaintexts to that directory first.
