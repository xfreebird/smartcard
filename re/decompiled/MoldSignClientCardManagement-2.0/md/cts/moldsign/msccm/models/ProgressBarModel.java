/*
 * Decompiled with CFR 0.152.
 */
package md.cts.moldsign.msccm.models;

public class ProgressBarModel {
    private String message;
    private int messageType;

    public ProgressBarModel() {
    }

    public ProgressBarModel(String message, int messageType) {
        this.message = message;
        this.messageType = messageType;
    }

    public String getMessage() {
        return this.message;
    }

    public void setMessage(String message) {
        this.message = message;
    }

    public int getMessageType() {
        return this.messageType;
    }

    public void setMessageType(int messageType) {
        this.messageType = messageType;
    }
}

