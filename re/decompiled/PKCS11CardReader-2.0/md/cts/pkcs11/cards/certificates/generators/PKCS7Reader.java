/*
 * Decompiled with CFR 0.152.
 * 
 * Could not load the following classes:
 *  iaik.asn1.CodingException
 *  iaik.asn1.structures.Name
 *  iaik.security.provider.IAIK
 *  iaik.utils.Util
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
import iaik.security.provider.IAIK;
import iaik.utils.Util;
import iaik.x509.X509Certificate;
import iaik.x509.X509ExtensionInitException;
import iaik.x509.extensions.KeyUsage;
import iaik.x509.extensions.SubjectKeyIdentifier;
import java.io.FileInputStream;
import java.io.FileNotFoundException;
import java.security.NoSuchAlgorithmException;
import java.security.NoSuchProviderException;
import java.security.PrivateKey;
import java.security.Provider;
import java.security.PublicKey;
import java.security.Security;
import java.security.cert.Certificate;
import java.security.cert.CertificateException;
import java.security.cert.CertificateFactory;
import java.util.ArrayList;
import java.util.Collection;
import java.util.List;
import md.cts.pkcs11.cards.certificates.generators.CertificateOnly;
import md.cts.pkcs11.cards.certificates.generators.StorableKeyAndCertificate;
import md.cts.pkcs11.cards.exceptions.CertificateImportException;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

public final class PKCS7Reader
implements StorableKeyAndCertificate {
    private static final Logger logger = LoggerFactory.getLogger(PKCS7Reader.class);
    private final X509Certificate certificate;
    private final List<StorableKeyAndCertificate> chain = new ArrayList<StorableKeyAndCertificate>();
    private KeyUsage keyUsage = null;

    public PKCS7Reader(String p7File) throws CertificateImportException {
        Collection<? extends Certificate> certificateChain;
        FileInputStream fileInputStream;
        CertificateFactory certificateFactory;
        Security.addProvider((Provider)new IAIK());
        logger.info("---Starting reading PKCS#7/DER file:");
        logger.info("Loading IAIK X.509 provider");
        try {
            certificateFactory = CertificateFactory.getInstance("X.509", "IAIK");
        }
        catch (CertificateException ex) {
            logger.error("", (Throwable)ex);
            throw new CertificateImportException("Invalid certificate", ex);
        }
        catch (NoSuchProviderException ex) {
            logger.error("", (Throwable)ex);
            throw new CertificateImportException("No such provider", ex);
        }
        logger.info("Reading the file and getting certificates from it");
        try {
            fileInputStream = new FileInputStream(p7File);
        }
        catch (FileNotFoundException ex) {
            logger.error("", (Throwable)ex);
            throw new CertificateImportException("File not found", ex);
        }
        logger.info("Arrange certificate chain so that the original certificate is first");
        try {
            certificateChain = certificateFactory.generateCertificates(fileInputStream);
        }
        catch (CertificateException ex) {
            logger.error("", (Throwable)ex);
            throw new CertificateImportException("Cannot load certificate", ex);
        }
        if (certificateChain.isEmpty()) {
            logger.warn("The file doesn't contain any certificate");
            throw new CertificateImportException("Empty file");
        }
        X509Certificate[] chainArray = new X509Certificate[certificateChain.size()];
        int j = 0;
        for (X509Certificate x509Certificate : certificateChain) {
            chainArray[j++] = x509Certificate;
        }
        chainArray = Util.arrangeCertificateChain((X509Certificate[])chainArray, (boolean)false);
        logger.info("Getting the certificate and put the rest in the chain");
        this.certificate = chainArray[0];
        for (int i = 1; i < chainArray.length; ++i) {
            X509Certificate x509Certificate = chainArray[i];
            this.chain.add(new CertificateOnly(x509Certificate));
        }
        logger.info("Try to get the key usage from the certificate");
        try {
            this.keyUsage = (KeyUsage)this.certificate.getExtension(KeyUsage.oid);
        }
        catch (X509ExtensionInitException ex) {
            logger.error("", (Throwable)ex);
        }
        logger.info("---End reading PKCS#7/DER file:");
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
        return this.keyUsage;
    }

    @Override
    public byte[] getObjectId() {
        try {
            SubjectKeyIdentifier ski = new SubjectKeyIdentifier(this.certificate.getPublicKey());
            return ski.get();
        }
        catch (CodingException | NoSuchAlgorithmException ex) {
            logger.error("", ex);
            return null;
        }
    }

    public X509Certificate getCertificate() {
        return this.certificate;
    }

    @Override
    public List<StorableKeyAndCertificate> getChain() {
        return this.chain;
    }
}

