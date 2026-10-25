/*
 * Decompiled with CFR 0.152.
 */
package md.cts.pkcs11.providers.pin_providers;

public final class NoMoreAttemptsException
extends Exception {
    public NoMoreAttemptsException() {
        super("No more attempts are allowed");
    }
}

