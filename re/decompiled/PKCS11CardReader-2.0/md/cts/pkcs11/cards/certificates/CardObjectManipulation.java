/*
 * Decompiled with CFR 0.152.
 * 
 * Could not load the following classes:
 *  md.cts.moldsign.transferobjects.models.CertificateModel
 *  org.slf4j.Logger
 *  org.slf4j.LoggerFactory
 */
package md.cts.pkcs11.cards.certificates;

import java.util.ArrayList;
import java.util.Collection;
import java.util.HashMap;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import md.cts.cryptography.providers.CertificateProvider;
import md.cts.moldsign.transferobjects.models.CertificateModel;
import md.cts.pkcs11.TokenSes;
import md.cts.pkcs11.cards.CardReader;
import md.cts.pkcs11.cards.CardReaderManager;
import md.cts.pkcs11.cards.certificates.CertificateFull;
import md.cts.pkcs11.cards.exceptions.InvalidPinException;
import md.cts.pkcs11.cards.exceptions.OperationFailedException;
import md.cts.pkcs11.util.ByteArrayWrapper;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

public final class CardObjectManipulation
implements CertificateProvider {
    private static final Logger logger = LoggerFactory.getLogger(CardObjectManipulation.class);
    private static final Map<Long, CardObjectManipulation> instances = new HashMap<Long, CardObjectManipulation>();
    private final Long slotGlobalId;
    private List<CertificateFull> certFullList = new ArrayList<CertificateFull>();

    private CardObjectManipulation(Long slotGlobalId) {
        this.slotGlobalId = slotGlobalId;
    }

    public static CardObjectManipulation getInstance(Long slotGlobalId) {
        if (!instances.containsKey(slotGlobalId)) {
            CardObjectManipulation com = new CardObjectManipulation(slotGlobalId);
            instances.put(slotGlobalId, com);
        }
        return instances.get(slotGlobalId);
    }

    public static void closeCardReader(Long slotGlobalId) {
        instances.remove(slotGlobalId);
    }

    @Override
    public String getId() {
        CardReader cardReader = CardReaderManager.get().getSlotByGlobalId(this.slotGlobalId);
        return cardReader.getId();
    }

    @Override
    public void refreshCertificates() throws OperationFailedException {
        logger.info("Refreshing list of certificates");
        try {
            this.certFullList = TokenSes.refreshCertificates(this.slotGlobalId);
            logger.info("found:{}", (Object)this.certFullList.size());
        }
        catch (InvalidPinException ex) {
            logger.error("", (Throwable)ex);
            throw new OperationFailedException(ex);
        }
        catch (ClassCastException ex) {
            logger.error("", (Throwable)ex);
            throw new OperationFailedException(ex);
        }
    }

    @Override
    public Collection<CertificateModel> getCertificates(boolean privateKeyExists) {
        HashSet<CertificateModel> certificates = new HashSet<CertificateModel>();
        for (CertificateFull cert : this.certFullList) {
            if (!cert.hasCert()) continue;
            ByteArrayWrapper baw = new ByteArrayWrapper(cert.getId());
            CertificateModel certResult = new CertificateModel(baw.toString(), cert.getLabel(), this.getId(), cert.getCert(), true);
            certificates.add(certResult);
        }
        return certificates;
    }

    public List<CertificateFull> getPKCS11Certificates() {
        logger.info("getPKCS11Certificates() count={}", (Object)this.certFullList.size());
        return this.certFullList;
    }
}

