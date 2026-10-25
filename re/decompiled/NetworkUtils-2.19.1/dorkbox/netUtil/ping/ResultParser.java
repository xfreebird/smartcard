/*
 * Decompiled with CFR 0.152.
 * 
 * Could not load the following classes:
 *  kotlin.Metadata
 *  kotlin.jvm.functions.Function2
 *  kotlin.jvm.internal.DefaultConstructorMarker
 *  kotlin.jvm.internal.Intrinsics
 *  org.jetbrains.annotations.NotNull
 */
package dorkbox.netUtil.ping;

import dorkbox.netUtil.ping.PingResult;
import java.util.regex.Matcher;
import java.util.regex.Pattern;
import kotlin.Metadata;
import kotlin.jvm.functions.Function2;
import kotlin.jvm.internal.DefaultConstructorMarker;
import kotlin.jvm.internal.Intrinsics;
import org.jetbrains.annotations.NotNull;

@Metadata(mv={1, 7, 1}, k=1, xi=48, d1={"\u0000(\n\u0002\u0018\u0002\n\u0002\u0010\u0000\n\u0000\n\u0002\u0018\u0002\n\u0000\n\u0002\u0018\u0002\n\u0002\u0018\u0002\n\u0002\u0018\u0002\n\u0002\b\u0004\n\u0002\u0010\u000e\n\u0002\b\u0002\u0018\u0000 \r2\u00020\u0001:\u0001\rB'\u0012\u0006\u0010\u0002\u001a\u00020\u0003\u0012\u0018\u0010\u0004\u001a\u0014\u0012\u0004\u0012\u00020\u0006\u0012\u0004\u0012\u00020\u0007\u0012\u0004\u0012\u00020\u00060\u0005\u00a2\u0006\u0002\u0010\bJ\u0016\u0010\t\u001a\u00020\u00062\u0006\u0010\n\u001a\u00020\u00062\u0006\u0010\u000b\u001a\u00020\fR\u000e\u0010\u0002\u001a\u00020\u0003X\u0082\u0004\u00a2\u0006\u0002\n\u0000R \u0010\u0004\u001a\u0014\u0012\u0004\u0012\u00020\u0006\u0012\u0004\u0012\u00020\u0007\u0012\u0004\u0012\u00020\u00060\u0005X\u0082\u0004\u00a2\u0006\u0002\n\u0000\u00a8\u0006\u000e"}, d2={"Ldorkbox/netUtil/ping/ResultParser;", "", "pattern", "Ljava/util/regex/Pattern;", "reader", "Lkotlin/Function2;", "Ldorkbox/netUtil/ping/PingResult;", "Ljava/util/regex/Matcher;", "(Ljava/util/regex/Pattern;Lkotlin/jvm/functions/Function2;)V", "fill", "result", "output", "", "Companion", "NetworkUtils"})
public final class ResultParser {
    @NotNull
    public static final Companion Companion = new Companion(null);
    @NotNull
    private final Pattern pattern;
    @NotNull
    private final Function2<PingResult, Matcher, PingResult> reader;

    public ResultParser(@NotNull Pattern pattern, @NotNull Function2<? super PingResult, ? super Matcher, PingResult> reader) {
        Intrinsics.checkNotNullParameter((Object)pattern, (String)"pattern");
        Intrinsics.checkNotNullParameter(reader, (String)"reader");
        this.pattern = pattern;
        this.reader = reader;
    }

    @NotNull
    public final PingResult fill(@NotNull PingResult result, @NotNull String output) {
        Intrinsics.checkNotNullParameter((Object)result, (String)"result");
        Intrinsics.checkNotNullParameter((Object)output, (String)"output");
        PingResult r = result;
        Matcher matcher = this.pattern.matcher(output);
        while (matcher.find()) {
            Intrinsics.checkNotNullExpressionValue((Object)matcher, (String)"matcher");
            r = (PingResult)this.reader.invoke((Object)r, (Object)matcher);
        }
        return r;
    }

    @Metadata(mv={1, 7, 1}, k=1, xi=48, d1={"\u0000&\n\u0002\u0018\u0002\n\u0002\u0010\u0000\n\u0002\b\u0002\n\u0002\u0018\u0002\n\u0000\n\u0002\u0010\u000e\n\u0000\n\u0002\u0018\u0002\n\u0002\u0018\u0002\n\u0002\u0018\u0002\n\u0000\b\u0086\u0003\u0018\u00002\u00020\u0001B\u0007\b\u0002\u00a2\u0006\u0002\u0010\u0002J(\u0010\u0003\u001a\u00020\u00042\u0006\u0010\u0005\u001a\u00020\u00062\u0018\u0010\u0007\u001a\u0014\u0012\u0004\u0012\u00020\t\u0012\u0004\u0012\u00020\n\u0012\u0004\u0012\u00020\t0\b\u00a8\u0006\u000b"}, d2={"Ldorkbox/netUtil/ping/ResultParser$Companion;", "", "()V", "of", "Ldorkbox/netUtil/ping/ResultParser;", "regex", "", "reader", "Lkotlin/Function2;", "Ldorkbox/netUtil/ping/PingResult;", "Ljava/util/regex/Matcher;", "NetworkUtils"})
    public static final class Companion {
        private Companion() {
        }

        @NotNull
        public final ResultParser of(@NotNull String regex, @NotNull Function2<? super PingResult, ? super Matcher, PingResult> reader) {
            Intrinsics.checkNotNullParameter((Object)regex, (String)"regex");
            Intrinsics.checkNotNullParameter(reader, (String)"reader");
            Pattern compile = Pattern.compile(regex);
            Intrinsics.checkNotNullExpressionValue((Object)compile, (String)"compile");
            return new ResultParser(compile, reader);
        }

        public /* synthetic */ Companion(DefaultConstructorMarker $constructor_marker) {
            this();
        }
    }
}

