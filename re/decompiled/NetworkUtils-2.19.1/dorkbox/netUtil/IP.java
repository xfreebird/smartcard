/*
 * Decompiled with CFR 0.152.
 * 
 * Could not load the following classes:
 *  kotlin.Metadata
 *  kotlin.Result
 *  kotlin.ResultKt
 *  kotlin.collections.CollectionsKt
 *  kotlin.io.CloseableKt
 *  kotlin.jvm.internal.Intrinsics
 *  org.jetbrains.annotations.NotNull
 *  org.jetbrains.annotations.Nullable
 *  org.slf4j.Logger
 */
package dorkbox.netUtil;

import dorkbox.netUtil.Common;
import dorkbox.netUtil.IPv4;
import dorkbox.netUtil.IPv6;
import dorkbox.netUtil.SocketUtils;
import java.io.BufferedReader;
import java.io.Closeable;
import java.io.InputStreamReader;
import java.net.Inet4Address;
import java.net.Inet6Address;
import java.net.InetAddress;
import java.net.InetSocketAddress;
import java.net.NetworkInterface;
import java.net.Socket;
import java.net.SocketException;
import java.net.URL;
import java.net.UnknownHostException;
import java.util.ArrayList;
import java.util.Collection;
import java.util.Enumeration;
import java.util.List;
import java.util.regex.Matcher;
import java.util.regex.Pattern;
import kotlin.Metadata;
import kotlin.Result;
import kotlin.ResultKt;
import kotlin.collections.CollectionsKt;
import kotlin.io.CloseableKt;
import kotlin.jvm.internal.Intrinsics;
import org.jetbrains.annotations.NotNull;
import org.jetbrains.annotations.Nullable;
import org.slf4j.Logger;

@Metadata(mv={1, 7, 1}, k=1, xi=48, d1={"\u0000N\n\u0002\u0018\u0002\n\u0002\u0010\u0000\n\u0002\b\u0002\n\u0002\u0018\u0002\n\u0002\b\u0003\n\u0002\u0018\u0002\n\u0002\b\u0003\n\u0002\u0010\u000e\n\u0000\n\u0002\u0010\u000b\n\u0002\b\u0003\n\u0002\u0018\u0002\n\u0002\u0018\u0002\n\u0002\b\u0006\n\u0002\u0010\u0012\n\u0002\b\u0004\n\u0002\u0018\u0002\n\u0002\b\u0002\n\u0002\u0010\b\n\u0002\b\u0005\b\u00c6\u0002\u0018\u00002\u00020\u0001B\u0007\b\u0002\u00a2\u0006\u0002\u0010\u0002J\u000e\u0010\r\u001a\u00020\u000e2\u0006\u0010\u000f\u001a\u00020\fJ\u0006\u0010\u0010\u001a\u00020\u0004J$\u0010\u0011\u001a\u00060\u0012j\u0002`\u00132\u0006\u0010\u0014\u001a\u00020\f2\u0006\u0010\u0015\u001a\u00020\f2\u0006\u0010\u0016\u001a\u00020\u000eH\u0002J\b\u0010\u0017\u001a\u0004\u0018\u00010\fJ\u0010\u0010\u0018\u001a\u0004\u0018\u00010\u00042\u0006\u0010\u000f\u001a\u00020\fJ\u000e\u0010\u0019\u001a\u00020\u001a2\u0006\u0010\u001b\u001a\u00020\fJ\u0018\u0010\u001c\u001a\u00020\f2\u0006\u0010\u000f\u001a\u00020\u00042\b\b\u0002\u0010\u001d\u001a\u00020\u000eJ\u000e\u0010\u001c\u001a\u00020\f2\u0006\u0010\u001e\u001a\u00020\u001fJ\"\u0010\u001c\u001a\u00020\f2\u0006\u0010 \u001a\u00020\u001a2\b\b\u0002\u0010!\u001a\u00020\"2\b\b\u0002\u0010#\u001a\u00020\"J\u0016\u0010\u001c\u001a\u00020\f2\u0006\u0010\u0014\u001a\u00020\f2\u0006\u0010\u0015\u001a\u00020\"J\u0018\u0010$\u001a\u0004\u0018\u00010\u00042\u0006\u0010%\u001a\u00020\u00042\u0006\u0010&\u001a\u00020\"R\u0011\u0010\u0003\u001a\u00020\u0004\u00a2\u0006\b\n\u0000\u001a\u0004\b\u0005\u0010\u0006R\u0011\u0010\u0007\u001a\u00020\b\u00a2\u0006\b\n\u0000\u001a\u0004\b\t\u0010\nR\u000e\u0010\u000b\u001a\u00020\fX\u0086T\u00a2\u0006\u0002\n\u0000\u00a8\u0006'"}, d2={"Ldorkbox/netUtil/IP;", "", "()V", "LOCALHOST", "Ljava/net/InetAddress;", "getLOCALHOST", "()Ljava/net/InetAddress;", "LOOPBACK_IF", "Ljava/net/NetworkInterface;", "getLOOPBACK_IF", "()Ljava/net/NetworkInterface;", "version", "", "isValid", "", "ip", "lanAddress", "newSocketAddressStringBuilder", "Ljava/lang/StringBuilder;", "Lkotlin/text/StringBuilder;", "host", "port", "ipv4", "publicIpViaHttp", "toAddress", "toBytes", "", "ipAddressString", "toString", "ipv4Mapped", "addr", "Ljava/net/InetSocketAddress;", "bytes", "offset", "", "length", "truncate", "address", "maskLength", "NetworkUtils"})
public final class IP {
    @NotNull
    public static final IP INSTANCE;
    @NotNull
    public static final String version = "2.19.1";
    @NotNull
    private static final InetAddress LOCALHOST;
    @NotNull
    private static final NetworkInterface LOOPBACK_IF;

