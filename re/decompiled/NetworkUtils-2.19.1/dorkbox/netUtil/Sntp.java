/*
 * Decompiled with CFR 0.152.
 * 
 * Could not load the following classes:
 *  kotlin.Metadata
 *  kotlin.jvm.internal.DefaultConstructorMarker
 *  kotlin.jvm.internal.Intrinsics
 *  kotlin.random.Random
 *  org.jetbrains.annotations.NotNull
 */
package dorkbox.netUtil;

import java.net.DatagramPacket;
import java.net.DatagramSocket;
import java.net.InetAddress;
import java.util.Arrays;
import java.util.concurrent.TimeUnit;
import kotlin.Metadata;
import kotlin.jvm.internal.DefaultConstructorMarker;
import kotlin.jvm.internal.Intrinsics;
import kotlin.random.Random;
import org.jetbrains.annotations.NotNull;

@Metadata(mv={1, 7, 1}, k=1, xi=48, d1={"\u0000\"\n\u0002\u0018\u0002\n\u0002\u0010\u0000\n\u0002\b\u0002\n\u0002\u0010\u000e\n\u0000\n\u0002\u0018\u0002\n\u0002\b\u0002\n\u0002\u0010\b\n\u0002\b\u0002\b\u00c6\u0002\u0018\u00002\u00020\u0001:\u0001\nB\u0007\b\u0002\u00a2\u0006\u0002\u0010\u0002J\u0018\u0010\u0005\u001a\u00020\u00062\u0006\u0010\u0007\u001a\u00020\u00042\b\b\u0002\u0010\b\u001a\u00020\tR\u000e\u0010\u0003\u001a\u00020\u0004X\u0086T\u00a2\u0006\u0002\n\u0000\u00a8\u0006\u000b"}, d2={"Ldorkbox/netUtil/Sntp;", "", "()V", "version", "", "update", "Ldorkbox/netUtil/Sntp$SntpClient;", "server", "timeoutInMS", "", "SntpClient", "NetworkUtils"})
public final class Sntp {
    @NotNull
    public static final Sntp INSTANCE = new Sntp();
    @NotNull
    public static final String version = "2.19.1";

    private Sntp() {
    }

    @NotNull
    public final SntpClient update(@NotNull String server, int timeoutInMS) {
        Intrinsics.checkNotNullParameter((Object)server, (String)"server");
        return new SntpClient().requestTime$NetworkUtils(server, timeoutInMS);
    }

    public static /* synthetic */ SntpClient update$default(Sntp sntp, String string, int n, int n2, Object object) {
        if ((n2 & 2) != 0) {
            n = 10000;
        }
        return sntp.update(string, n);
    }

