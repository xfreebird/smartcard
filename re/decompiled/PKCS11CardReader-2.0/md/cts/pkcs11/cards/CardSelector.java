/*
 * Decompiled with CFR 0.152.
 * 
 * Could not load the following classes:
 *  iaik.pkcs.pkcs11.Module
 *  iaik.pkcs.pkcs11.Slot
 *  iaik.pkcs.pkcs11.TokenException
 *  md.ghesar.Intern
 *  org.slf4j.Logger
 *  org.slf4j.LoggerFactory
 */
package md.cts.pkcs11.cards;

import iaik.pkcs.pkcs11.Module;
import iaik.pkcs.pkcs11.Slot;
import iaik.pkcs.pkcs11.TokenException;
import java.util.HashSet;
import java.util.Set;
import md.cts.pkcs11.cards.CardReader;
import md.ghesar.Intern;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

public final class CardSelector {
    private static final Logger logger = LoggerFactory.getLogger(CardSelector.class);
    private final String moduleLibrary;
    private Module pkcs11Module;
    private boolean initialized = false;
    private short initErrCount = 0;

    public CardSelector(String nativeLibraryPath) {
        this.moduleLibrary = nativeLibraryPath;
    }

    public String getId() {
        return this.moduleLibrary;
    }

    public Module getModule() {
        return this.pkcs11Module;
    }

    private void pkcs11Initialize() throws TokenException {
        logger.info("init driver: {}", (Object)this.moduleLibrary);
        try {
            this.pkcs11Module.initialize(null);
        }
        catch (TokenException ex) {
            String message = ex.getMessage();
            logger.error("init {}", (Object)message);
            if (message.equalsIgnoreCase("CKR_CRYPTOKI_ALREADY_INITIALIZED")) {
                return;
            }
            throw ex;
        }
    }

    public Set<CardReader> getAllReaders() {
        Slot[] slots;
        if (!this.initialized) {
            try {
                if (this.pkcs11Module == null) {
                    logger.info("Loading driver: {}", (Object)this.moduleLibrary);
                    this.pkcs11Module = Module.getInstance((String)this.moduleLibrary);
                }
                this.pkcs11Initialize();
                this.initialized = true;
            }
            catch (Exception ex) {
                this.initErrCount = (short)(this.initErrCount + 1);
                if (this.initErrCount <= 2) {
                    logger.error("Failed to initialize module {}", (Object)this.moduleLibrary, (Object)ex);
                }
                return null;
            }
        }
        if ((slots = this.getPkcs11ModuleSlots()) == null || slots.length == 0) {
            return null;
        }
        HashSet<CardReader> currentReaders = new HashSet<CardReader>(slots.length);
        for (Slot s : slots) {
            CardReader reader = new CardReader(s, this.getId());
            currentReaders.add(reader);
        }
        return currentReaders;
    }

    private Slot[] getPkcs11ModuleSlots() {
        Slot[] slots;
        if (Intern.resetOnSlotListRefresh) {
            try {
                this.pkcs11Module.getSlotList(false);
            }
            catch (TokenException ex) {
                logger.error("getSlotList reset", (Throwable)ex);
            }
        }
        try {
            slots = this.pkcs11Module.getSlotList(true);
        }
        catch (TokenException ex) {
            logger.error("getSlotList", (Throwable)ex);
            return null;
        }
        return slots;
    }

    public void close() {
        logger.info("close() {}", (Object)this.moduleLibrary);
        if (this.pkcs11Module == null) {
            return;
        }
        try {
            this.pkcs11Module.finalize(null);
            this.initialized = false;
            this.pkcs11Module = null;
        }
        catch (TokenException ex) {
            logger.warn("Error closing driver {}", (Object)this.moduleLibrary);
            logger.error("", (Throwable)ex);
        }
    }

    public String getPkcs11ModuleName() {
        return this.pkcs11Module.toString();
    }

    public String getPkcs11ModuleInfo() {
        try {
            return this.pkcs11Module.getInfo().toString();
        }
        catch (TokenException ex) {
            logger.error("", (Throwable)ex);
            return null;
        }
    }
}

