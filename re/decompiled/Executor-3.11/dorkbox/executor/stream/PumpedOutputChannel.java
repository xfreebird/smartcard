/*
 * Decompiled with CFR 0.152.
 * 
 * Could not load the following classes:
 *  kotlin.Metadata
 *  kotlin.ResultKt
 *  kotlin.Unit
 *  kotlin.collections.IntIterator
 *  kotlin.coroutines.Continuation
 *  kotlin.coroutines.intrinsics.IntrinsicsKt
 *  kotlin.coroutines.jvm.internal.Boxing
 *  kotlin.coroutines.jvm.internal.ContinuationImpl
 *  kotlin.jvm.internal.Intrinsics
 *  kotlin.ranges.RangesKt
 *  kotlinx.coroutines.channels.Channel
 *  kotlinx.coroutines.channels.SendChannel
 *  kotlinx.coroutines.channels.SendChannel$DefaultImpls
 *  org.jetbrains.annotations.NotNull
 *  org.jetbrains.annotations.Nullable
 */
package dorkbox.executor.stream;

import dorkbox.executor.stream.IOStream;
import dorkbox.executor.stream.PumpedOutputChannel;
import java.io.InputStream;
import java.util.Iterator;
import kotlin.Metadata;
import kotlin.ResultKt;
import kotlin.Unit;
import kotlin.collections.IntIterator;
import kotlin.coroutines.Continuation;
import kotlin.coroutines.intrinsics.IntrinsicsKt;
import kotlin.coroutines.jvm.internal.Boxing;
import kotlin.coroutines.jvm.internal.ContinuationImpl;
import kotlin.jvm.internal.Intrinsics;
import kotlin.ranges.RangesKt;
import kotlinx.coroutines.channels.Channel;
import kotlinx.coroutines.channels.SendChannel;
import org.jetbrains.annotations.NotNull;
import org.jetbrains.annotations.Nullable;

@Metadata(mv={1, 6, 0}, k=1, xi=48, d1={"\u0000,\n\u0002\u0018\u0002\n\u0002\u0018\u0002\n\u0000\n\u0002\u0018\u0002\n\u0002\u0010\u0005\n\u0002\b\u0002\n\u0002\u0010\u0002\n\u0002\b\u0002\n\u0002\u0010\b\n\u0000\n\u0002\u0018\u0002\n\u0002\b\u0002\u0018\u00002\u00020\u0001B\u0013\u0012\f\u0010\u0002\u001a\b\u0012\u0004\u0012\u00020\u00040\u0003\u00a2\u0006\u0002\u0010\u0005J\b\u0010\u0006\u001a\u00020\u0007H\u0016J!\u0010\b\u001a\u00020\u00072\u0006\u0010\t\u001a\u00020\n2\u0006\u0010\u000b\u001a\u00020\fH\u0096@\u00f8\u0001\u0000\u00a2\u0006\u0002\u0010\rR\u0014\u0010\u0002\u001a\b\u0012\u0004\u0012\u00020\u00040\u0003X\u0082\u0004\u00a2\u0006\u0002\n\u0000\u0082\u0002\u0004\n\u0002\b\u0019\u00a8\u0006\u000e"}, d2={"Ldorkbox/executor/stream/PumpedOutputChannel;", "Ldorkbox/executor/stream/IOStream;", "channel", "Lkotlinx/coroutines/channels/Channel;", "", "(Lkotlinx/coroutines/channels/Channel;)V", "close", "", "pump", "length", "", "inputStream", "Ljava/io/InputStream;", "(ILjava/io/InputStream;Lkotlin/coroutines/Continuation;)Ljava/lang/Object;", "Executor"})
public final class PumpedOutputChannel
implements IOStream {
    @NotNull
    private final Channel<Byte> channel;

    public PumpedOutputChannel(@NotNull Channel<Byte> channel) {
        Intrinsics.checkNotNullParameter(channel, (String)"channel");
        this.channel = channel;
    }

    /*
     * Unable to fully structure code
     */
    @Override
    @Nullable
    public Object pump(int var1_1, @NotNull InputStream var2_2, @NotNull Continuation<? super Unit> var3_3) {
        if (!(var3_3 instanceof pump.1)) ** GOTO lbl-1000
        var10_4 = var3_3;
        if ((var10_4.label & -2147483648) != 0) {
            var10_4.label -= -2147483648;
        } else lbl-1000:
        // 2 sources

        {
            $continuation = new ContinuationImpl(this, var3_3){
                Object L$0;
                Object L$1;
                Object L$2;
                /* synthetic */ Object result;
                final /* synthetic */ PumpedOutputChannel this$0;
                int label;
                {
                    this.this$0 = this$0;
                    super($completion);
                }

                @Nullable
                public final Object invokeSuspend(@NotNull Object $result) {
                    this.result = $result;
                    this.label |= Integer.MIN_VALUE;
                    return this.this$0.pump(0, null, (Continuation<? super Unit>)((Continuation)this));
                }
            };
        }
        $result = $continuation.result;
        var11_6 = IntrinsicsKt.getCOROUTINE_SUSPENDED();
        switch ($continuation.label) {
            case 0: {
                ResultKt.throwOnFailure((Object)$result);
                $this$forEach$iv = (Iterable)RangesKt.until((int)0, (int)RangesKt.coerceAtMost((int)length, (int)1024));
                $i$f$forEach = false;
                var6_9 = $this$forEach$iv.iterator();
lbl15:
                // 3 sources

                while (var6_9.hasNext()) {
                    var7_10 = ((IntIterator)var6_9).nextInt();
                    $i$a$-forEach-PumpedOutputChannel$pump$2 = false;
                    $continuation.L$0 = this;
                    $continuation.L$1 = inputStream;
                    $continuation.L$2 = var6_9;
                    $continuation.label = 1;
                    v0 = this.channel.send((Object)Boxing.boxByte((byte)((byte)inputStream.read())), (Continuation)$continuation);
                    if (v0 != var11_6) continue;
                    return var11_6;
                }
                break;
            }
            case 1: {
                $i$f$forEach = false;
                $i$a$-forEach-PumpedOutputChannel$pump$2 = false;
                var6_9 = (Iterator<T>)$continuation.L$2;
                inputStream = (InputStream)$continuation.L$1;
                this = (PumpedOutputChannel)$continuation.L$0;
                ResultKt.throwOnFailure((Object)$result);
                v0 = $result;
                ** GOTO lbl15
            }
        }
        return Unit.INSTANCE;
        throw new IllegalStateException("call to 'resume' before 'invoke' with coroutine");
    }

    @Override
    public void close() {
        SendChannel.DefaultImpls.close$default((SendChannel)((SendChannel)this.channel), null, (int)1, null);
    }
}

