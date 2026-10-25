/*
 * Decompiled with CFR 0.152.
 * 
 * Could not load the following classes:
 *  kotlin.Metadata
 *  kotlin.jvm.internal.DefaultConstructorMarker
 *  kotlin.jvm.internal.Intrinsics
 *  kotlin.text.Charsets
 *  org.jetbrains.annotations.NotNull
 *  org.jetbrains.annotations.Nullable
 */
package dorkbox.util.crypto;

import dorkbox.util.crypto.OpenSSLPBECommon;
import java.io.IOException;
import java.io.InputStream;
import java.security.InvalidAlgorithmParameterException;
import java.security.InvalidKeyException;
import java.security.NoSuchAlgorithmException;
import java.security.spec.InvalidKeySpecException;
import javax.crypto.BadPaddingException;
import javax.crypto.Cipher;
import javax.crypto.IllegalBlockSizeException;
import javax.crypto.NoSuchPaddingException;
import kotlin.Metadata;
import kotlin.jvm.internal.DefaultConstructorMarker;
import kotlin.jvm.internal.Intrinsics;
import kotlin.text.Charsets;
import org.jetbrains.annotations.NotNull;
import org.jetbrains.annotations.Nullable;

@Metadata(mv={1, 7, 1}, k=1, xi=48, d1={"\u0000*\n\u0002\u0018\u0002\n\u0002\u0018\u0002\n\u0002\b\u0002\n\u0002\u0010\u000e\n\u0002\b\u0002\n\u0002\u0010\u0012\n\u0002\b\u0002\n\u0002\u0018\u0002\n\u0000\n\u0002\u0010\b\n\u0002\b\u0006\u0018\u0000 \u00112\u00020\u0001:\u0001\u0011B\u0015\u0012\u0006\u0010\u0002\u001a\u00020\u0001\u0012\u0006\u0010\u0003\u001a\u00020\u0004\u00a2\u0006\u0002\u0010\u0005J\b\u0010\u000e\u001a\u00020\fH\u0016J\b\u0010\u000f\u001a\u00020\fH\u0016J\b\u0010\u0010\u001a\u00020\u0007H\u0002R\u000e\u0010\u0006\u001a\u00020\u0007X\u0082\u0004\u00a2\u0006\u0002\n\u0000R\u0010\u0010\b\u001a\u0004\u0018\u00010\u0007X\u0082\u000e\u00a2\u0006\u0002\n\u0000R\u000e\u0010\t\u001a\u00020\nX\u0082\u0004\u00a2\u0006\u0002\n\u0000R\u000e\u0010\u0002\u001a\u00020\u0001X\u0082\u0004\u00a2\u0006\u0002\n\u0000R\u000e\u0010\u000b\u001a\u00020\fX\u0082\u000e\u00a2\u0006\u0002\n\u0000R\u000e\u0010\r\u001a\u00020\fX\u0082\u000e\u00a2\u0006\u0002\n\u0000\u00a8\u0006\u0012"}, d2={"Ldorkbox/util/crypto/OpenSSLPBEInputStream;", "Ljava/io/InputStream;", "inStream", "password", "", "(Ljava/io/InputStream;Ljava/lang/String;)V", "bufferCipher", "", "bufferClear", "cipher", "Ljavax/crypto/Cipher;", "index", "", "maxIndex", "available", "read", "readSalt", "Companion", "Utilities"})
public final class OpenSSLPBEInputStream
extends InputStream {
    @NotNull
    public static final Companion Companion = new Companion(null);
    @NotNull
    private final InputStream inStream;
    @NotNull
    private final Cipher cipher;
    @NotNull
    private final byte[] bufferCipher;
    @Nullable
    private byte[] bufferClear;
    private int index;
    private int maxIndex;
    private static final int READ_BLOCK_SIZE = 65536;

    public OpenSSLPBEInputStream(@NotNull InputStream inStream, @NotNull String password) throws IOException {
        Intrinsics.checkNotNullParameter((Object)inStream, (String)"inStream");
        Intrinsics.checkNotNullParameter((Object)password, (String)"password");
        this.inStream = inStream;
        this.bufferCipher = new byte[65536];
        this.index = Integer.MAX_VALUE;
        try {
            byte[] salt = this.readSalt();
            this.cipher = OpenSSLPBECommon.INSTANCE.initializeCipher(password, salt, 2);
        }
        catch (InvalidKeySpecException e) {
            throw new IOException(e);
        }
        catch (NoSuchPaddingException e) {
            throw new IOException(e);
        }
        catch (NoSuchAlgorithmException e) {
            throw new IOException(e);
        }
        catch (InvalidKeyException e) {
            throw new IOException(e);
        }
        catch (InvalidAlgorithmParameterException e) {
            throw new IOException(e);
        }
    }

    private final byte[] readSalt() throws IOException {
        byte[] headerBytes = new byte[8];
        this.inStream.read(headerBytes);
        String headerString = new String(headerBytes, Charsets.US_ASCII);
        if (!Intrinsics.areEqual((Object)"Salted__", (Object)headerString)) {
            throw new IOException("unexpected magic bytes " + headerString);
        }
        byte[] salt = new byte[8];
        this.inStream.read(salt);
        return salt;
    }

    @Override
    public int read() throws IOException {
        block10: {
            block14: {
                block13: {
                    block12: {
                        block11: {
                            if (this.index <= this.maxIndex) break block10;
                            this.index = 0;
                            int read2 = this.inStream.read(this.bufferCipher);
                            if (read2 != -1) {
                                this.bufferClear = this.cipher.update(this.bufferCipher, 0, read2);
                            }
                            if (read2 == -1 || this.bufferClear == null) break block11;
                            Intrinsics.checkNotNull((Object)this.bufferClear);
                            if (!(this.bufferClear.length == 0)) break block12;
                        }
                        try {
                            this.bufferClear = this.cipher.doFinal();
                        }
                        catch (IllegalBlockSizeException e) {
                            this.bufferClear = null;
                        }
                        catch (BadPaddingException e) {
                            this.bufferClear = null;
                        }
                    }
                    if (this.bufferClear == null) break block13;
                    Intrinsics.checkNotNull((Object)this.bufferClear);
                    if (!(this.bufferClear.length == 0)) break block14;
                }
                return -1;
            }
            Intrinsics.checkNotNull((Object)this.bufferClear);
            this.maxIndex = this.bufferClear.length - 1;
        }
        Intrinsics.checkNotNull((Object)this.bufferClear);
        int n = this.index;
        this.index = n + 1;
        n = this.bufferClear[n];
        int n2 = -1;
        return (byte)(n & n2);
    }

    @Override
    public int available() throws IOException {
        return this.inStream.available();
    }

    @Metadata(mv={1, 7, 1}, k=1, xi=48, d1={"\u0000\u0012\n\u0002\u0018\u0002\n\u0002\u0010\u0000\n\u0002\b\u0002\n\u0002\u0010\b\n\u0000\b\u0086\u0003\u0018\u00002\u00020\u0001B\u0007\b\u0002\u00a2\u0006\u0002\u0010\u0002R\u000e\u0010\u0003\u001a\u00020\u0004X\u0082T\u00a2\u0006\u0002\n\u0000\u00a8\u0006\u0005"}, d2={"Ldorkbox/util/crypto/OpenSSLPBEInputStream$Companion;", "", "()V", "READ_BLOCK_SIZE", "", "Utilities"})
    public static final class Companion {
        private Companion() {
        }

        public /* synthetic */ Companion(DefaultConstructorMarker $constructor_marker) {
            this();
        }
    }
}

