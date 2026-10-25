/*
 * Decompiled with CFR 0.152.
 * 
 * Could not load the following classes:
 *  dorkbox.updates.Updates
 *  kotlin.Metadata
 *  kotlin.ResultKt
 *  kotlin.Unit
 *  kotlin.collections.ArraysKt
 *  kotlin.collections.CollectionsKt
 *  kotlin.coroutines.Continuation
 *  kotlin.coroutines.CoroutineContext
 *  kotlin.coroutines.intrinsics.IntrinsicsKt
 *  kotlin.io.CloseableKt
 *  kotlin.jvm.JvmOverloads
 *  kotlin.jvm.functions.Function1
 *  kotlin.jvm.functions.Function2
 *  kotlin.jvm.internal.DefaultConstructorMarker
 *  kotlin.jvm.internal.Intrinsics
 *  kotlin.jvm.internal.SpreadBuilder
 *  kotlin.text.Regex
 *  kotlin.text.StringsKt
 *  kotlinx.coroutines.BuildersKt
 *  kotlinx.coroutines.CoroutineScope
 *  kotlinx.coroutines.CoroutineScopeKt
 *  kotlinx.coroutines.Dispatchers
 *  org.jetbrains.annotations.NotNull
 *  org.jetbrains.annotations.Nullable
 *  org.slf4j.Logger
 *  org.slf4j.LoggerFactory
 */
package dorkbox.executor;

import dorkbox.executor.DeferredProcessResult;
import dorkbox.executor.Executor;
import dorkbox.executor.JvmExecOptions;
import dorkbox.executor.LogHelper;
import dorkbox.executor.Params;
import dorkbox.executor.ProcessAttributes;
import dorkbox.executor.SshExecOptions;
import dorkbox.executor.exceptions.InvalidExitValueException;
import dorkbox.executor.exceptions.ProcessInitException;
import dorkbox.executor.listener.CompositeProcessListener;
import dorkbox.executor.listener.DestroyerListenerAdapter;
import dorkbox.executor.listener.ProcessDestroyer;
import dorkbox.executor.listener.ProcessListener;
import dorkbox.executor.listener.ShutdownHookProcessDestroyer;
import dorkbox.executor.processResults.ProcessResult;
import dorkbox.executor.processResults.SyncProcessResult;
import dorkbox.executor.stop.DestroyProcessStopper;
import dorkbox.executor.stop.NopProcessStopper;
import dorkbox.executor.stop.ProcessStopper;
import dorkbox.executor.stream.CallerLoggerUtil;
import dorkbox.executor.stream.IOStreamHandler;
import dorkbox.executor.stream.NopPumpStreamHandler;
import dorkbox.executor.stream.nopStreams.NopInputStream;
import dorkbox.executor.stream.nopStreams.NopOutputStream;
import dorkbox.executor.stream.slf4j.Slf4jStream;
import dorkbox.updates.Updates;
import java.io.ByteArrayOutputStream;
import java.io.Closeable;
import java.io.File;
import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.Collection;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.ListIterator;
import java.util.Locale;
import java.util.Map;
import java.util.Scanner;
import java.util.Set;
import java.util.concurrent.TimeUnit;
import java.util.concurrent.TimeoutException;
import kotlin.Metadata;
import kotlin.ResultKt;
import kotlin.Unit;
import kotlin.collections.ArraysKt;
import kotlin.collections.CollectionsKt;
import kotlin.coroutines.Continuation;
import kotlin.coroutines.CoroutineContext;
import kotlin.coroutines.intrinsics.IntrinsicsKt;
import kotlin.io.CloseableKt;
import kotlin.jvm.JvmOverloads;
import kotlin.jvm.functions.Function1;
import kotlin.jvm.functions.Function2;
import kotlin.jvm.internal.DefaultConstructorMarker;
import kotlin.jvm.internal.Intrinsics;
import kotlin.jvm.internal.SpreadBuilder;
import kotlin.text.Regex;
import kotlin.text.StringsKt;
import kotlinx.coroutines.BuildersKt;
import kotlinx.coroutines.CoroutineScope;
import kotlinx.coroutines.CoroutineScopeKt;
import kotlinx.coroutines.Dispatchers;
import org.jetbrains.annotations.NotNull;
import org.jetbrains.annotations.Nullable;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

