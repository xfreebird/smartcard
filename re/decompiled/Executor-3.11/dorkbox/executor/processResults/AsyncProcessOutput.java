/*
 * Decompiled with CFR 0.152.
 * 
 * Could not load the following classes:
 *  kotlin.Metadata
 *  kotlin.ResultKt
 *  kotlin.collections.ArraysKt
 *  kotlin.coroutines.Continuation
 *  kotlin.coroutines.intrinsics.IntrinsicsKt
 *  kotlin.coroutines.jvm.internal.ContinuationImpl
 *  kotlin.jvm.internal.DefaultConstructorMarker
 *  kotlin.jvm.internal.Intrinsics
 *  kotlin.text.Charsets
 *  kotlinx.coroutines.channels.Channel
 *  kotlinx.coroutines.channels.ClosedReceiveChannelException
 *  org.jetbrains.annotations.NotNull
 *  org.jetbrains.annotations.Nullable
 */
package dorkbox.executor.processResults;

import dorkbox.executor.processResults.AsyncProcessOutput;
import dorkbox.executor.processResults.ProcessOutput;
import dorkbox.executor.processResults.SyncProcessResult;
import java.io.ByteArrayOutputStream;
import java.io.UnsupportedEncodingException;
import java.nio.charset.Charset;
import java.util.List;
import java.util.concurrent.atomic.AtomicInteger;
import kotlin.Metadata;
import kotlin.ResultKt;
import kotlin.collections.ArraysKt;
import kotlin.coroutines.Continuation;
import kotlin.coroutines.intrinsics.IntrinsicsKt;
import kotlin.coroutines.jvm.internal.ContinuationImpl;
import kotlin.jvm.internal.DefaultConstructorMarker;
import kotlin.jvm.internal.Intrinsics;
import kotlin.text.Charsets;
import kotlinx.coroutines.channels.Channel;
import kotlinx.coroutines.channels.ClosedReceiveChannelException;
import org.jetbrains.annotations.NotNull;
import org.jetbrains.annotations.Nullable;

