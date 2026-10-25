/*
 * Decompiled with CFR 0.152.
 * 
 * Could not load the following classes:
 *  ch.qos.logback.classic.Level
 *  ch.qos.logback.classic.Logger
 *  kotlin.Metadata
 *  kotlin.collections.CollectionsKt
 *  kotlin.jvm.internal.Intrinsics
 *  kotlin.text.StringsKt
 *  net.schmizz.sshj.SSHClient
 *  net.schmizz.sshj.common.KeyType
 *  net.schmizz.sshj.common.LoggerFactory
 *  net.schmizz.sshj.transport.kex.Curve25519SHA256
 *  net.schmizz.sshj.transport.random.JCERandom
 *  org.jetbrains.annotations.NotNull
 *  org.jetbrains.annotations.Nullable
 *  org.slf4j.Logger
 *  org.slf4j.LoggerFactory
 *  org.slf4j.helpers.MarkerIgnoringBase
 *  org.slf4j.helpers.NOPLogger
 */
package dorkbox.executor;

import ch.qos.logback.classic.Level;
import dorkbox.executor.SshExecOptions;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.Collection;
import java.util.List;
import kotlin.Metadata;
import kotlin.collections.CollectionsKt;
import kotlin.jvm.internal.Intrinsics;
import kotlin.text.StringsKt;
import net.schmizz.sshj.SSHClient;
import net.schmizz.sshj.common.KeyType;
import net.schmizz.sshj.common.LoggerFactory;
import net.schmizz.sshj.transport.kex.Curve25519SHA256;
import net.schmizz.sshj.transport.random.JCERandom;
import org.jetbrains.annotations.NotNull;
import org.jetbrains.annotations.Nullable;
import org.slf4j.Logger;
import org.slf4j.helpers.MarkerIgnoringBase;
import org.slf4j.helpers.NOPLogger;

@Metadata(mv={1, 6, 0}, k=1, xi=48, d1={"\u0000.\n\u0002\u0018\u0002\n\u0002\u0010\u0000\n\u0002\b\u0002\n\u0002\u0010\u0002\n\u0000\n\u0002\u0018\u0002\n\u0000\n\u0002\u0018\u0002\n\u0002\b\u0003\n\u0002\u0010\u000e\n\u0000\n\u0002\u0010\u0011\n\u0002\b\u0003\b\u00c6\u0002\u0018\u00002\u00020\u0001:\u0001\u0010B\u0007\b\u0002\u00a2\u0006\u0002\u0010\u0002J\u0010\u0010\u0003\u001a\u00020\u00042\b\u0010\u0005\u001a\u0004\u0018\u00010\u0006J\u0010\u0010\u0007\u001a\u00020\b2\b\u0010\t\u001a\u0004\u0018\u00010\u0006J1\u0010\n\u001a\u00020\u00042\b\u0010\u0005\u001a\u0004\u0018\u00010\u00062\u0006\u0010\u000b\u001a\u00020\f2\u0012\u0010\r\u001a\n\u0012\u0006\b\u0001\u0012\u00020\u00010\u000e\"\u00020\u0001\u00a2\u0006\u0002\u0010\u000f\u00a8\u0006\u0011"}, d2={"Ldorkbox/executor/LogHelper;", "", "()V", "fixSshLogger", "", "log", "Lorg/slf4j/Logger;", "getLogFactory", "Lnet/schmizz/sshj/common/LoggerFactory;", "logger", "logAtLowestLevel", "message", "", "arguments", "", "(Lorg/slf4j/Logger;Ljava/lang/String;[Ljava/lang/Object;)V", "LogHelperLogger", "Executor"})
public final class LogHelper {
    @NotNull
    public static final LogHelper INSTANCE = new LogHelper();

    private LogHelper() {
    }

