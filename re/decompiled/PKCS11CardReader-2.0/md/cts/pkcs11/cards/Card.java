/*
 * Decompiled with CFR 0.152.
 * 
 * Could not load the following classes:
 *  iaik.pkcs.pkcs11.Session
 *  iaik.pkcs.pkcs11.Slot
 *  iaik.pkcs.pkcs11.Token
 *  iaik.pkcs.pkcs11.TokenException
 *  iaik.pkcs.pkcs11.TokenInfo
 *  org.slf4j.Logger
 *  org.slf4j.LoggerFactory
 */
package md.cts.pkcs11.cards;

import iaik.pkcs.pkcs11.Session;
import iaik.pkcs.pkcs11.Slot;
import iaik.pkcs.pkcs11.Token;
import iaik.pkcs.pkcs11.TokenException;
import iaik.pkcs.pkcs11.TokenInfo;
import java.util.HashMap;
import java.util.Map;
import md.cts.pkcs11.cards.exceptions.InvalidCardException;
import md.cts.pkcs11.cards.exceptions.InvalidPinException;
import md.cts.pkcs11.cards.exceptions.PinLockedException;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

public final class Card {
    private static final Logger logger = LoggerFactory.getLogger(Card.class);
    private static final Map<String, Boolean> exSem = new HashMap<String, Boolean>();
    private final Token token;
    private TokenInfo info = null;

    public Card(Token token) {
        this.token = token;
    }

    public boolean readTokenInfo() throws InvalidCardException {
        Slot slot = this.token.getSlot();
        try {
            this.info = this.token.getTokenInfo();
            return true;
        }
        catch (TokenException ex) {
            String k = slot.getSlotID() + "-" + slot.getModule().toString();
            if (!exSem.containsKey(k)) {
                exSem.put(k, true);
                logger.error("Exception on reading token info for slot:{} {}", (Object)slot.getSlotID(), (Object)slot.getModule().toString());
                logger.error("", (Throwable)ex);
            }
            return false;
        }
    }

    public String getCardVersion() {
        if (this.info != null) {
            return this.info.getHardwareVersion().toString().trim();
        }
        return "[No card present]";
    }

    public boolean isPinLocked() {
        logger.info("Check if PIN is locked {}", (Object)this.info.isUserPinLocked());
        return this.info.isUserPinLocked();
    }

    public boolean isPukLocked() {
        logger.info("Check if PUK is locked {}", (Object)this.info.isSoPinLocked());
        return this.info.isSoPinLocked();
    }

    public String getName() {
        if (this.info != null && this.info.getLabel() != null) {
            return this.info.getLabel().trim();
        }
        return "[No card present]";
    }

    public String getSerialNumber() {
        if (this.info != null) {
            return this.info.getSerialNumber().trim();
        }
        return "[No card present]";
    }

    public long getTotalPrivateMemory() throws InvalidCardException {
        if (this.info != null) {
            return this.info.getTotalPrivateMemory();
        }
        throw new InvalidCardException();
    }

    public long getFreePrivateMemory() throws InvalidCardException {
        if (this.info != null) {
            return this.info.getFreePrivateMemory();
        }
        throw new InvalidCardException();
    }

    public long getTotalPublicMemory() throws InvalidCardException {
        if (this.info != null) {
            return this.info.getTotalPublicMemory();
        }
        throw new InvalidCardException();
    }

    public long getFreePublicMemory() throws InvalidCardException {
        if (this.info != null) {
            return this.info.getFreePublicMemory();
        }
        throw new InvalidCardException();
    }

    public void changePin(char[] oldPin, char[] newPin) throws Exception {
        try {
            Session s = this.token.openSession(true, true, null, null);
            s.setPIN(oldPin, newPin);
            s.closeSession();
        }
        catch (TokenException ex) {
            switch (ex.getMessage()) {
                case "CKR_PIN_INCORRECT": {
                    throw new InvalidPinException(ex);
                }
                case "CKR_PIN_LOCKED": {
                    throw new PinLockedException(ex);
                }
                case "CKR_PIN_LEN_RANGE": {
                    throw new Exception(ex);
                }
            }
            logger.error("", (Throwable)ex);
        }
    }

    public void resetPin(char[] puk, char[] pin) throws Exception {
        try {
            this.token.closeAllSessions();
            Session s = this.token.openSession(true, true, null, null);
            s.login(false, puk);
            s.initPIN(pin);
            s.logout();
            s.closeSession();
        }
        catch (TokenException ex) {
            switch (ex.getMessage()) {
                case "CKR_PIN_INCORRECT": {
                    throw new InvalidPinException(ex);
                }
                case "CKR_PIN_LOCKED": {
                    throw new PinLockedException(ex);
                }
                case "CKR_PIN_LEN_RANGE": {
                    throw new Exception(ex);
                }
            }
            logger.error("", (Throwable)ex);
        }
    }
}

