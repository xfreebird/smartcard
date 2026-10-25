/*
 * Decompiled with CFR 0.152.
 * 
 * Could not load the following classes:
 *  iaik.x509.X509Certificate
 *  md.cts.moldsign.transferobjects.models.CertificateModel
 *  org.slf4j.Logger
 *  org.slf4j.LoggerFactory
 */
package md.cts.cryptography.providers;

import iaik.x509.X509Certificate;
import java.io.IOException;
import java.security.KeyStore;
import java.security.KeyStoreException;
import java.security.NoSuchAlgorithmException;
import java.security.cert.CertificateException;
import java.util.Collection;
import java.util.Enumeration;
import java.util.LinkedList;
import java.util.List;
import md.cts.cryptography.providers.CertificateProvider;
import md.cts.moldsign.transferobjects.models.CertificateModel;
import md.cts.pkcs11.cards.exceptions.OperationFailedException;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

public final class JKSTrustedCertificateProvider
implements CertificateProvider {
    private static final String providerId = "JKS trusted";
    private static final Logger logger = LoggerFactory.getLogger(JKSTrustedCertificateProvider.class);
    private List<CertificateModel> certificates = null;

    @Override
    public String getId() {
        return providerId;
    }

    private KeyStore getKeyStore() {
        KeyStore ks = null;
        try {
            ks = KeyStore.getInstance("JKS");
            ks.load(JKSTrustedCertificateProvider.class.getResourceAsStream("/trusted.jks"), "MoldSignKeyStorePass2012".toCharArray());
        }
        catch (IOException | KeyStoreException | NoSuchAlgorithmException | CertificateException ex) {
            logger.error("", (Throwable)ex);
        }
        return ks;
    }

    @Override
    public Collection<CertificateModel> getCertificates(boolean privateKeyExists) {
        if (this.certificates == null) {
            try {
                this.refreshCertificates();
            }
            catch (OperationFailedException ex) {
                logger.error("", (Throwable)ex);
            }
        }
        logger.info("providerId:{} certificates.size() = {}", (Object)providerId, (Object)this.certificates.size());
        return this.certificates;
    }

    @Override
    public void refreshCertificates() throws OperationFailedException {
        if (this.certificates == null) {
            this.certificates = new LinkedList<CertificateModel>();
        } else {
            this.certificates.clear();
        }
        try {
            KeyStore ks = this.getKeyStore();
            Enumeration<String> aliasEnum = ks.aliases();
            while (aliasEnum.hasMoreElements()) {
                CertificateModel cert = new CertificateModel();
                String alias = aliasEnum.nextElement();
                try {
                    cert.setCertificate(new X509Certificate(ks.getCertificate(alias).getEncoded()));
                    cert.setLabel(alias);
                    cert.setPrivateKeyPresent(ks.isKeyEntry(alias));
                    cert.setProviderId(providerId);
                    this.certificates.add(cert);
                }
                catch (CertificateException ex) {
                    logger.error("", (Throwable)ex);
                }
            }
        }
        catch (KeyStoreException ex) {
            logger.error("", (Throwable)ex);
        }
    }
}

