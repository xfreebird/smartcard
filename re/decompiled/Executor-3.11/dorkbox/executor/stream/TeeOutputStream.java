/*
 * Decompiled with CFR 0.152.
 * 
 * Could not load the following classes:
 *  kotlin.Metadata
 *  kotlin.jvm.internal.Intrinsics
 *  org.jetbrains.annotations.NotNull
 */
package dorkbox.executor.stream;

import java.io.IOException;
import java.io.OutputStream;
import kotlin.Metadata;
import kotlin.jvm.internal.Intrinsics;
import org.jetbrains.annotations.NotNull;

@Metadata(mv={1, 6, 0}, k=1, xi=48, d1={"\u0000\"\n\u0002\u0018\u0002\n\u0002\u0018\u0002\n\u0002\b\u0004\n\u0002\u0010\u0002\n\u0002\b\u0003\n\u0002\u0010\u0012\n\u0000\n\u0002\u0010\b\n\u0002\b\u0002\u0018\u00002\u00020\u0001B\u0015\u0012\u0006\u0010\u0002\u001a\u00020\u0001\u0012\u0006\u0010\u0003\u001a\u00020\u0001\u00a2\u0006\u0002\u0010\u0004J\b\u0010\u0005\u001a\u00020\u0006H\u0016J\b\u0010\u0007\u001a\u00020\u0006H\u0016J\u0010\u0010\b\u001a\u00020\u00062\u0006\u0010\t\u001a\u00020\nH\u0016J \u0010\b\u001a\u00020\u00062\u0006\u0010\t\u001a\u00020\n2\u0006\u0010\u000b\u001a\u00020\f2\u0006\u0010\r\u001a\u00020\fH\u0016J\u0010\u0010\b\u001a\u00020\u00062\u0006\u0010\t\u001a\u00020\fH\u0016R\u000e\u0010\u0002\u001a\u00020\u0001X\u0082\u0004\u00a2\u0006\u0002\n\u0000R\u000e\u0010\u0003\u001a\u00020\u0001X\u0082\u0004\u00a2\u0006\u0002\n\u0000\u00a8\u0006\u000e"}, d2={"Ldorkbox/executor/stream/TeeOutputStream;", "Ljava/io/OutputStream;", "left", "right", "(Ljava/io/OutputStream;Ljava/io/OutputStream;)V", "close", "", "flush", "write", "b", "", "off", "", "len", "Executor"})
public final class TeeOutputStream
extends OutputStream {
    @NotNull
    private final OutputStream left;
    @NotNull
    private final OutputStream right;

    public TeeOutputStream(@NotNull OutputStream left, @NotNull OutputStream right) {
        Intrinsics.checkNotNullParameter((Object)left, (String)"left");
        Intrinsics.checkNotNullParameter((Object)right, (String)"right");
        this.left = left;
        this.right = right;
    }

    @Override
    public void write(@NotNull byte[] b, int off, int len) throws IOException {
        Intrinsics.checkNotNullParameter((Object)b, (String)"b");
        this.left.write(b, off, len);
        this.right.write(b, off, len);
    }

    @Override
    public void write(int b) throws IOException {
        this.left.write(b);
        this.right.write(b);
    }

    @Override
    public void write(@NotNull byte[] b) throws IOException {
        Intrinsics.checkNotNullParameter((Object)b, (String)"b");
        this.left.write(b);
        this.right.write(b);
    }

    /*
     * WARNING - Removed try catching itself - possible behaviour change.
     */
    @Override
    public void close() throws IOException {
        try {
            this.left.close();
        }
        finally {
            this.right.close();
        }
    }

    @Override
    public void flush() throws IOException {
        this.left.flush();
        this.right.flush();
    }
}

