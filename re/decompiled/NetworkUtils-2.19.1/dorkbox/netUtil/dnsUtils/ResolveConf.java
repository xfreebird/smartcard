/*
 * Decompiled with CFR 0.152.
 * 
 * Could not load the following classes:
 *  com.sun.jna.Memory
 *  com.sun.jna.Pointer
 *  com.sun.jna.ptr.IntByReference
 *  kotlin.Metadata
 *  kotlin.Pair
 *  kotlin.Unit
 *  kotlin.io.CloseableKt
 *  kotlin.jvm.internal.Intrinsics
 *  kotlin.jvm.internal.TypeIntrinsics
 *  kotlin.text.Regex
 *  kotlin.text.StringsKt
 *  org.jetbrains.annotations.NotNull
 */
package dorkbox.netUtil.dnsUtils;

import com.sun.jna.Memory;
import com.sun.jna.Pointer;
import com.sun.jna.ptr.IntByReference;
import dorkbox.netUtil.Common;
import dorkbox.netUtil.IP;
import dorkbox.netUtil.jna.windows.IPHlpAPI;
import dorkbox.netUtil.jna.windows.structs.IP_ADAPTER_ADDRESSES_LH;
import java.io.BufferedReader;
import java.io.Closeable;
import java.io.FileReader;
import java.io.IOException;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.net.Inet4Address;
import java.net.InetSocketAddress;
import java.net.URI;
import java.net.URISyntaxException;
import java.net.UnknownHostException;
import java.nio.file.Files;
import java.nio.file.LinkOption;
import java.nio.file.OpenOption;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.ArrayList;
import java.util.Hashtable;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.StringTokenizer;
import javax.naming.NamingException;
import javax.naming.directory.InitialDirContext;
import kotlin.Metadata;
import kotlin.Pair;
import kotlin.Unit;
import kotlin.io.CloseableKt;
import kotlin.jvm.internal.Intrinsics;
import kotlin.jvm.internal.TypeIntrinsics;
import kotlin.text.Regex;
import kotlin.text.StringsKt;
import org.jetbrains.annotations.NotNull;

