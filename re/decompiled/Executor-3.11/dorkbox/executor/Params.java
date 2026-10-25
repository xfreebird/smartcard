/*
 * Decompiled with CFR 0.152.
 * 
 * Could not load the following classes:
 *  kotlin.Metadata
 *  kotlin.Unit
 *  kotlin.jvm.functions.Function1
 *  kotlin.jvm.internal.Intrinsics
 *  org.jetbrains.annotations.NotNull
 *  org.jetbrains.annotations.Nullable
 *  org.slf4j.Logger
 */
package dorkbox.executor;

import dorkbox.executor.ProcessAttributes;
import dorkbox.executor.listener.ProcessListener;
import dorkbox.executor.stop.ProcessStopper;
import dorkbox.executor.stream.IOStreamHandler;
import java.util.concurrent.TimeUnit;
import kotlin.Metadata;
import kotlin.Unit;
import kotlin.jvm.functions.Function1;
import kotlin.jvm.internal.Intrinsics;
import org.jetbrains.annotations.NotNull;
import org.jetbrains.annotations.Nullable;
import org.slf4j.Logger;

@Metadata(mv={1, 6, 0}, k=1, xi=48, d1={"\u0000Z\n\u0002\u0018\u0002\n\u0002\u0010\u0000\n\u0000\n\u0002\u0018\u0002\n\u0000\n\u0002\u0018\u0002\n\u0000\n\u0002\u0018\u0002\n\u0000\n\u0002\u0018\u0002\n\u0000\n\u0002\u0018\u0002\n\u0000\n\u0002\u0018\u0002\n\u0002\u0018\u0002\n\u0002\u0018\u0002\n\u0002\u0010\u0002\n\u0000\n\u0002\u0010\t\n\u0000\n\u0002\u0018\u0002\n\u0000\n\u0002\u0010\u000b\n\u0002\b \n\u0002\u0010\b\n\u0000\n\u0002\u0010\u000e\n\u0000\b\u0080\b\u0018\u00002\u00020\u0001B_\u0012\u0006\u0010\u0002\u001a\u00020\u0003\u0012\u0006\u0010\u0004\u001a\u00020\u0005\u0012\u0006\u0010\u0006\u001a\u00020\u0007\u0012\u0006\u0010\b\u001a\u00020\t\u0012\b\u0010\n\u001a\u0004\u0018\u00010\u000b\u0012\u0016\u0010\f\u001a\u0012\u0012\b\u0012\u00060\u000ej\u0002`\u000f\u0012\u0004\u0012\u00020\u00100\r\u0012\u0006\u0010\u0011\u001a\u00020\u0012\u0012\u0006\u0010\u0013\u001a\u00020\u0014\u0012\u0006\u0010\u0015\u001a\u00020\u0016\u00a2\u0006\u0002\u0010\u0017J\t\u0010*\u001a\u00020\u0003H\u00c6\u0003J\t\u0010+\u001a\u00020\u0005H\u00c6\u0003J\t\u0010,\u001a\u00020\u0007H\u00c6\u0003J\t\u0010-\u001a\u00020\tH\u00c6\u0003J\u000b\u0010.\u001a\u0004\u0018\u00010\u000bH\u00c6\u0003J\u0019\u0010/\u001a\u0012\u0012\b\u0012\u00060\u000ej\u0002`\u000f\u0012\u0004\u0012\u00020\u00100\rH\u00c6\u0003J\t\u00100\u001a\u00020\u0012H\u00c6\u0003J\t\u00101\u001a\u00020\u0014H\u00c6\u0003J\t\u00102\u001a\u00020\u0016H\u00c6\u0003Ju\u00103\u001a\u00020\u00002\b\b\u0002\u0010\u0002\u001a\u00020\u00032\b\b\u0002\u0010\u0004\u001a\u00020\u00052\b\b\u0002\u0010\u0006\u001a\u00020\u00072\b\b\u0002\u0010\b\u001a\u00020\t2\n\b\u0002\u0010\n\u001a\u0004\u0018\u00010\u000b2\u0018\b\u0002\u0010\f\u001a\u0012\u0012\b\u0012\u00060\u000ej\u0002`\u000f\u0012\u0004\u0012\u00020\u00100\r2\b\b\u0002\u0010\u0011\u001a\u00020\u00122\b\b\u0002\u0010\u0013\u001a\u00020\u00142\b\b\u0002\u0010\u0015\u001a\u00020\u0016H\u00c6\u0001J\u0013\u00104\u001a\u00020\u00162\b\u00105\u001a\u0004\u0018\u00010\u0001H\u00d6\u0003J\t\u00106\u001a\u000207H\u00d6\u0001J\t\u00108\u001a\u000209H\u00d6\u0001R\u0011\u0010\u0015\u001a\u00020\u0016\u00a2\u0006\b\n\u0000\u001a\u0004\b\u0018\u0010\u0019R\u0011\u0010\u0011\u001a\u00020\u0012\u00a2\u0006\b\n\u0000\u001a\u0004\b\u001a\u0010\u001bR\u0011\u0010\u0013\u001a\u00020\u0014\u00a2\u0006\b\n\u0000\u001a\u0004\b\u001c\u0010\u001dR!\u0010\f\u001a\u0012\u0012\b\u0012\u00060\u000ej\u0002`\u000f\u0012\u0004\u0012\u00020\u00100\r\u00a2\u0006\b\n\u0000\u001a\u0004\b\u001e\u0010\u001fR\u0011\u0010\u0006\u001a\u00020\u0007\u00a2\u0006\b\n\u0000\u001a\u0004\b \u0010!R\u0013\u0010\n\u001a\u0004\u0018\u00010\u000b\u00a2\u0006\b\n\u0000\u001a\u0004\b\"\u0010#R\u0011\u0010\u0002\u001a\u00020\u0003\u00a2\u0006\b\n\u0000\u001a\u0004\b$\u0010%R\u0011\u0010\u0004\u001a\u00020\u0005\u00a2\u0006\b\n\u0000\u001a\u0004\b&\u0010'R\u0011\u0010\b\u001a\u00020\t\u00a2\u0006\b\n\u0000\u001a\u0004\b(\u0010)\u00a8\u0006:"}, d2={"Ldorkbox/executor/Params;", "", "processAttributes", "Ldorkbox/executor/ProcessAttributes;", "stopper", "Ldorkbox/executor/stop/ProcessStopper;", "listener", "Ldorkbox/executor/listener/ProcessListener;", "streams", "Ldorkbox/executor/stream/IOStreamHandler;", "logger", "Lorg/slf4j/Logger;", "errorMessageHandler", "Lkotlin/Function1;", "Ljava/lang/StringBuilder;", "Lkotlin/text/StringBuilder;", "", "closeTimeout", "", "closeTimeoutUnit", "Ljava/util/concurrent/TimeUnit;", "asyncProcessStart", "", "(Ldorkbox/executor/ProcessAttributes;Ldorkbox/executor/stop/ProcessStopper;Ldorkbox/executor/listener/ProcessListener;Ldorkbox/executor/stream/IOStreamHandler;Lorg/slf4j/Logger;Lkotlin/jvm/functions/Function1;JLjava/util/concurrent/TimeUnit;Z)V", "getAsyncProcessStart", "()Z", "getCloseTimeout", "()J", "getCloseTimeoutUnit", "()Ljava/util/concurrent/TimeUnit;", "getErrorMessageHandler", "()Lkotlin/jvm/functions/Function1;", "getListener", "()Ldorkbox/executor/listener/ProcessListener;", "getLogger", "()Lorg/slf4j/Logger;", "getProcessAttributes", "()Ldorkbox/executor/ProcessAttributes;", "getStopper", "()Ldorkbox/executor/stop/ProcessStopper;", "getStreams", "()Ldorkbox/executor/stream/IOStreamHandler;", "component1", "component2", "component3", "component4", "component5", "component6", "component7", "component8", "component9", "copy", "equals", "other", "hashCode", "", "toString", "", "Executor"})
public final class Params {
    @NotNull
    private final ProcessAttributes processAttributes;
    @NotNull
    private final ProcessStopper stopper;
    @NotNull
    private final ProcessListener listener;
    @NotNull
    private final IOStreamHandler streams;
    @Nullable
    private final Logger logger;
    @NotNull
    private final Function1<StringBuilder, Unit> errorMessageHandler;
    private final long closeTimeout;
    @NotNull
    private final TimeUnit closeTimeoutUnit;
    private final boolean asyncProcessStart;