    /*
     * WARNING - void declaration
     */
    public final void fixSshLogger(@Nullable Logger log) {
        try {
            void $this$mapTo$iv$iv;
            Level logLevel = log != null ? ((ch.qos.logback.classic.Logger)log).getLevel() : Level.ERROR;
            Object[] objectArray = new Class[]{JCERandom.class, Curve25519SHA256.class, KeyType.class};
            Iterable $this$map$iv = CollectionsKt.mutableListOf((Object[])objectArray);
            boolean $i$f$map = false;
            Iterable iterable = $this$map$iv;
            Collection destination$iv$iv = new ArrayList(CollectionsKt.collectionSizeOrDefault((Iterable)$this$map$iv, (int)10));
            boolean $i$f$mapTo = false;
            for (Object item$iv$iv : $this$mapTo$iv$iv) {
                void it;
                Class clazz = (Class)item$iv$iv;
                Collection collection = destination$iv$iv;
                boolean bl = false;
                Logger logger = org.slf4j.LoggerFactory.getLogger((Class)it);
                if (logger == null) {
                    throw new NullPointerException("null cannot be cast to non-null type ch.qos.logback.classic.Logger");
                }
                collection.add((ch.qos.logback.classic.Logger)logger);
            }
            Iterable $this$forEach$iv = (List)destination$iv$iv;
            boolean $i$f$forEach = false;
            for (Object element$iv : $this$forEach$iv) {
                ch.qos.logback.classic.Logger it = (ch.qos.logback.classic.Logger)element$iv;
                boolean bl = false;
                it.setLevel(logLevel);
            }
        }
        catch (Exception exception) {
            // empty catch block
        }
    }

    public final void logAtLowestLevel(@Nullable Logger log, @NotNull String message, Object ... arguments) {
        Intrinsics.checkNotNullParameter((Object)message, (String)"message");
        Intrinsics.checkNotNullParameter((Object)arguments, (String)"arguments");
        if (log == null) {
            return;
        }
        if (log.isTraceEnabled()) {
            log.trace(message, Arrays.copyOf(arguments, arguments.length));
        } else if (log.isDebugEnabled()) {
            log.debug(message, Arrays.copyOf(arguments, arguments.length));
        } else if (log.isInfoEnabled()) {
            log.info(message, Arrays.copyOf(arguments, arguments.length));
        } else if (log.isWarnEnabled()) {
            log.warn(message, Arrays.copyOf(arguments, arguments.length));
        } else if (log.isErrorEnabled()) {
            log.error(message, Arrays.copyOf(arguments, arguments.length));
        }
    }

    @NotNull
    public final LoggerFactory getLogFactory(@Nullable Logger logger) {
        if (logger == null) {
            return new LoggerFactory(){

                @NotNull
                public Logger getLogger(@NotNull String name) {
                    Intrinsics.checkNotNullParameter((Object)name, (String)"name");
                    NOPLogger nOPLogger = NOPLogger.NOP_LOGGER;
                    Intrinsics.checkNotNullExpressionValue((Object)nOPLogger, (String)"NOP_LOGGER");
                    return (Logger)nOPLogger;
                }

                @NotNull
                public Logger getLogger(@NotNull Class<?> clazz) {
                    Intrinsics.checkNotNullParameter(clazz, (String)"clazz");
                    NOPLogger nOPLogger = NOPLogger.NOP_LOGGER;
                    Intrinsics.checkNotNullExpressionValue((Object)nOPLogger, (String)"NOP_LOGGER");
                    return (Logger)nOPLogger;
                }
            };
        }
        return new LoggerFactory(){

            @NotNull
            public Logger getLogger(@NotNull String name) {
                Intrinsics.checkNotNullParameter((Object)name, (String)"name");
                return (Logger)new LogHelperLogger(name);
            }

            @NotNull
            public Logger getLogger(@NotNull Class<?> clazz) {
                String name;
                Intrinsics.checkNotNullParameter(clazz, (String)"clazz");
                String string2 = name = clazz.getName();
                Intrinsics.checkNotNullExpressionValue((Object)string2, (String)"name");
                String string3 = string2;
                string2 = SshExecOptions.class.getName();
                Intrinsics.checkNotNullExpressionValue((Object)string2, (String)"SshExecOptions::class.java.name");
                if (StringsKt.startsWith$default((String)string3, (String)string2, (boolean)false, (int)2, null)) {
                    name = SSHClient.class.getName();
                }
                string2 = name;
                Intrinsics.checkNotNullExpressionValue((Object)string2, (String)"name");
                return (Logger)new LogHelperLogger(string2);
            }
        };
    }

