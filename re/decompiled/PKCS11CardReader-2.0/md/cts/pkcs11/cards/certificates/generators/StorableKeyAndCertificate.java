/*
 * Decompiled with CFR 0.152.
 * 
 * Could not load the following classes:
 *  iaik.asn1.structures.Name
 *  iaik.x509.extensions.KeyUsage
 */
package md.cts.pkcs11.cards.certificates.generators;

import iaik.asn1.structures.Name;
import iaik.x509.extensions.KeyUsage;
import java.security.PrivateKey;
import java.security.PublicKey;
import java.security.cert.X509Certificate;
import java.util.List;

public interface StorableKeyAndCertificate {
    public PrivateKey getPrivateKey();

    public PublicKey getPublicKey();

    public Name getCertificateName();

    public KeyUsage getKeyUsage();

    public byte[] getObjectId();

    public X509Certificate getCertificate();

    public List<StorableKeyAndCertificate> getChain();
}