@Metadata(mv={1, 6, 0}, k=1, xi=48, d1={"\u0000F\n\u0002\u0018\u0002\n\u0002\u0010\u0000\n\u0000\n\u0002\u0018\u0002\n\u0002\u0010\u0005\n\u0000\n\u0002\u0018\u0002\n\u0002\b\u0002\n\u0002\u0010\u000b\n\u0002\b\u0004\n\u0002\u0018\u0002\n\u0002\b\u0005\n\u0002\u0010\u0012\n\u0002\b\u0002\n\u0002\u0010 \n\u0002\u0010\u000e\n\u0000\n\u0002\u0018\u0002\n\u0002\b\n\b\u0016\u0018\u0000 #2\u00020\u0001:\u0001#B\u001d\u0012\f\u0010\u0002\u001a\b\u0012\u0004\u0012\u00020\u00040\u0003\u0012\b\u0010\u0005\u001a\u0004\u0018\u00010\u0006\u00a2\u0006\u0002\u0010\u0007J\u0011\u0010\u0013\u001a\u00020\u0014H\u0082@\u00f8\u0001\u0000\u00a2\u0006\u0002\u0010\u0015J\u001f\u0010\u0016\u001a\b\u0012\u0004\u0012\u00020\u00180\u00172\u0006\u0010\u0019\u001a\u00020\u001aH\u0086@\u00f8\u0001\u0000\u00a2\u0006\u0002\u0010\u001bJ\u0011\u0010\u001c\u001a\u00020\u0014H\u0082@\u00f8\u0001\u0000\u00a2\u0006\u0002\u0010\u0015J\u0017\u0010\u001d\u001a\b\u0012\u0004\u0012\u00020\u00180\u0017H\u0086@\u00f8\u0001\u0000\u00a2\u0006\u0002\u0010\u0015J\u0017\u0010\u001e\u001a\b\u0012\u0004\u0012\u00020\u00180\u0017H\u0086@\u00f8\u0001\u0000\u00a2\u0006\u0002\u0010\u0015J\u0011\u0010\u001f\u001a\u00020\u0018H\u0086@\u00f8\u0001\u0000\u00a2\u0006\u0002\u0010\u0015J\u0019\u0010\u001f\u001a\u00020\u00182\u0006\u0010\u0019\u001a\u00020\u001aH\u0086@\u00f8\u0001\u0000\u00a2\u0006\u0002\u0010\u001bJ\u0011\u0010 \u001a\u00020\u0018H\u0082@\u00f8\u0001\u0000\u00a2\u0006\u0002\u0010\u0015J\u0019\u0010 \u001a\u00020\u00182\u0006\u0010\u0019\u001a\u00020\u001aH\u0086@\u00f8\u0001\u0000\u00a2\u0006\u0002\u0010\u001bJ\u0011\u0010!\u001a\u00020\u0018H\u0086@\u00f8\u0001\u0000\u00a2\u0006\u0002\u0010\u0015J\u0011\u0010\"\u001a\u00020\u0018H\u0086@\u00f8\u0001\u0000\u00a2\u0006\u0002\u0010\u0015R\u0014\u0010\u0002\u001a\b\u0012\u0004\u0012\u00020\u00040\u0003X\u0082\u0004\u00a2\u0006\u0002\n\u0000R\u0017\u0010\b\u001a\u00020\t8F\u00a2\u0006\f\u0012\u0004\b\n\u0010\u000b\u001a\u0004\b\b\u0010\fR\u001a\u0010\r\u001a\u00020\u000eX\u0086\u000e\u00a2\u0006\u000e\n\u0000\u001a\u0004\b\u000f\u0010\u0010\"\u0004\b\u0011\u0010\u0012R\u0010\u0010\u0005\u001a\u0004\u0018\u00010\u0006X\u0082\u0004\u00a2\u0006\u0002\n\u0000\u0082\u0002\u0004\n\u0002\b\u0019\u00a8\u0006$"}, d2={"Ldorkbox/executor/processResults/AsyncProcessOutput;", "", "channel", "Lkotlinx/coroutines/channels/Channel;", "", "processResult", "Ldorkbox/executor/processResults/SyncProcessResult;", "(Lkotlinx/coroutines/channels/Channel;Ldorkbox/executor/processResults/SyncProcessResult;)V", "isOpen", "", "isOpen$annotations", "()V", "()Z", "previousValue", "Ljava/util/concurrent/atomic/AtomicInteger;", "getPreviousValue", "()Ljava/util/concurrent/atomic/AtomicInteger;", "setPreviousValue", "(Ljava/util/concurrent/atomic/AtomicInteger;)V", "getBuffered", "", "(Lkotlin/coroutines/Continuation;)Ljava/lang/Object;", "getLines", "", "", "charset", "Ljava/nio/charset/Charset;", "(Ljava/nio/charset/Charset;Lkotlin/coroutines/Continuation;)Ljava/lang/Object;", "getRaw", "lines", "linesAsUtf8", "string", "stringBuffered", "utf8", "utf8Buffered", "Companion", "Executor"})
public class AsyncProcessOutput {
    @NotNull
    public static final Companion Companion = new Companion(null);
    @NotNull
    private final Channel<Byte> channel;
    @Nullable
    private final SyncProcessResult processResult;
    @NotNull
    private AtomicInteger previousValue;
    private static final int NEW_LINE_WIN;
    private static final int NEW_LINE_NIX;

    public AsyncProcessOutput(@NotNull Channel<Byte> channel, @Nullable SyncProcessResult processResult) {
        Intrinsics.checkNotNullParameter(channel, (String)"channel");
        this.channel = channel;
        this.processResult = processResult;
        this.previousValue = new AtomicInteger(-1);
    }

    public final boolean isOpen() {
        return !this.channel.isClosedForReceive();
    }

    public static /* synthetic */ void isOpen$annotations() {
    }

    @NotNull
    public final AtomicInteger getPreviousValue() {
        return this.previousValue;
    }

    public final void setPreviousValue(@NotNull AtomicInteger atomicInteger) {
        Intrinsics.checkNotNullParameter((Object)atomicInteger, (String)"<set-?>");
        this.previousValue = atomicInteger;
    }

