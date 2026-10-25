/*
 * Decompiled with CFR 0.152.
 * 
 * Could not load the following classes:
 *  kotlin.Metadata
 *  kotlin.Unit
 *  kotlin.coroutines.Continuation
 *  kotlin.jvm.internal.DefaultConstructorMarker
 *  kotlin.jvm.internal.Intrinsics
 *  org.jetbrains.annotations.NotNull
 *  org.jetbrains.annotations.Nullable
 */
package dorkbox.executor.stream;

import dorkbox.executor.stream.PumpStreamHandler;
import dorkbox.executor.stream.TeeOutputStream;
import dorkbox.executor.stream.nopStreams.NopInputStream;
import dorkbox.executor.stream.nopStreams.NopOutputStream;
import java.io.InputStream;
import java.io.OutputStream;
import java.io.PrintStream;
import kotlin.Metadata;
import kotlin.Unit;
import kotlin.coroutines.Continuation;
import kotlin.jvm.internal.DefaultConstructorMarker;
import kotlin.jvm.internal.Intrinsics;
import org.jetbrains.annotations.NotNull;
import org.jetbrains.annotations.Nullable;

@Metadata(mv={1, 6, 0}, k=1, xi=48, d1={"\u00006\n\u0002\u0018\u0002\n\u0002\u0010\u0000\n\u0000\n\u0002\u0018\u0002\n\u0002\b\u0002\n\u0002\u0018\u0002\n\u0000\n\u0002\u0010\u000b\n\u0002\b\t\n\u0002\u0018\u0002\n\u0002\b\u0007\n\u0002\u0010\u0002\n\u0000\n\u0002\u0018\u0002\n\u0002\b\b\b&\u0018\u00002\u00020\u0001B-\u0012\b\b\u0002\u0010\u0002\u001a\u00020\u0003\u0012\b\b\u0002\u0010\u0004\u001a\u00020\u0003\u0012\b\b\u0002\u0010\u0005\u001a\u00020\u0006\u0012\b\b\u0002\u0010\u0007\u001a\u00020\b\u00a2\u0006\u0002\u0010\tJ\u0006\u0010\u0011\u001a\u00020\u0012J\u000e\u0010\u0013\u001a\u00020\u00002\u0006\u0010\u0014\u001a\u00020\u0003J\u000e\u0010\u0015\u001a\u00020\u00002\u0006\u0010\u0016\u001a\u00020\u0006J\u000e\u0010\u0017\u001a\u00020\u00002\u0006\u0010\u0018\u001a\u00020\u0003J \u0010\u0019\u001a\u00020\u001a2\u0006\u0010\u001b\u001a\u00020\u001c2\u0006\u0010\u001d\u001a\u00020\b2\u0006\u0010\u001e\u001a\u00020\bH\u0016J!\u0010\u001f\u001a\u00020\u001a2\u0006\u0010\u001b\u001a\u00020\u001c2\u0006\u0010 \u001a\u00020\bH\u0096@\u00f8\u0001\u0000\u00a2\u0006\u0002\u0010!J\u000e\u0010\"\u001a\u00020\u00122\u0006\u0010\u0018\u001a\u00020\u0003J\u000e\u0010#\u001a\u00020\u00122\u0006\u0010\u0018\u001a\u00020\u0003R\u0014\u0010\u0007\u001a\u00020\bX\u0080\u0004\u00a2\u0006\b\n\u0000\u001a\u0004\b\n\u0010\u000bR\u0014\u0010\u0004\u001a\u00020\u0003X\u0080\u0004\u00a2\u0006\b\n\u0000\u001a\u0004\b\f\u0010\rR\u0014\u0010\u0005\u001a\u00020\u0006X\u0080\u0004\u00a2\u0006\b\n\u0000\u001a\u0004\b\u000e\u0010\u000fR\u0014\u0010\u0002\u001a\u00020\u0003X\u0080\u0004\u00a2\u0006\b\n\u0000\u001a\u0004\b\u0010\u0010\r\u0082\u0002\u0004\n\u0002\b\u0019\u00a8\u0006$"}, d2={"Ldorkbox/executor/stream/IOStreamHandler;", "", "out", "Ljava/io/OutputStream;", "err", "input", "Ljava/io/InputStream;", "asyncSupport", "", "(Ljava/io/OutputStream;Ljava/io/OutputStream;Ljava/io/InputStream;Z)V", "getAsyncSupport$Executor", "()Z", "getErr$Executor", "()Ljava/io/OutputStream;", "getInput$Executor", "()Ljava/io/InputStream;", "getOut$Executor", "asyncMode", "Ldorkbox/executor/stream/PumpStreamHandler;", "setErrorStream", "errorStream", "setInputStream", "inputStream", "setOutputStream", "outputStream", "start", "", "process", "Ljava/lang/Process;", "separateErrorStream", "highPerformanceIO", "stop", "finishedCleanly", "(Ljava/lang/Process;ZLkotlin/coroutines/Continuation;)Ljava/lang/Object;", "teeErrorStream", "teeOutputStream", "Executor"})
public abstract class IOStreamHandler {
    @NotNull
    private final OutputStream out;
    @NotNull
    private final OutputStream err;
    @NotNull
    private final InputStream input;
    private final boolean asyncSupport;

