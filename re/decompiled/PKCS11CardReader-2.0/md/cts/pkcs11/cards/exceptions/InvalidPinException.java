/*
 * Decompiled with CFR 0.152.
 */
package md.cts.pkcs11.cards.exceptions;

public final class InvalidPinException
extends Exception {
    public InvalidPinException() {
        super("The provided PIN is invalid!");
    }

    public InvalidPinException(String msg) {
        super(msg);
    }

    public InvalidPinException(Throwable cause) {
        this();
        this.initCause(cause);
    }
}