    private IP() {
    }

    @NotNull
    public final InetAddress getLOCALHOST() {
        return LOCALHOST;
    }

    @NotNull
    public final NetworkInterface getLOOPBACK_IF() {
        return LOOPBACK_IF;
    }

    /*
     * WARNING - Removed try catching itself - possible behaviour change.
     * WARNING - void declaration
     */
    @NotNull
    public final InetAddress lanAddress() {
        Object $this$lanAddress_u24lambda_u241;
        Object inetAddr;
        Object ifaces2;
        List likelyAddress = new ArrayList();
        List candidates = new ArrayList();
        try {
            ifaces2 = NetworkInterface.getNetworkInterfaces();
            while (ifaces2.hasMoreElements()) {
                NetworkInterface iface = ifaces2.nextElement();
                Enumeration<InetAddress> inetAddrs = iface.getInetAddresses();
                while (inetAddrs.hasMoreElements()) {
                    inetAddr = inetAddrs.nextElement();
                    if (((InetAddress)inetAddr).isLoopbackAddress()) continue;
                    if (((InetAddress)inetAddr).isSiteLocalAddress()) {
                        Intrinsics.checkNotNullExpressionValue((Object)inetAddr, (String)"inetAddr");
                        likelyAddress.add(inetAddr);
                        continue;
                    }
                    Intrinsics.checkNotNullExpressionValue((Object)inetAddr, (String)"inetAddr");
                    candidates.add(inetAddr);
                }
            }
        }
        catch (Exception ifaces2) {
            // empty catch block
        }
        if (likelyAddress.size() == 1) {
            return (InetAddress)CollectionsKt.first((List)likelyAddress);
        }
        ifaces2 = this;
        try {
            $this$lanAddress_u24lambda_u241 = (IP)ifaces2;
            boolean bl = false;
            inetAddr = new Socket();
            Throwable throwable = null;
            try {
                Socket it = (Socket)inetAddr;
                boolean bl2 = false;
                it.connect(new InetSocketAddress("1.1.1.1", 80));
                InetAddress inetAddress = it.getLocalAddress();
                Intrinsics.checkNotNullExpressionValue((Object)inetAddress, (String)"it.localAddress");
                InetAddress inetAddress2 = inetAddress;
                return inetAddress2;
            }
            catch (Throwable it) {
                throwable = it;
                throw it;
            }
            finally {
                CloseableKt.closeFinally((Closeable)inetAddr, (Throwable)throwable);
            }
        }
        catch (Throwable bl) {
            InetAddress inetAddress;
            List ipv4;
            List ipv6;
            boolean $i$f$filterIsInstanceTo;
            Collection destination$iv$iv;
            Iterable $this$filterIsInstance$iv;
            ifaces2 = Result.constructor-impl((Object)ResultKt.createFailure((Throwable)bl));
            Throwable throwable = Result.exceptionOrNull-impl((Object)ifaces2);
            if (throwable != null) {
                Object it = $this$lanAddress_u24lambda_u241 = throwable;
                boolean bl3 = false;
                Common.INSTANCE.getLogger$NetworkUtils().error("Unable to determine outbound traffic local address. Using alternate logic instead.", (Throwable)it);
            }
            if (IPv6.INSTANCE.isPreferred()) {
                void $this$filterIsInstanceTo$iv$iv;
                $this$filterIsInstance$iv = likelyAddress;
                boolean $i$f$filterIsInstance = false;
                Iterable bl3 = $this$filterIsInstance$iv;
                destination$iv$iv = new ArrayList();
                $i$f$filterIsInstanceTo = false;
                for (Object element$iv$iv : $this$filterIsInstanceTo$iv$iv) {
                    if (!(element$iv$iv instanceof Inet6Address)) continue;
                    destination$iv$iv.add(element$iv$iv);
                }
                ipv6 = (List)destination$iv$iv;
                if (!((Collection)ipv6).isEmpty()) {
                    return (InetAddress)CollectionsKt.first((List)ipv6);
                }
            } else if (IPv4.INSTANCE.isPreferred()) {
                $this$filterIsInstance$iv = likelyAddress;
                boolean $i$f$filterIsInstance = false;
                Iterable $this$filterIsInstanceTo$iv$iv = $this$filterIsInstance$iv;
                destination$iv$iv = new ArrayList();
                $i$f$filterIsInstanceTo = false;
                for (Object element$iv$iv : $this$filterIsInstanceTo$iv$iv) {
                    if (!(element$iv$iv instanceof Inet4Address)) continue;
                    destination$iv$iv.add(element$iv$iv);
                }
                ipv4 = (List)destination$iv$iv;
                if (!((Collection)ipv4).isEmpty()) {
                    return (InetAddress)CollectionsKt.first((List)ipv4);
                }
            }
            if (IPv6.INSTANCE.isPreferred()) {
                $this$filterIsInstance$iv = candidates;
                boolean $i$f$filterIsInstance = false;
                Iterable $this$filterIsInstanceTo$iv$iv = $this$filterIsInstance$iv;
                destination$iv$iv = new ArrayList();
                $i$f$filterIsInstanceTo = false;
                for (Object element$iv$iv : $this$filterIsInstanceTo$iv$iv) {
                    if (!(element$iv$iv instanceof Inet6Address)) continue;
                    destination$iv$iv.add(element$iv$iv);
                }
                ipv6 = (List)destination$iv$iv;
                if (!((Collection)ipv6).isEmpty()) {
                    return (InetAddress)CollectionsKt.first((List)ipv6);
                }
            } else if (IPv4.INSTANCE.isPreferred()) {
                $this$filterIsInstance$iv = candidates;
                boolean $i$f$filterIsInstance = false;
                Iterable $this$filterIsInstanceTo$iv$iv = $this$filterIsInstance$iv;
                destination$iv$iv = new ArrayList();
                $i$f$filterIsInstanceTo = false;
                for (Object element$iv$iv : $this$filterIsInstanceTo$iv$iv) {
                    if (!(element$iv$iv instanceof Inet4Address)) continue;
                    destination$iv$iv.add(element$iv$iv);
                }
                ipv4 = (List)destination$iv$iv;
                if (!((Collection)ipv4).isEmpty()) {
                    return (InetAddress)CollectionsKt.first((List)ipv4);
                }
            }
            if ((inetAddress = InetAddress.getLocalHost()) == null) {
                throw new UnknownHostException("The JDK InetAddress.getLocalHost() method unexpectedly returned null.");
            }
            return inetAddress;
        }
    }

