/*
 * Decompiled with CFR 0.152.
 */
package cargo;

public final class Rust {
    private static final char[] HEX_ARRAY = new char[]{'0', '1', '2', '3', '4', '5', '6', '7', '8', '9', 'A', 'B', 'C', 'D', 'E', 'F'};

    private Rust() {
        throw new AssertionError((Object)"Cannot instantiate Rust utility class");
    }

    public static String bytesToHex(byte[] bytes) {
        if (bytes == null) {
            throw new IllegalArgumentException("Input cannot be null");
        }
        char[] hexChars = new char[bytes.length << 1];
        for (int j = 0; j < bytes.length; ++j) {
            int v = bytes[j] & 0xFF;
            hexChars[j << 1] = HEX_ARRAY[v >>> 4];
            hexChars[(j << 1) + 1] = HEX_ARRAY[v & 0xF];
        }
        return new String(hexChars);
    }

    public static byte[] hexToBytes(String str) {
        if (str == null) {
            throw new IllegalArgumentException("Input cannot be null");
        }
        if ((str.length() & 1) != 0) {
            throw new IllegalArgumentException("Hex string must have an even length");
        }
        int len = str.length() >>> 1;
        byte[] buf = new byte[len];
        for (int j = 0; j < len; ++j) {
            int hi = Rust.hexToBin(str.charAt(j << 1));
            int lo = Rust.hexToBin(str.charAt((j << 1) + 1));
            if (hi < 0 || lo < 0) {
                throw new IllegalArgumentException("Illegal character for hex");
            }
            buf[j] = (byte)(hi << 4 | lo);
        }
        return buf;
    }

    private static int hexToBin(char ch) {
        if ('0' <= ch && ch <= '9') {
            return ch - 48;
        }
        if ('A' <= ch && ch <= 'F') {
            return ch - 65 + 10;
        }
        if ('a' <= ch && ch <= 'f') {
            return ch - 97 + 10;
        }
        return -1;
    }

    public static byte[] concatenateByteArrays(byte[] ... arrays) {
        int len = 0;
        for (byte[] arr : arrays) {
            len += arr.length;
        }
        byte[] result = new byte[len];
        int pos = 0;
        for (byte[] arr : arrays) {
            System.arraycopy(arr, 0, result, pos, arr.length);
            pos += arr.length;
        }
        return result;
    }
}

