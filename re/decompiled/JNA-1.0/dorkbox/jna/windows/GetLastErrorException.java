/*
 * Decompiled with CFR 0.152.
 * 
 * Could not load the following classes:
 *  com.sun.jna.platform.win32.Kernel32Util
 */
package dorkbox.jna.windows;

import com.sun.jna.platform.win32.Kernel32Util;

public class GetLastErrorException
extends RuntimeException {
    private static final long serialVersionUID = 3980497906900380359L;
    private String message = Kernel32Util.getLastErrorMessage();

    @Override
    public String toString() {
        return this.message;
    }
}