    /*
     * WARNING - void declaration
     */
    @Nullable
    public final String publicIpViaHttp() {
        String[] stringArray = new String[]{"http://ip.dorkbox.com/", "http://checkip.dyndns.com/", "http://checkip.dyn.com/", "http://curlmyip.com/", "http://ipecho.net/plain", "http://icanhazip.com/"};
        String[] websites = stringArray;
        int n = websites.length;
        for (int i = 0; i < n; ++i) {
            try {
                void $this$trim$iv;
                void $this$trim$iv2;
                URL autoIP = new URL(websites[i]);
                BufferedReader in = new BufferedReader(new InputStreamReader(autoIP.openStream()));
                Intrinsics.checkNotNullExpressionValue((Object)in.readLine(), (String)"`in`.readLine()");
                boolean $i$f$trim = false;
                CharSequence $this$trim$iv$iv = (CharSequence)$this$trim$iv2;
                boolean $i$f$trim2 = false;
                int startIndex$iv$iv = 0;
                int endIndex$iv$iv = $this$trim$iv$iv.length() - 1;
                boolean startFound$iv$iv = false;
                while (startIndex$iv$iv <= endIndex$iv$iv) {
                    boolean match$iv$iv;
                    int index$iv$iv = !startFound$iv$iv ? startIndex$iv$iv : endIndex$iv$iv;
                    char it = $this$trim$iv$iv.charAt(index$iv$iv);
                    boolean bl = false;
                    boolean bl2 = match$iv$iv = Intrinsics.compare((int)it, (int)32) <= 0;
                    if (!startFound$iv$iv) {
                        if (!match$iv$iv) {
                            startFound$iv$iv = true;
                            continue;
                        }
                        ++startIndex$iv$iv;
                        continue;
                    }
                    if (!match$iv$iv) break;
                    --endIndex$iv$iv;
                }
                String response = ((Object)$this$trim$iv$iv.subSequence(startIndex$iv$iv, endIndex$iv$iv + 1)).toString();
                in.close();
                Pattern pattern = Pattern.compile("\\b\\d{1,3}\\.\\d{1,3}\\.\\d{1,3}\\.\\d{1,3}\\b");
                Matcher matcher = pattern.matcher(response);
                if (!matcher.find()) continue;
                String string = matcher.group();
                Intrinsics.checkNotNullExpressionValue((Object)string, (String)"matcher.group()");
                $this$trim$iv$iv = string;
                $i$f$trim2 = false;
                CharSequence $this$trim$iv$iv2 = (CharSequence)$this$trim$iv;
                boolean $i$f$trim3 = false;
                int startIndex$iv$iv2 = 0;
                int endIndex$iv$iv2 = $this$trim$iv$iv2.length() - 1;
                boolean startFound$iv$iv2 = false;
                while (startIndex$iv$iv2 <= endIndex$iv$iv2) {
                    boolean match$iv$iv;
                    int index$iv$iv = !startFound$iv$iv2 ? startIndex$iv$iv2 : endIndex$iv$iv2;
                    char it = $this$trim$iv$iv2.charAt(index$iv$iv);
                    boolean bl = false;
                    boolean bl3 = match$iv$iv = Intrinsics.compare((int)it, (int)32) <= 0;
                    if (!startFound$iv$iv2) {
                        if (!match$iv$iv) {
                            startFound$iv$iv2 = true;
                            continue;
                        }
                        ++startIndex$iv$iv2;
                        continue;
                    }
                    if (!match$iv$iv) break;
                    --endIndex$iv$iv2;
                }
                return ((Object)$this$trim$iv$iv2.subSequence(startIndex$iv$iv2, endIndex$iv$iv2 + 1)).toString();
            }
            catch (Exception exception) {
                // empty catch block
            }
        }
        return null;
    }