    public IOStreamHandler(@NotNull OutputStream out, @NotNull OutputStream err, @NotNull InputStream input, boolean asyncSupport) {
        Intrinsics.checkNotNullParameter((Object)out, (String)"out");
        Intrinsics.checkNotNullParameter((Object)err, (String)"err");
        Intrinsics.checkNotNullParameter((Object)input, (String)"input");
        this.out = out;
        this.err = err;
        this.input = input;
        this.asyncSupport = asyncSupport;
    }

    public /* synthetic */ IOStreamHandler(OutputStream outputStream, OutputStream outputStream2, InputStream inputStream, boolean bl, int n, DefaultConstructorMarker defaultConstructorMarker) {
        PrintStream printStream;
        if ((n & 1) != 0) {
            printStream = System.out;
            Intrinsics.checkNotNullExpressionValue((Object)printStream, (String)"out");
            outputStream = printStream;
        }
        if ((n & 2) != 0) {
            printStream = System.err;
            Intrinsics.checkNotNullExpressionValue((Object)printStream, (String)"err");
            outputStream2 = printStream;
        }
        if ((n & 4) != 0) {
            inputStream = NopInputStream.Companion.getINPUT_STREAM();
        }
        if ((n & 8) != 0) {
            bl = false;
        }
        this(outputStream, outputStream2, inputStream, bl);
    }

    @NotNull
    public final OutputStream getOut$Executor() {
        return this.out;
    }

    @NotNull
    public final OutputStream getErr$Executor() {
        return this.err;
    }

    @NotNull
    public final InputStream getInput$Executor() {
        return this.input;
    }

    public final boolean getAsyncSupport$Executor() {
        return this.asyncSupport;
    }

    @NotNull
    public final PumpStreamHandler asyncMode() {
        return new PumpStreamHandler(this.out, this.err, this.input, true);
    }

    @NotNull
    public final IOStreamHandler setInputStream(@NotNull InputStream inputStream) {
        Intrinsics.checkNotNullParameter((Object)inputStream, (String)"inputStream");
        return new PumpStreamHandler(this.out, this.err, inputStream, this.asyncSupport);
    }

    @NotNull
    public final IOStreamHandler setOutputStream(@NotNull OutputStream outputStream) {
        Intrinsics.checkNotNullParameter((Object)outputStream, (String)"outputStream");
        return new PumpStreamHandler(outputStream, this.err, this.input, this.asyncSupport);
    }

    @NotNull
    public final IOStreamHandler setErrorStream(@NotNull OutputStream errorStream) {
        Intrinsics.checkNotNullParameter((Object)errorStream, (String)"errorStream");
        return new PumpStreamHandler(this.out, errorStream, this.input, this.asyncSupport);
    }

    @NotNull
    public final PumpStreamHandler teeOutputStream(@NotNull OutputStream outputStream) {
        Intrinsics.checkNotNullParameter((Object)outputStream, (String)"outputStream");
        return this.out instanceof NopOutputStream ? new PumpStreamHandler(outputStream, this.err, this.input, this.asyncSupport) : new PumpStreamHandler(new TeeOutputStream(this.out, outputStream), this.err, this.input, this.asyncSupport);
    }

    @NotNull
    public final PumpStreamHandler teeErrorStream(@NotNull OutputStream outputStream) {
        Intrinsics.checkNotNullParameter((Object)outputStream, (String)"outputStream");
        return this.err instanceof NopOutputStream ? new PumpStreamHandler(this.out, outputStream, this.input, this.asyncSupport) : new PumpStreamHandler(this.out, new TeeOutputStream(this.err, outputStream), this.input, this.asyncSupport);
    }

    public void start(@NotNull Process process, boolean separateErrorStream, boolean highPerformanceIO) {
        Intrinsics.checkNotNullParameter((Object)process, (String)"process");
    }

    @Nullable
    public Object stop(@NotNull Process process, boolean finishedCleanly, @NotNull Continuation<? super Unit> $completion) {
        return IOStreamHandler.stop$suspendImpl(this, process, finishedCleanly, $completion);
    }

    static /* synthetic */ Object stop$suspendImpl(IOStreamHandler this_, Process process, boolean finishedCleanly, Continuation $completion) {
        return Unit.INSTANCE;
    }

    public IOStreamHandler() {
        this(null, null, null, false, 15, null);
    }
}

