/*
 * Decompiled with CFR 0.152.
 * 
 * Could not load the following classes:
 *  kotlin.Metadata
 *  kotlin.ResultKt
 *  kotlin.Unit
 *  kotlin.collections.CollectionsKt
 *  kotlin.coroutines.Continuation
 *  kotlin.coroutines.intrinsics.IntrinsicsKt
 *  kotlin.jvm.JvmOverloads
 *  kotlin.jvm.functions.Function2
 *  kotlin.jvm.internal.DefaultConstructorMarker
 *  kotlin.jvm.internal.Intrinsics
 *  kotlinx.coroutines.BuildersKt
 *  kotlinx.coroutines.CoroutineScope
 *  net.schmizz.sshj.Config
 *  net.schmizz.sshj.DefaultConfig
 *  net.schmizz.sshj.SSHClient
 *  net.schmizz.sshj.common.LoggerFactory
 *  net.schmizz.sshj.connection.channel.direct.Session
 *  net.schmizz.sshj.connection.channel.direct.Session$Command
 *  net.schmizz.sshj.transport.verification.HostKeyVerifier
 *  net.schmizz.sshj.transport.verification.PromiscuousVerifier
 *  org.jetbrains.annotations.NotNull
 *  org.jetbrains.annotations.Nullable
 *  org.slf4j.Logger
 */
package dorkbox.executor;

import dorkbox.executor.DeferredProcessResult;
import dorkbox.executor.Executor;
import dorkbox.executor.LogHelper;
import dorkbox.executor.SshProcess;
import dorkbox.executor.exceptions.InvalidExitValueException;
import dorkbox.executor.processResults.SyncProcessResult;
import java.io.File;
import java.io.IOException;
import java.util.Arrays;
import java.util.List;
import java.util.concurrent.TimeUnit;
import java.util.concurrent.TimeoutException;
import kotlin.Metadata;
import kotlin.ResultKt;
import kotlin.Unit;
import kotlin.collections.CollectionsKt;
import kotlin.coroutines.Continuation;
import kotlin.coroutines.intrinsics.IntrinsicsKt;
import kotlin.jvm.JvmOverloads;
import kotlin.jvm.functions.Function2;
import kotlin.jvm.internal.DefaultConstructorMarker;
import kotlin.jvm.internal.Intrinsics;
import kotlinx.coroutines.BuildersKt;
import kotlinx.coroutines.CoroutineScope;
import net.schmizz.sshj.Config;
import net.schmizz.sshj.DefaultConfig;
import net.schmizz.sshj.SSHClient;
import net.schmizz.sshj.common.LoggerFactory;
import net.schmizz.sshj.connection.channel.direct.Session;
import net.schmizz.sshj.transport.verification.HostKeyVerifier;
import net.schmizz.sshj.transport.verification.PromiscuousVerifier;
import org.jetbrains.annotations.NotNull;
import org.jetbrains.annotations.Nullable;
import org.slf4j.Logger;

