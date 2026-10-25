/*
 * Decompiled with CFR 0.152.
 * 
 * Could not load the following classes:
 *  kotlin.ExceptionsKt
 *  kotlin.Metadata
 *  kotlin.ResultKt
 *  kotlin.Unit
 *  kotlin.collections.IntIterator
 *  kotlin.coroutines.Continuation
 *  kotlin.coroutines.CoroutineContext
 *  kotlin.coroutines.intrinsics.IntrinsicsKt
 *  kotlin.coroutines.jvm.internal.ContinuationImpl
 *  kotlin.jvm.functions.Function1
 *  kotlin.jvm.functions.Function2
 *  kotlin.jvm.internal.DefaultConstructorMarker
 *  kotlin.jvm.internal.Intrinsics
 *  kotlin.ranges.RangesKt
 *  kotlinx.coroutines.BuildersKt
 *  kotlinx.coroutines.CoroutineScope
 *  kotlinx.coroutines.DelayKt
 *  kotlinx.coroutines.Dispatchers
 *  kotlinx.coroutines.Job
 *  kotlinx.coroutines.channels.Channel
 *  kotlinx.coroutines.channels.ChannelKt
 *  org.jetbrains.annotations.NotNull
 *  org.jetbrains.annotations.Nullable
 *  org.slf4j.Logger
 *  org.slf4j.LoggerFactory
 *  org.slf4j.MDC
 */
package dorkbox.executor.stream;

import dorkbox.executor.Executor;
import dorkbox.executor.stream.IOStream;
import dorkbox.executor.stream.IOStreamHandler;
import dorkbox.executor.stream.PumpStreamHandler;
import dorkbox.executor.stream.PumpedOutputChannel;
import dorkbox.executor.stream.PumpedOutputStream;
import dorkbox.executor.stream.nopStreams.NopInputStream;
import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;
import java.io.PrintStream;
import java.util.Map;
import java.util.concurrent.CancellationException;
import kotlin.ExceptionsKt;
import kotlin.Metadata;
import kotlin.ResultKt;
import kotlin.Unit;
import kotlin.collections.IntIterator;
import kotlin.coroutines.Continuation;
import kotlin.coroutines.CoroutineContext;
import kotlin.coroutines.intrinsics.IntrinsicsKt;
import kotlin.coroutines.jvm.internal.ContinuationImpl;
import kotlin.jvm.functions.Function1;
import kotlin.jvm.functions.Function2;
import kotlin.jvm.internal.DefaultConstructorMarker;
import kotlin.jvm.internal.Intrinsics;
import kotlin.ranges.RangesKt;
import kotlinx.coroutines.BuildersKt;
import kotlinx.coroutines.CoroutineScope;
import kotlinx.coroutines.DelayKt;
import kotlinx.coroutines.Dispatchers;
import kotlinx.coroutines.Job;
import kotlinx.coroutines.channels.Channel;
import kotlinx.coroutines.channels.ChannelKt;
import org.jetbrains.annotations.NotNull;
import org.jetbrains.annotations.Nullable;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.slf4j.MDC;

