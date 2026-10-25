/*
 * Decompiled with CFR 0.152.
 * 
 * Could not load the following classes:
 *  kotlin.Metadata
 *  kotlin.jvm.internal.DefaultConstructorMarker
 *  kotlin.jvm.internal.Intrinsics
 *  org.jetbrains.annotations.NotNull
 */
package dorkbox.executor.stop;

import dorkbox.executor.stop.ProcessStopper;
import kotlin.Metadata;
import kotlin.jvm.internal.DefaultConstructorMarker;
import kotlin.jvm.internal.Intrinsics;
import org.jetbrains.annotations.NotNull;

@Metadata(mv={1, 6, 0}, k=1, xi=48, d1={"\u0000\u001a\n\u0002\u0018\u0002\n\u0002\u0018\u0002\n\u0002\b\u0002\n\u0002\u0010\u0002\n\u0000\n\u0002\u0018\u0002\n\u0002\b\u0002\u0018\u0000 \u00072\u00020\u0001:\u0001\u0007B\u0005\u00a2\u0006\u0002\u0010\u0002J\u0010\u0010\u0003\u001a\u00020\u00042\u0006\u0010\u0005\u001a\u00020\u0006H\u0016\u00a8\u0006\b"}, d2={"Ldorkbox/executor/stop/DestroyProcessStopper;", "Ldorkbox/executor/stop/ProcessStopper;", "()V", "stop", "", "process", "Ljava/lang/Process;", "Companion", "Executor"})
public final class DestroyProcessStopper
implements ProcessStopper {
    @NotNull
    public static final Companion Companion = new Companion(null);
    @NotNull
    private static final ProcessStopper INSTANCE = new DestroyProcessStopper();

    @Override
    public void stop(@NotNull Process process) {
        Intrinsics.checkNotNullParameter((Object)process, (String)"process");
        process.destroy();
    }

    @Metadata(mv={1, 6, 0}, k=1, xi=48, d1={"\u0000\u0014\n\u0002\u0018\u0002\n\u0002\u0010\u0000\n\u0002\b\u0002\n\u0002\u0018\u0002\n\u0002\b\u0003\b\u0086\u0003\u0018\u00002\u00020\u0001B\u0007\b\u0002\u00a2\u0006\u0002\u0010\u0002R\u0011\u0010\u0003\u001a\u00020\u0004\u00a2\u0006\b\n\u0000\u001a\u0004\b\u0005\u0010\u0006\u00a8\u0006\u0007"}, d2={"Ldorkbox/executor/stop/DestroyProcessStopper$Companion;", "", "()V", "INSTANCE", "Ldorkbox/executor/stop/ProcessStopper;", "getINSTANCE", "()Ldorkbox/executor/stop/ProcessStopper;", "Executor"})
    public static final class Companion {
        private Companion() {
        }

        @NotNull
        public final ProcessStopper getINSTANCE() {
            return INSTANCE;
        }

        public /* synthetic */ Companion(DefaultConstructorMarker $constructor_marker) {
            this();
        }
    }
}