@Metadata(mv={1, 6, 0}, k=1, xi=48, d1={"\u0000p\n\u0002\u0018\u0002\n\u0002\u0010\u0000\n\u0000\n\u0002\u0018\u0002\n\u0002\b\u0004\n\u0002\u0010\u000e\n\u0002\b\u0003\n\u0002\u0010\b\n\u0002\b\u0002\n\u0002\u0018\u0002\n\u0000\n\u0002\u0010\u000b\n\u0002\b\u0002\n\u0002\u0018\u0002\n\u0002\b\u0002\n\u0002\u0010\u0011\n\u0000\n\u0002\u0010\u001c\n\u0002\b\b\n\u0002\u0018\u0002\n\u0000\n\u0002\u0010\t\n\u0000\n\u0002\u0018\u0002\n\u0002\b\u0002\n\u0002\u0018\u0002\n\u0002\b\u0002\n\u0002\u0018\u0002\n\u0000\n\u0002\u0018\u0002\n\u0002\b\u0003\u0018\u0000 02\u00020\u0001:\u00010B\r\u0012\u0006\u0010\u0002\u001a\u00020\u0003\u00a2\u0006\u0002\u0010\u0004J\u001f\u0010\u0015\u001a\u00020\u00002\u0012\u0010\u0016\u001a\n\u0012\u0006\b\u0001\u0012\u00020\b0\u0017\"\u00020\b\u00a2\u0006\u0002\u0010\u0018J\u0014\u0010\u0015\u001a\u00020\u00002\f\u0010\u0016\u001a\b\u0012\u0004\u0012\u00020\b0\u0019J\u001f\u0010\u001a\u001a\u00020\u00002\u0012\u0010\u001a\u001a\n\u0012\u0006\b\u0001\u0012\u00020\b0\u0017\"\u00020\b\u00a2\u0006\u0002\u0010\u0018J\u0014\u0010\u001a\u001a\u00020\u00002\f\u0010\u001a\u001a\b\u0012\u0004\u0012\u00020\b0\u0019J\u000e\u0010\u001b\u001a\u00020\u00002\u0006\u0010\u001c\u001a\u00020\bJ\u0006\u0010\u001d\u001a\u00020\u0000J\u000e\u0010\u0007\u001a\u00020\u00002\u0006\u0010\u0007\u001a\u00020\bJ\u0006\u0010\u001e\u001a\u00020\bJ\u000e\u0010\n\u001a\u00020\u00002\u0006\u0010\n\u001a\u00020\bJ\u000e\u0010\u000b\u001a\u00020\u00002\u0006\u0010\u000b\u001a\u00020\fJ\u000e\u0010\r\u001a\u00020\u00002\u0006\u0010\r\u001a\u00020\bJ\u000e\u0010\u001f\u001a\u00020\u00002\u0006\u0010\u0013\u001a\u00020\u0014J\u000e\u0010 \u001a\u00020\u00002\u0006\u0010\t\u001a\u00020\bJ\u0006\u0010\u000e\u001a\u00020\u000fJ%\u0010!\u001a\u00020\"2\b\b\u0002\u0010#\u001a\u00020$2\b\b\u0002\u0010%\u001a\u00020&H\u0087@\u00f8\u0001\u0000\u00a2\u0006\u0002\u0010'J\u001c\u0010(\u001a\u00020)2\b\b\u0002\u0010#\u001a\u00020$2\b\b\u0002\u0010%\u001a\u00020&H\u0007J\u001c\u0010*\u001a\u00020\"2\b\b\u0002\u0010#\u001a\u00020$2\b\b\u0002\u0010%\u001a\u00020&H\u0007J'\u0010+\u001a\u00020,2\u0006\u0010#\u001a\u00020$2\u0006\u0010%\u001a\u00020&2\b\u0010-\u001a\u0004\u0018\u00010.H\u0000\u00a2\u0006\u0002\b/J\u000e\u0010\u0012\u001a\u00020\u00002\u0006\u0010\u0012\u001a\u00020\bR\u0011\u0010\u0002\u001a\u00020\u0003\u00a2\u0006\b\n\u0000\u001a\u0004\b\u0005\u0010\u0006R\u0010\u0010\u0007\u001a\u0004\u0018\u00010\bX\u0082\u000e\u00a2\u0006\u0002\n\u0000R\u0010\u0010\t\u001a\u0004\u0018\u00010\bX\u0082\u000e\u00a2\u0006\u0002\n\u0000R\u0010\u0010\n\u001a\u0004\u0018\u00010\bX\u0082\u000e\u00a2\u0006\u0002\n\u0000R\u000e\u0010\u000b\u001a\u00020\fX\u0082\u000e\u00a2\u0006\u0002\n\u0000R\u0010\u0010\r\u001a\u0004\u0018\u00010\bX\u0082\u000e\u00a2\u0006\u0002\n\u0000R\u000e\u0010\u000e\u001a\u00020\u000fX\u0082.\u00a2\u0006\u0002\n\u0000R\u000e\u0010\u0010\u001a\u00020\u0011X\u0082\u000e\u00a2\u0006\u0002\n\u0000R\u0010\u0010\u0012\u001a\u0004\u0018\u00010\bX\u0082\u000e\u00a2\u0006\u0002\n\u0000R\u0010\u0010\u0013\u001a\u0004\u0018\u00010\u0014X\u0082\u000e\u00a2\u0006\u0002\n\u0000\u0082\u0002\u0004\n\u0002\b\u0019\u00a8\u00061"}, d2={"Ldorkbox/executor/SshExecOptions;", "", "executor", "Ldorkbox/executor/Executor;", "(Ldorkbox/executor/Executor;)V", "getExecutor", "()Ldorkbox/executor/Executor;", "host", "", "knownHostsFile", "password", "port", "", "privateKeyFile", "ssh", "Lnet/schmizz/sshj/SSHClient;", "strictHostCheck", "", "userName", "verifier", "Lnet/schmizz/sshj/transport/verification/HostKeyVerifier;", "addArg", "arguments", "", "([Ljava/lang/String;)Ldorkbox/executor/SshExecOptions;", "", "command", "commandSplit", "commandWithArgs", "disableStrictHostChecking", "info", "setHostVerifier", "setKnownHostsFile", "start", "Ldorkbox/executor/processResults/SyncProcessResult;", "timeout", "", "timeoutUnit", "Ljava/util/concurrent/TimeUnit;", "(JLjava/util/concurrent/TimeUnit;Lkotlin/coroutines/Continuation;)Ljava/lang/Object;", "startAsync", "Ldorkbox/executor/DeferredProcessResult;", "startBlocking", "startProcess", "Ldorkbox/executor/SshProcess;", "logger", "Lorg/slf4j/Logger;", "startProcess$Executor", "Companion", "Executor"})
public final class SshExecOptions {
    @NotNull
    public static final Companion Companion = new Companion(null);
    @NotNull
    private final Executor executor;
    @Nullable
    private String host;
    private int port;
    @Nullable
    private String userName;
    @Nullable
    private String password;
    @Nullable
    private String privateKeyFile;
    @Nullable
    private HostKeyVerifier verifier;
    private boolean strictHostCheck;
    @Nullable
    private String knownHostsFile;
    private SSHClient ssh;

