/*
 * Decompiled with CFR 0.152.
 * 
 * Could not load the following classes:
 *  kotlin.Metadata
 *  kotlin.jvm.internal.Intrinsics
 *  org.jetbrains.annotations.NotNull
 *  org.jetbrains.annotations.Nullable
 */
package dorkbox.netUtil.ping;

import java.time.Duration;
import java.util.ArrayList;
import kotlin.Metadata;
import kotlin.jvm.internal.Intrinsics;
import org.jetbrains.annotations.NotNull;
import org.jetbrains.annotations.Nullable;

@Metadata(mv={1, 7, 1}, k=1, xi=48, d1={"\u0000<\n\u0002\u0018\u0002\n\u0002\u0010\u0000\n\u0002\b\u0002\n\u0002\u0018\u0002\n\u0002\b\u0005\n\u0002\u0010\u000e\n\u0002\b\u0011\n\u0002\u0010\u0006\n\u0002\b\u0005\n\u0002\u0010\b\n\u0002\b\u0005\n\u0002\u0018\u0002\n\u0002\u0018\u0002\n\u0002\u0018\u0002\n\u0002\b\u000b\u0018\u00002\u00020\u0001:\u00014B\u0005\u00a2\u0006\u0002\u0010\u0002J\b\u00103\u001a\u00020\nH\u0016R\u001c\u0010\u0003\u001a\u0004\u0018\u00010\u0004X\u0086\u000e\u00a2\u0006\u000e\n\u0000\u001a\u0004\b\u0005\u0010\u0006\"\u0004\b\u0007\u0010\bR\u001c\u0010\t\u001a\u0004\u0018\u00010\nX\u0086\u000e\u00a2\u0006\u000e\n\u0000\u001a\u0004\b\u000b\u0010\f\"\u0004\b\r\u0010\u000eR\u001c\u0010\u000f\u001a\u0004\u0018\u00010\nX\u0086\u000e\u00a2\u0006\u000e\n\u0000\u001a\u0004\b\u0010\u0010\f\"\u0004\b\u0011\u0010\u000eR\u001c\u0010\u0012\u001a\u0004\u0018\u00010\u0004X\u0086\u000e\u00a2\u0006\u000e\n\u0000\u001a\u0004\b\u0013\u0010\u0006\"\u0004\b\u0014\u0010\bR\u001c\u0010\u0015\u001a\u0004\u0018\u00010\u0004X\u0086\u000e\u00a2\u0006\u000e\n\u0000\u001a\u0004\b\u0016\u0010\u0006\"\u0004\b\u0017\u0010\bR\u001c\u0010\u0018\u001a\u0004\u0018\u00010\u0004X\u0086\u000e\u00a2\u0006\u000e\n\u0000\u001a\u0004\b\u0019\u0010\u0006\"\u0004\b\u001a\u0010\bR\u001a\u0010\u001b\u001a\u00020\u001cX\u0086\u000e\u00a2\u0006\u000e\n\u0000\u001a\u0004\b\u001d\u0010\u001e\"\u0004\b\u001f\u0010 R\u001a\u0010!\u001a\u00020\"X\u0086\u000e\u00a2\u0006\u000e\n\u0000\u001a\u0004\b#\u0010$\"\u0004\b%\u0010&R!\u0010'\u001a\u0012\u0012\u0004\u0012\u00020)0(j\b\u0012\u0004\u0012\u00020)`*\u00a2\u0006\b\n\u0000\u001a\u0004\b+\u0010,R\u001c\u0010-\u001a\u0004\u0018\u00010\u0004X\u0086\u000e\u00a2\u0006\u000e\n\u0000\u001a\u0004\b.\u0010\u0006\"\u0004\b/\u0010\bR\u001a\u00100\u001a\u00020\"X\u0086\u000e\u00a2\u0006\u000e\n\u0000\u001a\u0004\b1\u0010$\"\u0004\b2\u0010&\u00a8\u00065"}, d2={"Ldorkbox/netUtil/ping/PingResult;", "", "()V", "avgRoundTripTime", "Ljava/time/Duration;", "getAvgRoundTripTime", "()Ljava/time/Duration;", "setAvgRoundTripTime", "(Ljava/time/Duration;)V", "host", "", "getHost", "()Ljava/lang/String;", "setHost", "(Ljava/lang/String;)V", "ip", "getIp", "setIp", "maxRoundTripTime", "getMaxRoundTripTime", "setMaxRoundTripTime", "mdevRoundTripTime", "getMdevRoundTripTime", "setMdevRoundTripTime", "minRoundTripTime", "getMinRoundTripTime", "setMinRoundTripTime", "packetLoss", "", "getPacketLoss", "()D", "setPacketLoss", "(D)V", "receivedPackets", "", "getReceivedPackets", "()I", "setReceivedPackets", "(I)V", "responses", "Ljava/util/ArrayList;", "Ldorkbox/netUtil/ping/PingResult$Response;", "Lkotlin/collections/ArrayList;", "getResponses", "()Ljava/util/ArrayList;", "time", "getTime", "setTime", "transmittedPackets", "getTransmittedPackets", "setTransmittedPackets", "toString", "Response", "NetworkUtils"})
public final class PingResult {
    @Nullable
    private String host;
    @Nullable
    private String ip;
    @NotNull
    private final ArrayList<Response> responses = new ArrayList();
    private int transmittedPackets;
    private int receivedPackets;
    private double packetLoss;
    @Nullable
    private Duration time;
    @Nullable
    private Duration minRoundTripTime;
    @Nullable
    private Duration avgRoundTripTime;
    @Nullable
    private Duration maxRoundTripTime;
    @Nullable
    private Duration mdevRoundTripTime;

