/*
 * Decompiled with CFR 0.152.
 */
package cargo;

public interface DartCallback {
    public void run(Code var1);

    public static enum Code {
        OK,
        LOCAL_ERROR,
        REMOTE_ERROR;

    }
}

