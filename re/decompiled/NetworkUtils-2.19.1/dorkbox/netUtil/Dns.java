/*
 * Decompiled with CFR 0.152.
 * 
 * Could not load the following classes:
 *  dorkbox.executor.Executor
 *  kotlin.Lazy
 *  kotlin.LazyKt
 *  kotlin.Metadata
 *  kotlin.Unit
 *  kotlin.io.CloseableKt
 *  kotlin.io.TextStreamsKt
 *  kotlin.jvm.functions.Function0
 *  kotlin.jvm.internal.Intrinsics
 *  kotlin.sequences.Sequence
 *  kotlin.text.Charsets
 *  kotlin.text.StringsKt
 *  org.jetbrains.annotations.NotNull
 *  org.jetbrains.annotations.Nullable
 */
package dorkbox.netUtil;

import dorkbox.executor.Executor;
import dorkbox.netUtil.Common;
import dorkbox.netUtil.Dns;
import dorkbox.netUtil.dnsUtils.DefaultHostsFileResolver;
import dorkbox.netUtil.dnsUtils.ResolvedAddressTypes;
import java.io.BufferedReader;
import java.io.BufferedWriter;
import java.io.Closeable;
import java.io.File;
import java.io.FileWriter;
import java.io.IOException;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.io.Reader;
import java.net.InetAddress;
import java.net.InetSocketAddress;
import java.nio.charset.Charset;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import kotlin.Lazy;
import kotlin.LazyKt;
import kotlin.Metadata;
import kotlin.Unit;
import kotlin.io.CloseableKt;
import kotlin.io.TextStreamsKt;
import kotlin.jvm.functions.Function0;
import kotlin.jvm.internal.Intrinsics;
import kotlin.sequences.Sequence;
import kotlin.text.Charsets;
import kotlin.text.StringsKt;
import org.jetbrains.annotations.NotNull;
import org.jetbrains.annotations.Nullable;

