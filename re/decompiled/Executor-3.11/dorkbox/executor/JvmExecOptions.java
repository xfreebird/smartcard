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
 *  kotlin.text.Regex
 *  kotlinx.coroutines.BuildersKt
 *  kotlinx.coroutines.CoroutineScope
 *  org.jetbrains.annotations.NotNull
 *  org.jetbrains.annotations.Nullable
 *  org.slf4j.Logger
 *  org.slf4j.LoggerFactory
 */
package dorkbox.executor;

import dorkbox.executor.DeferredProcessResult;
import dorkbox.executor.Executor;
import dorkbox.executor.JvmHelper;
import dorkbox.executor.exceptions.InvalidExitValueException;
import dorkbox.executor.processResults.SyncProcessResult;
import java.io.File;
import java.io.IOException;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.Collection;
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
import kotlin.text.Regex;
import kotlinx.coroutines.BuildersKt;
import kotlinx.coroutines.CoroutineScope;
import org.jetbrains.annotations.NotNull;
import org.jetbrains.annotations.Nullable;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

@Metadata(mv={1, 6, 0}, k=1, xi=48, d1={"\u0000j\n\u0002\u0018\u0002\n\u0002\u0010\u0000\n\u0000\n\u0002\u0018\u0002\n\u0000\n\u0002\u0010\u000e\n\u0002\b\u0002\n\u0002\u0010!\n\u0002\b\u0003\n\u0002\u0010\u000b\n\u0002\b\u0005\n\u0002\u0010\b\n\u0002\b\n\n\u0002\u0018\u0002\n\u0002\b\u0010\n\u0002\u0010\u0011\n\u0000\n\u0002\u0010\u001c\n\u0002\b\u0004\n\u0002\u0010\u0002\n\u0002\b\b\n\u0002\u0018\u0002\n\u0000\n\u0002\u0010\t\n\u0000\n\u0002\u0018\u0002\n\u0002\b\u0002\n\u0002\u0018\u0002\n\u0002\b\u0003\u0018\u0000 G2\u00020\u0001:\u0001GB\u0019\u0012\u0006\u0010\u0002\u001a\u00020\u0003\u0012\n\b\u0002\u0010\u0004\u001a\u0004\u0018\u00010\u0005\u00a2\u0006\u0002\u0010\u0006J\u001f\u0010,\u001a\u00020\u00002\u0012\u0010-\u001a\n\u0012\u0006\b\u0001\u0012\u00020\u00050.\"\u00020\u0005\u00a2\u0006\u0002\u0010/J\u0014\u0010,\u001a\u00020\u00002\f\u0010-\u001a\b\u0012\u0004\u0012\u00020\u000500J\u001f\u00101\u001a\u00020\u00002\u0012\u00102\u001a\n\u0012\u0006\b\u0001\u0012\u00020\u00050.\"\u00020\u0005\u00a2\u0006\u0002\u0010/J\u001f\u00103\u001a\u00020\u00002\u0012\u0010-\u001a\n\u0012\u0006\b\u0001\u0012\u00020\u00050.\"\u00020\u0005\u00a2\u0006\u0002\u0010/J\u0006\u0010\u000b\u001a\u00020\u0000J\r\u00104\u001a\u000205H\u0000\u00a2\u0006\u0002\b6J\u0006\u00107\u001a\u00020\u0005J\u000e\u00108\u001a\u00020\u00002\u0006\u0010\u0011\u001a\u00020\u0012J\u000e\u00109\u001a\u00020\u00002\u0006\u0010\u0017\u001a\u00020\u0005J\u000e\u0010:\u001a\u00020\u00002\u0006\u0010\u001c\u001a\u00020\u001dJ\u000e\u0010:\u001a\u00020\u00002\u0006\u0010\u001c\u001a\u00020\u0005J\u000e\u0010;\u001a\u00020\u00002\u0006\u0010$\u001a\u00020\u0005J\u000e\u0010<\u001a\u00020\u00002\u0006\u0010)\u001a\u00020\u0012J%\u0010=\u001a\u00020>2\b\b\u0002\u0010?\u001a\u00020@2\b\b\u0002\u0010A\u001a\u00020BH\u0087@\u00f8\u0001\u0000\u00a2\u0006\u0002\u0010CJ\u001c\u0010D\u001a\u00020E2\b\b\u0002\u0010?\u001a\u00020@2\b\b\u0002\u0010A\u001a\u00020BH\u0007J\u001c\u0010F\u001a\u00020>2\b\b\u0002\u0010?\u001a\u00020@2\b\b\u0002\u0010A\u001a\u00020BH\u0007R\u001a\u0010\u0007\u001a\b\u0012\u0004\u0012\u00020\u00050\bX\u0080\u0004\u00a2\u0006\b\n\u0000\u001a\u0004\b\t\u0010\nR\u001a\u0010\u000b\u001a\u00020\fX\u0080\u000e\u00a2\u0006\u000e\n\u0000\u001a\u0004\b\r\u0010\u000e\"\u0004\b\u000f\u0010\u0010R\u000e\u0010\u0002\u001a\u00020\u0003X\u0082\u0004\u00a2\u0006\u0002\n\u0000R\u001a\u0010\u0011\u001a\u00020\u0012X\u0080\u000e\u00a2\u0006\u000e\n\u0000\u001a\u0004\b\u0013\u0010\u0014\"\u0004\b\u0015\u0010\u0016R\u001c\u0010\u0017\u001a\u0004\u0018\u00010\u0005X\u0080\u000e\u00a2\u0006\u000e\n\u0000\u001a\u0004\b\u0018\u0010\u0019\"\u0004\b\u001a\u0010\u001bR\u0010\u0010\u0004\u001a\u0004\u0018\u00010\u0005X\u0082\u0004\u00a2\u0006\u0002\n\u0000R\u001a\u0010\u001c\u001a\u00020\u001dX\u0080\u000e\u00a2\u0006\u000e\n\u0000\u001a\u0004\b\u001e\u0010\u001f\"\u0004\b \u0010!R\u001a\u0010\"\u001a\b\u0012\u0004\u0012\u00020\u00050\bX\u0080\u0004\u00a2\u0006\b\n\u0000\u001a\u0004\b#\u0010\nR\u001c\u0010$\u001a\u0004\u0018\u00010\u0005X\u0080\u000e\u00a2\u0006\u000e\n\u0000\u001a\u0004\b%\u0010\u0019\"\u0004\b&\u0010\u001bR\u001a\u0010'\u001a\b\u0012\u0004\u0012\u00020\u00050\bX\u0080\u0004\u00a2\u0006\b\n\u0000\u001a\u0004\b(\u0010\nR\u001a\u0010)\u001a\u00020\u0012X\u0080\u000e\u00a2\u0006\u000e\n\u0000\u001a\u0004\b*\u0010\u0014\"\u0004\b+\u0010\u0016\u0082\u0002\u0004\n\u0002\b\u0019\u00a8\u0006H"}, d2={"Ldorkbox/executor/JvmExecOptions;", "", "executor", "Ldorkbox/executor/Executor;", "javaExecutable", "", "(Ldorkbox/executor/Executor;Ljava/lang/String;)V", "classpathEntries", "", "getClasspathEntries$Executor", "()Ljava/util/List;", "cloneClasspath", "", "getCloneClasspath$Executor", "()Z", "setCloneClasspath$Executor", "(Z)V", "initialHeapSizeInMegabytes", "", "getInitialHeapSizeInMegabytes$Executor", "()I", "setInitialHeapSizeInMegabytes$Executor", "(I)V", "jarFile", "getJarFile$Executor", "()Ljava/lang/String;", "setJarFile$Executor", "(Ljava/lang/String;)V", "javaLocation", "Ljava/io/File;", "getJavaLocation$Executor", "()Ljava/io/File;", "setJavaLocation$Executor", "(Ljava/io/File;)V", "jvmOptions", "getJvmOptions$Executor", "mainClass", "getMainClass$Executor", "setMainClass$Executor", "mainClassArguments", "getMainClassArguments$Executor", "maximumHeapSizeInMegabytes", "getMaximumHeapSizeInMegabytes$Executor", "setMaximumHeapSizeInMegabytes$Executor", "addArg", "arguments", "", "([Ljava/lang/String;)Ldorkbox/executor/JvmExecOptions;", "", "addJvmClasspath", "classpath", "addJvmOption", "configure", "", "configure$Executor", "getClasspath", "setInitialHeapSizeInMegabytes", "setJarFile", "setJava", "setMainClass", "setMaximumHeapSizeInMegabytes", "start", "Ldorkbox/executor/processResults/SyncProcessResult;", "timeout", "", "timeoutUnit", "Ljava/util/concurrent/TimeUnit;", "(JLjava/util/concurrent/TimeUnit;Lkotlin/coroutines/Continuation;)Ljava/lang/Object;", "startAsync", "Ldorkbox/executor/DeferredProcessResult;", "startBlocking", "Companion", "Executor"})
public final class JvmExecOptions {
    @NotNull
    public static final Companion Companion = new Companion(null);
    @NotNull
    private final Executor executor;
    @Nullable
    private final String javaExecutable;
    @NotNull
    private File javaLocation;
    @Nullable
    private String mainClass;
    private int initialHeapSizeInMegabytes;
    private int maximumHeapSizeInMegabytes;
    @NotNull
    private final List<String> jvmOptions;
    @NotNull
    private final List<String> classpathEntries;
    @NotNull
    private final List<String> mainClassArguments;
    @Nullable
    private String jarFile;
    private boolean cloneClasspath;
    private static final Logger log = LoggerFactory.getLogger(JvmExecOptions.class);
    @NotNull
    private static final Regex SPACE_REGEX = new Regex(" ");