@Metadata(mv={1, 7, 1}, k=1, xi=48, d1={"\u0000R\n\u0002\u0018\u0002\n\u0002\u0010\u0000\n\u0002\b\u0002\n\u0002\u0010\u000e\n\u0002\b\u0003\n\u0002\u0010\b\n\u0000\n\u0002\u0018\u0002\n\u0000\n\u0002\u0010$\n\u0002\u0010 \n\u0002\u0018\u0002\n\u0002\b\u0003\n\u0002\u0010\r\n\u0002\b\u0004\n\u0002\u0010\u0002\n\u0000\n\u0002\u0010%\n\u0002\b\u0004\n\u0002\u0018\u0002\n\u0002\u0010\u000b\n\u0002\b\u0004\b\u00c6\u0002\u0018\u00002\u00020\u0001B\u0007\b\u0002\u00a2\u0006\u0002\u0010\u0002J\u0010\u0010\u0007\u001a\u00020\b2\u0006\u0010\t\u001a\u00020\nH\u0002J\u001f\u0010\u000b\u001a\u0014\u0012\u0004\u0012\u00020\u0004\u0012\n\u0012\b\u0012\u0004\u0012\u00020\u000e0\r0\fH\u0000\u00a2\u0006\u0002\b\u000fJ\u0018\u0010\u0010\u001a\u00020\b2\u0006\u0010\u0011\u001a\u00020\u00122\u0006\u0010\u0013\u001a\u00020\bH\u0002J\u0010\u0010\u0014\u001a\u00020\b2\u0006\u0010\u0015\u001a\u00020\u0004H\u0002J2\u0010\u0016\u001a\u00020\u00172\u0018\u0010\u0018\u001a\u0014\u0012\u0004\u0012\u00020\u0004\u0012\n\u0012\b\u0012\u0004\u0012\u00020\u000e0\r0\u00192\u0006\u0010\u001a\u001a\u00020\u00042\u0006\u0010\u001b\u001a\u00020\u000eH\u0002J8\u0010\u0016\u001a\u00020\u00172\u0018\u0010\u0018\u001a\u0014\u0012\u0004\u0012\u00020\u0004\u0012\n\u0012\b\u0012\u0004\u0012\u00020\u000e0\r0\u00192\u0006\u0010\u001a\u001a\u00020\u00042\f\u0010\u001c\u001a\b\u0012\u0004\u0012\u00020\u000e0\rH\u0002J!\u0010\u001d\u001a\u000e\u0012\u0004\u0012\u00020\u001f\u0012\u0004\u0012\u00020\b0\u001e2\u0006\u0010 \u001a\u00020\u0004H\u0000\u00a2\u0006\u0002\b!J.\u0010\"\u001a \u0012\u0004\u0012\u00020\u001f\u0012\u0016\u0012\u0014\u0012\u0004\u0012\u00020\u0004\u0012\n\u0012\b\u0012\u0004\u0012\u00020\u000e0\r0\f0\u001e2\u0006\u0010 \u001a\u00020\u0004H\u0002R\u000e\u0010\u0003\u001a\u00020\u0004X\u0082T\u00a2\u0006\u0002\n\u0000R\u000e\u0010\u0005\u001a\u00020\u0004X\u0082T\u00a2\u0006\u0002\n\u0000R\u000e\u0010\u0006\u001a\u00020\u0004X\u0082T\u00a2\u0006\u0002\n\u0000\u00a8\u0006#"}, d2={"Ldorkbox/netUtil/dnsUtils/ResolveConf;", "", "()V", "DOMAIN_ROW_LABEL", "", "NAMESERVER_ROW_LABEL", "PORT_ROW_LABEL", "getNdots", "", "in", "Ljava/io/InputStream;", "getUnsortedNameServers", "", "", "Ljava/net/InetSocketAddress;", "getUnsortedNameServers$NetworkUtils", "indexOfNonWhiteSpace", "seq", "", "offset", "parseNdots", "token", "putIfAbsent", "", "nameServerDomains", "", "domainName", "nameServer", "nameServers", "tryParseResolvConfNDots", "Lkotlin/Pair;", "", "path", "tryParseResolvConfNDots$NetworkUtils", "tryParseResolvConfNameservers", "NetworkUtils"})
public final class ResolveConf {
    @NotNull
    public static final ResolveConf INSTANCE = new ResolveConf();
    @NotNull
    private static final String NAMESERVER_ROW_LABEL = "nameserver";
    @NotNull
    private static final String DOMAIN_ROW_LABEL = "domain";
    @NotNull
    private static final String PORT_ROW_LABEL = "port";

    private ResolveConf() {
    }