@Metadata(mv={1, 7, 1}, k=1, xi=48, d1={"\u0000T\n\u0002\u0018\u0002\n\u0002\u0010\u0000\n\u0002\b\u0002\n\u0002\u0010\u000e\n\u0000\n\u0002\u0010 \n\u0002\u0018\u0002\n\u0002\b\u0005\n\u0002\u0018\u0002\n\u0002\u0018\u0002\n\u0000\n\u0002\u0010$\n\u0002\b\u0004\n\u0002\u0010\b\n\u0002\b\b\n\u0002\u0010\u000b\n\u0000\n\u0002\u0018\u0002\n\u0002\b\u0002\n\u0002\u0018\u0002\n\u0000\n\u0002\u0010\u0002\n\u0002\b\u0003\b\u00c6\u0002\u0018\u00002\u00020\u0001B\u0007\b\u0002\u00a2\u0006\u0002\u0010\u0002J\u0010\u0010\u001b\u001a\u0004\u0018\u00010\u00042\u0006\u0010\u001c\u001a\u00020\u0004J\u000e\u0010\u001d\u001a\u00020\u001e2\u0006\u0010\u001c\u001a\u00020\u0004J\u001a\u0010\u001f\u001a\u0004\u0018\u00010 2\u0006\u0010!\u001a\u00020\u00042\b\b\u0002\u0010\"\u001a\u00020#J\u000e\u0010$\u001a\u00020%2\u0006\u0010&\u001a\u00020\u0004J\u000e\u0010'\u001a\u00020\u00042\u0006\u0010\u001c\u001a\u00020\u0004R\u000e\u0010\u0003\u001a\u00020\u0004X\u0086T\u00a2\u0006\u0002\n\u0000R!\u0010\u0005\u001a\b\u0012\u0004\u0012\u00020\u00070\u00068FX\u0086\u0084\u0002\u00a2\u0006\f\n\u0004\b\n\u0010\u000b\u001a\u0004\b\b\u0010\tR\u001e\u0010\f\u001a\u0012\u0012\u0004\u0012\u00020\u00040\rj\b\u0012\u0004\u0012\u00020\u0004`\u000eX\u0082\u0004\u00a2\u0006\u0002\n\u0000R-\u0010\u000f\u001a\u0014\u0012\u0004\u0012\u00020\u0004\u0012\n\u0012\b\u0012\u0004\u0012\u00020\u00070\u00060\u00108FX\u0086\u0084\u0002\u00a2\u0006\f\n\u0004\b\u0013\u0010\u000b\u001a\u0004\b\u0011\u0010\u0012R\u001b\u0010\u0014\u001a\u00020\u00158FX\u0086\u0084\u0002\u00a2\u0006\f\n\u0004\b\u0018\u0010\u000b\u001a\u0004\b\u0016\u0010\u0017R\u001e\u0010\u0019\u001a\u0012\u0012\u0004\u0012\u00020\u00040\rj\b\u0012\u0004\u0012\u00020\u0004`\u000eX\u0082\u0004\u00a2\u0006\u0002\n\u0000R\u000e\u0010\u001a\u001a\u00020\u0004X\u0086T\u00a2\u0006\u0002\n\u0000\u00a8\u0006("}, d2={"Ldorkbox/netUtil/Dns;", "", "()V", "DEFAULT_SEARCH_DOMAIN", "", "defaultNameServers", "", "Ljava/net/InetSocketAddress;", "getDefaultNameServers", "()Ljava/util/List;", "defaultNameServers$delegate", "Lkotlin/Lazy;", "exceptions", "Ljava/util/HashSet;", "Lkotlin/collections/HashSet;", "nameServers", "", "getNameServers", "()Ljava/util/Map;", "nameServers$delegate", "numberDots", "", "getNumberDots", "()I", "numberDots$delegate", "suffixes", "version", "extractSLD", "domain", "isTLD", "", "resolveFromHosts", "Ljava/net/InetAddress;", "inetHost", "resolvedAddressTypes", "Ldorkbox/netUtil/dnsUtils/ResolvedAddressTypes;", "setDNSServers", "", "dnsServersString", "withoutTLD", "NetworkUtils"})
public final class Dns {
    @NotNull
    public static final Dns INSTANCE = new Dns();
    @NotNull
    public static final String version = "2.19.1";
    @NotNull
    public static final String DEFAULT_SEARCH_DOMAIN = "";
    @NotNull
    private static final HashSet<String> exceptions = new HashSet();
    @NotNull
    private static final HashSet<String> suffixes = new HashSet();
    @NotNull
    private static final Lazy nameServers$delegate = LazyKt.lazy((Function0)nameServers.2.INSTANCE);
    @NotNull
    private static final Lazy defaultNameServers$delegate = LazyKt.lazy((Function0)defaultNameServers.2.INSTANCE);
    @NotNull
    private static final Lazy numberDots$delegate = LazyKt.lazy((Function0)numberDots.2.INSTANCE);

    private Dns() {
    }

