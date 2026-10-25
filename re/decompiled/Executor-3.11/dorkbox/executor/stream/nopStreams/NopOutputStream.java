/*
 * Decompiled with CFR 0.152.
 * 
 * Could not load the following classes:
 *  kotlin.Metadata
 *  kotlin.jvm.internal.DefaultConstructorMarker
 *  kotlin.jvm.internal.Intrinsics
 *  org.jetbrains.annotations.NotNull
 */
package dorkbox.executor.stream.nopStreams;

import java.io.IOException;
import java.io.OutputStream;
import kotlin.Metadata;
import kotlin.jvm.internal.DefaultConstructorMarker;
import kotlin.jvm.internal.Intrinsics;
import org.jetbrains.annotations.NotNull;

@Metadata(mv={1, 6, 0}, k=1, xi=48, d1={"\u0000 \n\u0002\u0018\u0002\n\u0002\u0018\u0002\n\u0002\b\u0002\n\u0002\u0010\u0002\n\u0000\n\u0002\u0010\u0012\n\u0000\n\u0002\u0010\b\n\u0002\b\u0003\u0018\u0000 \n2\u00020\u0001:\u0001\nB\u0005\u00a2\u0006\u0002\u0010\u0002J\u0010\u0010\u0003\u001a\u00020\u00042\u0006\u0010\u0005\u001a\u00020\u0006H\u0016J \u0010\u0003\u001a\u00020\u00042\u0006\u0010\u0005\u001a\u00020\u00062\u0006\u0010\u0007\u001a\u00020\b2\u0006\u0010\t\u001a\u00020\bH\u0016J\u0010\u0010\u0003\u001a\u00020\u00042\u0006\u0010\u0005\u001a\u00020\bH\u0016\u00a8\u0006\u000b"}, d2={"Ldorkbox/executor/stream/nopStreams/NopOutputStream;", "Ljava/io/OutputStream;", "()V", "write", "", "b", "", "off", "", "len", "Companion", "Executor"})
public final class NopOutputStream
extends OutputStream {
    @NotNull
    public static final Companion Companion = new Companion(null);
    @NotNull
    private static final NopOutputStream OUTPUT_STREAM = new NopOutputStream();

    @Override
    public void write(@NotNull byte[] b, int off, int len) {
        Intrinsics.checkNotNullParameter((Object)b, (String)"b");
    }

    @Override
    public void write(int b) {
    }

    @Override
    public void write(@NotNull byte[] b) throws IOException {
        Intrinsics.checkNotNullParameter((Object)b, (String)"b");
    }

    @Metadata(mv={1, 6, 0}, k=1, xi=48, d1={"\u0000\u0014\n\u0002\u0018\u0002\n\u0002\u0010\u0000\n\u0002\b\u0002\n\u0002\u0018\u0002\n\u0002\b\u0003\b\u0086\u0003\u0018\u00002\u00020\u0001B\u0007\b\u0002\u00a2\u0006\u0002\u0010\u0002R\u0011\u0010\u0003\u001a\u00020\u0004\u00a2\u0006\b\n\u0000\u001a\u0004\b\u0005\u0010\u0006\u00a8\u0006\u0007"}, d2={"Ldorkbox/executor/stream/nopStreams/NopOutputStream$Companion;", "", "()V", "OUTPUT_STREAM", "Ldorkbox/executor/stream/nopStreams/NopOutputStream;", "getOUTPUT_STREAM", "()Ldorkbox/executor/stream/nopStreams/NopOutputStream;", "Executor"})
    public static final class Companion {
        private Companion() {
        }

        @NotNull
        public final NopOutputStream getOUTPUT_STREAM() {
            return OUTPUT_STREAM;
        }

        public /* synthetic */ Companion(DefaultConstructorMarker $constructor_marker) {
            this();
        }
    }
}

