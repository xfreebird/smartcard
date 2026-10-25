/*
 * Decompiled with CFR 0.152.
 * 
 * Could not load the following classes:
 *  kotlin.Lazy
 *  kotlin.LazyKt
 *  kotlin.Metadata
 *  kotlin.ResultKt
 *  kotlin.Unit
 *  kotlin.coroutines.Continuation
 *  kotlin.coroutines.CoroutineContext
 *  kotlin.coroutines.CoroutineContext$Key
 *  kotlin.coroutines.intrinsics.IntrinsicsKt
 *  kotlin.coroutines.jvm.internal.Boxing
 *  kotlin.coroutines.jvm.internal.ContinuationImpl
 *  kotlin.jvm.functions.Function0
 *  kotlin.jvm.functions.Function2
 *  kotlin.jvm.internal.DefaultConstructorMarker
 *  kotlin.jvm.internal.Intrinsics
 *  kotlin.jvm.internal.Ref$BooleanRef
 *  kotlin.text.Charsets
 *  kotlin.text.StringsKt
 *  kotlinx.coroutines.BuildersKt
 *  kotlinx.coroutines.CoroutineExceptionHandler
 *  kotlinx.coroutines.CoroutineExceptionHandler$Key
 *  kotlinx.coroutines.CoroutineScope
 *  kotlinx.coroutines.Dispatchers
 *  kotlinx.coroutines.ExceptionsKt
 *  kotlinx.coroutines.ExperimentalCoroutinesApi
 *  kotlinx.coroutines.Job
 *  kotlinx.coroutines.Job$DefaultImpls
 *  kotlinx.coroutines.TimeoutCancellationException
 *  kotlinx.coroutines.TimeoutKt
 *  kotlinx.coroutines.channels.Channel
 *  org.jetbrains.annotations.NotNull
 *  org.jetbrains.annotations.Nullable
 *  org.slf4j.Logger
 *  org.slf4j.LoggerFactory
 *  org.slf4j.MDC
 */
package dorkbox.executor;

import dorkbox.executor.DeferredProcessResult;
import dorkbox.executor.Executor;
import dorkbox.executor.LogHelper;
import dorkbox.executor.Params;
import dorkbox.executor.PidHelper;
import dorkbox.executor.ProcessAttributes;
import dorkbox.executor.SuspendNotifier;
import dorkbox.executor.exceptions.InvalidExitValueException;
import dorkbox.executor.processResults.AsyncProcessOutput;
import dorkbox.executor.processResults.ProcessResult;
import dorkbox.executor.processResults.SyncProcessResult;
import dorkbox.executor.stream.PumpStreamHandler;
import java.io.OutputStream;
import java.util.ArrayList;
import java.util.Collection;
import java.util.Map;
import java.util.Set;
import java.util.concurrent.CancellationException;
import java.util.concurrent.ExecutionException;
import java.util.concurrent.TimeUnit;
import java.util.concurrent.TimeoutException;
import kotlin.Lazy;
import kotlin.LazyKt;
import kotlin.Metadata;
import kotlin.ResultKt;
import kotlin.Unit;
import kotlin.coroutines.Continuation;
import kotlin.coroutines.CoroutineContext;
import kotlin.coroutines.intrinsics.IntrinsicsKt;
import kotlin.coroutines.jvm.internal.Boxing;
import kotlin.coroutines.jvm.internal.ContinuationImpl;
import kotlin.jvm.functions.Function0;
import kotlin.jvm.functions.Function2;
import kotlin.jvm.internal.DefaultConstructorMarker;
import kotlin.jvm.internal.Intrinsics;
import kotlin.jvm.internal.Ref;
import kotlin.text.Charsets;
import kotlin.text.StringsKt;
import kotlinx.coroutines.BuildersKt;
import kotlinx.coroutines.CoroutineExceptionHandler;
import kotlinx.coroutines.CoroutineScope;
import kotlinx.coroutines.Dispatchers;
import kotlinx.coroutines.ExceptionsKt;
import kotlinx.coroutines.ExperimentalCoroutinesApi;
import kotlinx.coroutines.Job;
import kotlinx.coroutines.TimeoutCancellationException;
import kotlinx.coroutines.TimeoutKt;
import kotlinx.coroutines.channels.Channel;
import org.jetbrains.annotations.NotNull;
import org.jetbrains.annotations.Nullable;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.slf4j.MDC;