    public SshExecOptions(@NotNull Executor executor) {
        Intrinsics.checkNotNullParameter((Object)executor, (String)"executor");
        this.executor = executor;
        this.port = 22;
        this.strictHostCheck = true;
    }

    @NotNull
    public final Executor getExecutor() {
        return this.executor;
    }

    @NotNull
    public final SshProcess startProcess$Executor(long timeout, @NotNull TimeUnit timeoutUnit, @Nullable Logger logger) {
        Object object;
        SSHClient sSHClient;
        Intrinsics.checkNotNullParameter((Object)((Object)timeoutUnit), (String)"timeoutUnit");
        LogHelper.INSTANCE.fixSshLogger(logger);
        LoggerFactory factory = LogHelper.INSTANCE.getLogFactory(logger);
        DefaultConfig config2 = new DefaultConfig(factory){
            final /* synthetic */ LoggerFactory $factory;
            {
                this.$factory = $factory;
            }

            public void setLoggerFactory(@NotNull LoggerFactory loggerFactory) {
                Intrinsics.checkNotNullParameter((Object)loggerFactory, (String)"loggerFactory");
                super.setLoggerFactory(this.$factory);
            }

            @NotNull
            public LoggerFactory getLoggerFactory() {
                return this.$factory;
            }
        };
        config2.setLoggerFactory(factory);
        this.ssh = new SSHClient((Config)config2);
        if (this.strictHostCheck) {
            if (this.knownHostsFile != null) {
                SSHClient sSHClient2 = this.ssh;
                if (sSHClient2 == null) {
                    Intrinsics.throwUninitializedPropertyAccessException((String)"ssh");
                    sSHClient2 = null;
                }
                String string2 = this.knownHostsFile;
                Intrinsics.checkNotNull((Object)string2);
                sSHClient2.loadKnownHosts(new File(string2));
            } else {
                SSHClient sSHClient3 = this.ssh;
                if (sSHClient3 == null) {
                    Intrinsics.throwUninitializedPropertyAccessException((String)"ssh");
                    sSHClient3 = null;
                }
                sSHClient3.addHostKeyVerifier(this.verifier);
            }
        } else {
            SSHClient sSHClient4 = this.ssh;
            if (sSHClient4 == null) {
                Intrinsics.throwUninitializedPropertyAccessException((String)"ssh");
                sSHClient4 = null;
            }
            sSHClient4.addHostKeyVerifier((HostKeyVerifier)new PromiscuousVerifier());
        }
        if (timeout > 0L) {
            SSHClient sSHClient5 = this.ssh;
            if (sSHClient5 == null) {
                Intrinsics.throwUninitializedPropertyAccessException((String)"ssh");
                sSHClient5 = null;
            }
            sSHClient5.setConnectTimeout((int)timeoutUnit.toMillis(timeout));
        }
        if ((sSHClient = this.ssh) == null) {
            Intrinsics.throwUninitializedPropertyAccessException((String)"ssh");
            sSHClient = null;
        }
        sSHClient.connect(this.host, this.port);
        if (this.privateKeyFile != null) {
            SSHClient sSHClient6 = this.ssh;
            if (sSHClient6 == null) {
                Intrinsics.throwUninitializedPropertyAccessException((String)"ssh");
                sSHClient6 = null;
            }
            object = new String[]{this.privateKeyFile};
            sSHClient6.authPublickey(this.userName, object);
        } else {
            SSHClient sSHClient7 = this.ssh;
            if (sSHClient7 == null) {
                Intrinsics.throwUninitializedPropertyAccessException((String)"ssh");
                sSHClient7 = null;
            }
            sSHClient7.authPassword(this.userName, this.password);
        }
        try {
            SSHClient sSHClient8 = this.ssh;
            if (sSHClient8 == null) {
                Intrinsics.throwUninitializedPropertyAccessException((String)"ssh");
                sSHClient8 = null;
            }
            Session session = sSHClient8.startSession();
            List<String> list = this.executor.getBuilder$Executor().command();
            Intrinsics.checkNotNullExpressionValue(list, (String)"executor.builder.command()");
            String execCommand = CollectionsKt.joinToString$default((Iterable)list, (CharSequence)" ", null, null, (int)0, null, null, (int)62, null);
            Session.Command command = session.exec(execCommand);
            SSHClient sSHClient9 = this.ssh;
            if (sSHClient9 == null) {
                Intrinsics.throwUninitializedPropertyAccessException((String)"ssh");
                sSHClient9 = null;
            }
            Intrinsics.checkNotNullExpressionValue((Object)session, (String)"session");
            Intrinsics.checkNotNullExpressionValue((Object)command, (String)"command");
            object = new SshProcess(sSHClient9, session, command);
        }
        catch (Exception e) {
            throw new IOException(e.getMessage(), e);
        }
        return object;
    }