    @Metadata(mv={1, 7, 1}, k=1, xi=48, d1={"\u0000D\n\u0002\u0018\u0002\n\u0002\u0010\u0000\n\u0002\b\u0002\n\u0002\u0010\t\n\u0002\b\u0003\n\u0002\u0010\b\n\u0002\b\u0016\n\u0002\u0010\u0006\n\u0002\b\u0011\n\u0002\u0010\u0012\n\u0002\b\u0004\n\u0002\u0010\u000e\n\u0002\b\u0003\n\u0002\u0010\u0002\n\u0002\b\u0003\n\u0002\u0010\u0005\n\u0002\b\u0002\u0018\u0000 ?2\u00020\u0001:\u0001?B\u0005\u00a2\u0006\u0002\u0010\u0002J\u0018\u0010/\u001a\u00020\u00042\u0006\u00100\u001a\u0002012\u0006\u00102\u001a\u00020\bH\u0002J\u0018\u00103\u001a\u00020\u00042\u0006\u00100\u001a\u0002012\u0006\u00102\u001a\u00020\bH\u0002J\u001d\u00104\u001a\u00020\u00002\u0006\u00105\u001a\u0002062\u0006\u00107\u001a\u00020\bH\u0000\u00a2\u0006\u0002\b8J(\u00109\u001a\u00020:2\u0006\u00100\u001a\u0002012\u0006\u0010;\u001a\u00020\b2\u0006\u0010<\u001a\u00020\u00042\u0006\u0010=\u001a\u00020>H\u0002R\u001e\u0010\u0005\u001a\u00020\u00042\u0006\u0010\u0003\u001a\u00020\u0004@BX\u0086\u000e\u00a2\u0006\b\n\u0000\u001a\u0004\b\u0006\u0010\u0007R\u001e\u0010\t\u001a\u00020\b2\u0006\u0010\u0003\u001a\u00020\b@BX\u0086\u000e\u00a2\u0006\b\n\u0000\u001a\u0004\b\n\u0010\u000bR\u001e\u0010\f\u001a\u00020\u00042\u0006\u0010\u0003\u001a\u00020\u0004@BX\u0086\u000e\u00a2\u0006\b\n\u0000\u001a\u0004\b\r\u0010\u0007R\u001e\u0010\u000e\u001a\u00020\b2\u0006\u0010\u0003\u001a\u00020\b@BX\u0086\u000e\u00a2\u0006\b\n\u0000\u001a\u0004\b\u000f\u0010\u000bR\u0011\u0010\u0010\u001a\u00020\u00048F\u00a2\u0006\u0006\u001a\u0004\b\u0011\u0010\u0007R\u001e\u0010\u0012\u001a\u00020\u00042\u0006\u0010\u0003\u001a\u00020\u0004@BX\u0086\u000e\u00a2\u0006\b\n\u0000\u001a\u0004\b\u0013\u0010\u0007R\u001e\u0010\u0014\u001a\u00020\u00042\u0006\u0010\u0003\u001a\u00020\u0004@BX\u0086\u000e\u00a2\u0006\b\n\u0000\u001a\u0004\b\u0015\u0010\u0007R\u001e\u0010\u0016\u001a\u00020\b2\u0006\u0010\u0003\u001a\u00020\b@BX\u0086\u000e\u00a2\u0006\b\n\u0000\u001a\u0004\b\u0017\u0010\u000bR\u001e\u0010\u0018\u001a\u00020\b2\u0006\u0010\u0003\u001a\u00020\b@BX\u0086\u000e\u00a2\u0006\b\n\u0000\u001a\u0004\b\u0019\u0010\u000bR\u001e\u0010\u001a\u001a\u00020\u00042\u0006\u0010\u0003\u001a\u00020\u0004@BX\u0086\u000e\u00a2\u0006\b\n\u0000\u001a\u0004\b\u001b\u0010\u0007R\u001e\u0010\u001c\u001a\u00020\u00042\u0006\u0010\u0003\u001a\u00020\u0004@BX\u0086\u000e\u00a2\u0006\b\n\u0000\u001a\u0004\b\u001d\u0010\u0007R\u001a\u0010\u001e\u001a\u00020\u001fX\u0086\u000e\u00a2\u0006\u000e\n\u0000\u001a\u0004\b \u0010!\"\u0004\b\"\u0010#R\u001a\u0010$\u001a\u00020\u001fX\u0086\u000e\u00a2\u0006\u000e\n\u0000\u001a\u0004\b%\u0010!\"\u0004\b&\u0010#R\u001e\u0010'\u001a\u00020\u00042\u0006\u0010\u0003\u001a\u00020\u0004@BX\u0086\u000e\u00a2\u0006\b\n\u0000\u001a\u0004\b(\u0010\u0007R\u001e\u0010)\u001a\u00020\b2\u0006\u0010\u0003\u001a\u00020\b@BX\u0086\u000e\u00a2\u0006\b\n\u0000\u001a\u0004\b*\u0010\u000bR\u001e\u0010+\u001a\u00020\u00042\u0006\u0010\u0003\u001a\u00020\u0004@BX\u0086\u000e\u00a2\u0006\b\n\u0000\u001a\u0004\b,\u0010\u0007R\u001e\u0010-\u001a\u00020\b2\u0006\u0010\u0003\u001a\u00020\b@BX\u0086\u000e\u00a2\u0006\b\n\u0000\u001a\u0004\b.\u0010\u000b\u00a8\u0006@"}, d2={"Ldorkbox/netUtil/Sntp$SntpClient;", "", "()V", "<set-?>", "", "destinationTimestamp", "getDestinationTimestamp", "()J", "", "leap", "getLeap", "()I", "localClockOffset", "getLocalClockOffset", "mode", "getMode", "now", "getNow", "ntpTime", "getNtpTime", "originateTimestamp", "getOriginateTimestamp", "pollInterval", "getPollInterval", "precision", "getPrecision", "receiveTimestamp", "getReceiveTimestamp", "referenceTimestamp", "getReferenceTimestamp", "rootDelay", "", "getRootDelay", "()D", "setRootDelay", "(D)V", "rootDispersion", "getRootDispersion", "setRootDispersion", "roundTripDelay", "getRoundTripDelay", "stratum", "getStratum", "transmitTimestamp", "getTransmitTimestamp", "version", "getVersion", "read32", "buffer", "", "offset", "readTimeStamp", "requestTime", "host", "", "timeoutMS", "requestTime$NetworkUtils", "writeTimeStamp", "", "offset_", "time", "randomNumber", "", "Companion", "NetworkUtils"})
    public static final class SntpClient {
        @NotNull
        public static final Companion Companion = new Companion(null);
        private int leap;
        private int version;
        private int mode;
        private int stratum;
        private int pollInterval;
        private int precision;
        private double rootDelay;
        private double rootDispersion;
        private long referenceTimestamp;
        private long originateTimestamp;
        private long receiveTimestamp;
        private long transmitTimestamp;
        private long destinationTimestamp;
        private long ntpTime;
        private long roundTripDelay;
        private long localClockOffset;
        private static final int REFERENCE_TIME_OFFSET = 16;
        private static final int ORIGINATE_TIME_OFFSET = 24;
        private static final int RECEIVE_TIME_OFFSET = 32;
        private static final int TRANSMIT_TIME_OFFSET = 40;
        private static final int NTP_PACKET_SIZE = 48;
        private static final int NTP_PORT = 123;
        private static final int NTP_MODE_CLIENT = 3;
        private static final int NTP_MODE_SERVER = 4;
        private static final int NTP_MODE_BROADCAST = 5;
        private static final int NTP_VERSION = 3;
        private static final int NTP_LEAP_NOSYNC = 3;
        private static final int NTP_STRATUM_DEATH = 0;
        private static final int NTP_STRATUM_MAX = 15;
        private static final long OFFSET_1900_TO_1970 = 2208988800L;

