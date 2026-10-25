/*
 * Decompiled with CFR 0.152.
 * 
 * Could not load the following classes:
 *  kotlin.Metadata
 *  kotlin.io.FilesKt
 *  kotlin.jvm.JvmStatic
 *  kotlin.jvm.internal.Intrinsics
 *  kotlin.text.Charsets
 *  org.jetbrains.annotations.NotNull
 *  org.jetbrains.annotations.Nullable
 */
package dorkbox.util.crypto;

import java.io.File;
import java.io.IOException;
import java.nio.file.Files;
import java.security.GeneralSecurityException;
import java.security.Key;
import java.security.MessageDigest;
import java.security.SecureRandom;
import java.util.Arrays;
import javax.crypto.BadPaddingException;
import javax.crypto.Cipher;
import javax.crypto.IllegalBlockSizeException;
import javax.crypto.spec.IvParameterSpec;
import javax.crypto.spec.SecretKeySpec;
import kotlin.Metadata;
import kotlin.io.FilesKt;
import kotlin.jvm.JvmStatic;
import kotlin.jvm.internal.Intrinsics;
import kotlin.text.Charsets;
import org.jetbrains.annotations.NotNull;
import org.jetbrains.annotations.Nullable;

@Metadata(mv={1, 7, 1}, k=1, xi=48, d1={"\u00006\n\u0002\u0018\u0002\n\u0002\u0010\u0000\n\u0002\b\u0002\n\u0002\u0010\b\n\u0002\b\t\n\u0002\u0010\u0011\n\u0002\u0010\u0012\n\u0002\b\u0003\n\u0002\u0018\u0002\n\u0002\b\b\n\u0002\u0010\u0002\n\u0000\n\u0002\u0010\u000e\n\u0002\b\u0002\b\u00c6\u0002\u0018\u00002\u00020\u0001B\u0007\b\u0002\u00a2\u0006\u0002\u0010\u0002JE\u0010\r\u001a\b\u0012\u0004\u0012\u00020\u000f0\u000e2\u0006\u0010\u0010\u001a\u00020\u00042\u0006\u0010\u0011\u001a\u00020\u00042\u0006\u0010\u0012\u001a\u00020\u00132\b\u0010\u0014\u001a\u0004\u0018\u00010\u000f2\b\u0010\u0015\u001a\u0004\u0018\u00010\u000f2\u0006\u0010\u0016\u001a\u00020\u0004\u00a2\u0006\u0002\u0010\u0017J\u0016\u0010\u0018\u001a\u00020\u000f2\u0006\u0010\u0019\u001a\u00020\u000f2\u0006\u0010\u001a\u001a\u00020\u000fJ\u001b\u0010\u001b\u001a\u00020\u001c2\f\u0010\u001d\u001a\b\u0012\u0004\u0012\u00020\u001e0\u000eH\u0007\u00a2\u0006\u0002\u0010\u001fR\u000e\u0010\u0003\u001a\u00020\u0004X\u0082D\u00a2\u0006\u0002\n\u0000R\u000e\u0010\u0005\u001a\u00020\u0004X\u0082D\u00a2\u0006\u0002\n\u0000R\u000e\u0010\u0006\u001a\u00020\u0004X\u0082D\u00a2\u0006\u0002\n\u0000R\u000e\u0010\u0007\u001a\u00020\u0004X\u0082D\u00a2\u0006\u0002\n\u0000R\u000e\u0010\b\u001a\u00020\u0004X\u0082D\u00a2\u0006\u0002\n\u0000R\u000e\u0010\t\u001a\u00020\u0004X\u0082D\u00a2\u0006\u0002\n\u0000R\u000e\u0010\n\u001a\u00020\u0004X\u0082D\u00a2\u0006\u0002\n\u0000R\u000e\u0010\u000b\u001a\u00020\u0004X\u0082D\u00a2\u0006\u0002\n\u0000R\u000e\u0010\f\u001a\u00020\u0004X\u0082D\u00a2\u0006\u0002\n\u0000\u00a8\u0006 "}, d2={"Ldorkbox/util/crypto/OpenSSLDecryptor;", "", "()V", "ARG_INDEX_FILENAME", "", "ARG_INDEX_PASSWORD", "CIPHERTEXT_OFFSET", "INDEX_IV", "INDEX_KEY", "ITERATIONS", "KEY_SIZE_BITS", "SALT_OFFSET", "SALT_SIZE", "EVP_BytesToKey", "", "", "key_len", "iv_len", "md", "Ljava/security/MessageDigest;", "salt", "data", "count", "(IILjava/security/MessageDigest;[B[BI)[[B", "concat", "a", "b", "main", "", "args", "", "([Ljava/lang/String;)V", "Utilities"})
public final class OpenSSLDecryptor {
    @NotNull
    public static final OpenSSLDecryptor INSTANCE = new OpenSSLDecryptor();
    private static final int INDEX_KEY;
    private static final int INDEX_IV;
    private static final int ITERATIONS;
    private static final int ARG_INDEX_FILENAME;
    private static final int ARG_INDEX_PASSWORD;
    private static final int SALT_OFFSET;
    private static final int SALT_SIZE;
    private static final int CIPHERTEXT_OFFSET;
    private static final int KEY_SIZE_BITS;

    private OpenSSLDecryptor() {
    }

