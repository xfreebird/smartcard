/*
 * Decompiled with CFR 0.152.
 * 
 * Could not load the following classes:
 *  iaik.pkcs.pkcs11.Session
 *  iaik.pkcs.pkcs11.TokenException
 *  iaik.pkcs.pkcs11.objects.Certificate
 *  iaik.pkcs.pkcs11.objects.Key
 *  iaik.pkcs.pkcs11.objects.Object
 *  iaik.pkcs.pkcs11.objects.X509PublicKeyCertificate
 *  org.slf4j.Logger
 *  org.slf4j.LoggerFactory
 */
package md.cts.pkcs11;

import iaik.pkcs.pkcs11.Session;
import iaik.pkcs.pkcs11.TokenException;
import iaik.pkcs.pkcs11.objects.Certificate;
import iaik.pkcs.pkcs11.objects.Key;
import iaik.pkcs.pkcs11.objects.X509PublicKeyCertificate;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import md.cts.pkcs11.cards.CardReader;
import md.cts.pkcs11.cards.CardReaderManager;
import md.cts.pkcs11.cards.certificates.CertificateFull;
import md.cts.pkcs11.cards.exceptions.InvalidPinException;
import md.cts.pkcs11.cards.exceptions.OperationFailedException;
import md.cts.pkcs11.cards.exceptions.SessionInitializationException;
import md.cts.pkcs11.util.ByteArrayWrapper;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

public final class TokenSes {
    private static final Logger logger = LoggerFactory.getLogger(TokenSes.class);

    private static Session openSession(CardReader reader) throws SessionInitializationException {
        Session session;
        try {
            session = reader.getPkcsProvider().getTokenManager().getSession(false);
        }
        catch (Exception ex) {
            throw new SessionInitializationException(ex);
        }
        logger.info("Session initialized");
        return session;
    }

    private static void closeSession(CardReader reader, Session session) {
        if (session != null) {
            try {
                session.closeSession();
                reader.getPkcsProvider().getTokenManager().closeSession(session);
                reader.getPkcsProvider().getTokenManager().disposeSession(session);
            }
            catch (TokenException ex) {
                logger.warn("closeSession", (Throwable)ex);
            }
        }
    }

    /*
     * WARNING - Removed try catching itself - possible behaviour change.
     */
    public static synchronized List<CertificateFull> refreshCertificates(Long slotGlobalId) throws OperationFailedException, InvalidPinException {
        Session session;
        CardReader cardReader = CardReaderManager.get().getSlotByGlobalId(slotGlobalId);
        if (cardReader == null) {
            return new ArrayList<CertificateFull>();
        }
        int nrRetries = 5;
        try {
            session = TokenSes.openSession(cardReader);
        }
        catch (SessionInitializationException ex) {
            throw new OperationFailedException(ex);
        }
        HashMap<ByteArrayWrapper, CertificateFull> certs = new HashMap<ByteArrayWrapper, CertificateFull>();
        try {
            try {
                session.findObjectsInit(null);
            }
            catch (TokenException ex) {
                throw new OperationFailedException(ex);
            }
            while (true) {
                ByteArrayWrapper baw;
                iaik.pkcs.pkcs11.objects.Object[] oarr;
                try {
                    oarr = session.findObjects(1);
                }
                catch (TokenException ex) {
                    if (nrRetries > 0) {
                        --nrRetries;
                        continue;
                    }
                    throw new OperationFailedException(ex);
                }
                if (oarr.length == 0) break;
                iaik.pkcs.pkcs11.objects.Object obj = oarr[0];
                if (obj instanceof Key) {
                    Key key = (Key)obj;
                    baw = new ByteArrayWrapper(key.getId());
                } else {
                    if (!(obj instanceof Certificate)) continue;
                    X509PublicKeyCertificate cert = (X509PublicKeyCertificate)obj;
                    baw = new ByteArrayWrapper(cert.getId());
                }
                CertificateFull fullCertificate = (CertificateFull)certs.get(baw);
                if (fullCertificate == null) {
                    fullCertificate = new CertificateFull(obj);
                } else {
                    fullCertificate.addObject(obj);
                }
                certs.put(baw, fullCertificate);
            }
            try {
                session.findObjectsFinal();
            }
            catch (TokenException oarr) {
                logger.info("", (Throwable)oarr);
            }
        }
        finally {
            TokenSes.closeSession(cardReader, session);
        }
        return new ArrayList<CertificateFull>(certs.values());
    }
}