    public Params(@NotNull ProcessAttributes processAttributes, @NotNull ProcessStopper stopper, @NotNull ProcessListener listener, @NotNull IOStreamHandler streams, @Nullable Logger logger, @NotNull Function1<? super StringBuilder, Unit> errorMessageHandler, long closeTimeout, @NotNull TimeUnit closeTimeoutUnit, boolean asyncProcessStart) {
        Intrinsics.checkNotNullParameter((Object)processAttributes, (String)"processAttributes");
        Intrinsics.checkNotNullParameter((Object)stopper, (String)"stopper");
        Intrinsics.checkNotNullParameter((Object)listener, (String)"listener");
        Intrinsics.checkNotNullParameter((Object)streams, (String)"streams");
        Intrinsics.checkNotNullParameter(errorMessageHandler, (String)"errorMessageHandler");
        Intrinsics.checkNotNullParameter((Object)((Object)closeTimeoutUnit), (String)"closeTimeoutUnit");
        this.processAttributes = processAttributes;
        this.stopper = stopper;
        this.listener = listener;
        this.streams = streams;
        this.logger = logger;
        this.errorMessageHandler = errorMessageHandler;
        this.closeTimeout = closeTimeout;
        this.closeTimeoutUnit = closeTimeoutUnit;
        this.asyncProcessStart = asyncProcessStart;
    }

