/*
 * Decompiled with CFR 0.152.
 * 
 * Could not load the following classes:
 *  iaik.pkcs.pkcs11.Module
 *  iaik.x509.X509Certificate
 *  md.cts.moldsign.transferobjects.models.CertificateModel
 *  org.slf4j.Logger
 *  org.slf4j.LoggerFactory
 */
package md.cts.pkcs11.cards;

import iaik.pkcs.pkcs11.Module;
import iaik.x509.X509Certificate;
import java.util.ArrayList;
import java.util.Collection;
import java.util.Collections;
import java.util.HashMap;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.Objects;
import java.util.Set;
import java.util.concurrent.atomic.AtomicLong;
import md.cts.cryptography.providers.GlobalCertificateProvider;
import md.cts.cryptography.providers.PKCS11SecurityProvider;
import md.cts.cryptography.providers.SecurityOperationsProviderManager;
import md.cts.moldsign.transferobjects.models.CertificateModel;
import md.cts.pkcs11.cards.Card;
import md.cts.pkcs11.cards.CardReader;
import md.cts.pkcs11.cards.CardSelector;
import md.cts.pkcs11.cards.certificates.CardObjectManipulation;
import md.cts.pkcs11.cards.observers.CardActionObserver;
import md.cts.pkcs11.cards.observers.CardReaderEvent;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

public final class CardReaderManager {
    private static final Logger logger = LoggerFactory.getLogger(CardReaderManager.class);
    private static final AtomicLong counter = new AtomicLong(1L);
    private static CardReaderManager instance = null;
    private final Map<Long, CardReader> readers = Collections.synchronizedMap(new HashMap());
    private final Map<Long, CardSelector> selectors = Collections.synchronizedMap(new HashMap());
    private final List<CardActionObserver> cardActionObservers = new ArrayList<CardActionObserver>();
    private CardSelectorMonitor observerThread;

    private CardReaderManager() {
    }

    public static CardReaderManager get() {
        if (instance == null) {
            instance = new CardReaderManager();
        }
        return instance;
    }

    private static long atomicLongKey() {
        return counter.getAndIncrement();
    }

    /*
     * WARNING - Removed try catching itself - possible behaviour change.
     */
    public CardReader getSlotByGlobalId(Long slotGlobalId) {
        Map<Long, CardReader> map = this.readers;
        synchronized (map) {
            return this.readers.get(slotGlobalId);
        }
    }

    public Collection<CardSelector> getAllSelector() {
        return this.selectors.values();
    }

    /*
     * WARNING - Removed try catching itself - possible behaviour change.
     */
    public List<Module> getAllModules() {
        ArrayList<Module> drvList = new ArrayList<Module>();
        Map<Long, CardSelector> map = this.selectors;
        synchronized (map) {
            for (CardSelector drv : this.selectors.values()) {
                if ("acospkcs11.dll".equals(drv.getId())) continue;
                drvList.add(drv.getModule());
            }
        }
        return drvList;
    }

    public Card getCardByCertificate(X509Certificate cert) {
        for (CardReader reader : this.readers.values()) {
            Collection<CertificateModel> certList = CardObjectManipulation.getInstance(reader.getGlobalId()).getCertificates(true);
            for (CertificateModel model : certList) {
                if (!Objects.equals(cert.getSerialNumber(), model.getCertificate().getSerialNumber())) continue;
                return reader.getCard();
            }
        }
        return null;
    }

    private void onRemove(CardReader slot) {
        logger.info("Card removed from reader {}", (Object)slot.getId());
        CardObjectManipulation.closeCardReader(slot.getGlobalId());
        SecurityOperationsProviderManager.removeProvider(slot.getId());
        GlobalCertificateProvider.get().removeProvider(slot.getId());
        this.notifyCardActionObservers(new CardReaderEvent(slot.getGlobalId(), CardReaderEvent.Action.REMOVED));
    }

    private void onInsert(CardReader slot) {
        logger.info("Card inserted into reader {}", (Object)slot.getId());
        GlobalCertificateProvider.get().registerProvider(CardObjectManipulation.getInstance(slot.getGlobalId()), false);
        SecurityOperationsProviderManager.registerProvider(slot.getId(), new PKCS11SecurityProvider(slot.getPkcsProvider()));
        this.notifyCardActionObservers(new CardReaderEvent(slot.getGlobalId(), CardReaderEvent.Action.INSERTED));
    }

    /*
     * WARNING - Removed try catching itself - possible behaviour change.
     */
    private void monitorRemoving() {
        HashSet<CardReader> newToNotify = new HashSet<CardReader>();
        Map<Long, CardReader> map = this.readers;
        synchronized (map) {
            for (Map.Entry<Long, CardReader> entry : this.readers.entrySet()) {
                Long id = entry.getKey();
                CardReader slot = entry.getValue();
                if (slot.checkCardPresent()) continue;
                newToNotify.add(slot);
                this.readers.remove(id);
            }
        }
        if (newToNotify.isEmpty()) {
            return;
        }
        for (CardReader slot : newToNotify) {
            this.onRemove(slot);
        }
    }

