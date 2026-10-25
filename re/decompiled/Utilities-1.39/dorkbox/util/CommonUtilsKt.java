/*
 * Decompiled with CFR 0.152.
 * 
 * Could not load the following classes:
 *  kotlin.Metadata
 *  kotlin.ResultKt
 *  kotlin.Unit
 *  kotlin.coroutines.Continuation
 *  kotlin.coroutines.CoroutineContext
 *  kotlin.coroutines.CoroutineContext$Key
 *  kotlin.coroutines.intrinsics.IntrinsicsKt
 *  kotlin.jvm.functions.Function0
 *  kotlin.jvm.functions.Function1
 *  kotlin.jvm.functions.Function2
 *  kotlin.jvm.internal.InlineMarker
 *  kotlin.jvm.internal.Intrinsics
 *  kotlinx.coroutines.BuildersKt
 *  kotlinx.coroutines.CoroutineDispatcher
 *  kotlinx.coroutines.CoroutineScope
 *  kotlinx.coroutines.Dispatchers
 *  kotlinx.coroutines.GlobalScope
 *  kotlinx.coroutines.Job
 *  kotlinx.coroutines.sync.Mutex
 *  org.jetbrains.annotations.NotNull
 *  org.jetbrains.annotations.Nullable
 */
package dorkbox.util;

import dorkbox.util.ReentrantMutexContextElement;
import dorkbox.util.ReentrantMutexContextKey;
import java.io.PrintWriter;
import java.io.StringWriter;
import kotlin.Metadata;
import kotlin.ResultKt;
import kotlin.Unit;
import kotlin.coroutines.Continuation;
import kotlin.coroutines.CoroutineContext;
import kotlin.coroutines.intrinsics.IntrinsicsKt;
import kotlin.jvm.functions.Function0;
import kotlin.jvm.functions.Function1;
import kotlin.jvm.functions.Function2;
import kotlin.jvm.internal.InlineMarker;
import kotlin.jvm.internal.Intrinsics;
import kotlinx.coroutines.BuildersKt;
import kotlinx.coroutines.CoroutineDispatcher;
import kotlinx.coroutines.CoroutineScope;
import kotlinx.coroutines.Dispatchers;
import kotlinx.coroutines.GlobalScope;
import kotlinx.coroutines.Job;
import kotlinx.coroutines.sync.Mutex;
import org.jetbrains.annotations.NotNull;
import org.jetbrains.annotations.Nullable;