@Metadata(mv={1, 6, 0}, k=1, xi=48, d1={"\u0000\u00e4\u0001\n\u0002\u0018\u0002\n\u0002\u0010\u0000\n\u0002\b\u0002\n\u0002\u0010\u001c\n\u0002\u0010\u000e\n\u0000\n\u0002\u0010\u0011\n\u0002\b\u0002\n\u0002\u0010\"\n\u0002\u0010\b\n\u0000\n\u0002\u0018\u0002\n\u0002\b\u0003\n\u0002\u0018\u0002\n\u0002\b\u0003\n\u0002\u0010\t\n\u0000\n\u0002\u0018\u0002\n\u0000\n\u0002\u0010%\n\u0002\b\u0003\n\u0002\u0010\u000b\n\u0002\b\u0006\n\u0002\u0018\u0002\n\u0000\n\u0002\u0018\u0002\n\u0000\n\u0002\u0018\u0002\n\u0000\n\u0002\u0010!\n\u0002\b\u0002\n\u0002\u0018\u0002\n\u0000\n\u0002\u0018\u0002\n\u0000\n\u0002\u0018\u0002\n\u0002\b\u0005\n\u0002\u0018\u0002\n\u0002\b\u0002\n\u0002\u0018\u0002\n\u0002\b\u0004\n\u0002\u0018\u0002\n\u0002\b\u0002\n\u0002\u0010\u0002\n\u0000\n\u0002\u0018\u0002\n\u0002\b\r\n\u0002\u0010$\n\u0002\b\u0006\n\u0002\u0010\u0015\n\u0000\n\u0002\u0010 \n\u0002\b\u0005\n\u0002\u0018\u0002\n\u0002\b\u0004\n\u0002\u0018\u0002\n\u0002\b\n\n\u0002\u0018\u0002\n\u0002\b\n\n\u0002\u0018\u0002\n\u0000\n\u0002\u0018\u0002\n\u0002\b\u000b\b\u0016\u0018\u0000 \u0088\u00012\u00020\u0001:\u0002\u0088\u0001B\u0007\b\u0016\u00a2\u0006\u0002\u0010\u0002B\u0015\b\u0016\u0012\f\u0010\u0003\u001a\b\u0012\u0004\u0012\u00020\u00050\u0004\u00a2\u0006\u0002\u0010\u0006B\u001b\b\u0016\u0012\u0012\u0010\u0003\u001a\n\u0012\u0006\b\u0001\u0012\u00020\u00050\u0007\"\u00020\u0005\u00a2\u0006\u0002\u0010\bJ\u001f\u00102\u001a\u00020\u00002\u0012\u00103\u001a\n\u0012\u0006\b\u0001\u0012\u00020\u00050\u0007\"\u00020\u0005\u00a2\u0006\u0002\u00104J\u0014\u00102\u001a\u00020\u00002\f\u00103\u001a\b\u0012\u0004\u0012\u00020\u00050\u0004J\u000e\u00105\u001a\u00020\u00002\u0006\u00106\u001a\u000207J\u000e\u00108\u001a\u00020\u00002\u0006\u00109\u001a\u00020:J\u001f\u0010;\u001a\u00020\u00002\u0012\u0010<\u001a\n\u0012\u0006\b\u0001\u0012\u00020\u00050\u0007\"\u00020\u0005\u00a2\u0006\u0002\u00104J\u000e\u0010=\u001a\u00020$2\u0006\u0010>\u001a\u00020?J\u0014\u0010=\u001a\u00020$2\n\b\u0002\u0010>\u001a\u0004\u0018\u00010\u0005H\u0007J\u0006\u0010@\u001a\u00020-J\u000e\u0010A\u001a\u00020B2\u0006\u0010C\u001a\u00020DJ\u0006\u0010E\u001a\u00020\u0000J\u0016\u0010\u0014\u001a\u00020\u00002\u0006\u0010F\u001a\u00020\u00152\u0006\u0010G\u001a\u00020\u0017J'\u0010\u0003\u001a\u00020\u00002\u0006\u0010\u0003\u001a\u00020?2\u0012\u0010H\u001a\n\u0012\u0006\b\u0001\u0012\u00020\u00050\u0007\"\u00020\u0005\u00a2\u0006\u0002\u0010IJ\u001f\u0010\u0003\u001a\u00020\u00002\u0012\u0010\u0003\u001a\n\u0012\u0006\b\u0001\u0012\u00020\u00050\u0007\"\u00020\u0005\u00a2\u0006\u0002\u00104J\u0014\u0010\u0003\u001a\u00020\u00002\f\u0010\u0003\u001a\b\u0012\u0004\u0012\u00020\u00050\u0004J\u000e\u0010J\u001a\u00020\u00002\u0006\u0010K\u001a\u00020\u0005J\u0006\u0010L\u001a\u00020\u0000J\u0006\u0010M\u001a\u00020\u0000J\u0010\u00106\u001a\u00020\u00002\b\u00106\u001a\u0004\u0018\u000107J\u0006\u0010N\u001a\u00020\u0000J\u0018\u0010\u0018\u001a\u00020\u00002\u0006\u0010O\u001a\u00020\u00052\b\u0010P\u001a\u0004\u0018\u00010\u0005J\u001c\u0010\u0018\u001a\u00020\u00002\u0014\u0010Q\u001a\u0010\u0012\u0004\u0012\u00020\u0005\u0012\u0006\u0012\u0004\u0018\u00010\u00050RJ\u000e\u0010S\u001a\u00020\u00002\u0006\u0010T\u001a\u00020?J\u000e\u0010S\u001a\u00020\u00002\u0006\u0010T\u001a\u00020\u0005J\u000e\u0010U\u001a\u00020\u00002\u0006\u0010U\u001a\u00020\u000bJ\u0006\u0010V\u001a\u00020\u0000J\u0006\u0010W\u001a\u00020\u0000J\u0012\u0010X\u001a\u00020\u00002\n\u0010X\u001a\u00020Y\"\u00020\u000bJ\f\u0010Z\u001a\b\u0012\u0004\u0012\u00020\u00050[J\u000e\u0010\\\u001a\b\u0012\u0004\u0012\u00020\u00050[H\u0016J\u0006\u0010]\u001a\u00020\u0005J\u0006\u0010^\u001a\u00020\u0005J\b\u0010_\u001a\u0004\u0018\u00010?J\u0006\u0010!\u001a\u00020\u0000J\u0006\u0010\"\u001a\u00020\u0000J\u0010\u00109\u001a\u00020\u00002\b\u00109\u001a\u0004\u0018\u00010:J \u0010`\u001a\u00020a2\u0006\u0010F\u001a\u00020\u00152\u0006\u0010b\u001a\u00020\u00172\u0006\u0010c\u001a\u00020\u001dH\u0002J\u0010\u0010d\u001a\u00020\u00002\b\u0010e\u001a\u0004\u0018\u00010fJ\u000e\u0010g\u001a\u00020\u00002\u0006\u0010e\u001a\u00020fJ\u0006\u0010h\u001a\u00020\u0000J\u000e\u0010h\u001a\u00020\u00002\u0006\u0010i\u001a\u00020(J\u0006\u0010j\u001a\u00020\u0000J\u000e\u0010j\u001a\u00020\u00002\u0006\u0010i\u001a\u00020(J\u0006\u0010k\u001a\u00020\u0000J\u000e\u0010k\u001a\u00020\u00002\u0006\u0010i\u001a\u00020(J\u0006\u0010l\u001a\u00020\u0000J\u000e\u0010l\u001a\u00020\u00002\u0006\u0010i\u001a\u00020(J\u0006\u0010m\u001a\u00020\u0000J\u000e\u0010m\u001a\u00020\u00002\u0006\u0010i\u001a\u00020(J\u000e\u0010n\u001a\u00020\u00002\u0006\u0010n\u001a\u00020\u001dJ\u0010\u0010o\u001a\u00020\u00002\b\u0010p\u001a\u0004\u0018\u00010qJ\u0014\u0010r\u001a\u00020\u00002\n\b\u0002\u0010e\u001a\u0004\u0018\u00010fH\u0007J\u000e\u0010s\u001a\u00020\u00002\u0006\u0010e\u001a\u00020fJ\u0006\u0010t\u001a\u00020\u0000J\u000e\u0010t\u001a\u00020\u00002\u0006\u0010i\u001a\u00020(J\u0006\u0010u\u001a\u00020\u0000J\u000e\u0010u\u001a\u00020\u00002\u0006\u0010i\u001a\u00020(J\u0006\u0010v\u001a\u00020\u0000J\u000e\u0010v\u001a\u00020\u00002\u0006\u0010i\u001a\u00020(J\u0006\u0010w\u001a\u00020\u0000J\u000e\u0010w\u001a\u00020\u00002\u0006\u0010i\u001a\u00020(J\u0006\u0010x\u001a\u00020\u0000J\u000e\u0010x\u001a\u00020\u00002\u0006\u0010i\u001a\u00020(J\u000e\u0010y\u001a\u00020\u00002\u0006\u00109\u001a\u00020:J\u0016\u0010z\u001a\u00020\u00002\u000e\u0010{\u001a\n\u0012\u0006\b\u0001\u0012\u00020:0|J%\u0010}\u001a\u00020~2\b\b\u0002\u0010F\u001a\u00020\u00152\b\b\u0002\u0010b\u001a\u00020\u0017H\u0087@\u00f8\u0001\u0000\u00a2\u0006\u0002\u0010\u007fJ&\u0010\u0080\u0001\u001a\u00020~2\b\b\u0002\u0010F\u001a\u00020\u00152\b\b\u0002\u0010b\u001a\u00020\u0017H\u0087@\u00f8\u0001\u0000\u00a2\u0006\u0002\u0010\u007fJ\u001d\u0010\u0081\u0001\u001a\u00020a2\b\b\u0002\u0010F\u001a\u00020\u00152\b\b\u0002\u0010b\u001a\u00020\u0017H\u0007J\u001d\u0010\u0082\u0001\u001a\u00020~2\b\b\u0002\u0010F\u001a\u00020\u00152\b\b\u0002\u0010b\u001a\u00020\u0017H\u0007J\u001d\u0010\u0083\u0001\u001a\u00020a2\b\b\u0002\u0010F\u001a\u00020\u00152\b\b\u0002\u0010b\u001a\u00020\u0017H\u0007J\u001d\u0010\u0084\u0001\u001a\u00020~2\b\b\u0002\u0010F\u001a\u00020\u00152\b\b\u0002\u0010b\u001a\u00020\u0017H\u0007J\u0010\u0010.\u001a\u00020\u00002\b\u0010.\u001a\u0004\u0018\u00010/J\u0006\u00100\u001a\u000201J\u000e\u00100\u001a\u00020\u00002\u0006\u00100\u001a\u000201J\u0007\u0010\u0085\u0001\u001a\u00020\u0000J\u0012\u0010\u0086\u0001\u001a\u00020\u00002\t\u0010\u0087\u0001\u001a\u0004\u0018\u00010?J\u0012\u0010\u0086\u0001\u001a\u00020\u00002\t\u0010\u0087\u0001\u001a\u0004\u0018\u00010\u0005R\u0016\u0010\t\u001a\n\u0012\u0004\u0012\u00020\u000b\u0018\u00010\nX\u0082\u000e\u00a2\u0006\u0002\n\u0000R\u0014\u0010\f\u001a\u00020\r8BX\u0082\u0004\u00a2\u0006\u0006\u001a\u0004\b\u000e\u0010\u000fR\u0014\u0010\u0010\u001a\u00020\u0011X\u0080\u0004\u00a2\u0006\b\n\u0000\u001a\u0004\b\u0012\u0010\u0013R\u000e\u0010\u0014\u001a\u00020\u0015X\u0082\u000e\u00a2\u0006\u0002\n\u0000R\u000e\u0010\u0016\u001a\u00020\u0017X\u0082\u000e\u00a2\u0006\u0002\n\u0000R\u001f\u0010\u0018\u001a\u0010\u0012\u0004\u0012\u00020\u0005\u0012\u0006\u0012\u0004\u0018\u00010\u00050\u0019\u00a2\u0006\b\n\u0000\u001a\u0004\b\u001a\u0010\u001bR\u000e\u0010\u001c\u001a\u00020\u001dX\u0082\u000e\u00a2\u0006\u0002\n\u0000R\u0014\u0010\u001e\u001a\u00020\u00058BX\u0082\u0004\u00a2\u0006\u0006\u001a\u0004\b\u001f\u0010 R\u000e\u0010!\u001a\u00020\u001dX\u0082\u000e\u00a2\u0006\u0002\n\u0000R\u000e\u0010\"\u001a\u00020\u001dX\u0082\u000e\u00a2\u0006\u0002\n\u0000R\u0010\u0010#\u001a\u0004\u0018\u00010$X\u0082\u000e\u00a2\u0006\u0002\n\u0000R\u000e\u0010%\u001a\u00020&X\u0082\u0004\u00a2\u0006\u0002\n\u0000R\u0010\u0010'\u001a\u0004\u0018\u00010(X\u0082\u000e\u00a2\u0006\u0002\n\u0000R\u0014\u0010)\u001a\b\u0012\u0004\u0012\u00020\u00050*X\u0082\u000e\u00a2\u0006\u0002\n\u0000R\u000e\u0010+\u001a\u00020\u001dX\u0082\u000e\u00a2\u0006\u0002\n\u0000R\u0010\u0010,\u001a\u0004\u0018\u00010-X\u0082\u000e\u00a2\u0006\u0002\n\u0000R\u000e\u0010.\u001a\u00020/X\u0082\u000e\u00a2\u0006\u0002\n\u0000R\u000e\u00100\u001a\u000201X\u0082\u000e\u00a2\u0006\u0002\n\u0000\u0082\u0002\u0004\n\u0002\b\u0019\u00a8\u0006\u0089\u0001"}, d2={"Ldorkbox/executor/Executor;", "", "()V", "command", "", "", "(Ljava/lang/Iterable;)V", "", "([Ljava/lang/String;)V", "allowedExitValues", "", "", "attributes", "Ldorkbox/executor/ProcessAttributes;", "getAttributes", "()Ldorkbox/executor/ProcessAttributes;", "builder", "Ljava/lang/ProcessBuilder;", "getBuilder$Executor", "()Ljava/lang/ProcessBuilder;", "closeTimeout", "", "closeTimeoutUnit", "Ljava/util/concurrent/TimeUnit;", "environment", "", "getEnvironment", "()Ljava/util/Map;", "executeAsShell", "", "executingMessageParams", "getExecutingMessageParams", "()Ljava/lang/String;", "highPerformanceIO", "inheritIO", "jvmExecOptions", "Ldorkbox/executor/JvmExecOptions;", "listeners", "Ldorkbox/executor/listener/CompositeProcessListener;", "logger", "Lorg/slf4j/Logger;", "pathsToPrepend", "", "readOutput", "sshExecOptions", "Ldorkbox/executor/SshExecOptions;", "stopper", "Ldorkbox/executor/stop/ProcessStopper;", "streams", "Ldorkbox/executor/stream/IOStreamHandler;", "addArg", "arguments", "([Ljava/lang/String;)Ldorkbox/executor/Executor;", "addDestroyer", "destroyer", "Ldorkbox/executor/listener/ProcessDestroyer;", "addListener", "listener", "Ldorkbox/executor/listener/ProcessListener;", "addPath", "pathsToAdd", "asJvmProcess", "javaExecutable", "Ljava/io/File;", "asSshProcess", "checkExitValue", "", "result", "Ldorkbox/executor/processResults/ProcessResult;", "clearListeners", "timeout", "unit", "args", "(Ljava/io/File;[Ljava/lang/String;)Ldorkbox/executor/Executor;", "commandSplit", "commandWithArgs", "defaultLogger", "destroyOnExit", "enableRead", "name", "value", "env", "", "executable", "exe", "exitValue", "exitValueAny", "exitValueNormal", "exitValues", "", "getArgs", "", "getCommand", "getExecutable", "getSystemPath", "getWorkingDirectory", "prepareProcess", "Ldorkbox/executor/DeferredProcessResult;", "timeoutUnit", "asyncProcessStart", "redirectError", "output", "Ljava/io/OutputStream;", "redirectErrorAlsoTo", "redirectErrorAsDebug", "log", "redirectErrorAsError", "redirectErrorAsInfo", "redirectErrorAsTrace", "redirectErrorAsWarn", "redirectErrorStream", "redirectInput", "input", "Ljava/io/InputStream;", "redirectOutput", "redirectOutputAlsoTo", "redirectOutputAsDebug", "redirectOutputAsError", "redirectOutputAsInfo", "redirectOutputAsTrace", "redirectOutputAsWarn", "removeListener", "removeListeners", "listenerType", "Ljava/lang/Class;", "start", "Ldorkbox/executor/processResults/SyncProcessResult;", "(JLjava/util/concurrent/TimeUnit;Lkotlin/coroutines/Continuation;)Ljava/lang/Object;", "startAsShell", "startAsShellAsync", "startAsShellBlocking", "startAsync", "startBlocking", "useSystemEnvironment", "workingDirectory", "directory", "Companion", "Executor"})
public class Executor {
    @NotNull
    public static final Companion Companion = new Companion(null);
    @NotNull
    private final ProcessBuilder builder;
    @NotNull
    private final Map<String, String> environment;
    @Nullable
    private JvmExecOptions jvmExecOptions;
    @Nullable
    private SshExecOptions sshExecOptions;
    private boolean executeAsShell;
    @NotNull
    private List<String> pathsToPrepend;
    @Nullable
    private Set<Integer> allowedExitValues;
    @NotNull
    private ProcessStopper stopper;
    @NotNull
    private IOStreamHandler streams;
    private long closeTimeout;
    @NotNull
    private TimeUnit closeTimeoutUnit;
    private boolean readOutput;
    private boolean inheritIO;
    private boolean highPerformanceIO;
    @NotNull
    private final CompositeProcessListener listeners;
    @Nullable
    private Logger logger;
    @NotNull
    public static final String version = "3.11";
    @NotNull
    private static final Logger log;
    private static final boolean IS_OS_WINDOWS;
    private static final boolean IS_OS_MAC;
    @Nullable
    private static final Integer[] DEFAULT_EXIT_VALUES;
    private static final int NORMAL_EXIT_VALUE = 0;
    public static final boolean DEFAULT_REDIRECT_ERROR_STREAM = true;
    @NotNull
    private static final CoroutineScope IO_DISPATCH;
    private static final String LINE_SEPARATOR;
    @NotNull
    private static final Regex EXTRA_SPACE_REGEX;
    @Nullable
    private static String DEFAULT_SHELL;

