/*
 * Decompiled with CFR 0.152.
 * 
 * Could not load the following classes:
 *  kotlin.Metadata
 *  kotlin.Unit
 *  kotlin.collections.IntIterator
 *  kotlin.coroutines.Continuation
 *  kotlin.jvm.JvmInline
 *  kotlin.jvm.internal.Intrinsics
 *  kotlin.ranges.RangesKt
 *  org.jetbrains.annotations.NotNull
 *  org.jetbrains.annotations.Nullable
 */
package dorkbox.executor.stream;

import dorkbox.executor.stream.IOStream;
import java.io.InputStream;
import java.io.OutputStream;
import java.util.Iterator;
import kotlin.Metadata;
import kotlin.Unit;
import kotlin.collections.IntIterator;
import kotlin.coroutines.Continuation;
import kotlin.jvm.JvmInline;
import kotlin.jvm.internal.Intrinsics;
import kotlin.ranges.RangesKt;
import org.jetbrains.annotations.NotNull;
import org.jetbrains.annotations.Nullable;

/*
 * Illegal identifiers - consider using --renameillegalidents true
 */
@JvmInline
@Metadata(mv={1, 6, 0}, k=1, xi=48, d1={"\u0000@\n\u0002\u0018\u0002\n\u0002\u0018\u0002\n\u0000\n\u0002\u0018\u0002\n\u0002\b\u0003\n\u0002\u0010\u0002\n\u0002\b\u0003\n\u0002\u0010\u000b\n\u0000\n\u0002\u0010\u0000\n\u0002\b\u0003\n\u0002\u0010\b\n\u0002\b\u0005\n\u0002\u0018\u0002\n\u0002\b\u0003\n\u0002\u0010\u000e\n\u0002\b\u0003\b\u0087@\u0018\u00002\u00020\u0001B\u0012\u0012\u0006\u0010\u0002\u001a\u00020\u0003\u00f8\u0001\u0000\u00a2\u0006\u0004\b\u0004\u0010\u0005J\u000f\u0010\u0006\u001a\u00020\u0007H\u0016\u00a2\u0006\u0004\b\b\u0010\tJ\u001a\u0010\n\u001a\u00020\u000b2\b\u0010\f\u001a\u0004\u0018\u00010\rH\u00d6\u0003\u00a2\u0006\u0004\b\u000e\u0010\u000fJ\u0010\u0010\u0010\u001a\u00020\u0011H\u00d6\u0001\u00a2\u0006\u0004\b\u0012\u0010\u0013J#\u0010\u0014\u001a\u00020\u00072\u0006\u0010\u0015\u001a\u00020\u00112\u0006\u0010\u0016\u001a\u00020\u0017H\u0096@\u00f8\u0001\u0000\u00a2\u0006\u0004\b\u0018\u0010\u0019J\u0010\u0010\u001a\u001a\u00020\u001bH\u00d6\u0001\u00a2\u0006\u0004\b\u001c\u0010\u001dR\u000e\u0010\u0002\u001a\u00020\u0003X\u0082\u0004\u00a2\u0006\u0002\n\u0000\u0088\u0001\u0002\u0092\u0001\u00020\u0003\u00f8\u0001\u0000\u0082\u0002\u0004\n\u0002\b\u0019\u00a8\u0006\u001e"}, d2={"Ldorkbox/executor/stream/PumpedOutputStream;", "Ldorkbox/executor/stream/IOStream;", "out", "Ljava/io/OutputStream;", "constructor-impl", "(Ljava/io/OutputStream;)Ljava/io/OutputStream;", "close", "", "close-impl", "(Ljava/io/OutputStream;)V", "equals", "", "other", "", "equals-impl", "(Ljava/io/OutputStream;Ljava/lang/Object;)Z", "hashCode", "", "hashCode-impl", "(Ljava/io/OutputStream;)I", "pump", "length", "inputStream", "Ljava/io/InputStream;", "pump-impl", "(Ljava/io/OutputStream;ILjava/io/InputStream;Lkotlin/coroutines/Continuation;)Ljava/lang/Object;", "toString", "", "toString-impl", "(Ljava/io/OutputStream;)Ljava/lang/String;", "Executor"})
public final class PumpedOutputStream
implements IOStream {
    @NotNull
    private final OutputStream out;

    @Nullable
    public static Object pump-impl(OutputStream arg0, int length, @NotNull InputStream inputStream, @NotNull Continuation<? super Unit> $completion) {
        Iterable $this$forEach$iv = (Iterable)RangesKt.until((int)0, (int)RangesKt.coerceAtMost((int)length, (int)1024));
        boolean $i$f$forEach = false;
        Iterator iterator = $this$forEach$iv.iterator();
        while (iterator.hasNext()) {
            int element$iv;
            int $noName_0 = element$iv = ((IntIterator)iterator).nextInt();
            boolean bl = false;
            arg0.write(inputStream.read());
        }
        arg0.flush();
        return Unit.INSTANCE;
    }

    @Override
    @Nullable
    public Object pump(int length, @NotNull InputStream inputStream, @NotNull Continuation<? super Unit> $completion) {
        return PumpedOutputStream.pump-impl(this.out, length, inputStream, $completion);
    }

    public static void close-impl(OutputStream arg0) {
        Intrinsics.checkNotNullParameter((Object)arg0, (String)"arg0");
        arg0.close();
    }

    @Override
    public void close() {
        PumpedOutputStream.close-impl(this.out);
    }

    public static String toString-impl(OutputStream arg0) {
        return "PumpedOutputStream(out=" + arg0 + ')';
    }

    public String toString() {
        return PumpedOutputStream.toString-impl(this.out);
    }

    public static int hashCode-impl(OutputStream arg0) {
        return arg0.hashCode();
    }

    public int hashCode() {
        return PumpedOutputStream.hashCode-impl(this.out);
    }

    public static boolean equals-impl(OutputStream arg0, Object other) {
        if (!(other instanceof PumpedOutputStream)) {
            return false;
        }
        return Intrinsics.areEqual((Object)arg0, (Object)((PumpedOutputStream)other).unbox-impl());
    }

    public boolean equals(Object other) {
        return PumpedOutputStream.equals-impl(this.out, other);
    }

    private /* synthetic */ PumpedOutputStream(OutputStream out) {
        this.out = out;
    }

    @NotNull
    public static OutputStream constructor-impl(@NotNull OutputStream out) {
        Intrinsics.checkNotNullParameter((Object)out, (String)"out");
        return out;
    }

    public static final /* synthetic */ PumpedOutputStream box-impl(OutputStream v) {
        return new PumpedOutputStream(v);
    }

    public final /* synthetic */ OutputStream unbox-impl() {
        return this.out;
    }

    public static final boolean equals-impl0(OutputStream p1, OutputStream p2) {
        return Intrinsics.areEqual((Object)p1, (Object)p2);
    }
}