    @NotNull
    public final ProcessAttributes getProcessAttributes() {
        return this.processAttributes;
    }

    @NotNull
    public final ProcessStopper getStopper() {
        return this.stopper;
    }

    @NotNull
    public final ProcessListener getListener() {
        return this.listener;
    }

    @NotNull
    public final IOStreamHandler getStreams() {
        return this.streams;
    }

    @Nullable
    public final Logger getLogger() {
        return this.logger;
    }

    @NotNull
    public final Function1<StringBuilder, Unit> getErrorMessageHandler() {
        return this.errorMessageHandler;
    }

    public final long getCloseTimeout() {
        return this.closeTimeout;
    }

    @NotNull
    public final TimeUnit getCloseTimeoutUnit() {
        return this.closeTimeoutUnit;
    }

    public final boolean getAsyncProcessStart() {
        return this.asyncProcessStart;
    }

    @NotNull
    public final ProcessAttributes component1() {
        return this.processAttributes;
    }

    @NotNull
    public final ProcessStopper component2() {
        return this.stopper;
    }

    @NotNull
    public final ProcessListener component3() {
        return this.listener;
    }

    @NotNull
    public final IOStreamHandler component4() {
        return this.streams;
    }

    @Nullable
    public final Logger component5() {
        return this.logger;
    }

    @NotNull
    public final Function1<StringBuilder, Unit> component6() {
        return this.errorMessageHandler;
    }

    public final long component7() {
        return this.closeTimeout;
    }

    @NotNull
    public final TimeUnit component8() {
        return this.closeTimeoutUnit;
    }

    public final boolean component9() {
        return this.asyncProcessStart;
    }

    @NotNull
    public final Params copy(@NotNull ProcessAttributes processAttributes, @NotNull ProcessStopper stopper, @NotNull ProcessListener listener, @NotNull IOStreamHandler streams, @Nullable Logger logger, @NotNull Function1<? super StringBuilder, Unit> errorMessageHandler, long closeTimeout, @NotNull TimeUnit closeTimeoutUnit, boolean asyncProcessStart) {
        Intrinsics.checkNotNullParameter((Object)processAttributes, (String)"processAttributes");
        Intrinsics.checkNotNullParameter((Object)stopper, (String)"stopper");
        Intrinsics.checkNotNullParameter((Object)listener, (String)"listener");
        Intrinsics.checkNotNullParameter((Object)streams, (String)"streams");
        Intrinsics.checkNotNullParameter(errorMessageHandler, (String)"errorMessageHandler");
        Intrinsics.checkNotNullParameter((Object)((Object)closeTimeoutUnit), (String)"closeTimeoutUnit");
        return new Params(processAttributes, stopper, listener, streams, logger, errorMessageHandler, closeTimeout, closeTimeoutUnit, asyncProcessStart);
    }

