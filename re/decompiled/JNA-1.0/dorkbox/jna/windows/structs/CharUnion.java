/*
 * Decompiled with CFR 0.152.
 * 
 * Could not load the following classes:
 *  com.sun.jna.Union
 */
package dorkbox.jna.windows.structs;

import com.sun.jna.Union;

public class CharUnion
extends Union {
    public char unicodeChar;
    public byte asciiChar;

    public CharUnion() {
    }

    public CharUnion(char c) {
        this.setType(Character.TYPE);
        this.unicodeChar = c;
    }

    public CharUnion(byte c) {
        this.setType(Byte.TYPE);
        this.asciiChar = c;
    }

    public void set(char c) {
        this.setType(Character.TYPE);
        this.unicodeChar = c;
    }

    public void set(byte c) {
        this.setType(Byte.TYPE);
        this.asciiChar = c;
    }
}