    /*
     * Unable to fully structure code
     */
    @NotNull
    public final Map<String, List<InetSocketAddress>> getUnsortedNameServers$NetworkUtils() {
        block17: {
            block16: {
                nameServerDomains = new LinkedHashMap<K, V>();
                env = new Hashtable<K, V>();
                ((Map)env).put("java.naming.factory.initial", "com.sun.jndi.dns.DnsContextFactory");
                ((Map)env).put("java.naming.provider.url", "dns://");
                try {
                    ctx = new InitialDirContext(env);
                    v0 = ctx.getEnvironment();
                    Intrinsics.checkNotNullExpressionValue(v0, (String)"ctx.environment");
                    var5_5 = v0;
                    dnsUrls = (String)var5_5.get("java.naming.provider.url");
                    if (dnsUrls != null) {
                        var6_8 = dnsUrls;
                        var7_10 = new Regex(" ");
                        var8_13 = 0;
                        var6_8 = var7_10.split((CharSequence)var6_8, var8_13);
                        $i$f$toTypedArray = 0;
                        thisCollection$iv = $this$toTypedArray$iv;
                        v1 = thisCollection$iv.toArray(new String[0]);
                        Intrinsics.checkNotNull((Object)v1, (String)"null cannot be cast to non-null type kotlin.Array<T of kotlin.collections.ArraysKt__ArraysJVMKt.toTypedArray>");
                        for (String server : v1) {
                            try {
                                v2 = new URI(server).getHost();
                                Intrinsics.checkNotNullExpressionValue((Object)v2, (String)"URI(server).host");
                                this.putIfAbsent((Map<String, List<InetSocketAddress>>)nameServerDomains, "", Common.INSTANCE.socketAddress(v2, 53));
                            }
                            catch (URISyntaxException e) {
                                Common.INSTANCE.getLogger$NetworkUtils().debug("Skipping a malformed nameserver URI: {}", (Object)server, (Object)e);
                            }
                        }
                    }
                }
                catch (NamingException ctx) {
                    // empty catch block
                }
                if (!Common.INSTANCE.getOS_WINDOWS()) break block16;
                flags = 39;
                buffer = new Memory(15360L);
                size = new IntByReference(0);
                error = IPHlpAPI.INSTANCE.GetAdaptersAddresses(0, flags, Pointer.NULL, (Pointer)buffer, size);
                if (error == 111) {
                    buffer = new Memory((long)size.getValue());
                    error = IPHlpAPI.INSTANCE.GetAdaptersAddresses(0, flags, Pointer.NULL, (Pointer)buffer, size);
                }
                if (error != 0) break block17;
                result = new IP_ADAPTER_ADDRESSES_LH((Pointer)buffer);
                while (result != null) {
                    block18: {
                        if (result.OperStatus != 1) break block18;
                        dns = result.FirstDnsServerAddress;
                        while (dns != null) {
                            address = null;
                            try {
                                v3 = dns.Address;
                                v4 = address = v3 != null ? v3.toAddress() : null;
                                if (address instanceof Inet4Address) ** GOTO lbl-1000
                                v5 = address;
                                Intrinsics.checkNotNull((Object)v5);
                                if (!v5.isSiteLocalAddress()) lbl-1000:
                                // 2 sources

                                {
                                    this.putIfAbsent((Map<String, List<InetSocketAddress>>)nameServerDomains, "", Common.INSTANCE.socketAddress(address, 53));
                                } else {
                                    Common.INSTANCE.getLogger$NetworkUtils().trace("Skipped site-local IPv6 server address {} on adapter index {}", (Object)address, (Object)result.IfIndex);
                                }
                            }
                            catch (UnknownHostException e) {
                                Common.INSTANCE.getLogger$NetworkUtils().warn("Invalid nameserver address on adapter index {}", (Object)result.IfIndex, (Object)e);
                            }
                            dns = dns.Next;
                        }
                    }
                    result = result.Next;
                }
                break block17;
            }
            tryParse = this.tryParseResolvConfNameservers("/etc/resolv.conf");
            if (!((Boolean)tryParse.getFirst()).booleanValue()) {
                tryParse = this.tryParseResolvConfNameservers("sys:/etc/resolv.cfg");
            }
            if (((Boolean)tryParse.getFirst()).booleanValue()) {
                tryParse.getSecond();
            }
        }
        if (nameServerDomains.get("") == null) {
            this.putIfAbsent((Map<String, List<InetSocketAddress>>)nameServerDomains, "", Common.INSTANCE.socketAddress("1.1.1.1", 53));
            this.putIfAbsent((Map<String, List<InetSocketAddress>>)nameServerDomains, "", Common.INSTANCE.socketAddress("1.1.1.1", 53));
        }
        return nameServerDomains;
    }