    @Metadata(mv={1, 6, 0}, k=1, xi=48, d1={"\u0000B\n\u0002\u0018\u0002\n\u0002\u0018\u0002\n\u0000\n\u0002\u0010\u000e\n\u0002\b\u0002\n\u0002\u0018\u0002\n\u0002\b\u0003\n\u0002\u0010\u0002\n\u0002\b\u0003\n\u0002\u0010\u0000\n\u0002\b\u0003\n\u0002\u0010\u0011\n\u0002\b\u0002\n\u0002\u0010\u0003\n\u0002\b\u0004\n\u0002\u0010\u000b\n\u0002\b\b\b\u0016\u0018\u00002\u00020\u0001B\r\u0012\u0006\u0010\u0002\u001a\u00020\u0003\u00a2\u0006\u0002\u0010\u0004J\u0010\u0010\t\u001a\u00020\n2\u0006\u0010\u000b\u001a\u00020\u0003H\u0016J\u0018\u0010\t\u001a\u00020\n2\u0006\u0010\f\u001a\u00020\u00032\u0006\u0010\r\u001a\u00020\u000eH\u0016J \u0010\t\u001a\u00020\n2\u0006\u0010\f\u001a\u00020\u00032\u0006\u0010\u000f\u001a\u00020\u000e2\u0006\u0010\u0010\u001a\u00020\u000eH\u0016J)\u0010\t\u001a\u00020\n2\u0006\u0010\f\u001a\u00020\u00032\u0012\u0010\u0011\u001a\n\u0012\u0006\b\u0001\u0012\u00020\u000e0\u0012\"\u00020\u000eH\u0016\u00a2\u0006\u0002\u0010\u0013J\u0018\u0010\t\u001a\u00020\n2\u0006\u0010\u000b\u001a\u00020\u00032\u0006\u0010\u0014\u001a\u00020\u0015H\u0016J\u0010\u0010\u0016\u001a\u00020\n2\u0006\u0010\u000b\u001a\u00020\u0003H\u0016J\u0018\u0010\u0016\u001a\u00020\n2\u0006\u0010\f\u001a\u00020\u00032\u0006\u0010\u000f\u001a\u00020\u000eH\u0016J \u0010\u0016\u001a\u00020\n2\u0006\u0010\f\u001a\u00020\u00032\u0006\u0010\u000f\u001a\u00020\u000e2\u0006\u0010\u0010\u001a\u00020\u000eH\u0016J)\u0010\u0016\u001a\u00020\n2\u0006\u0010\f\u001a\u00020\u00032\u0012\u0010\u0011\u001a\n\u0012\u0006\b\u0001\u0012\u00020\u000e0\u0012\"\u00020\u000eH\u0016\u00a2\u0006\u0002\u0010\u0013J\u0018\u0010\u0016\u001a\u00020\n2\u0006\u0010\u000b\u001a\u00020\u00032\u0006\u0010\u0014\u001a\u00020\u0015H\u0016J\b\u0010\u0017\u001a\u00020\u0003H\u0016J\u0010\u0010\u0018\u001a\u00020\n2\u0006\u0010\u000b\u001a\u00020\u0003H\u0016J\u0018\u0010\u0018\u001a\u00020\n2\u0006\u0010\f\u001a\u00020\u00032\u0006\u0010\u000f\u001a\u00020\u000eH\u0016J \u0010\u0018\u001a\u00020\n2\u0006\u0010\f\u001a\u00020\u00032\u0006\u0010\u000f\u001a\u00020\u000e2\u0006\u0010\u0010\u001a\u00020\u000eH\u0016J)\u0010\u0018\u001a\u00020\n2\u0006\u0010\f\u001a\u00020\u00032\u0012\u0010\u0011\u001a\n\u0012\u0006\b\u0001\u0012\u00020\u000e0\u0012\"\u00020\u000eH\u0016\u00a2\u0006\u0002\u0010\u0013J\u0018\u0010\u0018\u001a\u00020\n2\u0006\u0010\u000b\u001a\u00020\u00032\u0006\u0010\u0014\u001a\u00020\u0015H\u0016J\b\u0010\u0019\u001a\u00020\u001aH\u0016J\b\u0010\u001b\u001a\u00020\u001aH\u0016J\b\u0010\u001c\u001a\u00020\u001aH\u0016J\b\u0010\u001d\u001a\u00020\u001aH\u0016J\b\u0010\u001e\u001a\u00020\u001aH\u0016J\u000e\u0010\u001f\u001a\u00020\n2\u0006\u0010\u000b\u001a\u00020\u0003J\u0016\u0010\u001f\u001a\u00020\n2\u0006\u0010\f\u001a\u00020\u00032\u0006\u0010\r\u001a\u00020\u000eJ\u001e\u0010\u001f\u001a\u00020\n2\u0006\u0010\f\u001a\u00020\u00032\u0006\u0010\u000f\u001a\u00020\u000e2\u0006\u0010\u0010\u001a\u00020\u000eJ'\u0010\u001f\u001a\u00020\n2\u0006\u0010\f\u001a\u00020\u00032\u0012\u0010\u0011\u001a\n\u0012\u0006\b\u0001\u0012\u00020\u000e0\u0012\"\u00020\u000e\u00a2\u0006\u0002\u0010\u0013J\u0016\u0010\u001f\u001a\u00020\n2\u0006\u0010\u000b\u001a\u00020\u00032\u0006\u0010\u0014\u001a\u00020\u0015J\u0010\u0010 \u001a\u00020\n2\u0006\u0010\u000b\u001a\u00020\u0003H\u0016J\u0018\u0010 \u001a\u00020\n2\u0006\u0010\f\u001a\u00020\u00032\u0006\u0010\r\u001a\u00020\u000eH\u0016J \u0010 \u001a\u00020\n2\u0006\u0010\f\u001a\u00020\u00032\u0006\u0010\u000f\u001a\u00020\u000e2\u0006\u0010\u0010\u001a\u00020\u000eH\u0016J)\u0010 \u001a\u00020\n2\u0006\u0010\f\u001a\u00020\u00032\u0012\u0010\u0011\u001a\n\u0012\u0006\b\u0001\u0012\u00020\u000e0\u0012\"\u00020\u000eH\u0016\u00a2\u0006\u0002\u0010\u0013J\u0018\u0010 \u001a\u00020\n2\u0006\u0010\u000b\u001a\u00020\u00032\u0006\u0010\u0014\u001a\u00020\u0015H\u0016J\u0010\u0010!\u001a\u00020\n2\u0006\u0010\u000b\u001a\u00020\u0003H\u0016J\u0018\u0010!\u001a\u00020\n2\u0006\u0010\f\u001a\u00020\u00032\u0006\u0010\u000f\u001a\u00020\u000eH\u0016J \u0010!\u001a\u00020\n2\u0006\u0010\f\u001a\u00020\u00032\u0006\u0010\u000f\u001a\u00020\u000e2\u0006\u0010\u0010\u001a\u00020\u000eH\u0016J)\u0010!\u001a\u00020\n2\u0006\u0010\f\u001a\u00020\u00032\u0012\u0010\u0011\u001a\n\u0012\u0006\b\u0001\u0012\u00020\u000e0\u0012\"\u00020\u000eH\u0016\u00a2\u0006\u0002\u0010\u0013J\u0018\u0010!\u001a\u00020\n2\u0006\u0010\u000b\u001a\u00020\u00032\u0006\u0010\u0014\u001a\u00020\u0015H\u0016R\u0011\u0010\u0005\u001a\u00020\u0006\u00a2\u0006\b\n\u0000\u001a\u0004\b\u0007\u0010\b\u00a8\u0006\""}, d2={"Ldorkbox/executor/LogHelper$LogHelperLogger;", "Lorg/slf4j/helpers/MarkerIgnoringBase;", "name", "", "(Ljava/lang/String;)V", "logger", "Lorg/slf4j/Logger;", "getLogger", "()Lorg/slf4j/Logger;", "debug", "", "msg", "format", "arg", "", "arg1", "arg2", "argArray", "", "(Ljava/lang/String;[Ljava/lang/Object;)V", "t", "", "error", "getName", "info", "isDebugEnabled", "", "isErrorEnabled", "isInfoEnabled", "isTraceEnabled", "isWarnEnabled", "log", "trace", "warn", "Executor"})
    public static class LogHelperLogger
    extends MarkerIgnoringBase {
        @NotNull
        private final Logger logger;

        public LogHelperLogger(@NotNull String name) {
            Intrinsics.checkNotNullParameter((Object)name, (String)"name");
            Logger logger = org.slf4j.LoggerFactory.getLogger((String)name);
            Intrinsics.checkNotNull((Object)logger);
            this.logger = logger;
        }

        @NotNull
        public final Logger getLogger() {
            return this.logger;
        }

        @NotNull
        public String getName() {
            String string2 = this.name;
            Intrinsics.checkNotNullExpressionValue((Object)string2, (String)"name");
            return string2;
        }

        public boolean isTraceEnabled() {
            return true;
        }

        public final void log(@NotNull String msg) {
            Intrinsics.checkNotNullParameter((Object)msg, (String)"msg");
            if (this.logger.isTraceEnabled()) {
                this.logger.trace(msg);
            } else if (this.logger.isDebugEnabled()) {
                this.logger.debug(msg);
            } else if (this.logger.isInfoEnabled()) {
                this.logger.info(msg);
            } else if (this.logger.isWarnEnabled()) {
                this.logger.warn(msg);
            } else if (this.logger.isErrorEnabled()) {
                this.logger.error(msg);
            }
        }

        public final void log(@NotNull String format, @NotNull Object arg) {
            Intrinsics.checkNotNullParameter((Object)format, (String)"format");
            Intrinsics.checkNotNullParameter((Object)arg, (String)"arg");
            if (this.logger.isTraceEnabled()) {
                this.logger.trace(format, arg);
            } else if (this.logger.isDebugEnabled()) {
                this.logger.debug(format, arg);
            } else if (this.logger.isInfoEnabled()) {
                this.logger.info(format, arg);
            } else if (this.logger.isWarnEnabled()) {
                this.logger.warn(format, arg);
            } else if (this.logger.isErrorEnabled()) {
                this.logger.error(format, arg);
            }
        }

        public final void log(@NotNull String format, @NotNull Object arg1, @NotNull Object arg2) {
            Intrinsics.checkNotNullParameter((Object)format, (String)"format");
            Intrinsics.checkNotNullParameter((Object)arg1, (String)"arg1");
            Intrinsics.checkNotNullParameter((Object)arg2, (String)"arg2");
            if (this.logger.isTraceEnabled()) {
                this.logger.trace(format, arg1, arg2);
            } else if (this.logger.isDebugEnabled()) {
                this.logger.debug(format, arg1, arg2);
            } else if (this.logger.isInfoEnabled()) {
                this.logger.info(format, arg1, arg2);
            } else if (this.logger.isWarnEnabled()) {
                this.logger.warn(format, arg1, arg2);
            } else if (this.logger.isErrorEnabled()) {
                this.logger.error(format, arg1, arg2);
            }
        }

        public final void log(@NotNull String format, Object ... argArray) {
            Intrinsics.checkNotNullParameter((Object)format, (String)"format");
            Intrinsics.checkNotNullParameter((Object)argArray, (String)"argArray");
            if (this.logger.isTraceEnabled()) {
                this.logger.trace(format, (Object)argArray);
            } else if (this.logger.isDebugEnabled()) {
                this.logger.debug(format, (Object)argArray);
            } else if (this.logger.isInfoEnabled()) {
                this.logger.info(format, (Object)argArray);
            } else if (this.logger.isWarnEnabled()) {
                this.logger.warn(format, (Object)argArray);
            } else if (this.logger.isErrorEnabled()) {
                this.logger.error(format, (Object)argArray);
            }
        }

        public final void log(@NotNull String msg, @NotNull Throwable t) {
            Intrinsics.checkNotNullParameter((Object)msg, (String)"msg");
            Intrinsics.checkNotNullParameter((Object)t, (String)"t");
            if (this.logger.isTraceEnabled()) {
                this.logger.trace(msg, t);
            } else if (this.logger.isDebugEnabled()) {
                this.logger.debug(msg, t);
            } else if (this.logger.isInfoEnabled()) {
                this.logger.info(msg, t);
            } else if (this.logger.isWarnEnabled()) {
                this.logger.warn(msg, t);
            } else if (this.logger.isErrorEnabled()) {
                this.logger.error(msg, t);
            }
        }

        public void trace(@NotNull String msg) {
            Intrinsics.checkNotNullParameter((Object)msg, (String)"msg");
            this.log(msg);
        }

        public void trace(@NotNull String format, @NotNull Object arg) {
            Intrinsics.checkNotNullParameter((Object)format, (String)"format");
            Intrinsics.checkNotNullParameter((Object)arg, (String)"arg");
            this.log(format, arg);
        }

        public void trace(@NotNull String format, @NotNull Object arg1, @NotNull Object arg2) {
            Intrinsics.checkNotNullParameter((Object)format, (String)"format");
            Intrinsics.checkNotNullParameter((Object)arg1, (String)"arg1");
            Intrinsics.checkNotNullParameter((Object)arg2, (String)"arg2");
            this.log(format, arg1, arg2);
        }

        public void trace(@NotNull String format, Object ... argArray) {
            Intrinsics.checkNotNullParameter((Object)format, (String)"format");
            Intrinsics.checkNotNullParameter((Object)argArray, (String)"argArray");
            this.log(format, (Object)argArray);
        }

        public void trace(@NotNull String msg, @NotNull Throwable t) {
            Intrinsics.checkNotNullParameter((Object)msg, (String)"msg");
            Intrinsics.checkNotNullParameter((Object)t, (String)"t");
            this.log(msg, t);
        }

        public boolean isDebugEnabled() {
            return true;
        }

        public void debug(@NotNull String msg) {
            Intrinsics.checkNotNullParameter((Object)msg, (String)"msg");
            this.log(msg);
        }

        public void debug(@NotNull String format, @NotNull Object arg) {
            Intrinsics.checkNotNullParameter((Object)format, (String)"format");
            Intrinsics.checkNotNullParameter((Object)arg, (String)"arg");
            this.log(format, arg);
        }

        public void debug(@NotNull String format, @NotNull Object arg1, @NotNull Object arg2) {
            Intrinsics.checkNotNullParameter((Object)format, (String)"format");
            Intrinsics.checkNotNullParameter((Object)arg1, (String)"arg1");
            Intrinsics.checkNotNullParameter((Object)arg2, (String)"arg2");
            this.log(format, arg1, arg2);
        }

        public void debug(@NotNull String format, Object ... argArray) {
            Intrinsics.checkNotNullParameter((Object)format, (String)"format");
            Intrinsics.checkNotNullParameter((Object)argArray, (String)"argArray");
            this.log(format, (Object)argArray);
        }

        public void debug(@NotNull String msg, @NotNull Throwable t) {
            Intrinsics.checkNotNullParameter((Object)msg, (String)"msg");
            Intrinsics.checkNotNullParameter((Object)t, (String)"t");
            this.log(msg, t);
        }

        public boolean isInfoEnabled() {
            return true;
        }

        public void info(@NotNull String msg) {
            Intrinsics.checkNotNullParameter((Object)msg, (String)"msg");
            this.log(msg);
        }

        public void info(@NotNull String format, @NotNull Object arg1) {
            Intrinsics.checkNotNullParameter((Object)format, (String)"format");
            Intrinsics.checkNotNullParameter((Object)arg1, (String)"arg1");
            this.log(format, arg1);
        }

        public void info(@NotNull String format, @NotNull Object arg1, @NotNull Object arg2) {
            Intrinsics.checkNotNullParameter((Object)format, (String)"format");
            Intrinsics.checkNotNullParameter((Object)arg1, (String)"arg1");
            Intrinsics.checkNotNullParameter((Object)arg2, (String)"arg2");
            this.log(format, arg1, arg2);
        }

        public void info(@NotNull String format, Object ... argArray) {
            Intrinsics.checkNotNullParameter((Object)format, (String)"format");
            Intrinsics.checkNotNullParameter((Object)argArray, (String)"argArray");
            this.log(format, (Object)argArray);
        }

        public void info(@NotNull String msg, @NotNull Throwable t) {
            Intrinsics.checkNotNullParameter((Object)msg, (String)"msg");
            Intrinsics.checkNotNullParameter((Object)t, (String)"t");
            this.log(msg, t);
        }

        public boolean isWarnEnabled() {
            return true;
        }

        public void warn(@NotNull String msg) {
            Intrinsics.checkNotNullParameter((Object)msg, (String)"msg");
            this.log(msg);
        }

        public void warn(@NotNull String format, @NotNull Object arg1) {
            Intrinsics.checkNotNullParameter((Object)format, (String)"format");
            Intrinsics.checkNotNullParameter((Object)arg1, (String)"arg1");
            this.log(format, arg1);
        }

        public void warn(@NotNull String format, @NotNull Object arg1, @NotNull Object arg2) {
            Intrinsics.checkNotNullParameter((Object)format, (String)"format");
            Intrinsics.checkNotNullParameter((Object)arg1, (String)"arg1");
            Intrinsics.checkNotNullParameter((Object)arg2, (String)"arg2");
            this.log(format, arg1, arg2);
        }

        public void warn(@NotNull String format, Object ... argArray) {
            Intrinsics.checkNotNullParameter((Object)format, (String)"format");
            Intrinsics.checkNotNullParameter((Object)argArray, (String)"argArray");
            this.log(format, (Object)argArray);
        }

        public void warn(@NotNull String msg, @NotNull Throwable t) {
            Intrinsics.checkNotNullParameter((Object)msg, (String)"msg");
            Intrinsics.checkNotNullParameter((Object)t, (String)"t");
            this.log(msg, t);
        }

        public boolean isErrorEnabled() {
            return true;
        }

        public void error(@NotNull String msg) {
            Intrinsics.checkNotNullParameter((Object)msg, (String)"msg");
            this.log(msg);
        }

        public void error(@NotNull String format, @NotNull Object arg1) {
            Intrinsics.checkNotNullParameter((Object)format, (String)"format");
            Intrinsics.checkNotNullParameter((Object)arg1, (String)"arg1");
            this.log(format, arg1);
        }

        public void error(@NotNull String format, @NotNull Object arg1, @NotNull Object arg2) {
            Intrinsics.checkNotNullParameter((Object)format, (String)"format");
            Intrinsics.checkNotNullParameter((Object)arg1, (String)"arg1");
            Intrinsics.checkNotNullParameter((Object)arg2, (String)"arg2");
            this.log(format, arg1, arg2);
        }

        public void error(@NotNull String format, Object ... argArray) {
            Intrinsics.checkNotNullParameter((Object)format, (String)"format");
            Intrinsics.checkNotNullParameter((Object)argArray, (String)"argArray");
            this.log(format, (Object)argArray);
        }

        public void error(@NotNull String msg, @NotNull Throwable t) {
            Intrinsics.checkNotNullParameter((Object)msg, (String)"msg");
            Intrinsics.checkNotNullParameter((Object)t, (String)"t");
            this.log(msg, t);
        }
    }
}

