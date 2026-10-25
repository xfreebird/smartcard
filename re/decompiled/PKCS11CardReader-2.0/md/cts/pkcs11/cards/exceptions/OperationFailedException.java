/*
 * Decompiled with CFR 0.152.
 */
package md.cts.pkcs11.cards.exceptions;

public final class OperationFailedException
extends Exception {
    public OperationFailedException(Throwable cause) {
        super("exception.general.unknown_problem", cause);
    }

    public OperationFailedException(String msg, Throwable cause) {
        super(msg, cause);
    }
}

