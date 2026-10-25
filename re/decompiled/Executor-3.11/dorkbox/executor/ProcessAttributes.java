/*
 * Decompiled with CFR 0.152.
 * 
 * Could not load the following classes:
 *  kotlin.Metadata
 *  kotlin.collections.SetsKt
 *  kotlin.jvm.internal.DefaultConstructorMarker
 *  kotlin.jvm.internal.Intrinsics
 *  org.jetbrains.annotations.NotNull
 *  org.jetbrains.annotations.Nullable
 */
package dorkbox.executor;

import java.io.File;
import java.util.List;
import java.util.Map;
import java.util.Set;
import kotlin.Metadata;
import kotlin.collections.SetsKt;
import kotlin.jvm.internal.DefaultConstructorMarker;
import kotlin.jvm.internal.Intrinsics;
import org.jetbrains.annotations.NotNull;
import org.jetbrains.annotations.Nullable;

@Metadata(mv={1, 6, 0}, k=1, xi=48, d1={"\u0000,\n\u0002\u0018\u0002\n\u0002\u0010\u0000\n\u0000\n\u0002\u0010 \n\u0002\u0010\u000e\n\u0000\n\u0002\u0018\u0002\n\u0000\n\u0002\u0010$\n\u0000\n\u0002\u0010\"\n\u0002\u0010\b\n\u0002\b\n\b\u0000\u0018\u00002\u00020\u0001BC\u0012\f\u0010\u0002\u001a\b\u0012\u0004\u0012\u00020\u00040\u0003\u0012\b\u0010\u0005\u001a\u0004\u0018\u00010\u0006\u0012\u0014\u0010\u0007\u001a\u0010\u0012\u0004\u0012\u00020\u0004\u0012\u0006\u0012\u0004\u0018\u00010\u00040\b\u0012\u000e\b\u0002\u0010\t\u001a\b\u0012\u0004\u0012\u00020\u000b0\n\u00a2\u0006\u0002\u0010\fR\u0017\u0010\t\u001a\b\u0012\u0004\u0012\u00020\u000b0\n\u00a2\u0006\b\n\u0000\u001a\u0004\b\r\u0010\u000eR\u0017\u0010\u0002\u001a\b\u0012\u0004\u0012\u00020\u00040\u0003\u00a2\u0006\b\n\u0000\u001a\u0004\b\u000f\u0010\u0010R\u0013\u0010\u0005\u001a\u0004\u0018\u00010\u0006\u00a2\u0006\b\n\u0000\u001a\u0004\b\u0011\u0010\u0012R\u001f\u0010\u0007\u001a\u0010\u0012\u0004\u0012\u00020\u0004\u0012\u0006\u0012\u0004\u0018\u00010\u00040\b\u00a2\u0006\b\n\u0000\u001a\u0004\b\u0013\u0010\u0014\u00a8\u0006\u0015"}, d2={"Ldorkbox/executor/ProcessAttributes;", "", "command", "", "", "directory", "Ljava/io/File;", "environment", "", "allowedExitValues", "", "", "(Ljava/util/List;Ljava/io/File;Ljava/util/Map;Ljava/util/Set;)V", "getAllowedExitValues", "()Ljava/util/Set;", "getCommand", "()Ljava/util/List;", "getDirectory", "()Ljava/io/File;", "getEnvironment", "()Ljava/util/Map;", "Executor"})
public final class ProcessAttributes {
    @NotNull
    private final List<String> command;
    @Nullable
    private final File directory;
    @NotNull
    private final Map<String, String> environment;
    @NotNull
    private final Set<Integer> allowedExitValues;

    public ProcessAttributes(@NotNull List<String> command, @Nullable File directory, @NotNull Map<String, String> environment, @NotNull Set<Integer> allowedExitValues) {
        Intrinsics.checkNotNullParameter(command, (String)"command");
        Intrinsics.checkNotNullParameter(environment, (String)"environment");
        Intrinsics.checkNotNullParameter(allowedExitValues, (String)"allowedExitValues");
        this.command = command;
        this.directory = directory;
        this.environment = environment;
        this.allowedExitValues = allowedExitValues;
    }

    public /* synthetic */ ProcessAttributes(List list, File file, Map map, Set set, int n, DefaultConstructorMarker defaultConstructorMarker) {
        if ((n & 8) != 0) {
            set = SetsKt.emptySet();
        }
        this(list, file, map, set);
    }

    @NotNull
    public final List<String> getCommand() {
        return this.command;
    }

    @Nullable
    public final File getDirectory() {
        return this.directory;
    }

    @NotNull
    public final Map<String, String> getEnvironment() {
        return this.environment;
    }

    @NotNull
    public final Set<Integer> getAllowedExitValues() {
        return this.allowedExitValues;
    }
}