@Metadata(mv={1, 7, 1}, k=2, xi=48, d1={"\u0000V\n\u0000\n\u0002\u0018\u0002\n\u0000\n\u0002\u0018\u0002\n\u0000\n\u0002\u0018\u0002\n\u0002\u0018\u0002\n\u0002\u0018\u0002\n\u0002\u0010\u0002\n\u0002\u0010\u0000\n\u0002\u0018\u0002\n\u0002\b\u0005\n\u0002\u0018\u0002\n\u0002\b\u0002\n\u0002\u0010\u0011\n\u0002\b\u0002\n\u0002\u0010\u000e\n\u0002\u0018\u0002\n\u0002\u0018\u0002\n\u0002\b\u0002\n\u0002\u0018\u0002\n\u0002\u0018\u0002\n\u0002\b\u0002\u001a?\u0010\u0000\u001a\u00020\u00012\u0006\u0010\u0002\u001a\u00020\u00032'\u0010\u0004\u001a#\b\u0001\u0012\u0004\u0012\u00020\u0006\u0012\n\u0012\b\u0012\u0004\u0012\u00020\b0\u0007\u0012\u0006\u0012\u0004\u0018\u00010\t0\u0005\u00a2\u0006\u0002\b\n\u00f8\u0001\u0000\u00a2\u0006\u0002\u0010\u000b\u001a7\u0010\f\u001a\u00020\u00012'\u0010\u0004\u001a#\b\u0001\u0012\u0004\u0012\u00020\u0006\u0012\n\u0012\b\u0012\u0004\u0012\u00020\b0\u0007\u0012\u0006\u0012\u0004\u0018\u00010\t0\u0005\u00a2\u0006\u0002\b\n\u00f8\u0001\u0000\u00a2\u0006\u0002\u0010\r\u001a\u001a\u0010\u000e\u001a\u00020\b2\f\u0010\u000f\u001a\b\u0012\u0004\u0012\u00020\b0\u0010H\u0086\b\u00f8\u0001\u0001\u001a.\u0010\u0011\u001a\u00020\b2\u001e\u0010\u0012\u001a\u0010\u0012\f\b\u0001\u0012\b\u0012\u0004\u0012\u00020\b0\u00100\u0013\"\b\u0012\u0004\u0012\u00020\b0\u0010H\u0086\b\u00a2\u0006\u0002\u0010\u0014\u001a\u000e\u0010\u0015\u001a\u00020\u0016*\u00060\u0017j\u0002`\u0018\u001a;\u0010\u0019\u001a\u0002H\u001a\"\u0004\b\u0000\u0010\u001a*\u00020\u001b2\u001e\b\u0004\u0010\u000f\u001a\u0018\b\u0001\u0012\n\u0012\b\u0012\u0004\u0012\u0002H\u001a0\u0007\u0012\u0006\u0012\u0004\u0018\u00010\t0\u001cH\u0086H\u00f8\u0001\u0000\u00a2\u0006\u0002\u0010\u001d\u0082\u0002\u000b\n\u0002\b\u0019\n\u0005\b\u009920\u0001\u00a8\u0006\u001e"}, d2={"async", "Lkotlinx/coroutines/Job;", "dispatcher", "Lkotlinx/coroutines/CoroutineDispatcher;", "action", "Lkotlin/Function2;", "Lkotlinx/coroutines/CoroutineScope;", "Lkotlin/coroutines/Continuation;", "", "", "Lkotlin/ExtensionFunctionType;", "(Lkotlinx/coroutines/CoroutineDispatcher;Lkotlin/jvm/functions/Function2;)Lkotlinx/coroutines/Job;", "asyncIO", "(Lkotlin/jvm/functions/Function2;)Lkotlinx/coroutines/Job;", "ignoreException", "block", "Lkotlin/Function0;", "ignoreExceptions", "blocks", "", "([Lkotlin/jvm/functions/Function0;)V", "stackTraceToString", "", "Ljava/lang/Exception;", "Lkotlin/Exception;", "withReentrantLock", "T", "Lkotlinx/coroutines/sync/Mutex;", "Lkotlin/Function1;", "(Lkotlinx/coroutines/sync/Mutex;Lkotlin/jvm/functions/Function1;Lkotlin/coroutines/Continuation;)Ljava/lang/Object;", "Utilities"})
public final class CommonUtilsKt {
    @NotNull
    public static final String stackTraceToString(@NotNull Exception $this$stackTraceToString) {
        Intrinsics.checkNotNullParameter((Object)$this$stackTraceToString, (String)"<this>");
        StringWriter exceptionWriter = new StringWriter();
        $this$stackTraceToString.printStackTrace(new PrintWriter(exceptionWriter));
        String string = exceptionWriter.toString();
        Intrinsics.checkNotNullExpressionValue((Object)string, (String)"exceptionWriter.toString()");
        return string;
    }

    public static final void ignoreException(@NotNull Function0<Unit> block) {
        Intrinsics.checkNotNullParameter(block, (String)"block");
        boolean $i$f$ignoreException = false;
        try {
            block.invoke();
        }
        catch (Exception exception) {
            // empty catch block
        }
    }

    public static final void ignoreExceptions(Function0<Unit> ... blocks) {
        Intrinsics.checkNotNullParameter(blocks, (String)"blocks");
        boolean $i$f$ignoreExceptions = false;
        Function0<Unit>[] $this$forEach$iv = blocks;
        boolean $i$f$forEach = false;
        int n = $this$forEach$iv.length;
        for (int i = 0; i < n; ++i) {
            Function0<Unit> element$iv;
            Function0<Unit> block = element$iv = $this$forEach$iv[i];
            boolean bl = false;
            try {
                block.invoke();
                continue;
            }
            catch (Exception exception) {
            }
        }
    }