        public final int getLeap() {
            return this.leap;
        }

        public final int getVersion() {
            return this.version;
        }

        public final int getMode() {
            return this.mode;
        }

        public final int getStratum() {
            return this.stratum;
        }

        public final int getPollInterval() {
            return this.pollInterval;
        }

        public final int getPrecision() {
            return this.precision;
        }

        public final double getRootDelay() {
            return this.rootDelay;
        }

        public final void setRootDelay(double d) {
            this.rootDelay = d;
        }

        public final double getRootDispersion() {
            return this.rootDispersion;
        }

        public final void setRootDispersion(double d) {
            this.rootDispersion = d;
        }

        public final long getReferenceTimestamp() {
            return this.referenceTimestamp;
        }

        public final long getOriginateTimestamp() {
            return this.originateTimestamp;
        }

        public final long getReceiveTimestamp() {
            return this.receiveTimestamp;
        }

        public final long getTransmitTimestamp() {
            return this.transmitTimestamp;
        }

        public final long getDestinationTimestamp() {
            return this.destinationTimestamp;
        }

        public final long getNtpTime() {
            return this.ntpTime;
        }

        public final long getRoundTripDelay() {
            return this.roundTripDelay;
        }

        public final long getLocalClockOffset() {
            return this.localClockOffset;
        }

        public final long getNow() {
            return System.currentTimeMillis() + this.localClockOffset;
        }