    @NotNull
    public final SSHClient ssh() {
        SSHClient sSHClient = this.ssh;
        if (sSHClient == null) {
            Intrinsics.throwUninitializedPropertyAccessException((String)"ssh");
            sSHClient = null;
        }
        return sSHClient;
    }

    @NotNull
    public final SshExecOptions userName(@NotNull String userName) {
        Intrinsics.checkNotNullParameter((Object)userName, (String)"userName");
        this.userName = userName;
        return this;
    }

    @NotNull
    public final SshExecOptions host(@NotNull String host) {
        Intrinsics.checkNotNullParameter((Object)host, (String)"host");
        this.host = host;
        return this;
    }

    @NotNull
    public final SshExecOptions port(int port) {
        this.port = port;
        return this;
    }

    @NotNull
    public final SshExecOptions privateKeyFile(@NotNull String privateKeyFile) {
        Intrinsics.checkNotNullParameter((Object)privateKeyFile, (String)"privateKeyFile");
        this.privateKeyFile = privateKeyFile;
        return this;
    }

    @NotNull
    public final SshExecOptions password(@NotNull String password) {
        Intrinsics.checkNotNullParameter((Object)password, (String)"password");
        this.password = password;
        return this;
    }

    @NotNull
    public final SshExecOptions disableStrictHostChecking() {
        this.strictHostCheck = false;
        return this;
    }

    @NotNull
    public final SshExecOptions setHostVerifier(@NotNull HostKeyVerifier verifier) {
        Intrinsics.checkNotNullParameter((Object)verifier, (String)"verifier");
        this.verifier = verifier;
        return this;
    }

