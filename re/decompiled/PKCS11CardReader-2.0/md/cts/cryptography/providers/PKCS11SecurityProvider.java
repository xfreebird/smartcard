/*
 * Decompiled with CFR 0.152.
 * 
 * Could not load the following classes:
 *  iaik.cms.SecurityProvider
 *  iaik.pkcs.pkcs11.provider.IAIKPkcs11
 *  iaik.pkcs.pkcs11.provider.TokenKeyStore
 *  org.slf4j.Logger
 *  org.slf4j.LoggerFactory
 */
package md.cts.cryptography.providers;

import iaik.cms.SecurityProvider;
import iaik.pkcs.pkcs11.provider.IAIKPkcs11;
import iaik.pkcs.pkcs11.provider.TokenKeyStore;
import java.security.KeyStore;
import java.security.KeyStoreException;
import java.security.NoSuchAlgorithmException;
import java.security.PrivateKey;
import java.security.Provider;
import java.security.UnrecoverableKeyException;
import md.cts.cryptography.providers.IaikPkcs11SecurityProvider;
import md.cts.cryptography.providers.SecurityOperationProvider;
import md.cts.pkcs11.cards.exceptions.OperationFailedException;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

public final class PKCS11SecurityProvider
extends SecurityOperationProvider {
    private static final Logger logger = LoggerFactory.getLogger(PKCS11SecurityProvider.class);
    private final IAIKPkcs11 provider;

    public PKCS11SecurityProvider(IAIKPkcs11 provider) {
        logger.info("new PKCS11SecurityProvider");
        this.provider = provider;
    }

    @Override
    public Provider getProvider() {
        return this.provider;
    }

    private KeyStore getKeyStore() throws OperationFailedException {
        TokenKeyStore tokenKeyStore = this.provider.getTokenManager().getKeyStore();
        return tokenKeyStore;
    }

    @Override
    public PrivateKey getPrivateKey(String alias) throws OperationFailedException {
        KeyStore store = this.getKeyStore();
        logger.info("store.getKey");
        try {
            return (PrivateKey)store.getKey(alias, null);
        }
        catch (KeyStoreException | NoSuchAlgorithmException | UnrecoverableKeyException ex) {
            throw new OperationFailedException("exception.certificate.no_private_key", ex);
        }
    }

    @Override
    public SecurityProvider getSecurityProvider() {
        if (this.provider != null) {
            return new IaikPkcs11SecurityProvider(this.provider);
        }
        return new SecurityProvider();
    }
}