    /*
     * WARNING - Removed try catching itself - possible behaviour change.
     */
    public final void setDNSServers(@NotNull String dnsServersString) {
        String[] stringArray;
        Intrinsics.checkNotNullParameter((Object)dnsServersString, (String)"dnsServersString");
        if (Common.INSTANCE.getOS_LINUX()) {
            String[] stringArray2 = new String[]{","};
            List dnsServers = StringsKt.split$default((CharSequence)dnsServersString, (String[])stringArray2, (boolean)false, (int)0, (int)6, null);
            File dnsFile = new File("/etc/resolvconf/resolv.conf.d/head");
            if (!dnsFile.canRead()) {
                throw new IOException("Unable to initialize dns server file. Something is SERIOUSLY wrong");
            }
            stringArray = (String[])new BufferedWriter(new FileWriter(dnsFile));
            Throwable throwable = null;
            try {
                BufferedWriter it = (BufferedWriter)stringArray;
                boolean bl = false;
                it.write("# File location: /etc/resolvconf/resolv.conf.d/head\n");
                it.write("# Dynamic resolv.conf(5) file for glibc resolver(3) generated by resolvconf(8)\n");
                Iterable $this$forEach$iv = dnsServers;
                boolean $i$f$forEach = false;
                for (Object element$iv : $this$forEach$iv) {
                    String dns = (String)element$iv;
                    boolean bl2 = false;
                    it.write("nameserver " + dns + '\n');
                }
                it.flush();
                Unit unit = Unit.INSTANCE;
            }
            catch (Throwable throwable2) {
                throwable = throwable2;
                throw throwable2;
            }
            finally {
                CloseableKt.closeFinally((Closeable)stringArray, (Throwable)throwable);
            }
        } else {
            throw new RuntimeException("NOT IMPL.");
        }
        stringArray = new String[]{"resolvconf", "-u"};
        Executor.startBlocking$default((Executor)new Executor().command(stringArray), (long)0L, null, (int)3, null);
    }

    @Nullable
    public final InetAddress resolveFromHosts(@NotNull String inetHost, @NotNull ResolvedAddressTypes resolvedAddressTypes) {
        Intrinsics.checkNotNullParameter((Object)inetHost, (String)"inetHost");
        Intrinsics.checkNotNullParameter((Object)((Object)resolvedAddressTypes), (String)"resolvedAddressTypes");
        return DefaultHostsFileResolver.INSTANCE.address(inetHost, resolvedAddressTypes);
    }

    public static /* synthetic */ InetAddress resolveFromHosts$default(Dns dns, String string, ResolvedAddressTypes resolvedAddressTypes, int n, Object object) {
        if ((n & 2) != 0) {
            resolvedAddressTypes = ResolvedAddressTypes.IPV4_PREFERRED;
        }
        return dns.resolveFromHosts(string, resolvedAddressTypes);
    }

    @NotNull
    public final Map<String, List<InetSocketAddress>> getNameServers() {
        Lazy lazy = nameServers$delegate;
        return (Map)lazy.getValue();
    }

    @NotNull
    public final List<InetSocketAddress> getDefaultNameServers() {
        Lazy lazy = defaultNameServers$delegate;
        return (List)lazy.getValue();
    }

    public final int getNumberDots() {
        Lazy lazy = numberDots$delegate;
        return ((Number)lazy.getValue()).intValue();
    }

    @Nullable
    public final String extractSLD(@NotNull String domain) {
        String domain2;
        Intrinsics.checkNotNullParameter((Object)domain, (String)"domain");
        String last = domain2 = domain;
        boolean anySLD = false;
        do {
            if (this.isTLD(domain2)) {
                return anySLD ? last : (String)null;
            }
            anySLD = true;
            last = domain2;
            int nextDot = StringsKt.indexOf$default((CharSequence)domain2, (String)".", (int)0, (boolean)false, (int)6, null);
            if (nextDot == -1) {
                return null;
            }
            Intrinsics.checkNotNullExpressionValue((Object)domain2.substring(nextDot + 1), (String)"this as java.lang.String).substring(startIndex)");
        } while (((CharSequence)domain2).length() > 0);
        return null;
    }

    @NotNull
    public final String withoutTLD(@NotNull String domain) {
        Intrinsics.checkNotNullParameter((Object)domain, (String)"domain");
        for (int index = 0; index != -1; ++index) {
            if ((index = StringsKt.indexOf$default((CharSequence)domain, (char)'.', (int)index, (boolean)false, (int)4, null)) != -1) {
                String string = domain.substring(index);
                Intrinsics.checkNotNullExpressionValue((Object)string, (String)"this as java.lang.String).substring(startIndex)");
                if (!this.isTLD(string)) continue;
                String string2 = domain.substring(0, index);
                Intrinsics.checkNotNullExpressionValue((Object)string2, (String)"this as java.lang.String\u2026ing(startIndex, endIndex)");
                return string2;
            }
            return DEFAULT_SEARCH_DOMAIN;
        }
        return DEFAULT_SEARCH_DOMAIN;
    }