    public static /* synthetic */ Params copy$default(Params params, ProcessAttributes processAttributes, ProcessStopper processStopper, ProcessListener processListener, IOStreamHandler iOStreamHandler, Logger logger, Function1 function1, long l, TimeUnit timeUnit, boolean bl, int n, Object object) {
        if ((n & 1) != 0) {
            processAttributes = params.processAttributes;
        }
        if ((n & 2) != 0) {
            processStopper = params.stopper;
        }
        if ((n & 4) != 0) {
            processListener = params.listener;
        }
        if ((n & 8) != 0) {
            iOStreamHandler = params.streams;
        }
        if ((n & 0x10) != 0) {
            logger = params.logger;
        }
        if ((n & 0x20) != 0) {
            function1 = params.errorMessageHandler;
        }
        if ((n & 0x40) != 0) {
            l = params.closeTimeout;
        }
        if ((n & 0x80) != 0) {
            timeUnit = params.closeTimeoutUnit;
        }
        if ((n & 0x100) != 0) {
            bl = params.asyncProcessStart;
        }
        return params.copy(processAttributes, processStopper, processListener, iOStreamHandler, logger, function1, l, timeUnit, bl);
    }

    @NotNull
    public String toString() {
        return "Params(processAttributes=" + this.processAttributes + ", stopper=" + this.stopper + ", listener=" + this.listener + ", streams=" + this.streams + ", logger=" + this.logger + ", errorMessageHandler=" + this.errorMessageHandler + ", closeTimeout=" + this.closeTimeout + ", closeTimeoutUnit=" + (Object)((Object)this.closeTimeoutUnit) + ", asyncProcessStart=" + this.asyncProcessStart + ')';
    }

    public int hashCode() {
        int result = this.processAttributes.hashCode();
        result = result * 31 + this.stopper.hashCode();
        result = result * 31 + this.listener.hashCode();
        result = result * 31 + this.streams.hashCode();
        result = result * 31 + (this.logger == null ? 0 : this.logger.hashCode());
        result = result * 31 + this.errorMessageHandler.hashCode();
        result = result * 31 + Long.hashCode(this.closeTimeout);
        result = result * 31 + this.closeTimeoutUnit.hashCode();
        int n = this.asyncProcessStart ? 1 : 0;
        if (n != 0) {
            n = 1;
        }
        result = result * 31 + n;
        return result;
    }

    public boolean equals(@Nullable Object other) {
        if (this == other) {
            return true;
        }
        if (!(other instanceof Params)) {
            return false;
        }
        Params params = (Params)other;
        if (!Intrinsics.areEqual((Object)this.processAttributes, (Object)params.processAttributes)) {
            return false;
        }
        if (!Intrinsics.areEqual((Object)this.stopper, (Object)params.stopper)) {
            return false;
        }
        if (!Intrinsics.areEqual((Object)this.listener, (Object)params.listener)) {
            return false;
        }
        if (!Intrinsics.areEqual((Object)this.streams, (Object)params.streams)) {
            return false;
        }
        if (!Intrinsics.areEqual((Object)this.logger, (Object)params.logger)) {
            return false;
        }
        if (!Intrinsics.areEqual(this.errorMessageHandler, params.errorMessageHandler)) {
            return false;
        }
        if (this.closeTimeout != params.closeTimeout) {
            return false;
        }
        if (this.closeTimeoutUnit != params.closeTimeoutUnit) {
            return false;
        }
        return this.asyncProcessStart == params.asyncProcessStart;
    }
}