    @NotNull
    public final byte[] toBytes(@NotNull String ipAddressString) {
        Intrinsics.checkNotNullParameter((Object)ipAddressString, (String)"ipAddressString");
        if (IPv4.INSTANCE.isValid(ipAddressString)) {
            return IPv4.INSTANCE.toBytes(ipAddressString);
        }
        return IPv6.INSTANCE.toBytes(ipAddressString);
    }

    @NotNull
    public final String toString(@NotNull byte[] bytes, int offset, int length) {
        String string;
        Intrinsics.checkNotNullParameter((Object)bytes, (String)"bytes");
        switch (length) {
            case 4: {
                String string2 = new StringBuilder(15).append(bytes[offset]).append('.').append(bytes[offset + 1]).append('.').append(bytes[offset + 2]).append('.').append(bytes[offset + 3]).toString();
                string = string2;
                Intrinsics.checkNotNullExpressionValue((Object)string2, (String)"{\n                String\u2026.toString()\n            }");
                break;
            }
            case 16: {
                string = IPv6.INSTANCE.toString(bytes, offset);
                break;
            }
            default: {
                throw new IllegalArgumentException("length: " + length + " (expected: 4 or 16)");
            }
        }
        return string;
    }

    public static /* synthetic */ String toString$default(IP iP, byte[] byArray, int n, int n2, int n3, Object object) {
        if ((n3 & 2) != 0) {
            n = 0;
        }
        if ((n3 & 4) != 0) {
            n2 = byArray.length;
        }
        return iP.toString(byArray, n, n2);
    }