    @Nullable
    public final String getHost() {
        return this.host;
    }

    public final void setHost(@Nullable String string) {
        this.host = string;
    }

    @Nullable
    public final String getIp() {
        return this.ip;
    }

    public final void setIp(@Nullable String string) {
        this.ip = string;
    }

    @NotNull
    public final ArrayList<Response> getResponses() {
        return this.responses;
    }

    public final int getTransmittedPackets() {
        return this.transmittedPackets;
    }

    public final void setTransmittedPackets(int n) {
        this.transmittedPackets = n;
    }

    public final int getReceivedPackets() {
        return this.receivedPackets;
    }

    public final void setReceivedPackets(int n) {
        this.receivedPackets = n;
    }

    public final double getPacketLoss() {
        return this.packetLoss;
    }

    public final void setPacketLoss(double d) {
        this.packetLoss = d;
    }

    @Nullable
    public final Duration getTime() {
        return this.time;
    }

    public final void setTime(@Nullable Duration duration) {
        this.time = duration;
    }

    @Nullable
    public final Duration getMinRoundTripTime() {
        return this.minRoundTripTime;
    }

    public final void setMinRoundTripTime(@Nullable Duration duration) {
        this.minRoundTripTime = duration;
    }

    @Nullable
    public final Duration getAvgRoundTripTime() {
        return this.avgRoundTripTime;
    }

    public final void setAvgRoundTripTime(@Nullable Duration duration) {
        this.avgRoundTripTime = duration;
    }

    @Nullable
    public final Duration getMaxRoundTripTime() {
        return this.maxRoundTripTime;
    }

    public final void setMaxRoundTripTime(@Nullable Duration duration) {
        this.maxRoundTripTime = duration;
    }

    @Nullable
    public final Duration getMdevRoundTripTime() {
        return this.mdevRoundTripTime;
    }

    public final void setMdevRoundTripTime(@Nullable Duration duration) {
        this.mdevRoundTripTime = duration;
    }

    @NotNull
    public String toString() {
        StringBuilder stringBuilder = new StringBuilder();
        stringBuilder.append("PingResult(host=").append(this.host).append(", ip=").append(this.ip).append(", responses=").append(this.responses).append(", transmittedPackets=").append(this.transmittedPackets).append(", receivedPackets=").append(this.receivedPackets).append(", packetLoss=").append(this.packetLoss).append("%, time=").append(this.time).append(", minRoundTripTime=").append(this.minRoundTripTime).append(", avgRoundTripTime=").append(this.avgRoundTripTime).append(", maxRoundTripTime=").append(this.maxRoundTripTime).append(", mdevRoundTripTime=").append(this.mdevRoundTripTime).append(')');
        return stringBuilder.toString();
    }