@Metadata(mv={1, 6, 0}, k=1, xi=48, d1={"\u0000b\n\u0002\u0018\u0002\n\u0002\u0018\u0002\n\u0000\n\u0002\u0018\u0002\n\u0002\b\u0002\n\u0002\u0018\u0002\n\u0000\n\u0002\u0010\u000b\n\u0002\b\u0002\n\u0002\u0018\u0002\n\u0002\u0010\u0005\n\u0002\b\u0003\n\u0002\u0018\u0002\n\u0002\b\u0003\n\u0002\u0018\u0002\n\u0002\b\u0004\n\u0002\u0018\u0002\n\u0002\b\u0003\n\u0002\u0010\u0002\n\u0000\n\u0002\u0018\u0002\n\u0002\b\b\n\u0002\u0018\u0002\n\u0002\u0018\u0002\n\u0002\u0010\u0000\n\u0002\b\u0005\u0018\u0000 .2\u00020\u0001:\u0001.B-\u0012\b\b\u0002\u0010\u0002\u001a\u00020\u0003\u0012\b\b\u0002\u0010\u0004\u001a\u00020\u0003\u0012\b\b\u0002\u0010\u0005\u001a\u00020\u0006\u0012\b\b\u0002\u0010\u0007\u001a\u00020\b\u00a2\u0006\u0002\u0010\tJ\u0018\u0010\u0018\u001a\u00020\u00192\b\u0010\u001a\u001a\u0004\u0018\u00010\u00192\u0006\u0010\u001b\u001a\u00020\u0019J!\u0010\u001c\u001a\u00020\u001d2\u0006\u0010\u001e\u001a\u00020\u001f2\u0006\u0010 \u001a\u00020\bH\u0082@\u00f8\u0001\u0000\u00a2\u0006\u0002\u0010!J\u0019\u0010\"\u001a\u00020\u001d2\u0006\u0010\u001e\u001a\u00020\u001fH\u0082@\u00f8\u0001\u0000\u00a2\u0006\u0002\u0010#J\u0019\u0010$\u001a\u00020\u001d2\u0006\u0010\u001e\u001a\u00020\u001fH\u0082@\u00f8\u0001\u0000\u00a2\u0006\u0002\u0010#J\u0019\u0010%\u001a\u00020\u001d2\u0006\u0010\u001e\u001a\u00020\u001fH\u0082@\u00f8\u0001\u0000\u00a2\u0006\u0002\u0010#J.\u0010&\u001a\u00020\u00142\u001c\u0010'\u001a\u0018\b\u0001\u0012\n\u0012\b\u0012\u0004\u0012\u00020\u001d0)\u0012\u0006\u0012\u0004\u0018\u00010*0(H\u0002\u00f8\u0001\u0000\u00a2\u0006\u0002\u0010+J \u0010,\u001a\u00020\u001d2\u0006\u0010\u001e\u001a\u00020\u001f2\u0006\u0010 \u001a\u00020\b2\u0006\u0010-\u001a\u00020\bH\u0016J!\u0010\u0017\u001a\u00020\u001d2\u0006\u0010\u001e\u001a\u00020\u001f2\u0006\u0010\u0011\u001a\u00020\bH\u0096@\u00f8\u0001\u0000\u00a2\u0006\u0002\u0010!R\u001a\u0010\n\u001a\b\u0012\u0004\u0012\u00020\f0\u000bX\u0080\u0004\u00a2\u0006\b\n\u0000\u001a\u0004\b\r\u0010\u000eR\u000e\u0010\u000f\u001a\u00020\u0010X\u0082\u0004\u00a2\u0006\u0002\n\u0000R\u000e\u0010\u0011\u001a\u00020\bX\u0082\u000e\u00a2\u0006\u0002\n\u0000R\u000e\u0010\u0012\u001a\u00020\u0010X\u0082\u0004\u00a2\u0006\u0002\n\u0000R\u000e\u0010\u0013\u001a\u00020\u0014X\u0082.\u00a2\u0006\u0002\n\u0000R\u0010\u0010\u0015\u001a\u0004\u0018\u00010\u0014X\u0082\u000e\u00a2\u0006\u0002\n\u0000R\u0010\u0010\u0016\u001a\u0004\u0018\u00010\u0014X\u0082\u000e\u00a2\u0006\u0002\n\u0000R\u000e\u0010\u0017\u001a\u00020\bX\u0082\u000e\u00a2\u0006\u0002\n\u0000\u0082\u0002\u0004\n\u0002\b\u0019\u00a8\u0006/"}, d2={"Ldorkbox/executor/stream/PumpStreamHandler;", "Ldorkbox/executor/stream/IOStreamHandler;", "out", "Ljava/io/OutputStream;", "err", "input", "Ljava/io/InputStream;", "asyncSupport", "", "(Ljava/io/OutputStream;Ljava/io/OutputStream;Ljava/io/InputStream;Z)V", "channel", "Lkotlinx/coroutines/channels/Channel;", "", "getChannel$Executor", "()Lkotlinx/coroutines/channels/Channel;", "error", "Ldorkbox/executor/stream/IOStream;", "finishedCleanly", "output", "pumpJob", "Lkotlinx/coroutines/Job;", "pumpJobB", "pumpJobC", "stop", "add", "Ljava/io/IOException;", "exception", "newException", "runAllSingleThread", "", "process", "Ljava/lang/Process;", "separateErrorStream", "(Ljava/lang/Process;ZLkotlin/coroutines/Continuation;)Ljava/lang/Object;", "runErrThread", "(Ljava/lang/Process;Lkotlin/coroutines/Continuation;)Ljava/lang/Object;", "runInThread", "runOutThread", "runWithContext", "action", "Lkotlin/Function1;", "Lkotlin/coroutines/Continuation;", "", "(Lkotlin/jvm/functions/Function1;)Lkotlinx/coroutines/Job;", "start", "highPerformanceIO", "Companion", "Executor"})
public final class PumpStreamHandler
extends IOStreamHandler {
    @NotNull
    public static final Companion Companion = new Companion(null);
    private volatile boolean stop;
    private volatile boolean finishedCleanly;
    private Job pumpJob;
    @Nullable
    private Job pumpJobB;
    @Nullable
    private Job pumpJobC;
    @NotNull
    private final Channel<Byte> channel;
    @NotNull
    private final IOStream output;
    @NotNull
    private final IOStream error;
    private static final Logger log = LoggerFactory.getLogger(PumpStreamHandler.class);
    public static final int DEFAULT_SIZE = 1024;
    public static final long POLL_TIMEOUT = 250L;

    public PumpStreamHandler(@NotNull OutputStream out, @NotNull OutputStream err, @NotNull InputStream input, boolean asyncSupport) {
        Intrinsics.checkNotNullParameter((Object)out, (String)"out");
        Intrinsics.checkNotNullParameter((Object)err, (String)"err");
        Intrinsics.checkNotNullParameter((Object)input, (String)"input");
        super(out, err, input, asyncSupport);
        this.channel = ChannelKt.Channel$default((int)1024, null, null, (int)6, null);
        if (asyncSupport) {
            this.output = new PumpedOutputChannel(this.channel);
            this.error = new PumpedOutputChannel(this.channel);
        } else {
            this.output = PumpedOutputStream.box-impl(PumpedOutputStream.constructor-impl(out));
            this.error = PumpedOutputStream.box-impl(PumpedOutputStream.constructor-impl(err));
        }
    }

    public /* synthetic */ PumpStreamHandler(OutputStream outputStream, OutputStream outputStream2, InputStream inputStream, boolean bl, int n, DefaultConstructorMarker defaultConstructorMarker) {
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
    public final Channel<Byte> getChannel$Executor() {
        return this.channel;
    }

    private final Job runWithContext(Function1<? super Continuation<? super Unit>, ? extends Object> action) {
        Map contextMap = MDC.getCopyOfContextMap();
        return contextMap != null ? BuildersKt.launch$default((CoroutineScope)Executor.Companion.getIO_DISPATCH$Executor(), null, null, (Function2)((Function2)new Function2<CoroutineScope, Continuation<? super Unit>, Object>((Map<String, String>)contextMap, action, null){
            int label;
            final /* synthetic */ Map<String, String> $contextMap;
            final /* synthetic */ Function1<Continuation<? super Unit>, Object> $action;
            {
                this.$contextMap = $contextMap;
                this.$action = $action;
                super(2, $completion);
            }

            /*
             * WARNING - Removed try catching itself - possible behaviour change.
             * WARNING - void declaration
             * Enabled force condition propagation
             * Lifted jumps to return sites
             */
            @Nullable
            public final Object invokeSuspend(@NotNull Object object) {
                Object object2 = IntrinsicsKt.getCOROUTINE_SUSPENDED();
                switch (this.label) {
                    case 0: {
                        ResultKt.throwOnFailure((Object)object);
                        MDC.setContextMap(this.$contextMap);
                        this.label = 1;
                        Object object3 = this.$action.invoke((Object)((Object)this));
                        if (object3 != object2) return Unit.INSTANCE;
                        return object2;
                    }
                    case 1: {
                        Object object3;
                        try {
                            void $result;
                            ResultKt.throwOnFailure((Object)$result);
                            object3 = $result;
                            return Unit.INSTANCE;
                        }
                        catch (Throwable throwable) {
                            throw throwable;
                        }
                        finally {
                            MDC.clear();
                        }
                    }
                }
                throw new IllegalStateException("call to 'resume' before 'invoke' with coroutine");
            }

            @NotNull
            public final Continuation<Unit> create(@Nullable Object value, @NotNull Continuation<?> $completion) {
                return (Continuation)new /* invalid duplicate definition of identical inner class */;
            }

            @Nullable
            public final Object invoke(@NotNull CoroutineScope p1, @Nullable Continuation<? super Unit> p2) {
                return (this.create(p1, p2)).invokeSuspend(Unit.INSTANCE);
            }
        }), (int)3, null) : BuildersKt.launch$default((CoroutineScope)Executor.Companion.getIO_DISPATCH$Executor(), null, null, (Function2)((Function2)new Function2<CoroutineScope, Continuation<? super Unit>, Object>(action, null){
            int label;
            final /* synthetic */ Function1<Continuation<? super Unit>, Object> $action;
            {
                this.$action = $action;
                super(2, $completion);
            }

            /*
             * WARNING - void declaration
             * Enabled force condition propagation
             * Lifted jumps to return sites
             */
            @Nullable
            public final Object invokeSuspend(@NotNull Object object) {
                Object object2 = IntrinsicsKt.getCOROUTINE_SUSPENDED();
                switch (this.label) {
                    case 0: {
                        ResultKt.throwOnFailure((Object)object);
                        this.label = 1;
                        Object object3 = this.$action.invoke((Object)((Object)this));
                        if (object3 != object2) return Unit.INSTANCE;
                        return object2;
                    }
                    case 1: {
                        void $result;
                        ResultKt.throwOnFailure((Object)$result);
                        Object object3 = $result;
                        return Unit.INSTANCE;
                    }
                }
                throw new IllegalStateException("call to 'resume' before 'invoke' with coroutine");
            }

            @NotNull
            public final Continuation<Unit> create(@Nullable Object value, @NotNull Continuation<?> $completion) {
                return (Continuation)new /* invalid duplicate definition of identical inner class */;
            }

            @Nullable
            public final Object invoke(@NotNull CoroutineScope p1, @Nullable Continuation<? super Unit> p2) {
                return (this.create(p1, p2)).invokeSuspend(Unit.INSTANCE);
            }
        }), (int)3, null);
    }

    @Override
    public void start(@NotNull Process process, boolean separateErrorStream, boolean highPerformanceIO) {
        Intrinsics.checkNotNullParameter((Object)process, (String)"process");
        if (highPerformanceIO) {
            this.pumpJob = this.runWithContext((Function1<? super Continuation<? super Unit>, ? extends Object>)((Function1)new Function1<Continuation<? super Unit>, Object>(this, process, null){
                int label;
                final /* synthetic */ PumpStreamHandler this$0;
                final /* synthetic */ Process $process;
                {
                    this.this$0 = $receiver;
                    this.$process = $process;
                    super(1, $completion);
                }

                /*
                 * WARNING - void declaration
                 * Enabled force condition propagation
                 * Lifted jumps to return sites
                 */
                @Nullable
                public final Object invokeSuspend(@NotNull Object object) {
                    Object object2 = IntrinsicsKt.getCOROUTINE_SUSPENDED();
                    switch (this.label) {
                        case 0: {
                            ResultKt.throwOnFailure((Object)object);
                            this.label = 1;
                            Object object3 = PumpStreamHandler.access$runInThread(this.this$0, this.$process, (Continuation)this);
                            if (object3 != object2) return Unit.INSTANCE;
                            return object2;
                        }
                        case 1: {
                            void $result;
                            ResultKt.throwOnFailure((Object)$result);
                            Object object3 = $result;
                            return Unit.INSTANCE;
                        }
                    }
                    throw new IllegalStateException("call to 'resume' before 'invoke' with coroutine");
                }

                @NotNull
                public final Continuation<Unit> create(@NotNull Continuation<?> $completion) {
                    return (Continuation)new /* invalid duplicate definition of identical inner class */;
                }

                @Nullable
                public final Object invoke(@Nullable Continuation<? super Unit> p1) {
                    return (this.create(p1)).invokeSuspend(Unit.INSTANCE);
                }
            }));
            this.pumpJobB = this.runWithContext((Function1<? super Continuation<? super Unit>, ? extends Object>)((Function1)new Function1<Continuation<? super Unit>, Object>(this, process, null){
                int label;
                final /* synthetic */ PumpStreamHandler this$0;
                final /* synthetic */ Process $process;
                {
                    this.this$0 = $receiver;
                    this.$process = $process;
                    super(1, $completion);
                }

                /*
                 * WARNING - void declaration
                 * Enabled force condition propagation
                 * Lifted jumps to return sites
                 */
                @Nullable
                public final Object invokeSuspend(@NotNull Object object) {
                    Object object2 = IntrinsicsKt.getCOROUTINE_SUSPENDED();
                    switch (this.label) {
                        case 0: {
                            ResultKt.throwOnFailure((Object)object);
                            this.label = 1;
                            Object object3 = PumpStreamHandler.access$runOutThread(this.this$0, this.$process, (Continuation)this);
                            if (object3 != object2) return Unit.INSTANCE;
                            return object2;
                        }
                        case 1: {
                            void $result;
                            ResultKt.throwOnFailure((Object)$result);
                            Object object3 = $result;
                            return Unit.INSTANCE;
                        }
                    }
                    throw new IllegalStateException("call to 'resume' before 'invoke' with coroutine");
                }

                @NotNull
                public final Continuation<Unit> create(@NotNull Continuation<?> $completion) {
                    return (Continuation)new /* invalid duplicate definition of identical inner class */;
                }

                @Nullable
                public final Object invoke(@Nullable Continuation<? super Unit> p1) {
                    return (this.create(p1)).invokeSuspend(Unit.INSTANCE);
                }
            }));
            if (separateErrorStream) {
                this.pumpJobC = this.runWithContext((Function1<? super Continuation<? super Unit>, ? extends Object>)((Function1)new Function1<Continuation<? super Unit>, Object>(this, process, null){
                    int label;
                    final /* synthetic */ PumpStreamHandler this$0;
                    final /* synthetic */ Process $process;
                    {
                        this.this$0 = $receiver;
                        this.$process = $process;
                        super(1, $completion);
                    }

                    /*
                     * WARNING - void declaration
                     * Enabled force condition propagation
                     * Lifted jumps to return sites
                     */
                    @Nullable
                    public final Object invokeSuspend(@NotNull Object object) {
                        Object object2 = IntrinsicsKt.getCOROUTINE_SUSPENDED();
                        switch (this.label) {
                            case 0: {
                                ResultKt.throwOnFailure((Object)object);
                                this.label = 1;
                                Object object3 = PumpStreamHandler.access$runErrThread(this.this$0, this.$process, (Continuation)this);
                                if (object3 != object2) return Unit.INSTANCE;
                                return object2;
                            }
                            case 1: {
                                void $result;
                                ResultKt.throwOnFailure((Object)$result);
                                Object object3 = $result;
                                return Unit.INSTANCE;
                            }
                        }
                        throw new IllegalStateException("call to 'resume' before 'invoke' with coroutine");
                    }

                    @NotNull
                    public final Continuation<Unit> create(@NotNull Continuation<?> $completion) {
                        return (Continuation)new /* invalid duplicate definition of identical inner class */;
                    }

                    @Nullable
                    public final Object invoke(@Nullable Continuation<? super Unit> p1) {
                        return (this.create(p1)).invokeSuspend(Unit.INSTANCE);
                    }
                }));
            }
        } else {
            this.pumpJob = this.runWithContext((Function1<? super Continuation<? super Unit>, ? extends Object>)((Function1)new Function1<Continuation<? super Unit>, Object>(this, process, separateErrorStream, null){
                int label;
                final /* synthetic */ PumpStreamHandler this$0;
                final /* synthetic */ Process $process;
                final /* synthetic */ boolean $separateErrorStream;
                {
                    this.this$0 = $receiver;
                    this.$process = $process;
                    this.$separateErrorStream = $separateErrorStream;
                    super(1, $completion);
                }

                /*
                 * WARNING - void declaration
                 * Enabled force condition propagation
                 * Lifted jumps to return sites
                 */
                @Nullable
                public final Object invokeSuspend(@NotNull Object object) {
                    Object object2 = IntrinsicsKt.getCOROUTINE_SUSPENDED();
                    switch (this.label) {
                        case 0: {
                            ResultKt.throwOnFailure((Object)object);
                            this.label = 1;
                            Object object3 = PumpStreamHandler.access$runAllSingleThread(this.this$0, this.$process, this.$separateErrorStream, (Continuation)this);
                            if (object3 != object2) return Unit.INSTANCE;
                            return object2;
                        }
                        case 1: {
                            void $result;
                            ResultKt.throwOnFailure((Object)$result);
                            Object object3 = $result;
                            return Unit.INSTANCE;
                        }
                    }
                    throw new IllegalStateException("call to 'resume' before 'invoke' with coroutine");
                }

                @NotNull
                public final Continuation<Unit> create(@NotNull Continuation<?> $completion) {
                    return (Continuation)new /* invalid duplicate definition of identical inner class */;
                }

                @Nullable
                public final Object invoke(@Nullable Continuation<? super Unit> p1) {
                    return (this.create(p1)).invokeSuspend(Unit.INSTANCE);
                }
            }));
        }
    }

    private final Object runAllSingleThread(Process process, boolean separateErrorStream, Continuation<? super Unit> $completion) {
        Object object = BuildersKt.withContext((CoroutineContext)((CoroutineContext)Dispatchers.getIO()), (Function2)((Function2)new Function2<CoroutineScope, Continuation<? super Unit>, Object>(process, separateErrorStream, this, null){
            int I$0;
            Object L$0;
            Object L$1;
            Object L$2;
            int label;
            final /* synthetic */ Process $process;
            final /* synthetic */ boolean $separateErrorStream;
            final /* synthetic */ PumpStreamHandler this$0;
            {
                this.$process = $process;
                this.$separateErrorStream = $separateErrorStream;
                this.this$0 = $receiver;
                super(2, $completion);
            }

            /*
             * WARNING - Removed back jump from a try to a catch block - possible behaviour change.
             * Unable to fully structure code
             * Enabled aggressive block sorting
             * Enabled unnecessary exception pruning
             * Enabled aggressive exception aggregation
             */
            @Nullable
            public final Object invokeSuspend(@NotNull Object var1_1) {
                var13_2 = IntrinsicsKt.getCOROUTINE_SUSPENDED();
                switch (this.label) {
                    case 0: {
                        ResultKt.throwOnFailure((Object)var1_1);
                        try {
                            var7_3 /* !! */  = this.$process.getOutputStream();
                            Intrinsics.checkNotNullExpressionValue((Object)var7_3 /* !! */ , (String)"process.outputStream");
                            processIn = var7_3 /* !! */ ;
                            var7_3 /* !! */  = this.$process.getInputStream();
                            Intrinsics.checkNotNullExpressionValue((Object)var7_3 /* !! */ , (String)"process.inputStream");
                            processOut = var7_3 /* !! */ ;
                            if (this.$separateErrorStream) {
                                var7_3 /* !! */  = this.$process.getErrorStream();
                                Intrinsics.checkNotNullExpressionValue((Object)var7_3 /* !! */ , (String)"{\n                proces\u2026errorStream\n            }");
                                v0 /* !! */  = var7_3 /* !! */ ;
                            } else {
                                v0 /* !! */  = processOut;
                            }
                            processErr = v0 /* !! */ ;
                        }
                        catch (IOException e) {
                            this.$process.destroy();
                            throw e;
                        }
                        try {
                        }
                        catch (CancellationException var7_8) {
                            // empty catch block
                            return Unit.INSTANCE;
                        }
lbl31:
                        // 5 sources

                        while (true) {
                            readData = 0;
                            try {
                                e = this.this$0.getInput$Executor().available();
                            }
                            catch (Exception var8_15) {
                                e = 0;
                            }
                            length = e;
                            if (length > 0) {
                                readData = 1;
                                e = (Iterable)RangesKt.until((int)0, (int)RangesKt.coerceAtMost((int)length, (int)1024));
                                var8_14 = this.this$0;
                                $i$f$forEach = false;
                                var10_19 = $this$forEach$iv.iterator();
                                while (var10_19.hasNext()) {
                                    element$iv = ((IntIterator)var10_19).nextInt();
                                    $i$a$-forEach-PumpStreamHandler$runAllSingleThread$2$1 = false;
                                    processIn.write(var8_14.getInput$Executor().read());
                                }
                                processIn.flush();
                            }
                            try {
                                var7_7 = processOut.available();
                            }
                            catch (Exception var8_16) {
                                var7_7 = 0;
                            }
                            length = var7_7;
                            if (length > 0) {
                                readData = 1;
                                this.L$0 = processIn;
                                this.L$1 = processOut;
                                this.L$2 = processErr;
                                this.I$0 = readData;
                                this.label = 1;
                                v1 = PumpStreamHandler.access$getOutput$p(this.this$0).pump(length, (InputStream)processOut, (Continuation<? super Unit>)((Continuation)this));
                                if (v1 == var13_2) {
                                    return var13_2;
                                }
                            }
                            ** GOTO lbl79
                            break;
                        }
                    }
                    case 1: {
                        readData = this.I$0;
                        processErr = (InputStream)this.L$2;
                        processOut = (InputStream)this.L$1;
                        processIn = (OutputStream)this.L$0;
                        {
                            ResultKt.throwOnFailure((Object)$result);
                            v1 = $result;
lbl79:
                            // 2 sources

                            if (processErr == processOut) ** GOTO lbl106
                            try {
                                var7_7 = processErr.available();
                            }
                            catch (Exception var8_17) {
                                var7_7 = 0;
                            }
                            length = var7_7;
                            if (length <= 0) ** GOTO lbl106
                            readData = 1;
                            this.L$0 = processIn;
                            this.L$1 = processOut;
                            this.L$2 = processErr;
                            this.I$0 = readData;
                            this.label = 2;
                            v2 = PumpStreamHandler.access$getError$p(this.this$0).pump(length, processErr, (Continuation<? super Unit>)((Continuation)this));
                            ** if (v2 != var13_2) goto lbl97
                        }
lbl96:
                        // 1 sources

                        return var13_2;
lbl97:
                        // 1 sources

                        ** GOTO lbl106
                    }
                    case 2: {
                        readData = this.I$0;
                        processErr = (InputStream)this.L$2;
                        processOut = (InputStream)this.L$1;
                        processIn = (OutputStream)this.L$0;
                        {
                            ResultKt.throwOnFailure((Object)$result);
                            v2 = $result;
lbl106:
                            // 4 sources

                            if (!PumpStreamHandler.access$getStop$p(this.this$0)) ** GOTO lbl111
                            if (!PumpStreamHandler.access$getFinishedCleanly$p(this.this$0)) {
                                return Unit.INSTANCE;
                            }
                            if (readData == 0) return Unit.INSTANCE;
                            ** GOTO lbl31
lbl111:
                            // 1 sources

                            if (readData != 0) ** GOTO lbl31
                            this.L$0 = processIn;
                            this.L$1 = processOut;
                            this.L$2 = processErr;
                            this.label = 3;
                            v3 = DelayKt.delay((long)250L, (Continuation)((Continuation)this));
                            if (v3 != var13_2) ** GOTO lbl31
                        }
                        return var13_2;
                    }
                    case 3: {
                        processErr = (InputStream)this.L$2;
                        processOut = (InputStream)this.L$1;
                        processIn = (OutputStream)this.L$0;
                        {
                            ResultKt.throwOnFailure((Object)$result);
                            v3 = $result;
                            ** continue;
                        }
                    }
                }
                throw new IllegalStateException("call to 'resume' before 'invoke' with coroutine");
            }

            @NotNull
            public final Continuation<Unit> create(@Nullable Object value, @NotNull Continuation<?> $completion) {
                return (Continuation)new /* invalid duplicate definition of identical inner class */;
            }

            @Nullable
            public final Object invoke(@NotNull CoroutineScope p1, @Nullable Continuation<? super Unit> p2) {
                return (this.create(p1, p2)).invokeSuspend(Unit.INSTANCE);
            }
        }), $completion);
        if (object == IntrinsicsKt.getCOROUTINE_SUSPENDED()) {
            return object;
        }
        return Unit.INSTANCE;
    }

    private final Object runInThread(Process process, Continuation<? super Unit> $completion) {
        Object object = BuildersKt.withContext((CoroutineContext)((CoroutineContext)Dispatchers.getIO()), (Function2)((Function2)new Function2<CoroutineScope, Continuation<? super Unit>, Object>(process, this, null){
            Object L$0;
            Object L$1;
            int label;
            final /* synthetic */ Process $process;
            final /* synthetic */ PumpStreamHandler this$0;
            {
                this.$process = $process;
                this.this$0 = $receiver;
                super(2, $completion);
            }

            /*
             * WARNING - void declaration
             * Enabled aggressive block sorting
             * Enabled unnecessary exception pruning
             * Enabled aggressive exception aggregation
             */
            @Nullable
            public final Object invokeSuspend(@NotNull Object object) {
                Object object2;
                OutputStream processIn;
                byte[] buf;
                Object object3 = IntrinsicsKt.getCOROUTINE_SUSPENDED();
                switch (this.label) {
                    case 0: {
                        ResultKt.throwOnFailure((Object)object);
                        buf = new byte[1024];
                        try {
                            OutputStream outputStream = this.$process.getOutputStream();
                            Intrinsics.checkNotNullExpressionValue((Object)outputStream, (String)"process.outputStream");
                            processIn = outputStream;
                        }
                        catch (IOException e) {
                            this.$process.destroy();
                            throw e;
                        }
                        break;
                    }
                    case 1: {
                        processIn = (OutputStream)this.L$1;
                        buf = (byte[])this.L$0;
                        try {
                            void $result;
                            ResultKt.throwOnFailure((Object)$result);
                            object2 = $result;
                            break;
                        }
                        catch (CancellationException cancellationException) {
                            // empty catch block
                        }
                        return Unit.INSTANCE;
                    }
                    default: {
                        throw new IllegalStateException("call to 'resume' before 'invoke' with coroutine");
                    }
                }
                while (true) {
                    int n;
                    boolean readData = false;
                    try {
                        n = this.this$0.getInput$Executor().available();
                    }
                    catch (Exception exception) {
                        n = 0;
                    }
                    int length = n;
                    if (length > 0) {
                        readData = true;
                        length = this.this$0.getInput$Executor().read(buf, 0, RangesKt.coerceAtMost((int)length, (int)1024));
                        processIn.write(buf, 0, length);
                        processIn.flush();
                    }
                    if (PumpStreamHandler.access$getStop$p(this.this$0)) {
                        if (!PumpStreamHandler.access$getFinishedCleanly$p(this.this$0)) {
                            return Unit.INSTANCE;
                        }
                        if (!readData) return Unit.INSTANCE;
                        continue;
                    }
                    if (readData) continue;
                    this.L$0 = buf;
                    this.L$1 = processIn;
                    this.label = 1;
                    object2 = DelayKt.delay((long)250L, (Continuation)((Continuation)this));
                    if (object2 == object3) break;
                }
                return object3;
            }

            @NotNull
            public final Continuation<Unit> create(@Nullable Object value, @NotNull Continuation<?> $completion) {
                return (Continuation)new /* invalid duplicate definition of identical inner class */;
            }

            @Nullable
            public final Object invoke(@NotNull CoroutineScope p1, @Nullable Continuation<? super Unit> p2) {
                return (this.create(p1, p2)).invokeSuspend(Unit.INSTANCE);
            }
        }), $completion);
        if (object == IntrinsicsKt.getCOROUTINE_SUSPENDED()) {
            return object;
        }
        return Unit.INSTANCE;
    }

    private final Object runOutThread(Process process, Continuation<? super Unit> $completion) {
        Object object = BuildersKt.withContext((CoroutineContext)((CoroutineContext)Dispatchers.getIO()), (Function2)((Function2)new Function2<CoroutineScope, Continuation<? super Unit>, Object>(process, this, null){
            int I$0;
            Object L$0;
            int label;
            final /* synthetic */ Process $process;
            final /* synthetic */ PumpStreamHandler this$0;
            {
                this.$process = $process;
                this.this$0 = $receiver;
                super(2, $completion);
            }

            /*
             * WARNING - Removed back jump from a try to a catch block - possible behaviour change.
             * Unable to fully structure code
             * Enabled aggressive block sorting
             * Enabled unnecessary exception pruning
             * Enabled aggressive exception aggregation
             */
            @Nullable
            public final Object invokeSuspend(@NotNull Object var1_1) {
                var7_2 = IntrinsicsKt.getCOROUTINE_SUSPENDED();
                switch (this.label) {
                    case 0: {
                        ResultKt.throwOnFailure((Object)var1_1);
                        try {
                            var5_3 = this.$process.getInputStream();
                            Intrinsics.checkNotNullExpressionValue((Object)var5_3, (String)"process.inputStream");
                            processOut = var5_3;
                        }
                        catch (IOException e) {
                            this.$process.destroy();
                            throw e;
                        }
                        try {
                        }
                        catch (CancellationException var5_6) {
                            PumpStreamHandler.access$getLog$cp().error("pow");
                            return Unit.INSTANCE;
                        }
lbl21:
                        // 5 sources

                        while (true) {
                            readData = 0;
                            try {
                                var5_5 = processOut.available();
                            }
                            catch (Exception var6_10) {
                                var5_5 = 0;
                            }
                            length = var5_5;
                            if (length > 0) {
                                readData = 1;
                                this.L$0 = processOut;
                                this.I$0 = readData;
                                this.label = 1;
                                v0 = PumpStreamHandler.access$getOutput$p(this.this$0).pump(length, processOut, (Continuation<? super Unit>)((Continuation)this));
                                if (v0 == var7_2) {
                                    return var7_2;
                                }
                            }
                            ** GOTO lbl45
                            break;
                        }
                    }
                    case 1: {
                        readData = this.I$0;
                        processOut = (InputStream)this.L$0;
                        {
                            ResultKt.throwOnFailure((Object)$result);
                            v0 = $result;
lbl45:
                            // 2 sources

                            if (!PumpStreamHandler.access$getStop$p(this.this$0)) ** GOTO lbl50
                            if (!PumpStreamHandler.access$getFinishedCleanly$p(this.this$0)) {
                                return Unit.INSTANCE;
                            }
                            if (readData == 0) return Unit.INSTANCE;
                            ** GOTO lbl21
lbl50:
                            // 1 sources

                            if (readData != 0) ** GOTO lbl21
                            this.L$0 = processOut;
                            this.label = 2;
                            v1 = DelayKt.delay((long)250L, (Continuation)((Continuation)this));
                            if (v1 != var7_2) ** GOTO lbl21
                        }
                        return var7_2;
                    }
                    case 2: {
                        processOut = (InputStream)this.L$0;
                        {
                            ResultKt.throwOnFailure((Object)$result);
                            v1 = $result;
                            ** continue;
                        }
                    }
                }
                throw new IllegalStateException("call to 'resume' before 'invoke' with coroutine");
            }

            @NotNull
            public final Continuation<Unit> create(@Nullable Object value, @NotNull Continuation<?> $completion) {
                return (Continuation)new /* invalid duplicate definition of identical inner class */;
            }

            @Nullable
            public final Object invoke(@NotNull CoroutineScope p1, @Nullable Continuation<? super Unit> p2) {
                return (this.create(p1, p2)).invokeSuspend(Unit.INSTANCE);
            }
        }), $completion);
        if (object == IntrinsicsKt.getCOROUTINE_SUSPENDED()) {
            return object;
        }
        return Unit.INSTANCE;
    }

    private final Object runErrThread(Process process, Continuation<? super Unit> $completion) {
        Object object = BuildersKt.withContext((CoroutineContext)((CoroutineContext)Dispatchers.getIO()), (Function2)((Function2)new Function2<CoroutineScope, Continuation<? super Unit>, Object>(process, this, null){
            int I$0;
            Object L$0;
            int label;
            final /* synthetic */ Process $process;
            final /* synthetic */ PumpStreamHandler this$0;
            {
                this.$process = $process;
                this.this$0 = $receiver;
                super(2, $completion);
            }

            /*
             * WARNING - Removed back jump from a try to a catch block - possible behaviour change.
             * Unable to fully structure code
             * Enabled aggressive block sorting
             * Enabled unnecessary exception pruning
             * Enabled aggressive exception aggregation
             */
            @Nullable
            public final Object invokeSuspend(@NotNull Object var1_1) {
                var7_2 = IntrinsicsKt.getCOROUTINE_SUSPENDED();
                switch (this.label) {
                    case 0: {
                        ResultKt.throwOnFailure((Object)var1_1);
                        try {
                            var5_3 = this.$process.getErrorStream();
                            Intrinsics.checkNotNullExpressionValue((Object)var5_3, (String)"process.errorStream");
                            processErr = var5_3;
                        }
                        catch (IOException e) {
                            this.$process.destroy();
                            throw e;
                        }
                        try {
                        }
                        catch (CancellationException var5_6) {
                            // empty catch block
                            return Unit.INSTANCE;
                        }
lbl21:
                        // 5 sources

                        while (true) {
                            readData = 0;
                            try {
                                var5_5 = processErr.available();
                            }
                            catch (Exception var6_10) {
                                var5_5 = 0;
                            }
                            length = var5_5;
                            if (length > 0) {
                                readData = 1;
                                this.L$0 = processErr;
                                this.I$0 = readData;
                                this.label = 1;
                                v0 = PumpStreamHandler.access$getError$p(this.this$0).pump(length, processErr, (Continuation<? super Unit>)((Continuation)this));
                                if (v0 == var7_2) {
                                    return var7_2;
                                }
                            }
                            ** GOTO lbl45
                            break;
                        }
                    }
                    case 1: {
                        readData = this.I$0;
                        processErr = (InputStream)this.L$0;
                        {
                            ResultKt.throwOnFailure((Object)$result);
                            v0 = $result;
lbl45:
                            // 2 sources

                            if (!PumpStreamHandler.access$getStop$p(this.this$0)) ** GOTO lbl50
                            if (!PumpStreamHandler.access$getFinishedCleanly$p(this.this$0)) {
                                return Unit.INSTANCE;
                            }
                            if (readData == 0) return Unit.INSTANCE;
                            ** GOTO lbl21
lbl50:
                            // 1 sources

                            if (readData != 0) ** GOTO lbl21
                            this.L$0 = processErr;
                            this.label = 2;
                            v1 = DelayKt.delay((long)250L, (Continuation)((Continuation)this));
                            if (v1 != var7_2) ** GOTO lbl21
                        }
                        return var7_2;
                    }
                    case 2: {
                        processErr = (InputStream)this.L$0;
                        {
                            ResultKt.throwOnFailure((Object)$result);
                            v1 = $result;
                            ** continue;
                        }
                    }
                }
                throw new IllegalStateException("call to 'resume' before 'invoke' with coroutine");
            }

            @NotNull
            public final Continuation<Unit> create(@Nullable Object value, @NotNull Continuation<?> $completion) {
                return (Continuation)new /* invalid duplicate definition of identical inner class */;
            }

            @Nullable
            public final Object invoke(@NotNull CoroutineScope p1, @Nullable Continuation<? super Unit> p2) {
                return (this.create(p1, p2)).invokeSuspend(Unit.INSTANCE);
            }
        }), $completion);
        if (object == IntrinsicsKt.getCOROUTINE_SUSPENDED()) {
            return object;
        }
        return Unit.INSTANCE;
    }

    /*
     * Unable to fully structure code
     */
    @Override
    @Nullable
    public Object stop(@NotNull Process var1_1, boolean var2_2, @NotNull Continuation<? super Unit> var3_3) {
        if (!(var3_3 instanceof stop.1)) ** GOTO lbl-1000
        var7_4 = var3_3;
        if ((var7_4.label & -2147483648) != 0) {
            var7_4.label -= -2147483648;
        } else lbl-1000:
        // 2 sources

        {
            $continuation = new ContinuationImpl(this, var3_3){
                Object L$0;
                Object L$1;
                /* synthetic */ Object result;
                final /* synthetic */ PumpStreamHandler this$0;
                int label;
                {
                    this.this$0 = this$0;
                    super($completion);
                }

                @Nullable
                public final Object invokeSuspend(@NotNull Object $result) {
                    this.result = $result;
                    this.label |= Integer.MIN_VALUE;
                    return this.this$0.stop(null, false, (Continuation<? super Unit>)((Continuation)this));
                }
            };
        }
        $result = $continuation.result;
        var8_6 = IntrinsicsKt.getCOROUTINE_SUSPENDED();
        switch ($continuation.label) {
            case 0: {
                ResultKt.throwOnFailure((Object)$result);
                this.stop = true;
                this.finishedCleanly = finishedCleanly != false;
                PumpStreamHandler.log.trace("waiting for IO pump job");
                v0 = this.pumpJob;
                if (v0 == null) {
                    Intrinsics.throwUninitializedPropertyAccessException((String)"pumpJob");
                    v0 = null;
                }
                $continuation.L$0 = this;
                $continuation.L$1 = process;
                $continuation.label = 1;
                v1 = v0.join((Continuation)$continuation);
                ** if (v1 != var8_6) goto lbl27
lbl26:
                // 1 sources

                return var8_6;
lbl27:
                // 1 sources

                ** GOTO lbl39
            }
            case 1: {
                process = (Process)$continuation.L$1;
                this = (PumpStreamHandler)$continuation.L$0;
                try {
                    ResultKt.throwOnFailure((Object)$result);
                    v1 = $result;
                }
                catch (InterruptedException var4_7) {
                    // empty catch block
                }
lbl39:
                // 4 sources

                v2 = this.pumpJobB;
                if (v2 == null) ** GOTO lbl60
                $continuation.L$0 = this;
                $continuation.L$1 = process;
                $continuation.label = 2;
                v3 = v2.join((Continuation)$continuation);
                ** if (v3 != var8_6) goto lbl48
lbl47:
                // 1 sources

                return var8_6;
lbl48:
                // 1 sources

                ** GOTO lbl60
            }
            case 2: {
                process = (Process)$continuation.L$1;
                this = (PumpStreamHandler)$continuation.L$0;
                try {
                    ResultKt.throwOnFailure((Object)$result);
                    v3 = $result;
                }
                catch (InterruptedException var4_8) {
                    // empty catch block
                }
lbl60:
                // 5 sources

                v4 = this.pumpJobC;
                if (v4 == null) ** GOTO lbl80
                $continuation.L$0 = this;
                $continuation.L$1 = process;
                $continuation.label = 3;
                v5 = v4.join((Continuation)$continuation);
                ** if (v5 != var8_6) goto lbl69
lbl68:
                // 1 sources

                return var8_6;
lbl69:
                // 1 sources

                ** GOTO lbl80
            }
            case 3: {
                process = (Process)$continuation.L$1;
                this = (PumpStreamHandler)$continuation.L$0;
                try {
                    ResultKt.throwOnFailure((Object)$result);
                    v5 = $result;
                }
                catch (InterruptedException var4_10) {
                    // empty catch block
                }
lbl80:
                // 4 sources

                caught = null;
                try {
                    process.getOutputStream().close();
                }
                catch (IOException e) {
                    if (Intrinsics.areEqual((Object)e.getMessage(), (Object)"Stream closed")) {
                        PumpStreamHandler.log.trace("Failed to close process output stream", (Throwable)e);
                    }
                    caught = this.add(caught, e);
                }
                try {
                    process.getInputStream().close();
                }
                catch (IOException e) {
                    caught = this.add(caught, e);
                }
                try {
                    process.getErrorStream().close();
                }
                catch (IOException e) {
                    caught = this.add(caught, e);
                }
                if (caught != null) {
                    throw caught;
                }
                return Unit.INSTANCE;
            }
        }
        throw new IllegalStateException("call to 'resume' before 'invoke' with coroutine");
    }

    @NotNull
    public final IOException add(@Nullable IOException exception, @NotNull IOException newException) {
        Intrinsics.checkNotNullParameter((Object)newException, (String)"newException");
        if (exception == null) {
            return newException;
        }
        ExceptionsKt.addSuppressed((Throwable)exception, (Throwable)newException);
        return exception;
    }

    public PumpStreamHandler() {
        this(null, null, null, false, 15, null);
    }

    public static final /* synthetic */ Object access$runInThread(PumpStreamHandler $this, Process process, Continuation $completion) {
        return $this.runInThread(process, (Continuation<? super Unit>)$completion);
    }

    public static final /* synthetic */ Object access$runOutThread(PumpStreamHandler $this, Process process, Continuation $completion) {
        return $this.runOutThread(process, (Continuation<? super Unit>)$completion);
    }

    public static final /* synthetic */ Object access$runErrThread(PumpStreamHandler $this, Process process, Continuation $completion) {
        return $this.runErrThread(process, (Continuation<? super Unit>)$completion);
    }

    public static final /* synthetic */ Object access$runAllSingleThread(PumpStreamHandler $this, Process process, boolean separateErrorStream, Continuation $completion) {
        return $this.runAllSingleThread(process, separateErrorStream, (Continuation<? super Unit>)$completion);
    }

    public static final /* synthetic */ IOStream access$getOutput$p(PumpStreamHandler $this) {
        return $this.output;
    }

    public static final /* synthetic */ IOStream access$getError$p(PumpStreamHandler $this) {
        return $this.error;
    }

    public static final /* synthetic */ boolean access$getStop$p(PumpStreamHandler $this) {
        return $this.stop;
    }

    public static final /* synthetic */ boolean access$getFinishedCleanly$p(PumpStreamHandler $this) {
        return $this.finishedCleanly;
    }

    public static final /* synthetic */ Logger access$getLog$cp() {
        return log;
    }

    @Metadata(mv={1, 6, 0}, k=1, xi=48, d1={"\u0000 \n\u0002\u0018\u0002\n\u0002\u0010\u0000\n\u0002\b\u0002\n\u0002\u0010\b\n\u0000\n\u0002\u0010\t\n\u0000\n\u0002\u0018\u0002\n\u0002\b\u0002\b\u0086\u0003\u0018\u00002\u00020\u0001B\u0007\b\u0002\u00a2\u0006\u0002\u0010\u0002R\u000e\u0010\u0003\u001a\u00020\u0004X\u0080T\u00a2\u0006\u0002\n\u0000R\u000e\u0010\u0005\u001a\u00020\u0006X\u0086T\u00a2\u0006\u0002\n\u0000R\u0016\u0010\u0007\u001a\n \t*\u0004\u0018\u00010\b0\bX\u0082\u0004\u00a2\u0006\u0002\n\u0000\u00a8\u0006\n"}, d2={"Ldorkbox/executor/stream/PumpStreamHandler$Companion;", "", "()V", "DEFAULT_SIZE", "", "POLL_TIMEOUT", "", "log", "Lorg/slf4j/Logger;", "kotlin.jvm.PlatformType", "Executor"})
    public static final class Companion {
        private Companion() {
        }

        public /* synthetic */ Companion(DefaultConstructorMarker $constructor_marker) {
            this();
        }
    }
}

