/*
 * Decompiled with CFR 0.152.
 * 
 * Could not load the following classes:
 *  kotlin.Metadata
 *  kotlin.jvm.internal.Intrinsics
 *  org.jetbrains.annotations.NotNull
 */
package dorkbox.executor.listener;

import dorkbox.executor.Executor;
import dorkbox.executor.listener.ProcessListener;
import dorkbox.executor.processResults.ProcessResult;
import java.util.Collection;
import java.util.Iterator;
import java.util.List;
import java.util.concurrent.CopyOnWriteArrayList;
import kotlin.Metadata;
import kotlin.jvm.internal.Intrinsics;
import org.jetbrains.annotations.NotNull;

@Metadata(mv={1, 6, 0}, k=1, xi=48, d1={"\u0000@\n\u0002\u0018\u0002\n\u0002\u0018\u0002\n\u0002\u0010\u001a\n\u0002\b\u0002\n\u0002\u0010 \n\u0000\n\u0002\u0010!\n\u0000\n\u0002\u0010\u0002\n\u0002\b\u0003\n\u0002\u0018\u0002\n\u0000\n\u0002\u0018\u0002\n\u0002\b\u0002\n\u0002\u0018\u0002\n\u0002\b\u0007\n\u0002\u0018\u0002\n\u0000\u0018\u00002\u00020\u00012\u00020\u0002B\u0007\b\u0016\u00a2\u0006\u0002\u0010\u0003B\u0015\b\u0016\u0012\f\u0010\u0004\u001a\b\u0012\u0004\u0012\u00020\u00010\u0005\u00a2\u0006\u0002\u0010\u0006J\u000e\u0010\b\u001a\u00020\t2\u0006\u0010\n\u001a\u00020\u0001J\u0018\u0010\u000b\u001a\u00020\t2\u0006\u0010\f\u001a\u00020\r2\u0006\u0010\u000e\u001a\u00020\u000fH\u0016J\u0018\u0010\u0010\u001a\u00020\t2\u0006\u0010\f\u001a\u00020\r2\u0006\u0010\u0011\u001a\u00020\u0012H\u0016J\u0010\u0010\u0013\u001a\u00020\t2\u0006\u0010\f\u001a\u00020\rH\u0016J\u0010\u0010\u0014\u001a\u00020\t2\u0006\u0010\u0011\u001a\u00020\u0012H\u0016J\u0006\u0010\u0015\u001a\u00020\tJ\b\u0010\u0016\u001a\u00020\u0000H\u0016J\u000e\u0010\u0017\u001a\u00020\t2\u0006\u0010\n\u001a\u00020\u0001J\u0016\u0010\u0018\u001a\u00020\t2\u000e\u0010\u0019\u001a\n\u0012\u0006\b\u0001\u0012\u00020\u00010\u001aR\u0014\u0010\u0004\u001a\b\u0012\u0004\u0012\u00020\u00010\u0007X\u0082\u0004\u00a2\u0006\u0002\n\u0000\u00a8\u0006\u001b"}, d2={"Ldorkbox/executor/listener/CompositeProcessListener;", "Ldorkbox/executor/listener/ProcessListener;", "", "()V", "children", "", "(Ljava/util/List;)V", "", "add", "", "listener", "afterFinish", "process", "Ljava/lang/Process;", "result", "Ldorkbox/executor/processResults/ProcessResult;", "afterStart", "executor", "Ldorkbox/executor/Executor;", "afterStop", "beforeStart", "clear", "clone", "remove", "removeAll", "type", "Ljava/lang/Class;", "Executor"})
public final class CompositeProcessListener
extends ProcessListener
implements Cloneable {
    @NotNull
    private final List<ProcessListener> children;

    public CompositeProcessListener() {
        this.children = new CopyOnWriteArrayList();
    }

    public CompositeProcessListener(@NotNull List<? extends ProcessListener> children) {
        Intrinsics.checkNotNullParameter(children, (String)"children");
        this.children = new CopyOnWriteArrayList();
        this.children.addAll((Collection<ProcessListener>)children);
    }

    public final void add(@NotNull ProcessListener listener) {
        Intrinsics.checkNotNullParameter((Object)listener, (String)"listener");
        this.children.add(listener);
    }

    public final void remove(@NotNull ProcessListener listener) {
        Intrinsics.checkNotNullParameter((Object)listener, (String)"listener");
        this.children.remove(listener);
    }

    public final void removeAll(@NotNull Class<? extends ProcessListener> type) {
        Intrinsics.checkNotNullParameter(type, (String)"type");
        Iterator<ProcessListener> it = this.children.iterator();
        while (it.hasNext()) {
            if (!type.isInstance(it.next())) continue;
            it.remove();
        }
    }

    public final void clear() {
        this.children.clear();
    }

    @NotNull
    public CompositeProcessListener clone() {
        return new CompositeProcessListener(this.children);
    }

    @Override
    public void beforeStart(@NotNull Executor executor) {
        Intrinsics.checkNotNullParameter((Object)executor, (String)"executor");
        Iterable $this$forEach$iv = this.children;
        boolean $i$f$forEach = false;
        for (Object element$iv : $this$forEach$iv) {
            ProcessListener it = (ProcessListener)element$iv;
            boolean bl = false;
            it.beforeStart(executor);
        }
    }

    @Override
    public void afterStart(@NotNull Process process, @NotNull Executor executor) {
        Intrinsics.checkNotNullParameter((Object)process, (String)"process");
        Intrinsics.checkNotNullParameter((Object)executor, (String)"executor");
        Iterable $this$forEach$iv = this.children;
        boolean $i$f$forEach = false;
        for (Object element$iv : $this$forEach$iv) {
            ProcessListener it = (ProcessListener)element$iv;
            boolean bl = false;
            it.afterStart(process, executor);
        }
    }

    @Override
    public void afterFinish(@NotNull Process process, @NotNull ProcessResult result) {
        Intrinsics.checkNotNullParameter((Object)process, (String)"process");
        Intrinsics.checkNotNullParameter((Object)result, (String)"result");
        Iterable $this$forEach$iv = this.children;
        boolean $i$f$forEach = false;
        for (Object element$iv : $this$forEach$iv) {
            ProcessListener it = (ProcessListener)element$iv;
            boolean bl = false;
            it.afterFinish(process, result);
        }
    }

    @Override
    public void afterStop(@NotNull Process process) {
        Intrinsics.checkNotNullParameter((Object)process, (String)"process");
        Iterable $this$forEach$iv = this.children;
        boolean $i$f$forEach = false;
        for (Object element$iv : $this$forEach$iv) {
            ProcessListener it = (ProcessListener)element$iv;
            boolean bl = false;
            it.afterStop(process);
        }
    }
}

