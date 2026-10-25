/*
 * Decompiled with CFR 0.152.
 * 
 * Could not load the following classes:
 *  kotlin.Metadata
 *  kotlin.collections.CollectionsKt
 *  kotlin.jvm.internal.Intrinsics
 *  org.jetbrains.annotations.NotNull
 *  org.jetbrains.annotations.Nullable
 */
package dorkbox.netUtil;

import java.io.IOException;
import java.net.InetAddress;
import java.net.InetSocketAddress;
import java.net.NetworkInterface;
import java.net.ServerSocket;
import java.net.Socket;
import java.net.SocketAddress;
import java.net.SocketException;
import java.net.UnknownHostException;
import java.nio.channels.DatagramChannel;
import java.nio.channels.ServerSocketChannel;
import java.nio.channels.SocketChannel;
import java.security.AccessController;
import java.security.PrivilegedActionException;
import java.util.Collections;
import java.util.Enumeration;
import kotlin.Metadata;
import kotlin.collections.CollectionsKt;
import kotlin.jvm.internal.Intrinsics;
import org.jetbrains.annotations.NotNull;
import org.jetbrains.annotations.Nullable;

@Metadata(mv={1, 7, 1}, k=1, xi=48, d1={"\u0000x\n\u0002\u0018\u0002\n\u0002\u0010\u0000\n\u0002\b\u0002\n\u0002\u0018\u0002\n\u0002\b\u0002\n\u0002\u0010\u000e\n\u0000\n\u0002\u0018\u0002\n\u0000\n\u0002\u0018\u0002\n\u0000\n\u0002\u0018\u0002\n\u0002\b\u0003\n\u0002\u0018\u0002\n\u0000\n\u0002\u0010\u0011\n\u0002\b\u0002\n\u0002\u0010\u0002\n\u0000\n\u0002\u0018\u0002\n\u0000\n\u0002\u0018\u0002\n\u0000\n\u0002\u0018\u0002\n\u0002\b\u0005\n\u0002\u0010\b\n\u0002\u0010\u000b\n\u0002\b\u0003\n\u0002\u0010\u0012\n\u0000\n\u0002\u0018\u0002\n\u0002\b\u0002\n\u0002\u0018\u0002\n\u0002\b\u0002\b\u00c6\u0002\u0018\u00002\u00020\u0001B\u0007\b\u0002\u00a2\u0006\u0002\u0010\u0002J\u000e\u0010\b\u001a\u00020\t2\u0006\u0010\n\u001a\u00020\u000bJ\u0010\u0010\f\u001a\u00020\r2\b\u0010\u000e\u001a\u0004\u0018\u00010\u0007J\u0014\u0010\u000f\u001a\b\u0012\u0004\u0012\u00020\r0\u00042\u0006\u0010\u0010\u001a\u00020\u0011J\u001b\u0010\u0012\u001a\b\u0012\u0004\u0012\u00020\r0\u00132\b\u0010\u000e\u001a\u0004\u0018\u00010\u0007\u00a2\u0006\u0002\u0010\u0014J\u0018\u0010\u0015\u001a\u00020\u00162\u0006\u0010\u0017\u001a\u00020\u00182\b\u0010\u0019\u001a\u0004\u0018\u00010\u001aJ\u0018\u0010\u0015\u001a\u00020\u00162\u0006\u0010\u001b\u001a\u00020\u001c2\b\u0010\u001d\u001a\u0004\u0018\u00010\u001aJ\u0018\u0010\u0015\u001a\u00020\u00162\u0006\u0010\u001e\u001a\u00020\t2\b\u0010\u001d\u001a\u0004\u0018\u00010\u001aJ \u0010\u001f\u001a\u00020\u00162\u0006\u0010\u0017\u001a\u00020\u00182\b\u0010 \u001a\u0004\u0018\u00010\u001a2\u0006\u0010!\u001a\u00020\"J\u0018\u0010\u001f\u001a\u00020#2\u0006\u0010\u001e\u001a\u00020\t2\b\u0010 \u001a\u0004\u0018\u00010\u001aJ\u0014\u0010$\u001a\b\u0012\u0004\u0012\u0002H%0\u0004\"\u0004\b\u0000\u0010%H\u0002J\u000e\u0010&\u001a\u00020'2\u0006\u0010\u0010\u001a\u00020\u0011J\u000e\u0010(\u001a\u00020\u001a2\u0006\u0010\u0017\u001a\u00020)J\u0006\u0010*\u001a\u00020\rJ\u0018\u0010+\u001a\u00020,2\b\u0010\u000e\u001a\u0004\u0018\u00010\u00072\u0006\u0010-\u001a\u00020\"R2\u0010\u0003\u001a&\u0012\f\u0012\n \u0005*\u0004\u0018\u00010\u00010\u0001 \u0005*\u0012\u0012\f\u0012\n \u0005*\u0004\u0018\u00010\u00010\u0001\u0018\u00010\u00040\u0004X\u0082\u0004\u00a2\u0006\u0002\n\u0000R\u000e\u0010\u0006\u001a\u00020\u0007X\u0086T\u00a2\u0006\u0002\n\u0000\u00a8\u0006."}, d2={"Ldorkbox/netUtil/SocketUtils;", "", "()V", "EMPTY", "Ljava/util/Enumeration;", "kotlin.jvm.PlatformType", "version", "", "accept", "Ljava/nio/channels/SocketChannel;", "serverSocketChannel", "Ljava/nio/channels/ServerSocketChannel;", "addressByName", "Ljava/net/InetAddress;", "hostname", "addressesFromNetworkInterface", "intf", "Ljava/net/NetworkInterface;", "allAddressesByName", "", "(Ljava/lang/String;)[Ljava/net/InetAddress;", "bind", "", "socket", "Ljava/net/Socket;", "bindpoint", "Ljava/net/SocketAddress;", "networkChannel", "Ljava/nio/channels/DatagramChannel;", "address", "socketChannel", "connect", "remoteAddress", "timeout", "", "", "empty", "T", "hardwareAddressFromNetworkInterface", "", "localSocketAddress", "Ljava/net/ServerSocket;", "loopbackAddress", "socketAddress", "Ljava/net/InetSocketAddress;", "port", "NetworkUtils"})
public final class SocketUtils {
    @NotNull
    public static final SocketUtils INSTANCE = new SocketUtils();
    @NotNull
    public static final String version = "2.19.1";
    private static final Enumeration<Object> EMPTY = Collections.enumeration(CollectionsKt.emptyList());

