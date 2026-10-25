/*
 * Decompiled with CFR 0.152.
 */
package md.cts.pkcs11.cards.exceptions;

public final class PinLockedException
extends Exception {
    public PinLockedException() {
    }

    public PinLockedException(String msg) {
        super(msg);
    }

    public PinLockedException(String message, Throwable cause) {
        super(message, cause);
    }

    public PinLockedException(Throwable cause) {
        super(cause);
    }
}

