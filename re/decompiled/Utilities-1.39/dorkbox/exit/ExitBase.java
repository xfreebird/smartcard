/*
 * Decompiled with CFR 0.152.
 */
package dorkbox.exit;

import java.io.IOException;
import java.io.NotSerializableException;
import java.io.ObjectInputStream;
import java.io.ObjectOutputStream;

class ExitBase
extends Error {
    private static final long serialVersionUID = 546657685093303326L;
    private final String message;
    private final int exitCode;
    private final String title;

    ExitBase(int exitCode) {
        this(exitCode, null, null);
    }

    ExitBase(int exitCode, String message) {
        this(exitCode, null, message);
    }

    ExitBase(int exitCode, String title, String message) {
        this.exitCode = exitCode;
        this.title = title;
        this.message = message;
    }

    public final String getTitle() {
        return this.title;
    }

    @Override
    public final String getMessage() {
        return this.message;
    }

    public final int getExitCode() {
        return this.exitCode;
    }

    public final Object clone() throws CloneNotSupportedException {
        throw new CloneNotSupportedException();
    }

    public final void writeObject(ObjectOutputStream out) throws IOException {
        throw new NotSerializableException();
    }

    public final void readObject(ObjectInputStream in) throws IOException {
        throw new NotSerializableException();
    }
}

