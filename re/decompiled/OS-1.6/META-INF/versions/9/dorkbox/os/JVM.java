/*
 * Decompiled with CFR 0.152.
 * 
 * Could not load the following classes:
 *  kotlin.Metadata
 *  org.jetbrains.annotations.NotNull
 */
package dorkbox.os;

import kotlin.Metadata;
import org.jetbrains.annotations.NotNull;

/*
 * Multiple versions of this class in jar - see https://www.benf.org/other/cfr/multi-version-jar.html
 */
@Metadata(mv={1, 6, 0}, k=1, xi=48, d1={"\u0000\u0014\n\u0002\u0018\u0002\n\u0002\u0010\u0000\n\u0002\b\u0002\n\u0002\u0010\u000b\n\u0002\b\u0005\b\u00c0\u0002\u0018\u00002\u00020\u0001B\u0007\b\u0002\u00a2\u0006\u0002\u0010\u0002R\u001a\u0010\u0003\u001a\u00020\u0004X\u0086\u000e\u00a2\u0006\u000e\n\u0000\u001a\u0004\b\u0005\u0010\u0006\"\u0004\b\u0007\u0010\b\u00a8\u0006\t"}, d2={"Ldorkbox/os/JVM;", "", "()V", "usesJpms", "", "getUsesJpms", "()Z", "setUsesJpms", "(Z)V", "OS"})
public final class JVM {
    @NotNull
    public static final JVM INSTANCE = new JVM();
    private static boolean usesJpms = true == ModuleLayer.boot().findModule("java.desktop").isPresent();

    private JVM() {
    }

    public final boolean getUsesJpms() {
        return usesJpms;
    }

    public final void setUsesJpms(boolean bl) {
        usesJpms = bl;
    }
}

