/*
 * Decompiled with CFR 0.152.
 * 
 * Could not load the following classes:
 *  kotlin.Metadata
 *  kotlin.jvm.internal.DefaultConstructorMarker
 *  org.jetbrains.annotations.NotNull
 */
package dorkbox.executor.stream.nopStreams;

import java.io.InputStream;
import kotlin.Metadata;
import kotlin.jvm.internal.DefaultConstructorMarker;
import org.jetbrains.annotations.NotNull;

@Metadata(mv={1, 6, 0}, k=1, xi=48, d1={"\u0000\u0014\n\u0002\u0018\u0002\n\u0002\u0018\u0002\n\u0002\b\u0002\n\u0002\u0010\b\n\u0002\b\u0003\u0018\u0000 \u00062\u00020\u0001:\u0001\u0006B\u0005\u00a2\u0006\u0002\u0010\u0002J\b\u0010\u0003\u001a\u00020\u0004H\u0016J\b\u0010\u0005\u001a\u00020\u0004H\u0016\u00a8\u0006\u0007"}, d2={"Ldorkbox/executor/stream/nopStreams/NopInputStream;", "Ljava/io/InputStream;", "()V", "available", "", "read", "Companion", "Executor"})
public final class NopInputStream
extends InputStream {
    @NotNull
    public static final Companion Companion = new Companion(null);
    @NotNull
    private static final NopInputStream INPUT_STREAM = new NopInputStream();

    @Override
    public int available() {
        return 0;
    }

    @Override
    public int read() {
        return -1;
    }

    @Metadata(mv={1, 6, 0}, k=1, xi=48, d1={"\u0000\u0014\n\u0002\u0018\u0002\n\u0002\u0010\u0000\n\u0002\b\u0002\n\u0002\u0018\u0002\n\u0002\b\u0003\b\u0086\u0003\u0018\u00002\u00020\u0001B\u0007\b\u0002\u00a2\u0006\u0002\u0010\u0002R\u0011\u0010\u0003\u001a\u00020\u0004\u00a2\u0006\b\n\u0000\u001a\u0004\b\u0005\u0010\u0006\u00a8\u0006\u0007"}, d2={"Ldorkbox/executor/stream/nopStreams/NopInputStream$Companion;", "", "()V", "INPUT_STREAM", "Ldorkbox/executor/stream/nopStreams/NopInputStream;", "getINPUT_STREAM", "()Ldorkbox/executor/stream/nopStreams/NopInputStream;", "Executor"})
    public static final class Companion {
        private Companion() {
        }

        @NotNull
        public final NopInputStream getINPUT_STREAM() {
            return INPUT_STREAM;
        }

        public /* synthetic */ Companion(DefaultConstructorMarker $constructor_marker) {
            this();
        }
    }
}