    public JvmExecOptions(@NotNull Executor executor, @Nullable String javaExecutable) {
        Intrinsics.checkNotNullParameter((Object)executor, (String)"executor");
        this.executor = executor;
        this.javaExecutable = javaExecutable;
        this.javaLocation = JvmHelper.INSTANCE.getJvmPath(Executor.Companion.getIS_OS_MAC(), Executor.Companion.getIS_OS_WINDOWS());
        this.jvmOptions = new ArrayList();
        this.classpathEntries = new ArrayList();
        this.mainClassArguments = new ArrayList();
    }

    public /* synthetic */ JvmExecOptions(Executor executor, String string2, int n, DefaultConstructorMarker defaultConstructorMarker) {
        if ((n & 2) != 0) {
            string2 = null;
        }
        this(executor, string2);
    }

    @NotNull
    public final File getJavaLocation$Executor() {
        return this.javaLocation;
    }

    public final void setJavaLocation$Executor(@NotNull File file) {
        Intrinsics.checkNotNullParameter((Object)file, (String)"<set-?>");
        this.javaLocation = file;
    }

    @Nullable
    public final String getMainClass$Executor() {
        return this.mainClass;
    }

    public final void setMainClass$Executor(@Nullable String string2) {
        this.mainClass = string2;
    }