    /*
     * Exception decompiling
     */
    private final Object getBuffered(Continuation<? super byte[]> var1_1) {
        /*
         * This method has failed to decompile.  When submitting a bug report, please provide this stack trace, and (if you hold appropriate legal rights) the relevant class file.
         * 
         * org.benf.cfr.reader.util.ConfusedCFRException: Tried to end blocks [0[TRYBLOCK]], but top level block is 11[UNCONDITIONALDOLOOP]
         *     at org.benf.cfr.reader.bytecode.analysis.opgraph.Op04StructuredStatement.processEndingBlocks(Op04StructuredStatement.java:435)
         *     at org.benf.cfr.reader.bytecode.analysis.opgraph.Op04StructuredStatement.buildNestedBlocks(Op04StructuredStatement.java:484)
         *     at org.benf.cfr.reader.bytecode.analysis.opgraph.Op03SimpleStatement.createInitialStructuredBlock(Op03SimpleStatement.java:736)
         *     at org.benf.cfr.reader.bytecode.CodeAnalyser.getAnalysisInner(CodeAnalyser.java:850)
         *     at org.benf.cfr.reader.bytecode.CodeAnalyser.getAnalysisOrWrapFail(CodeAnalyser.java:278)
         *     at org.benf.cfr.reader.bytecode.CodeAnalyser.getAnalysis(CodeAnalyser.java:201)
         *     at org.benf.cfr.reader.entities.attributes.AttributeCode.analyse(AttributeCode.java:94)
         *     at org.benf.cfr.reader.entities.Method.analyse(Method.java:531)
         *     at org.benf.cfr.reader.entities.ClassFile.analyseMid(ClassFile.java:1055)
         *     at org.benf.cfr.reader.entities.ClassFile.analyseTop(ClassFile.java:942)
         *     at org.benf.cfr.reader.Driver.doJarVersionTypes(Driver.java:257)
         *     at org.benf.cfr.reader.Driver.doJar(Driver.java:139)
         *     at org.benf.cfr.reader.CfrDriverImpl.analyse(CfrDriverImpl.java:76)
         *     at org.benf.cfr.reader.Main.main(Main.java:54)
         */
        throw new IllegalStateException("Decompilation failed");
    }

    /*
     * Unable to fully structure code
     * Could not resolve type clashes
     */
    private final Object getRaw(Continuation<? super byte[]> var1_1) {
        if (!(var1_1 instanceof getRaw.1)) ** GOTO lbl-1000
        var7_2 = var1_1;
        if ((var7_2.label & -2147483648) != 0) {
            var7_2.label -= -2147483648;
        } else lbl-1000:
        // 2 sources

        {
            $continuation = new ContinuationImpl(this, var1_1){
                Object L$0;
                Object L$1;
                int I$0;
                /* synthetic */ Object result;
                final /* synthetic */ AsyncProcessOutput this$0;
                int label;
                {
                    this.this$0 = this$0;
                    super($completion);
                }

                @Nullable
                public final Object invokeSuspend(@NotNull Object $result) {
                    this.result = $result;
                    this.label |= Integer.MIN_VALUE;
                    return AsyncProcessOutput.access$getRaw(this.this$0, (Continuation)this);
                }
            };
        }
        $result = $continuation.result;
        var8_4 = IntrinsicsKt.getCOROUTINE_SUSPENDED();
        switch ($continuation.label) {
            case 0: {
                ResultKt.throwOnFailure((Object)$result);
                out = new ByteArrayOutputStream(2);
                value = this.getPreviousValue().getAndSet(-1);
                if (value != -1) {
                    out.write(value);
                }
                $continuation.L$0 = this;
                $continuation.L$1 = out;
                $continuation.I$0 = value;
                $continuation.label = 1;
                v0 = this.channel.receive((Continuation)$continuation);
                ** if (v0 != var8_4) goto lbl25
lbl24:
                // 1 sources

                return var8_4;
lbl25:
                // 1 sources

                ** GOTO lbl34
            }
            case 1: {
                value = $continuation.I$0;
                out = (ByteArrayOutputStream)$continuation.L$1;
                this = (AsyncProcessOutput)$continuation.L$0;
                try {
                    ResultKt.throwOnFailure((Object)$result);
                    v0 = $result;
lbl34:
                    // 2 sources

                    toInt = ((Number)v0).byteValue();
                    if (value == 1) {
                        var5_10 = new byte[]{toInt};
                        return var5_10;
                    }
                    out.write(toInt);
                }
                catch (ClosedReceiveChannelException var4_8) {
                    v1 = this.processResult;
                    if (v1 == null) {
                        v2 /* !! */  = null;
                    } else {
                        v3 = v1.getOutput();
                        v2 /* !! */  = internalBytes = (byte[])(v3 == null ? null : v3.getBytes_$Executor());
                    }
                    if (internalBytes == null) ** GOTO lbl51
                    if (out.size() == 0) {
                        return internalBytes;
                    }
                    out.write(internalBytes, 0, internalBytes.length);
                }
lbl51:
                // 3 sources

                var4_9 = out.toByteArray();
                Intrinsics.checkNotNullExpressionValue((Object)var4_9, (String)"out.toByteArray()");
                return var4_9;
            }
        }
        throw new IllegalStateException("call to 'resume' before 'invoke' with coroutine");
    }