    @NotNull
    public static final Job async(@NotNull CoroutineDispatcher dispatcher, @NotNull Function2<? super CoroutineScope, ? super Continuation<? super Unit>, ? extends Object> action) {
        Intrinsics.checkNotNullParameter((Object)dispatcher, (String)"dispatcher");
        Intrinsics.checkNotNullParameter(action, (String)"action");
        return BuildersKt.launch$default((CoroutineScope)((CoroutineScope)GlobalScope.INSTANCE), (CoroutineContext)((CoroutineContext)dispatcher), null, (Function2)((Function2)new Function2<CoroutineScope, Continuation<? super Unit>, Object>(action, null){
            int label;
            private /* synthetic */ Object L$0;
            final /* synthetic */ Function2<CoroutineScope, Continuation<? super Unit>, Object> $action;
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
                        CoroutineScope $this$launch = (CoroutineScope)this.L$0;
                        this.label = 1;
                        Object object3 = this.$action.invoke((Object)$this$launch, (Object)((Object)this));
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
                Function2<CoroutineScope, Continuation<? super Unit>, Object> function2 = new /* invalid duplicate definition of identical inner class */;
                function2.L$0 = value;
                return (Continuation)function2;
            }

            @Nullable
            public final Object invoke(@NotNull CoroutineScope p1, @Nullable Continuation<? super Unit> p2) {
                return (this.create(p1, p2)).invokeSuspend(Unit.INSTANCE);
            }
        }), (int)2, null);
    }

    @NotNull
    public static final Job asyncIO(@NotNull Function2<? super CoroutineScope, ? super Continuation<? super Unit>, ? extends Object> action) {
        Intrinsics.checkNotNullParameter(action, (String)"action");
        return BuildersKt.launch$default((CoroutineScope)((CoroutineScope)GlobalScope.INSTANCE), (CoroutineContext)((CoroutineContext)Dispatchers.getIO()), null, (Function2)((Function2)new Function2<CoroutineScope, Continuation<? super Unit>, Object>(action, null){
            int label;
            private /* synthetic */ Object L$0;
            final /* synthetic */ Function2<CoroutineScope, Continuation<? super Unit>, Object> $action;
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
                        CoroutineScope $this$launch = (CoroutineScope)this.L$0;
                        this.label = 1;
                        Object object3 = this.$action.invoke((Object)$this$launch, (Object)((Object)this));
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
                Function2<CoroutineScope, Continuation<? super Unit>, Object> function2 = new /* invalid duplicate definition of identical inner class */;
                function2.L$0 = value;
                return (Continuation)function2;
            }

            @Nullable
            public final Object invoke(@NotNull CoroutineScope p1, @Nullable Continuation<? super Unit> p2) {
                return (this.create(p1, p2)).invokeSuspend(Unit.INSTANCE);
            }
        }), (int)2, null);
    }

    @Nullable
    public static final <T> Object withReentrantLock(@NotNull Mutex $this$withReentrantLock, @NotNull Function1<? super Continuation<? super T>, ? extends Object> block, @NotNull Continuation<? super T> $completion) {
        boolean $i$f$withReentrantLock = false;
        ReentrantMutexContextKey key = new ReentrantMutexContextKey($this$withReentrantLock);
        if ($completion.getContext().get((CoroutineContext.Key)key) != null) {
            return block.invoke($completion);
        }
        return BuildersKt.withContext((CoroutineContext)((CoroutineContext)new ReentrantMutexContextElement(key)), (Function2)new Function2<CoroutineScope, Continuation<? super T>, Object>($this$withReentrantLock, block, null){
            Object L$0;
            Object L$1;
            int label;
            final /* synthetic */ Mutex $this_withReentrantLock;
            final /* synthetic */ Function1<Continuation<? super T>, Object> $block;
            {
                this.$this_withReentrantLock = $receiver;
                this.$block = $block;
                super(2, $completion);
            }

            /*
             * WARNING - Removed try catching itself - possible behaviour change.
             * Unable to fully structure code
             */
            @Nullable
            public final Object invokeSuspend(@NotNull Object var1_1) {
                var9_2 = IntrinsicsKt.getCOROUTINE_SUSPENDED();
                switch (this.label) {
                    case 0: {
                        ResultKt.throwOnFailure((Object)var1_1);
                        var2_3 = this.$this_withReentrantLock;
                        var4_4 = this.$block;
                        owner$iv = null;
                        $i$f$withLock = false;
                        this.L$0 = $this$withLock_u24default$iv;
                        this.L$1 = var4_4;
                        this.label = 1;
                        v0 = $this$withLock_u24default$iv.lock(owner$iv, (Continuation)this);
                        if (v0 == var9_2) {
                            return var9_2;
                        }
                        ** GOTO lbl25
                    }
                    case 1: {
                        $i$f$withLock = false;
                        var4_4 = (Function1<Continuation<? super T>, Object>)this.L$1;
                        owner$iv = null;
                        $this$withLock_u24default$iv = (Mutex)this.L$0;
                        ResultKt.throwOnFailure((Object)$result);
                        v0 = $result;
lbl25:
                        // 3 sources

                        $i$a$-withLock$default-CommonUtilsKt$withReentrantLock$2$1 = false;
                        this.L$0 = $this$withLock_u24default$iv;
                        this.L$1 = null;
                        this.label = 2;
                        v1 = var4_4.invoke((Object)this);
                        ** if (v1 != var9_2) goto lbl33
lbl32:
                        // 1 sources

                        return var9_2;
lbl33:
                        // 1 sources

                        ** GOTO lbl43
                    }
                    case 2: {
                        $i$f$withLock = false;
                        $i$a$-withLock$default-CommonUtilsKt$withReentrantLock$2$1 = false;
                        owner$iv = null;
                        $this$withLock_u24default$iv = (Mutex)this.L$0;
                        try {
                            ResultKt.throwOnFailure((Object)$result);
                            v1 = $result;
lbl43:
                            // 2 sources

                            var8_8 = v1;
                            return var8_8;
                        }
                        catch (Throwable var7_9) {
                            throw var7_9;
                        }
                        finally {
                            $this$withLock_u24default$iv.unlock(owner$iv);
                        }
                    }
                }
                throw new IllegalStateException("call to 'resume' before 'invoke' with coroutine");
            }

            /*
             * WARNING - Removed try catching itself - possible behaviour change.
             * WARNING - void declaration
             */
            @Nullable
            public final Object invokeSuspend$$forInline(@NotNull Object $result) {
                void $this$withLock_u24default$iv;
                Mutex mutex = this.$this_withReentrantLock;
                Function1<Continuation<? super T>, Object> function1 = this.$block;
                Object owner$iv = null;
                boolean $i$f$withLock = false;
                Continuation continuation = (Continuation)this;
                InlineMarker.mark((int)0);
                $this$withLock_u24default$iv.lock(owner$iv, continuation);
                InlineMarker.mark((int)1);
                try {
                    boolean bl = false;
                    InlineMarker.mark((int)3);
                    Object object = function1.invoke(null);
                    return object;
                }
                finally {
                    $this$withLock_u24default$iv.unlock(owner$iv);
                }
            }

            @NotNull
            public final Continuation<Unit> create(@Nullable Object value, @NotNull Continuation<?> $completion) {
                return (Continuation)new /* invalid duplicate definition of identical inner class */;
            }

            @Nullable
            public final Object invoke(@NotNull CoroutineScope p1, @Nullable Continuation<? super T> p2) {
                return (this.create(p1, p2)).invokeSuspend(Unit.INSTANCE);
            }
        }, $completion);
    }

    private static final <T> Object withReentrantLock$$forInline(Mutex $this$withReentrantLock, Function1<? super Continuation<? super T>, ? extends Object> block, Continuation<? super T> $completion) {
        boolean $i$f$withReentrantLock = false;
        ReentrantMutexContextKey key = new ReentrantMutexContextKey($this$withReentrantLock);
        InlineMarker.mark((int)3);
        if (null.getContext().get((CoroutineContext.Key)key) != null) {
            return block.invoke($completion);
        }
        CoroutineContext coroutineContext = (CoroutineContext)new ReentrantMutexContextElement(key);
        Function2 function2 = new /* invalid duplicate definition of identical inner class */;
        InlineMarker.mark((int)0);
        Object object = BuildersKt.withContext((CoroutineContext)coroutineContext, (Function2)function2, $completion);
        InlineMarker.mark((int)1);
        return object;
    }
}

