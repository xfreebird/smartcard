/*
 * Decompiled with CFR 0.152.
 * 
 * Could not load the following classes:
 *  kotlin.Metadata
 *  kotlin.collections.ArraysKt
 *  kotlin.jvm.internal.Intrinsics
 *  kotlin.text.Charsets
 *  org.jetbrains.annotations.NotNull
 */
package dorkbox.util.crypto;

import java.security.InvalidAlgorithmParameterException;
import java.security.InvalidKeyException;
import java.security.Key;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.security.spec.InvalidKeySpecException;
import javax.crypto.Cipher;
import javax.crypto.NoSuchPaddingException;
import javax.crypto.spec.IvParameterSpec;
import javax.crypto.spec.SecretKeySpec;
import kotlin.Metadata;
import kotlin.collections.ArraysKt;
import kotlin.jvm.internal.Intrinsics;
import kotlin.text.Charsets;
import org.jetbrains.annotations.NotNull;

@Metadata(mv={1, 7, 1}, k=1, xi=48, d1={"\u00006\n\u0002\u0018\u0002\n\u0002\u0010\u0000\n\u0002\b\u0002\n\u0002\u0010\u000e\n\u0000\n\u0002\u0010\u0012\n\u0002\b\u0003\n\u0002\u0010\b\n\u0000\n\u0002\u0018\u0002\n\u0002\b\u0005\n\u0002\u0018\u0002\n\u0002\b\u0005\n\u0002\u0010\u0019\n\u0000\b\u00c0\u0002\u0018\u00002\u00020\u0001B\u0007\b\u0002\u00a2\u0006\u0002\u0010\u0002J\u0018\u0010\u000e\u001a\u00020\u00062\u0006\u0010\u000f\u001a\u00020\u00062\u0006\u0010\u0010\u001a\u00020\u0006H\u0002J\u001e\u0010\u0011\u001a\u00020\u00122\u0006\u0010\u0013\u001a\u00020\u00042\u0006\u0010\u0014\u001a\u00020\u00062\u0006\u0010\u0015\u001a\u00020\nJ\u000e\u0010\u0016\u001a\u00020\u00062\u0006\u0010\u0017\u001a\u00020\u0018R\u000e\u0010\u0003\u001a\u00020\u0004X\u0086T\u00a2\u0006\u0002\n\u0000R\u0011\u0010\u0005\u001a\u00020\u0006\u00a2\u0006\b\n\u0000\u001a\u0004\b\u0007\u0010\bR\u000e\u0010\t\u001a\u00020\nX\u0086T\u00a2\u0006\u0002\n\u0000R\u0016\u0010\u000b\u001a\n \r*\u0004\u0018\u00010\f0\fX\u0082\u0004\u00a2\u0006\u0002\n\u0000\u00a8\u0006\u0019"}, d2={"Ldorkbox/util/crypto/OpenSSLPBECommon;", "", "()V", "OPENSSL_HEADER_STRING", "", "OPENSSL_HEADER_STRING_BYTES", "", "getOPENSSL_HEADER_STRING_BYTES", "()[B", "SALT_SIZE_BYTES", "", "hashDigest", "Ljava/security/MessageDigest;", "kotlin.jvm.PlatformType", "concat", "a", "b", "initializeCipher", "Ljavax/crypto/Cipher;", "password", "salt", "cipherMode", "toByteArray", "chars", "", "Utilities"})
public final class OpenSSLPBECommon {
    @NotNull
    public static final OpenSSLPBECommon INSTANCE = new OpenSSLPBECommon();
    public static final int SALT_SIZE_BYTES = 8;
    @NotNull
    public static final String OPENSSL_HEADER_STRING = "Salted__";
    @NotNull
    private static final byte[] OPENSSL_HEADER_STRING_BYTES;
    private static final MessageDigest hashDigest;

    private OpenSSLPBECommon() {
    }

    @NotNull
    public final byte[] getOPENSSL_HEADER_STRING_BYTES() {
        return OPENSSL_HEADER_STRING_BYTES;
    }

    @NotNull
    public final byte[] toByteArray(@NotNull char[] chars) {
        Intrinsics.checkNotNullParameter((Object)chars, (String)"chars");
        byte[] bytes = new byte[chars.length];
        int n = bytes.length;
        for (int i = 0; i < n; ++i) {
            bytes[i] = (byte)chars[i];
        }
        return bytes;
    }

    @NotNull
    public final Cipher initializeCipher(@NotNull String password, @NotNull byte[] salt, int cipherMode) throws NoSuchAlgorithmException, InvalidKeySpecException, InvalidKeyException, NoSuchPaddingException, InvalidAlgorithmParameterException {
        Intrinsics.checkNotNullParameter((Object)password, (String)"password");
        Intrinsics.checkNotNullParameter((Object)salt, (String)"salt");
        byte[] byArray = password.getBytes(Charsets.US_ASCII);
        Intrinsics.checkNotNullExpressionValue((Object)byArray, (String)"this as java.lang.String).getBytes(charset)");
        byte[] passwordBytes = byArray;
        hashDigest.update(passwordBytes);
        hashDigest.update(salt);
        byte[] hash = hashDigest.digest();
        byte[] keyAndIV = (byte[])hash.clone();
        hashDigest.update(hash);
        hashDigest.update(passwordBytes);
        hashDigest.update(salt);
        hash = hashDigest.digest();
        Intrinsics.checkNotNullExpressionValue((Object)hash, (String)"hash");
        byte[] byArray2 = keyAndIV = this.concat(keyAndIV, hash);
        int n = 0;
        int n2 = 32;
        byte[] keyBytes = ArraysKt.copyOfRange((byte[])byArray2, (int)n, (int)n2);
        byte[] byArray3 = keyAndIV;
        n2 = 32;
        int n3 = 48;
        byte[] ivBytes = ArraysKt.copyOfRange((byte[])byArray3, (int)n2, (int)n3);
        SecretKeySpec key = new SecretKeySpec(keyBytes, "AES");
        IvParameterSpec iv = new IvParameterSpec(ivBytes);
        Cipher cipher = Cipher.getInstance("AES/CBC/PKCS5PADDING");
        cipher.init(cipherMode, (Key)key, iv);
        Intrinsics.checkNotNullExpressionValue((Object)cipher, (String)"cipher");
        return cipher;
    }

    private final byte[] concat(byte[] a, byte[] b) {
        byte[] c = new byte[a.length + b.length];
        System.arraycopy(a, 0, c, 0, a.length);
        System.arraycopy(b, 0, c, a.length, b.length);
        return c;
    }

    static {
        byte[] byArray = OPENSSL_HEADER_STRING.getBytes(Charsets.US_ASCII);
        Intrinsics.checkNotNullExpressionValue((Object)byArray, (String)"this as java.lang.String).getBytes(charset)");
        OPENSSL_HEADER_STRING_BYTES = byArray;
        hashDigest = MessageDigest.getInstance("SHA-256");
    }
}