    /*
     * Unable to fully structure code
     */
    @Nullable
    public final Object string(@NotNull Continuation<? super String> var1_1) {
        if (!(var1_1 instanceof string.1)) ** GOTO lbl-1000
        var4_2 = var1_1;
        if ((var4_2.label & -2147483648) != 0) {
            var4_2.label -= -2147483648;
        } else lbl-1000:
        // 2 sources

        {
            $continuation = new ContinuationImpl(this, var1_1){
                /* synthetic */ Object result;
                final /* synthetic */ AsyncProcessOutput this$0;
                int label;
                {
                    this.this$0 = this$0;
                    super($completion);
                }

                @Nullable
                public final Object invokeSuspend(@NotNull Object $result) {
                    this.result = $result;
                    this.label |= Integer.MIN_VALUE;
                    return this.this$0.string((Continuation<? super String>)((Continuation)this));
                }
            };
        }
        $result = $continuation.result;
        var5_4 = IntrinsicsKt.getCOROUTINE_SUSPENDED();
        switch ($continuation.label) {
            case 0: {
                ResultKt.throwOnFailure((Object)$result);
                $continuation.label = 1;
                v0 = this.getRaw((Continuation<? super byte[]>)$continuation);
                if (v0 == var5_4) {
                    return var5_4;
                }
                ** GOTO lbl20
            }
            case 1: {
                ResultKt.throwOnFailure((Object)$result);
                v0 = $result;
lbl20:
                // 2 sources

                var2_5 = (byte[])v0;
                return new String(var2_5, Charsets.UTF_8);
            }
        }
        throw new IllegalStateException("call to 'resume' before 'invoke' with coroutine");
    }

    /*
     * Unable to fully structure code
     */
    private final Object stringBuffered(Continuation<? super String> var1_1) {
        if (!(var1_1 instanceof stringBuffered.1)) ** GOTO lbl-1000
        var4_2 = var1_1;
        if ((var4_2.label & -2147483648) != 0) {
            var4_2.label -= -2147483648;
        } else lbl-1000:
        // 2 sources

        {
            $continuation = new ContinuationImpl(this, var1_1){
                /* synthetic */ Object result;
                final /* synthetic */ AsyncProcessOutput this$0;
                int label;
                {
                    this.this$0 = this$0;
                    super($completion);
                }

                @Nullable
                public final Object invokeSuspend(@NotNull Object $result) {
                    this.result = $result;
                    this.label |= Integer.MIN_VALUE;
                    return AsyncProcessOutput.access$stringBuffered(this.this$0, (Continuation)this);
                }
            };
        }
        $result = $continuation.result;
        var5_4 = IntrinsicsKt.getCOROUTINE_SUSPENDED();
        switch ($continuation.label) {
            case 0: {
                ResultKt.throwOnFailure((Object)$result);
                $continuation.label = 1;
                v0 = this.getBuffered((Continuation<? super byte[]>)$continuation);
                if (v0 == var5_4) {
                    return var5_4;
                }
                ** GOTO lbl20
            }
            case 1: {
                ResultKt.throwOnFailure((Object)$result);
                v0 = $result;
lbl20:
                // 2 sources

                var2_5 = (byte[])v0;
                return new String(var2_5, Charsets.UTF_8);
            }
        }
        throw new IllegalStateException("call to 'resume' before 'invoke' with coroutine");
    }

