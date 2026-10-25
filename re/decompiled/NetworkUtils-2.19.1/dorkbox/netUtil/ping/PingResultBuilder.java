/*
 * Decompiled with CFR 0.152.
 * 
 * Could not load the following classes:
 *  kotlin.Metadata
 *  kotlin.collections.CollectionsKt
 *  kotlin.jvm.functions.Function2
 *  kotlin.jvm.internal.Intrinsics
 *  org.jetbrains.annotations.NotNull
 */
package dorkbox.netUtil.ping;

import dorkbox.netUtil.Common;
import dorkbox.netUtil.ping.PingResult;
import dorkbox.netUtil.ping.PingResultBuilder;
import dorkbox.netUtil.ping.ResultParser;
import java.util.List;
import java.util.regex.Matcher;
import kotlin.Metadata;
import kotlin.collections.CollectionsKt;
import kotlin.jvm.functions.Function2;
import kotlin.jvm.internal.Intrinsics;
import org.jetbrains.annotations.NotNull;

@Metadata(mv={1, 7, 1}, k=1, xi=48, d1={"\u0000,\n\u0002\u0018\u0002\n\u0002\u0010\u0000\n\u0002\b\u0002\n\u0002\u0010 \n\u0002\u0018\u0002\n\u0000\n\u0002\u0018\u0002\n\u0002\u0018\u0002\n\u0002\u0018\u0002\n\u0002\b\u0002\n\u0002\u0010\u000e\n\u0000\b\u00c0\u0002\u0018\u00002\u00020\u0001B\u0007\b\u0002\u00a2\u0006\u0002\u0010\u0002J\u000e\u0010\n\u001a\u00020\b2\u0006\u0010\u000b\u001a\u00020\fR\u0014\u0010\u0003\u001a\b\u0012\u0004\u0012\u00020\u00050\u0004X\u0082\u0004\u00a2\u0006\u0002\n\u0000R \u0010\u0006\u001a\u0014\u0012\u0004\u0012\u00020\b\u0012\u0004\u0012\u00020\t\u0012\u0004\u0012\u00020\b0\u0007X\u0082\u0004\u00a2\u0006\u0002\n\u0000\u00a8\u0006\r"}, d2={"Ldorkbox/netUtil/ping/PingResultBuilder;", "", "()V", "resultParsers", "", "Ldorkbox/netUtil/ping/ResultParser;", "roundTripTimeParser", "Lkotlin/Function2;", "Ldorkbox/netUtil/ping/PingResult;", "Ljava/util/regex/Matcher;", "fromOutput", "output", "", "NetworkUtils"})
public final class PingResultBuilder {
    @NotNull
    public static final PingResultBuilder INSTANCE;
    @NotNull
    private static final Function2<PingResult, Matcher, PingResult> roundTripTimeParser;
    @NotNull
    private static final List<ResultParser> resultParsers;

    private PingResultBuilder() {
    }

    @NotNull
    public final PingResult fromOutput(@NotNull String output) {
        Intrinsics.checkNotNullParameter((Object)output, (String)"output");
        PingResult pingResult = new PingResult();
        Iterable $this$forEach$iv = resultParsers;
        boolean $i$f$forEach = false;
        for (Object element$iv : $this$forEach$iv) {
            ResultParser rp = (ResultParser)element$iv;
            boolean bl = false;
            rp.fill(pingResult, output);
        }
        return pingResult;
    }

    static {
        List list;
        INSTANCE = new PingResultBuilder();
        roundTripTimeParser = roundTripTimeParser.1.INSTANCE;
        if (Common.INSTANCE.getOS_MAC()) {
            Object[] objectArray = new ResultParser[]{ResultParser.Companion.of("PING (.*) \\((.*?)\\): (.*) data bytes", (Function2<? super PingResult, ? super Matcher, PingResult>)((Function2)resultParsers.1.INSTANCE)), ResultParser.Companion.of("(.*) packets transmitted, (.*) packets received, (.*)% packet loss", (Function2<? super PingResult, ? super Matcher, PingResult>)((Function2)resultParsers.2.INSTANCE)), ResultParser.Companion.of("round-trip min\\/avg\\/max\\/stddev = (.*)\\/(.*)\\/(.*)\\/(.*) ms", roundTripTimeParser), ResultParser.Companion.of("(.*) bytes from (.*): icmp_seq=(.*) ttl=(.*) time=(.*) ms", (Function2<? super PingResult, ? super Matcher, PingResult>)((Function2)resultParsers.3.INSTANCE))};
            list = CollectionsKt.listOf((Object[])objectArray);
        } else if (Common.INSTANCE.getOS_WINDOWS()) {
            Object[] objectArray = new ResultParser[]{ResultParser.Companion.of("Pinging (.*) with", (Function2<? super PingResult, ? super Matcher, PingResult>)((Function2)resultParsers.4.INSTANCE)), ResultParser.Companion.of("(.*) packets transmitted, (.*) packets received, (.*)% packet loss", (Function2<? super PingResult, ? super Matcher, PingResult>)((Function2)resultParsers.5.INSTANCE)), ResultParser.Companion.of("round-trip min\\/avg\\/max\\/stddev = (.*)\\/(.*)\\/(.*)\\/(.*) ms", roundTripTimeParser), ResultParser.Companion.of("(.*) bytes from (.*): icmp_seq=(.*) ttl=(.*) time=(.*) ms", (Function2<? super PingResult, ? super Matcher, PingResult>)((Function2)resultParsers.6.INSTANCE))};
            list = CollectionsKt.listOf((Object[])objectArray);
        } else {
            Object[] objectArray = new ResultParser[]{ResultParser.Companion.of("PING (.*) \\((.*?)\\)", (Function2<? super PingResult, ? super Matcher, PingResult>)((Function2)resultParsers.7.INSTANCE)), ResultParser.Companion.of("(.*) packets transmitted, (.*) received, (.*)% packet loss, time (.*)ms", (Function2<? super PingResult, ? super Matcher, PingResult>)((Function2)resultParsers.8.INSTANCE)), ResultParser.Companion.of("rtt min\\/avg\\/max\\/mdev = (.*)\\/(.*)\\/(.*)\\/(.*) ms", roundTripTimeParser)};
            list = CollectionsKt.listOf((Object[])objectArray);
        }
        resultParsers = list;
    }
}

