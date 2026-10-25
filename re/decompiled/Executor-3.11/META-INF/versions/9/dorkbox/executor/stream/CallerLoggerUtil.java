/*
 * Decompiled with CFR 0.152.
 * 
 * Could not load the following classes:
 *  kotlin.Metadata
 *  kotlin.jvm.internal.Intrinsics
 *  kotlin.text.StringsKt
 *  org.jetbrains.annotations.NotNull
 *  org.jetbrains.annotations.Nullable
 */
package dorkbox.executor.stream;

import java.util.Optional;
import java.util.stream.Stream;
import kotlin.Metadata;
import kotlin.jvm.internal.Intrinsics;
import kotlin.text.StringsKt;
import org.jetbrains.annotations.NotNull;
import org.jetbrains.annotations.Nullable;

/*
 * Illegal identifiers - consider using --renameillegalidents true
 * Multiple versions of this class in jar - see https://www.benf.org/other/cfr/multi-version-jar.html
 */
@Metadata(mv={1, 6, 0}, k=1, xi=48, d1={"\u0000\u001a\n\u0002\u0018\u0002\n\u0002\u0010\u0000\n\u0002\b\u0002\n\u0002\u0010\u000e\n\u0002\b\u0002\n\u0002\u0010\b\n\u0000\b\u00c6\u0002\u0018\u00002\u00020\u0001B\u0007\b\u0002\u00a2\u0006\u0002\u0010\u0002J\u0012\u0010\u0003\u001a\u00020\u00042\n\b\u0002\u0010\u0005\u001a\u0004\u0018\u00010\u0004J\u0018\u0010\u0003\u001a\u00020\u00042\b\u0010\u0005\u001a\u0004\u0018\u00010\u00042\u0006\u0010\u0006\u001a\u00020\u0007\u00a8\u0006\b"}, d2={"Ldorkbox/executor/stream/CallerLoggerUtil;", "", "()V", "getName", "", "name", "level", "", "Executor"})
public final class CallerLoggerUtil {
    @NotNull
    public static final CallerLoggerUtil INSTANCE = new CallerLoggerUtil();

    private CallerLoggerUtil() {
    }

    @NotNull
    public final String getName(@Nullable String name) {
        return this.getName(name, 2);
    }

    public static /* synthetic */ String getName$default(CallerLoggerUtil callerLoggerUtil, String string, int n, Object object) {
        if ((n & 1) != 0) {
            string = null;
        }
        return callerLoggerUtil.getName(string);
    }

    @NotNull
    public final String getName(@Nullable String name, int level) {
        Object object;
        if (name == null) {
            String string = ((Class)StackWalker.getInstance(StackWalker.Option.RETAIN_CLASS_REFERENCE).walk(arg_0 -> CallerLoggerUtil.getName$lambda-0(level, arg_0)).get()).getName();
            Intrinsics.checkNotNullExpressionValue((Object)string, (String)"{\n                StackW\u2026.get().name\n            }");
            object = string;
        } else {
            object = StringsKt.contains$default((CharSequence)name, (CharSequence)".", (boolean)false, (int)2, null) ? name : ((Class)StackWalker.getInstance(StackWalker.Option.RETAIN_CLASS_REFERENCE).walk(arg_0 -> CallerLoggerUtil.getName$lambda-1(level, arg_0)).get()).getName() + "." + name;
        }
        return object;
    }

    private static final Optional getName$lambda-0(int $level, Stream s) {
        return s.map(StackWalker.StackFrame::getDeclaringClass).skip($level).findFirst();
    }

    private static final Optional getName$lambda-1(int $level, Stream s) {
        return s.map(StackWalker.StackFrame::getDeclaringClass).skip($level).findFirst();
    }
}