@Metadata(mv={1, 6, 0}, k=1, xi=48, d1={"\u0000\u008a\u0001\n\u0002\u0018\u0002\n\u0002\u0010\u0000\n\u0000\n\u0002\u0018\u0002\n\u0000\n\u0002\u0018\u0002\n\u0000\n\u0002\u0018\u0002\n\u0002\u0010\t\n\u0002\u0010\b\n\u0002\u0018\u0002\n\u0002\b\u0002\n\u0002\u0010\u000b\n\u0002\b\u0005\n\u0002\u0018\u0002\n\u0002\b\u0005\n\u0002\u0018\u0002\n\u0002\b\u0002\n\u0002\u0018\u0002\n\u0002\b\b\n\u0002\u0010\u0003\n\u0002\b\u000b\n\u0002\u0018\u0002\n\u0002\b\n\n\u0002\u0018\u0002\n\u0002\b\u0003\n\u0002\u0010\u0002\n\u0000\n\u0002\u0010\u000e\n\u0002\b\n\n\u0002\u0018\u0002\n\u0000\n\u0002\u0010\u0011\n\u0002\u0018\u0002\n\u0002\b\u0005\n\u0002\u0010\u0012\n\u0002\b\u0004\u0018\u0000 Y2\u00020\u0001:\u0001YB1\b\u0000\u0012\u0006\u0010\u0002\u001a\u00020\u0003\u0012\u0006\u0010\u0004\u001a\u00020\u0005\u0012\u0018\u0010\u0006\u001a\u0014\u0012\u0004\u0012\u00020\b\u0012\u0004\u0012\u00020\t\u0012\u0004\u0012\u00020\n0\u0007\u00a2\u0006\u0002\u0010\u000bJ\u0011\u00106\u001a\u00020\nH\u0086@\u00f8\u0001\u0000\u00a2\u0006\u0002\u00107J\u0019\u00106\u001a\u00020\n2\u0006\u00108\u001a\u00020\bH\u0086@\u00f8\u0001\u0000\u00a2\u0006\u0002\u00109J!\u00106\u001a\u00020\n2\u0006\u0010:\u001a\u00020\b2\u0006\u0010;\u001a\u00020<H\u0086@\u00f8\u0001\u0000\u00a2\u0006\u0002\u0010=J\u0006\u0010>\u001a\u00020\nJ\u000e\u0010>\u001a\u00020\n2\u0006\u00108\u001a\u00020\bJ\u0016\u0010>\u001a\u00020\n2\u0006\u0010:\u001a\u00020\b2\u0006\u0010;\u001a\u00020<J\u001c\u0010?\u001a\u00020@2\b\b\u0002\u0010A\u001a\u00020B2\n\b\u0002\u0010C\u001a\u0004\u0018\u00010%J\u0019\u0010D\u001a\u00020\n2\u0006\u0010E\u001a\u00020\tH\u0083@\u00f8\u0001\u0000\u00a2\u0006\u0002\u0010FJ\u0006\u0010G\u001a\u00020@J\u0019\u0010H\u001a\u0004\u0018\u00010\t2\b\u0010\u0002\u001a\u0004\u0018\u00010\u0003H\u0002\u00a2\u0006\u0002\u0010IJ\u0018\u0010J\u001a\u00020B2\u0006\u0010:\u001a\u00020\b2\u0006\u0010K\u001a\u00020<H\u0002J3\u0010L\u001a\u00020M2\u0006\u0010\u0002\u001a\u00020\u00032\f\u0010N\u001a\b\u0012\u0004\u0012\u00020P0O2\u0006\u0010:\u001a\u00020\b2\u0006\u0010;\u001a\u00020<H\u0002\u00a2\u0006\u0002\u0010QJ\b\u0010R\u001a\u00020@H\u0007J\u0011\u0010S\u001a\u00020\tH\u0082@\u00f8\u0001\u0000\u00a2\u0006\u0002\u00107J\u000e\u0010T\u001a\u00020@2\u0006\u0010U\u001a\u00020VJ\u000e\u0010T\u001a\u00020@2\u0006\u0010W\u001a\u00020BJ\u000e\u0010X\u001a\u00020@2\u0006\u0010W\u001a\u00020BR\u001a\u0010\f\u001a\u00020\rX\u0086\u000e\u00a2\u0006\u000e\n\u0000\u001a\u0004\b\u000e\u0010\u000f\"\u0004\b\u0010\u0010\u0011R \u0010\u0006\u001a\u0014\u0012\u0004\u0012\u00020\b\u0012\u0004\u0012\u00020\t\u0012\u0004\u0012\u00020\n0\u0007X\u0082\u0004\u00a2\u0006\u0002\n\u0000R\u001a\u0010\u0012\u001a\u00020\u0013X\u0086.\u00a2\u0006\u000e\n\u0000\u001a\u0004\b\u0014\u0010\u0015\"\u0004\b\u0016\u0010\u0017R\u0016\u0010\u0018\u001a\n \u001a*\u0004\u0018\u00010\u00190\u0019X\u0082\u0004\u00a2\u0006\u0002\n\u0000R\u001b\u0010\u001b\u001a\u00020\u001c8FX\u0086\u0084\u0002\u00a2\u0006\f\n\u0004\b\u001f\u0010 \u001a\u0004\b\u001d\u0010\u001eR\u000e\u0010\u0004\u001a\u00020\u0005X\u0082\u0004\u00a2\u0006\u0002\n\u0000R\u0011\u0010!\u001a\u00020\b\u00a2\u0006\b\n\u0000\u001a\u0004\b\"\u0010#R\u000e\u0010\u0002\u001a\u00020\u0003X\u0082\u0004\u00a2\u0006\u0002\n\u0000R\u0010\u0010$\u001a\u0004\u0018\u00010%X\u0082\u000e\u00a2\u0006\u0002\n\u0000R\u001c\u0010&\u001a\u0004\u0018\u00010\nX\u0086\u000e\u00a2\u0006\u000e\n\u0000\u001a\u0004\b'\u0010(\"\u0004\b)\u0010*R\u001a\u0010+\u001a\u00020\u0019X\u0086.\u00a2\u0006\u000e\n\u0000\u001a\u0004\b,\u0010-\"\u0004\b.\u0010/R\u0019\u00100\u001a\u000201X\u0082\u0004\u00f8\u0001\u0000\u00f8\u0001\u0001\u00f8\u0001\u0002\u00a2\u0006\u0004\n\u0002\u00102R\u001a\u00103\u001a\u00020\rX\u0086\u000e\u00a2\u0006\u000e\n\u0000\u001a\u0004\b4\u0010\u000f\"\u0004\b5\u0010\u0011\u0082\u0002\u000f\n\u0002\b\u0019\n\u0005\b\u00a1\u001e0\u0001\n\u0002\b!\u00a8\u0006Z"}, d2={"Ldorkbox/executor/DeferredProcessResult;", "", "process", "Ljava/lang/Process;", "params", "Ldorkbox/executor/Params;", "createProcessResults", "Lkotlin/Function2;", "", "", "Ldorkbox/executor/processResults/SyncProcessResult;", "(Ljava/lang/Process;Ldorkbox/executor/Params;Lkotlin/jvm/functions/Function2;)V", "calledAwait", "", "getCalledAwait", "()Z", "setCalledAwait", "(Z)V", "job", "Lkotlinx/coroutines/Job;", "getJob", "()Lkotlinx/coroutines/Job;", "setJob", "(Lkotlinx/coroutines/Job;)V", "launchingThread", "Ljava/lang/Thread;", "kotlin.jvm.PlatformType", "output", "Ldorkbox/executor/processResults/AsyncProcessOutput;", "getOutput", "()Ldorkbox/executor/processResults/AsyncProcessOutput;", "output$delegate", "Lkotlin/Lazy;", "pid", "getPid", "()J", "processException", "", "processResult", "getProcessResult", "()Ldorkbox/executor/processResults/SyncProcessResult;", "setProcessResult", "(Ldorkbox/executor/processResults/SyncProcessResult;)V", "thread", "getThread", "()Ljava/lang/Thread;", "setThread", "(Ljava/lang/Thread;)V", "waiter", "Ldorkbox/executor/SuspendNotifier;", "Lkotlinx/coroutines/channels/Channel;", "waiting", "getWaiting", "setWaiting", "await", "(Lkotlin/coroutines/Continuation;)Ljava/lang/Object;", "timeoutInMs", "(JLkotlin/coroutines/Continuation;)Ljava/lang/Object;", "timeout", "timeoutUnit", "Ljava/util/concurrent/TimeUnit;", "(JLjava/util/concurrent/TimeUnit;Lkotlin/coroutines/Continuation;)Ljava/lang/Object;", "awaitBlocking", "cancel", "", "message", "", "cause", "finishWaiting", "exitCode", "(ILkotlin/coroutines/Continuation;)Ljava/lang/Object;", "flush", "getExitCodeOrNull", "(Ljava/lang/Process;)Ljava/lang/Integer;", "getUnitsAsString", "timeUnit", "newTimeoutException", "Ljava/util/concurrent/TimeoutException;", "processStackTrace", "", "Ljava/lang/StackTraceElement;", "(Ljava/lang/Process;[Ljava/lang/StackTraceElement;JLjava/util/concurrent/TimeUnit;)Ljava/util/concurrent/TimeoutException;", "start", "waitForProcessToComplete", "write", "bytes", "", "command", "writeLine", "Companion", "Executor"})
public final class DeferredProcessResult {
    @NotNull
    public static final Companion Companion = new Companion(null);
    @NotNull
    private final Process process;
    @NotNull
    private final Params params;
    @NotNull
    private final Function2<Long, Integer, SyncProcessResult> createProcessResults;
    @NotNull
    private final Channel<Unit> waiter;
    private final Thread launchingThread;
    private volatile boolean calledAwait;
    private volatile boolean waiting;
    public volatile Job job;
    public volatile Thread thread;
    @Nullable
    private volatile Throwable processException;
    @Nullable
    private volatile SyncProcessResult processResult;
    @NotNull
    private final Lazy output$delegate;
    private final long pid;
    @NotNull
    private static final byte[] EOL;
    private static final Logger log;
    private static final int MAX_OUTPUT_SIZE_IN_ERROR_MESSAGE = 5000;

