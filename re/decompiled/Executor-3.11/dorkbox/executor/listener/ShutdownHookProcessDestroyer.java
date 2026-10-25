/*
 * Decompiled with CFR 0.152.
 * 
 * Could not load the following classes:
 *  kotlin.Metadata
 *  kotlin.Unit
 *  kotlin.jvm.internal.DefaultConstructorMarker
 *  kotlin.jvm.internal.Intrinsics
 *  org.jetbrains.annotations.NotNull
 *  org.jetbrains.annotations.Nullable
 *  org.slf4j.Logger
 *  org.slf4j.LoggerFactory
 */
package dorkbox.executor.listener;

import dorkbox.executor.listener.ProcessDestroyer;
import java.util.ArrayList;
import java.util.List;
import kotlin.Metadata;
import kotlin.Unit;
import kotlin.jvm.internal.DefaultConstructorMarker;
import kotlin.jvm.internal.Intrinsics;
import org.jetbrains.annotations.NotNull;
import org.jetbrains.annotations.Nullable;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

@Metadata(mv={1, 6, 0}, k=1, xi=48, d1={"\u0000:\n\u0002\u0018\u0002\n\u0002\u0018\u0002\n\u0002\u0018\u0002\n\u0002\b\u0002\n\u0002\u0018\u0002\n\u0000\n\u0002\u0010\u000b\n\u0002\b\u0003\n\u0002\u0010!\n\u0002\u0018\u0002\n\u0002\b\u0005\n\u0002\u0010\u0002\n\u0002\b\u0005\n\u0002\u0010\b\n\u0002\b\u0003\u0018\u0000 \u00192\u00020\u00012\u00020\u0002:\u0002\u0019\u001aB\u0005\u00a2\u0006\u0002\u0010\u0003J\u0010\u0010\u000f\u001a\u00020\u00072\u0006\u0010\u0010\u001a\u00020\fH\u0016J\b\u0010\u0011\u001a\u00020\u0012H\u0002J\u0010\u0010\u0013\u001a\u00020\u00122\u0006\u0010\u0010\u001a\u00020\fH\u0002J\u0010\u0010\u0014\u001a\u00020\u00072\u0006\u0010\u0010\u001a\u00020\fH\u0016J\b\u0010\u0015\u001a\u00020\u0012H\u0002J\b\u0010\u0016\u001a\u00020\u0012H\u0016J\b\u0010\u0017\u001a\u00020\u0018H\u0016R\u0014\u0010\u0004\u001a\b\u0018\u00010\u0005R\u00020\u0000X\u0082\u000e\u00a2\u0006\u0002\n\u0000R\u001e\u0010\b\u001a\u00020\u00072\u0006\u0010\u0006\u001a\u00020\u0007@BX\u0086\u000e\u00a2\u0006\b\n\u0000\u001a\u0004\b\b\u0010\tR\u0014\u0010\n\u001a\b\u0012\u0004\u0012\u00020\f0\u000bX\u0082\u0004\u00a2\u0006\u0002\n\u0000R\u000e\u0010\r\u001a\u00020\u0007X\u0082\u000e\u00a2\u0006\u0002\n\u0000R\u000e\u0010\u000e\u001a\u00020\u0007X\u0082\u000e\u00a2\u0006\u0002\n\u0000\u00a8\u0006\u001b"}, d2={"Ldorkbox/executor/listener/ShutdownHookProcessDestroyer;", "Ldorkbox/executor/listener/ProcessDestroyer;", "Ljava/lang/Runnable;", "()V", "destroyProcessThread", "Ldorkbox/executor/listener/ShutdownHookProcessDestroyer$ProcessDestroyerImpl;", "<set-?>", "", "isAddedAsShutdownHook", "()Z", "processes", "", "Ljava/lang/Process;", "running", "shutDownHookExecuted", "add", "process", "addShutdownHook", "", "destroy", "remove", "removeShutdownHook", "run", "size", "", "Companion", "ProcessDestroyerImpl", "Executor"})
public final class ShutdownHookProcessDestroyer
implements ProcessDestroyer,
Runnable {
    @NotNull
    public static final Companion Companion = new Companion(null);
    @NotNull
    private final List<Process> processes = new ArrayList();
    @Nullable
    private ProcessDestroyerImpl destroyProcessThread;
    private boolean isAddedAsShutdownHook;
    private volatile boolean shutDownHookExecuted;
    private volatile boolean running;
    private static final Logger log = LoggerFactory.getLogger(ShutdownHookProcessDestroyer.class);
    @NotNull
    private static final ProcessDestroyer INSTANCE = new ShutdownHookProcessDestroyer();

    public final boolean isAddedAsShutdownHook() {
        return this.isAddedAsShutdownHook;
    }

    private final void addShutdownHook() {
        if (!this.running) {
            this.destroyProcessThread = new ProcessDestroyerImpl();
            Runtime.getRuntime().addShutdownHook(this.destroyProcessThread);
            this.isAddedAsShutdownHook = true;
        }
    }

    private final void removeShutdownHook() {
        if (this.isAddedAsShutdownHook && !this.running) {
            boolean removed = Runtime.getRuntime().removeShutdownHook(this.destroyProcessThread);
            if (!removed) {
                log.error("Could not remove shutdown hook");
            }
            ProcessDestroyerImpl processDestroyerImpl = this.destroyProcessThread;
            Intrinsics.checkNotNull((Object)processDestroyerImpl);
            processDestroyerImpl.setShouldDestroy(false);
            ProcessDestroyerImpl processDestroyerImpl2 = this.destroyProcessThread;
            Intrinsics.checkNotNull((Object)processDestroyerImpl2);
            processDestroyerImpl2.start();
            try {
                ProcessDestroyerImpl processDestroyerImpl3 = this.destroyProcessThread;
                Intrinsics.checkNotNull((Object)processDestroyerImpl3);
                processDestroyerImpl3.join(20000L);
            }
            catch (InterruptedException interruptedException) {
                // empty catch block
            }
            this.destroyProcessThread = null;
            this.isAddedAsShutdownHook = false;
        }
    }

    /*
     * WARNING - Removed try catching itself - possible behaviour change.
     */
    @Override
    public boolean add(@NotNull Process process) {
        Intrinsics.checkNotNullParameter((Object)process, (String)"process");
        List<Process> list = this.processes;
        synchronized (list) {
            boolean bl = false;
            if (this.processes.size() == 0) {
                try {
                    if (!(!this.shutDownHookExecuted)) {
                        String string2 = "Check failed.";
                        throw new IllegalStateException(string2.toString());
                    }
                    this.addShutdownHook();
                }
                catch (IllegalStateException e) {
                    this.destroy(process);
                }
            }
            this.processes.add(process);
            boolean bl2 = this.processes.contains(process);
            return bl2;
        }
    }

    /*
     * WARNING - Removed try catching itself - possible behaviour change.
     */
    @Override
    public boolean remove(@NotNull Process process) {
        Intrinsics.checkNotNullParameter((Object)process, (String)"process");
        List<Process> list = this.processes;
        synchronized (list) {
            boolean bl = false;
            boolean processRemoved = this.processes.remove(process);
            if (processRemoved && this.processes.size() == 0) {
                try {
                    this.removeShutdownHook();
                }
                catch (IllegalStateException e) {
                    this.shutDownHookExecuted = true;
                }
            }
            boolean bl2 = processRemoved;
            return bl2;
        }
    }

    @Override
    public int size() {
        return this.processes.size();
    }

    /*
     * WARNING - Removed try catching itself - possible behaviour change.
     */
    @Override
    public void run() {
        if (this.shutDownHookExecuted) {
            return;
        }
        List<Process> list = this.processes;
        synchronized (list) {
            boolean bl = false;
            this.running = true;
            Iterable $this$forEach$iv = this.processes;
            boolean $i$f$forEach = false;
            for (Object element$iv : $this$forEach$iv) {
                Process it = (Process)element$iv;
                boolean bl2 = false;
                this.destroy(it);
            }
            this.processes.clear();
            this.shutDownHookExecuted = true;
            Unit unit = Unit.INSTANCE;
        }
    }

    private final void destroy(Process process) {
        try {
            process.destroy();
        }
        catch (Throwable t) {
            log.error("Unable to terminate process during process shutdown");
        }
    }

    @Metadata(mv={1, 6, 0}, k=1, xi=48, d1={"\u0000\u001c\n\u0002\u0018\u0002\n\u0002\u0010\u0000\n\u0002\b\u0002\n\u0002\u0018\u0002\n\u0002\b\u0003\n\u0002\u0018\u0002\n\u0002\b\u0002\b\u0086\u0003\u0018\u00002\u00020\u0001B\u0007\b\u0002\u00a2\u0006\u0002\u0010\u0002R\u0011\u0010\u0003\u001a\u00020\u0004\u00a2\u0006\b\n\u0000\u001a\u0004\b\u0005\u0010\u0006R\u0016\u0010\u0007\u001a\n \t*\u0004\u0018\u00010\b0\bX\u0082\u0004\u00a2\u0006\u0002\n\u0000\u00a8\u0006\n"}, d2={"Ldorkbox/executor/listener/ShutdownHookProcessDestroyer$Companion;", "", "()V", "INSTANCE", "Ldorkbox/executor/listener/ProcessDestroyer;", "getINSTANCE", "()Ldorkbox/executor/listener/ProcessDestroyer;", "log", "Lorg/slf4j/Logger;", "kotlin.jvm.PlatformType", "Executor"})
    public static final class Companion {
        private Companion() {
        }

        @NotNull
        public final ProcessDestroyer getINSTANCE() {
            return INSTANCE;
        }

        public /* synthetic */ Companion(DefaultConstructorMarker $constructor_marker) {
            this();
        }
    }

    @Metadata(mv={1, 6, 0}, k=1, xi=48, d1={"\u0000\u001a\n\u0002\u0018\u0002\n\u0002\u0018\u0002\n\u0002\b\u0002\n\u0002\u0010\u000b\n\u0000\n\u0002\u0010\u0002\n\u0002\b\u0002\b\u0082\u0004\u0018\u00002\u00020\u0001B\u0005\u00a2\u0006\u0002\u0010\u0002J\b\u0010\u0005\u001a\u00020\u0006H\u0016J\u000e\u0010\u0007\u001a\u00020\u00062\u0006\u0010\u0003\u001a\u00020\u0004R\u000e\u0010\u0003\u001a\u00020\u0004X\u0082\u000e\u00a2\u0006\u0002\n\u0000\u00a8\u0006\b"}, d2={"Ldorkbox/executor/listener/ShutdownHookProcessDestroyer$ProcessDestroyerImpl;", "Ljava/lang/Thread;", "(Ldorkbox/executor/listener/ShutdownHookProcessDestroyer;)V", "shouldDestroy", "", "run", "", "setShouldDestroy", "Executor"})
    private final class ProcessDestroyerImpl
    extends Thread {
        private boolean shouldDestroy;

        public ProcessDestroyerImpl() {
            Intrinsics.checkNotNullParameter((Object)ShutdownHookProcessDestroyer.this, (String)"this$0");
            super("ProcessDestroyer Shutdown Hook");
            this.shouldDestroy = true;
        }

        @Override
        public void run() {
            if (this.shouldDestroy) {
                ShutdownHookProcessDestroyer.this.run();
            }
        }

        public final void setShouldDestroy(boolean shouldDestroy) {
            this.shouldDestroy = shouldDestroy;
        }
    }
}