    /*
     * WARNING - Removed try catching itself - possible behaviour change.
     */
    private void registerCards(List<CardReader> newToRegister) {
        HashSet<CardReader> newToNotify = new HashSet<CardReader>();
        Map<Long, CardReader> map = this.readers;
        synchronized (map) {
            for (CardReader slot : newToRegister) {
                if (!slot.checkCardPresent()) continue;
                Long slotGlobalId = CardReaderManager.atomicLongKey();
                this.readers.put(slotGlobalId, slot);
                slot.setGlobalId(slotGlobalId);
                newToNotify.add(slot);
            }
        }
        if (newToNotify.isEmpty()) {
            return;
        }
        for (CardReader slot : newToNotify) {
            this.onInsert(slot);
        }
    }

    /*
     * WARNING - Removed try catching itself - possible behaviour change.
     */
    private void refreshCardReaders() {
        ArrayList<CardReader> newToRegister = new ArrayList<CardReader>();
        Map<Long, CardSelector> map = this.selectors;
        synchronized (map) {
            for (CardSelector drv : this.selectors.values()) {
                Set<CardReader> currentReaders = drv.getAllReaders();
                if (currentReaders == null) continue;
                Map<Long, CardReader> map2 = this.readers;
                synchronized (map2) {
                    HashSet<CardReader> readersCopy = new HashSet<CardReader>(this.readers.values());
                    currentReaders.removeAll(readersCopy);
                    newToRegister.addAll(currentReaders);
                }
            }
        }
        if (newToRegister.isEmpty()) {
            return;
        }
        this.registerCards(newToRegister);
    }

    public void loadDriverLibList(List<String> driverLibList) {
        for (String driverLib : driverLibList) {
            this.loadDriver(driverLib);
        }
    }

    /*
     * WARNING - Removed try catching itself - possible behaviour change.
     */
    public void loadDriver(String driverName) {
        if ((driverName = driverName.trim()).isEmpty()) {
            return;
        }
        Map<Long, CardSelector> map = this.selectors;
        synchronized (map) {
            for (CardSelector drv : this.selectors.values()) {
                if (!driverName.equals(drv.getId())) continue;
                return;
            }
            CardSelector selector = new CardSelector(driverName);
            this.selectors.put(CardReaderManager.atomicLongKey(), selector);
        }
    }

    /*
     * WARNING - Removed try catching itself - possible behaviour change.
     */
    public void removeAllDrivers() {
        Map<Long, CardSelector> map = this.selectors;
        synchronized (map) {
            for (CardSelector drv : this.selectors.values()) {
                logger.info("removing driver {}", (Object)drv.getId());
                drv.close();
            }
            this.selectors.clear();
            Map<Long, CardReader> map2 = this.readers;
            synchronized (map2) {
                for (CardReader slot : this.readers.values()) {
                    logger.info("removing slot {}", (Object)slot.getId());
                    this.onRemove(slot);
                }
                this.readers.clear();
            }
        }
    }

    /*
     * WARNING - Removed try catching itself - possible behaviour change.
     */
    public void removeDriver(String driverName) {
        if ((driverName = driverName.trim()).isEmpty()) {
            return;
        }
        logger.info("remove {}", (Object)driverName);
        Map<Long, CardSelector> map = this.selectors;
        synchronized (map) {
            for (Map.Entry<Long, CardSelector> entry : this.selectors.entrySet()) {
                Long id = entry.getKey();
                CardSelector drv = entry.getValue();
                this.selectors.remove(id);
                drv.close();
            }
        }
    }

    /*
     * WARNING - Removed try catching itself - possible behaviour change.
     */
    public void registerCardActionObserver(CardActionObserver observer) {
        List<CardActionObserver> list = this.cardActionObservers;
        synchronized (list) {
            this.cardActionObservers.add(observer);
        }
    }

    /*
     * WARNING - Removed try catching itself - possible behaviour change.
     */
    public void notifyCardActionObservers(CardReaderEvent cre) {
        List<CardActionObserver> list = this.cardActionObservers;
        synchronized (list) {
            for (CardActionObserver cao : this.cardActionObservers) {
                cao.onCardAction(cre);
            }
        }
    }

    public void startListeners() {
        this.observerThread = new CardSelectorMonitor("Monitor");
        this.observerThread.start();
    }

    public void stopListening() {
        this.observerThread.stopRunning();
    }

    private class CardSelectorMonitor
    extends Thread {
        private volatile boolean shouldRun;

        public CardSelectorMonitor(String name) {
            super(name);
            this.shouldRun = true;
        }

        @Override
        public void run() {
            logger.info("thread started");
            while (this.shouldRun) {
                try {
                    CardReaderManager.this.monitorRemoving();
                    CardReaderManager.this.refreshCardReaders();
                }
                catch (Exception ex) {
                    logger.error("", (Throwable)ex);
                }
                try {
                    Thread.sleep(1000L);
                }
                catch (InterruptedException ex) {
                    this.shouldRun = false;
                }
            }
            logger.info("thread stopped");
        }

        public void stopRunning() {
            this.shouldRun = false;
            this.interrupt();
        }
    }
}