    public final int getInitialHeapSizeInMegabytes$Executor() {
        return this.initialHeapSizeInMegabytes;
    }

    public final void setInitialHeapSizeInMegabytes$Executor(int n) {
        this.initialHeapSizeInMegabytes = n;
    }

    public final int getMaximumHeapSizeInMegabytes$Executor() {
        return this.maximumHeapSizeInMegabytes;
    }

    public final void setMaximumHeapSizeInMegabytes$Executor(int n) {
        this.maximumHeapSizeInMegabytes = n;
    }

    @NotNull
    public final List<String> getJvmOptions$Executor() {
        return this.jvmOptions;
    }

    @NotNull
    public final List<String> getClasspathEntries$Executor() {
        return this.classpathEntries;
    }

    @NotNull
    public final List<String> getMainClassArguments$Executor() {
        return this.mainClassArguments;
    }

    @Nullable
    public final String getJarFile$Executor() {
        return this.jarFile;
    }

    public final void setJarFile$Executor(@Nullable String string2) {
        this.jarFile = string2;
    }

    public final boolean getCloneClasspath$Executor() {
        return this.cloneClasspath;
    }

    public final void setCloneClasspath$Executor(boolean bl) {
        this.cloneClasspath = bl;
    }

    @NotNull
    public final String getClasspath() {
        StringBuilder builder = new StringBuilder();
        int count = 0;
        int totalSize = this.classpathEntries.size();
        String pathSeparator = File.pathSeparator;
        Iterable $this$forEach$iv = this.classpathEntries;
        boolean $i$f$forEach = false;
        for (Object element$iv : $this$forEach$iv) {
            String it = (String)element$iv;
            boolean bl = false;
            try {
                CharSequence charSequence = it;
                Regex regex = SPACE_REGEX;
                String string2 = "\\ ";
                CharSequence classpathEntry = regex.replace(charSequence, string2);
                charSequence = new File((String)classpathEntry).getAbsolutePath();
                Intrinsics.checkNotNullExpressionValue((Object)charSequence, (String)"File(classpathEntry).absolutePath");
                classpathEntry = charSequence;
                builder.append((String)classpathEntry);
                int n = count;
                count = n + 1;
            }
            catch (Exception e) {
                log.error("Error processing classpath!!", (Throwable)e);
            }
            if (count >= totalSize) continue;
            builder.append(pathSeparator);
        }
        if (this.cloneClasspath) {
            String additionalClasspath = System.getProperty("java.class.path");
            Intrinsics.checkNotNullExpressionValue((Object)additionalClasspath, (String)"additionalClasspath");
            if (((CharSequence)additionalClasspath).length() > 0) {
                if (count > 0) {
                    builder.append(pathSeparator);
                }
                builder.append(additionalClasspath);
            }
        }
        String string3 = builder.toString();
        Intrinsics.checkNotNullExpressionValue((Object)string3, (String)"builder.toString()");
        return string3;
    }

