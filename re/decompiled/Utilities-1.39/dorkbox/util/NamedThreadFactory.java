/*
 * Decompiled with CFR 0.152.
 * 
 * Could not load the following classes:
 *  kotlin.Metadata
 *  kotlin.jvm.internal.DefaultConstructorMarker
 *  kotlin.jvm.internal.Intrinsics
 *  org.jetbrains.annotations.NotNull
 */
package dorkbox.util;

import java.util.Arrays;
import java.util.concurrent.ThreadFactory;
import java.util.concurrent.atomic.AtomicInteger;
import kotlin.Metadata;
import kotlin.jvm.internal.DefaultConstructorMarker;
import kotlin.jvm.internal.Intrinsics;
import org.jetbrains.annotations.NotNull;

@Metadata(mv={1, 7, 1}, k=1, xi=48, d1={"\u0000<\n\u0002\u0018\u0002\n\u0002\u0018\u0002\n\u0000\n\u0002\u0010\u000e\n\u0000\n\u0002\u0018\u0002\n\u0002\b\u0002\n\u0002\u0010\u000b\n\u0002\b\u0004\n\u0002\u0010\b\n\u0002\b\t\n\u0002\u0018\u0002\n\u0002\b\u0003\n\u0002\u0018\u0002\n\u0000\n\u0002\u0018\u0002\n\u0000\u0018\u00002\u00020\u0001B\u0017\b\u0016\u0012\u0006\u0010\u0002\u001a\u00020\u0003\u0012\u0006\u0010\u0004\u001a\u00020\u0005\u00a2\u0006\u0002\u0010\u0006B\u0017\b\u0016\u0012\u0006\u0010\u0002\u001a\u00020\u0003\u0012\u0006\u0010\u0007\u001a\u00020\b\u00a2\u0006\u0002\u0010\tB\u001f\b\u0016\u0012\u0006\u0010\u0002\u001a\u00020\u0003\u0012\u0006\u0010\u0004\u001a\u00020\u0005\u0012\u0006\u0010\u0007\u001a\u00020\b\u00a2\u0006\u0002\u0010\nB+\u0012\u0006\u0010\u000b\u001a\u00020\u0003\u0012\b\b\u0002\u0010\u0004\u001a\u00020\u0005\u0012\b\b\u0002\u0010\f\u001a\u00020\r\u0012\b\b\u0002\u0010\u000e\u001a\u00020\b\u00a2\u0006\u0002\u0010\u000fJ\u0010\u0010\u001a\u001a\u00020\u001b2\u0006\u0010\u001c\u001a\u00020\u001dH\u0016R\u0011\u0010\u000e\u001a\u00020\b\u00a2\u0006\b\n\u0000\u001a\u0004\b\u0010\u0010\u0011R\u0011\u0010\u0004\u001a\u00020\u0005\u00a2\u0006\b\n\u0000\u001a\u0004\b\u0012\u0010\u0013R\u0011\u0010\u000b\u001a\u00020\u0003\u00a2\u0006\b\n\u0000\u001a\u0004\b\u0014\u0010\u0015R\u000e\u0010\u0016\u001a\u00020\u0017X\u0082\u0004\u00a2\u0006\u0002\n\u0000R\u0011\u0010\f\u001a\u00020\r\u00a2\u0006\b\n\u0000\u001a\u0004\b\u0018\u0010\u0019\u00a8\u0006\u001e"}, d2={"Ldorkbox/util/NamedThreadFactory;", "Ljava/util/concurrent/ThreadFactory;", "poolNamePrefix", "", "group", "Ljava/lang/ThreadGroup;", "(Ljava/lang/String;Ljava/lang/ThreadGroup;)V", "isDaemon", "", "(Ljava/lang/String;Z)V", "(Ljava/lang/String;Ljava/lang/ThreadGroup;Z)V", "namePrefix", "threadPriority", "", "daemon", "(Ljava/lang/String;Ljava/lang/ThreadGroup;IZ)V", "getDaemon", "()Z", "getGroup", "()Ljava/lang/ThreadGroup;", "getNamePrefix", "()Ljava/lang/String;", "poolId", "Ljava/util/concurrent/atomic/AtomicInteger;", "getThreadPriority", "()I", "newThread", "Ljava/lang/Thread;", "r", "Ljava/lang/Runnable;", "Utilities"})
public final class NamedThreadFactory
implements ThreadFactory {
    @NotNull
    private final String namePrefix;
    @NotNull
    private final ThreadGroup group;
    private final int threadPriority;
    private final boolean daemon;
    @NotNull
    private final AtomicInteger poolId;

    public NamedThreadFactory(@NotNull String namePrefix, @NotNull ThreadGroup group, int threadPriority, boolean daemon) {
        Intrinsics.checkNotNullParameter((Object)namePrefix, (String)"namePrefix");
        Intrinsics.checkNotNullParameter((Object)group, (String)"group");
        this.namePrefix = namePrefix;
        this.group = group;
        this.threadPriority = threadPriority;
        this.daemon = daemon;
        this.poolId = new AtomicInteger();
        if (!(this.threadPriority >= 1)) {
            boolean $i$a$-require-NamedThreadFactory$32 = false;
            String string = "Thread priority (%s) must be >= %s";
            Object[] objectArray = new Object[]{this.threadPriority, 1};
            String string2 = String.format(string, Arrays.copyOf(objectArray, objectArray.length));
            Intrinsics.checkNotNullExpressionValue((Object)string2, (String)"format(format, *args)");
            String $i$a$-require-NamedThreadFactory$32 = string2;
            throw new IllegalArgumentException($i$a$-require-NamedThreadFactory$32.toString());
        }
        if (!(this.threadPriority <= 10)) {
            boolean bl = false;
            String string = "Thread priority (%s) must be <= %s";
            Object[] objectArray = new Object[]{this.threadPriority, 10};
            String string3 = String.format(string, Arrays.copyOf(objectArray, objectArray.length));
            Intrinsics.checkNotNullExpressionValue((Object)string3, (String)"format(format, *args)");
            String string4 = string3;
            throw new IllegalArgumentException(string4.toString());
        }
    }

    public /* synthetic */ NamedThreadFactory(String string, ThreadGroup threadGroup, int n, boolean bl, int n2, DefaultConstructorMarker defaultConstructorMarker) {
        if ((n2 & 2) != 0) {
            ThreadGroup threadGroup2 = Thread.currentThread().getThreadGroup();
            Intrinsics.checkNotNullExpressionValue((Object)threadGroup2, (String)"currentThread().threadGroup");
            threadGroup = threadGroup2;
        }
        if ((n2 & 4) != 0) {
            n = 5;
        }
        if ((n2 & 8) != 0) {
            bl = true;
        }
        this(string, threadGroup, n, bl);
    }

    @NotNull
    public final String getNamePrefix() {
        return this.namePrefix;
    }

    @NotNull
    public final ThreadGroup getGroup() {
        return this.group;
    }

    public final int getThreadPriority() {
        return this.threadPriority;
    }

    public final boolean getDaemon() {
        return this.daemon;
    }

    public NamedThreadFactory(@NotNull String poolNamePrefix, @NotNull ThreadGroup group) {
        Intrinsics.checkNotNullParameter((Object)poolNamePrefix, (String)"poolNamePrefix");
        Intrinsics.checkNotNullParameter((Object)group, (String)"group");
        this(poolNamePrefix, group, 5, true);
    }

    public NamedThreadFactory(@NotNull String poolNamePrefix, boolean isDaemon) {
        Intrinsics.checkNotNullParameter((Object)poolNamePrefix, (String)"poolNamePrefix");
        ThreadGroup threadGroup = Thread.currentThread().getThreadGroup();
        Intrinsics.checkNotNullExpressionValue((Object)threadGroup, (String)"currentThread().threadGroup");
        this(poolNamePrefix, threadGroup, isDaemon);
    }

    public NamedThreadFactory(@NotNull String poolNamePrefix, @NotNull ThreadGroup group, boolean isDaemon) {
        Intrinsics.checkNotNullParameter((Object)poolNamePrefix, (String)"poolNamePrefix");
        Intrinsics.checkNotNullParameter((Object)group, (String)"group");
        this(poolNamePrefix, group, 5, isDaemon);
    }

    @Override
    @NotNull
    public Thread newThread(@NotNull Runnable r) {
        Intrinsics.checkNotNullParameter((Object)r, (String)"r");
        Thread t = new Thread(this.group, r, this.namePrefix + '-' + this.poolId.incrementAndGet());
        t.setDaemon(this.daemon);
        t.setPriority(this.threadPriority);
        return t;
    }
}