    @Nullable
    public final Object utf8(@NotNull Continuation<? super String> $completion) {
        return this.string(Charsets.UTF_8, $completion);
    }

    @Nullable
    public final Object utf8Buffered(@NotNull Continuation<? super String> $completion) {
        return this.stringBuffered(Charsets.UTF_8, $completion);
    }

    /*
     * Unable to fully structure code
     * Could not resolve type clashes
     */
    @Nullable
    public final Object string(@NotNull Charset var1_1, @NotNull Continuation<? super String> var2_2) throws IllegalStateException {
        if (!(var2_2 instanceof string.2)) ** GOTO lbl-1000
        var6_3 = var2_2;
        if ((var6_3.label & -2147483648) != 0) {
            var6_3.label -= -2147483648;
        } else lbl-1000:
        // 2 sources

        {
            $continuation = new ContinuationImpl(this, var2_2){
                Object L$0;
                /* synthetic */ Object result;
                final /* synthetic */ AsyncProcessOutput this$0;
                int label;
                {
                    this.this$0 = this$0;
                    super($completion);
                }

                @Nullable
                public final Object invokeSuspend(@NotNull Object $result) {
                    this.result = $result;
                    this.label |= Integer.MIN_VALUE;
                    return this.this$0.string(null, (Continuation<? super String>)((Continuation)this));
                }
            };
        }
        $result = $continuation.result;
        var7_5 = IntrinsicsKt.getCOROUTINE_SUSPENDED();
        switch ($continuation.label) {
            case 0: {
                ResultKt.throwOnFailure((Object)$result);
                $continuation.L$0 = charset;
                $continuation.label = 1;
                v0 = this.getRaw((Continuation<? super byte[]>)$continuation);
                ** if (v0 != var7_5) goto lbl19
lbl18:
                // 1 sources

                return var7_5;
lbl19:
                // 1 sources

                ** GOTO lbl26
            }
            case 1: {
                charset = (Charset)$continuation.L$0;
                try {
                    ResultKt.throwOnFailure((Object)$result);
                    v0 = $result;
lbl26:
                    // 2 sources

                    var3_6 /* !! */  = (byte[])v0;
                    var3_6 /* !! */  = (byte[])new String(var3_6 /* !! */ , charset);
                }
                catch (UnsupportedEncodingException e) {
                    throw new IllegalStateException(e.getMessage());
                }
                return var3_6 /* !! */ ;
            }
        }
        throw new IllegalStateException("call to 'resume' before 'invoke' with coroutine");
    }

    /*
     * Unable to fully structure code
     * Could not resolve type clashes
     */
    @Nullable
    public final Object stringBuffered(@NotNull Charset var1_1, @NotNull Continuation<? super String> var2_2) throws IllegalStateException {
        if (!(var2_2 instanceof stringBuffered.2)) ** GOTO lbl-1000
        var6_3 = var2_2;
        if ((var6_3.label & -2147483648) != 0) {
            var6_3.label -= -2147483648;
        } else lbl-1000:
        // 2 sources

        {
            $continuation = new ContinuationImpl(this, var2_2){
                Object L$0;
                /* synthetic */ Object result;
                final /* synthetic */ AsyncProcessOutput this$0;
                int label;
                {
                    this.this$0 = this$0;
                    super($completion);
                }

                @Nullable
                public final Object invokeSuspend(@NotNull Object $result) {
                    this.result = $result;
                    this.label |= Integer.MIN_VALUE;
                    return this.this$0.stringBuffered(null, (Continuation<? super String>)((Continuation)this));
                }
            };
        }
        $result = $continuation.result;
        var7_5 = IntrinsicsKt.getCOROUTINE_SUSPENDED();
        switch ($continuation.label) {
            case 0: {
                ResultKt.throwOnFailure((Object)$result);
                $continuation.L$0 = charset;
                $continuation.label = 1;
                v0 = this.getBuffered((Continuation<? super byte[]>)$continuation);
                ** if (v0 != var7_5) goto lbl19
lbl18:
                // 1 sources

                return var7_5;
lbl19:
                // 1 sources

                ** GOTO lbl26
            }
            case 1: {
                charset = (Charset)$continuation.L$0;
                try {
                    ResultKt.throwOnFailure((Object)$result);
                    v0 = $result;
lbl26:
                    // 2 sources

                    var3_6 /* !! */  = (byte[])v0;
                    var3_6 /* !! */  = (byte[])new String(var3_6 /* !! */ , charset);
                }
                catch (UnsupportedEncodingException e) {
                    throw new IllegalStateException(e.getMessage());
                }
                return var3_6 /* !! */ ;
            }
        }
        throw new IllegalStateException("call to 'resume' before 'invoke' with coroutine");
    }

