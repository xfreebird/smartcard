/*
 * Decompiled with CFR 0.152.
 */
package md.cts.pkcs11.cards.observers;

public final class CardReaderEvent {
    private final Action action;
    private final Long slotGlobalId;

    public CardReaderEvent(Long slotGlobalId, Action action) {
        this.action = action;
        this.slotGlobalId = slotGlobalId;
    }

    public Action getAction() {
        return this.action;
    }

    public Long getSlotGlobalId() {
        return this.slotGlobalId;
    }

    public static enum Action {
        REMOVED,
        INSERTED;

    }
}