    @NotNull
    public final byte[][] EVP_BytesToKey(int key_len, int iv_len, @NotNull MessageDigest md, @Nullable byte[] salt, @Nullable byte[] data, int count) {
        Intrinsics.checkNotNullParameter((Object)md, (String)"md");
        byte[] key = new byte[key_len];
        int key_ix = 0;
        byte[] iv = new byte[iv_len];
        int iv_ix = 0;
        byte[][] byArrayArray = new byte[][]{key, iv};
        byte[][] both = byArrayArray;
        if (data == null) {
            return both;
        }
        byte[] md_buf = null;
        int nkey = key_len;
        int niv = iv_len;
        int i = 0;
        int addmd = 0;
        do {
            md.reset();
            if (addmd++ > 0) {
                Intrinsics.checkNotNull(md_buf);
                md.update(md_buf);
            }
            md.update(data);
            if (salt != null) {
                md.update(salt, 0, 8);
            }
            md_buf = md.digest();
            for (i = 1; i < count; ++i) {
                md.reset();
                Intrinsics.checkNotNull((Object)md_buf);
                md.update(md_buf);
                md_buf = md.digest();
            }
            i = 0;
            if (nkey > 0) {
                while (nkey != 0) {
                    Intrinsics.checkNotNull((Object)md_buf);
                    if (i == md_buf.length) break;
                    key[key_ix++] = md_buf[i];
                    --nkey;
                    ++i;
                }
            }
            if (niv <= 0) continue;
            Intrinsics.checkNotNull((Object)md_buf);
            if (i == md_buf.length) continue;
            while (niv != 0 && i != md_buf.length) {
                iv[iv_ix++] = md_buf[i];
                --niv;
                ++i;
            }
        } while (nkey != 0 || niv != 0);
        i = 0;
        while (true) {
            Intrinsics.checkNotNull((Object)md_buf);
            if (i >= md_buf.length) break;
            md_buf[i] = 0;
            ++i;
        }
        return both;
    }

    @JvmStatic
    public static final void main(@NotNull String[] args) {
        Intrinsics.checkNotNullParameter((Object)args, (String)"args");
        boolean decrypt = false;
        try {
            String password = "xyfjWNl6yPIZfRYLu64L2sleiF8vD5xgHsJ3sa3Ya6sY01";
            byte[] byArray = password.getBytes(Charsets.US_ASCII);
            Intrinsics.checkNotNullExpressionValue((Object)byArray, (String)"this as java.lang.String).getBytes(charset)");
            byte[] passwordBytes = byArray;
            String plaintextFileName = "password.txt";
            String encryptedFileName = "password.txt.enc";
            File plainTextFile = new File(plaintextFileName).getAbsoluteFile();
            Intrinsics.checkNotNullExpressionValue((Object)plainTextFile, (String)"plainTextFile");
            byte[] data = FilesKt.readBytes((File)plainTextFile);
            byte[] salt = new byte[8];
            SecureRandom secureRandom = new SecureRandom();
            secureRandom.nextBytes(salt);
            Cipher aesCBC = Cipher.getInstance("AES/CBC/PKCS5Padding");
            MessageDigest md = MessageDigest.getInstance("SHA-256");
            md.update(passwordBytes);
            md.update(salt);
            byte[] hash = md.digest();
            byte[] keyAndIV = (byte[])hash.clone();
            md.update(hash);
            md.update(passwordBytes);
            md.update(salt);
            hash = md.digest();
            Intrinsics.checkNotNullExpressionValue((Object)hash, (String)"hash");
            keyAndIV = INSTANCE.concat(keyAndIV, hash);
            byte[] keyBytes = Arrays.copyOfRange(keyAndIV, 0, 32);
            byte[] ivBytes = Arrays.copyOfRange(keyAndIV, 32, 48);
            SecretKeySpec key = new SecretKeySpec(keyBytes, "AES");
            IvParameterSpec iv = new IvParameterSpec(ivBytes);
            aesCBC.init(1, (Key)key, iv);
            byte[] encrypted = aesCBC.doFinal(data);
            byte[] byArray2 = "Salted__".getBytes(Charsets.US_ASCII);
            Intrinsics.checkNotNullExpressionValue((Object)byArray2, (String)"this as java.lang.String).getBytes(charset)");
            byte[] a1 = byArray2;
            byte[] byArray3 = INSTANCE.concat(a1, salt);
            Intrinsics.checkNotNullExpressionValue((Object)encrypted, (String)"encrypted");
            byte[] finalEncrypted = INSTANCE.concat(byArray3, encrypted);
            File encryptedFile = new File(encryptedFileName).getAbsoluteFile();
            Files.deleteIfExists(encryptedFile.toPath());
            Intrinsics.checkNotNullExpressionValue((Object)encryptedFile, (String)"encryptedFile");
            FilesKt.writeBytes((File)encryptedFile, (byte[])finalEncrypted);
        }
        catch (BadPaddingException e) {
            throw new IllegalStateException("Bad password, algorithm, mode or padding; no salt, wrong number of iterations or corrupted ciphertext.");
        }
        catch (IllegalBlockSizeException e) {
            throw new IllegalStateException("Bad algorithm, mode or corrupted (resized) ciphertext.");
        }
        catch (GeneralSecurityException e) {
            throw new IllegalStateException(e);
        }
        catch (IOException e) {
            throw new IllegalStateException(e);
        }
    }

    @NotNull
    public final byte[] concat(@NotNull byte[] a, @NotNull byte[] b) {
        Intrinsics.checkNotNullParameter((Object)a, (String)"a");
        Intrinsics.checkNotNullParameter((Object)b, (String)"b");
        byte[] c = new byte[a.length + b.length];
        System.arraycopy(a, 0, c, 0, a.length);
        System.arraycopy(b, 0, c, a.length, b.length);
        return c;
    }

    static {
        INDEX_IV = 1;
        ITERATIONS = 1;
        ARG_INDEX_PASSWORD = 1;
        SALT_OFFSET = 8;
        SALT_SIZE = 8;
        CIPHERTEXT_OFFSET = SALT_OFFSET + SALT_SIZE;
        KEY_SIZE_BITS = 256;
    }
}