    @NotNull
    public final ProcessBuilder getBuilder$Executor() {
        return this.builder;
    }

    @NotNull
    public final Map<String, String> getEnvironment() {
        return this.environment;
    }

    private final ProcessAttributes getAttributes() {
        Set<Integer> allowedExit = this.allowedExitValues;
        return allowedExit != null ? new ProcessAttributes(this.getCommand(), this.getWorkingDirectory(), (Map<String, String>)new LinkedHashMap<String, String>(this.environment), CollectionsKt.toSet((Iterable)allowedExit)) : new ProcessAttributes(this.getCommand(), this.getWorkingDirectory(), new LinkedHashMap<String, String>(this.environment), null, 8, null);
    }

    private final String getExecutingMessageParams() {
        List<String> list = this.builder.command();
        Intrinsics.checkNotNullExpressionValue(list, (String)"builder.command()");
        String result = CollectionsKt.joinToString$default((Iterable)list, (CharSequence)" ", null, null, (int)0, null, null, (int)62, null);
        if (this.builder.directory() != null) {
            result = result + " in " + this.builder.directory();
        }
        if (!this.environment.isEmpty()) {
            result = result + " with environment " + this.environment;
        }
        return result;
    }

    public Executor() {
        this.builder = new ProcessBuilder(new String[0]);
        this.environment = new LinkedHashMap();
        this.pathsToPrepend = new ArrayList();
        this.stopper = NopProcessStopper.Companion.getINSTANCE();
        this.streams = new NopPumpStreamHandler();
        this.closeTimeoutUnit = TimeUnit.SECONDS;
        this.listeners = new CompositeProcessListener();
        this.exitValueAny();
        this.stopper(DestroyProcessStopper.Companion.getINSTANCE());
        this.redirectOutput(null);
        this.redirectError(null);
        this.destroyer(null);
        this.redirectErrorStream(true);
    }

    public Executor(@NotNull Iterable<String> command) {
        Intrinsics.checkNotNullParameter(command, (String)"command");
        this.builder = new ProcessBuilder(new String[0]);
        this.environment = new LinkedHashMap();
        this.pathsToPrepend = new ArrayList();
        this.stopper = NopProcessStopper.Companion.getINSTANCE();
        this.streams = new NopPumpStreamHandler();
        this.closeTimeoutUnit = TimeUnit.SECONDS;
        this.listeners = new CompositeProcessListener();
        this.exitValueAny();
        this.stopper(DestroyProcessStopper.Companion.getINSTANCE());
        this.redirectOutput(null);
        this.redirectError(null);
        this.destroyer(null);
        this.redirectErrorStream(true);
        this.command(command);
    }

    public Executor(String ... command) {
        Intrinsics.checkNotNullParameter((Object)command, (String)"command");
        this.builder = new ProcessBuilder(new String[0]);
        this.environment = new LinkedHashMap();
        this.pathsToPrepend = new ArrayList();
        this.stopper = NopProcessStopper.Companion.getINSTANCE();
        this.streams = new NopPumpStreamHandler();
        this.closeTimeoutUnit = TimeUnit.SECONDS;
        this.listeners = new CompositeProcessListener();
        this.exitValueAny();
        this.stopper(DestroyProcessStopper.Companion.getINSTANCE());
        this.redirectOutput(null);
        this.redirectError(null);
        this.destroyer(null);
        this.redirectErrorStream(true);
        this.command(Arrays.copyOf(command, command.length));
    }

    @NotNull
    public List<String> getCommand() {
        return new ArrayList(this.builder.command());
    }

    /*
     * WARNING - void declaration
     */
    @NotNull
    public final Executor command(@NotNull Iterable<String> command) {
        void $this$mapTo$iv$iv;
        Intrinsics.checkNotNullParameter(command, (String)"command");
        Iterable<String> $this$map$iv = command;
        boolean $i$f$map = false;
        Iterable<String> iterable = $this$map$iv;
        Collection destination$iv$iv = new ArrayList(CollectionsKt.collectionSizeOrDefault($this$map$iv, (int)10));
        boolean $i$f$mapTo = false;
        for (Object item$iv$iv : $this$mapTo$iv$iv) {
            void it;
            String string2 = (String)item$iv$iv;
            Collection collection = destination$iv$iv;
            boolean bl = false;
            collection.add(it);
        }
        List list = (List)destination$iv$iv;
        this.builder.command().addAll((Collection<String>)Companion.fixArguments$Executor(list));
        return this;
    }

    @NotNull
    public final Executor command(String ... command) {
        Intrinsics.checkNotNullParameter((Object)command, (String)"command");
        this.builder.command().addAll((Collection<String>)Companion.fixArguments$Executor(CollectionsKt.listOf((Object[])Arrays.copyOf(command, command.length))));
        return this;
    }

    @NotNull
    public final Executor command(@NotNull File command, String ... args) {
        Intrinsics.checkNotNullParameter((Object)command, (String)"command");
        Intrinsics.checkNotNullParameter((Object)args, (String)"args");
        SpreadBuilder spreadBuilder = new SpreadBuilder(2);
        spreadBuilder.add((Object)command.getAbsolutePath());
        spreadBuilder.addSpread((Object)args);
        List combined = CollectionsKt.listOf((Object[])spreadBuilder.toArray((Object[])new String[spreadBuilder.size()]));
        this.builder.command().addAll((Collection<String>)Companion.fixArguments$Executor(combined));
        return this;
    }

    @NotNull
    public final Executor commandSplit(@NotNull String commandWithArgs) {
        Intrinsics.checkNotNullParameter((Object)commandWithArgs, (String)"commandWithArgs");
        CharSequence charSequence = commandWithArgs;
        Regex regex = EXTRA_SPACE_REGEX;
        int n = 0;
        this.builder.command().addAll(regex.split(charSequence, n));
        return this;
    }

    @NotNull
    public final Executor executable(@NotNull String exe) {
        Intrinsics.checkNotNullParameter((Object)exe, (String)"exe");
        this.builder.command().add(0, exe);
        return this;
    }

    @NotNull
    public final Executor executable(@NotNull File exe) {
        Intrinsics.checkNotNullParameter((Object)exe, (String)"exe");
        this.builder.command().add(0, exe.getAbsolutePath());
        return this;
    }

    @NotNull
    public final String getExecutable() {
        List<String> command = this.builder.command();
        if (command.isEmpty()) {
            return "";
        }
        String string2 = command.get(0);
        Intrinsics.checkNotNullExpressionValue((Object)string2, (String)"command[0]");
        return string2;
    }

    @NotNull
    public final Executor addArg(String ... arguments) {
        Intrinsics.checkNotNullParameter((Object)arguments, (String)"arguments");
        List<String> fixed = Companion.fixArguments$Executor(CollectionsKt.listOf((Object[])Arrays.copyOf(arguments, arguments.length)));
        this.builder.command().addAll((Collection<String>)fixed);
        return this;
    }

    @NotNull
    public final Executor addArg(@NotNull Iterable<String> arguments) {
        Intrinsics.checkNotNullParameter(arguments, (String)"arguments");
        List<String> fixed = Companion.fixArguments$Executor(arguments);
        this.builder.command().addAll((Collection<String>)fixed);
        return this;
    }

    @NotNull
    public final List<String> getArgs() {
        List<String> command = this.builder.command();
        return command.size() <= 1 ? CollectionsKt.emptyList() : command.subList(1, command.size());
    }

    @Nullable
    public final File getWorkingDirectory() {
        return this.builder.directory();
    }