    private SocketUtils() {
    }

    private final <T> Enumeration<T> empty() {
        Enumeration<Object> enumeration = EMPTY;
        Intrinsics.checkNotNull(enumeration, (String)"null cannot be cast to non-null type java.util.Enumeration<T of dorkbox.netUtil.SocketUtils.empty>");
        return enumeration;
    }

    public final void connect(@NotNull Socket socket, @Nullable SocketAddress remoteAddress, int timeout) throws IOException {
        Intrinsics.checkNotNullParameter((Object)socket, (String)"socket");
        try {
            AccessController.doPrivileged(() -> SocketUtils.connect$lambda$0(socket, remoteAddress, timeout));
        }
        catch (PrivilegedActionException e) {
            IOException iOException = (IOException)e.getCause();
            Intrinsics.checkNotNull((Object)iOException);
            throw iOException;
        }
    }

    public final void bind(@NotNull Socket socket, @Nullable SocketAddress bindpoint) throws IOException {
        Intrinsics.checkNotNullParameter((Object)socket, (String)"socket");
        try {
            AccessController.doPrivileged(() -> SocketUtils.bind$lambda$1(socket, bindpoint));
        }
        catch (PrivilegedActionException e) {
            IOException iOException = (IOException)e.getCause();
            Intrinsics.checkNotNull((Object)iOException);
            throw iOException;
        }
    }

    public final boolean connect(@NotNull SocketChannel socketChannel, @Nullable SocketAddress remoteAddress) throws IOException {
        boolean bl;
        Intrinsics.checkNotNullParameter((Object)socketChannel, (String)"socketChannel");
        try {
            Boolean bl2 = AccessController.doPrivileged(() -> SocketUtils.connect$lambda$2(socketChannel, remoteAddress));
            Intrinsics.checkNotNullExpressionValue((Object)bl2, (String)"{\n            AccessCont\u2026moteAddress) })\n        }");
            bl = bl2;
        }
        catch (PrivilegedActionException e) {
            IOException iOException = (IOException)e.getCause();
            Intrinsics.checkNotNull((Object)iOException);
            throw iOException;
        }
        return bl;
    }

