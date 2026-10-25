/*
 * Decompiled with CFR 0.152.
 * 
 * Could not load the following classes:
 *  kotlin.Metadata
 *  kotlin.io.ByteStreamsKt
 *  kotlin.io.CloseableKt
 *  kotlin.jvm.internal.Intrinsics
 *  org.jetbrains.annotations.NotNull
 *  org.tukaani.xz.LZMA2Options
 *  org.tukaani.xz.LZMAInputStream
 *  org.tukaani.xz.LZMAOutputStream
 */
package dorkbox.util;

import java.io.ByteArrayOutputStream;
import java.io.Closeable;
import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;
import kotlin.Metadata;
import kotlin.io.ByteStreamsKt;
import kotlin.io.CloseableKt;
import kotlin.jvm.internal.Intrinsics;
import org.jetbrains.annotations.NotNull;
import org.tukaani.xz.LZMA2Options;
import org.tukaani.xz.LZMAInputStream;
import org.tukaani.xz.LZMAOutputStream;

@Metadata(mv={1, 7, 1}, k=1, xi=48, d1={"\u0000$\n\u0002\u0018\u0002\n\u0002\u0010\u0000\n\u0002\b\u0002\n\u0002\u0018\u0002\n\u0000\n\u0002\u0018\u0002\n\u0002\u0010\u0002\n\u0000\n\u0002\u0018\u0002\n\u0002\b\u0002\b\u00c6\u0002\u0018\u00002\u00020\u0001B\u0007\b\u0002\u00a2\u0006\u0002\u0010\u0002J\u000e\u0010\u0003\u001a\u00020\u00042\u0006\u0010\u0005\u001a\u00020\u0006J\u0016\u0010\u0003\u001a\u00020\u00072\u0006\u0010\u0005\u001a\u00020\u00062\u0006\u0010\b\u001a\u00020\tJ\u0016\u0010\n\u001a\u00020\u00072\u0006\u0010\u0005\u001a\u00020\u00062\u0006\u0010\b\u001a\u00020\t\u00a8\u0006\u000b"}, d2={"Ldorkbox/util/LZMA;", "", "()V", "decode", "Ljava/io/ByteArrayOutputStream;", "input", "Ljava/io/InputStream;", "", "output", "Ljava/io/OutputStream;", "encode", "Utilities"})
public final class LZMA {
    @NotNull
    public static final LZMA INSTANCE = new LZMA();

    private LZMA() {
    }

    /*
     * WARNING - Removed try catching itself - possible behaviour change.
     */
    public final void encode(@NotNull InputStream input, @NotNull OutputStream output) throws IOException {
        Intrinsics.checkNotNullParameter((Object)input, (String)"input");
        Intrinsics.checkNotNullParameter((Object)output, (String)"output");
        Closeable closeable = (Closeable)new LZMAOutputStream(output, new LZMA2Options(3), true);
        Throwable throwable = null;
        try {
            LZMAOutputStream compressionStream = (LZMAOutputStream)closeable;
            boolean bl = false;
            long l = ByteStreamsKt.copyTo$default((InputStream)input, (OutputStream)((OutputStream)compressionStream), (int)0, (int)2, null);
        }
        catch (Throwable throwable2) {
            throwable = throwable2;
            throw throwable2;
        }
        finally {
            CloseableKt.closeFinally((Closeable)closeable, (Throwable)throwable);
        }
    }

    /*
     * WARNING - Removed try catching itself - possible behaviour change.
     */
    @NotNull
    public final ByteArrayOutputStream decode(@NotNull InputStream input) throws IOException {
        Intrinsics.checkNotNullParameter((Object)input, (String)"input");
        ByteArrayOutputStream byteArrayOutputStream = new ByteArrayOutputStream(8192);
        Closeable closeable = (Closeable)new LZMAInputStream(input);
        Throwable throwable = null;
        try {
            LZMAInputStream compressedStream = (LZMAInputStream)closeable;
            boolean bl = false;
            long l = ByteStreamsKt.copyTo$default((InputStream)((InputStream)compressedStream), (OutputStream)byteArrayOutputStream, (int)0, (int)2, null);
        }
        catch (Throwable throwable2) {
            throwable = throwable2;
            throw throwable2;
        }
        finally {
            CloseableKt.closeFinally((Closeable)closeable, (Throwable)throwable);
        }
        return byteArrayOutputStream;
    }

    /*
     * WARNING - Removed try catching itself - possible behaviour change.
     */
    public final void decode(@NotNull InputStream input, @NotNull OutputStream output) throws IOException {
        Intrinsics.checkNotNullParameter((Object)input, (String)"input");
        Intrinsics.checkNotNullParameter((Object)output, (String)"output");
        Closeable closeable = (Closeable)new LZMAInputStream(input);
        Throwable throwable = null;
        try {
            LZMAInputStream compressedStream = (LZMAInputStream)closeable;
            boolean bl = false;
            long l = ByteStreamsKt.copyTo$default((InputStream)((InputStream)compressedStream), (OutputStream)output, (int)0, (int)2, null);
        }
        catch (Throwable throwable2) {
            throwable = throwable2;
            throw throwable2;
        }
        finally {
            CloseableKt.closeFinally((Closeable)closeable, (Throwable)throwable);
        }
    }
}

