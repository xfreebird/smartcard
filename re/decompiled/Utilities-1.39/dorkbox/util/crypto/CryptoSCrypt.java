/*
 * Decompiled with CFR 0.152.
 * 
 * Could not load the following classes:
 *  org.bouncycastle.crypto.generators.SCrypt
 */
package dorkbox.util.crypto;

import dorkbox.util.crypto.Crypto;
import java.security.SecureRandom;
import java.util.Arrays;
import java.util.Base64;
import org.bouncycastle.crypto.generators.SCrypt;

public final class CryptoSCrypt {
    public static String encrypt(char[] password) {
        return CryptoSCrypt.encrypt(password, 16384, 32, 1);
    }

    public static String encrypt(char[] password, byte[] salt) {
        return CryptoSCrypt.encrypt(password, salt, 16384, 128, 1, 64);
    }

    public static String encrypt(char[] password, int N, int r, int p) {
        SecureRandom secureRandom = new SecureRandom();
        byte[] salt = new byte[32];
        secureRandom.nextBytes(salt);
        return CryptoSCrypt.encrypt(password, salt, N, r, p, 64);
    }

    public static String encrypt(char[] password, byte[] salt, int N, int r, int p, int dkLen) {
        byte[] passwordBytes = Crypto.charToBytesPassword_UTF16(password);
        byte[] derived = CryptoSCrypt.encrypt(passwordBytes, salt, N, r, p, dkLen);
        String params = Integer.toString(CryptoSCrypt.log2(N) << 16 | r << 8 | p, 16);
        StringBuilder sb = new StringBuilder((salt.length + derived.length) * 2);
        sb.append("$s0$").append(params).append('$');
        sb.append(Base64.getEncoder().encodeToString(salt)).append('$');
        sb.append(Base64.getEncoder().encodeToString(derived));
        return sb.toString();
    }

    public static boolean verify(char[] password, String hashed) {
        byte[] passwordBytes = Crypto.charToBytesPassword_UTF16(password);
        String[] parts = hashed.split("\\$");
        if (parts.length != 5 || !parts[1].equals("s0")) {
            throw new IllegalArgumentException("Invalid hashed value");
        }
        int params = Integer.parseInt(parts[2], 16);
        byte[] salt = Base64.getDecoder().decode(parts[3]);
        byte[] derived0 = Base64.getDecoder().decode(parts[4]);
        int N = (int)Math.pow(2.0, params >> 16 & 0xFF);
        int r = params >> 8 & 0xFF;
        int p = params & 0xFF;
        int length = derived0.length;
        if (length == 0) {
            return false;
        }
        byte[] derived1 = CryptoSCrypt.encrypt(passwordBytes, salt, N, r, p, length);
        if (length != derived1.length) {
            return false;
        }
        int result = 0;
        for (int i = 0; i < length; ++i) {
            result |= derived0[i] ^ derived1[i];
        }
        return result == 0;
    }

    private static int log2(int n) {
        int log = 0;
        if ((n & 0xFFFF0000) != 0) {
            n >>>= 16;
            log = 16;
        }
        if (n >= 256) {
            n >>>= 8;
            log += 8;
        }
        if (n >= 16) {
            n >>>= 4;
            log += 4;
        }
        if (n >= 4) {
            n >>>= 2;
            log += 2;
        }
        return log + (n >>> 1);
    }

    /*
     * WARNING - Removed try catching itself - possible behaviour change.
     */
    public static byte[] encrypt(byte[] password, byte[] salt, int N, int r, int p, int dkLen) {
        if (N == 0 || (N & N - 1) != 0) {
            throw new IllegalArgumentException("N must be > 0 and a power of 2");
        }
        if (N > 0xFFFFFF / r) {
            throw new IllegalArgumentException("Parameter N is too large");
        }
        if (r > 0xFFFFFF / p) {
            throw new IllegalArgumentException("Parameter r is too large");
        }
        try {
            byte[] byArray = SCrypt.generate((byte[])password, (byte[])salt, (int)N, (int)r, (int)p, (int)dkLen);
            return byArray;
        }
        finally {
            Arrays.fill(password, (byte)0);
        }
    }

    private CryptoSCrypt() {
    }
}