    @NotNull
    public final Executor workingDirectory(@Nullable File directory) {
        this.builder.directory(directory);
        return this;
    }

    @NotNull
    public final Executor workingDirectory(@Nullable String directory) {
        if (directory != null) {
            this.builder.directory(new File(directory));
        } else {
            this.builder.directory((File)((Object)directory));
        }
        return this;
    }

    @NotNull
    public final Executor environment(@NotNull Map<String, String> env) {
        Intrinsics.checkNotNullParameter(env, (String)"env");
        this.environment.putAll(env);
        return this;
    }

    @NotNull
    public final Executor environment(@NotNull String name, @Nullable String value) {
        Intrinsics.checkNotNullParameter((Object)name, (String)"name");
        this.environment.put(name, value);
        return this;
    }

    @NotNull
    public final Executor useSystemEnvironment() {
        Map<String, String> map = System.getenv();
        Intrinsics.checkNotNullExpressionValue(map, (String)"getenv()");
        this.environment.putAll(map);
        return this;
    }

    @NotNull
    public final Executor addPath(String ... pathsToAdd) {
        Intrinsics.checkNotNullParameter((Object)pathsToAdd, (String)"pathsToAdd");
        CollectionsKt.addAll((Collection)this.pathsToPrepend, (Object[])pathsToAdd);
        this.executeAsShell = true;
        return this;
    }

    @NotNull
    public final String getSystemPath() {
        Map<String, String> systemEnv = System.getenv();
        String string2 = systemEnv.get("PATH");
        if (string2 == null && (string2 = systemEnv.get("Path")) == null && (string2 = systemEnv.get("path")) == null) {
            string2 = "";
        }
        return string2;
    }

    @NotNull
    public final Executor redirectErrorStream(boolean redirectErrorStream) {
        this.builder.redirectErrorStream(redirectErrorStream);
        return this;
    }

    @NotNull
    public final Executor exitValueAny() {
        this.allowedExitValues = null;
        return this;
    }

    @NotNull
    public final Executor exitValueNormal() {
        int[] nArray = new int[]{0};
        return this.exitValues(nArray);
    }

    @NotNull
    public final Executor exitValue(int exitValue) {
        int[] nArray = new int[]{exitValue};
        return this.exitValues(nArray);
    }

    @NotNull
    public final Executor exitValues(int ... exitValues) {
        Intrinsics.checkNotNullParameter((Object)exitValues, (String)"exitValues");
        this.allowedExitValues = ArraysKt.toSet((int[])exitValues);
        return this;
    }

    @NotNull
    public final Executor stopper(@Nullable ProcessStopper stopper) {
        this.stopper = stopper == null ? NopProcessStopper.Companion.getINSTANCE() : stopper;
        return this;
    }

    @NotNull
    public final IOStreamHandler streams() {
        return this.streams;
    }

    @NotNull
    public final Executor streams(@NotNull IOStreamHandler streams) {
        Intrinsics.checkNotNullParameter((Object)streams, (String)"streams");
        this.streams = streams;
        return this;
    }

    @NotNull
    public final Executor closeTimeout(long timeout, @NotNull TimeUnit unit) {
        Intrinsics.checkNotNullParameter((Object)((Object)unit), (String)"unit");
        this.closeTimeout = timeout;
        this.closeTimeoutUnit = unit;
        return this;
    }

    @NotNull
    public final Executor enableRead() {
        this.readOutput = true;
        return this;
    }

    @NotNull
    public final Executor inheritIO() {
        this.inheritIO = true;
        return this;
    }

    @NotNull
    public final Executor redirectInput(@Nullable InputStream input) {
        InputStream inputStream = input == null ? (InputStream)NopInputStream.Companion.getINPUT_STREAM() : input;
        this.streams = this.streams.setInputStream(inputStream);
        return this;
    }

    @JvmOverloads
    @NotNull
    public final Executor redirectOutput(@Nullable OutputStream output2) {
        OutputStream outputStream = output2;
        if (outputStream == null) {
            outputStream = NopOutputStream.Companion.getOUTPUT_STREAM();
        }
        this.streams = this.streams.setOutputStream(outputStream);
        return this;
    }

    public static /* synthetic */ Executor redirectOutput$default(Executor executor, OutputStream outputStream, int n, Object object) {
        if (object != null) {
            throw new UnsupportedOperationException("Super calls with default arguments not supported in this target, function: redirectOutput");
        }
        if ((n & 1) != 0) {
            outputStream = null;
        }
        return executor.redirectOutput(outputStream);
    }

    @NotNull
    public final Executor redirectError(@Nullable OutputStream output2) {
        OutputStream outputStream = output2;
        if (outputStream == null) {
            outputStream = NopOutputStream.Companion.getOUTPUT_STREAM();
        }
        this.streams = this.streams.setErrorStream(outputStream);
        this.redirectErrorStream(false);
        return this;
    }

    @NotNull
    public final Executor redirectOutputAlsoTo(@NotNull OutputStream output2) {
        Intrinsics.checkNotNullParameter((Object)output2, (String)"output");
        this.streams = this.streams.teeOutputStream(output2);
        return this;
    }

    @NotNull
    public final Executor redirectErrorAlsoTo(@NotNull OutputStream output2) {
        Intrinsics.checkNotNullParameter((Object)output2, (String)"output");
        this.streams = this.streams.teeErrorStream(output2);
        this.redirectErrorStream(false);
        return this;
    }

    @NotNull
    public final Executor redirectOutputAsTrace() {
        Logger logger = LoggerFactory.getLogger((String)CallerLoggerUtil.INSTANCE.getName(null, 1));
        Intrinsics.checkNotNullExpressionValue((Object)logger, (String)"getLogger(\n             \u2026gerUtil.getName(null, 1))");
        return this.redirectOutput(Slf4jStream.INSTANCE.asDebug(logger));
    }

    @NotNull
    public final Executor redirectOutputAsDebug() {
        Logger logger = LoggerFactory.getLogger((String)CallerLoggerUtil.INSTANCE.getName(null, 1));
        Intrinsics.checkNotNullExpressionValue((Object)logger, (String)"getLogger(\n             \u2026gerUtil.getName(null, 1))");
        return this.redirectOutput(Slf4jStream.INSTANCE.asDebug(logger));
    }

    @NotNull
    public final Executor redirectOutputAsInfo() {
        Logger logger = LoggerFactory.getLogger((String)CallerLoggerUtil.INSTANCE.getName(null, 1));
        Intrinsics.checkNotNullExpressionValue((Object)logger, (String)"getLogger(\n             \u2026gerUtil.getName(null, 1))");
        return this.redirectOutput(Slf4jStream.INSTANCE.asInfo(logger));
    }

    @NotNull
    public final Executor redirectOutputAsWarn() {
        Logger logger = LoggerFactory.getLogger((String)CallerLoggerUtil.INSTANCE.getName(null, 1));
        Intrinsics.checkNotNullExpressionValue((Object)logger, (String)"getLogger(\n             \u2026gerUtil.getName(null, 1))");
        return this.redirectOutput(Slf4jStream.INSTANCE.asWarn(logger));
    }

    @NotNull
    public final Executor redirectOutputAsError() {
        Logger logger = LoggerFactory.getLogger((String)CallerLoggerUtil.INSTANCE.getName(null, 1));
        Intrinsics.checkNotNullExpressionValue((Object)logger, (String)"getLogger(\n             \u2026gerUtil.getName(null, 1))");
        return this.redirectOutput(Slf4jStream.INSTANCE.asDebug(logger));
    }

    @NotNull
    public final Executor redirectOutputAsTrace(@NotNull Logger log) {
        Intrinsics.checkNotNullParameter((Object)log, (String)"log");
        return this.redirectOutput(Slf4jStream.INSTANCE.asDebug(log));
    }

    @NotNull
    public final Executor redirectOutputAsDebug(@NotNull Logger log) {
        Intrinsics.checkNotNullParameter((Object)log, (String)"log");
        return this.redirectOutput(Slf4jStream.INSTANCE.asDebug(log));
    }

    @NotNull
    public final Executor redirectOutputAsInfo(@NotNull Logger log) {
        Intrinsics.checkNotNullParameter((Object)log, (String)"log");
        return this.redirectOutput(Slf4jStream.INSTANCE.asInfo(log));
    }

    @NotNull
    public final Executor redirectOutputAsWarn(@NotNull Logger log) {
        Intrinsics.checkNotNullParameter((Object)log, (String)"log");
        return this.redirectOutput(Slf4jStream.INSTANCE.asWarn(log));
    }

    @NotNull
    public final Executor redirectOutputAsError(@NotNull Logger log) {
        Intrinsics.checkNotNullParameter((Object)log, (String)"log");
        return this.redirectOutput(Slf4jStream.INSTANCE.asDebug(log));
    }

    @NotNull
    public final Executor redirectErrorAsTrace() {
        Logger logger = LoggerFactory.getLogger((String)CallerLoggerUtil.INSTANCE.getName(null, 1));
        Intrinsics.checkNotNullExpressionValue((Object)logger, (String)"getLogger(\n             \u2026gerUtil.getName(null, 1))");
        return this.redirectError(Slf4jStream.INSTANCE.asTrace(logger));
    }

    @NotNull
    public final Executor redirectErrorAsDebug() {
        Logger logger = LoggerFactory.getLogger((String)CallerLoggerUtil.INSTANCE.getName(null, 1));
        Intrinsics.checkNotNullExpressionValue((Object)logger, (String)"getLogger(\n             \u2026gerUtil.getName(null, 1))");
        return this.redirectError(Slf4jStream.INSTANCE.asDebug(logger));
    }

    @NotNull
    public final Executor redirectErrorAsInfo() {
        Logger logger = LoggerFactory.getLogger((String)CallerLoggerUtil.INSTANCE.getName(null, 1));
        Intrinsics.checkNotNullExpressionValue((Object)logger, (String)"getLogger(\n             \u2026gerUtil.getName(null, 1))");
        return this.redirectError(Slf4jStream.INSTANCE.asInfo(logger));
    }

