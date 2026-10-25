/*
 * Decompiled with CFR 0.152.
 * 
 * Could not load the following classes:
 *  kotlin.Metadata
 *  kotlin.coroutines.CoroutineContext
 *  kotlin.coroutines.CoroutineContext$Element
 *  kotlin.coroutines.CoroutineContext$Element$DefaultImpls
 *  kotlin.coroutines.CoroutineContext$Key
 *  kotlin.jvm.functions.Function2
 *  kotlin.jvm.internal.Intrinsics
 *  org.jetbrains.annotations.NotNull
 *  org.jetbrains.annotations.Nullable
 */
package dorkbox.util;

import dorkbox.util.ReentrantMutexContextKey;
import kotlin.Metadata;
import kotlin.coroutines.CoroutineContext;
import kotlin.jvm.functions.Function2;
import kotlin.jvm.internal.Intrinsics;
import org.jetbrains.annotations.NotNull;
import org.jetbrains.annotations.Nullable;

@Metadata(mv={1, 7, 1}, k=1, xi=48, d1={"\u0000\u0012\n\u0002\u0018\u0002\n\u0002\u0018\u0002\n\u0000\n\u0002\u0018\u0002\n\u0002\b\u0004\u0018\u00002\u00020\u0001B\r\u0012\u0006\u0010\u0002\u001a\u00020\u0003\u00a2\u0006\u0002\u0010\u0004R\u0014\u0010\u0002\u001a\u00020\u0003X\u0096\u0004\u00a2\u0006\b\n\u0000\u001a\u0004\b\u0005\u0010\u0006\u00a8\u0006\u0007"}, d2={"Ldorkbox/util/ReentrantMutexContextElement;", "Lkotlin/coroutines/CoroutineContext$Element;", "key", "Ldorkbox/util/ReentrantMutexContextKey;", "(Ldorkbox/util/ReentrantMutexContextKey;)V", "getKey", "()Ldorkbox/util/ReentrantMutexContextKey;", "Utilities"})
public final class ReentrantMutexContextElement
implements CoroutineContext.Element {
    @NotNull
    private final ReentrantMutexContextKey key;

    public ReentrantMutexContextElement(@NotNull ReentrantMutexContextKey key) {
        Intrinsics.checkNotNullParameter((Object)key, (String)"key");
        this.key = key;
    }

    @NotNull
    public ReentrantMutexContextKey getKey() {
        return this.key;
    }

    public <R> R fold(R initial, @NotNull Function2<? super R, ? super CoroutineContext.Element, ? extends R> operation) {
        return (R)CoroutineContext.Element.DefaultImpls.fold((CoroutineContext.Element)this, initial, operation);
    }

    @Nullable
    public <E extends CoroutineContext.Element> E get(@NotNull CoroutineContext.Key<E> key) {
        return (E)CoroutineContext.Element.DefaultImpls.get((CoroutineContext.Element)this, key);
    }

    @NotNull
    public CoroutineContext minusKey(@NotNull CoroutineContext.Key<?> key) {
        return CoroutineContext.Element.DefaultImpls.minusKey((CoroutineContext.Element)this, key);
    }

    @NotNull
    public CoroutineContext plus(@NotNull CoroutineContext context) {
        return CoroutineContext.Element.DefaultImpls.plus((CoroutineContext.Element)this, (CoroutineContext)context);
    }
}