    @NotNull
    public final JvmExecOptions setInitialHeapSizeInMegabytes(int initialHeapSizeInMegabytes) {
        this.initialHeapSizeInMegabytes = initialHeapSizeInMegabytes;
        return this;
    }

    @NotNull
    public final JvmExecOptions setMaximumHeapSizeInMegabytes(int maximumHeapSizeInMegabytes) {
        this.maximumHeapSizeInMegabytes = maximumHeapSizeInMegabytes;
        return this;
    }

    @NotNull
    public final JvmExecOptions cloneClasspath() {
        this.cloneClasspath = true;
        return this;
    }

    @NotNull
    public final JvmExecOptions setMainClass(@NotNull String mainClass) {
        Intrinsics.checkNotNullParameter((Object)mainClass, (String)"mainClass");
        this.mainClass = mainClass;
        return this;
    }

    @NotNull
    public final JvmExecOptions addJvmClasspath(String ... classpath) {
        Intrinsics.checkNotNullParameter((Object)classpath, (String)"classpath");
        String[] $this$forEach$iv = classpath;
        boolean $i$f$forEach = false;
        for (String element$iv : $this$forEach$iv) {
            String it = element$iv;
            boolean bl = false;
            this.getClasspathEntries$Executor().add(it);
        }
        return this;
    }

    @NotNull
    public final JvmExecOptions addJvmOption(String ... arguments) {
        Intrinsics.checkNotNullParameter((Object)arguments, (String)"arguments");
        String[] $this$forEach$iv = arguments;
        boolean $i$f$forEach = false;
        for (String element$iv : $this$forEach$iv) {
            String it = element$iv;
            boolean bl = false;
            this.getJvmOptions$Executor().add(it);
        }
        return this;
    }

    @NotNull
    public final JvmExecOptions setJarFile(@NotNull String jarFile) {
        Intrinsics.checkNotNullParameter((Object)jarFile, (String)"jarFile");
        this.jarFile = jarFile;
        return this;
    }

    @NotNull
    public final JvmExecOptions setJava(@NotNull String javaLocation) {
        Intrinsics.checkNotNullParameter((Object)javaLocation, (String)"javaLocation");
        this.javaLocation = new File(javaLocation);
        return this;
    }

    @NotNull
    public final JvmExecOptions setJava(@NotNull File javaLocation) {
        Intrinsics.checkNotNullParameter((Object)javaLocation, (String)"javaLocation");
        this.javaLocation = javaLocation;
        return this;
    }

    @NotNull
    public final JvmExecOptions addArg(String ... arguments) {
        Intrinsics.checkNotNullParameter((Object)arguments, (String)"arguments");
        List<String> fixed = Executor.Companion.fixArguments$Executor(CollectionsKt.listOf((Object[])Arrays.copyOf(arguments, arguments.length)));
        this.mainClassArguments.addAll((Collection<String>)fixed);
        return this;
    }

