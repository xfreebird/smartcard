/*
 * Decompiled with CFR 0.152.
 * 
 * Could not load the following classes:
 *  kotlin.Metadata
 */
package dorkbox.executor.stream.slf4j;

import kotlin.Metadata;

@Metadata(mv={1, 6, 0}, k=1, xi=48, d1={"\u0000\f\n\u0002\u0018\u0002\n\u0002\u0010\u0010\n\u0002\b\u0007\b\u0086\u0001\u0018\u00002\b\u0012\u0004\u0012\u00020\u00000\u0001B\u0007\b\u0002\u00a2\u0006\u0002\u0010\u0002j\u0002\b\u0003j\u0002\b\u0004j\u0002\b\u0005j\u0002\b\u0006j\u0002\b\u0007\u00a8\u0006\b"}, d2={"Ldorkbox/executor/stream/slf4j/Level;", "", "(Ljava/lang/String;I)V", "TRACE", "DEBUG", "INFO", "WARN", "ERROR", "Executor"})
public final class Level
extends Enum<Level> {
    public static final /* enum */ Level TRACE = new Level();
    public static final /* enum */ Level DEBUG = new Level();
    public static final /* enum */ Level INFO = new Level();
    public static final /* enum */ Level WARN = new Level();
    public static final /* enum */ Level ERROR = new Level();
    private static final /* synthetic */ Level[] $VALUES;

    public static Level[] values() {
        return (Level[])$VALUES.clone();
    }

    public static Level valueOf(String value) {
        return Enum.valueOf(Level.class, value);
    }

    static {
        $VALUES = levelArray = new Level[]{Level.TRACE, Level.DEBUG, Level.INFO, Level.WARN, Level.ERROR};
    }
}

