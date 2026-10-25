/*
 * Decompiled with CFR 0.152.
 */
package md.cts.pkcs11.cards.exceptions;

public final class SessionInitializationException
extends Exception {
    public SessionInitializationException(Throwable cause) {
        super("Session cannot be initialized", cause);
    }

    public SessionInitializationException(String msg, Throwable cause) {
        super(msg);
    }
}