    @NotNull
    public final JvmExecOptions addArg(@NotNull Iterable<String> arguments) {
        Intrinsics.checkNotNullParameter(arguments, (String)"arguments");
        List<String> fixed = Executor.Companion.fixArguments$Executor(arguments);
        this.mainClassArguments.addAll((Collection<String>)fixed);
        return this;
    }

    @JvmOverloads
    @Nullable
    public final Object start(long timeout, @NotNull TimeUnit timeoutUnit, @NotNull Continuation<? super SyncProcessResult> $completion) throws IOException, InterruptedException, TimeoutException, InvalidExitValueException {
        return this.executor.start(timeout, timeoutUnit, $completion);
    }

    public static /* synthetic */ Object start$default(JvmExecOptions jvmExecOptions, long l, TimeUnit timeUnit, Continuation continuation, int n, Object object) throws IOException, InterruptedException, TimeoutException, InvalidExitValueException {
        if ((n & 1) != 0) {
            l = 0L;
        }
        if ((n & 2) != 0) {
            timeUnit = TimeUnit.SECONDS;
        }
        return jvmExecOptions.start(l, timeUnit, (Continuation<? super SyncProcessResult>)continuation);
    }

    @JvmOverloads
    @NotNull
    public final DeferredProcessResult startAsync(long timeout, @NotNull TimeUnit timeoutUnit) throws IOException {
        Intrinsics.checkNotNullParameter((Object)((Object)timeoutUnit), (String)"timeoutUnit");
        return this.executor.startAsync(timeout, timeoutUnit);
    }

    public static /* synthetic */ DeferredProcessResult startAsync$default(JvmExecOptions jvmExecOptions, long l, TimeUnit timeUnit, int n, Object object) throws IOException {
        if ((n & 1) != 0) {
            l = 0L;
        }
        if ((n & 2) != 0) {
            timeUnit = TimeUnit.SECONDS;
        }
        return jvmExecOptions.startAsync(l, timeUnit);
    }