    /*
     * Unable to fully structure code
     */
    @Nullable
    public final Object lines(@NotNull Continuation<? super List<String>> var1_1) {
        if (!(var1_1 instanceof lines.1)) ** GOTO lbl-1000
        var4_2 = var1_1;
        if ((var4_2.label & -2147483648) != 0) {
            var4_2.label -= -2147483648;
        } else lbl-1000:
        // 2 sources

        {
            $continuation = new ContinuationImpl(this, var1_1){
                Object L$0;
                /* synthetic */ Object result;
                final /* synthetic */ AsyncProcessOutput this$0;
                int label;
                {
                    this.this$0 = this$0;
                    super($completion);
                }

                @Nullable
                public final Object invokeSuspend(@NotNull Object $result) {
                    this.result = $result;
                    this.label |= Integer.MIN_VALUE;
                    return this.this$0.lines((Continuation<? super List<String>>)((Continuation)this));
                }
            };
        }
        $result = $continuation.result;
        var5_4 = IntrinsicsKt.getCOROUTINE_SUSPENDED();
        switch ($continuation.label) {
            case 0: {
                ResultKt.throwOnFailure((Object)$result);
                var2_5 = ProcessOutput.Companion;
                $continuation.L$0 = var2_5;
                $continuation.label = 1;
                v0 = this.stringBuffered((Continuation<? super String>)$continuation);
                if (v0 == var5_4) {
                    return var5_4;
                }
                ** GOTO lbl23
            }
            case 1: {
                var2_5 = (ProcessOutput.Companion)$continuation.L$0;
                ResultKt.throwOnFailure((Object)$result);
                v0 = $result;
lbl23:
                // 2 sources

                return var2_5.getLinesFrom((String)v0);
            }
        }
        throw new IllegalStateException("call to 'resume' before 'invoke' with coroutine");
    }

    /*
     * Unable to fully structure code
     */
    @Nullable
    public final Object linesAsUtf8(@NotNull Continuation<? super List<String>> var1_1) {
        if (!(var1_1 instanceof linesAsUtf8.1)) ** GOTO lbl-1000
        var4_2 = var1_1;
        if ((var4_2.label & -2147483648) != 0) {
            var4_2.label -= -2147483648;
        } else lbl-1000:
        // 2 sources

        {
            $continuation = new ContinuationImpl(this, var1_1){
                Object L$0;
                /* synthetic */ Object result;
                final /* synthetic */ AsyncProcessOutput this$0;
                int label;
                {
                    this.this$0 = this$0;
                    super($completion);
                }

                @Nullable
                public final Object invokeSuspend(@NotNull Object $result) {
                    this.result = $result;
                    this.label |= Integer.MIN_VALUE;
                    return this.this$0.linesAsUtf8((Continuation<? super List<String>>)((Continuation)this));
                }
            };
        }
        $result = $continuation.result;
        var5_4 = IntrinsicsKt.getCOROUTINE_SUSPENDED();
        switch ($continuation.label) {
            case 0: {
                ResultKt.throwOnFailure((Object)$result);
                var2_5 = ProcessOutput.Companion;
                $continuation.L$0 = var2_5;
                $continuation.label = 1;
                v0 = this.utf8Buffered((Continuation<? super String>)$continuation);
                if (v0 == var5_4) {
                    return var5_4;
                }
                ** GOTO lbl23
            }
            case 1: {
                var2_5 = (ProcessOutput.Companion)$continuation.L$0;
                ResultKt.throwOnFailure((Object)$result);
                v0 = $result;
lbl23:
                // 2 sources

                return var2_5.getLinesFrom((String)v0);
            }
        }
        throw new IllegalStateException("call to 'resume' before 'invoke' with coroutine");
    }

