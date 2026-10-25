/*
 * Decompiled with CFR 0.152.
 * 
 * Could not load the following classes:
 *  kotlin.Metadata
 *  kotlin.Unit
 *  kotlin.io.CloseableKt
 *  kotlin.io.TextStreamsKt
 *  kotlin.jvm.functions.Function1
 *  kotlin.jvm.internal.Intrinsics
 *  kotlin.sequences.Sequence
 *  kotlin.sequences.SequencesKt
 *  org.jetbrains.annotations.NotNull
 */
package dorkbox.netUtil.dnsUtils;

import dorkbox.netUtil.Common;
import dorkbox.netUtil.IPv4;
import dorkbox.netUtil.IPv6;
import dorkbox.netUtil.dnsUtils.HostsFileEntries;
import dorkbox.netUtil.dnsUtils.HostsFileParser;
import java.io.BufferedReader;
import java.io.Closeable;
import java.io.File;
import java.io.FileInputStream;
import java.io.IOException;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.io.Reader;
import java.net.Inet4Address;
import java.net.Inet6Address;
import java.net.InetAddress;
import java.nio.charset.Charset;
import java.util.Arrays;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.regex.Pattern;
import kotlin.Metadata;
import kotlin.Unit;
import kotlin.io.CloseableKt;
import kotlin.io.TextStreamsKt;
import kotlin.jvm.functions.Function1;
import kotlin.jvm.internal.Intrinsics;
import kotlin.sequences.Sequence;
import kotlin.sequences.SequencesKt;
import org.jetbrains.annotations.NotNull;

@Metadata(mv={1, 7, 1}, k=1, xi=48, d1={"\u0000>\n\u0002\u0018\u0002\n\u0002\u0010\u0000\n\u0002\b\u0002\n\u0002\u0018\u0002\n\u0002\b\u0002\n\u0002\u0010\u000e\n\u0002\b\u0003\n\u0002\u0018\u0002\n\u0000\n\u0002\u0018\u0002\n\u0002\b\u0002\n\u0002\u0010\u0011\n\u0002\u0018\u0002\n\u0002\b\u0002\n\u0002\u0018\u0002\n\u0002\b\u0002\b\u00c6\u0002\u0018\u00002\u00020\u0001B\u0007\b\u0002\u00a2\u0006\u0002\u0010\u0002J\b\u0010\n\u001a\u00020\u000bH\u0002J\u0006\u0010\f\u001a\u00020\rJ'\u0010\f\u001a\u00020\r2\u0006\u0010\u000e\u001a\u00020\u000b2\u0012\u0010\u000f\u001a\n\u0012\u0006\b\u0001\u0012\u00020\u00110\u0010\"\u00020\u0011\u00a2\u0006\u0002\u0010\u0012J\u000e\u0010\f\u001a\u00020\r2\u0006\u0010\u0013\u001a\u00020\u0014J\u001f\u0010\f\u001a\u00020\r2\u0012\u0010\u000f\u001a\n\u0012\u0006\b\u0001\u0012\u00020\u00110\u0010\"\u00020\u0011\u00a2\u0006\u0002\u0010\u0015R\u0016\u0010\u0003\u001a\n \u0005*\u0004\u0018\u00010\u00040\u0004X\u0082\u0004\u00a2\u0006\u0002\n\u0000R\u000e\u0010\u0006\u001a\u00020\u0007X\u0082T\u00a2\u0006\u0002\n\u0000R\u000e\u0010\b\u001a\u00020\u0007X\u0082T\u00a2\u0006\u0002\n\u0000R\u000e\u0010\t\u001a\u00020\u0007X\u0082T\u00a2\u0006\u0002\n\u0000\u00a8\u0006\u0016"}, d2={"Ldorkbox/netUtil/dnsUtils/HostsFileParser;", "", "()V", "WHITESPACES", "Ljava/util/regex/Pattern;", "kotlin.jvm.PlatformType", "WINDOWS_DEFAULT_SYSTEM_ROOT", "", "WINDOWS_HOSTS_FILE_RELATIVE_PATH", "X_PLATFORMS_HOSTS_FILE_PATH", "locateHostsFile", "Ljava/io/File;", "parse", "Ldorkbox/netUtil/dnsUtils/HostsFileEntries;", "file", "charsets", "", "Ljava/nio/charset/Charset;", "(Ljava/io/File;[Ljava/nio/charset/Charset;)Ldorkbox/netUtil/dnsUtils/HostsFileEntries;", "reader", "Ljava/io/Reader;", "([Ljava/nio/charset/Charset;)Ldorkbox/netUtil/dnsUtils/HostsFileEntries;", "NetworkUtils"})
public final class HostsFileParser {
    @NotNull
    public static final HostsFileParser INSTANCE = new HostsFileParser();
    @NotNull
    private static final String WINDOWS_DEFAULT_SYSTEM_ROOT = "C:\\Windows";
    @NotNull
    private static final String WINDOWS_HOSTS_FILE_RELATIVE_PATH = "\\system32\\drivers\\etc\\hosts";
    @NotNull
    private static final String X_PLATFORMS_HOSTS_FILE_PATH = "/etc/hosts";
    private static final Pattern WHITESPACES = Pattern.compile("[ \t]+");

    private HostsFileParser() {
    }

    private final File locateHostsFile() {
        File hostsFile = null;
        if (Common.INSTANCE.getOS_WINDOWS()) {
            hostsFile = new File(System.getenv("SystemRoot") + WINDOWS_HOSTS_FILE_RELATIVE_PATH);
            if (!hostsFile.exists()) {
                hostsFile = new File("C:\\Windows\\system32\\drivers\\etc\\hosts");
            }
        } else {
            hostsFile = new File(X_PLATFORMS_HOSTS_FILE_PATH);
        }
        return hostsFile;
    }