    public final boolean isTLD(@NotNull String domain) {
        Intrinsics.checkNotNullParameter((Object)domain, (String)"domain");
        String domain2 = domain;
        if (StringsKt.startsWith$default((String)domain2, (String)".", (boolean)false, (int)2, null)) {
            String string = domain2.substring(1);
            Intrinsics.checkNotNullExpressionValue((Object)string, (String)"this as java.lang.String).substring(startIndex)");
            domain2 = string;
        }
        if (exceptions.contains(domain2)) {
            return false;
        }
        if (suffixes.contains(domain2)) {
            return true;
        }
        int nextdot = StringsKt.indexOf$default((CharSequence)domain2, (char)'.', (int)0, (boolean)false, (int)6, null);
        if (nextdot == -1) {
            return false;
        }
        StringBuilder stringBuilder = new StringBuilder().append('*');
        String string = domain2.substring(nextdot);
        Intrinsics.checkNotNullExpressionValue((Object)string, (String)"this as java.lang.String).substring(startIndex)");
        domain2 = stringBuilder.append(string).toString();
        return suffixes.contains(domain2);
    }

    /*
     * WARNING - Removed try catching itself - possible behaviour change.
     */
    static {
        InputStream tldResource = INSTANCE.getClass().getResourceAsStream("/effective_tld_names.dat");
        Intrinsics.checkNotNullExpressionValue((Object)tldResource, (String)"tldResource");
        InputStream inputStream = tldResource;
        Charset charset = Charsets.UTF_8;
        Closeable closeable = new InputStreamReader(inputStream, charset);
        int n = 8192;
        Reader $this$useLines$iv = closeable instanceof BufferedReader ? (BufferedReader)closeable : new BufferedReader((Reader)closeable, n);
        boolean $i$f$useLines = false;
        closeable = $this$useLines$iv;
        n = 8192;
        closeable = closeable instanceof BufferedReader ? (BufferedReader)closeable : new BufferedReader((Reader)closeable, n);
        Throwable throwable = null;
        try {
            BufferedReader it$iv = (BufferedReader)closeable;
            boolean bl = false;
            Sequence lines = TextStreamsKt.lineSequence((BufferedReader)it$iv);
            boolean bl2 = false;
            Sequence $this$forEach$iv = lines;
            boolean $i$f$forEach = false;
            for (Object element$iv : $this$forEach$iv) {
                boolean isException;
                String line = (String)element$iv;
                boolean bl3 = false;
                String line2 = line;
                if (!(((CharSequence)line2).length() > 0) || StringsKt.startsWith$default((String)line2, (String)"//", (boolean)false, (int)2, null)) continue;
                if (StringsKt.startsWith$default((String)line2, (String)".", (boolean)false, (int)2, null)) {
                    String string = line2.substring(1);
                    Intrinsics.checkNotNullExpressionValue((Object)string, (String)"this as java.lang.String).substring(startIndex)");
                    line2 = string;
                }
                if (isException = StringsKt.startsWith$default((String)line2, (String)"!", (boolean)false, (int)2, null)) {
                    String string = line2.substring(1);
                    Intrinsics.checkNotNullExpressionValue((Object)string, (String)"this as java.lang.String).substring(startIndex)");
                    line2 = string;
                }
                if (isException) {
                    exceptions.add(line2);
                    continue;
                }
                suffixes.add(line2);
            }
            Unit unit = Unit.INSTANCE;
        }
        catch (Throwable throwable2) {
            throwable = throwable2;
            throw throwable2;
        }
        finally {
            CloseableKt.closeFinally((Closeable)closeable, (Throwable)throwable);
        }
    }
}

