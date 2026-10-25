/*
 * Decompiled with CFR 0.152.
 * 
 * Could not load the following classes:
 *  kotlin.Metadata
 *  kotlin.jvm.internal.DefaultConstructorMarker
 *  kotlin.jvm.internal.Intrinsics
 *  org.jetbrains.annotations.NotNull
 */
package dorkbox.executor.stream;

import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.io.OutputStream;
import kotlin.Metadata;
import kotlin.jvm.internal.DefaultConstructorMarker;
import kotlin.jvm.internal.Intrinsics;
import org.jetbrains.annotations.NotNull;

@Metadata(mv={1, 6, 0}, k=1, xi=48, d1={"\u00008\n\u0002\u0018\u0002\n\u0002\u0018\u0002\n\u0002\b\u0002\n\u0002\u0018\u0002\n\u0000\n\u0002\u0010\f\n\u0002\b\u0005\n\u0002\u0010\u0002\n\u0002\b\u0004\n\u0002\u0010\u000e\n\u0002\b\u0002\n\u0002\u0010\u0012\n\u0000\n\u0002\u0010\b\n\u0002\b\u0004\b&\u0018\u0000 \u00192\u00020\u0001:\u0001\u0019B\u0005\u00a2\u0006\u0002\u0010\u0002J\b\u0010\u000b\u001a\u00020\fH\u0016J\b\u0010\r\u001a\u00020\fH\u0016J\b\u0010\u000e\u001a\u00020\fH\u0004J\u0010\u0010\u000f\u001a\u00020\f2\u0006\u0010\u0010\u001a\u00020\u0011H$J \u0010\u0012\u001a\u00020\f2\u0006\u0010\u0013\u001a\u00020\u00142\u0006\u0010\u0015\u001a\u00020\u00162\u0006\u0010\u0017\u001a\u00020\u0016H\u0016J\u0010\u0010\u0012\u001a\u00020\f2\u0006\u0010\u0018\u001a\u00020\u0016H\u0016R\u000e\u0010\u0003\u001a\u00020\u0004X\u0082\u0004\u00a2\u0006\u0002\n\u0000R\u001a\u0010\u0005\u001a\u00020\u0006X\u0086\u000e\u00a2\u0006\u000e\n\u0000\u001a\u0004\b\u0007\u0010\b\"\u0004\b\t\u0010\n\u00a8\u0006\u001a"}, d2={"Ldorkbox/executor/stream/LogOutputStream;", "Ljava/io/OutputStream;", "()V", "buffer", "Ljava/io/ByteArrayOutputStream;", "lastReceivedChar", "", "getLastReceivedChar", "()C", "setLastReceivedChar", "(C)V", "close", "", "flush", "processBuffer", "processLine", "line", "", "write", "b", "", "off", "", "len", "cc", "Companion", "Executor"})
public abstract class LogOutputStream
extends OutputStream {
    @NotNull
    public static final Companion Companion = new Companion(null);
    @NotNull
    private final ByteArrayOutputStream buffer = new ByteArrayOutputStream(132);
    private char lastReceivedChar = (char)32;
    private static final int INTIAL_SIZE = 132;
    private static final byte CR = 13;
    private static final byte LF = 10;

    public final char getLastReceivedChar() {
        return this.lastReceivedChar;
    }

    public final void setLastReceivedChar(char c) {
        this.lastReceivedChar = c;
    }

    @Override
    public void write(int cc) throws IOException {
        char c = (char)cc;
        if (c == '\n' || c == '\r') {
            if (c == '\r' || c == '\n' && this.lastReceivedChar != '\r' && this.lastReceivedChar != '\n') {
                this.processBuffer();
            }
        } else {
            this.buffer.write(cc);
        }
        this.lastReceivedChar = c;
    }

    @Override
    public void flush() {
        if (this.buffer.size() > 0) {
            this.processBuffer();
        }
    }

    @Override
    public void close() throws IOException {
        if (this.buffer.size() > 0) {
            this.processBuffer();
        }
        super.close();
    }

    @Override
    public void write(@NotNull byte[] b, int off, int len) throws IOException {
        int offset;
        Intrinsics.checkNotNullParameter((Object)b, (String)"b");
        int blockStartOffset = offset = off;
        int remaining = len;
        while (remaining > 0) {
            while (remaining > 0 && b[offset] != 10 && b[offset] != 13) {
                int n = offset;
                offset = n + 1;
                n = remaining;
                remaining = n + -1;
            }
            int blockLength = offset - blockStartOffset;
            if (blockLength > 0) {
                this.buffer.write(b, blockStartOffset, blockLength);
                this.lastReceivedChar = (char)32;
            }
            while (remaining > 0 && (b[offset] == 10 || b[offset] == 13)) {
                this.write(b[offset]);
                int n = offset;
                offset = n + 1;
                n = remaining;
                remaining = n + -1;
            }
            blockStartOffset = offset;
        }
    }

    protected final void processBuffer() {
        String string2 = this.buffer.toString();
        Intrinsics.checkNotNullExpressionValue((Object)string2, (String)"buffer.toString()");
        this.processLine(string2);
        this.buffer.reset();
    }

    protected abstract void processLine(@NotNull String var1);

    @Metadata(mv={1, 6, 0}, k=1, xi=48, d1={"\u0000\u001a\n\u0002\u0018\u0002\n\u0002\u0010\u0000\n\u0002\b\u0002\n\u0002\u0010\u0005\n\u0000\n\u0002\u0010\b\n\u0002\b\u0002\b\u0086\u0003\u0018\u00002\u00020\u0001B\u0007\b\u0002\u00a2\u0006\u0002\u0010\u0002R\u000e\u0010\u0003\u001a\u00020\u0004X\u0082T\u00a2\u0006\u0002\n\u0000R\u000e\u0010\u0005\u001a\u00020\u0006X\u0082T\u00a2\u0006\u0002\n\u0000R\u000e\u0010\u0007\u001a\u00020\u0004X\u0082T\u00a2\u0006\u0002\n\u0000\u00a8\u0006\b"}, d2={"Ldorkbox/executor/stream/LogOutputStream$Companion;", "", "()V", "CR", "", "INTIAL_SIZE", "", "LF", "Executor"})
    public static final class Companion {
        private Companion() {
        }

        public /* synthetic */ Companion(DefaultConstructorMarker $constructor_marker) {
            this();
        }
    }
}