    @NotNull
    public final SshExecOptions setKnownHostsFile(@NotNull String knownHostsFile) {
        Intrinsics.checkNotNullParameter((Object)knownHostsFile, (String)"knownHostsFile");
        this.knownHostsFile = knownHostsFile;
        return this;
    }

    @NotNull
    public final SshExecOptions command(String ... command) {
        Intrinsics.checkNotNullParameter((Object)command, (String)"command");
        this.executor.command((Iterable<String>)Executor.Companion.fixArguments$Executor(CollectionsKt.listOf((Object[])Arrays.copyOf(command, command.length))));
        return this;
    }

    @NotNull
    public final SshExecOptions command(@NotNull Iterable<String> command) {
        Intrinsics.checkNotNullParameter(command, (String)"command");
        this.executor.command(command);
        return this;
    }

    @NotNull
    public final SshExecOptions commandSplit(@NotNull String commandWithArgs) {
        Intrinsics.checkNotNullParameter((Object)commandWithArgs, (String)"commandWithArgs");
        this.executor.commandSplit(commandWithArgs);
        return this;
    }

    @NotNull
    public final SshExecOptions addArg(String ... arguments) {
        Intrinsics.checkNotNullParameter((Object)arguments, (String)"arguments");
        this.executor.addArg(Arrays.copyOf(arguments, arguments.length));
        return this;
    }

    @NotNull
    public final SshExecOptions addArg(@NotNull Iterable<String> arguments) {
        Intrinsics.checkNotNullParameter(arguments, (String)"arguments");
        this.executor.addArg(arguments);
        return this;
    }

    @NotNull
    public final String info() {
        return this.userName + '@' + this.host + ':' + this.port;
    }

    @JvmOverloads
    @Nullable
    public final Object start(long timeout, @NotNull TimeUnit timeoutUnit, @NotNull Continuation<? super SyncProcessResult> $completion) {
        return this.getExecutor().start(timeout, timeoutUnit, $completion);
    }

    public static /* synthetic */ Object start$default(SshExecOptions sshExecOptions, long l, TimeUnit timeUnit, Continuation continuation, int n, Object object) {
        if ((n & 1) != 0) {
            l = 0L;
        }
        if ((n & 2) != 0) {
            timeUnit = TimeUnit.SECONDS;
        }
        return sshExecOptions.start(l, timeUnit, (Continuation<? super SyncProcessResult>)continuation);
    }

    @JvmOverloads
    @NotNull
    public final DeferredProcessResult startAsync(long timeout, @NotNull TimeUnit timeoutUnit) throws IOException {
        Intrinsics.checkNotNullParameter((Object)((Object)timeoutUnit), (String)"timeoutUnit");
        return this.executor.startAsync(timeout, timeoutUnit);
    }

    public static /* synthetic */ DeferredProcessResult startAsync$default(SshExecOptions sshExecOptions, long l, TimeUnit timeUnit, int n, Object object) throws IOException {
        if ((n & 1) != 0) {
            l = 0L;
        }
        if ((n & 2) != 0) {
            timeUnit = TimeUnit.SECONDS;
        }
        return sshExecOptions.startAsync(l, timeUnit);
    }

