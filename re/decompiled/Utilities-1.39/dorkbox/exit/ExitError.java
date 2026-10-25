/*
 * Decompiled with CFR 0.152.
 */
package dorkbox.exit;

import dorkbox.exit.ExitBase;

public final class ExitError
extends ExitBase {
    private static final long serialVersionUID = 4291020084877555138L;

    public ExitError(int exitCode) {
        super(exitCode);
    }

    public ExitError(int exitCode, String message) {
        super(exitCode, message);
    }

    public ExitError(int exitCode, String title, String message) {
        super(exitCode, title, message);
    }
}