    @JvmOverloads
    @NotNull
    public final SyncProcessResult startBlocking(long timeout, @NotNull TimeUnit timeoutUnit) throws IOException, InterruptedException, TimeoutException, InvalidExitValueException {
        Intrinsics.checkNotNullParameter((Object)((Object)timeoutUnit), (String)"timeoutUnit");
        return (SyncProcessResult)BuildersKt.runBlocking$default(null, (Function2)((Function2)new Function2<CoroutineScope, Continuation<? super SyncProcessResult>, Object>(this, timeout, timeoutUnit, null){
            int label;
            final /* synthetic */ JvmExecOptions this$0;
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

    public static /* synthetic */ SyncProcessResult startBlocking$default(JvmExecOptions jvmExecOptions, long l, TimeUnit timeUnit, int n, Object object) throws IOException, InterruptedException, TimeoutException, InvalidExitValueException {
        if ((n & 1) != 0) {
            l = 0L;
        }
        if ((n & 2) != 0) {
            timeUnit = TimeUnit.SECONDS;
        }
        return jvmExecOptions.startBlocking(l, timeUnit);
    }

    public final void configure$Executor() {
        List<String> commandLineArgs = this.executor.getBuilder$Executor().command();
        List newArgs = new ArrayList();
        if (this.javaExecutable != null) {
            newArgs.add(this.javaExecutable);
        } else {
            String string2 = this.javaLocation.getCanonicalFile().getPath();
            Intrinsics.checkNotNullExpressionValue((Object)string2, (String)"javaLocation.canonicalFile.path");
            newArgs.add(string2);
        }
        if (this.initialHeapSizeInMegabytes != 0) {
            newArgs.add("-Xms");
            newArgs.add("" + this.initialHeapSizeInMegabytes + 'M');
        }
        if (this.maximumHeapSizeInMegabytes != 0) {
            newArgs.add("-Xmx");
            newArgs.add("" + this.maximumHeapSizeInMegabytes + 'M');
        }
        if (!((Collection)this.jvmOptions).isEmpty()) {
            newArgs.addAll((Collection)Executor.Companion.fixArguments$Executor((Iterable<String>)this.jvmOptions));
        }
        Intrinsics.checkNotNullExpressionValue(commandLineArgs, (String)"commandLineArgs");
        newArgs.addAll((Collection)commandLineArgs);
        String classpath = this.getClasspath();
        if (this.jarFile != null) {
            newArgs.add("-jar");
            String string3 = this.jarFile;
            Intrinsics.checkNotNull((Object)string3);
            newArgs.add(string3);
            if (!(((CharSequence)classpath).length() == 0)) {
                boolean bl = false;
                String string4 = "WHOOPS.  You CANNOT have a classpath specified on the commandline when using JARs, it must be set in the JARs MANIFEST instead.";
                throw new IllegalArgumentException(string4.toString());
            }
        } else if (this.mainClass != null) {
            if (((CharSequence)classpath).length() > 0) {
                newArgs.add("--class-path");
                newArgs.add(classpath);
            }
            String string5 = this.mainClass;
            Intrinsics.checkNotNull((Object)string5);
            newArgs.add(string5);
        } else {
            throw new IllegalArgumentException("You must specify a jar or main class when running a java process!");
        }
        if (!((Collection)this.mainClassArguments).isEmpty()) {
            newArgs.addAll((Collection)Executor.Companion.fixArguments$Executor((Iterable<String>)this.mainClassArguments));
        }
        this.executor.getBuilder$Executor().command(newArgs);
    }

    @JvmOverloads
    @Nullable
    public final Object start(long timeout, @NotNull Continuation<? super SyncProcessResult> $completion) throws IOException, InterruptedException, TimeoutException, InvalidExitValueException {
        return JvmExecOptions.start$default(this, timeout, null, $completion, 2, null);
    }

    @JvmOverloads
    @Nullable
    public final Object start(@NotNull Continuation<? super SyncProcessResult> $completion) throws IOException, InterruptedException, TimeoutException, InvalidExitValueException {
        return JvmExecOptions.start$default(this, 0L, null, $completion, 3, null);
    }

    @JvmOverloads
    @NotNull
    public final DeferredProcessResult startAsync(long timeout) throws IOException {
        return JvmExecOptions.startAsync$default(this, timeout, null, 2, null);
    }

    @JvmOverloads
    @NotNull
    public final DeferredProcessResult startAsync() throws IOException {
        return JvmExecOptions.startAsync$default(this, 0L, null, 3, null);
    }

    @JvmOverloads
    @NotNull
    public final SyncProcessResult startBlocking(long timeout) throws IOException, InterruptedException, TimeoutException, InvalidExitValueException {
        return JvmExecOptions.startBlocking$default(this, timeout, null, 2, null);
    }

    @JvmOverloads
    @NotNull
    public final SyncProcessResult startBlocking() throws IOException, InterruptedException, TimeoutException, InvalidExitValueException {
        return JvmExecOptions.startBlocking$default(this, 0L, null, 3, null);
    }

    @Metadata(mv={1, 6, 0}, k=1, xi=48, d1={"\u0000\u001a\n\u0002\u0018\u0002\n\u0002\u0010\u0000\n\u0002\b\u0002\n\u0002\u0018\u0002\n\u0000\n\u0002\u0018\u0002\n\u0002\b\u0002\b\u0086\u0003\u0018\u00002\u00020\u0001B\u0007\b\u0002\u00a2\u0006\u0002\u0010\u0002R\u000e\u0010\u0003\u001a\u00020\u0004X\u0082\u0004\u00a2\u0006\u0002\n\u0000R\u0016\u0010\u0005\u001a\n \u0007*\u0004\u0018\u00010\u00060\u0006X\u0082\u0004\u00a2\u0006\u0002\n\u0000\u00a8\u0006\b"}, d2={"Ldorkbox/executor/JvmExecOptions$Companion;", "", "()V", "SPACE_REGEX", "Lkotlin/text/Regex;", "log", "Lorg/slf4j/Logger;", "kotlin.jvm.PlatformType", "Executor"})
    public static final class Companion {
        private Companion() {
        }

        public /* synthetic */ Companion(DefaultConstructorMarker $constructor_marker) {
            this();
        }
    }
}