    @JvmOverloads
    @NotNull
    public final SyncProcessResult startBlocking(long timeout, @NotNull TimeUnit timeoutUnit) throws IOException, InterruptedException, TimeoutException, InvalidExitValueException {
        Intrinsics.checkNotNullParameter((Object)((Object)timeoutUnit), (String)"timeoutUnit");
        return (SyncProcessResult)BuildersKt.runBlocking$default(null, (Function2)((Function2)new Function2<CoroutineScope, Continuation<? super SyncProcessResult>, Object>(this, timeout, timeoutUnit, null){
            int label;
            final /* synthetic */ SshExecOptions this$0;
            final /* synthetic */ long $timeout;
            final /* synthetic */ TimeUnit $timeoutUnit;
            {
                this.this$0 = $receiver;
                this.$timeout = $timeout;
                this.$timeoutUnit = $timeoutUnit;
                super(2, $completion);
            }

            /*
             * WARNING - void declaration
             * Enabled force condition propagation
             * Lifted jumps to return sites
             */
            @Nullable
            public final Object invokeSuspend(@NotNull Object object) {
                Object object2 = IntrinsicsKt.getCOROUTINE_SUSPENDED();
                switch (this.label) {
                    case 0: {
                        ResultKt.throwOnFailure((Object)object);
                        this.label = 1;
                        Object object3 = this.this$0.start(this.$timeout, this.$timeoutUnit, (Continuation<? super SyncProcessResult>)((Continuation)this));
                        if (object3 != object2) return object3;
                        return object2;
                    }
                    case 1: {
                        void $result;
                        ResultKt.throwOnFailure((Object)$result);
                        Object object3 = $result;
                        return object3;
                    }
                }
                throw new IllegalStateException("call to 'resume' before 'invoke' with coroutine");
            }

            @NotNull
            public final Continuation<Unit> create(@Nullable Object value, @NotNull Continuation<?> $completion) {
                return (Continuation)new /* invalid duplicate definition of identical inner class */;
            }

            @Nullable
            public final Object invoke(@NotNull CoroutineScope p1, @Nullable Continuation<? super SyncProcessResult> p2) {
                return (this.create(p1, p2)).invokeSuspend(Unit.INSTANCE);
            }
        }), (int)1, null);
    }

    public static /* synthetic */ SyncProcessResult startBlocking$default(SshExecOptions sshExecOptions, long l, TimeUnit timeUnit, int n, Object object) throws IOException, InterruptedException, TimeoutException, InvalidExitValueException {
        if ((n & 1) != 0) {
            l = 0L;
        }
        if ((n & 2) != 0) {
            timeUnit = TimeUnit.SECONDS;
        }
        return sshExecOptions.startBlocking(l, timeUnit);
    }

    @JvmOverloads
    @Nullable
    public final Object start(long timeout, @NotNull Continuation<? super SyncProcessResult> $completion) {
        return SshExecOptions.start$default(this, timeout, null, $completion, 2, null);
    }

    @JvmOverloads
    @Nullable
    public final Object start(@NotNull Continuation<? super SyncProcessResult> $completion) {
        return SshExecOptions.start$default(this, 0L, null, $completion, 3, null);
    }

    @JvmOverloads
    @NotNull
    public final DeferredProcessResult startAsync(long timeout) throws IOException {
        return SshExecOptions.startAsync$default(this, timeout, null, 2, null);
    }

    @JvmOverloads
    @NotNull
    public final DeferredProcessResult startAsync() throws IOException {
        return SshExecOptions.startAsync$default(this, 0L, null, 3, null);
    }

    @JvmOverloads
    @NotNull
    public final SyncProcessResult startBlocking(long timeout) throws IOException, InterruptedException, TimeoutException, InvalidExitValueException {
        return SshExecOptions.startBlocking$default(this, timeout, null, 2, null);
    }

    @JvmOverloads
    @NotNull
    public final SyncProcessResult startBlocking() throws IOException, InterruptedException, TimeoutException, InvalidExitValueException {
        return SshExecOptions.startBlocking$default(this, 0L, null, 3, null);
    }

    static {
        try {
            Class.forName("net.schmizz.sshj.SSHClient");
        }
        catch (Exception e) {
            throw new RuntimeException("Unable to execute SSH commands. The SSHJ library is not available. \n\nFor example, implementation(\"com.hierynomus:sshj:0.31.0\") as a dependency will add this library. \nYou might need to use a more recent version, as 0.31.0 might not be the latest available.", e);
        }
    }

    @Metadata(mv={1, 6, 0}, k=1, xi=48, d1={"\u0000\f\n\u0002\u0018\u0002\n\u0002\u0010\u0000\n\u0002\b\u0002\b\u0086\u0003\u0018\u00002\u00020\u0001B\u0007\b\u0002\u00a2\u0006\u0002\u0010\u0002\u00a8\u0006\u0003"}, d2={"Ldorkbox/executor/SshExecOptions$Companion;", "", "()V", "Executor"})
    public static final class Companion {
        private Companion() {
        }

        public /* synthetic */ Companion(DefaultConstructorMarker $constructor_marker) {
            this();
        }
    }
}