    /*
     * WARNING - Removed try catching itself - possible behaviour change.
     */
    private final Pair<Boolean, Map<String, List<InetSocketAddress>>> tryParseResolvConfNameservers(String path) {
        Path p = Paths.get(path, new String[0]);
        if (Files.exists(p, new LinkOption[0])) {
            try {
                Closeable closeable = new FileReader(path);
                Throwable throwable = null;
                try {
                    Pair pair;
                    FileReader fr = (FileReader)closeable;
                    boolean bl = false;
                    Closeable closeable2 = new BufferedReader(fr);
                    Throwable throwable2 = null;
                    try {
                        BufferedReader br = (BufferedReader)closeable2;
                        boolean bl2 = false;
                        List nameServers2 = new ArrayList();
                        Map nameServerDomains = new LinkedHashMap();
                        int port = 53;
                        String domainName = "";
                        String line0 = null;
                        while (true) {
                            int i;
                            char c;
                            String line;
                            String string;
                            String string2;
                            String it = string2 = br.readLine();
                            boolean bl3 = false;
                            String string3 = it;
                            if (string3 != null) {
                                Intrinsics.checkNotNullExpressionValue((Object)string3, (String)"it");
                                string = ((Object)StringsKt.trim((CharSequence)it)).toString();
                            } else {
                                string = line0 = null;
                            }
                            if (string2 == null) break;
                            Intrinsics.checkNotNull((Object)line0);
                            if (((CharSequence)line).length() == 0 || (c = line.charAt(0)) == '#' || c == ';') continue;
                            if (StringsKt.startsWith$default((String)line, (String)NAMESERVER_ROW_LABEL, (boolean)false, (int)2, null)) {
                                String maybeIP;
                                i = INSTANCE.indexOfNonWhiteSpace(line, 10);
                                if (!(i >= 0)) {
                                    boolean $i$a$-require-ResolveConf$tryParseResolvConfNameservers$1$1$62 = false;
                                    String $i$a$-require-ResolveConf$tryParseResolvConfNameservers$1$1$62 = "error parsing label nameserver in file " + path + ". value: " + line;
                                    throw new IllegalArgumentException($i$a$-require-ResolveConf$tryParseResolvConfNameservers$1$1$62.toString());
                                }
                                Intrinsics.checkNotNullExpressionValue((Object)line.substring(i), (String)"this as java.lang.String).substring(startIndex)");
                                if (!IP.INSTANCE.isValid(maybeIP)) {
                                    i = StringsKt.lastIndexOf$default((CharSequence)maybeIP, (char)'.', (int)0, (boolean)false, (int)6, null);
                                    if (!(i + 1 >= maybeIP.length())) {
                                        boolean bl4 = false;
                                        String string4 = "error parsing label nameserver in file " + path + ". invalid IP value: " + line;
                                        throw new IllegalArgumentException(string4.toString());
                                    }
                                    String string5 = maybeIP.substring(i + 1);
                                    Intrinsics.checkNotNullExpressionValue((Object)string5, (String)"this as java.lang.String).substring(startIndex)");
                                    port = Integer.parseInt(string5);
                                    String string6 = maybeIP.substring(0, i);
                                    Intrinsics.checkNotNullExpressionValue((Object)string6, (String)"this as java.lang.String\u2026ing(startIndex, endIndex)");
                                    maybeIP = string6;
                                }
                                nameServers2.add(Common.INSTANCE.socketAddress(maybeIP, port));
                                continue;
                            }
                            if (StringsKt.startsWith$default((String)line, (String)DOMAIN_ROW_LABEL, (boolean)false, (int)2, null)) {
                                i = INSTANCE.indexOfNonWhiteSpace(line, 6);
                                if (!(i >= 0)) {
                                    boolean $i$a$-require-ResolveConf$tryParseResolvConfNameservers$1$1$72 = false;
                                    String $i$a$-require-ResolveConf$tryParseResolvConfNameservers$1$1$72 = "error parsing label domain in file " + path + " value: " + line;
                                    throw new IllegalArgumentException($i$a$-require-ResolveConf$tryParseResolvConfNameservers$1$1$72.toString());
                                }
                                INSTANCE.putIfAbsent((Map<String, List<InetSocketAddress>>)nameServerDomains, domainName, nameServers2);
                                nameServers2 = new ArrayList();
                                Intrinsics.checkNotNullExpressionValue((Object)line.substring(i), (String)"this as java.lang.String).substring(startIndex)");
                                continue;
                            }
                            if (!StringsKt.startsWith$default((String)line, (String)PORT_ROW_LABEL, (boolean)false, (int)2, null)) continue;
                            i = INSTANCE.indexOfNonWhiteSpace(line, 4);
                            if (!(i >= 0)) {
                                boolean bl5 = false;
                                String string7 = "error parsing label port in file " + path + " value: " + line;
                                throw new IllegalArgumentException(string7.toString());
                            }
                            String string8 = line.substring(i);
                            Intrinsics.checkNotNullExpressionValue((Object)string8, (String)"this as java.lang.String).substring(startIndex)");
                            port = Integer.parseInt(string8);
                        }
                        INSTANCE.putIfAbsent((Map<String, List<InetSocketAddress>>)nameServerDomains, domainName, nameServers2);
                        pair = new Pair((Object)true, (Object)nameServerDomains);
                    }
                    catch (Throwable throwable3) {
                        try {
                            try {
                                throwable2 = throwable3;
                                throw throwable3;
                            }
                            catch (Throwable throwable4) {
                                CloseableKt.closeFinally((Closeable)closeable2, throwable2);
                                throw throwable4;
                            }
                        }
                        catch (Throwable throwable5) {
                            throwable = throwable5;
                            throw throwable5;
                        }
                    }
                    CloseableKt.closeFinally((Closeable)closeable2, (Throwable)throwable2);
                    Pair pair2 = pair;
                    return pair2;
                }
                finally {
                    CloseableKt.closeFinally((Closeable)closeable, (Throwable)throwable);
                }
            }
            catch (IOException e) {
                Common.INSTANCE.getLogger$NetworkUtils().error("Error parsing " + path, (Throwable)e);
            }
        }
        return new Pair((Object)false, (Object)new LinkedHashMap());
    }

