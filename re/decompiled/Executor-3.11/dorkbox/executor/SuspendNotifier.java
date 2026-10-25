/*
 * Decompiled with CFR 0.152.
 * 
 * Could not load the following classes:
 *  kotlin.Metadata
 *  kotlin.Unit
 *  kotlin.coroutines.Continuation
 *  kotlin.coroutines.intrinsics.IntrinsicsKt
 *  kotlin.jvm.JvmInline
 *  kotlin.jvm.internal.DefaultConstructorMarker
 *  kotlin.jvm.internal.Intrinsics
 *  kotlinx.coroutines.channels.Channel
 *  kotlinx.coroutines.channels.ChannelKt
 *  kotlinx.coroutines.channels.ReceiveChannel
 *  kotlinx.coroutines.channels.ReceiveChannel$DefaultImpls
 *  org.jetbrains.annotations.NotNull
 *  org.jetbrains.annotations.Nullable
 */
package dorkbox.executor;

import kotlin.Metadata;
import kotlin.Unit;
import kotlin.coroutines.Continuation;
import kotlin.coroutines.intrinsics.IntrinsicsKt;
import kotlin.jvm.JvmInline;
import kotlin.jvm.internal.DefaultConstructorMarker;
import kotlin.jvm.internal.Intrinsics;
import kotlinx.coroutines.channels.Channel;
import kotlinx.coroutines.channels.ChannelKt;
import kotlinx.coroutines.channels.ReceiveChannel;
import org.jetbrains.annotations.NotNull;
import org.jetbrains.annotations.Nullable;

/*
 * Illegal identifiers - consider using --renameillegalidents true
 */
@JvmInline
@Metadata(mv={1, 6, 0}, k=1, xi=48, d1={"\u0000.\n\u0002\u0018\u0002\n\u0002\u0010\u0000\n\u0000\n\u0002\u0018\u0002\n\u0002\u0010\u0002\n\u0002\b\u000b\n\u0002\u0010\u000b\n\u0002\b\u0004\n\u0002\u0010\b\n\u0002\b\u0003\n\u0002\u0010\u000e\n\u0002\b\u0003\b\u0087@\u0018\u00002\u00020\u0001B\u001a\u0012\u000e\b\u0002\u0010\u0002\u001a\b\u0012\u0004\u0012\u00020\u00040\u0003\u00f8\u0001\u0000\u00a2\u0006\u0004\b\u0005\u0010\u0006J\r\u0010\u0007\u001a\u00020\u0004\u00a2\u0006\u0004\b\b\u0010\tJ\u0013\u0010\n\u001a\u00020\u0004H\u0086@\u00f8\u0001\u0000\u00a2\u0006\u0004\b\u000b\u0010\fJ\u0013\u0010\r\u001a\u00020\u0004H\u0086@\u00f8\u0001\u0000\u00a2\u0006\u0004\b\u000e\u0010\fJ\u001a\u0010\u000f\u001a\u00020\u00102\b\u0010\u0011\u001a\u0004\u0018\u00010\u0001H\u00d6\u0003\u00a2\u0006\u0004\b\u0012\u0010\u0013J\u0010\u0010\u0014\u001a\u00020\u0015H\u00d6\u0001\u00a2\u0006\u0004\b\u0016\u0010\u0017J\u0010\u0010\u0018\u001a\u00020\u0019H\u00d6\u0001\u00a2\u0006\u0004\b\u001a\u0010\u001bR\u0014\u0010\u0002\u001a\b\u0012\u0004\u0012\u00020\u00040\u0003X\u0082\u0004\u00a2\u0006\u0002\n\u0000\u0088\u0001\u0002\u0092\u0001\b\u0012\u0004\u0012\u00020\u00040\u0003\u00f8\u0001\u0000\u0082\u0002\u0004\n\u0002\b\u0019\u00a8\u0006\u001c"}, d2={"Ldorkbox/executor/SuspendNotifier;", "", "channel", "Lkotlinx/coroutines/channels/Channel;", "", "constructor-impl", "(Lkotlinx/coroutines/channels/Channel;)Lkotlinx/coroutines/channels/Channel;", "cancel", "cancel-impl", "(Lkotlinx/coroutines/channels/Channel;)V", "doNotify", "doNotify-impl", "(Lkotlinx/coroutines/channels/Channel;Lkotlin/coroutines/Continuation;)Ljava/lang/Object;", "doWait", "doWait-impl", "equals", "", "other", "equals-impl", "(Lkotlinx/coroutines/channels/Channel;Ljava/lang/Object;)Z", "hashCode", "", "hashCode-impl", "(Lkotlinx/coroutines/channels/Channel;)I", "toString", "", "toString-impl", "(Lkotlinx/coroutines/channels/Channel;)Ljava/lang/String;", "Executor"})
public final class SuspendNotifier {
    @NotNull
    private final Channel<Unit> channel;

    @Nullable
    public static final Object doWait-impl(Channel<Unit> arg0, @NotNull Continuation<? super Unit> $completion) {
        Object object = arg0.receive($completion);
        if (object == IntrinsicsKt.getCOROUTINE_SUSPENDED()) {
            return object;
        }
        return Unit.INSTANCE;
    }

    @Nullable
    public static final Object doNotify-impl(Channel<Unit> arg0, @NotNull Continuation<? super Unit> $completion) {
        Object object = arg0.send((Object)Unit.INSTANCE, $completion);
        if (object == IntrinsicsKt.getCOROUTINE_SUSPENDED()) {
            return object;
        }
        return Unit.INSTANCE;
    }

    public static final void cancel-impl(Channel<Unit> arg0) {
        Intrinsics.checkNotNullParameter(arg0, (String)"arg0");
        ReceiveChannel.DefaultImpls.cancel$default((ReceiveChannel)((ReceiveChannel)arg0), null, (int)1, null);
    }

    public static String toString-impl(Channel<Unit> arg0) {
        return "SuspendNotifier(channel=" + arg0 + ')';
    }

    public String toString() {
        return SuspendNotifier.toString-impl(this.channel);
    }

    public static int hashCode-impl(Channel<Unit> arg0) {
        return arg0.hashCode();
    }

    public int hashCode() {
        return SuspendNotifier.hashCode-impl(this.channel);
    }

    public static boolean equals-impl(Channel<Unit> arg0, Object other) {
        if (!(other instanceof SuspendNotifier)) {
            return false;
        }
        return Intrinsics.areEqual(arg0, (Object)((SuspendNotifier)other).unbox-impl());
    }

    public boolean equals(Object other) {
        return SuspendNotifier.equals-impl(this.channel, other);
    }

    private /* synthetic */ SuspendNotifier(Channel channel) {
        this.channel = channel;
    }

    @NotNull
    public static Channel<Unit> constructor-impl(@NotNull Channel<Unit> channel) {
        Intrinsics.checkNotNullParameter(channel, (String)"channel");
        return channel;
    }

    public static /* synthetic */ Channel constructor-impl$default(Channel channel, int n, DefaultConstructorMarker defaultConstructorMarker) {
        if ((n & 1) != 0) {
            channel = ChannelKt.Channel$default((int)2, null, null, (int)6, null);
        }
        return SuspendNotifier.constructor-impl((Channel<Unit>)channel);
    }

    public static final /* synthetic */ SuspendNotifier box-impl(Channel v) {
        return new SuspendNotifier(v);
    }

    public final /* synthetic */ Channel unbox-impl() {
        return this.channel;
    }

    public static final boolean equals-impl0(Channel<Unit> p1, Channel<Unit> p2) {
        return Intrinsics.areEqual(p1, p2);
    }
}

