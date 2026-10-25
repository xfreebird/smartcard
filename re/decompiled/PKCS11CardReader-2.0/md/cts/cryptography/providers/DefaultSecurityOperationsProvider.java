/*
 * Decompiled with CFR 0.152.
 * 
 * Could not load the following classes:
 *  iaik.cms.SecurityProvider
 *  iaik.security.provider.IAIK
 *  org.slf4j.Logger
 *  org.slf4j.LoggerFactory
 */
package md.cts.cryptography.providers;

import iaik.cms.SecurityProvider;
import iaik.security.provider.IAIK;
import java.security.PrivateKey;
import java.security.Provider;
import md.cts.cryptography.providers.SecurityOperationProvider;
import md.cts.pkcs11.cards.exceptions.OperationFailedException;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

public final class DefaultSecurityOperationsProvider
extends SecurityOperationProvider {
    private static final Logger logger = LoggerFactory.getLogger(DefaultSecurityOperationsProvider.class);

    public DefaultSecurityOperationsProvider() {
        logger.info("new DefaultSecurityOperationsProvider");
        IAIK.addAsProvider();
    }

    @Override
    public Provider getProvider() {
        return IAIK.getInstance();
    }

    @Override
    public SecurityProvider getSecurityProvider() {
        throw new UnsupportedOperationException("Not supported yet.");
    }

    @Override
    public PrivateKey getPrivateKey(String alias) throws OperationFailedException {
        throw new UnsupportedOperationException("Not supported yet.");
    }
}