    private final int indexOfNonWhiteSpace(CharSequence seq, int offset) {
        for (int o = offset; o < seq.length(); ++o) {
            if (Character.isWhitespace(seq.charAt(o))) continue;
            return o;
        }
        return -1;
    }

    private final void putIfAbsent(Map<String, List<InetSocketAddress>> nameServerDomains, String domainName, InetSocketAddress nameServer) {
        List list = nameServerDomains.get(domainName);
        if (list == null) {
            list = new ArrayList();
            nameServerDomains.put(domainName, list);
        }
        TypeIntrinsics.asMutableList(list);
        if (!list.contains(nameServer)) {
            list.add(nameServer);
        }
    }

    private final void putIfAbsent(Map<String, List<InetSocketAddress>> nameServerDomains, String domainName, List<? extends InetSocketAddress> nameServers2) {
        List list = null;
        list = nameServerDomains.get(domainName);
        if (list == null) {
            list = new ArrayList();
            nameServerDomains.put(domainName, list);
        }
        TypeIntrinsics.asMutableList(list);
        Iterable $this$forEach$iv = nameServers2;
        boolean $i$f$forEach = false;
        for (Object element$iv : $this$forEach$iv) {
            InetSocketAddress it = (InetSocketAddress)element$iv;
            boolean bl = false;
            if (list.contains(it)) continue;
            list.add(it);
        }
    }

    /*
     * WARNING - Removed try catching itself - possible behaviour change.
     */
    @NotNull
    public final Pair<Boolean, Integer> tryParseResolvConfNDots$NetworkUtils(@NotNull String path) {
        Intrinsics.checkNotNullParameter((Object)path, (String)"path");
        Path p = Paths.get(path, new String[0]);
        if (Files.exists(p, new LinkOption[0])) {
            try {
                Closeable closeable = Files.newInputStream(p, new OpenOption[0]);
                Throwable throwable = null;
                try {
                    InputStream in = (InputStream)closeable;
                    boolean bl = false;
                    Boolean bl2 = true;
                    Intrinsics.checkNotNullExpressionValue((Object)in, (String)"`in`");
                    Pair pair = new Pair((Object)bl2, (Object)INSTANCE.getNdots(in));
                    return pair;
                }
                catch (Throwable throwable2) {
                    throwable = throwable2;
                    throw throwable2;
                }
                finally {
                    CloseableKt.closeFinally((Closeable)closeable, (Throwable)throwable);
                }
            }
            catch (IOException iOException) {
                // empty catch block
            }
        }
        return new Pair((Object)false, (Object)1);
    }

