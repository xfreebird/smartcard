/*
 * Decompiled with CFR 0.152.
 */
package md.cts.moldsign.clientcardmanager.models;

public class ProgressBarModel {
    private final String message;
    private final int messageType;

    public ProgressBarModel(String message, int messageType) {
        this.message = message;
        this.messageType = messageType;
    }

    public String getMessage() {
        return this.message;
    }

    public int getMessageType() {
        return this.messageType;
    }
}

