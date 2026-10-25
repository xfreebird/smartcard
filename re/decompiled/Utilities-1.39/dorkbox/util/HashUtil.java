/*
 * Decompiled with CFR 0.152.
 * 
 * Could not load the following classes:
 *  org.bouncycastle.crypto.digests.SHA256Digest
 */
package dorkbox.util;

import dorkbox.util.Sys;
import org.bouncycastle.crypto.digests.SHA256Digest;

public class HashUtil {
    public static byte[] getSha256WithSalt(String username, byte[] saltBytes) {
        if (username == null) {
            return null;
        }
        byte[] charToBytes = Sys.charToBytes16(username.toCharArray());
        byte[] userNameWithSalt = Sys.concatBytes(charToBytes, saltBytes);
        SHA256Digest sha256 = new SHA256Digest();
        byte[] usernameHashBytes = new byte[sha256.getDigestSize()];
        sha256.update(userNameWithSalt, 0, userNameWithSalt.length);
        sha256.doFinal(usernameHashBytes, 0);
        return usernameHashBytes;
    }

    public static byte[] getSha256(String string) {
        byte[] charToBytes = Sys.charToBytes16(string.toCharArray());
        SHA256Digest sha256 = new SHA256Digest();
        byte[] usernameHashBytes = new byte[sha256.getDigestSize()];
        sha256.update(charToBytes, 0, charToBytes.length);
        sha256.doFinal(usernameHashBytes, 0);
        return usernameHashBytes;
    }

    public static byte[] getSha256(byte[] bytes) {
        SHA256Digest sha256 = new SHA256Digest();
        byte[] hashBytes = new byte[sha256.getDigestSize()];
        sha256.update(bytes, 0, bytes.length);
        sha256.doFinal(hashBytes, 0);
        return hashBytes;
    }

    public static byte[] getSha256WithSalt(byte[] bytes, byte[] saltBytes) {
        if (bytes == null || saltBytes == null) {
            return null;
        }
        byte[] bytesWithSalt = Sys.concatBytes(bytes, saltBytes);
        SHA256Digest sha256 = new SHA256Digest();
        byte[] usernameHashBytes = new byte[sha256.getDigestSize()];
        sha256.update(bytesWithSalt, 0, bytesWithSalt.length);
        sha256.doFinal(usernameHashBytes, 0);
        return usernameHashBytes;
    }
}