    public final void bind(@NotNull SocketChannel socketChannel, @Nullable SocketAddress address) throws IOException {
        Intrinsics.checkNotNullParameter((Object)socketChannel, (String)"socketChannel");
        try {
            AccessController.doPrivileged(() -> SocketUtils.bind$lambda$3(socketChannel, address));
        }
        catch (PrivilegedActionException e) {
            IOException iOException = (IOException)e.getCause();
            Intrinsics.checkNotNull((Object)iOException);
            throw iOException;
        }
    }

    @NotNull
    public final SocketChannel accept(@NotNull ServerSocketChannel serverSocketChannel) throws IOException {
        SocketChannel socketChannel;
        Intrinsics.checkNotNullParameter((Object)serverSocketChannel, (String)"serverSocketChannel");
        try {
            SocketChannel socketChannel2 = AccessController.doPrivileged(() -> SocketUtils.accept$lambda$4(serverSocketChannel));
            Intrinsics.checkNotNullExpressionValue((Object)socketChannel2, (String)"{\n            AccessCont\u2026nel.accept() })\n        }");
            socketChannel = socketChannel2;
        }
        catch (PrivilegedActionException e) {
            IOException iOException = (IOException)e.getCause();
            Intrinsics.checkNotNull((Object)iOException);
            throw iOException;
        }
        return socketChannel;
    }

    public final void bind(@NotNull DatagramChannel networkChannel, @Nullable SocketAddress address) throws IOException {
        Intrinsics.checkNotNullParameter((Object)networkChannel, (String)"networkChannel");
        try {
            AccessController.doPrivileged(() -> SocketUtils.bind$lambda$5(networkChannel, address));
        }
        catch (PrivilegedActionException e) {
            IOException iOException = (IOException)e.getCause();
            Intrinsics.checkNotNull((Object)iOException);
            throw iOException;
        }
    }

    @NotNull
    public final SocketAddress localSocketAddress(@NotNull ServerSocket socket) {
        Intrinsics.checkNotNullParameter((Object)socket, (String)"socket");
        SocketAddress socketAddress = AccessController.doPrivileged(() -> SocketUtils.localSocketAddress$lambda$6(socket));
        Intrinsics.checkNotNullExpressionValue((Object)socketAddress, (String)"doPrivileged(PrivilegedA\u2026ket.localSocketAddress })");
        return socketAddress;
    }

    @NotNull
    public final InetAddress addressByName(@Nullable String hostname) throws UnknownHostException {
        InetAddress inetAddress;
        try {
            InetAddress inetAddress2 = AccessController.doPrivileged(() -> SocketUtils.addressByName$lambda$7(hostname));
            Intrinsics.checkNotNullExpressionValue((Object)inetAddress2, (String)"{\n            AccessCont\u2026me(hostname) })\n        }");
            inetAddress = inetAddress2;
        }
        catch (PrivilegedActionException e) {
            UnknownHostException unknownHostException = (UnknownHostException)e.getCause();
            Intrinsics.checkNotNull((Object)unknownHostException);
            throw unknownHostException;
        }
        return inetAddress;
    }

    @NotNull
    public final InetAddress[] allAddressesByName(@Nullable String hostname) throws UnknownHostException {
        InetAddress[] inetAddressArray;
        try {
            InetAddress[] inetAddressArray2 = AccessController.doPrivileged(() -> SocketUtils.allAddressesByName$lambda$8(hostname));
            Intrinsics.checkNotNullExpressionValue((Object)inetAddressArray2, (String)"{\n            AccessCont\u2026me(hostname) })\n        }");
            inetAddressArray = inetAddressArray2;
        }
        catch (PrivilegedActionException e) {
            UnknownHostException unknownHostException = (UnknownHostException)e.getCause();
            Intrinsics.checkNotNull((Object)unknownHostException);
            throw unknownHostException;
        }
        return inetAddressArray;
    }

    @NotNull
    public final InetSocketAddress socketAddress(@Nullable String hostname, int port) {
        InetSocketAddress inetSocketAddress = AccessController.doPrivileged(() -> SocketUtils.socketAddress$lambda$9(hostname, port));
        Intrinsics.checkNotNullExpressionValue((Object)inetSocketAddress, (String)"doPrivileged(PrivilegedA\u2026ddress(hostname, port) })");
        return inetSocketAddress;
    }