    @NotNull
    public final Executor redirectErrorAsWarn() {
        Logger logger = LoggerFactory.getLogger((String)CallerLoggerUtil.INSTANCE.getName(null, 1));
        Intrinsics.checkNotNullExpressionValue((Object)logger, (String)"getLogger(\n             \u2026gerUtil.getName(null, 1))");
        return this.redirectError(Slf4jStream.INSTANCE.asWarn(logger));
    }

    @NotNull
    public final Executor redirectErrorAsError() {
        return this.redirectError(Slf4jStream.INSTANCE.asError(log));
    }

    @NotNull
    public final Executor redirectErrorAsTrace(@NotNull Logger log) {
        Intrinsics.checkNotNullParameter((Object)log, (String)"log");
        return this.redirectError(Slf4jStream.INSTANCE.asTrace(log));
    }

    @NotNull
    public final Executor redirectErrorAsDebug(@NotNull Logger log) {
        Intrinsics.checkNotNullParameter((Object)log, (String)"log");
        return this.redirectError(Slf4jStream.INSTANCE.asDebug(log));
    }

    @NotNull
    public final Executor redirectErrorAsInfo(@NotNull Logger log) {
        Intrinsics.checkNotNullParameter((Object)log, (String)"log");
        return this.redirectError(Slf4jStream.INSTANCE.asInfo(log));
    }

    @NotNull
    public final Executor redirectErrorAsWarn(@NotNull Logger log) {
        Intrinsics.checkNotNullParameter((Object)log, (String)"log");
        return this.redirectError(Slf4jStream.INSTANCE.asWarn(log));
    }

    @NotNull
    public final Executor redirectErrorAsError(@NotNull Logger log) {
        Intrinsics.checkNotNullParameter((Object)log, (String)"log");
        return this.redirectError(Slf4jStream.INSTANCE.asError(log));
    }

    @NotNull
    public final Executor addDestroyer(@NotNull ProcessDestroyer destroyer) {
        Intrinsics.checkNotNullParameter((Object)destroyer, (String)"destroyer");
        return this.addListener(new DestroyerListenerAdapter(destroyer));
    }

    @NotNull
    public final Executor destroyer(@Nullable ProcessDestroyer destroyer) {
        this.removeListeners(DestroyerListenerAdapter.class);
        if (destroyer != null) {
            this.addListener(new DestroyerListenerAdapter(destroyer));
        }
        return this;
    }

    @NotNull
    public final Executor destroyOnExit() {
        return this.destroyer(ShutdownHookProcessDestroyer.Companion.getINSTANCE());
    }

    @NotNull
    public final Executor listener(@Nullable ProcessListener listener) {
        this.clearListeners();
        ProcessListener processListener = listener;
        if (processListener != null) {
            ProcessListener it = processListener;
            boolean bl = false;
            this.addListener(it);
        }
        return this;
    }

    @NotNull
    public final Executor addListener(@NotNull ProcessListener listener) {
        Intrinsics.checkNotNullParameter((Object)listener, (String)"listener");
        this.listeners.add(listener);
        return this;
    }

    @NotNull
    public final Executor removeListener(@NotNull ProcessListener listener) {
        Intrinsics.checkNotNullParameter((Object)listener, (String)"listener");
        this.listeners.remove(listener);
        return this;
    }

    @NotNull
    public final Executor removeListeners(@NotNull Class<? extends ProcessListener> listenerType) {
        Intrinsics.checkNotNullParameter(listenerType, (String)"listenerType");
        this.listeners.removeAll(listenerType);
        return this;
    }

    @NotNull
    public final Executor clearListeners() {
        this.listeners.clear();
        return this;
    }

    public final void checkExitValue(@NotNull ProcessResult result) throws InvalidExitValueException {
        Intrinsics.checkNotNullParameter((Object)result, (String)"result");
        DeferredProcessResult.Companion.checkExit$Executor(this.getAttributes(), result);
    }

    @NotNull
    public final Executor defaultLogger() {
        this.logger = log;
        return this;
    }

    @NotNull
    public final Executor highPerformanceIO() {
        this.highPerformanceIO = true;
        return this;
    }

    @JvmOverloads
    @NotNull
    public final JvmExecOptions asJvmProcess(@Nullable String javaExecutable) {
        JvmExecOptions jvmExecOptions = this.jvmExecOptions = new JvmExecOptions(this, javaExecutable);
        Intrinsics.checkNotNull((Object)jvmExecOptions);
        return jvmExecOptions;
    }

    public static /* synthetic */ JvmExecOptions asJvmProcess$default(Executor executor, String string2, int n, Object object) {
        if (object != null) {
            throw new UnsupportedOperationException("Super calls with default arguments not supported in this target, function: asJvmProcess");
        }
        if ((n & 1) != 0) {
            string2 = null;
        }
        return executor.asJvmProcess(string2);
    }

    @NotNull
    public final JvmExecOptions asJvmProcess(@NotNull File javaExecutable) {
        Intrinsics.checkNotNullParameter((Object)javaExecutable, (String)"javaExecutable");
        if (!javaExecutable.canExecute()) {
            throw new IllegalArgumentException(Intrinsics.stringPlus((String)"The java executable if specified, must be exist and be executable. Error with: ", (Object)javaExecutable));
        }
        JvmExecOptions jvmExecOptions = this.jvmExecOptions = new JvmExecOptions(this, javaExecutable.getCanonicalFile().getPath());
        Intrinsics.checkNotNull((Object)jvmExecOptions);
        return jvmExecOptions;
    }

    @NotNull
    public final SshExecOptions asSshProcess() {
        SshExecOptions sshExecOptions = this.sshExecOptions = new SshExecOptions(this);
        Intrinsics.checkNotNull((Object)sshExecOptions);
        return sshExecOptions;
    }

    @JvmOverloads
    @NotNull
    public final DeferredProcessResult startAsShellAsync(long timeout, @NotNull TimeUnit timeoutUnit) throws IOException {
        Intrinsics.checkNotNullParameter((Object)((Object)timeoutUnit), (String)"timeoutUnit");
        this.executeAsShell = true;
        return this.startAsync(timeout, timeoutUnit);
    }

    public static /* synthetic */ DeferredProcessResult startAsShellAsync$default(Executor executor, long l, TimeUnit timeUnit, int n, Object object) throws IOException {
        if (object != null) {
            throw new UnsupportedOperationException("Super calls with default arguments not supported in this target, function: startAsShellAsync");
        }
        if ((n & 1) != 0) {
            l = 0L;
        }
        if ((n & 2) != 0) {
            timeUnit = TimeUnit.SECONDS;
        }
        return executor.startAsShellAsync(l, timeUnit);
    }

    @JvmOverloads
    @NotNull
    public final DeferredProcessResult startAsync(long timeout, @NotNull TimeUnit timeoutUnit) throws IOException {
        Intrinsics.checkNotNullParameter((Object)((Object)timeoutUnit), (String)"timeoutUnit");
        return this.prepareProcess(timeout, timeoutUnit, true);
    }

    public static /* synthetic */ DeferredProcessResult startAsync$default(Executor executor, long l, TimeUnit timeUnit, int n, Object object) throws IOException {
        if (object != null) {
            throw new UnsupportedOperationException("Super calls with default arguments not supported in this target, function: startAsync");
        }
        if ((n & 1) != 0) {
            l = 0L;
        }
        if ((n & 2) != 0) {
            timeUnit = TimeUnit.SECONDS;
        }
        return executor.startAsync(l, timeUnit);
    }

    @JvmOverloads
    @Nullable
    public final Object startAsShell(long timeout, @NotNull TimeUnit timeoutUnit, @NotNull Continuation<? super SyncProcessResult> $completion) throws IOException, InterruptedException, TimeoutException, InvalidExitValueException {
        this.executeAsShell = true;
        return this.start(timeout, timeoutUnit, $completion);
    }

    public static /* synthetic */ Object startAsShell$default(Executor executor, long l, TimeUnit timeUnit, Continuation continuation, int n, Object object) throws IOException, InterruptedException, TimeoutException, InvalidExitValueException {
        if (object != null) {
            throw new UnsupportedOperationException("Super calls with default arguments not supported in this target, function: startAsShell");
        }
        if ((n & 1) != 0) {
            l = 0L;
        }
        if ((n & 2) != 0) {
            timeUnit = TimeUnit.SECONDS;
        }
        return executor.startAsShell(l, timeUnit, (Continuation<? super SyncProcessResult>)continuation);
    }