    /*
     * Unable to fully structure code
     */
    @Nullable
    public final Object getLines(@NotNull Charset var1_1, @NotNull Continuation<? super List<String>> var2_2) {
        if (!(var2_2 instanceof getLines.1)) ** GOTO lbl-1000
        var5_3 = var2_2;
        if ((var5_3.label & -2147483648) != 0) {
            var5_3.label -= -2147483648;
        } else lbl-1000:
        // 2 sources

        {
            $continuation = new ContinuationImpl(this, var2_2){
                Object L$0;
                /* synthetic */ Object result;
                final /* synthetic */ AsyncProcessOutput this$0;
                int label;
                {
                    this.this$0 = this$0;
                    super($completion);
                }

                @Nullable
                public final Object invokeSuspend(@NotNull Object $result) {
                    this.result = $result;
                    this.label |= Integer.MIN_VALUE;
                    return this.this$0.getLines(null, (Continuation<? super List<String>>)((Continuation)this));
                }
            };
        }
        $result = $continuation.result;
        var6_5 = IntrinsicsKt.getCOROUTINE_SUSPENDED();
        switch ($continuation.label) {
            case 0: {
                ResultKt.throwOnFailure((Object)$result);
                var3_6 = ProcessOutput.Companion;
                $continuation.L$0 = var3_6;
                $continuation.label = 1;
                v0 = this.stringBuffered((Charset)charset, (Continuation<? super String>)$continuation);
                if (v0 == var6_5) {
                    return var6_5;
                }
                ** GOTO lbl23
            }
            case 1: {
                var3_6 = (ProcessOutput.Companion)$continuation.L$0;
                ResultKt.throwOnFailure((Object)$result);
                v0 = $result;
lbl23:
                // 2 sources

                return var3_6.getLinesFrom((String)v0);
            }
        }
        throw new IllegalStateException("call to 'resume' before 'invoke' with coroutine");
    }

    public static final /* synthetic */ Object access$getBuffered(AsyncProcessOutput $this, Continuation $completion) {
        return $this.getBuffered((Continuation<? super byte[]>)$completion);
    }

    public static final /* synthetic */ Object access$getRaw(AsyncProcessOutput $this, Continuation $completion) {
        return $this.getRaw((Continuation<? super byte[]>)$completion);
    }

    public static final /* synthetic */ Object access$stringBuffered(AsyncProcessOutput $this, Continuation $completion) {
        return $this.stringBuffered((Continuation<? super String>)$completion);
    }

    static {
        char[] cArray = "\r".toCharArray();
        Intrinsics.checkNotNullExpressionValue((Object)cArray, (String)"this as java.lang.String).toCharArray()");
        NEW_LINE_WIN = ArraysKt.first((char[])cArray);
        cArray = "\n".toCharArray();
        Intrinsics.checkNotNullExpressionValue((Object)cArray, (String)"this as java.lang.String).toCharArray()");
        NEW_LINE_NIX = ArraysKt.first((char[])cArray);
    }

    @Metadata(mv={1, 6, 0}, k=1, xi=48, d1={"\u0000\u0014\n\u0002\u0018\u0002\n\u0002\u0010\u0000\n\u0002\b\u0002\n\u0002\u0010\b\n\u0002\b\u0002\b\u0086\u0003\u0018\u00002\u00020\u0001B\u0007\b\u0002\u00a2\u0006\u0002\u0010\u0002R\u000e\u0010\u0003\u001a\u00020\u0004X\u0082\u0004\u00a2\u0006\u0002\n\u0000R\u000e\u0010\u0005\u001a\u00020\u0004X\u0082\u0004\u00a2\u0006\u0002\n\u0000\u00a8\u0006\u0006"}, d2={"Ldorkbox/executor/processResults/AsyncProcessOutput$Companion;", "", "()V", "NEW_LINE_NIX", "", "NEW_LINE_WIN", "Executor"})
    public static final class Companion {
        private Companion() {
        }

        public /* synthetic */ Companion(DefaultConstructorMarker $constructor_marker) {
            this();
        }
    }
}