        /*
         * WARNING - Removed try catching itself - possible behaviour change.
         */
        @NotNull
        public final SntpClient requestTime$NetworkUtils(@NotNull String host, int timeoutMS) {
            Intrinsics.checkNotNullParameter((Object)host, (String)"host");
            DatagramSocket socket = null;
            InetAddress address = null;
            try {
                socket = new DatagramSocket();
                socket.setSoTimeout(timeoutMS);
                address = InetAddress.getByName(host);
                byte[] buffer = new byte[48];
                DatagramPacket request = new DatagramPacket(buffer, buffer.length, address, 123);
                buffer[0] = 27;
                byte randomNumber = (byte)Random.Default.nextInt(255);
                long timeAtSend = System.currentTimeMillis();
                this.writeTimeStamp(buffer, 40, timeAtSend, randomNumber);
                socket.send(request);
                DatagramPacket response = new DatagramPacket(buffer, buffer.length);
                socket.receive(response);
                this.destinationTimestamp = System.currentTimeMillis();
                socket.close();
                this.leap = buffer[0] >> 6 & 3;
                this.version = buffer[0] >> 3 & 7;
                this.mode = buffer[0] & 7;
                this.stratum = buffer[1];
                this.pollInterval = buffer[2];
                this.precision = buffer[3];
                this.rootDelay = (double)buffer[4] * 256.0 + (double)buffer[5] + (double)buffer[6] / 256.0 + (double)buffer[7] / 65536.0;
                this.rootDispersion = (double)buffer[8] * 256.0 + (double)buffer[9] + (double)buffer[10] / 256.0 + (double)buffer[11] / 65536.0;
                this.referenceTimestamp = this.readTimeStamp(buffer, 16);
                this.originateTimestamp = this.readTimeStamp(buffer, 24);
                this.receiveTimestamp = this.readTimeStamp(buffer, 32);
                this.transmitTimestamp = this.readTimeStamp(buffer, 40);
                SntpClient.Companion.checkValidServerReply(this.leap, this.mode, this.stratum, this.transmitTimestamp);
                this.roundTripDelay = this.destinationTimestamp - this.originateTimestamp - (this.transmitTimestamp - this.receiveTimestamp);
                this.localClockOffset = (this.receiveTimestamp - this.originateTimestamp + (this.transmitTimestamp - this.destinationTimestamp)) / 2L;
                socket.close();
            }
            catch (Exception e) {
                System.err.println("Error with NTP to " + address + ". " + e);
            }
            finally {
                DatagramSocket datagramSocket = socket;
                if (datagramSocket != null) {
                    datagramSocket.close();
                }
            }
            return this;
        }

        private final long read32(byte[] buffer, int offset) {
            int b0 = buffer[offset];
            int b1 = buffer[offset + 1];
            int b2 = buffer[offset + 2];
            int b3 = buffer[offset + 3];
            long i0 = (b0 & 0x80) == 128 ? (b0 & 0x7F) + 128 : b0;
            long i1 = (b1 & 0x80) == 128 ? (b1 & 0x7F) + 128 : b1;
            long i2 = (b2 & 0x80) == 128 ? (b2 & 0x7F) + 128 : b2;
            long i3 = (b3 & 0x80) == 128 ? (b3 & 0x7F) + 128 : b3;
            return (i0 << 24) + (i1 << 16) + (i2 << 8) + i3;
        }

        private final long readTimeStamp(byte[] buffer, int offset) {
            long seconds = this.read32(buffer, offset);
            long fraction = this.read32(buffer, offset + 4);
            return seconds == 0L && fraction == 0L ? 0L : (seconds - 2208988800L) * (long)1000 + fraction * 1000L / 0x100000000L;
        }

        private final void writeTimeStamp(byte[] buffer, int offset_, long time, byte randomNumber) {
            int offset = offset_;
            if (time == 0L) {
                Arrays.fill(buffer, offset, offset + 8, (byte)0);
                return;
            }
            long seconds = TimeUnit.MILLISECONDS.toSeconds(time);
            long remainingNotSeconds = time - TimeUnit.SECONDS.toMillis(seconds);
            long fraction = remainingNotSeconds * 0x100000000L / 1000L;
            buffer[offset++] = (byte)((seconds += 2208988800L) >> 24);
            buffer[offset++] = (byte)(seconds >> 16);
            buffer[offset++] = (byte)(seconds >> 8);
            buffer[offset++] = (byte)(seconds >> 0);
            buffer[offset++] = (byte)(fraction >> 24);
            buffer[offset++] = (byte)(fraction >> 16);
            buffer[offset++] = (byte)(fraction >> 8);
            buffer[offset] = randomNumber;
        }

