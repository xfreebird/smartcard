/*
 * Decompiled with CFR 0.152.
 * 
 * Could not load the following classes:
 *  iaik.asn1.CodingException
 *  iaik.asn1.structures.Name
 *  iaik.x509.X509Certificate
 *  iaik.x509.X509ExtensionInitException
 *  iaik.x509.extensions.KeyUsage
 *  iaik.x509.extensions.SubjectKeyIdentifier
 *  org.slf4j.Logger
 *  org.slf4j.LoggerFactory
 */
package md.cts.pkcs11.cards.certificates.generators;

import iaik.asn1.CodingException;
import iaik.asn1.structures.Name;
import iaik.x509.X509Certificate;
import iaik.x509.X509ExtensionInitException;
import iaik.x509.extensions.KeyUsage;
import iaik.x509.extensions.SubjectKeyIdentifier;
import java.security.NoSuchAlgorithmException;
import java.security.PrivateKey;
import java.security.PublicKey;
import java.util.ArrayList;
import java.util.List;
import md.cts.pkcs11.cards.certificates.generators.StorableKeyAndCertificate;
import md.cts.pkcs11.cards.exceptions.CertificateImportException;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

public final class CertificateOnly
implements StorableKeyAndCertificate {
    private static final Logger logger = LoggerFactory.getLogger(CertificateOnly.class);
    private final X509Certificate certificate;
    private final byte[] objectId;

    public CertificateOnly(X509Certificate certificate) throws CertificateImportException {
        SubjectKeyIdentifier ski;
        this.certificate = certificate;
        try {
            ski = new SubjectKeyIdentifier(certificate.getPublicKey());
        }
        catch (CodingException | NoSuchAlgorithmException ex) {
            logger.error("", ex);
            throw new CertificateImportException("Problem while generating Subject key identifier", ex);
        }
        this.objectId = ski.get();
    }

    @Override
    public PrivateKey getPrivateKey() {
        return null;
    }

    @Override
    public PublicKey getPublicKey() {
        return this.certificate.getPublicKey();
    }

    @Override
    public Name getCertificateName() {
        return (Name)this.certificate.getSubjectDN();
    }

    @Override
    public KeyUsage getKeyUsage() {
        try {
            return (KeyUsage)this.certificate.getExtension(KeyUsage.oid);
        }
        catch (X509ExtensionInitException ex) {
            return null;
        }
    }

    @Override
    public byte[] getObjectId() {
        return this.objectId;
    }

    public X509Certificate getCertificate() {
        return this.certificate;
    }

    @Override
    public List<StorableKeyAndCertificate> getChain() {
        return new ArrayList<StorableKeyAndCertificate>(0);
    }
}