    @NotNull
    public final String toString(@NotNull InetAddress ip, boolean ipv4Mapped) {
        Intrinsics.checkNotNullParameter((Object)ip, (String)"ip");
        if (ip instanceof Inet4Address) {
            return IPv4.INSTANCE.toString((Inet4Address)ip);
        }
        if (!(ip instanceof Inet6Address)) {
            boolean bl = false;
            String string = "Unhandled type: " + ip;
            throw new IllegalArgumentException(string.toString());
        }
        return IPv6.INSTANCE.toString((Inet6Address)ip, ipv4Mapped);
    }

    public static /* synthetic */ String toString$default(IP iP, InetAddress inetAddress, boolean bl, int n, Object object) {
        if ((n & 2) != 0) {
            bl = false;
        }
        return iP.toString(inetAddress, bl);
    }

    @NotNull
    public final String toString(@NotNull InetSocketAddress addr) {
        StringBuilder stringBuilder;
        Intrinsics.checkNotNullParameter((Object)addr, (String)"addr");
        String port = String.valueOf(addr.getPort());
        StringBuilder sb = null;
        if (addr.isUnresolved()) {
            String hostname = addr.getHostString();
            Intrinsics.checkNotNullExpressionValue((Object)hostname, (String)"hostname");
            stringBuilder = this.newSocketAddressStringBuilder(hostname, port, !IPv6.INSTANCE.isValid(hostname));
        } else {
            InetAddress address = addr.getAddress();
            Intrinsics.checkNotNullExpressionValue((Object)address, (String)"address");
            String hostString = IP.toString$default(this, address, false, 2, null);
            stringBuilder = this.newSocketAddressStringBuilder(hostString, port, address instanceof Inet4Address);
        }
        sb = stringBuilder;
        String string = sb.append(':').append(port).toString();
        Intrinsics.checkNotNullExpressionValue((Object)string, (String)"sb.append(':').append(port).toString()");
        return string;
    }

    @NotNull
    public final String toString(@NotNull String host, int port) {
        Intrinsics.checkNotNullParameter((Object)host, (String)"host");
        String portStr = String.valueOf(port);
        String string = this.newSocketAddressStringBuilder(host, portStr, !IPv6.INSTANCE.isValid(host)).append(':').append(portStr).toString();
        Intrinsics.checkNotNullExpressionValue((Object)string, (String)"newSocketAddressStringBu\u2026ppend(portStr).toString()");
        return string;
    }

    private final StringBuilder newSocketAddressStringBuilder(String host, String port, boolean ipv4) {
        StringBuilder stringBuilder;
        int hostLen = host.length();
        if (ipv4) {
            StringBuilder stringBuilder2 = new StringBuilder(hostLen + 1 + port.length()).append(host);
            Intrinsics.checkNotNullExpressionValue((Object)stringBuilder2, (String)"StringBuilder(hostLen + \u2026port.length).append(host)");
            return stringBuilder2;
        }
        StringBuilder stringBuilder3 = new StringBuilder(hostLen + 3 + port.length());
        if (hostLen > 1 && host.charAt(0) == '[' && host.charAt(hostLen - 1) == ']') {
            StringBuilder stringBuilder4 = stringBuilder3.append(host);
            stringBuilder = stringBuilder4;
            Intrinsics.checkNotNullExpressionValue((Object)stringBuilder4, (String)"{\n            stringBuilder.append(host)\n        }");
        } else {
            StringBuilder stringBuilder5 = stringBuilder3.append('[').append(host).append(']');
            stringBuilder = stringBuilder5;
            Intrinsics.checkNotNullExpressionValue((Object)stringBuilder5, (String)"{\n            stringBuil\u2026st).append(']')\n        }");
        }
        return stringBuilder;
    }

    @Nullable
    public final InetAddress toAddress(@NotNull String ip) {
        Intrinsics.checkNotNullParameter((Object)ip, (String)"ip");
        return IPv4.INSTANCE.isValid(ip) ? (InetAddress)IPv4.INSTANCE.toAddressUnsafe(ip) : (InetAddress)IPv6.INSTANCE.toAddress(ip);
    }

