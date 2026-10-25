/*
 * Decompiled with CFR 0.152.
 */
package md.cts.pkcs11.cards.exceptions;

public final class InvalidCardException
extends Exception {
    public InvalidCardException() {
        super("Cannot read card");
    }

    public InvalidCardException(String msg) {
        super(msg);
    }

    public InvalidCardException(String message, Throwable cause) {
        super(message, cause);
    }
}