    @JvmOverloads
    @NotNull
    public final SyncProcessResult startAsShellBlocking(long timeout, @NotNull TimeUnit timeoutUnit) throws IOException, InterruptedException, TimeoutException, InvalidExitValueException {
        Intrinsics.checkNotNullParameter((Object)((Object)timeoutUnit), (String)"timeoutUnit");
        return (SyncProcessResult)BuildersKt.runBlocking$default(null, (Function2)((Function2)new Function2<CoroutineScope, Continuation<? super SyncProcessResult>, Object>(this, timeout, timeoutUnit, null){
            int label;
            final /* synthetic */ Executor this$0;
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
                        Object object3 = this.this$0.startAsShell(this.$timeout, this.$timeoutUnit, (Continuation<? super SyncProcessResult>)((Continuation)this));
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

    public static /* synthetic */ SyncProcessResult startAsShellBlocking$default(Executor executor, long l, TimeUnit timeUnit, int n, Object object) throws IOException, InterruptedException, TimeoutException, InvalidExitValueException {
        if (object != null) {
            throw new UnsupportedOperationException("Super calls with default arguments not supported in this target, function: startAsShellBlocking");
        }
        if ((n & 1) != 0) {
            l = 0L;
        }
        if ((n & 2) != 0) {
            timeUnit = TimeUnit.SECONDS;
        }
        return executor.startAsShellBlocking(l, timeUnit);
    }

    @JvmOverloads
    @Nullable
    public final Object start(long timeout, @NotNull TimeUnit timeoutUnit, @NotNull Continuation<? super SyncProcessResult> $completion) throws IOException, InterruptedException, TimeoutException, InvalidExitValueException {
        return this.prepareProcess(timeout, timeoutUnit, false).await(timeout, timeoutUnit, $completion);
    }

    public static /* synthetic */ Object start$default(Executor executor, long l, TimeUnit timeUnit, Continuation continuation, int n, Object object) throws IOException, InterruptedException, TimeoutException, InvalidExitValueException {
        if (object != null) {
            throw new UnsupportedOperationException("Super calls with default arguments not supported in this target, function: start");
        }
        if ((n & 1) != 0) {
            l = 0L;
        }
        if ((n & 2) != 0) {
            timeUnit = TimeUnit.SECONDS;
        }
        return executor.start(l, timeUnit, (Continuation<? super SyncProcessResult>)continuation);
    }

    @JvmOverloads
    @NotNull
    public final SyncProcessResult startBlocking(long timeout, @NotNull TimeUnit timeoutUnit) throws IOException, InterruptedException, TimeoutException, InvalidExitValueException {
        Intrinsics.checkNotNullParameter((Object)((Object)timeoutUnit), (String)"timeoutUnit");
        return (SyncProcessResult)BuildersKt.runBlocking$default(null, (Function2)((Function2)new Function2<CoroutineScope, Continuation<? super SyncProcessResult>, Object>(this, timeout, timeoutUnit, null){
            int label;
            final /* synthetic */ Executor this$0;
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

    public static /* synthetic */ SyncProcessResult startBlocking$default(Executor executor, long l, TimeUnit timeUnit, int n, Object object) throws IOException, InterruptedException, TimeoutException, InvalidExitValueException {
        if (object != null) {
            throw new UnsupportedOperationException("Super calls with default arguments not supported in this target, function: startBlocking");
        }
        if ((n & 1) != 0) {
            l = 0L;
        }
        if ((n & 2) != 0) {
            timeUnit = TimeUnit.SECONDS;
        }
        return executor.startBlocking(l, timeUnit);
    }

    /*
     * WARNING - Removed try catching itself - possible behaviour change.
     * WARNING - void declaration
     */
    private final DeferredProcessResult prepareProcess(long timeout, TimeUnit timeoutUnit, boolean asyncProcessStart) {
        Object timeoutInfo;
        Object $dstr$key$value;
        Object $this$forEach$iv;
        String prependPaths;
        String string2;
        boolean hasPathToPrepend;
        if (!(!this.inheritIO || !this.highPerformanceIO)) {
            boolean $i$a$-check-Executor$prepareProcess$32 = false;
            String $i$a$-check-Executor$prepareProcess$32 = "inheritIO & highPerformanceIO cannot be both set at the same time, they cancel each-other out";
            throw new IllegalStateException($i$a$-check-Executor$prepareProcess$32.toString());
        }
        this.listeners.beforeStart(this);
        List<String> command = this.builder.command();
        if (this.jvmExecOptions == null) {
            Intrinsics.checkNotNullExpressionValue(command, (String)"command");
            if (!(!((Collection)command).isEmpty())) {
                boolean $i$a$-check-Executor$prepareProcess$42 = false;
                String $i$a$-check-Executor$prepareProcess$42 = "Command has not been set.";
                throw new IllegalStateException($i$a$-check-Executor$prepareProcess$42.toString());
            }
        }
        boolean bl = hasPathToPrepend = !((Collection)this.pathsToPrepend).isEmpty();
        if (hasPathToPrepend) {
            Iterable iterable = this.pathsToPrepend;
            String string3 = File.pathSeparator;
            Intrinsics.checkNotNullExpressionValue((Object)string3, (String)"pathSeparator");
            string2 = CollectionsKt.joinToString$default((Iterable)iterable, (CharSequence)string3, null, null, (int)0, null, null, (int)62, null);
        } else {
            string2 = prependPaths = "";
        }
        if (!this.environment.isEmpty() || hasPathToPrepend) {
            String correctPathName;
            Map<String, String> systemEnv = System.getenv();
            boolean systemUsesAllCapsPath = systemEnv.get("PATH") != null;
            boolean systemUsesMixCasePath = systemEnv.get("Path") != null;
            boolean systemUsesLowCasePath = systemEnv.get("path") != null;
            String string4 = systemUsesAllCapsPath ? "PATH" : (correctPathName = systemUsesMixCasePath ? "Path" : "path");
            if (systemUsesAllCapsPath || systemUsesMixCasePath || systemUsesLowCasePath) {
                String localEnvUsesLowCasePath;
                String string5;
                String localEnvUsesMixCasePath;
                String string6;
                String localEnvUsesAllCapsPath;
                String string7 = this.environment.remove("PATH");
                if (string7 == null) {
                    string7 = localEnvUsesAllCapsPath = "";
                }
                if ((string6 = this.environment.remove("Path")) == null) {
                    string6 = localEnvUsesMixCasePath = "";
                }
                if ((string5 = this.environment.remove("path")) == null) {
                    string5 = localEnvUsesLowCasePath = "";
                }
                if (((CharSequence)localEnvUsesAllCapsPath).length() > 0 || ((CharSequence)localEnvUsesMixCasePath).length() > 0 || ((CharSequence)localEnvUsesLowCasePath).length() > 0) {
                    Object path = "";
                    if (((CharSequence)localEnvUsesAllCapsPath).length() > 0) {
                        path = Intrinsics.stringPlus((String)path, (Object)localEnvUsesAllCapsPath);
                    }
                    if (((CharSequence)localEnvUsesMixCasePath).length() > 0) {
                        if (((CharSequence)path).length() > 0) {
                            path = Intrinsics.stringPlus((String)path, (Object)File.pathSeparator);
                        }
                        path = Intrinsics.stringPlus((String)path, (Object)localEnvUsesMixCasePath);
                    }
                    if (((CharSequence)localEnvUsesLowCasePath).length() > 0) {
                        if (((CharSequence)path).length() > 0) {
                            path = Intrinsics.stringPlus((String)path, (Object)File.pathSeparator);
                        }
                        path = Intrinsics.stringPlus((String)path, (Object)localEnvUsesLowCasePath);
                    }
                    if (hasPathToPrepend) {
                        path = prependPaths + File.pathSeparator + (String)path;
                    }
                    this.environment.put(correctPathName, (String)path);
                } else {
                    this.environment.put(correctPathName, prependPaths);
                }
            } else if (hasPathToPrepend) {
                this.environment.put(correctPathName, prependPaths);
            }
            Map<String, String> env = this.builder.environment();
            $this$forEach$iv = this.environment;
            boolean $i$f$forEach = false;
            for (Map.Entry<String, String> element$iv : $this$forEach$iv.entrySet()) {
                $dstr$key$value = element$iv;
                boolean bl2 = false;
                String key = $dstr$key$value.getKey();
                String value = $dstr$key$value.getValue();
                if (value == null) {
                    env.remove(key);
                    continue;
                }
                Intrinsics.checkNotNullExpressionValue(env, (String)"env");
                env.put(key, value);
            }
        }
        if (this.jvmExecOptions != null) {
            JvmExecOptions jvmExecOptions = this.jvmExecOptions;
            Intrinsics.checkNotNull((Object)jvmExecOptions);
            JvmExecOptions jvm = jvmExecOptions;
            jvm.configure$Executor();
        }
        if (this.executeAsShell) {
            Object $this$forEach$iv22;
            Intrinsics.checkNotNullExpressionValue(command, (String)"command");
            String shellCommand = CollectionsKt.joinToString$default((Iterable)command, (CharSequence)" ", null, null, (int)0, null, null, (int)62, null);
            command.clear();
            if (IS_OS_WINDOWS) {
                Object[] systemUsesAllCapsPath = new String[]{"cmd", "/c"};
                command.addAll(CollectionsKt.listOf((Object[])systemUsesAllCapsPath));
            } else {
                String shell;
                if (DEFAULT_SHELL == null && (shell = System.getenv().get("SHELL")) != null && new File(shell).canExecute()) {
                    DEFAULT_SHELL = shell;
                }
                if (DEFAULT_SHELL == null) {
                    try {
                        Object systemUsesMixCasePath = new String[]{"sh", "-c", "echo $SHELL"};
                        systemUsesMixCasePath = Runtime.getRuntime().exec((String[])systemUsesMixCasePath).getInputStream();
                        Throwable systemUsesLowCasePath = null;
                        try {
                            Object inputStream = (InputStream)systemUsesMixCasePath;
                            boolean bl3 = false;
                            $this$forEach$iv = new Scanner((InputStream)inputStream).useDelimiter("\\A");
                            Throwable $i$f$forEach = null;
                            try {
                                String string8;
                                Object s = (Scanner)$this$forEach$iv;
                                boolean bl4 = false;
                                if (((Scanner)s).hasNext()) {
                                    $dstr$key$value = ((Scanner)s).next();
                                    Intrinsics.checkNotNullExpressionValue((Object)$dstr$key$value, (String)"s.next()");
                                    string8 = ((Object)StringsKt.trim((CharSequence)((CharSequence)$dstr$key$value))).toString();
                                } else {
                                    string8 = null;
                                }
                                s = string8;
                            }
                            catch (Throwable s) {
                                $i$f$forEach = s;
                                throw s;
                            }
                            finally {
                                CloseableKt.closeFinally((Closeable)$this$forEach$iv, (Throwable)$i$f$forEach);
                            }
                            inputStream = s;
                        }
                        catch (Throwable inputStream) {
                            systemUsesLowCasePath = inputStream;
                            throw inputStream;
                        }
                        finally {
                            CloseableKt.closeFinally((Closeable)systemUsesMixCasePath, (Throwable)systemUsesLowCasePath);
                        }
                        Object result = inputStream;
                        if (result != null && !StringsKt.isBlank((CharSequence)((CharSequence)result)) && new File((String)result).canExecute()) {
                            DEFAULT_SHELL = result;
                        }
                    }
                    catch (IOException result) {
                        // empty catch block
                    }
                }
                if (DEFAULT_SHELL == null) {
                    void $this$forEach$iv22;
                    String[] result = new String[]{"/bin/bash", "/usr/bin/bash", "/bin/pfbash", "/usr/bin/pfbash", "/bin/csh", "/usr/bin/csh", "/bin/pfcsh", "/usr/bin/pfcsh", "/bin/jsh", "/usr/bin/jsh", "/bin/ksh", "/usr/bin/ksh", "/bin/pfksh", "/usr/bin/pfksh", "/bin/ksh93", "/usr/bin/ksh93", "/bin/pfksh93", "/usr/bin/pfksh93", "/bin/pfsh", "/usr/bin/pfsh", "/bin/tcsh", "/usr/bin/tcsh", "/bin/pftcsh", "/usr/bin/pftcsh", "/usr/xpg4/bin/sh", "/usr/xp4/bin/pfsh", "/bin/zsh", "/usr/bin/zsh", "/bin/pfzsh", "/usr/bin/pfzsh", "/bin/sh", "/usr/bin/sh"};
                    boolean $i$f$forEach = false;
                    for (void element$iv : $this$forEach$iv22) {
                        void shell2 = element$iv;
                        boolean bl5 = false;
                        if (!new File((String)shell2).canExecute()) continue;
                        DEFAULT_SHELL = shell2;
                    }
                }
                if (DEFAULT_SHELL == null) {
                    throw new IllegalStateException("Unable to determine the default shell for the linux/unix environment.");
                }
                $this$forEach$iv22 = new String[2];
                Intrinsics.checkNotNull((Object)DEFAULT_SHELL);
                $this$forEach$iv22[1] = "-c";
                command.addAll(CollectionsKt.listOf((Object[])$this$forEach$iv22));
            }
            command.add(shellCommand);
            if (IS_OS_MAC && !this.environment.containsKey("SOFTWARE")) {
                $this$forEach$iv22 = this.environment;
                String $i$f$forEach = "SOFTWARE";
                String systemUsesLowCasePath = "";
                $this$forEach$iv22.put($i$f$forEach, systemUsesLowCasePath);
            }
            if (!this.environment.containsKey("LANG")) {
                $this$forEach$iv22 = this.environment;
                String $i$f$forEach = "LANG";
                String systemUsesLowCasePath = "C";
                $this$forEach$iv22.put($i$f$forEach, systemUsesLowCasePath);
            }
        }
        if (this.inheritIO) {
            this.builder.inheritIO();
        }
        ProcessAttributes attributes = this.getAttributes();
        CompositeProcessListener newListeners = this.listeners.clone();
        if (!this.readOutput && this.executeAsShell && this.streams.getOut$Executor() instanceof NopOutputStream) {
            if (IS_OS_WINDOWS) {
                command.add("2>&1>");
                command.add("nul");
            } else {
                command.add(">/dev/null");
                command.add("2>&1");
            }
        }
        try {
            Process process;
            String executeText;
            timeoutInfo = timeout > 0L ? "(timeout: " + timeout + ' ' + (Object)((Object)timeoutUnit) + ") " : "";
            String string9 = executeText = this.executeAsShell ? Intrinsics.stringPlus((String)"Executing as shell ", (Object)timeoutInfo) : Intrinsics.stringPlus((String)"Executing ", (Object)timeoutInfo);
            if (this.sshExecOptions != null) {
                StringBuilder stringBuilder = new StringBuilder().append(executeText).append(" on ");
                SshExecOptions sshExecOptions = this.sshExecOptions;
                Intrinsics.checkNotNull((Object)sshExecOptions);
                LogHelper.INSTANCE.logAtLowestLevel(this.logger, stringBuilder.append(sshExecOptions.info()).append(' ').append(this.getExecutingMessageParams()).toString(), new Object[0]);
                SshExecOptions sshExecOptions2 = this.sshExecOptions;
                Intrinsics.checkNotNull((Object)sshExecOptions2);
                process = sshExecOptions2.startProcess$Executor(timeout, timeoutUnit, this.logger);
            } else {
                LogHelper.INSTANCE.logAtLowestLevel(this.logger, executeText + ' ' + this.getExecutingMessageParams(), new Object[0]);
                process = this.builder.start();
            }
            timeoutInfo = process;
        }
        catch (Exception e) {
            String string10;
            if (this.sshExecOptions != null) {
                StringBuilder stringBuilder = new StringBuilder().append("Could not execute on ");
                SshExecOptions sshExecOptions = this.sshExecOptions;
                Intrinsics.checkNotNull((Object)sshExecOptions);
                string10 = stringBuilder.append(sshExecOptions.info()).append(' ').append(this.getExecutingMessageParams()).toString();
            } else {
                string10 = Intrinsics.stringPlus((String)"Could not execute ", (Object)this.getExecutingMessageParams());
            }
            String errorMessage = string10;
            ProcessInitException processInitException = ProcessInitException.Companion.newInstance(errorMessage, e);
            throw processInitException == null ? (Throwable)new IOException(errorMessage, e) : (Throwable)processInitException;
        }
        Object nativeProcess = timeoutInfo;
        IOStreamHandler streams = null;
        Function2 createProcessResults = null;
        Function1 errorMessageHandler = null;
        if (!this.readOutput) {
            streams = this.streams;
            createProcessResults = prepareProcess.5.INSTANCE;
            errorMessageHandler = (Function1)new Function1<StringBuilder, Unit>(attributes){
                final /* synthetic */ ProcessAttributes $attributes;
                {
                    this.$attributes = $attributes;
                    super(1);
                }

                public final void invoke(@NotNull StringBuilder sb) {
                    Intrinsics.checkNotNullParameter((Object)sb, (String)"sb");
                    DeferredProcessResult.Companion.addExceptionMessageSuffix$Executor(this.$attributes, sb, "");
                }
            };
        } else {
            streams = this.streams;
            if (asyncProcessStart) {
                streams = streams.asyncMode();
            }
            ByteArrayOutputStream out = new ByteArrayOutputStream();
            streams = streams.teeOutputStream(out);
            createProcessResults = (Function2)new Function2<Long, Integer, SyncProcessResult>(out){
                final /* synthetic */ ByteArrayOutputStream $out;
                {
                    this.$out = $out;
                    super(2);
                }

                @NotNull
                public final SyncProcessResult invoke(long pid, int exitValue) {
                    byte[] byArray = this.$out.toByteArray();
                    Intrinsics.checkNotNullExpressionValue((Object)byArray, (String)"out.toByteArray()");
                    return new SyncProcessResult(pid, exitValue, byArray);
                }
            };
            errorMessageHandler = (Function1)new Function1<StringBuilder, Unit>(out, attributes){
                final /* synthetic */ ByteArrayOutputStream $out;
                final /* synthetic */ ProcessAttributes $attributes;
                {
                    this.$out = $out;
                    this.$attributes = $attributes;
                    super(1);
                }

                public final void invoke(@NotNull StringBuilder sb) {
                    Intrinsics.checkNotNullParameter((Object)sb, (String)"sb");
                    byte[] byArray = this.$out.toByteArray();
                    Intrinsics.checkNotNullExpressionValue((Object)byArray, (String)"out.toByteArray()");
                    SyncProcessResult results = new SyncProcessResult(0L, 0, byArray);
                    DeferredProcessResult.Companion.addExceptionMessageSuffix$Executor(this.$attributes, sb, results.getOutput().string());
                }
            };
        }
        boolean separateErrorStream = !this.builder.redirectErrorStream();
        Intrinsics.checkNotNullExpressionValue((Object)nativeProcess, (String)"nativeProcess");
        streams.start((Process)nativeProcess, separateErrorStream, this.highPerformanceIO);
        newListeners.afterStart((Process)nativeProcess, this);
        Logger logger = this.logger;
        Params params = new Params(attributes, this.stopper, newListeners, streams, logger, (Function1<? super StringBuilder, Unit>)errorMessageHandler, this.closeTimeout, this.closeTimeoutUnit, asyncProcessStart);
        DeferredProcessResult deferred = new DeferredProcessResult((Process)nativeProcess, params, (Function2<? super Long, ? super Integer, ? extends SyncProcessResult>)createProcessResults);
        long processPid = deferred.getPid();
        if (processPid == -1L) {
            LogHelper.INSTANCE.logAtLowestLevel(logger, "Started process", new Object[0]);
        } else {
            Object[] objectArray = new Object[]{processPid};
            LogHelper.INSTANCE.logAtLowestLevel(logger, "Started process [pid={}]", objectArray);
        }
        deferred.start();
        return deferred;
    }

    @JvmOverloads
    @NotNull
    public final Executor redirectOutput() {
        return Executor.redirectOutput$default(this, null, 1, null);
    }

    @JvmOverloads
    @NotNull
    public final JvmExecOptions asJvmProcess() {
        return Executor.asJvmProcess$default(this, null, 1, null);
    }

    @JvmOverloads
    @NotNull
    public final DeferredProcessResult startAsShellAsync(long timeout) throws IOException {
        return Executor.startAsShellAsync$default(this, timeout, null, 2, null);
    }

    @JvmOverloads
    @NotNull
    public final DeferredProcessResult startAsShellAsync() throws IOException {
        return Executor.startAsShellAsync$default(this, 0L, null, 3, null);
    }

    @JvmOverloads
    @NotNull
    public final DeferredProcessResult startAsync(long timeout) throws IOException {
        return Executor.startAsync$default(this, timeout, null, 2, null);
    }

    @JvmOverloads
    @NotNull
    public final DeferredProcessResult startAsync() throws IOException {
        return Executor.startAsync$default(this, 0L, null, 3, null);
    }

    @JvmOverloads
    @Nullable
    public final Object startAsShell(long timeout, @NotNull Continuation<? super SyncProcessResult> $completion) throws IOException, InterruptedException, TimeoutException, InvalidExitValueException {
        return Executor.startAsShell$default(this, timeout, null, $completion, 2, null);
    }

    @JvmOverloads
    @Nullable
    public final Object startAsShell(@NotNull Continuation<? super SyncProcessResult> $completion) throws IOException, InterruptedException, TimeoutException, InvalidExitValueException {
        return Executor.startAsShell$default(this, 0L, null, $completion, 3, null);
    }

    @JvmOverloads
    @NotNull
    public final SyncProcessResult startAsShellBlocking(long timeout) throws IOException, InterruptedException, TimeoutException, InvalidExitValueException {
        return Executor.startAsShellBlocking$default(this, timeout, null, 2, null);
    }

    @JvmOverloads
    @NotNull
    public final SyncProcessResult startAsShellBlocking() throws IOException, InterruptedException, TimeoutException, InvalidExitValueException {
        return Executor.startAsShellBlocking$default(this, 0L, null, 3, null);
    }

    @JvmOverloads
    @Nullable
    public final Object start(long timeout, @NotNull Continuation<? super SyncProcessResult> $completion) throws IOException, InterruptedException, TimeoutException, InvalidExitValueException {
        return Executor.start$default(this, timeout, null, $completion, 2, null);
    }

    @JvmOverloads
    @Nullable
    public final Object start(@NotNull Continuation<? super SyncProcessResult> $completion) throws IOException, InterruptedException, TimeoutException, InvalidExitValueException {
        return Executor.start$default(this, 0L, null, $completion, 3, null);
    }

    @JvmOverloads
    @NotNull
    public final SyncProcessResult startBlocking(long timeout) throws IOException, InterruptedException, TimeoutException, InvalidExitValueException {
        return Executor.startBlocking$default(this, timeout, null, 2, null);
    }

    @JvmOverloads
    @NotNull
    public final SyncProcessResult startBlocking() throws IOException, InterruptedException, TimeoutException, InvalidExitValueException {
        return Executor.startBlocking$default(this, 0L, null, 3, null);
    }

    static {
        Logger logger = LoggerFactory.getLogger(Executor.class);
        Intrinsics.checkNotNull((Object)logger);
        log = logger;
        IO_DISPATCH = CoroutineScopeKt.CoroutineScope((CoroutineContext)((CoroutineContext)Dispatchers.getIO()));
        LINE_SEPARATOR = System.getProperty("line.separator");
        EXTRA_SPACE_REGEX = new Regex("\\s+");
        String string2 = System.getProperty("os.name");
        Intrinsics.checkNotNullExpressionValue((Object)string2, (String)"getProperty(\"os.name\")");
        String string3 = string2.toLowerCase(Locale.ROOT);
        Intrinsics.checkNotNullExpressionValue((Object)string3, (String)"this as java.lang.String).toLowerCase(Locale.ROOT)");
        String osName = string3;
        IS_OS_WINDOWS = StringsKt.startsWith$default((String)osName, (String)"win", (boolean)false, (int)2, null);
        IS_OS_MAC = StringsKt.startsWith$default((String)osName, (String)"mac", (boolean)false, (int)2, null) || StringsKt.startsWith$default((String)osName, (String)"darwin", (boolean)false, (int)2, null);
        Updates.INSTANCE.add(Executor.class, "03fcf3762a2b4f68b5e968aaf79f3a72", version);
    }

    @Metadata(mv={1, 6, 0}, k=1, xi=48, d1={"\u0000P\n\u0002\u0018\u0002\n\u0002\u0010\u0000\n\u0002\b\u0002\n\u0002\u0010\u0011\n\u0002\u0010\b\n\u0002\b\u0004\n\u0002\u0010\u000b\n\u0000\n\u0002\u0010\u000e\n\u0000\n\u0002\u0018\u0002\n\u0000\n\u0002\u0018\u0002\n\u0002\b\u000b\n\u0002\u0018\u0002\n\u0002\b\u0004\n\u0002\u0010!\n\u0000\n\u0002\u0010\u001c\n\u0002\b\u0003\n\u0002\u0018\u0002\n\u0002\b\u0004\b\u0086\u0003\u0018\u00002\u00020\u0001B\u0007\b\u0002\u00a2\u0006\u0002\u0010\u0002J!\u0010 \u001a\b\u0012\u0004\u0012\u00020\f0!2\f\u0010\"\u001a\b\u0012\u0004\u0012\u00020\f0#H\u0000\u00a2\u0006\u0002\b$J'\u0010%\u001a\u00020\f2\u0006\u0010&\u001a\u00020'2\u0012\u0010(\u001a\n\u0012\u0006\b\u0001\u0012\u00020\f0\u0004\"\u00020\f\u00a2\u0006\u0002\u0010)J\u001c\u0010%\u001a\u00020\f2\u0006\u0010&\u001a\u00020'2\f\u0010(\u001a\b\u0012\u0004\u0012\u00020\f0#J\u001f\u0010%\u001a\u00020\f2\u0012\u0010\"\u001a\n\u0012\u0006\b\u0001\u0012\u00020\f0\u0004\"\u00020\f\u00a2\u0006\u0002\u0010*J\u0014\u0010%\u001a\u00020\f2\f\u0010\"\u001a\b\u0012\u0004\u0012\u00020\f0#R\u001b\u0010\u0003\u001a\n\u0012\u0004\u0012\u00020\u0005\u0018\u00010\u0004\u00a2\u0006\n\n\u0002\u0010\b\u001a\u0004\b\u0006\u0010\u0007R\u000e\u0010\t\u001a\u00020\nX\u0086T\u00a2\u0006\u0002\n\u0000R\u0010\u0010\u000b\u001a\u0004\u0018\u00010\fX\u0082\u000e\u00a2\u0006\u0002\n\u0000R\u000e\u0010\r\u001a\u00020\u000eX\u0082\u0004\u00a2\u0006\u0002\n\u0000R\u0014\u0010\u000f\u001a\u00020\u0010X\u0080\u0004\u00a2\u0006\b\n\u0000\u001a\u0004\b\u0011\u0010\u0012R\u0011\u0010\u0013\u001a\u00020\n\u00a2\u0006\b\n\u0000\u001a\u0004\b\u0014\u0010\u0015R\u0011\u0010\u0016\u001a\u00020\n\u00a2\u0006\b\n\u0000\u001a\u0004\b\u0017\u0010\u0015R\u0016\u0010\u0018\u001a\n \u0019*\u0004\u0018\u00010\f0\fX\u0082\u0004\u00a2\u0006\u0002\n\u0000R\u000e\u0010\u001a\u001a\u00020\u0005X\u0082T\u00a2\u0006\u0002\n\u0000R\u0011\u0010\u001b\u001a\u00020\u001c\u00a2\u0006\b\n\u0000\u001a\u0004\b\u001d\u0010\u001eR\u000e\u0010\u001f\u001a\u00020\fX\u0086T\u00a2\u0006\u0002\n\u0000\u00a8\u0006+"}, d2={"Ldorkbox/executor/Executor$Companion;", "", "()V", "DEFAULT_EXIT_VALUES", "", "", "getDEFAULT_EXIT_VALUES", "()[Ljava/lang/Integer;", "[Ljava/lang/Integer;", "DEFAULT_REDIRECT_ERROR_STREAM", "", "DEFAULT_SHELL", "", "EXTRA_SPACE_REGEX", "Lkotlin/text/Regex;", "IO_DISPATCH", "Lkotlinx/coroutines/CoroutineScope;", "getIO_DISPATCH$Executor", "()Lkotlinx/coroutines/CoroutineScope;", "IS_OS_MAC", "getIS_OS_MAC", "()Z", "IS_OS_WINDOWS", "getIS_OS_WINDOWS", "LINE_SEPARATOR", "kotlin.jvm.PlatformType", "NORMAL_EXIT_VALUE", "log", "Lorg/slf4j/Logger;", "getLog", "()Lorg/slf4j/Logger;", "version", "fixArguments", "", "command", "", "fixArguments$Executor", "run", "executable", "Ljava/io/File;", "args", "(Ljava/io/File;[Ljava/lang/String;)Ljava/lang/String;", "([Ljava/lang/String;)Ljava/lang/String;", "Executor"})
    public static final class Companion {
        private Companion() {
        }

        @NotNull
        public final Logger getLog() {
            return log;
        }

        public final boolean getIS_OS_WINDOWS() {
            return IS_OS_WINDOWS;
        }

        public final boolean getIS_OS_MAC() {
            return IS_OS_MAC;
        }

        @Nullable
        public final Integer[] getDEFAULT_EXIT_VALUES() {
            return DEFAULT_EXIT_VALUES;
        }

        @NotNull
        public final CoroutineScope getIO_DISPATCH$Executor() {
            return IO_DISPATCH;
        }

        @NotNull
        public final List<String> fixArguments$Executor(@NotNull Iterable<String> command) {
            List list;
            Intrinsics.checkNotNullParameter(command, (String)"command");
            if (!this.getIS_OS_WINDOWS()) {
                return CollectionsKt.toMutableList(command);
            }
            List $this$fixArguments_u24lambda_u2d0 = list = (List)new ArrayList();
            boolean bl = false;
            CollectionsKt.addAll((Collection)$this$fixArguments_u24lambda_u2d0, command);
            List result = list;
            ListIterator<String> it = result.listIterator();
            while (it.hasNext()) {
                if (!Intrinsics.areEqual((Object)"", it.next())) continue;
                it.set("\"\"");
            }
            return result;
        }

        @NotNull
        public final String run(@NotNull Iterable<String> command) {
            Intrinsics.checkNotNullParameter(command, (String)"command");
            return Executor.startBlocking$default(new Executor().command(command).enableRead(), 0L, null, 3, null).getOutput().utf8();
        }

        @NotNull
        public final String run(@NotNull File executable, @NotNull Iterable<String> args) {
            Intrinsics.checkNotNullParameter((Object)executable, (String)"executable");
            Intrinsics.checkNotNullParameter(args, (String)"args");
            return Executor.startBlocking$default(new Executor().executable(executable).command(args).enableRead(), 0L, null, 3, null).getOutput().utf8();
        }

        @NotNull
        public final String run(String ... command) {
            Intrinsics.checkNotNullParameter((Object)command, (String)"command");
            return Executor.startBlocking$default(new Executor().command(CollectionsKt.listOf((Object[])Arrays.copyOf(command, command.length))).enableRead(), 0L, null, 3, null).getOutput().utf8();
        }

        @NotNull
        public final String run(@NotNull File executable, String ... args) {
            Intrinsics.checkNotNullParameter((Object)executable, (String)"executable");
            Intrinsics.checkNotNullParameter((Object)args, (String)"args");
            return Executor.startBlocking$default(new Executor().executable(executable).command(CollectionsKt.listOf((Object[])Arrays.copyOf(args, args.length))).enableRead(), 0L, null, 3, null).getOutput().utf8();
        }

        public /* synthetic */ Companion(DefaultConstructorMarker $constructor_marker) {
            this();
        }
    }
}