    public DeferredProcessResult(@NotNull Process process, @NotNull Params params, @NotNull Function2<? super Long, ? super Integer, ? extends SyncProcessResult> createProcessResults) {
        Intrinsics.checkNotNullParameter((Object)process, (String)"process");
        Intrinsics.checkNotNullParameter((Object)params, (String)"params");
        Intrinsics.checkNotNullParameter(createProcessResults, (String)"createProcessResults");
        this.process = process;
        this.params = params;
        this.createProcessResults = createProcessResults;
        this.waiter = SuspendNotifier.constructor-impl$default(null, 1, null);
        this.launchingThread = Thread.currentThread();
        this.output$delegate = LazyKt.lazy((Function0)((Function0)new Function0<AsyncProcessOutput>(this){
            final /* synthetic */ DeferredProcessResult this$0;
            {
                this.this$0 = $receiver;
                super(0);
            }

            @NotNull
            public final AsyncProcessOutput invoke() {
                if (!DeferredProcessResult.access$getParams$p(this.this$0).getAsyncProcessStart()) {
                    throw new IllegalArgumentException("Cannot get synchronous output, the process must be started asynchronously (something is wrong!)");
                }
                Channel<Byte> channel = ((PumpStreamHandler)DeferredProcessResult.access$getParams$p(this.this$0).getStreams()).getChannel$Executor();
                return new AsyncProcessOutput(channel, this.this$0.getProcessResult());
            }
        }));
        this.pid = PidHelper.INSTANCE.get(this.process);
    }

    public final boolean getCalledAwait() {
        return this.calledAwait;
    }

    public final void setCalledAwait(boolean bl) {
        this.calledAwait = bl;
    }

    public final boolean getWaiting() {
        return this.waiting;
    }

    public final void setWaiting(boolean bl) {
        this.waiting = bl;
    }

    @NotNull
    public final Job getJob() {
        Job job = this.job;
        if (job != null) {
            return job;
        }
        Intrinsics.throwUninitializedPropertyAccessException((String)"job");
        return null;
    }

    public final void setJob(@NotNull Job job) {
        Intrinsics.checkNotNullParameter((Object)job, (String)"<set-?>");
        this.job = job;
    }

    @NotNull
    public final Thread getThread() {
        Thread thread = this.thread;
        if (thread != null) {
            return thread;
        }
        Intrinsics.throwUninitializedPropertyAccessException((String)"thread");
        return null;
    }

    public final void setThread(@NotNull Thread thread) {
        Intrinsics.checkNotNullParameter((Object)thread, (String)"<set-?>");
        this.thread = thread;
    }

    @Nullable
    public final SyncProcessResult getProcessResult() {
        return this.processResult;
    }

    public final void setProcessResult(@Nullable SyncProcessResult syncProcessResult) {
        this.processResult = syncProcessResult;
    }

    @ExperimentalCoroutinesApi
    public final void start() {
        Map contextMap = MDC.getCopyOfContextMap();
        boolean $i$f$CoroutineExceptionHandler = false;
        CoroutineExceptionHandler.Key key = CoroutineExceptionHandler.Key;
        CoroutineExceptionHandler coroutineExceptionHandler = new CoroutineExceptionHandler(key, this){
            final /* synthetic */ DeferredProcessResult this$0;
            {
                this.this$0 = deferredProcessResult;
                super((CoroutineContext.Key)$super_call_param$1);
            }

            /*
             * WARNING - void declaration
             */
            public void handleException(@NotNull CoroutineContext context, @NotNull Throwable exception) {
                void throwable;
                Throwable throwable2 = exception;
                CoroutineContext $noName_0 = context;
                boolean bl = false;
                DeferredProcessResult.access$setProcessException$p(this.this$0, (Throwable)throwable);
            }
        };
        this.setJob(BuildersKt.launch$default((CoroutineScope)Executor.Companion.getIO_DISPATCH$Executor(), (CoroutineContext)((CoroutineContext)coroutineExceptionHandler), null, (Function2)((Function2)new Function2<CoroutineScope, Continuation<? super Unit>, Object>(this, (Map<String, String>)contextMap, null){
            Object L$0;
            Object L$1;
            int label;
            final /* synthetic */ DeferredProcessResult this$0;
            final /* synthetic */ Map<String, String> $contextMap;
            {
                this.this$0 = $receiver;
                this.$contextMap = $contextMap;
                super(2, $completion);
            }

            /*
             * Exception decompiling
             */
            @Nullable
            public final Object invokeSuspend(@NotNull Object var1_1) {
                /*
                 * This method has failed to decompile.  When submitting a bug report, please provide this stack trace, and (if you hold appropriate legal rights) the relevant class file.
                 * 
                 * org.benf.cfr.reader.util.ConfusedCFRException: Tried to end blocks [14[SWITCH], 17[CASE]], but top level block is 2[TRYBLOCK]
                 *     at org.benf.cfr.reader.bytecode.analysis.opgraph.Op04StructuredStatement.processEndingBlocks(Op04StructuredStatement.java:435)
                 *     at org.benf.cfr.reader.bytecode.analysis.opgraph.Op04StructuredStatement.buildNestedBlocks(Op04StructuredStatement.java:484)
                 *     at org.benf.cfr.reader.bytecode.analysis.opgraph.Op03SimpleStatement.createInitialStructuredBlock(Op03SimpleStatement.java:736)
                 *     at org.benf.cfr.reader.bytecode.CodeAnalyser.getAnalysisInner(CodeAnalyser.java:850)
                 *     at org.benf.cfr.reader.bytecode.CodeAnalyser.getAnalysisOrWrapFail(CodeAnalyser.java:278)
                 *     at org.benf.cfr.reader.bytecode.CodeAnalyser.getAnalysis(CodeAnalyser.java:201)
                 *     at org.benf.cfr.reader.entities.attributes.AttributeCode.analyse(AttributeCode.java:94)
                 *     at org.benf.cfr.reader.entities.Method.dump(Method.java:598)
                 *     at org.benf.cfr.reader.entities.classfilehelpers.ClassFileDumperAnonymousInner.dumpWithArgs(ClassFileDumperAnonymousInner.java:87)
                 *     at org.benf.cfr.reader.bytecode.analysis.parse.expression.ConstructorInvokationAnonymousInner.dumpInner(ConstructorInvokationAnonymousInner.java:82)
                 *     at org.benf.cfr.reader.bytecode.analysis.parse.expression.AbstractExpression.dumpWithOuterPrecedence(AbstractExpression.java:142)
                 *     at org.benf.cfr.reader.bytecode.analysis.parse.expression.CastExpression.dumpInner(CastExpression.java:114)
                 *     at org.benf.cfr.reader.bytecode.analysis.parse.expression.AbstractExpression.dumpWithOuterPrecedence(AbstractExpression.java:139)
                 *     at org.benf.cfr.reader.bytecode.analysis.parse.expression.CastExpression.dumpInner(CastExpression.java:114)
                 *     at org.benf.cfr.reader.bytecode.analysis.parse.expression.AbstractExpression.dumpWithOuterPrecedence(AbstractExpression.java:142)
                 *     at org.benf.cfr.reader.bytecode.analysis.parse.expression.AbstractExpression.dump(AbstractExpression.java:98)
                 *     at org.benf.cfr.reader.state.TypeUsageCollectingDumper.dump(TypeUsageCollectingDumper.java:194)
                 *     at org.benf.cfr.reader.bytecode.analysis.parse.expression.StaticFunctionInvokation.dumpInner(StaticFunctionInvokation.java:143)
                 *     at org.benf.cfr.reader.bytecode.analysis.parse.expression.AbstractExpression.dumpWithOuterPrecedence(AbstractExpression.java:142)
                 *     at org.benf.cfr.reader.bytecode.analysis.parse.expression.AbstractExpression.dump(AbstractExpression.java:98)
                 *     at org.benf.cfr.reader.bytecode.analysis.types.MethodPrototype.dumpAppropriatelyCastedArgumentString(MethodPrototype.java:562)
                 *     at org.benf.cfr.reader.bytecode.analysis.parse.expression.MemberFunctionInvokation.dumpInner(MemberFunctionInvokation.java:63)
                 *     at org.benf.cfr.reader.bytecode.analysis.parse.expression.AbstractExpression.dumpWithOuterPrecedence(AbstractExpression.java:142)
                 *     at org.benf.cfr.reader.bytecode.analysis.parse.expression.AbstractExpression.dump(AbstractExpression.java:98)
                 *     at org.benf.cfr.reader.state.TypeUsageCollectingDumper.dump(TypeUsageCollectingDumper.java:194)
                 *     at org.benf.cfr.reader.bytecode.analysis.structured.statement.StructuredExpressionStatement.dump(StructuredExpressionStatement.java:29)
                 *     at org.benf.cfr.reader.state.TypeUsageCollectingDumper.dump(TypeUsageCollectingDumper.java:194)
                 *     at org.benf.cfr.reader.bytecode.analysis.opgraph.Op04StructuredStatement.dump(Op04StructuredStatement.java:220)
                 *     at org.benf.cfr.reader.bytecode.analysis.structured.statement.Block.dump(Block.java:564)
                 *     at org.benf.cfr.reader.state.TypeUsageCollectingDumper.dump(TypeUsageCollectingDumper.java:194)
                 *     at org.benf.cfr.reader.bytecode.analysis.opgraph.Op04StructuredStatement.dump(Op04StructuredStatement.java:220)
                 *     at org.benf.cfr.reader.entities.attributes.AttributeCode.dump(AttributeCode.java:135)
                 *     at org.benf.cfr.reader.state.TypeUsageCollectingDumper.dump(TypeUsageCollectingDumper.java:194)
                 *     at org.benf.cfr.reader.entities.Method.dump(Method.java:627)
                 *     at org.benf.cfr.reader.entities.classfilehelpers.AbstractClassFileDumper.dumpMethods(AbstractClassFileDumper.java:211)
                 *     at org.benf.cfr.reader.entities.classfilehelpers.ClassFileDumperNormal.dump(ClassFileDumperNormal.java:70)
                 *     at org.benf.cfr.reader.entities.ClassFile.dump(ClassFile.java:1167)
                 *     at org.benf.cfr.reader.entities.ClassFile.analyseTop(ClassFile.java:952)
                 *     at org.benf.cfr.reader.Driver.doJarVersionTypes(Driver.java:257)
                 *     at org.benf.cfr.reader.Driver.doJar(Driver.java:139)
                 *     at org.benf.cfr.reader.CfrDriverImpl.analyse(CfrDriverImpl.java:76)
                 *     at org.benf.cfr.reader.Main.main(Main.java:54)
                 */
                throw new IllegalStateException("Decompilation failed");
            }

            @NotNull
            public final Continuation<Unit> create(@Nullable Object value, @NotNull Continuation<?> $completion) {
                return (Continuation)new /* invalid duplicate definition of identical inner class */;
            }

            @Nullable
            public final Object invoke(@NotNull CoroutineScope p1, @Nullable Continuation<? super Unit> p2) {
                return (this.create(p1, p2)).invokeSuspend(Unit.INSTANCE);
            }
        }), (int)2, null));
    }