        @Metadata(mv={1, 7, 1}, k=1, xi=48, d1={"\u0000$\n\u0002\u0018\u0002\n\u0002\u0010\u0000\n\u0002\b\u0002\n\u0002\u0010\b\n\u0002\b\t\n\u0002\u0010\t\n\u0002\b\u0005\n\u0002\u0010\u0002\n\u0002\b\u0006\b\u0086\u0003\u0018\u00002\u00020\u0001:\u0001\u0019B\u0007\b\u0002\u00a2\u0006\u0002\u0010\u0002J(\u0010\u0013\u001a\u00020\u00142\u0006\u0010\u0015\u001a\u00020\u00042\u0006\u0010\u0016\u001a\u00020\u00042\u0006\u0010\u0017\u001a\u00020\u00042\u0006\u0010\u0018\u001a\u00020\u000eH\u0002R\u000e\u0010\u0003\u001a\u00020\u0004X\u0082T\u00a2\u0006\u0002\n\u0000R\u000e\u0010\u0005\u001a\u00020\u0004X\u0082T\u00a2\u0006\u0002\n\u0000R\u000e\u0010\u0006\u001a\u00020\u0004X\u0082T\u00a2\u0006\u0002\n\u0000R\u000e\u0010\u0007\u001a\u00020\u0004X\u0082T\u00a2\u0006\u0002\n\u0000R\u000e\u0010\b\u001a\u00020\u0004X\u0082T\u00a2\u0006\u0002\n\u0000R\u000e\u0010\t\u001a\u00020\u0004X\u0082T\u00a2\u0006\u0002\n\u0000R\u000e\u0010\n\u001a\u00020\u0004X\u0082T\u00a2\u0006\u0002\n\u0000R\u000e\u0010\u000b\u001a\u00020\u0004X\u0082T\u00a2\u0006\u0002\n\u0000R\u000e\u0010\f\u001a\u00020\u0004X\u0082T\u00a2\u0006\u0002\n\u0000R\u000e\u0010\r\u001a\u00020\u000eX\u0082T\u00a2\u0006\u0002\n\u0000R\u000e\u0010\u000f\u001a\u00020\u0004X\u0082T\u00a2\u0006\u0002\n\u0000R\u000e\u0010\u0010\u001a\u00020\u0004X\u0082T\u00a2\u0006\u0002\n\u0000R\u000e\u0010\u0011\u001a\u00020\u0004X\u0082T\u00a2\u0006\u0002\n\u0000R\u000e\u0010\u0012\u001a\u00020\u0004X\u0082T\u00a2\u0006\u0002\n\u0000\u00a8\u0006\u001a"}, d2={"Ldorkbox/netUtil/Sntp$SntpClient$Companion;", "", "()V", "NTP_LEAP_NOSYNC", "", "NTP_MODE_BROADCAST", "NTP_MODE_CLIENT", "NTP_MODE_SERVER", "NTP_PACKET_SIZE", "NTP_PORT", "NTP_STRATUM_DEATH", "NTP_STRATUM_MAX", "NTP_VERSION", "OFFSET_1900_TO_1970", "", "ORIGINATE_TIME_OFFSET", "RECEIVE_TIME_OFFSET", "REFERENCE_TIME_OFFSET", "TRANSMIT_TIME_OFFSET", "checkValidServerReply", "", "leap", "mode", "stratum", "transmitTime", "InvalidServerReplyException", "NetworkUtils"})
        public static final class Companion {
            private Companion() {
            }

            private final void checkValidServerReply(int leap, int mode, int stratum, long transmitTime) throws InvalidServerReplyException {
                if (leap == 3) {
                    throw new InvalidServerReplyException("unsynchronized server");
                }
                if (mode != 4 && mode != 5) {
                    throw new InvalidServerReplyException("untrusted mode: " + mode);
                }
                if (stratum == 0 || stratum > 15) {
                    throw new InvalidServerReplyException("untrusted stratum: " + stratum);
                }
                if (transmitTime == 0L) {
                    throw new InvalidServerReplyException("zero transmitTime");
                }
            }

            public /* synthetic */ Companion(DefaultConstructorMarker $constructor_marker) {
                this();
            }

            @Metadata(mv={1, 7, 1}, k=1, xi=48, d1={"\u0000\u0016\n\u0002\u0018\u0002\n\u0002\u0018\u0002\n\u0002\u0018\u0002\n\u0000\n\u0002\u0010\u000e\n\u0002\b\u0002\b\u0002\u0018\u00002\u00060\u0001j\u0002`\u0002B\r\u0012\u0006\u0010\u0003\u001a\u00020\u0004\u00a2\u0006\u0002\u0010\u0005\u00a8\u0006\u0006"}, d2={"Ldorkbox/netUtil/Sntp$SntpClient$Companion$InvalidServerReplyException;", "Ljava/lang/Exception;", "Lkotlin/Exception;", "message", "", "(Ljava/lang/String;)V", "NetworkUtils"})
            private static final class InvalidServerReplyException
            extends Exception {
                public InvalidServerReplyException(@NotNull String message) {
                    Intrinsics.checkNotNullParameter((Object)message, (String)"message");
                    super(message);
                }
            }
        }
    }
}