    @Metadata(mv={1, 7, 1}, k=1, xi=48, d1={"\u0000(\n\u0002\u0018\u0002\n\u0002\u0010\u0000\n\u0000\n\u0002\u0010\b\n\u0000\n\u0002\u0010\u000e\n\u0002\b\u0003\n\u0002\u0018\u0002\n\u0002\b\u0010\n\u0002\u0010\u000b\n\u0002\b\u0004\b\u0086\b\u0018\u00002\u00020\u0001B-\u0012\u0006\u0010\u0002\u001a\u00020\u0003\u0012\u0006\u0010\u0004\u001a\u00020\u0005\u0012\u0006\u0010\u0006\u001a\u00020\u0003\u0012\u0006\u0010\u0007\u001a\u00020\u0003\u0012\u0006\u0010\b\u001a\u00020\t\u00a2\u0006\u0002\u0010\nJ\t\u0010\u0013\u001a\u00020\u0003H\u00c6\u0003J\t\u0010\u0014\u001a\u00020\u0005H\u00c6\u0003J\t\u0010\u0015\u001a\u00020\u0003H\u00c6\u0003J\t\u0010\u0016\u001a\u00020\u0003H\u00c6\u0003J\t\u0010\u0017\u001a\u00020\tH\u00c6\u0003J;\u0010\u0018\u001a\u00020\u00002\b\b\u0002\u0010\u0002\u001a\u00020\u00032\b\b\u0002\u0010\u0004\u001a\u00020\u00052\b\b\u0002\u0010\u0006\u001a\u00020\u00032\b\b\u0002\u0010\u0007\u001a\u00020\u00032\b\b\u0002\u0010\b\u001a\u00020\tH\u00c6\u0001J\u0013\u0010\u0019\u001a\u00020\u001a2\b\u0010\u001b\u001a\u0004\u0018\u00010\u0001H\u00d6\u0003J\t\u0010\u001c\u001a\u00020\u0003H\u00d6\u0001J\t\u0010\u001d\u001a\u00020\u0005H\u00d6\u0001R\u0011\u0010\u0002\u001a\u00020\u0003\u00a2\u0006\b\n\u0000\u001a\u0004\b\u000b\u0010\fR\u0011\u0010\u0004\u001a\u00020\u0005\u00a2\u0006\b\n\u0000\u001a\u0004\b\r\u0010\u000eR\u0011\u0010\u0006\u001a\u00020\u0003\u00a2\u0006\b\n\u0000\u001a\u0004\b\u000f\u0010\fR\u0011\u0010\b\u001a\u00020\t\u00a2\u0006\b\n\u0000\u001a\u0004\b\u0010\u0010\u0011R\u0011\u0010\u0007\u001a\u00020\u0003\u00a2\u0006\b\n\u0000\u001a\u0004\b\u0012\u0010\f\u00a8\u0006\u001e"}, d2={"Ldorkbox/netUtil/ping/PingResult$Response;", "", "bytes", "", "host", "", "icmpSeq", "ttl", "time", "Ljava/time/Duration;", "(ILjava/lang/String;IILjava/time/Duration;)V", "getBytes", "()I", "getHost", "()Ljava/lang/String;", "getIcmpSeq", "getTime", "()Ljava/time/Duration;", "getTtl", "component1", "component2", "component3", "component4", "component5", "copy", "equals", "", "other", "hashCode", "toString", "NetworkUtils"})
    public static final class Response {
        private final int bytes;
        @NotNull
        private final String host;
        private final int icmpSeq;
        private final int ttl;
        @NotNull
        private final Duration time;

        public Response(int bytes, @NotNull String host, int icmpSeq, int ttl, @NotNull Duration time) {
            Intrinsics.checkNotNullParameter((Object)host, (String)"host");
            Intrinsics.checkNotNullParameter((Object)time, (String)"time");
            this.bytes = bytes;
            this.host = host;
            this.icmpSeq = icmpSeq;
            this.ttl = ttl;
            this.time = time;
        }

        public final int getBytes() {
            return this.bytes;
        }

        @NotNull
        public final String getHost() {
            return this.host;
        }

        public final int getIcmpSeq() {
            return this.icmpSeq;
        }

        public final int getTtl() {
            return this.ttl;
        }

        @NotNull
        public final Duration getTime() {
            return this.time;
        }

        public final int component1() {
            return this.bytes;
        }

        @NotNull
        public final String component2() {
            return this.host;
        }

        public final int component3() {
            return this.icmpSeq;
        }

        public final int component4() {
            return this.ttl;
        }

        @NotNull
        public final Duration component5() {
            return this.time;
        }

        @NotNull
        public final Response copy(int bytes, @NotNull String host, int icmpSeq, int ttl, @NotNull Duration time) {
            Intrinsics.checkNotNullParameter((Object)host, (String)"host");
            Intrinsics.checkNotNullParameter((Object)time, (String)"time");
            return new Response(bytes, host, icmpSeq, ttl, time);
        }

        public static /* synthetic */ Response copy$default(Response response, int n, String string, int n2, int n3, Duration duration, int n4, Object object) {
            if ((n4 & 1) != 0) {
                n = response.bytes;
            }
            if ((n4 & 2) != 0) {
                string = response.host;
            }
            if ((n4 & 4) != 0) {
                n2 = response.icmpSeq;
            }
            if ((n4 & 8) != 0) {
                n3 = response.ttl;
            }
            if ((n4 & 0x10) != 0) {
                duration = response.time;
            }
            return response.copy(n, string, n2, n3, duration);
        }

        @NotNull
        public String toString() {
            return "Response(bytes=" + this.bytes + ", host=" + this.host + ", icmpSeq=" + this.icmpSeq + ", ttl=" + this.ttl + ", time=" + this.time + ')';
        }

        public int hashCode() {
            int result = Integer.hashCode(this.bytes);
            result = result * 31 + this.host.hashCode();
            result = result * 31 + Integer.hashCode(this.icmpSeq);
            result = result * 31 + Integer.hashCode(this.ttl);
            result = result * 31 + this.time.hashCode();
            return result;
        }

        public boolean equals(@Nullable Object other) {
            if (this == other) {
                return true;
            }
            if (!(other instanceof Response)) {
                return false;
            }
            Response response = (Response)other;
            if (this.bytes != response.bytes) {
                return false;
            }
            if (!Intrinsics.areEqual((Object)this.host, (Object)response.host)) {
                return false;
            }
            if (this.icmpSeq != response.icmpSeq) {
                return false;
            }
            if (this.ttl != response.ttl) {
                return false;
            }
            return Intrinsics.areEqual((Object)this.time, (Object)response.time);
        }
    }
}