    @Nullable
    public final Object await(@NotNull Continuation<? super SyncProcessResult> $completion) {
        return this.await(0L, $completion);
    }

    @Nullable
    public final Object await(long timeoutInMs, @NotNull Continuation<? super SyncProcessResult> $completion) {
        return this.await(timeoutInMs, TimeUnit.MILLISECONDS, $completion);
    }

    @NotNull
    public final SyncProcessResult awaitBlocking() {
        return (SyncProcessResult)BuildersKt.runBlocking$default(null, (Function2)((Function2)new Function2<CoroutineScope, Continuation<? super SyncProcessResult>, Object>(this, null){
            int label;
            final /* synthetic */ DeferredProcessResult this$0;
            {
                this.this$0 = $receiver;
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
                        Object object3 = BuildersKt.withContext((CoroutineContext)((CoroutineContext)Dispatchers.getIO()), (Function2)((Function2)new Function2<CoroutineScope, Continuation<? super SyncProcessResult>, Object>(this.this$0, null){
                            int label;
                            final /* synthetic */ DeferredProcessResult this$0;
                            {
                                this.this$0 = $receiver;
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
                                        Object object3 = this.this$0.await((Continuation<? super SyncProcessResult>)((Continuation)this));
                                        if (object3 != object2) return object3;
                                        return object2;
                                    }
                                    case 1: {
                                        void $result;
                                        ResultKt.throwOnFailure((Object)$result);
                                        Object object3 = $result;
                                        return object3;
                                    }
                                }
                                throw new IllegalStateException("call to 'resume' before 'invoke' with coroutine");
                            }

                            @NotNull
                            public final Continuation<Unit> create(@Nullable Object value, @NotNull Continuation<?> $completion) {
                                return (Continuation)new /* invalid duplicate definition of identical inner class */;
                            }

                            @Nullable
                            public final Object invoke(@NotNull CoroutineScope p1, @Nullable Continuation<? super SyncProcessResult> p2) {
                                return (this.create(p1, p2)).invokeSuspend(Unit.INSTANCE);
                            }
                        }), (Continuation)((Continuation)this));
                        if (object3 != object2) return object3;
                        return object2;
                    }
                    case 1: {
                        void $result;
                        ResultKt.throwOnFailure((Object)$result);
                        Object object3 = $result;
                        return object3;
                    }
                }
                throw new IllegalStateException("call to 'resume' before 'invoke' with coroutine");
            }

            @NotNull
            public final Continuation<Unit> create(@Nullable Object value, @NotNull Continuation<?> $completion) {
                return (Continuation)new /* invalid duplicate definition of identical inner class */;
            }

