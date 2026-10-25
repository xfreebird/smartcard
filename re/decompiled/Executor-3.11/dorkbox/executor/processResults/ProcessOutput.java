/*
 * Decompiled with CFR 0.152.
 * 
 * Could not load the following classes:
 *  kotlin.Metadata
 *  kotlin.jvm.internal.DefaultConstructorMarker
 *  kotlin.jvm.internal.Intrinsics
 *  kotlin.text.Charsets
 *  org.jetbrains.annotations.NotNull
 */
package dorkbox.executor.processResults;

import java.io.UnsupportedEncodingException;
import java.nio.charset.Charset;
import java.util.ArrayList;
import java.util.List;
import java.util.StringTokenizer;
import kotlin.Metadata;
import kotlin.jvm.internal.DefaultConstructorMarker;
import kotlin.jvm.internal.Intrinsics;
import kotlin.text.Charsets;
import org.jetbrains.annotations.NotNull;

@Metadata(mv={1, 6, 0}, k=1, xi=48, d1={"\u0000$\n\u0002\u0018\u0002\n\u0002\u0010\u0000\n\u0000\n\u0002\u0010\u0012\n\u0002\b\u0004\n\u0002\u0010 \n\u0002\u0010\u000e\n\u0000\n\u0002\u0018\u0002\n\u0002\b\u0006\u0018\u0000 \u00102\u00020\u0001:\u0001\u0010B\r\u0012\u0006\u0010\u0002\u001a\u00020\u0003\u00a2\u0006\u0002\u0010\u0004J\u0014\u0010\u0007\u001a\b\u0012\u0004\u0012\u00020\t0\b2\u0006\u0010\n\u001a\u00020\u000bJ\f\u0010\f\u001a\b\u0012\u0004\u0012\u00020\t0\bJ\f\u0010\r\u001a\b\u0012\u0004\u0012\u00020\t0\bJ\u0006\u0010\u000e\u001a\u00020\tJ\u000e\u0010\u000e\u001a\u00020\t2\u0006\u0010\n\u001a\u00020\u000bJ\u0006\u0010\u000f\u001a\u00020\tR\u0014\u0010\u0002\u001a\u00020\u0003X\u0080\u0004\u00a2\u0006\b\n\u0000\u001a\u0004\b\u0005\u0010\u0006\u00a8\u0006\u0011"}, d2={"Ldorkbox/executor/processResults/ProcessOutput;", "", "bytes_", "", "([B)V", "getBytes_$Executor", "()[B", "getLines", "", "", "charset", "Ljava/nio/charset/Charset;", "lines", "linesAsUtf8", "string", "utf8", "Companion", "Executor"})
public final class ProcessOutput {
    @NotNull
    public static final Companion Companion = new Companion(null);
    @NotNull
    private final byte[] bytes_;

    public ProcessOutput(@NotNull byte[] bytes_) {
        Intrinsics.checkNotNullParameter((Object)bytes_, (String)"bytes_");
        this.bytes_ = bytes_;
    }

    @NotNull
    public final byte[] getBytes_$Executor() {
        return this.bytes_;
    }

    @NotNull
    public final String string() {
        return new String(this.bytes_, Charsets.UTF_8);
    }

    @NotNull
    public final String utf8() {
        return this.string(Charsets.UTF_8);
    }

    @NotNull
    public final String string(@NotNull Charset charset) throws IllegalStateException {
        Object object;
        Intrinsics.checkNotNullParameter((Object)charset, (String)"charset");
        try {
            object = this.bytes_;
            object = new String((byte[])object, charset);
        }
        catch (UnsupportedEncodingException e) {
            throw new IllegalStateException(e.getMessage());
        }
        return object;
    }

    @NotNull
    public final List<String> lines() {
        return Companion.getLinesFrom(this.string());
    }

    @NotNull
    public final List<String> linesAsUtf8() {
        return Companion.getLinesFrom(this.utf8());
    }

    @NotNull
    public final List<String> getLines(@NotNull Charset charset) {
        Intrinsics.checkNotNullParameter((Object)charset, (String)"charset");
        return Companion.getLinesFrom(this.string(charset));
    }

    @Metadata(mv={1, 6, 0}, k=1, xi=48, d1={"\u0000\u0018\n\u0002\u0018\u0002\n\u0002\u0010\u0000\n\u0002\b\u0002\n\u0002\u0010 \n\u0002\u0010\u000e\n\u0002\b\u0002\b\u0086\u0003\u0018\u00002\u00020\u0001B\u0007\b\u0002\u00a2\u0006\u0002\u0010\u0002J\u0014\u0010\u0003\u001a\b\u0012\u0004\u0012\u00020\u00050\u00042\u0006\u0010\u0006\u001a\u00020\u0005\u00a8\u0006\u0007"}, d2={"Ldorkbox/executor/processResults/ProcessOutput$Companion;", "", "()V", "getLinesFrom", "", "", "output", "Executor"})
    public static final class Companion {
        private Companion() {
        }

        @NotNull
        public final List<String> getLinesFrom(@NotNull String output2) {
            Intrinsics.checkNotNullParameter((Object)output2, (String)"output");
            List result = new ArrayList();
            StringTokenizer st = new StringTokenizer(output2, "\r\n");
            while (st.hasMoreTokens()) {
                String string2 = st.nextToken();
                Intrinsics.checkNotNullExpressionValue((Object)string2, (String)"st.nextToken()");
                result.add(string2);
            }
            return result;
        }

        public /* synthetic */ Companion(DefaultConstructorMarker $constructor_marker) {
            this();
        }
    }
}

