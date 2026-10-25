/*
 * Decompiled with CFR 0.152.
 * 
 * Could not load the following classes:
 *  iaik.cms.SecurityProvider
 *  iaik.x509.X509Certificate
 *  md.cts.moldsign.transferobjects.models.CertificateModel
 *  org.slf4j.Logger
 *  org.slf4j.LoggerFactory
 */
package md.cts.cryptography.providers;

import iaik.cms.SecurityProvider;
import iaik.x509.X509Certificate;
import java.io.IOException;
import java.security.KeyStore;
import java.security.KeyStoreException;
import java.security.NoSuchAlgorithmException;
import java.security.NoSuchProviderException;
import java.security.PrivateKey;
import java.security.Provider;
import java.security.Security;
import java.security.UnrecoverableKeyException;
import java.security.cert.CertificateException;
import java.util.Collection;
import java.util.Enumeration;
import java.util.HashSet;
import java.util.LinkedList;
import java.util.List;
import md.cts.cryptography.providers.CertificateProvider;
import md.cts.cryptography.providers.SecurityOperationProvider;
import md.cts.moldsign.transferobjects.models.CertificateModel;
import md.cts.pkcs11.cards.exceptions.OperationFailedException;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

public final class MSCSPSecurityProvider
extends SecurityOperationProvider
implements CertificateProvider {
    private static final String providerId = "MSCSP";
    private static final Logger logger = LoggerFactory.getLogger(MSCSPSecurityProvider.class);
    private final Provider provider;
    private List<CertificateModel> certificates = null;

    public MSCSPSecurityProvider() {
        logger.info("new MSCSPSecurityProvider");
        this.provider = Security.getProvider("SunMSCAPI");
    }

    @Override
    public Provider getProvider() {
        return this.provider;
    }

    private KeyStore getKeyStore() throws OperationFailedException {
        logger.info("MSCSP getKeyStore()");
        try {
            KeyStore store = KeyStore.getInstance("Windows-MY", "SunMSCAPI");
            store.load(null, null);
            return store;
        }
        catch (NoSuchProviderException ex) {
            logger.error("", (Throwable)ex);
            throw new OperationFailedException("exception.general.no_such_provider", ex);
        }
        catch (KeyStoreException ex) {
            logger.error("", (Throwable)ex);
            throw new OperationFailedException("exception.general.key_store_exception", ex);
        }
        catch (CertificateException ex) {
            logger.error("", (Throwable)ex);
            throw new OperationFailedException("exception.general.certificate_exception", ex);
        }
        catch (NoSuchAlgorithmException ex) {
            logger.error("", (Throwable)ex);
            throw new OperationFailedException("exception.general.no_such_algorithm", ex);
        }
        catch (IOException ex) {
            logger.error("", (Throwable)ex);
            throw new OperationFailedException("exception.general.io_exception", ex);
        }
    }

    @Override
    public SecurityProvider getSecurityProvider() {
        return new SecurityProvider();
    }

    @Override
    public String getId() {
        return providerId;
    }

    @Override
    public Collection<CertificateModel> getCertificates(boolean privateKeyExists) {
        HashSet<CertificateModel> result = new HashSet<CertificateModel>();
        if (this.certificates == null) {
            try {
                this.refreshCertificates();
            }
            catch (OperationFailedException ex) {
                logger.error("", (Throwable)ex);
            }
        }
        for (CertificateModel cert : this.certificates) {
            if (privateKeyExists && !cert.isPrivateKeyPresent()) continue;
            result.add(cert);
        }
        return result;
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
            int i = 0;
            while (aliasEnum.hasMoreElements()) {
                CertificateModel cert = new CertificateModel();
                String alias = aliasEnum.nextElement();
                try {
                    cert.setCertificate(new X509Certificate(ks.getCertificate(alias).getEncoded()));
                    cert.setLabel(alias);
                    cert.setPrivateKeyPresent(ks.isKeyEntry(alias));
                    cert.setProviderId(providerId);
                    this.certificates.add(cert);
                    ++i;
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

    @Override
    public PrivateKey getPrivateKey(String alias) throws OperationFailedException {
        KeyStore store = this.getKeyStore();
        try {
            return (PrivateKey)store.getKey(alias, null);
        }
        catch (KeyStoreException | NoSuchAlgorithmException | UnrecoverableKeyException ex) {
            throw new OperationFailedException("exception.certificate.no_private_key", ex);
        }
    }
}

