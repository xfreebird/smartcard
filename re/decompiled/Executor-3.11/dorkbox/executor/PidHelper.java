/*
 * Decompiled with CFR 0.152.
 * 
 * Could not load the following classes:
 *  kotlin.Metadata
 *  kotlin.jvm.internal.Intrinsics
 *  org.jetbrains.annotations.NotNull
 */
package dorkbox.executor;

import java.lang.reflect.Field;
import kotlin.Metadata;
import kotlin.jvm.internal.Intrinsics;
import org.jetbrains.annotations.NotNull;

/*
 * Multiple versions of this class in jar - see https://www.benf.org/other/cfr/multi-version-jar.html
 */
@Metadata(mv={1, 6, 0}, k=1, xi=48, d1={"\u0000\u001a\n\u0002\u0018\u0002\n\u0002\u0010\u0000\n\u0002\b\u0002\n\u0002\u0010\t\n\u0002\b\u0002\n\u0002\u0018\u0002\n\u0000\b\u00c0\u0002\u0018\u00002\u00020\u0001B\u0007\b\u0002\u00a2\u0006\u0002\u0010\u0002J\u000e\u0010\u0005\u001a\u00020\u00042\u0006\u0010\u0006\u001a\u00020\u0007R\u000e\u0010\u0003\u001a\u00020\u0004X\u0086T\u00a2\u0006\u0002\n\u0000\u00a8\u0006\b"}, d2={"Ldorkbox/executor/PidHelper;", "", "()V", "INVALID", "", "get", "process", "Ljava/lang/Process;", "Executor"})
public final class PidHelper {
    @NotNull
    public static final PidHelper INSTANCE = new PidHelper();
    public static final long INVALID = -1L;

    private PidHelper() {
    }

    public final long get(@NotNull Process process) {
        Intrinsics.checkNotNullParameter((Object)process, (String)"process");
        String type = process.getClass().getName();
        try {
            if (Intrinsics.areEqual((Object)type, (Object)"java.lang.UNIXProcess")) {
                Field field = process.getClass().getDeclaredField("pid");
                Intrinsics.checkNotNullExpressionValue((Object)field, (String)"process.javaClass.getDeclaredField(\"pid\")");
                Field f = field;
                f.setAccessible(true);
                return f.getInt(process);
            }
        }
        catch (Exception exception) {
            // empty catch block
        }
        return -1L;
    }
}

