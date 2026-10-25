/*
 * Decompiled with CFR 0.152.
 * 
 * Could not load the following classes:
 *  kotlin.Metadata
 *  kotlin.jvm.internal.DefaultConstructorMarker
 *  kotlin.jvm.internal.Intrinsics
 *  org.jetbrains.annotations.NotNull
 */
package dorkbox.util.crypto;

import dorkbox.util.crypto.OpenSSLPBECommon;
import java.io.IOException;
import java.io.OutputStream;
import java.security.InvalidAlgorithmParameterException;
import java.security.NoSuchAlgorithmException;
import java.security.SecureRandom;
import java.security.spec.InvalidKeySpecException;
import javax.crypto.BadPaddingException;
import javax.crypto.Cipher;
import javax.crypto.IllegalBlockSizeException;
import javax.crypto.NoSuchPaddingException;
import kotlin.Metadata;
import kotlin.jvm.internal.DefaultConstructorMarker;
import kotlin.jvm.internal.Intrinsics;
import org.jetbrains.annotations.NotNull;

@Metadata(mv={1, 7, 1}, k=1, xi=48, d1={"\u0000.\n\u0002\u0018\u0002\n\u0002\u0018\u0002\n\u0002\b\u0002\n\u0002\u0010\u000e\n\u0002\b\u0002\n\u0002\u0010\u0012\n\u0000\n\u0002\u0010\b\n\u0000\n\u0002\u0018\u0002\n\u0000\n\u0002\u0010\u0002\n\u0002\b\u0005\u0018\u0000 \u00112\u00020\u0001:\u0001\u0011B\u0015\u0012\u0006\u0010\u0002\u001a\u00020\u0001\u0012\u0006\u0010\u0003\u001a\u00020\u0004\u00a2\u0006\u0002\u0010\u0005J\b\u0010\f\u001a\u00020\rH\u0016J\b\u0010\u000e\u001a\u00020\rH\u0016J\u0010\u0010\u000f\u001a\u00020\r2\u0006\u0010\u0010\u001a\u00020\tH\u0016R\u000e\u0010\u0006\u001a\u00020\u0007X\u0082\u0004\u00a2\u0006\u0002\n\u0000R\u000e\u0010\b\u001a\u00020\tX\u0082\u000e\u00a2\u0006\u0002\n\u0000R\u000e\u0010\n\u001a\u00020\u000bX\u0082\u0004\u00a2\u0006\u0002\n\u0000R\u000e\u0010\u0002\u001a\u00020\u0001X\u0082\u0004\u00a2\u0006\u0002\n\u0000\u00a8\u0006\u0012"}, d2={"Ldorkbox/util/crypto/OpenSSLPBEOutputStream;", "Ljava/io/OutputStream;", "outStream", "password", "", "(Ljava/io/OutputStream;Ljava/lang/String;)V", "buffer", "", "bufferIndex", "", "cipher", "Ljavax/crypto/Cipher;", "close", "", "flush", "write", "b", "Companion", "Utilities"})
public final class OpenSSLPBEOutputStream
extends OutputStream {
    @NotNull
    public static final Companion Companion = new Companion(null);
    @NotNull
    private final OutputStream outStream;
    @NotNull
    private final Cipher cipher;
    @NotNull
    private final byte[] buffer;
    private int bufferIndex;
    private static final int BUFFER_SIZE = 0x500000;

    public OpenSSLPBEOutputStream(@NotNull OutputStream outStream, @NotNull String password) throws IOException {
        Intrinsics.checkNotNullParameter((Object)outStream, (String)"outStream");
        Intrinsics.checkNotNullParameter((Object)password, (String)"password");
        this.outStream = outStream;
        this.buffer = new byte[0x500000];
        try {
            byte[] salt = new byte[8];
            SecureRandom secureRandom = new SecureRandom();
            secureRandom.nextBytes(salt);
            this.cipher = OpenSSLPBECommon.INSTANCE.initializeCipher(password, salt, 1);
            this.outStream.write(OpenSSLPBECommon.INSTANCE.getOPENSSL_HEADER_STRING_BYTES());
            this.outStream.write(salt);
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
        catch (InvalidAlgorithmParameterException e) {
            throw new IOException(e);
        }
    }

    @Override
    public void write(int b) throws IOException {
        this.buffer[this.bufferIndex] = (byte)b;
        int n = this.bufferIndex;
        this.bufferIndex = n + 1;
        if (this.bufferIndex == 0x500000) {
            byte[] result = this.cipher.update(this.buffer, 0, this.bufferIndex);
            this.outStream.write(result);
            this.bufferIndex = 0;
        }
    }

    @Override
    public void flush() throws IOException {
        if (this.bufferIndex > 0) {
            byte[] result = null;
            try {
                byte[] byArray = this.cipher.doFinal(this.buffer, 0, this.bufferIndex);
                Intrinsics.checkNotNullExpressionValue((Object)byArray, (String)"cipher.doFinal(buffer, 0, bufferIndex)");
                result = byArray;
                this.outStream.write(result);
            }
            catch (IllegalBlockSizeException e) {
                throw new IOException(e);
            }
            catch (BadPaddingException e) {
                throw new IOException(e);
            }
            this.bufferIndex = 0;
        }
    }

    @Override
    public void close() throws IOException {
        this.flush();
        this.outStream.close();
    }

    @Metadata(mv={1, 7, 1}, k=1, xi=48, d1={"\u0000\u0012\n\u0002\u0018\u0002\n\u0002\u0010\u0000\n\u0002\b\u0002\n\u0002\u0010\b\n\u0000\b\u0086\u0003\u0018\u00002\u00020\u0001B\u0007\b\u0002\u00a2\u0006\u0002\u0010\u0002R\u000e\u0010\u0003\u001a\u00020\u0004X\u0082T\u00a2\u0006\u0002\n\u0000\u00a8\u0006\u0005"}, d2={"Ldorkbox/util/crypto/OpenSSLPBEOutputStream$Companion;", "", "()V", "BUFFER_SIZE", "", "Utilities"})
    public static final class Companion {
        private Companion() {
        }

        public /* synthetic */ Companion(DefaultConstructorMarker $constructor_marker) {
            this();
        }
    }
}

