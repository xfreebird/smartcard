/*
 * Decompiled with CFR 0.152.
 * 
 * Could not load the following classes:
 *  iaik.pkcs.pkcs11.Slot
 *  iaik.pkcs.pkcs11.SlotInfo
 *  iaik.pkcs.pkcs11.TokenException
 *  iaik.pkcs.pkcs11.provider.IAIKPkcs11
 *  org.slf4j.Logger
 *  org.slf4j.LoggerFactory
 */
package md.cts.pkcs11.cards;

import iaik.pkcs.pkcs11.Slot;
import iaik.pkcs.pkcs11.SlotInfo;
import iaik.pkcs.pkcs11.TokenException;
import iaik.pkcs.pkcs11.provider.IAIKPkcs11;
import java.security.Provider;
import java.security.Security;
import java.util.Properties;
import md.cts.pkcs11.cards.Card;
import md.cts.pkcs11.cards.exceptions.InvalidCardException;
import md.cts.pkcs11.cards.exceptions.OperationFailedException;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

public final class CardReader {
    private static final Logger logger = LoggerFactory.getLogger(CardReader.class);
    private final Slot slot;
    private final String strModuleId;
    private SlotInfo sInfo = null;
    private IAIKPkcs11 provider;
    private Card card = null;
    private Long slotGlobalId = null;

    public CardReader(Slot slot, String strModuleId) {
        this.slot = slot;
        this.strModuleId = strModuleId;
    }

    public Long getGlobalId() {
        return this.slotGlobalId;
    }

    public void setGlobalId(Long id) {
        this.slotGlobalId = id;
    }

    public String getId() {
        return this.strModuleId + "-" + this.slot.getSlotID();
    }

    private SlotInfo getSlotInfo() {
        if (this.sInfo == null) {
            try {
                this.sInfo = this.slot.getSlotInfo();
                System.out.println("-----Slot-----");
                System.out.println(this.slot);
                System.out.println("-----SlotInfo-----");
                System.out.println(this.sInfo);
                System.out.println("-----");
            }
            catch (TokenException ex) {
                logger.error("", (Throwable)ex);
            }
        }
        return this.sInfo;
    }

    public boolean checkCardPresent() {
        try {
            return this.isCardPresent();
        }
        catch (Exception ex) {
            logger.error("", (Throwable)ex);
            return false;
        }
    }

    private boolean isCardPresent() throws OperationFailedException {
        block8: {
            try {
                boolean cardPresent = this.slot.getSlotInfo().isTokenPresent();
                if (!cardPresent) {
                    return false;
                }
            }
            catch (TokenException ex) {
                if (ex.getMessage().equals("CKR_SLOT_ID_INVALID")) {
                    return false;
                }
                if (ex.getMessage().equals("CKR_CRYPTOKI_NOT_INITIALIZED")) break block8;
                throw new OperationFailedException(ex);
            }
        }
        if (this.card == null) {
            try {
                Card cardTemp = new Card(this.slot.getToken());
                if (!cardTemp.readTokenInfo()) {
                    return false;
                }
                this.card = cardTemp;
                logger.info("Card is readable");
            }
            catch (TokenException | InvalidCardException ex) {
                logger.error("The card cannot be read", ex);
            }
        }
        return this.card != null;
    }

    public IAIKPkcs11 getPkcsProvider() {
        if (this.provider == null) {
            Properties providerConfig = new Properties();
            providerConfig.setProperty("PKCS11_NATIVE_MODULE", this.strModuleId);
            providerConfig.setProperty("MULTI_THREAD_INIT", "true");
            providerConfig.setProperty("LOGIN_KEYSTORE_SESSION_ON_DEMAND", "false");
            providerConfig.setProperty("USE_UTF8_ENCODING", "true");
            providerConfig.setProperty("SESSION_POOL_MAX_SIZE", "10");
            providerConfig.setProperty("SLOT_ID", Long.toString(this.slot.getSlotID()));
            this.provider = new IAIKPkcs11(providerConfig);
            Security.addProvider((Provider)this.provider);
            logger.info("new IAIKPkcs11 provider added for {} slot:{}", (Object)this.strModuleId, (Object)this.slot.getSlotID());
        }
        return this.provider;
    }

    public String getName() {
        StringBuilder cardName = new StringBuilder();
        SlotInfo info = this.getSlotInfo();
        if (info != null) {
            cardName.append(info.getSlotDescription().trim());
            if (this.card != null) {
                cardName.append("(").append(this.card.getName()).append(")");
            }
        } else {
            cardName.append("[No name]");
        }
        return cardName.toString();
    }

    public Card getCard() {
        return this.card;
    }

    public boolean equals(Object obj) {
        if (obj == null) {
            return false;
        }
        if (this.getClass() != obj.getClass()) {
            return false;
        }
        CardReader other = (CardReader)obj;
        return this.slot != null && this.slot.getModule() != null && this.slot.equals((Object)other.slot) && this.slot.getModule().equals((Object)other.slot.getModule());
    }

    public int hashCode() {
        int hash = 7;
        hash = 47 * hash + this.slot.hashCode() + this.slot.getModule().hashCode();
        return hash;
    }
}