    /*
     * WARNING - Removed try catching itself - possible behaviour change.
     */
    private final int getNdots(InputStream in) {
        int ndots = 0;
        ndots = 1;
        Closeable closeable = new InputStreamReader(in);
        Throwable throwable = null;
        try {
            InputStreamReader isr = (InputStreamReader)closeable;
            boolean bl = false;
            Closeable closeable2 = new BufferedReader(isr);
            Throwable throwable2 = null;
            try {
                BufferedReader br = (BufferedReader)closeable2;
                boolean bl2 = false;
                String line = null;
                block20: while (true) {
                    String string;
                    String string2;
                    String it = string2 = br.readLine();
                    boolean bl3 = false;
                    line = it;
                    if (string2 == null) break;
                    StringTokenizer st = new StringTokenizer(line);
                    if (!st.hasMoreTokens() || (string = st.nextToken()) == null) continue;
                    int n = -1;
                    switch (string.hashCode()) {
                        case -906336856: {
                            if (string.equals("search")) {
                                n = 1;
                            }
                            break;
                        }
                        case -1326197564: {
                            if (string.equals(DOMAIN_ROW_LABEL)) {
                                n = 2;
                            }
                            break;
                        }
                        case -1249474914: {
                            if (string.equals("options")) {
                                n = 3;
                            }
                            break;
                        }
                    }
                    switch (n) {
                        case 2: {
                            if (st.hasMoreTokens()) continue block20;
                            continue block20;
                        }
                        case 1: {
                            while (true) {
                                if (!st.hasMoreTokens()) continue block20;
                                String token = st.nextToken();
                                Intrinsics.checkNotNullExpressionValue((Object)token, (String)"token");
                                if (!StringsKt.startsWith$default((String)token, (String)"ndots:", (boolean)false, (int)2, null)) continue;
                                String string3 = token.substring(6);
                                Intrinsics.checkNotNullExpressionValue((Object)string3, (String)"this as java.lang.String).substring(startIndex)");
                                ndots = INSTANCE.parseNdots(string3);
                            }
                        }
                        case 3: {
                            while (true) {
                                if (!st.hasMoreTokens()) continue block20;
                                String token = st.nextToken();
                                Intrinsics.checkNotNullExpressionValue((Object)token, (String)"token");
                                if (!StringsKt.startsWith$default((String)token, (String)"ndots:", (boolean)false, (int)2, null)) continue;
                                String string4 = token.substring(6);
                                Intrinsics.checkNotNullExpressionValue((Object)string4, (String)"this as java.lang.String).substring(startIndex)");
                                ndots = INSTANCE.parseNdots(string4);
                            }
                        }
                    }
                }
                Unit unit = Unit.INSTANCE;
            }
            catch (Throwable throwable3) {
                throwable2 = throwable3;
                throw throwable3;
            }
            finally {
                CloseableKt.closeFinally((Closeable)closeable2, (Throwable)throwable2);
            }
            isr = Unit.INSTANCE;
        }
        catch (Throwable isr) {
            throwable = isr;
            throw isr;
        }
        finally {
            CloseableKt.closeFinally((Closeable)closeable, (Throwable)throwable);
        }
        String resOptions = System.getenv("RES_OPTIONS");
        if (resOptions != null && !(((CharSequence)resOptions).length() == 0)) {
            StringTokenizer st = new StringTokenizer(resOptions, " ");
            while (st.hasMoreTokens()) {
                String token = st.nextToken();
                Intrinsics.checkNotNullExpressionValue((Object)token, (String)"token");
                if (!StringsKt.startsWith$default((String)token, (String)"ndots:", (boolean)false, (int)2, null)) continue;
                String string = token.substring(6);
                Intrinsics.checkNotNullExpressionValue((Object)string, (String)"this as java.lang.String).substring(startIndex)");
                ndots = this.parseNdots(string);
            }
        }
        return ndots;
    }

    private final int parseNdots(String token) {
        if (((CharSequence)token).length() > 0) {
            try {
                int ndots = Integer.parseInt(token);
                if (ndots >= 0) {
                    if (ndots > 15) {
                        ndots = 15;
                    }
                    return ndots;
                }
            }
            catch (NumberFormatException numberFormatException) {
                // empty catch block
            }
        }
        return 1;
    }
}

