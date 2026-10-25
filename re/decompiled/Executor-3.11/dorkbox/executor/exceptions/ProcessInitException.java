/*
 * Decompiled with CFR 0.152.
 * 
 * Could not load the following classes:
 *  kotlin.Metadata
 *  kotlin.jvm.internal.DefaultConstructorMarker
 *  kotlin.jvm.internal.Intrinsics
 *  kotlin.text.StringsKt
 *  org.jetbrains.annotations.NotNull
 *  org.jetbrains.annotations.Nullable
 */
package dorkbox.executor.exceptions;

import java.io.IOException;
import kotlin.Metadata;
import kotlin.jvm.internal.DefaultConstructorMarker;
import kotlin.jvm.internal.Intrinsics;
import kotlin.text.StringsKt;
import org.jetbrains.annotations.NotNull;
import org.jetbrains.annotations.Nullable;

@Metadata(mv={1, 6, 0}, k=1, xi=48, d1={"\u0000\u001e\n\u0002\u0018\u0002\n\u0002\u0018\u0002\n\u0000\n\u0002\u0010\u000e\n\u0000\n\u0002\u0010\u0003\n\u0000\n\u0002\u0010\b\n\u0002\b\u0005\u0018\u0000 \u000b2\u00020\u0001:\u0001\u000bB!\u0012\b\u0010\u0002\u001a\u0004\u0018\u00010\u0003\u0012\b\u0010\u0004\u001a\u0004\u0018\u00010\u0005\u0012\u0006\u0010\u0006\u001a\u00020\u0007\u00a2\u0006\u0002\u0010\bR\u0011\u0010\u0006\u001a\u00020\u0007\u00a2\u0006\b\n\u0000\u001a\u0004\b\t\u0010\n\u00a8\u0006\f"}, d2={"Ldorkbox/executor/exceptions/ProcessInitException;", "Ljava/io/IOException;", "message", "", "cause", "", "errorCode", "", "(Ljava/lang/String;Ljava/lang/Throwable;I)V", "getErrorCode", "()I", "Companion", "Executor"})
public final class ProcessInitException
extends IOException {
    @NotNull
    public static final Companion Companion = new Companion(null);
    private final int errorCode;
    @NotNull
    private static final String BEFORE_CODE = " error=";
    @NotNull
    private static final String AFTER_CODE = ", ";
    @NotNull
    private static final String NEW_INFIX = " Error=";

    public ProcessInitException(@Nullable String message, @Nullable Throwable cause, int errorCode) {
        super(message, cause);
        this.errorCode = errorCode;
    }

    public final int getErrorCode() {
        return this.errorCode;
    }

    @Metadata(mv={1, 6, 0}, k=1, xi=48, d1={"\u0000&\n\u0002\u0018\u0002\n\u0002\u0010\u0000\n\u0002\b\u0002\n\u0002\u0010\u000e\n\u0002\b\u0003\n\u0002\u0018\u0002\n\u0002\b\u0002\n\u0002\u0018\u0002\n\u0002\u0018\u0002\n\u0000\b\u0086\u0003\u0018\u00002\u00020\u0001B\u0007\b\u0002\u00a2\u0006\u0002\u0010\u0002J \u0010\u0007\u001a\u0004\u0018\u00010\b2\n\b\u0002\u0010\t\u001a\u0004\u0018\u00010\u00042\n\u0010\n\u001a\u00060\u000bj\u0002`\fR\u000e\u0010\u0003\u001a\u00020\u0004X\u0082T\u00a2\u0006\u0002\n\u0000R\u000e\u0010\u0005\u001a\u00020\u0004X\u0082T\u00a2\u0006\u0002\n\u0000R\u000e\u0010\u0006\u001a\u00020\u0004X\u0082T\u00a2\u0006\u0002\n\u0000\u00a8\u0006\r"}, d2={"Ldorkbox/executor/exceptions/ProcessInitException$Companion;", "", "()V", "AFTER_CODE", "", "BEFORE_CODE", "NEW_INFIX", "newInstance", "Ldorkbox/executor/exceptions/ProcessInitException;", "prefix", "e", "Ljava/lang/Exception;", "Lkotlin/Exception;", "Executor"})
    public static final class Companion {
        private Companion() {
        }

        @Nullable
        public final ProcessInitException newInstance(@Nullable String prefix, @NotNull Exception e) {
            int n;
            String string2;
            int n2;
            Intrinsics.checkNotNullParameter((Object)e, (String)"e");
            String string3 = e.getMessage();
            if (string3 == null) {
                return null;
            }
            String m = string3;
            int i = StringsKt.lastIndexOf$default((CharSequence)m, (String)ProcessInitException.BEFORE_CODE, (int)0, (boolean)false, (int)6, null);
            if (i == -1) {
                return null;
            }
            int j = StringsKt.indexOf$default((CharSequence)m, (String)ProcessInitException.AFTER_CODE, (int)i, (boolean)false, (int)4, null);
            if (j == -1) {
                return null;
            }
            try {
                String string4 = m;
                n2 = i + ProcessInitException.BEFORE_CODE.length();
                string2 = string4.substring(n2, j);
                Intrinsics.checkNotNullExpressionValue((Object)string2, (String)"this as java.lang.String\u2026ing(startIndex, endIndex)");
                n = Integer.parseInt(string2);
            }
            catch (NumberFormatException n3) {
                return null;
            }
            int code = n;
            StringBuilder stringBuilder = new StringBuilder().append((Object)prefix).append(ProcessInitException.NEW_INFIX);
            String string5 = m;
            n2 = i + ProcessInitException.BEFORE_CODE.length();
            string2 = string5.substring(n2);
            Intrinsics.checkNotNullExpressionValue((Object)string2, (String)"this as java.lang.String).substring(startIndex)");
            return new ProcessInitException(stringBuilder.append(string2).toString(), e, code);
        }

        public static /* synthetic */ ProcessInitException newInstance$default(Companion companion, String string2, Exception exception, int n, Object object) {
            if ((n & 1) != 0) {
                string2 = "";
            }
            return companion.newInstance(string2, exception);
        }

        public /* synthetic */ Companion(DefaultConstructorMarker $constructor_marker) {
            this();
        }
    }
}