    @NotNull
    public final Enumeration<InetAddress> addressesFromNetworkInterface(@NotNull NetworkInterface intf) {
        Intrinsics.checkNotNullParameter((Object)intf, (String)"intf");
        Enumeration enumeration = AccessController.doPrivileged(() -> SocketUtils.addressesFromNetworkInterface$lambda$10(intf));
        if (enumeration == null) {
            return this.empty();
        }
        return enumeration;
    }

    @NotNull
    public final InetAddress loopbackAddress() {
        InetAddress inetAddress = AccessController.doPrivileged(SocketUtils::loopbackAddress$lambda$11);
        Intrinsics.checkNotNullExpressionValue((Object)inetAddress, (String)"doPrivileged(PrivilegedA\u2026pbackAddress()\n        })");
        return inetAddress;
    }

    @NotNull
    public final byte[] hardwareAddressFromNetworkInterface(@NotNull NetworkInterface intf) throws SocketException {
        byte[] byArray;
        Intrinsics.checkNotNullParameter((Object)intf, (String)"intf");
        try {
            byte[] byArray2 = AccessController.doPrivileged(() -> SocketUtils.hardwareAddressFromNetworkInterface$lambda$12(intf));
            Intrinsics.checkNotNullExpressionValue((Object)byArray2, (String)"{\n            AccessCont\u2026dwareAddress })\n        }");
            byArray = byArray2;
        }
        catch (PrivilegedActionException e) {
            SocketException socketException = (SocketException)e.getCause();
            Intrinsics.checkNotNull((Object)socketException);
            throw socketException;
        }
        return byArray;
    }

    private static final Void connect$lambda$0(Socket $socket, SocketAddress $remoteAddress, int $timeout) {
        Intrinsics.checkNotNullParameter((Object)$socket, (String)"$socket");
        $socket.connect($remoteAddress, $timeout);
        return null;
    }

    private static final Void bind$lambda$1(Socket $socket, SocketAddress $bindpoint) {
        Intrinsics.checkNotNullParameter((Object)$socket, (String)"$socket");
        $socket.bind($bindpoint);
        return null;
    }

    private static final Boolean connect$lambda$2(SocketChannel $socketChannel, SocketAddress $remoteAddress) {
        Intrinsics.checkNotNullParameter((Object)$socketChannel, (String)"$socketChannel");
        return $socketChannel.connect($remoteAddress);
    }

    private static final Void bind$lambda$3(SocketChannel $socketChannel, SocketAddress $address) {
        Intrinsics.checkNotNullParameter((Object)$socketChannel, (String)"$socketChannel");
        $socketChannel.bind($address);
        return null;
    }

    private static final SocketChannel accept$lambda$4(ServerSocketChannel $serverSocketChannel) {
        Intrinsics.checkNotNullParameter((Object)$serverSocketChannel, (String)"$serverSocketChannel");
        return $serverSocketChannel.accept();
    }

    private static final Void bind$lambda$5(DatagramChannel $networkChannel, SocketAddress $address) {
        Intrinsics.checkNotNullParameter((Object)$networkChannel, (String)"$networkChannel");
        $networkChannel.bind($address);
        return null;
    }

    private static final SocketAddress localSocketAddress$lambda$6(ServerSocket $socket) {
        Intrinsics.checkNotNullParameter((Object)$socket, (String)"$socket");
        return $socket.getLocalSocketAddress();
    }

    private static final InetAddress addressByName$lambda$7(String $hostname) {
        return InetAddress.getByName($hostname);
    }

    private static final InetAddress[] allAddressesByName$lambda$8(String $hostname) {
        return InetAddress.getAllByName($hostname);
    }

    private static final InetSocketAddress socketAddress$lambda$9(String $hostname, int $port) {
        return new InetSocketAddress($hostname, $port);
    }

    private static final Enumeration addressesFromNetworkInterface$lambda$10(NetworkInterface $intf) {
        Intrinsics.checkNotNullParameter((Object)$intf, (String)"$intf");
        return $intf.getInetAddresses();
    }

    private static final InetAddress loopbackAddress$lambda$11() {
        return InetAddress.getLoopbackAddress();
    }

    private static final byte[] hardwareAddressFromNetworkInterface$lambda$12(NetworkInterface $intf) {
        Intrinsics.checkNotNullParameter((Object)$intf, (String)"$intf");
        return $intf.getHardwareAddress();
    }
}