    @NotNull
    public final HostsFileEntries parse() {
        Charset[] charsetArray = new Charset[1];
        Intrinsics.checkNotNullExpressionValue((Object)Charset.defaultCharset(), (String)"defaultCharset()");
        return this.parse(charsetArray);
    }

    @NotNull
    public final HostsFileEntries parse(Charset ... charsets) {
        HostsFileEntries hostsFileEntries;
        Intrinsics.checkNotNullParameter((Object)charsets, (String)"charsets");
        File hostsFile = this.locateHostsFile();
        try {
            hostsFileEntries = this.parse(hostsFile, Arrays.copyOf(charsets, charsets.length));
        }
        catch (IOException e) {
            Common.INSTANCE.getLogger$NetworkUtils().warn("Failed to load and parse hosts file at " + hostsFile.getPath(), (Throwable)e);
            hostsFileEntries = new HostsFileEntries(null, null, 3, null);
        }
        return hostsFileEntries;
    }

    /*
     * WARNING - Removed try catching itself - possible behaviour change.
     */
    @NotNull
    public final HostsFileEntries parse(@NotNull File file, Charset ... charsets) {
        Intrinsics.checkNotNullParameter((Object)file, (String)"file");
        Intrinsics.checkNotNullParameter((Object)charsets, (String)"charsets");
        HostsFileEntries hostsFileEntries = new HostsFileEntries(null, null, 3, null);
        try {
            if (file.exists() && file.isFile()) {
                for (Charset charset : charsets) {
                    Closeable closeable = new BufferedReader(new InputStreamReader((InputStream)new FileInputStream(file), charset));
                    Throwable throwable = null;
                    try {
                        BufferedReader reader = (BufferedReader)closeable;
                        boolean bl = false;
                        HostsFileEntries entries = INSTANCE.parse(reader);
                        if (!Intrinsics.areEqual((Object)entries, (Object)hostsFileEntries)) {
                            HostsFileEntries hostsFileEntries2 = entries;
                            return hostsFileEntries2;
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
        }
        catch (IOException e) {
            Common.INSTANCE.getLogger$NetworkUtils().warn("Failed to load and parse hosts file at " + file.getPath(), (Throwable)e);
        }
        return hostsFileEntries;
    }

    /*
     * WARNING - Removed try catching itself - possible behaviour change.
     * WARNING - void declaration
     */
    @NotNull
    public final HostsFileEntries parse(@NotNull Reader reader) {
        Intrinsics.checkNotNullParameter((Object)reader, (String)"reader");
        Map ipv4Entries = new LinkedHashMap();
        Map ipv6Entries = new LinkedHashMap();
        Reader $this$useLines$iv = reader;
        boolean $i$f$useLines = false;
        Closeable closeable = $this$useLines$iv;
        int n = 8192;
        closeable = closeable instanceof BufferedReader ? (BufferedReader)closeable : new BufferedReader((Reader)closeable, n);
        Throwable throwable = null;
        try {
            void $this$forEach$iv;
            BufferedReader it$iv = (BufferedReader)closeable;
            boolean bl = false;
            Sequence lines = TextStreamsKt.lineSequence((BufferedReader)it$iv);
            boolean bl2 = false;
            Sequence sequence = SequencesKt.filter((Sequence)SequencesKt.map((Sequence)SequencesKt.filter((Sequence)SequencesKt.map((Sequence)SequencesKt.map((Sequence)lines, (Function1)parse.2.1.INSTANCE), (Function1)parse.2.2.INSTANCE), (Function1)parse.2.3.INSTANCE), (Function1)parse.2.4.INSTANCE), (Function1)parse.2.5.INSTANCE);
            boolean $i$f$forEach = false;
            for (Object element$iv : $this$forEach$iv) {
                List lineParts = (List)element$iv;
                boolean bl3 = false;
                String ip = (String)lineParts.get(0);
                byte[] ipBytes = IPv4.INSTANCE.isValid(ip) ? IPv4.INSTANCE.toBytes(ip) : (byte[])(IPv6.INSTANCE.isValid(ip) ? IPv6.INSTANCE.toBytes(ip) : null);
                if (ipBytes == null) continue;
                int n2 = lineParts.size();
                for (int i = 1; i < n2; ++i) {
                    InetAddress previous;
                    String hostnameLower;
                    String hostname;
                    String string = hostname = (String)lineParts.get(i);
                    Locale locale = Locale.ENGLISH;
                    Intrinsics.checkNotNullExpressionValue((Object)locale, (String)"ENGLISH");
                    Intrinsics.checkNotNullExpressionValue((Object)string.toLowerCase(locale), (String)"this as java.lang.String).toLowerCase(locale)");
                    InetAddress address = InetAddress.getByAddress(hostname, ipBytes);
                    if (address instanceof Inet4Address) {
                        previous = (Inet4Address)ipv4Entries.put(hostnameLower, address);
                        if (previous == null) continue;
                        ipv4Entries.put(hostnameLower, previous);
                        continue;
                    }
                    Intrinsics.checkNotNull((Object)address, (String)"null cannot be cast to non-null type java.net.Inet6Address");
                    previous = ipv6Entries.put(hostnameLower, (Inet6Address)address);
                    if (previous == null) continue;
                    ipv6Entries.put(hostnameLower, previous);
                }
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
        return new HostsFileEntries(ipv4Entries, ipv6Entries);
    }

    public static final /* synthetic */ Pattern access$getWHITESPACES$p() {
        return WHITESPACES;
    }
}