    @Nullable
    public final InetAddress truncate(@NotNull InetAddress address, int maskLength) {
        Intrinsics.checkNotNullParameter((Object)address, (String)"address");
        return address instanceof Inet4Address ? IPv4.INSTANCE.truncate((Inet4Address)address, maskLength) : IPv6.INSTANCE.truncate((Inet6Address)address, maskLength);
    }

    public final boolean isValid(@NotNull String ip) {
        Intrinsics.checkNotNullParameter((Object)ip, (String)"ip");
        return IPv4.INSTANCE.isValid(ip) || IPv6.INSTANCE.isValid(ip);
    }

    static {
        Enumeration<InetAddress> i;
        INSTANCE = new IP();
        Common.INSTANCE.getLogger$NetworkUtils().trace("-Djava.net.preferIPv4Stack: " + IPv4.INSTANCE.isPreferred());
        Common.INSTANCE.getLogger$NetworkUtils().trace("-Djava.net.preferIPv6Addresses: " + IPv6.INSTANCE.isPreferred());
        List netInterfaces = new ArrayList();
        try {
            Enumeration<NetworkInterface> interfaces = NetworkInterface.getNetworkInterfaces();
            if (interfaces != null) {
                while (interfaces.hasMoreElements()) {
                    NetworkInterface iface;
                    Intrinsics.checkNotNullExpressionValue((Object)interfaces.nextElement(), (String)"interfaces.nextElement()");
                    if (!SocketUtils.INSTANCE.addressesFromNetworkInterface(iface).hasMoreElements()) continue;
                    netInterfaces.add(iface);
                }
            }
        }
        catch (SocketException e) {
            Common.INSTANCE.getLogger$NetworkUtils().warn("Failed to retrieve the list of available network interfaces", (Throwable)e);
        }
        NetworkInterface loopbackIface = null;
        InetAddress loopbackAddr = null;
        block7: for (NetworkInterface iface : netInterfaces) {
            i = SocketUtils.INSTANCE.addressesFromNetworkInterface(iface);
            while (i.hasMoreElements()) {
                InetAddress addr;
                Intrinsics.checkNotNullExpressionValue((Object)i.nextElement(), (String)"i.nextElement()");
                if (!addr.isLoopbackAddress()) continue;
                loopbackIface = iface;
                loopbackAddr = addr;
                break block7;
            }
        }
        if (loopbackIface == null) {
            try {
                for (NetworkInterface iface : netInterfaces) {
                    if (!iface.isLoopback() || !(i = SocketUtils.INSTANCE.addressesFromNetworkInterface(iface)).hasMoreElements()) continue;
                    loopbackIface = iface;
                    loopbackAddr = i.nextElement();
                    break;
                }
                if (loopbackIface == null) {
                    Common.INSTANCE.getLogger$NetworkUtils().warn("Failed to find the loopback interface");
                }
            }
            catch (SocketException e) {
                Common.INSTANCE.getLogger$NetworkUtils().warn("Failed to find the loopback interface", (Throwable)e);
            }
        }
        if (loopbackIface != null) {
            Logger logger = Common.INSTANCE.getLogger$NetworkUtils();
            StringBuilder stringBuilder = new StringBuilder().append("Loopback interface: ").append(loopbackIface.getName()).append(" (").append(loopbackIface.getDisplayName()).append(", ");
            InetAddress inetAddress = loopbackAddr;
            Intrinsics.checkNotNull(inetAddress);
            logger.trace(stringBuilder.append(inetAddress.getHostAddress()).append(')').toString());
        } else if (loopbackAddr == null) {
            try {
                if (NetworkInterface.getByInetAddress(IPv6.INSTANCE.getLOCALHOST()) != null) {
                    Common.INSTANCE.getLogger$NetworkUtils().debug("Using hard-coded IPv6 localhost address: " + IPv6.INSTANCE.getLOCALHOST());
                    loopbackAddr = IPv6.INSTANCE.getLOCALHOST();
                }
            }
            catch (Exception exception) {
                // empty catch block
            }
            if (loopbackAddr == null) {
                Common.INSTANCE.getLogger$NetworkUtils().debug("Using hard-coded IPv4 localhost address: " + IPv4.INSTANCE.getLOCALHOST());
                loopbackAddr = IPv4.INSTANCE.getLOCALHOST();
            }
        }
        NetworkInterface networkInterface = loopbackIface;
        Intrinsics.checkNotNull(networkInterface);
        LOOPBACK_IF = networkInterface;
        LOCALHOST = loopbackAddr;
    }
}

