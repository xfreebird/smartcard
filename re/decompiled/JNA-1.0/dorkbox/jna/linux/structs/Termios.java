/*
 * Decompiled with CFR 0.152.
 * 
 * Could not load the following classes:
 *  com.sun.jna.Structure
 */
package dorkbox.jna.linux.structs;

import com.sun.jna.Structure;
import java.util.Arrays;
import java.util.List;

public class Termios
extends Structure {
    public static final int TCSANOW = 0;
    public int inputFlags;
    public int outputFlags;
    public int controlFlags;
    public int localFlags;
    public char lineDiscipline;
    public byte[] controlChars = new byte[32];
    public int inputSpeed;
    public int outputSpeed;

    protected List<String> getFieldOrder() {
        return Arrays.asList("inputFlags", "outputFlags", "controlFlags", "localFlags", "lineDiscipline", "controlChars", "inputSpeed", "outputSpeed");
    }

    public static class ControlChars {
        public static final int VINTR = 0;
        public static final int VQUIT = 1;
        public static final int VERASE = 2;
        public static final int VKILL = 3;
        public static final int VEOF = 4;
        public static final int VTIME = 5;
        public static final int VMIN = 6;
        public static final int VSWTC = 7;
        public static final int VSTART = 8;
        public static final int VSTOP = 9;
        public static final int VSUSP = 10;
        public static final int VEOL = 11;
        public static final int VREPRINT = 12;
        public static final int VDISCARD = 13;
        public static final int VWERASE = 14;
        public static final int VLNEXT = 15;
        public static final int VEOL2 = 16;
    }

    public static class Local {
        public static final int ISIG = 1;
        public static final int ICANON = 2;
        public static final int ECHO = 8;
        public static final int ECHOE = 16;
        public static final int ECHOK = 32;
        public static final int ECHONL = 64;
        public static final int NOFLSH = 128;
        public static final int TOSTOP = 256;
        public static final int ECHOCTL = 512;
        public static final int ECHOPRT = 1024;
        public static final int ECHOKE = 2048;
        public static final int FLUSHO = 512;
        public static final int PENDIN = 2048;
        public static final int IEXTEN = 32768;
        public static final int EXTPROC = 65536;
    }

    public static class Control {
        public static final int CSIZE = 48;
        public static final int CS5 = 0;
        public static final int CS6 = 16;
        public static final int CS7 = 32;
        public static final int CS8 = 48;
        public static final int CSTOPB = 64;
        public static final int CREAD = 128;
        public static final int PARENB = 256;
        public static final int PARODD = 512;
        public static final int HUPCL = 1024;
        public static final int CLOCAL = 2048;
    }

    public static class Output {
        public static final int OPOST = 1;
        public static final int ONLCR = 4;
        public static final int OCRNL = 8;
        public static final int ONOCR = 16;
        public static final int ONLRET = 32;
        public static final int OFILL = 64;
        public static final int OFDEL = 128;
    }

    public static class Input {
        public static final int IGNBRK = 1;
        public static final int BRKINT = 2;
        public static final int IGNPAR = 4;
        public static final int PARMRK = 8;
        public static final int INPCK = 16;
        public static final int ISTRIP = 32;
        public static final int INLCR = 64;
        public static final int IGNCR = 128;
        public static final int ICRNL = 256;
        public static final int IXON = 1024;
        public static final int IXANY = 2048;
        public static final int IXOFF = 4096;
        public static final int IMAXBEL = 8192;
    }
}

