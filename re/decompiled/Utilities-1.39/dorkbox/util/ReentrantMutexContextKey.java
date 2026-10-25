/*
 * Decompiled with CFR 0.152.
 * 
 * Could not load the following classes:
 *  kotlin.Metadata
 *  kotlin.coroutines.CoroutineContext$Key
 *  kotlin.jvm.internal.Intrinsics
 *  kotlinx.coroutines.sync.Mutex
 *  org.jetbrains.annotations.NotNull
 *  org.jetbrains.annotations.Nullable
 */
package dorkbox.util;

import dorkbox.util.ReentrantMutexContextElement;
import kotlin.Metadata;
import kotlin.coroutines.CoroutineContext;
import kotlin.jvm.internal.Intrinsics;
import kotlinx.coroutines.sync.Mutex;
import org.jetbrains.annotations.NotNull;
import org.jetbrains.annotations.Nullable;

@Metadata(mv={1, 7, 1}, k=1, xi=48, d1={"\u0000.\n\u0002\u0018\u0002\n\u0002\u0018\u0002\n\u0002\u0018\u0002\n\u0000\n\u0002\u0018\u0002\n\u0002\b\u0006\n\u0002\u0010\u000b\n\u0000\n\u0002\u0010\u0000\n\u0000\n\u0002\u0010\b\n\u0000\n\u0002\u0010\u000e\n\u0000\b\u0086\b\u0018\u00002\b\u0012\u0004\u0012\u00020\u00020\u0001B\r\u0012\u0006\u0010\u0003\u001a\u00020\u0004\u00a2\u0006\u0002\u0010\u0005J\t\u0010\b\u001a\u00020\u0004H\u00c6\u0003J\u0013\u0010\t\u001a\u00020\u00002\b\b\u0002\u0010\u0003\u001a\u00020\u0004H\u00c6\u0001J\u0013\u0010\n\u001a\u00020\u000b2\b\u0010\f\u001a\u0004\u0018\u00010\rH\u00d6\u0003J\t\u0010\u000e\u001a\u00020\u000fH\u00d6\u0001J\t\u0010\u0010\u001a\u00020\u0011H\u00d6\u0001R\u0011\u0010\u0003\u001a\u00020\u0004\u00a2\u0006\b\n\u0000\u001a\u0004\b\u0006\u0010\u0007\u00a8\u0006\u0012"}, d2={"Ldorkbox/util/ReentrantMutexContextKey;", "Lkotlin/coroutines/CoroutineContext$Key;", "Ldorkbox/util/ReentrantMutexContextElement;", "mutex", "Lkotlinx/coroutines/sync/Mutex;", "(Lkotlinx/coroutines/sync/Mutex;)V", "getMutex", "()Lkotlinx/coroutines/sync/Mutex;", "component1", "copy", "equals", "", "other", "", "hashCode", "", "toString", "", "Utilities"})
public final class ReentrantMutexContextKey
implements CoroutineContext.Key<ReentrantMutexContextElement> {
    @NotNull
    private final Mutex mutex;

    public ReentrantMutexContextKey(@NotNull Mutex mutex) {
        Intrinsics.checkNotNullParameter((Object)mutex, (String)"mutex");
        this.mutex = mutex;
    }

    @NotNull
    public final Mutex getMutex() {
        return this.mutex;
    }

    @NotNull
    public final Mutex component1() {
        return this.mutex;
    }

    @NotNull
    public final ReentrantMutexContextKey copy(@NotNull Mutex mutex) {
        Intrinsics.checkNotNullParameter((Object)mutex, (String)"mutex");
        return new ReentrantMutexContextKey(mutex);
    }

    public static /* synthetic */ ReentrantMutexContextKey copy$default(ReentrantMutexContextKey reentrantMutexContextKey, Mutex mutex, int n, Object object) {
        if ((n & 1) != 0) {
            mutex = reentrantMutexContextKey.mutex;
        }
        return reentrantMutexContextKey.copy(mutex);
    }

    @NotNull
    public String toString() {
        return "ReentrantMutexContextKey(mutex=" + this.mutex + ')';
    }

    public int hashCode() {
        return this.mutex.hashCode();
    }

    public boolean equals(@Nullable Object other) {
        if (this == other) {
            return true;
        }
        if (!(other instanceof ReentrantMutexContextKey)) {
            return false;
        }
        ReentrantMutexContextKey reentrantMutexContextKey = (ReentrantMutexContextKey)other;
        return Intrinsics.areEqual((Object)this.mutex, (Object)reentrantMutexContextKey.mutex);
    }
}

