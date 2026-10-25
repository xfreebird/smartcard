/*
 * Decompiled with CFR 0.152.
 * 
 * Could not load the following classes:
 *  kotlin.Metadata
 *  kotlin.jvm.internal.Intrinsics
 *  net.schmizz.sshj.SSHClient
 *  net.schmizz.sshj.common.Message
 *  net.schmizz.sshj.common.SSHPacket
 *  net.schmizz.sshj.connection.channel.direct.Session
 *  net.schmizz.sshj.connection.channel.direct.Session$Command
 *  org.jetbrains.annotations.NotNull
 */
package dorkbox.executor;

import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;
import kotlin.Metadata;
import kotlin.jvm.internal.Intrinsics;
import net.schmizz.sshj.SSHClient;
import net.schmizz.sshj.common.Message;
import net.schmizz.sshj.common.SSHPacket;
import net.schmizz.sshj.connection.channel.direct.Session;
import org.jetbrains.annotations.NotNull;

/*
 * Multiple versions of this class in jar - see https://www.benf.org/other/cfr/multi-version-jar.html
 */
@Metadata(mv={1, 6, 0}, k=1, xi=48, d1={"\u0000<\n\u0002\u0018\u0002\n\u0002\u0018\u0002\n\u0000\n\u0002\u0018\u0002\n\u0000\n\u0002\u0018\u0002\n\u0000\n\u0002\u0018\u0002\n\u0002\b\u0004\n\u0002\u0018\u0002\n\u0002\b\u0003\n\u0002\u0018\u0002\n\u0002\b\u0003\n\u0002\u0010\u0002\n\u0000\n\u0002\u0010\b\n\u0002\b\u0005\u0018\u00002\u00020\u0001B\u001d\u0012\u0006\u0010\u0002\u001a\u00020\u0003\u0012\u0006\u0010\u0004\u001a\u00020\u0005\u0012\u0006\u0010\u0006\u001a\u00020\u0007\u00a2\u0006\u0002\u0010\bJ\b\u0010\u0013\u001a\u00020\u0014H\u0016J\b\u0010\u0015\u001a\u00020\u0016H\u0016J\b\u0010\u0017\u001a\u00020\fH\u0016J\b\u0010\u0018\u001a\u00020\fH\u0016J\b\u0010\u0019\u001a\u00020\u0010H\u0016J\b\u0010\u001a\u001a\u00020\u0016H\u0016R\u0011\u0010\u0006\u001a\u00020\u0007\u00a2\u0006\b\n\u0000\u001a\u0004\b\t\u0010\nR\u0016\u0010\u000b\u001a\n \r*\u0004\u0018\u00010\f0\fX\u0082\u0004\u00a2\u0006\u0002\n\u0000R\u0016\u0010\u000e\u001a\n \r*\u0004\u0018\u00010\f0\fX\u0082\u0004\u00a2\u0006\u0002\n\u0000R\u0016\u0010\u000f\u001a\n \r*\u0004\u0018\u00010\u00100\u0010X\u0082\u0004\u00a2\u0006\u0002\n\u0000R\u0011\u0010\u0004\u001a\u00020\u0005\u00a2\u0006\b\n\u0000\u001a\u0004\b\u0011\u0010\u0012R\u000e\u0010\u0002\u001a\u00020\u0003X\u0082\u0004\u00a2\u0006\u0002\n\u0000\u00a8\u0006\u001b"}, d2={"Ldorkbox/executor/SshProcess;", "Ljava/lang/Process;", "ssh", "Lnet/schmizz/sshj/SSHClient;", "session", "Lnet/schmizz/sshj/connection/channel/direct/Session;", "command", "Lnet/schmizz/sshj/connection/channel/direct/Session$Command;", "(Lnet/schmizz/sshj/SSHClient;Lnet/schmizz/sshj/connection/channel/direct/Session;Lnet/schmizz/sshj/connection/channel/direct/Session$Command;)V", "getCommand", "()Lnet/schmizz/sshj/connection/channel/direct/Session$Command;", "errStream", "Ljava/io/InputStream;", "kotlin.jvm.PlatformType", "inputStream", "outputStream", "Ljava/io/OutputStream;", "getSession", "()Lnet/schmizz/sshj/connection/channel/direct/Session;", "destroy", "", "exitValue", "", "getErrorStream", "getInputStream", "getOutputStream", "waitFor", "Executor"})
public final class SshProcess
extends Process {
    @NotNull
    private final SSHClient ssh;
    @NotNull
    private final Session session;
    @NotNull
    private final Session.Command command;
    private final OutputStream outputStream;
    private final InputStream inputStream;
    private final InputStream errStream;

    public SshProcess(@NotNull SSHClient ssh, @NotNull Session session, @NotNull Session.Command command) {
        Intrinsics.checkNotNullParameter((Object)ssh, (String)"ssh");
        Intrinsics.checkNotNullParameter((Object)session, (String)"session");
        Intrinsics.checkNotNullParameter((Object)command, (String)"command");
        this.ssh = ssh;
        this.session = session;
        this.command = command;
        this.outputStream = this.command.getOutputStream();
        this.inputStream = this.command.getInputStream();
        this.errStream = this.command.getErrorStream();
    }

    @NotNull
    public final Session getSession() {
        return this.session;
    }

    @NotNull
    public final Session.Command getCommand() {
        return this.command;
    }

    @Override
    @NotNull
    public OutputStream getOutputStream() {
        OutputStream outputStream = this.outputStream;
        Intrinsics.checkNotNullExpressionValue((Object)outputStream, (String)"outputStream");
        return outputStream;
    }

    @Override
    @NotNull
    public InputStream getInputStream() {
        InputStream inputStream = this.inputStream;
        Intrinsics.checkNotNullExpressionValue((Object)inputStream, (String)"inputStream");
        return inputStream;
    }

    @Override
    @NotNull
    public InputStream getErrorStream() {
        InputStream inputStream = this.errStream;
        Intrinsics.checkNotNullExpressionValue((Object)inputStream, (String)"errStream");
        return inputStream;
    }

    @Override
    public int waitFor() throws InterruptedException {
        this.command.join();
        this.destroy();
        return this.exitValue();
    }

    @Override
    public int exitValue() {
        if (!this.command.isOpen()) {
            Integer n = this.command.getExitStatus();
            Intrinsics.checkNotNullExpressionValue((Object)n, (String)"command.exitStatus");
            return ((Number)n).intValue();
        }
        return -1;
    }

    @Override
    public void destroy() {
        try {
            this.ssh.getTransport().write((SSHPacket)new SSHPacket(Message.CHANNEL_EOF).putUInt32((long)this.session.getRecipient()));
        }
        catch (IOException iOException) {
            // empty catch block
        }
        try {
            this.session.close();
        }
        catch (IOException iOException) {
            // empty catch block
        }
        this.ssh.disconnect();
    }
}