            @Nullable
            public final Object invoke(@NotNull CoroutineScope p1, @Nullable Continuation<? super SyncProcessResult> p2) {
                return (this.create(p1, p2)).invokeSuspend(Unit.INSTANCE);
            }
        }), (int)1, null);
    }

    @NotNull
    public final SyncProcessResult awaitBlocking(long timeoutInMs) {
        return (SyncProcessResult)BuildersKt.runBlocking$default(null, (Function2)((Function2)new Function2<CoroutineScope, Continuation<? super SyncProcessResult>, Object>(this, timeoutInMs, null){
            int label;
            final /* synthetic */ DeferredProcessResult this$0;
            final /* synthetic */ long $timeoutInMs;
            {
                this.this$0 = $receiver;
                this.$timeoutInMs = $timeoutInMs;
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
                        Object object3 = BuildersKt.withContext((CoroutineContext)((CoroutineContext)Dispatchers.getIO()), (Function2)((Function2)new Function2<CoroutineScope, Continuation<? super SyncProcessResult>, Object>(this.this$0, this.$timeoutInMs, null){
                            int label;
                            final /* synthetic */ DeferredProcessResult this$0;
                            final /* synthetic */ long $timeoutInMs;
                            {
                                this.this$0 = $receiver;
                                this.$timeoutInMs = $timeoutInMs;
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
                                        Object object3 = this.this$0.await(this.$timeoutInMs, TimeUnit.MILLISECONDS, (Continuation<? super SyncProcessResult>)((Continuation)this));
                                        if (object3 != object2) return object3;
                                        return object2;
                                    }
                                    case 1: {
                                        void $result;
                                        ResultKt.throwOnFailure((Object)$result);
                                        Object object3 = $result;
                                        return object3;
                                    }
                                }
                                throw new IllegalStateException("call to 'resume' before 'invoke' with coroutine");
                            }

                            @NotNull
                            public final Continuation<Unit> create(@Nullable Object value, @NotNull Continuation<?> $completion) {
                                return (Continuation)new /* invalid duplicate definition of identical inner class */;
                            }

                            @Nullable
                            public final Object invoke(@NotNull CoroutineScope p1, @Nullable Continuation<? super SyncProcessResult> p2) {
                                return (this.create(p1, p2)).invokeSuspend(Unit.INSTANCE);
                            }
                        }), (Continuation)((Continuation)this));
                        if (object3 != object2) return object3;
                        return object2;
                    }
                    case 1: {
                        void $result;
                        ResultKt.throwOnFailure((Object)$result);
                        Object object3 = $result;
                        return object3;
                    }
                }
                throw new IllegalStateException("call to 'resume' before 'invoke' with coroutine");
            }

            @NotNull
            public final Continuation<Unit> create(@Nullable Object value, @NotNull Continuation<?> $completion) {
                return (Continuation)new /* invalid duplicate definition of identical inner class */;
            }

            @Nullable
            public final Object invoke(@NotNull CoroutineScope p1, @Nullable Continuation<? super SyncProcessResult> p2) {
                return (this.create(p1, p2)).invokeSuspend(Unit.INSTANCE);
            }
        }), (int)1, null);
    }

    @NotNull
    public final SyncProcessResult awaitBlocking(long timeout, @NotNull TimeUnit timeoutUnit) {
        Intrinsics.checkNotNullParameter((Object)((Object)timeoutUnit), (String)"timeoutUnit");
        return (SyncProcessResult)BuildersKt.runBlocking$default(null, (Function2)((Function2)new Function2<CoroutineScope, Continuation<? super SyncProcessResult>, Object>(this, timeout, timeoutUnit, null){
            int label;
            final /* synthetic */ DeferredProcessResult this$0;
            final /* synthetic */ long $timeout;
            final /* synthetic */ TimeUnit $timeoutUnit;
            {
                this.this$0 = $receiver;
                this.$timeout = $timeout;
                this.$timeoutUnit = $timeoutUnit;
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
                        Object object3 = BuildersKt.withContext((CoroutineContext)((CoroutineContext)Dispatchers.getIO()), (Function2)((Function2)new Function2<CoroutineScope, Continuation<? super SyncProcessResult>, Object>(this.this$0, this.$timeout, this.$timeoutUnit, null){
                            int label;
                            final /* synthetic */ DeferredProcessResult this$0;
                            final /* synthetic */ long $timeout;
                            final /* synthetic */ TimeUnit $timeoutUnit;
                            {
                                this.this$0 = $receiver;
                                this.$timeout = $timeout;
                                this.$timeoutUnit = $timeoutUnit;
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
                                        Object object3 = this.this$0.await(this.$timeout, this.$timeoutUnit, (Continuation<? super SyncProcessResult>)((Continuation)this));
                                        if (object3 != object2) return object3;
                                        return object2;
                                    }
                                    case 1: {
                                        void $result;
                                        ResultKt.throwOnFailure((Object)$result);
                                        Object object3 = $result;
                                        return object3;
                                    }
                                }
                                throw new IllegalStateException("call to 'resume' before 'invoke' with coroutine");
                            }

                            @NotNull
                            public final Continuation<Unit> create(@Nullable Object value, @NotNull Continuation<?> $completion) {
                                return (Continuation)new /* invalid duplicate definition of identical inner class */;
                            }

                            @Nullable
                            public final Object invoke(@NotNull CoroutineScope p1, @Nullable Continuation<? super SyncProcessResult> p2) {
                                return (this.create(p1, p2)).invokeSuspend(Unit.INSTANCE);
                            }
                        }), (Continuation)((Continuation)this));
                        if (object3 != object2) return object3;
                        return object2;
                    }
                    case 1: {
                        void $result;
                        ResultKt.throwOnFailure((Object)$result);
                        Object object3 = $result;
                        return object3;
                    }
                }
                throw new IllegalStateException("call to 'resume' before 'invoke' with coroutine");
            }

            @NotNull
            public final Continuation<Unit> create(@Nullable Object value, @NotNull Continuation<?> $completion) {
                return (Continuation)new /* invalid duplicate definition of identical inner class */;
            }

            @Nullable
            public final Object invoke(@NotNull CoroutineScope p1, @Nullable Continuation<? super SyncProcessResult> p2) {
                return (this.create(p1, p2)).invokeSuspend(Unit.INSTANCE);
            }
        }), (int)1, null);
    }

    /*
     * Unable to fully structure code
     */
    @Nullable
    public final Object await(long var1_1, @NotNull TimeUnit var3_2, @NotNull Continuation<? super SyncProcessResult> var4_3) {
        if (!(var4_3 instanceof await.3)) ** GOTO lbl-1000
        var24_4 = var4_3;
        if ((var24_4.label & -2147483648) != 0) {
            var24_4.label -= -2147483648;
        } else lbl-1000:
        // 2 sources

        {
            $continuation = new ContinuationImpl(this, var4_3){
                Object L$0;
                Object L$1;
                long J$0;
                /* synthetic */ Object result;
                final /* synthetic */ DeferredProcessResult this$0;
                int label;
                {
                    this.this$0 = this$0;
                    super($completion);
                }

                @Nullable
                public final Object invokeSuspend(@NotNull Object $result) {
                    this.result = $result;
                    this.label |= Integer.MIN_VALUE;
                    return this.this$0.await(0L, null, (Continuation<? super SyncProcessResult>)((Continuation)this));
                }
            };
        }
        $result = $continuation.result;
        var25_6 = IntrinsicsKt.getCOROUTINE_SUSPENDED();
        switch ($continuation.label) {
            case 0: {
                ResultKt.throwOnFailure((Object)$result);
                timeout = timeout;
                timeoutUnit = timeoutUnit;
                if (timeout == 0L) {
                    timeout = 0x7FFFFFFFFFFFFFFFL;
                    timeoutUnit = TimeUnit.DAYS;
                }
                this.setCalledAwait(true);
                this.setWaiting(true);
                $continuation.L$0 = this;
                $continuation.L$1 = timeoutUnit;
                $continuation.J$0 = timeout;
                $continuation.label = 1;
                v0 = TimeoutKt.withTimeoutOrNull((long)timeoutUnit.toMillis(timeout), (Function2)((Function2)new Function2<CoroutineScope, Continuation<? super Unit>, Object>(this, null){
                    int label;
                    final /* synthetic */ DeferredProcessResult this$0;
                    {
                        this.this$0 = $receiver;
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
                                Object object3 = SuspendNotifier.doWait-impl((Channel<Unit>)DeferredProcessResult.access$getWaiter$p(this.this$0), (Continuation<? super Unit>)((Continuation)this));
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
                                catch (CancellationException cancellationException) {
                                    // empty catch block
                                }
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
                }), (Continuation)$continuation);
                if (v0 == var25_6) {
                    return var25_6;
                }
                ** GOTO lbl33
            }
            case 1: {
                timeout = $continuation.J$0;
                timeoutUnit = (TimeUnit)$continuation.L$1;
                this = (DeferredProcessResult)$continuation.L$0;
                ResultKt.throwOnFailure((Object)$result);
                v0 = $result;
lbl33:
                // 2 sources

                this.setWaiting(false);
                if (this.getProcessResult() != null) {
                    v1 = this.getProcessResult();
                    Intrinsics.checkNotNull((Object)v1);
                    return v1;
                }
                exception = this.processException;
                if (exception == null) {
                    var9_10 = this.getThread().getStackTrace();
                    Intrinsics.checkNotNullExpressionValue((Object)var9_10, (String)"thread.stackTrace");
                    exception = this.newTimeoutException(this.process, var9_10, timeout, timeoutUnit);
                }
                stackTrace = Thread.currentThread().getStackTrace();
                caller = stackTrace[2].getClassName();
                newTrace = new ArrayList<E>();
                foundCaller = false;
                doneWithCoroutineStack = false;
                Intrinsics.checkNotNullExpressionValue((Object)stackTrace, (String)"stackTrace");
                $this$forEach$iv = stackTrace;
                $i$f$forEach = false;
                for (StackTraceElement element$iv : $this$forEach$iv) {
                    it = element$iv;
                    $i$a$-forEach-DeferredProcessResult$await$5 = false;
                    if (!foundCaller) continue;
                    if (doneWithCoroutineStack) {
                        Intrinsics.checkNotNullExpressionValue((Object)it, (String)"it");
                        newTrace.add(it);
                        continue;
                    }
                    var22_23 = it.getClassName();
                    Intrinsics.checkNotNullExpressionValue((Object)var22_23, (String)"it.className");
                    if (StringsKt.startsWith$default((String)var22_23, (String)"kotlin.coroutines", (boolean)false, (int)2, null)) continue;
                    var22_23 = it.getClassName();
                    Intrinsics.checkNotNullExpressionValue((Object)var22_23, (String)"it.className");
                    if (StringsKt.startsWith$default((String)var22_23, (String)"kotlinx.coroutines", (boolean)false, (int)2, null)) continue;
                    doneWithCoroutineStack = true;
                    Intrinsics.checkNotNullExpressionValue((Object)it, (String)"it");
                    newTrace.add(it);
                }
                $this$toTypedArray$iv = newTrace;
                $i$f$toTypedArray = false;
                thisCollection$iv = $this$toTypedArray$iv;
                v2 = thisCollection$iv.toArray(new StackTraceElement[0]);
                if (v2 == null) {
                    throw new NullPointerException("null cannot be cast to non-null type kotlin.Array<T of kotlin.collections.ArraysKt__ArraysJVMKt.toTypedArray>");
                }
                exception.setStackTrace(v2);
                Job.DefaultImpls.cancel$default((Job)this.getJob(), null, (int)1, null);
                this.getThread().interrupt();
                throw exception;
            }
        }
        throw new IllegalStateException("call to 'resume' before 'invoke' with coroutine");
    }

    /*
     * WARNING - Removed try catching itself - possible behaviour change.
     * Unable to fully structure code
     */
    private final Object waitForProcessToComplete(Continuation<? super Integer> var1_1) {
        block20: {
            block19: {
                block18: {
                    if (!(var1_1 instanceof waitForProcessToComplete.1)) ** GOTO lbl-1000
                    var7_2 = var1_1;
                    if ((var7_2.label & -2147483648) != 0) {
                        var7_2.label -= -2147483648;
                    } else lbl-1000:
                    // 2 sources

                    {
                        $continuation = new ContinuationImpl(this, var1_1){
                            int I$0;
                            Object L$0;
                            /* synthetic */ Object result;
                            final /* synthetic */ DeferredProcessResult this$0;
                            int label;
                            {
                                this.this$0 = this$0;
                                super($completion);
                            }

                            @Nullable
                            public final Object invokeSuspend(@NotNull Object $result) {
                                this.result = $result;
                                this.label |= Integer.MIN_VALUE;
                                return DeferredProcessResult.access$waitForProcessToComplete(this.this$0, (Continuation)this);
                            }
                        };
                    }
                    $result = $continuation.result;
                    var8_4 = IntrinsicsKt.getCOROUTINE_SUSPENDED();
                    switch ($continuation.label) {
                        case 0: {
                            ResultKt.throwOnFailure((Object)$result);
                            finished = new Ref.BooleanRef();
                            exit = this.process.waitFor();
                            finished.element = true;
                            var4_7 = new Object[]{this, Boxing.boxInt((int)exit)};
                            LogHelper.INSTANCE.logAtLowestLevel(this.params.getLogger(), "{} stopped with exit code {}", var4_7);
                            if (finished.element) ** GOTO lbl23
                            var4_7 = new Object[]{this};
                            LogHelper.INSTANCE.logAtLowestLevel(this.params.getLogger(), "Stopping {}...", var4_7);
                            this.params.getStopper().stop(this.process);
lbl23:
                            // 2 sources

                            if (this.params.getCloseTimeout() != 0L) break;
                            $continuation.I$0 = exit;
                            $continuation.label = 1;
                            v0 = this.params.getStreams().stop(this.process, finished.element, (Continuation<? super Unit>)$continuation);
                            if (v0 == var8_4) {
                                return var8_4;
                            }
                            break block20;
                        }
                        case 1: {
                            exit = $continuation.I$0;
                            ResultKt.throwOnFailure((Object)$result);
                            v0 = $result;
                            break block20;
                        }
                    }
                    try {
                        BuildersKt.launch$default((CoroutineScope)Executor.Companion.getIO_DISPATCH$Executor(), null, null, (Function2)((Function2)new Function2<CoroutineScope, Continuation<? super Unit>, Object>(this, finished, null){
                            int label;
                            final /* synthetic */ DeferredProcessResult this$0;
                            final /* synthetic */ Ref.BooleanRef $finished;
                            {
                                this.this$0 = $receiver;
                                this.$finished = $finished;
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
                                        Object object3 = TimeoutKt.withTimeout((long)DeferredProcessResult.access$getParams$p(this.this$0).getCloseTimeoutUnit().toMillis(DeferredProcessResult.access$getParams$p(this.this$0).getCloseTimeout()), (Function2)((Function2)new Function2<CoroutineScope, Continuation<? super Unit>, Object>(this.this$0, this.$finished, null){
                                            int label;
                                            final /* synthetic */ DeferredProcessResult this$0;
                                            final /* synthetic */ Ref.BooleanRef $finished;
                                            {
                                                this.this$0 = $receiver;
                                                this.$finished = $finished;
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
                                                        Object object3 = DeferredProcessResult.access$getParams$p(this.this$0).getStreams().stop(DeferredProcessResult.access$getProcess$p(this.this$0), this.$finished.element, (Continuation<? super Unit>)((Continuation)this));
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
                                        }), (Continuation)((Continuation)this));
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
                    catch (ExecutionException e) {
                        throw new IllegalStateException(Intrinsics.stringPlus((String)"Could not close streams of ", (Object)this.process), e.getCause());
                    }
                    catch (TimeoutCancellationException var4_9) {
                        DeferredProcessResult.log.warn("Could not close streams of " + this.process + " in " + this.params.getCloseTimeout() + ' ' + this.getUnitsAsString(this.params.getCloseTimeout(), this.params.getCloseTimeoutUnit()));
                    }
                    break block20;
                    catch (Throwable var4_10) {
                        if (!finished.element) {
                            var5_12 = new Object[]{this};
                            LogHelper.INSTANCE.logAtLowestLevel(this.params.getLogger(), "Stopping {}...", var5_12);
                            this.params.getStopper().stop(this.process);
                        }
                        if (this.params.getCloseTimeout() != 0L) break block18;
                        $continuation.L$0 = var4_10;
                        $continuation.label = 2;
                        v1 = this.params.getStreams().stop(this.process, finished.element, (Continuation<? super Unit>)$continuation);
                        if (v1 == var8_4) {
                            return var8_4;
                        }
                        break block19;
                    }
                    {
                        case 2: {
                            var4_11 = (Throwable)$continuation.L$0;
                            ResultKt.throwOnFailure((Object)$result);
                            v1 = $result;
                            break block19;
                        }
                    }
                }
                try {
                    BuildersKt.launch$default((CoroutineScope)Executor.Companion.getIO_DISPATCH$Executor(), null, null, (Function2)((Function2)new /* invalid duplicate definition of identical inner class */), (int)3, null);
                }
                catch (ExecutionException e) {
                    throw new IllegalStateException(Intrinsics.stringPlus((String)"Could not close streams of ", (Object)this.process), e.getCause());
                }
                catch (TimeoutCancellationException var5_14) {
                    DeferredProcessResult.log.warn("Could not close streams of " + this.process + " in " + this.params.getCloseTimeout() + ' ' + this.getUnitsAsString(this.params.getCloseTimeout(), this.params.getCloseTimeoutUnit()));
                }
            }
            throw var4_11;
        }
        return Boxing.boxInt((int)exit);
        throw new IllegalStateException("call to 'resume' before 'invoke' with coroutine");
    }

    /*
     * Exception decompiling
     */
    @ExperimentalCoroutinesApi
    private final Object finishWaiting(int var1_1, Continuation<? super SyncProcessResult> var2_2) {
        /*
         * This method has failed to decompile.  When submitting a bug report, please provide this stack trace, and (if you hold appropriate legal rights) the relevant class file.
         * 
         * org.benf.cfr.reader.util.ConfusedCFRException: Tried to end blocks [0[TRYBLOCK]], but top level block is 7[WHILELOOP]
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

    @NotNull
    public final AsyncProcessOutput getOutput() {
        Lazy lazy = this.output$delegate;
        return (AsyncProcessOutput)lazy.getValue();
    }

    public final long getPid() {
        return this.pid;
    }

    public final void writeLine(@NotNull String command) {
        Intrinsics.checkNotNullParameter((Object)command, (String)"command");
        OutputStream outputStream = this.process.getOutputStream();
        byte[] byArray = command.getBytes(Charsets.UTF_8);
        Intrinsics.checkNotNullExpressionValue((Object)byArray, (String)"this as java.lang.String).getBytes(charset)");
        outputStream.write(byArray);
        outputStream.write(EOL);
        try {
            outputStream.flush();
        }
        catch (Exception exception) {
            // empty catch block
        }
    }

    public final void write(@NotNull String command) {
        Intrinsics.checkNotNullParameter((Object)command, (String)"command");
        byte[] byArray = command.getBytes(Charsets.UTF_8);
        Intrinsics.checkNotNullExpressionValue((Object)byArray, (String)"this as java.lang.String).getBytes(charset)");
        this.write(byArray);
    }

    public final void write(@NotNull byte[] bytes) {
        Intrinsics.checkNotNullParameter((Object)bytes, (String)"bytes");
        this.process.getOutputStream().write(bytes);
        this.flush();
    }

    public final void flush() {
        try {
            this.process.getOutputStream().flush();
        }
        catch (Exception exception) {
            // empty catch block
        }
    }

    public final void cancel(@NotNull String message, @Nullable Throwable cause) {
        Intrinsics.checkNotNullParameter((Object)message, (String)"message");
        if (!this.waiting) {
            throw new IllegalStateException("Unable to cancel a process is not waiting.");
        }
        StringBuilder sb = new StringBuilder();
        if (((CharSequence)message).length() == 0) {
            sb.append("Process [pid=" + PidHelper.INSTANCE.get(this.process) + "] has been cancelled");
        } else {
            sb.append(message);
        }
        this.params.getErrorMessageHandler().invoke((Object)sb);
        CancellationException exception = ExceptionsKt.CancellationException((String)sb.toString(), (Throwable)cause);
        exception.setStackTrace(this.launchingThread.getStackTrace());
        this.processException = exception;
        SuspendNotifier.cancel-impl(this.waiter);
    }

    public static /* synthetic */ void cancel$default(DeferredProcessResult deferredProcessResult, String string2, Throwable throwable, int n, Object object) {
        if ((n & 1) != 0) {
            string2 = "";
        }
        if ((n & 2) != 0) {
            throwable = null;
        }
        deferredProcessResult.cancel(string2, throwable);
    }

    private final TimeoutException newTimeoutException(Process process, StackTraceElement[] processStackTrace, long timeout, TimeUnit timeoutUnit) {
        StringBuilder sb = new StringBuilder();
        Integer exitValue = this.getExitCodeOrNull(process);
        if (exitValue == null) {
            sb.append("Timed out waiting for ").append(process).append(" to finish");
        } else {
            sb.append("Timed out finishing ").append(process);
            sb.append(", exit value: ").append(exitValue);
        }
        sb.append(", timeout: ").append(timeout).append(" ").append(this.getUnitsAsString(timeout, timeoutUnit));
        this.params.getErrorMessageHandler().invoke((Object)sb);
        TimeoutException newException = new TimeoutException(sb.toString());
        if (exitValue != null) {
            Exception cause = new Exception("Stack dump of worker thread.");
            cause.setStackTrace(processStackTrace);
            newException.initCause(cause);
        }
        return newException;
    }

    private final String getUnitsAsString(long timeout, TimeUnit timeUnit) {
        String string2;
        String result = timeUnit.toChronoUnit().name();
        if (timeout == 1L) {
            String string3 = result.substring(0, result.length() - 1);
            Intrinsics.checkNotNullExpressionValue((Object)string3, (String)"this as java.lang.String\u2026ing(startIndex, endIndex)");
            string2 = string3;
        } else {
            string2 = result;
        }
        return string2;
    }

    private final Integer getExitCodeOrNull(Process process) {
        Integer n;
        try {
            Process process2 = process;
            Intrinsics.checkNotNull((Object)process2);
            n = process2.exitValue();
        }
        catch (IllegalThreadStateException e) {
            n = null;
        }
        return n;
    }

    public static final /* synthetic */ Object access$waitForProcessToComplete(DeferredProcessResult $this, Continuation $completion) {
        return $this.waitForProcessToComplete((Continuation<? super Integer>)$completion);
    }

    public static final /* synthetic */ Object access$finishWaiting(DeferredProcessResult $this, int exitCode, Continuation $completion) {
        return $this.finishWaiting(exitCode, (Continuation<? super SyncProcessResult>)$completion);
    }

    public static final /* synthetic */ void access$setProcessException$p(DeferredProcessResult $this, Throwable throwable) {
        $this.processException = throwable;
    }

    public static final /* synthetic */ Channel access$getWaiter$p(DeferredProcessResult $this) {
        return $this.waiter;
    }

    public static final /* synthetic */ Params access$getParams$p(DeferredProcessResult $this) {
        return $this.params;
    }

    public static final /* synthetic */ Process access$getProcess$p(DeferredProcessResult $this) {
        return $this.process;
    }

    static {
        byte[] byArray = "\n".getBytes(Charsets.UTF_8);
        Intrinsics.checkNotNullExpressionValue((Object)byArray, (String)"this as java.lang.String).getBytes(charset)");
        EOL = byArray;
        log = LoggerFactory.getLogger(DeferredProcessResult.class);
    }

    @Metadata(mv={1, 6, 0}, k=1, xi=48, d1={"\u0000F\n\u0002\u0018\u0002\n\u0002\u0010\u0000\n\u0002\b\u0002\n\u0002\u0010\u0012\n\u0000\n\u0002\u0010\b\n\u0000\n\u0002\u0018\u0002\n\u0002\b\u0002\n\u0002\u0010\u0002\n\u0000\n\u0002\u0018\u0002\n\u0000\n\u0002\u0018\u0002\n\u0002\u0018\u0002\n\u0000\n\u0002\u0010\u000e\n\u0002\b\u0003\n\u0002\u0018\u0002\n\u0002\b\u0002\b\u0086\u0003\u0018\u00002\u00020\u0001B\u0007\b\u0002\u00a2\u0006\u0002\u0010\u0002J)\u0010\n\u001a\u00020\u000b2\u0006\u0010\f\u001a\u00020\r2\n\u0010\u000e\u001a\u00060\u000fj\u0002`\u00102\u0006\u0010\u0011\u001a\u00020\u0012H\u0000\u00a2\u0006\u0002\b\u0013J\u001d\u0010\u0014\u001a\u00020\u000b2\u0006\u0010\f\u001a\u00020\r2\u0006\u0010\u0015\u001a\u00020\u0016H\u0000\u00a2\u0006\u0002\b\u0017R\u000e\u0010\u0003\u001a\u00020\u0004X\u0082\u0004\u00a2\u0006\u0002\n\u0000R\u000e\u0010\u0005\u001a\u00020\u0006X\u0082T\u00a2\u0006\u0002\n\u0000R\u0016\u0010\u0007\u001a\n \t*\u0004\u0018\u00010\b0\bX\u0082\u0004\u00a2\u0006\u0002\n\u0000\u00a8\u0006\u0018"}, d2={"Ldorkbox/executor/DeferredProcessResult$Companion;", "", "()V", "EOL", "", "MAX_OUTPUT_SIZE_IN_ERROR_MESSAGE", "", "log", "Lorg/slf4j/Logger;", "kotlin.jvm.PlatformType", "addExceptionMessageSuffix", "", "attributes", "Ldorkbox/executor/ProcessAttributes;", "sb", "Ljava/lang/StringBuilder;", "Lkotlin/text/StringBuilder;", "outputText", "", "addExceptionMessageSuffix$Executor", "checkExit", "result", "Ldorkbox/executor/processResults/ProcessResult;", "checkExit$Executor", "Executor"})
    public static final class Companion {
        private Companion() {
        }

        public final void checkExit$Executor(@NotNull ProcessAttributes attributes, @NotNull ProcessResult result) {
            Intrinsics.checkNotNullParameter((Object)attributes, (String)"attributes");
            Intrinsics.checkNotNullParameter((Object)result, (String)"result");
            Set<Integer> allowedExitValues = attributes.getAllowedExitValues();
            int exitValue = result.getExitValue();
            if (!((Collection)allowedExitValues).isEmpty() && !allowedExitValues.contains(exitValue)) {
                StringBuilder sb = new StringBuilder();
                sb.append("Unexpected exit value: ").append(exitValue);
                sb.append(", allowed exit values: ").append(allowedExitValues);
                if (result.getHasOutput() && result instanceof SyncProcessResult) {
                    this.addExceptionMessageSuffix$Executor(attributes, sb, ((SyncProcessResult)result).getOutput().string());
                }
                String string2 = sb.toString();
                Intrinsics.checkNotNullExpressionValue((Object)string2, (String)"sb.toString()");
                throw new InvalidExitValueException(string2, result);
            }
        }

        public final void addExceptionMessageSuffix$Executor(@NotNull ProcessAttributes attributes, @NotNull StringBuilder sb, @NotNull String outputText) {
            int length;
            Intrinsics.checkNotNullParameter((Object)attributes, (String)"attributes");
            Intrinsics.checkNotNullParameter((Object)sb, (String)"sb");
            Intrinsics.checkNotNullParameter((Object)outputText, (String)"outputText");
            sb.append(", executed command ").append(attributes.getCommand());
            if (attributes.getDirectory() != null) {
                sb.append(" in directory ").append(attributes.getDirectory());
            }
            if (!attributes.getEnvironment().isEmpty()) {
                sb.append(" with environment ").append(attributes.getEnvironment());
            }
            if ((length = outputText.length()) <= 5000) {
                sb.append(", output was ").append(length).append(" bytes:\n").append(((Object)StringsKt.trim((CharSequence)outputText)).toString());
            } else {
                sb.append(", output was ").append(length).append(" bytes (truncated):\n");
                int halfLimit = 2500;
                String string2 = outputText;
                int n = 0;
                String string3 = string2.substring(n, halfLimit);
                Intrinsics.checkNotNullExpressionValue((Object)string3, (String)"this as java.lang.String\u2026ing(startIndex, endIndex)");
                StringBuilder stringBuilder = sb.append(string3).append("\n...\n");
                string2 = outputText;
                n = length - halfLimit;
                string3 = string2.substring(n);
                Intrinsics.checkNotNullExpressionValue((Object)string3, (String)"this as java.lang.String).substring(startIndex)");
                stringBuilder.append(((Object)StringsKt.trim((CharSequence)string3)).toString());
            }
        }

        public /* synthetic */ Companion(DefaultConstructorMarker $constructor_marker) {
            this();
        }
    }
}

