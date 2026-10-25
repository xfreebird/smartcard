/*
 * Decompiled with CFR 0.152.
 * 
 * Could not load the following classes:
 *  dorkbox.updates.Updates
 *  kotlin.Lazy
 *  kotlin.LazyKt
 *  kotlin.Metadata
 *  kotlin.collections.ArraysKt
 *  kotlin.collections.MapsKt
 *  kotlin.io.TextStreamsKt
 *  kotlin.jvm.functions.Function0
 *  kotlin.jvm.internal.Intrinsics
 *  kotlin.ranges.RangesKt
 *  kotlin.text.Charsets
 *  kotlin.text.StringsKt
 *  org.jetbrains.annotations.NotNull
 *  org.jetbrains.annotations.Nullable
 */
package dorkbox.os;

import dorkbox.os.JVM;
import dorkbox.os.OS;
import dorkbox.os.OSType;
import dorkbox.updates.Updates;
import java.io.BufferedReader;
import java.io.Closeable;
import java.io.File;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.io.Reader;
import java.nio.charset.Charset;
import java.security.AccessController;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.Collection;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.TimeZone;
import java.util.concurrent.TimeUnit;
import kotlin.Lazy;
import kotlin.LazyKt;
import kotlin.Metadata;
import kotlin.collections.ArraysKt;
import kotlin.collections.MapsKt;
import kotlin.io.TextStreamsKt;
import kotlin.jvm.functions.Function0;
import kotlin.jvm.internal.Intrinsics;
import kotlin.ranges.RangesKt;
import kotlin.text.Charsets;
import kotlin.text.StringsKt;
import org.jetbrains.annotations.NotNull;
import org.jetbrains.annotations.Nullable;

/*
 * Illegal identifiers - consider using --renameillegalidents true
 */
@Metadata(mv={1, 6, 0}, k=1, xi=48, d1={"\u0000f\n\u0002\u0018\u0002\n\u0002\u0010\u0000\n\u0002\b\u0002\n\u0002\u0010\u000e\n\u0002\b\u0006\n\u0002\u0018\u0002\n\u0002\b\u0004\n\u0002\u0010\u000b\n\u0002\b\f\n\u0002\u0010\b\n\u0002\b\r\n\u0002\u0018\u0002\n\u0002\b\b\n\u0002\u0010\u0011\n\u0000\n\u0002\u0010\t\n\u0002\b\u0007\n\u0002\u0010\u0006\n\u0000\n\u0002\u0010$\n\u0002\b\u0002\n\u0002\u0010\u0003\n\u0000\n\u0002\u0010\u0007\n\u0002\b\u0004\n\u0002\u0010\u0002\n\u0002\b\u0005\b\u00c6\u0002\u0018\u00002\u00020\u0001:\u0004KLMNB\u0007\b\u0002\u00a2\u0006\u0002\u0010\u0002J+\u00102\u001a\u00020\u00042\u0012\u00103\u001a\n\u0012\u0006\b\u0001\u0012\u00020\u000404\"\u00020\u00042\b\b\u0002\u00105\u001a\u000206H\u0002\u00a2\u0006\u0002\u00107J+\u00108\u001a\u00020\u00102\u0012\u00103\u001a\n\u0012\u0006\b\u0001\u0012\u00020\u000404\"\u00020\u00042\b\b\u0002\u00105\u001a\u000206H\u0002\u00a2\u0006\u0002\u00109J\u0016\u0010:\u001a\u00020\u00102\u0006\u0010;\u001a\u00020\u00042\u0006\u0010<\u001a\u00020\u0010J\u0016\u0010=\u001a\u00020>2\u0006\u0010;\u001a\u00020\u00042\u0006\u0010<\u001a\u00020>J\u0012\u0010?\u001a\u000e\u0012\u0004\u0012\u00020\u0004\u0012\u0004\u0012\u00020\u00040@J\u0010\u0010?\u001a\u0004\u0018\u00010\u00042\u0006\u0010;\u001a\u00020\u0004J\u0016\u0010?\u001a\u00020\u00042\u0006\u0010;\u001a\u00020\u00042\u0006\u0010<\u001a\u00020\u0004J\u0010\u0010A\u001a\u0004\u0018\u00010\u00042\u0006\u0010B\u001a\u00020CJ\u0016\u0010D\u001a\u00020E2\u0006\u0010;\u001a\u00020\u00042\u0006\u0010<\u001a\u00020EJ\u0016\u0010F\u001a\u00020\u001d2\u0006\u0010;\u001a\u00020\u00042\u0006\u0010<\u001a\u00020\u001dJ\u0016\u0010G\u001a\u0002062\u0006\u0010;\u001a\u00020\u00042\u0006\u0010<\u001a\u000206J\u0010\u0010H\u001a\u0004\u0018\u00010\u00042\u0006\u0010;\u001a\u00020\u0004J\u0016\u0010H\u001a\u00020\u00042\u0006\u0010;\u001a\u00020\u00042\u0006\u0010<\u001a\u00020\u0004J\u0006\u0010I\u001a\u00020JR\u0011\u0010\u0003\u001a\u00020\u0004\u00a2\u0006\b\n\u0000\u001a\u0004\b\u0005\u0010\u0006R\u000e\u0010\u0007\u001a\u00020\u0004X\u0086T\u00a2\u0006\u0002\n\u0000R\u000e\u0010\b\u001a\u00020\u0004X\u0086T\u00a2\u0006\u0002\n\u0000R\u000e\u0010\t\u001a\u00020\u0004X\u0086T\u00a2\u0006\u0002\n\u0000R\u0019\u0010\n\u001a\n \f*\u0004\u0018\u00010\u000b0\u000b\u00a2\u0006\b\n\u0000\u001a\u0004\b\r\u0010\u000eR\u0011\u0010\u000f\u001a\u00020\u0010\u00a2\u0006\b\n\u0000\u001a\u0004\b\u000f\u0010\u0011R\u0011\u0010\u0012\u001a\u00020\u0010\u00a2\u0006\b\n\u0000\u001a\u0004\b\u0012\u0010\u0011R\u0011\u0010\u0013\u001a\u00020\u0010\u00a2\u0006\b\n\u0000\u001a\u0004\b\u0013\u0010\u0011R\u0011\u0010\u0014\u001a\u00020\u0010\u00a2\u0006\b\n\u0000\u001a\u0004\b\u0014\u0010\u0011R\u0011\u0010\u0015\u001a\u00020\u0010\u00a2\u0006\b\n\u0000\u001a\u0004\b\u0015\u0010\u0011R\u0011\u0010\u0016\u001a\u00020\u0010\u00a2\u0006\b\n\u0000\u001a\u0004\b\u0016\u0010\u0011R\u0011\u0010\u0017\u001a\u00020\u0010\u00a2\u0006\b\n\u0000\u001a\u0004\b\u0017\u0010\u0011R\u0011\u0010\u0018\u001a\u00020\u0010\u00a2\u0006\b\n\u0000\u001a\u0004\b\u0018\u0010\u0011R\u0011\u0010\u0019\u001a\u00020\u0010\u00a2\u0006\b\n\u0000\u001a\u0004\b\u0019\u0010\u0011R\u0011\u0010\u001a\u001a\u00020\u0010\u00a2\u0006\b\n\u0000\u001a\u0004\b\u001a\u0010\u0011R\u0011\u0010\u001b\u001a\u00020\u0010\u00a2\u0006\b\n\u0000\u001a\u0004\b\u001b\u0010\u0011R\u001b\u0010\u001c\u001a\u00020\u001d8FX\u0086\u0084\u0002\u00a2\u0006\f\n\u0004\b \u0010!\u001a\u0004\b\u001e\u0010\u001fR\u0011\u0010\"\u001a\u00020\u001d\u00a2\u0006\b\n\u0000\u001a\u0004\b#\u0010\u001fR\u0011\u0010$\u001a\u00020\u0004\u00a2\u0006\b\n\u0000\u001a\u0004\b%\u0010\u0006R\u0011\u0010&\u001a\u00020\u0004\u00a2\u0006\b\n\u0000\u001a\u0004\b'\u0010\u0006R\u0011\u0010(\u001a\u00020\u0004\u00a2\u0006\b\n\u0000\u001a\u0004\b)\u0010\u0006R\u001b\u0010*\u001a\u00020+8FX\u0086\u0084\u0002\u00a2\u0006\f\n\u0004\b.\u0010!\u001a\u0004\b,\u0010-R\u0011\u0010/\u001a\u00020\u0010\u00a2\u0006\b\n\u0000\u001a\u0004\b0\u0010\u0011R\u000e\u00101\u001a\u00020\u0004X\u0086T\u00a2\u0006\u0002\n\u0000\u00a8\u0006O"}, d2={"Ldorkbox/os/OS;", "", "()V", "LINE_SEPARATOR", "", "getLINE_SEPARATOR", "()Ljava/lang/String;", "LINE_SEPARATOR_MACOS", "LINE_SEPARATOR_UNIX", "LINE_SEPARATOR_WINDOWS", "TEMP_DIR", "Ljava/io/File;", "kotlin.jvm.PlatformType", "getTEMP_DIR", "()Ljava/io/File;", "is32bit", "", "()Z", "is64bit", "isAndroid", "isArm", "isLinux", "isMacOsX", "isMips", "isSolaris", "isUnix", "isWindows", "isX86", "javaVersion", "", "getJavaVersion", "()I", "javaVersion$delegate", "Lkotlin/Lazy;", "optimumNumberOfThreads", "getOptimumNumberOfThreads", "originalTimeZone", "getOriginalTimeZone", "osArch", "getOsArch", "osName", "getOsName", "type", "Ldorkbox/os/OSType;", "getType", "()Ldorkbox/os/OSType;", "type$delegate", "usesJpms", "getUsesJpms", "version", "execute", "args", "", "timeout", "", "([Ljava/lang/String;J)Ljava/lang/String;", "executeStatus", "([Ljava/lang/String;J)Z", "getBoolean", "property", "defaultValue", "getDouble", "", "getEnv", "", "getExceptionMessage", "throwable", "", "getFloat", "", "getInt", "getLong", "getProperty", "setUTC", "", "DesktopEnv", "Linux", "Unix", "Windows", "OS"})
public final class OS {
    @NotNull
    public static final OS INSTANCE = new OS();
    @NotNull
    public static final String version = "1.6";
    @NotNull
    private static final String LINE_SEPARATOR;
    @NotNull
    public static final String LINE_SEPARATOR_UNIX = "\n";
    @NotNull
    public static final String LINE_SEPARATOR_MACOS = "\r";
    @NotNull
    public static final String LINE_SEPARATOR_WINDOWS = "\r\n";
    private static final File TEMP_DIR;
    @NotNull
    private static final Lazy javaVersion$delegate;
    private static final boolean usesJpms;
    @NotNull
    private static final String originalTimeZone;
    @NotNull
    private static final String osName;
    @NotNull
    private static final String osArch;
    private static final int optimumNumberOfThreads;
    @NotNull
    private static final Lazy type$delegate;
    private static final boolean is32bit;
    private static final boolean is64bit;
    private static final boolean isX86;
    private static final boolean isMips;
    private static final boolean isArm;
    private static final boolean isLinux;
    private static final boolean isUnix;
    private static final boolean isSolaris;
    private static final boolean isWindows;
    private static final boolean isMacOsX;
    private static final boolean isAndroid;

    private OS() {
    }

    @NotNull
    public final String getLINE_SEPARATOR() {
        return LINE_SEPARATOR;
    }

    public final File getTEMP_DIR() {
        return TEMP_DIR;
    }

    public final int getJavaVersion() {
        Lazy lazy = javaVersion$delegate;
        return ((Number)lazy.getValue()).intValue();
    }

    public final boolean getUsesJpms() {
        return usesJpms;
    }

    @NotNull
    public final String getOriginalTimeZone() {
        return originalTimeZone;
    }

    @NotNull
    public final String getOsName() {
        return osName;
    }

    @NotNull
    public final String getOsArch() {
        return osArch;
    }

    public final int getOptimumNumberOfThreads() {
        return optimumNumberOfThreads;
    }

    @NotNull
    public final OSType getType() {
        Lazy lazy = type$delegate;
        return (OSType)((Object)lazy.getValue());
    }

    @Nullable
    public final String getProperty(@NotNull String property) {
        String string;
        Intrinsics.checkNotNullParameter((Object)property, (String)"property");
        try {
            string = System.getSecurityManager() == null ? System.getProperty(property, null) : AccessController.doPrivileged(() -> OS.getProperty$lambda-1(property));
        }
        catch (Exception ignored) {
            string = null;
        }
        return string;
    }

    @NotNull
    public final String getProperty(@NotNull String property, @NotNull String defaultValue) {
        String string;
        Intrinsics.checkNotNullParameter((Object)property, (String)"property");
        Intrinsics.checkNotNullParameter((Object)defaultValue, (String)"defaultValue");
        try {
            string = System.getSecurityManager() == null ? System.getProperty(property, defaultValue) : AccessController.doPrivileged(() -> OS.getProperty$lambda-2(property, defaultValue));
            Intrinsics.checkNotNullExpressionValue((Object)string, (String)"{\n            if (System\u2026)\n            }\n        }");
        }
        catch (Exception ignored) {
            string = defaultValue;
        }
        return string;
    }

    @NotNull
    public final Map<String, String> getEnv() {
        Map map;
        try {
            map = System.getSecurityManager() == null ? System.getenv() : AccessController.doPrivileged(OS::getEnv$lambda-3);
            Intrinsics.checkNotNullExpressionValue((Object)map, (String)"{\n            if (System\u2026)\n            }\n        }");
        }
        catch (Exception ignored) {
            map = MapsKt.emptyMap();
        }
        return map;
    }

    @Nullable
    public final String getEnv(@NotNull String property) {
        String string;
        Intrinsics.checkNotNullParameter((Object)property, (String)"property");
        try {
            string = System.getSecurityManager() == null ? System.getenv(property) : AccessController.doPrivileged(() -> OS.getEnv$lambda-4(property));
        }
        catch (Exception ignored) {
            string = null;
        }
        return string;
    }

    @NotNull
    public final String getEnv(@NotNull String property, @NotNull String defaultValue) {
        Intrinsics.checkNotNullParameter((Object)property, (String)"property");
        Intrinsics.checkNotNullParameter((Object)defaultValue, (String)"defaultValue");
        String string = this.getEnv(property);
        if (string == null) {
            string = defaultValue;
        }
        return string;
    }

    public final boolean getBoolean(@NotNull String property, boolean defaultValue) {
        String value;
        Intrinsics.checkNotNullParameter((Object)property, (String)"property");
        String string = this.getProperty(property);
        if (string == null) {
            return defaultValue;
        }
        String $this$trim$iv = value = string;
        boolean $i$f$trim = false;
        CharSequence $this$trim$iv$iv = $this$trim$iv;
        boolean $i$f$trim2 = false;
        int startIndex$iv$iv = 0;
        int endIndex$iv$iv = $this$trim$iv$iv.length() - 1;
        boolean startFound$iv$iv = false;
        while (startIndex$iv$iv <= endIndex$iv$iv) {
            boolean match$iv$iv;
            int index$iv$iv = !startFound$iv$iv ? startIndex$iv$iv : endIndex$iv$iv;
            char it = $this$trim$iv$iv.charAt(index$iv$iv);
            boolean bl = false;
            boolean bl2 = match$iv$iv = Intrinsics.compare((int)it, (int)32) <= 0;
            if (!startFound$iv$iv) {
                if (!match$iv$iv) {
                    startFound$iv$iv = true;
                    continue;
                }
                ++startIndex$iv$iv;
                continue;
            }
            if (!match$iv$iv) break;
            --endIndex$iv$iv;
        }
        String string2 = ((Object)$this$trim$iv$iv.subSequence(startIndex$iv$iv, endIndex$iv$iv + 1)).toString();
        Locale locale = Locale.getDefault();
        Intrinsics.checkNotNullExpressionValue((Object)locale, (String)"getDefault()");
        String string3 = string2.toLowerCase(locale);
        Intrinsics.checkNotNullExpressionValue((Object)string3, (String)"this as java.lang.String).toLowerCase(locale)");
        value = string3;
        if (((CharSequence)value).length() == 0) {
            return defaultValue;
        }
        if (Intrinsics.areEqual((Object)"false", (Object)value) || Intrinsics.areEqual((Object)"no", (Object)value) || Intrinsics.areEqual((Object)"0", (Object)value)) {
            return false;
        }
        return Intrinsics.areEqual((Object)"true", (Object)value) || Intrinsics.areEqual((Object)"yes", (Object)value) || Intrinsics.areEqual((Object)"1", (Object)value) ? true : defaultValue;
    }

    public final int getInt(@NotNull String property, int defaultValue) {
        String value;
        Intrinsics.checkNotNullParameter((Object)property, (String)"property");
        String string = this.getProperty(property);
        if (string == null) {
            return defaultValue;
        }
        String $this$trim$iv = value = string;
        boolean $i$f$trim = false;
        CharSequence $this$trim$iv$iv = $this$trim$iv;
        boolean $i$f$trim2 = false;
        int startIndex$iv$iv = 0;
        int endIndex$iv$iv = $this$trim$iv$iv.length() - 1;
        boolean startFound$iv$iv = false;
        while (startIndex$iv$iv <= endIndex$iv$iv) {
            boolean match$iv$iv;
            int index$iv$iv = !startFound$iv$iv ? startIndex$iv$iv : endIndex$iv$iv;
            char it = $this$trim$iv$iv.charAt(index$iv$iv);
            boolean bl = false;
            boolean bl2 = match$iv$iv = Intrinsics.compare((int)it, (int)32) <= 0;
            if (!startFound$iv$iv) {
                if (!match$iv$iv) {
                    startFound$iv$iv = true;
                    continue;
                }
                ++startIndex$iv$iv;
                continue;
            }
            if (!match$iv$iv) break;
            --endIndex$iv$iv;
        }
        value = ((Object)$this$trim$iv$iv.subSequence(startIndex$iv$iv, endIndex$iv$iv + 1)).toString();
        try {
            return Integer.parseInt(value);
        }
        catch (Exception exception) {
            return defaultValue;
        }
    }

    public final long getLong(@NotNull String property, long defaultValue) {
        String value;
        Intrinsics.checkNotNullParameter((Object)property, (String)"property");
        String string = this.getProperty(property);
        if (string == null) {
            return defaultValue;
        }
        String $this$trim$iv = value = string;
        boolean $i$f$trim = false;
        CharSequence $this$trim$iv$iv = $this$trim$iv;
        boolean $i$f$trim2 = false;
        int startIndex$iv$iv = 0;
        int endIndex$iv$iv = $this$trim$iv$iv.length() - 1;
        boolean startFound$iv$iv = false;
        while (startIndex$iv$iv <= endIndex$iv$iv) {
            boolean match$iv$iv;
            int index$iv$iv = !startFound$iv$iv ? startIndex$iv$iv : endIndex$iv$iv;
            char it = $this$trim$iv$iv.charAt(index$iv$iv);
            boolean bl = false;
            boolean bl2 = match$iv$iv = Intrinsics.compare((int)it, (int)32) <= 0;
            if (!startFound$iv$iv) {
                if (!match$iv$iv) {
                    startFound$iv$iv = true;
                    continue;
                }
                ++startIndex$iv$iv;
                continue;
            }
            if (!match$iv$iv) break;
            --endIndex$iv$iv;
        }
        value = ((Object)$this$trim$iv$iv.subSequence(startIndex$iv$iv, endIndex$iv$iv + 1)).toString();
        try {
            return Long.parseLong(value);
        }
        catch (Exception exception) {
            return defaultValue;
        }
    }

    public final float getFloat(@NotNull String property, float defaultValue) {
        String value;
        Intrinsics.checkNotNullParameter((Object)property, (String)"property");
        String string = this.getProperty(property);
        if (string == null) {
            return defaultValue;
        }
        String $this$trim$iv = value = string;
        boolean $i$f$trim = false;
        CharSequence $this$trim$iv$iv = $this$trim$iv;
        boolean $i$f$trim2 = false;
        int startIndex$iv$iv = 0;
        int endIndex$iv$iv = $this$trim$iv$iv.length() - 1;
        boolean startFound$iv$iv = false;
        while (startIndex$iv$iv <= endIndex$iv$iv) {
            boolean match$iv$iv;
            int index$iv$iv = !startFound$iv$iv ? startIndex$iv$iv : endIndex$iv$iv;
            char it = $this$trim$iv$iv.charAt(index$iv$iv);
            boolean bl = false;
            boolean bl2 = match$iv$iv = Intrinsics.compare((int)it, (int)32) <= 0;
            if (!startFound$iv$iv) {
                if (!match$iv$iv) {
                    startFound$iv$iv = true;
                    continue;
                }
                ++startIndex$iv$iv;
                continue;
            }
            if (!match$iv$iv) break;
            --endIndex$iv$iv;
        }
        value = ((Object)$this$trim$iv$iv.subSequence(startIndex$iv$iv, endIndex$iv$iv + 1)).toString();
        try {
            return Float.parseFloat(value);
        }
        catch (Exception exception) {
            return defaultValue;
        }
    }

    public final double getDouble(@NotNull String property, double defaultValue) {
        String value;
        Intrinsics.checkNotNullParameter((Object)property, (String)"property");
        String string = this.getProperty(property);
        if (string == null) {
            return defaultValue;
        }
        String $this$trim$iv = value = string;
        boolean $i$f$trim = false;
        CharSequence $this$trim$iv$iv = $this$trim$iv;
        boolean $i$f$trim2 = false;
        int startIndex$iv$iv = 0;
        int endIndex$iv$iv = $this$trim$iv$iv.length() - 1;
        boolean startFound$iv$iv = false;
        while (startIndex$iv$iv <= endIndex$iv$iv) {
            boolean match$iv$iv;
            int index$iv$iv = !startFound$iv$iv ? startIndex$iv$iv : endIndex$iv$iv;
            char it = $this$trim$iv$iv.charAt(index$iv$iv);
            boolean bl = false;
            boolean bl2 = match$iv$iv = Intrinsics.compare((int)it, (int)32) <= 0;
            if (!startFound$iv$iv) {
                if (!match$iv$iv) {
                    startFound$iv$iv = true;
                    continue;
                }
                ++startIndex$iv$iv;
                continue;
            }
            if (!match$iv$iv) break;
            --endIndex$iv$iv;
        }
        value = ((Object)$this$trim$iv$iv.subSequence(startIndex$iv$iv, endIndex$iv$iv + 1)).toString();
        try {
            return Double.parseDouble(value);
        }
        catch (Exception exception) {
            return defaultValue;
        }
    }

    public final boolean is32bit() {
        return is32bit;
    }

    public final boolean is64bit() {
        return is64bit;
    }

    public final boolean isX86() {
        return isX86;
    }

    public final boolean isMips() {
        return isMips;
    }

    public final boolean isArm() {
        return isArm;
    }

    public final boolean isLinux() {
        return isLinux;
    }

    public final boolean isUnix() {
        return isUnix;
    }

    public final boolean isSolaris() {
        return isSolaris;
    }

    public final boolean isWindows() {
        return isWindows;
    }

    public final boolean isMacOsX() {
        return isMacOsX;
    }

    public final boolean isAndroid() {
        return isAndroid;
    }

    public final void setUTC() {
        TimeZone.setDefault(TimeZone.getTimeZone("UTC"));
    }

    @Nullable
    public final String getExceptionMessage(@NotNull Throwable throwable) {
        Intrinsics.checkNotNullParameter((Object)throwable, (String)"throwable");
        String message = throwable.getMessage();
        if (message != null) {
            int index = StringsKt.indexOf$default((CharSequence)message, (String)LINE_SEPARATOR, (int)0, (boolean)false, (int)6, null);
            if (index > -1) {
                String string = message;
                int n = 0;
                String string2 = string.substring(n, index);
                Intrinsics.checkNotNullExpressionValue((Object)string2, (String)"this as java.lang.String\u2026ing(startIndex, endIndex)");
                message = string2;
            }
        } else {
            message = throwable.getClass().getSimpleName();
        }
        return message;
    }

    private final String execute(String[] args, long timeout) {
        Object object = new ProcessBuilder(ArraysKt.toList((Object[])args)).redirectOutput(ProcessBuilder.Redirect.PIPE).redirectError(ProcessBuilder.Redirect.PIPE).start();
        Process $this$execute_u24lambda_u2d10 = object;
        boolean bl = false;
        $this$execute_u24lambda_u2d10.waitFor(timeout, TimeUnit.SECONDS);
        InputStream inputStream = ((Process)object).getInputStream();
        Intrinsics.checkNotNullExpressionValue((Object)inputStream, (String)"ProcessBuilder(args.toLi\u2026\n            .inputStream");
        object = Charsets.UTF_8;
        Closeable closeable = inputStream;
        closeable = new InputStreamReader((InputStream)closeable, (Charset)object);
        int n = 8192;
        return ((Object)StringsKt.trim((CharSequence)TextStreamsKt.readText((Reader)(closeable instanceof BufferedReader ? (BufferedReader)closeable : new BufferedReader((Reader)closeable, n))))).toString();
    }

    static /* synthetic */ String execute$default(OS oS, String[] stringArray, long l, int n, Object object) {
        if ((n & 2) != 0) {
            l = 60L;
        }
        return oS.execute(stringArray, l);
    }

    private final boolean executeStatus(String[] args, long timeout) {
        Process process;
        Process $this$executeStatus_u24lambda_u2d11 = process = new ProcessBuilder(ArraysKt.toList((Object[])args)).redirectOutput(ProcessBuilder.Redirect.PIPE).redirectError(ProcessBuilder.Redirect.PIPE).start();
        boolean bl = false;
        $this$executeStatus_u24lambda_u2d11.waitFor(timeout, TimeUnit.SECONDS);
        return process.exitValue() == 0;
    }

    static /* synthetic */ boolean executeStatus$default(OS oS, String[] stringArray, long l, int n, Object object) {
        if ((n & 2) != 0) {
            l = 60L;
        }
        return oS.executeStatus(stringArray, l);
    }

    private static final void _init_$lambda-0() {
        while (true) {
            try {
                Thread.sleep(Long.MAX_VALUE);
            }
            catch (Exception exception) {
            }
        }
    }

    private static final String getProperty$lambda-1(String $property) {
        Intrinsics.checkNotNullParameter((Object)$property, (String)"$property");
        return System.getProperty($property, null);
    }

    private static final String getProperty$lambda-2(String $property, String $defaultValue) {
        Intrinsics.checkNotNullParameter((Object)$property, (String)"$property");
        Intrinsics.checkNotNullParameter((Object)$defaultValue, (String)"$defaultValue");
        return System.getProperty($property, $defaultValue);
    }

    private static final Map getEnv$lambda-3() {
        return System.getenv();
    }

    private static final String getEnv$lambda-4(String $property) {
        Intrinsics.checkNotNullParameter((Object)$property, (String)"$property");
        return System.getenv($property);
    }

    static {
        Updates.INSTANCE.add(OS.class, "a2afbd7d98084a9eb6eb663570dbec77", version);
        LINE_SEPARATOR = INSTANCE.getProperty("line.separator", LINE_SEPARATOR_UNIX);
        TEMP_DIR = new File(INSTANCE.getProperty("java.io.tmpdir", "temp")).getAbsoluteFile();
        javaVersion$delegate = LazyKt.lazy((Function0)javaVersion.2.INSTANCE);
        usesJpms = JVM.INSTANCE.getUsesJpms();
        String string = TimeZone.getDefault().getID();
        Intrinsics.checkNotNull((Object)string);
        originalTimeZone = string;
        String string2 = INSTANCE.getProperty("os.name", "linux").toLowerCase(Locale.ROOT);
        Intrinsics.checkNotNullExpressionValue((Object)string2, (String)"this as java.lang.String).toLowerCase(Locale.ROOT)");
        osName = string2;
        string2 = INSTANCE.getProperty("os.arch", "amd64").toLowerCase(Locale.ROOT);
        Intrinsics.checkNotNullExpressionValue((Object)string2, (String)"this as java.lang.String).toLowerCase(Locale.ROOT)");
        osArch = string2;
        optimumNumberOfThreads = RangesKt.coerceAtLeast((int)(Runtime.getRuntime().availableProcessors() - 2), (int)1);
        type$delegate = LazyKt.lazy((Function0)type.2.INSTANCE);
        if (!TEMP_DIR.isDirectory()) {
            TEMP_DIR.mkdirs();
        }
        if (INSTANCE.getType().isWindows()) {
            Thread timerAccuracyThread = new Thread(OS::_init_$lambda-0, "FixWindowsHighResTimer");
            timerAccuracyThread.setDaemon(true);
            timerAccuracyThread.start();
        }
        is32bit = INSTANCE.getType().is32bit();
        is64bit = INSTANCE.getType().is64bit();
        isX86 = INSTANCE.getType().isX86();
        isMips = INSTANCE.getType().isMips();
        isArm = INSTANCE.getType().isArm();
        isLinux = INSTANCE.getType().isLinux();
        isUnix = INSTANCE.getType().isUnix();
        isSolaris = INSTANCE.getType().isSolaris();
        isWindows = INSTANCE.getType().isWindows();
        isMacOsX = INSTANCE.getType().isMacOsX();
        isAndroid = INSTANCE.getType().isAndroid();
    }

    @Metadata(mv={1, 6, 0}, k=1, xi=48, d1={"\u0000\u001c\n\u0002\u0018\u0002\n\u0002\u0010\u0000\n\u0002\b\u0002\n\u0002\u0010\u000b\n\u0002\b\r\n\u0002\u0010\u0015\n\u0002\b\u0004\b\u00c6\u0002\u0018\u00002\u00020\u0001B\u0007\b\u0002\u00a2\u0006\u0002\u0010\u0002R\u0011\u0010\u0003\u001a\u00020\u0004\u00a2\u0006\b\n\u0000\u001a\u0004\b\u0003\u0010\u0005R\u0011\u0010\u0006\u001a\u00020\u0004\u00a2\u0006\b\n\u0000\u001a\u0004\b\u0006\u0010\u0005R\u0011\u0010\u0007\u001a\u00020\u0004\u00a2\u0006\b\n\u0000\u001a\u0004\b\u0007\u0010\u0005R\u0011\u0010\b\u001a\u00020\u0004\u00a2\u0006\b\n\u0000\u001a\u0004\b\b\u0010\u0005R\u0011\u0010\t\u001a\u00020\u0004\u00a2\u0006\b\n\u0000\u001a\u0004\b\t\u0010\u0005R\u0011\u0010\n\u001a\u00020\u0004\u00a2\u0006\b\n\u0000\u001a\u0004\b\n\u0010\u0005R\u0011\u0010\u000b\u001a\u00020\u0004\u00a2\u0006\b\n\u0000\u001a\u0004\b\u000b\u0010\u0005R\u001b\u0010\f\u001a\u00020\u00048FX\u0086\u0084\u0002\u00a2\u0006\f\n\u0004\b\r\u0010\u000e\u001a\u0004\b\f\u0010\u0005R\u0011\u0010\u000f\u001a\u00020\u0004\u00a2\u0006\b\n\u0000\u001a\u0004\b\u000f\u0010\u0005R\u0011\u0010\u0010\u001a\u00020\u0004\u00a2\u0006\b\n\u0000\u001a\u0004\b\u0010\u0010\u0005R\u001b\u0010\u0011\u001a\u00020\u00128FX\u0086\u0084\u0002\u00a2\u0006\f\n\u0004\b\u0015\u0010\u000e\u001a\u0004\b\u0013\u0010\u0014\u00a8\u0006\u0016"}, d2={"Ldorkbox/os/OS$Windows;", "", "()V", "isWindows10", "", "()Z", "isWindows10_plus", "isWindows11", "isWindows11_22H2", "isWindows7", "isWindows8", "isWindows8_1", "isWindows8_1_plus", "isWindows8_1_plus$delegate", "Lkotlin/Lazy;", "isWindowsVista", "isWindowsXP", "version", "", "getVersion", "()[I", "version$delegate", "OS"})
    public static final class Windows {
        @NotNull
        public static final Windows INSTANCE = new Windows();
        @NotNull
        private static final Lazy version$delegate = LazyKt.lazy((Function0)version.2.INSTANCE);
        private static final boolean isWindowsXP = INSTANCE.getVersion()[0] == 5;
        private static final boolean isWindowsVista = INSTANCE.getVersion()[0] == 6 && INSTANCE.getVersion()[1] == 0;
        private static final boolean isWindows7 = INSTANCE.getVersion()[0] == 6 && INSTANCE.getVersion()[1] == 1;
        private static final boolean isWindows8 = INSTANCE.getVersion()[0] == 6 && INSTANCE.getVersion()[1] == 2;
        private static final boolean isWindows8_1 = INSTANCE.getVersion()[0] == 6 && INSTANCE.getVersion()[1] == 3;
        @NotNull
        private static final Lazy isWindows8_1_plus$delegate = LazyKt.lazy((Function0)isWindows8_1_plus.2.INSTANCE);
        private static final boolean isWindows10 = INSTANCE.getVersion()[0] == 10;
        private static final boolean isWindows10_plus = INSTANCE.getVersion()[0] >= 10;
        private static final boolean isWindows11 = INSTANCE.getVersion()[0] == 10 && INSTANCE.getVersion()[1] == 0 && INSTANCE.getVersion()[2] >= 22000;
        private static final boolean isWindows11_22H2 = INSTANCE.getVersion()[0] == 10 && INSTANCE.getVersion()[1] == 0 && INSTANCE.getVersion()[2] >= 22621;

        private Windows() {
        }

        @NotNull
        public final int[] getVersion() {
            Lazy lazy = version$delegate;
            return (int[])lazy.getValue();
        }

        public final boolean isWindowsXP() {
            return isWindowsXP;
        }

        public final boolean isWindowsVista() {
            return isWindowsVista;
        }

        public final boolean isWindows7() {
            return isWindows7;
        }

        public final boolean isWindows8() {
            return isWindows8;
        }

        public final boolean isWindows8_1() {
            return isWindows8_1;
        }

        public final boolean isWindows8_1_plus() {
            Lazy lazy = isWindows8_1_plus$delegate;
            return (Boolean)lazy.getValue();
        }

        public final boolean isWindows10() {
            return isWindows10;
        }

        public final boolean isWindows10_plus() {
            return isWindows10_plus;
        }

        public final boolean isWindows11() {
            return isWindows11;
        }

        public final boolean isWindows11_22H2() {
            return isWindows11_22H2;
        }
    }

    @Metadata(mv={1, 6, 0}, k=1, xi=48, d1={"\u0000\u0014\n\u0002\u0018\u0002\n\u0002\u0010\u0000\n\u0002\b\u0002\n\u0002\u0010\u000b\n\u0002\b\u0004\b\u00c6\u0002\u0018\u00002\u00020\u0001B\u0007\b\u0002\u00a2\u0006\u0002\u0010\u0002R\u001b\u0010\u0003\u001a\u00020\u00048FX\u0086\u0084\u0002\u00a2\u0006\f\n\u0004\b\u0006\u0010\u0007\u001a\u0004\b\u0003\u0010\u0005\u00a8\u0006\b"}, d2={"Ldorkbox/os/OS$Unix;", "", "()V", "isFreeBSD", "", "()Z", "isFreeBSD$delegate", "Lkotlin/Lazy;", "OS"})
    public static final class Unix {
        @NotNull
        public static final Unix INSTANCE = new Unix();
        @NotNull
        private static final Lazy isFreeBSD$delegate = LazyKt.lazy((Function0)isFreeBSD.2.INSTANCE);

        private Unix() {
        }

        public final boolean isFreeBSD() {
            Lazy lazy = isFreeBSD$delegate;
            return (Boolean)lazy.getValue();
        }
    }

    @Metadata(mv={1, 6, 0}, k=1, xi=48, d1={"\u0000,\n\u0002\u0018\u0002\n\u0002\u0010\u0000\n\u0002\b\u0002\n\u0002\u0010\u000e\n\u0002\b\u0005\n\u0002\u0010\u0015\n\u0002\b\u0004\n\u0002\u0010\b\n\u0002\b\u0007\n\u0002\u0010\u000b\n\u0002\b\u001d\b\u00c6\u0002\u0018\u00002\u00020\u0001:\u00013B\u0007\b\u0002\u00a2\u0006\u0002\u0010\u0002J\u000e\u00101\u001a\u00020\u00172\u0006\u00102\u001a\u00020\u0004R\u001d\u0010\u0003\u001a\u0004\u0018\u00010\u00048FX\u0086\u0084\u0002\u00a2\u0006\f\n\u0004\b\u0007\u0010\b\u001a\u0004\b\u0005\u0010\u0006R\u001b\u0010\t\u001a\u00020\n8FX\u0086\u0084\u0002\u00a2\u0006\f\n\u0004\b\r\u0010\b\u001a\u0004\b\u000b\u0010\fR\u001b\u0010\u000e\u001a\u00020\u000f8FX\u0086\u0084\u0002\u00a2\u0006\f\n\u0004\b\u0012\u0010\b\u001a\u0004\b\u0010\u0010\u0011R\u001b\u0010\u0013\u001a\u00020\u00048FX\u0086\u0084\u0002\u00a2\u0006\f\n\u0004\b\u0015\u0010\b\u001a\u0004\b\u0014\u0010\u0006R\u001b\u0010\u0016\u001a\u00020\u00178FX\u0086\u0084\u0002\u00a2\u0006\f\n\u0004\b\u0019\u0010\b\u001a\u0004\b\u0016\u0010\u0018R\u001b\u0010\u001a\u001a\u00020\u00178FX\u0086\u0084\u0002\u00a2\u0006\f\n\u0004\b\u001b\u0010\b\u001a\u0004\b\u001a\u0010\u0018R\u001b\u0010\u001c\u001a\u00020\u00178FX\u0086\u0084\u0002\u00a2\u0006\f\n\u0004\b\u001d\u0010\b\u001a\u0004\b\u001c\u0010\u0018R\u001b\u0010\u001e\u001a\u00020\u00178FX\u0086\u0084\u0002\u00a2\u0006\f\n\u0004\b\u001f\u0010\b\u001a\u0004\b\u001e\u0010\u0018R\u001b\u0010 \u001a\u00020\u00178FX\u0086\u0084\u0002\u00a2\u0006\f\n\u0004\b!\u0010\b\u001a\u0004\b \u0010\u0018R\u001b\u0010\"\u001a\u00020\u00178FX\u0086\u0084\u0002\u00a2\u0006\f\n\u0004\b#\u0010\b\u001a\u0004\b\"\u0010\u0018R\u001b\u0010$\u001a\u00020\u00178FX\u0086\u0084\u0002\u00a2\u0006\f\n\u0004\b%\u0010\b\u001a\u0004\b$\u0010\u0018R\u001b\u0010&\u001a\u00020\u00178FX\u0086\u0084\u0002\u00a2\u0006\f\n\u0004\b'\u0010\b\u001a\u0004\b&\u0010\u0018R\u001b\u0010(\u001a\u00020\u00178FX\u0086\u0084\u0002\u00a2\u0006\f\n\u0004\b)\u0010\b\u001a\u0004\b(\u0010\u0018R\u001b\u0010*\u001a\u00020\u00178FX\u0086\u0084\u0002\u00a2\u0006\f\n\u0004\b+\u0010\b\u001a\u0004\b*\u0010\u0018R\u001b\u0010,\u001a\u00020\u00178FX\u0086\u0084\u0002\u00a2\u0006\f\n\u0004\b-\u0010\b\u001a\u0004\b,\u0010\u0018R\u001b\u0010.\u001a\u00020\n8FX\u0086\u0084\u0002\u00a2\u0006\f\n\u0004\b0\u0010\b\u001a\u0004\b/\u0010\f\u00a8\u00064"}, d2={"Ldorkbox/os/OS$Linux;", "", "()V", "distribReleaseInfo", "", "getDistribReleaseInfo", "()Ljava/lang/String;", "distribReleaseInfo$delegate", "Lkotlin/Lazy;", "elementaryOSVersion", "", "getElementaryOSVersion", "()[I", "elementaryOSVersion$delegate", "fedoraVersion", "", "getFedoraVersion", "()I", "fedoraVersion$delegate", "info", "getInfo", "info$delegate", "isArch", "", "()Z", "isArch$delegate", "isDebian", "isDebian$delegate", "isElementaryOS", "isElementaryOS$delegate", "isFedora", "isFedora$delegate", "isIgel", "isIgel$delegate", "isKali", "isKali$delegate", "isLinuxMint", "isLinuxMint$delegate", "isPop", "isPop$delegate", "isRoot", "isRoot$delegate", "isUbuntu", "isUbuntu$delegate", "isWSL", "isWSL$delegate", "ubuntuVersion", "getUbuntuVersion", "ubuntuVersion$delegate", "isReleaseType", "id", "PackageManager", "OS"})
    public static final class Linux {
        @NotNull
        public static final Linux INSTANCE = new Linux();
        @NotNull
        private static final Lazy info$delegate = LazyKt.lazy((Function0)info.2.INSTANCE);
        @NotNull
        private static final Lazy isArch$delegate = LazyKt.lazy((Function0)isArch.2.INSTANCE);
        @NotNull
        private static final Lazy isDebian$delegate = LazyKt.lazy((Function0)isDebian.2.INSTANCE);
        @NotNull
        private static final Lazy isElementaryOS$delegate = LazyKt.lazy((Function0)isElementaryOS.2.INSTANCE);
        @NotNull
        private static final Lazy isFedora$delegate = LazyKt.lazy((Function0)isFedora.2.INSTANCE);
        @NotNull
        private static final Lazy fedoraVersion$delegate = LazyKt.lazy((Function0)fedoraVersion.2.INSTANCE);
        @NotNull
        private static final Lazy isLinuxMint$delegate = LazyKt.lazy((Function0)isLinuxMint.2.INSTANCE);
        @NotNull
        private static final Lazy isUbuntu$delegate = LazyKt.lazy((Function0)isUbuntu.2.INSTANCE);
        @NotNull
        private static final Lazy ubuntuVersion$delegate = LazyKt.lazy((Function0)ubuntuVersion.2.INSTANCE);
        @NotNull
        private static final Lazy elementaryOSVersion$delegate = LazyKt.lazy((Function0)elementaryOSVersion.2.INSTANCE);
        @NotNull
        private static final Lazy isKali$delegate = LazyKt.lazy((Function0)isKali.2.INSTANCE);
        @NotNull
        private static final Lazy isPop$delegate = LazyKt.lazy((Function0)isPop.2.INSTANCE);
        @NotNull
        private static final Lazy isIgel$delegate = LazyKt.lazy((Function0)isIgel.2.INSTANCE);
        @NotNull
        private static final Lazy distribReleaseInfo$delegate = LazyKt.lazy((Function0)distribReleaseInfo.2.INSTANCE);
        @NotNull
        private static final Lazy isWSL$delegate = LazyKt.lazy((Function0)isWSL.2.INSTANCE);
        @NotNull
        private static final Lazy isRoot$delegate = LazyKt.lazy((Function0)isRoot.2.INSTANCE);

        private Linux() {
        }

        @NotNull
        public final String getInfo() {
            Lazy lazy = info$delegate;
            return (String)lazy.getValue();
        }

        public final boolean isReleaseType(@NotNull String id) {
            Intrinsics.checkNotNullParameter((Object)id, (String)"id");
            return StringsKt.contains$default((CharSequence)this.getInfo(), (CharSequence)("ID=" + id + '\n'), (boolean)false, (int)2, null);
        }

        public final boolean isArch() {
            Lazy lazy = isArch$delegate;
            return (Boolean)lazy.getValue();
        }

        public final boolean isDebian() {
            Lazy lazy = isDebian$delegate;
            return (Boolean)lazy.getValue();
        }

        public final boolean isElementaryOS() {
            Lazy lazy = isElementaryOS$delegate;
            return (Boolean)lazy.getValue();
        }

        public final boolean isFedora() {
            Lazy lazy = isFedora$delegate;
            return (Boolean)lazy.getValue();
        }

        public final int getFedoraVersion() {
            Lazy lazy = fedoraVersion$delegate;
            return ((Number)lazy.getValue()).intValue();
        }

        public final boolean isLinuxMint() {
            Lazy lazy = isLinuxMint$delegate;
            return (Boolean)lazy.getValue();
        }

        public final boolean isUbuntu() {
            Lazy lazy = isUbuntu$delegate;
            return (Boolean)lazy.getValue();
        }

        @NotNull
        public final int[] getUbuntuVersion() {
            Lazy lazy = ubuntuVersion$delegate;
            return (int[])lazy.getValue();
        }

        @NotNull
        public final int[] getElementaryOSVersion() {
            Lazy lazy = elementaryOSVersion$delegate;
            return (int[])lazy.getValue();
        }

        public final boolean isKali() {
            Lazy lazy = isKali$delegate;
            return (Boolean)lazy.getValue();
        }

        public final boolean isPop() {
            Lazy lazy = isPop$delegate;
            return (Boolean)lazy.getValue();
        }

        public final boolean isIgel() {
            Lazy lazy = isIgel$delegate;
            return (Boolean)lazy.getValue();
        }

        @Nullable
        public final String getDistribReleaseInfo() {
            Lazy lazy = distribReleaseInfo$delegate;
            return (String)lazy.getValue();
        }

        public final boolean isWSL() {
            Lazy lazy = isWSL$delegate;
            return (Boolean)lazy.getValue();
        }

        public final boolean isRoot() {
            Lazy lazy = isRoot$delegate;
            return (Boolean)lazy.getValue();
        }

        @Metadata(mv={1, 6, 0}, k=1, xi=48, d1={"\u0000\"\n\u0002\u0018\u0002\n\u0002\u0010\u0000\n\u0002\b\u0002\n\u0002\u0018\u0002\n\u0002\b\u0005\n\u0002\u0010\u000b\n\u0000\n\u0002\u0010\u000e\n\u0002\b\u0002\b\u00c6\u0002\u0018\u00002\u00020\u0001:\u0001\rB\u0007\b\u0002\u00a2\u0006\u0002\u0010\u0002J\u000e\u0010\t\u001a\u00020\n2\u0006\u0010\u000b\u001a\u00020\fR\u001b\u0010\u0003\u001a\u00020\u00048FX\u0086\u0084\u0002\u00a2\u0006\f\n\u0004\b\u0007\u0010\b\u001a\u0004\b\u0005\u0010\u0006\u00a8\u0006\u000e"}, d2={"Ldorkbox/os/OS$Linux$PackageManager;", "", "()V", "type", "Ldorkbox/os/OS$Linux$PackageManager$Type;", "getType", "()Ldorkbox/os/OS$Linux$PackageManager$Type;", "type$delegate", "Lkotlin/Lazy;", "isPackageInstalled", "", "packageName", "", "Type", "OS"})
        public static final class PackageManager {
            @NotNull
            public static final PackageManager INSTANCE = new PackageManager();
            @NotNull
            private static final Lazy type$delegate = LazyKt.lazy((Function0)type.2.INSTANCE);

            private PackageManager() {
            }

            @NotNull
            public final Type getType() {
                Lazy lazy = type$delegate;
                return (Type)((Object)lazy.getValue());
            }

            public final boolean isPackageInstalled(@NotNull String packageName) {
                Intrinsics.checkNotNullParameter((Object)packageName, (String)"packageName");
                boolean is_dpkg = new File("/usr/bin/dpkg").canExecute();
                if (is_dpkg) {
                    String[] stringArray = new String[]{"dpkg", "-L", packageName};
                    return !StringsKt.contains$default((CharSequence)OS.execute$default(OS.INSTANCE, stringArray, 0L, 2, null), (CharSequence)"is not installed", (boolean)false, (int)2, null);
                }
                boolean is_rpm = new File("/usr/bin/rpm").canExecute();
                if (is_rpm) {
                    String[] stringArray = new String[]{"rpm", "-q", packageName};
                    return !StringsKt.contains$default((CharSequence)OS.execute$default(OS.INSTANCE, stringArray, 0L, 2, null), (CharSequence)"is not installed", (boolean)false, (int)2, null);
                }
                boolean is_pacmac = new File("/usr/bin/pacman").canExecute();
                if (is_pacmac) {
                    try {
                        String[] stringArray = new String[]{"pacman", "-Qi", packageName};
                        return OS.executeStatus$default(OS.INSTANCE, stringArray, 0L, 2, null);
                    }
                    catch (Exception exception) {
                        // empty catch block
                    }
                }
                return false;
            }

            @Metadata(mv={1, 6, 0}, k=1, xi=48, d1={"\u0000\u0012\n\u0002\u0018\u0002\n\u0002\u0010\u0010\n\u0000\n\u0002\u0010\u000e\n\u0002\b\b\b\u0086\u0001\u0018\u00002\b\u0012\u0004\u0012\u00020\u00000\u0001B\u000f\b\u0002\u0012\u0006\u0010\u0002\u001a\u00020\u0003\u00a2\u0006\u0002\u0010\u0004R\u0011\u0010\u0002\u001a\u00020\u0003\u00a2\u0006\b\n\u0000\u001a\u0004\b\u0005\u0010\u0006j\u0002\b\u0007j\u0002\b\bj\u0002\b\tj\u0002\b\n\u00a8\u0006\u000b"}, d2={"Ldorkbox/os/OS$Linux$PackageManager$Type;", "", "installString", "", "(Ljava/lang/String;ILjava/lang/String;)V", "getInstallString", "()Ljava/lang/String;", "APT", "APTGET", "YUM", "PACMAN", "OS"})
            public static final class Type
            extends Enum<Type> {
                @NotNull
                private final String installString;
                public static final /* enum */ Type APT = new Type("apt install");
                public static final /* enum */ Type APTGET = new Type("apt-get install");
                public static final /* enum */ Type YUM = new Type("yum install");
                public static final /* enum */ Type PACMAN = new Type("pacman -S ");
                private static final /* synthetic */ Type[] $VALUES;

                private Type(String installString) {
                    this.installString = installString;
                }

                @NotNull
                public final String getInstallString() {
                    return this.installString;
                }

                public static Type[] values() {
                    return (Type[])$VALUES.clone();
                }

                public static Type valueOf(String value) {
                    return Enum.valueOf(Type.class, value);
                }

                static {
                    $VALUES = typeArray = new Type[]{Type.APT, Type.APTGET, Type.YUM, Type.PACMAN};
                }
            }
        }
    }

    @Metadata(mv={1, 6, 0}, k=1, xi=48, d1={"\u00004\n\u0002\u0018\u0002\n\u0002\u0010\u0000\n\u0002\b\u0002\n\u0002\u0018\u0002\n\u0002\b\u0005\n\u0002\u0010\u000e\n\u0002\b\u0004\n\u0002\u0010\u000b\n\u0002\b\u0010\n\u0002\u0010\u0006\n\u0002\b\u0007\n\u0002\u0018\u0002\n\u0002\b\f\b\u00c6\u0002\u0018\u00002\u00020\u0001:\u000223B\u0007\b\u0002\u00a2\u0006\u0002\u0010\u0002J\u000e\u0010\u001a\u001a\u00020\u000f2\u0006\u0010\u0003\u001a\u00020\u0004J\u0018\u0010,\u001a\u00020\u000f2\u0006\u0010-\u001a\u00020\n2\u0006\u0010.\u001a\u00020\nH\u0002J\u0018\u0010/\u001a\u00020\n2\u0006\u00100\u001a\u00020\n2\b\u00101\u001a\u0004\u0018\u00010\nR\u001b\u0010\u0003\u001a\u00020\u00048FX\u0086\u0084\u0002\u00a2\u0006\f\n\u0004\b\u0007\u0010\b\u001a\u0004\b\u0005\u0010\u0006R\u001d\u0010\t\u001a\u0004\u0018\u00010\n8FX\u0086\u0084\u0002\u00a2\u0006\f\n\u0004\b\r\u0010\b\u001a\u0004\b\u000b\u0010\fR\u001b\u0010\u000e\u001a\u00020\u000f8FX\u0086\u0084\u0002\u00a2\u0006\f\n\u0004\b\u0011\u0010\b\u001a\u0004\b\u000e\u0010\u0010R\u001b\u0010\u0012\u001a\u00020\u000f8FX\u0086\u0084\u0002\u00a2\u0006\f\n\u0004\b\u0013\u0010\b\u001a\u0004\b\u0012\u0010\u0010R\u001b\u0010\u0014\u001a\u00020\u000f8FX\u0086\u0084\u0002\u00a2\u0006\f\n\u0004\b\u0015\u0010\b\u001a\u0004\b\u0014\u0010\u0010R\u001b\u0010\u0016\u001a\u00020\u000f8FX\u0086\u0084\u0002\u00a2\u0006\f\n\u0004\b\u0017\u0010\b\u001a\u0004\b\u0016\u0010\u0010R\u001b\u0010\u0018\u001a\u00020\u000f8FX\u0086\u0084\u0002\u00a2\u0006\f\n\u0004\b\u0019\u0010\b\u001a\u0004\b\u0018\u0010\u0010R\u0011\u0010\u001a\u001a\u00020\u000f\u00a2\u0006\b\n\u0000\u001a\u0004\b\u001a\u0010\u0010R\u0011\u0010\u001b\u001a\u00020\u000f\u00a2\u0006\b\n\u0000\u001a\u0004\b\u001b\u0010\u0010R\u0011\u0010\u001c\u001a\u00020\u000f\u00a2\u0006\b\n\u0000\u001a\u0004\b\u001c\u0010\u0010R\u001b\u0010\u001d\u001a\u00020\u000f8FX\u0086\u0084\u0002\u00a2\u0006\f\n\u0004\b\u001e\u0010\b\u001a\u0004\b\u001d\u0010\u0010R\u001b\u0010\u001f\u001a\u00020 8FX\u0086\u0084\u0002\u00a2\u0006\f\n\u0004\b#\u0010\b\u001a\u0004\b!\u0010\"R\u001d\u0010$\u001a\u0004\u0018\u00010\n8FX\u0086\u0084\u0002\u00a2\u0006\f\n\u0004\b&\u0010\b\u001a\u0004\b%\u0010\fR\u001b\u0010'\u001a\u00020(8FX\u0086\u0084\u0002\u00a2\u0006\f\n\u0004\b+\u0010\b\u001a\u0004\b)\u0010*\u00a8\u00064"}, d2={"Ldorkbox/os/OS$DesktopEnv;", "", "()V", "env", "Ldorkbox/os/OS$DesktopEnv$Env;", "getEnv", "()Ldorkbox/os/OS$DesktopEnv$Env;", "env$delegate", "Lkotlin/Lazy;", "gnomeVersion", "", "getGnomeVersion", "()Ljava/lang/String;", "gnomeVersion$delegate", "isChromeOS", "", "()Z", "isChromeOS$delegate", "isGnome", "isGnome$delegate", "isKDE", "isKDE$delegate", "isMATE", "isMATE$delegate", "isNautilus", "isNautilus$delegate", "isUnity", "isWayland", "isX11", "isXfce", "isXfce$delegate", "plasmaVersion", "", "getPlasmaVersion", "()D", "plasmaVersion$delegate", "plasmaVersionFull", "getPlasmaVersionFull", "plasmaVersionFull$delegate", "type", "Ldorkbox/os/OS$DesktopEnv$EnvType;", "getType", "()Ldorkbox/os/OS$DesktopEnv$EnvType;", "type$delegate", "isValidCommand", "partialExpectationInOutput", "commandOutput", "queryXfce", "channel", "property", "Env", "EnvType", "OS"})
    public static final class DesktopEnv {
        @NotNull
        public static final DesktopEnv INSTANCE = new DesktopEnv();
        @NotNull
        private static final Lazy type$delegate = LazyKt.lazy((Function0)type.2.INSTANCE);
        private static final boolean isX11 = INSTANCE.getType() == EnvType.X11;
        private static final boolean isWayland = INSTANCE.getType() == EnvType.WAYLAND;
        @NotNull
        private static final Lazy isMATE$delegate = LazyKt.lazy((Function0)isMATE.2.INSTANCE);
        @NotNull
        private static final Lazy isGnome$delegate = LazyKt.lazy((Function0)isGnome.2.INSTANCE);
        @NotNull
        private static final Lazy gnomeVersion$delegate = LazyKt.lazy((Function0)gnomeVersion.2.INSTANCE);
        @NotNull
        private static final Lazy isKDE$delegate = LazyKt.lazy((Function0)isKDE.2.INSTANCE);
        @NotNull
        private static final Lazy plasmaVersionFull$delegate = LazyKt.lazy((Function0)plasmaVersionFull.2.INSTANCE);
        @NotNull
        private static final Lazy plasmaVersion$delegate = LazyKt.lazy((Function0)plasmaVersion.2.INSTANCE);
        @NotNull
        private static final Lazy isXfce$delegate = LazyKt.lazy((Function0)isXfce.2.INSTANCE);
        @NotNull
        private static final Lazy isNautilus$delegate = LazyKt.lazy((Function0)isNautilus.2.INSTANCE);
        @NotNull
        private static final Lazy isChromeOS$delegate = LazyKt.lazy((Function0)isChromeOS.2.INSTANCE);
        @NotNull
        private static final Lazy env$delegate = LazyKt.lazy((Function0)env.2.INSTANCE);
        private static final boolean isUnity = INSTANCE.isUnity(INSTANCE.getEnv());

        private DesktopEnv() {
        }

        private final boolean isValidCommand(String partialExpectationInOutput, String commandOutput) {
            return StringsKt.contains$default((CharSequence)commandOutput, (CharSequence)partialExpectationInOutput, (boolean)false, (int)2, null) && !StringsKt.contains$default((CharSequence)commandOutput, (CharSequence)"not installed", (boolean)false, (int)2, null) && !StringsKt.contains$default((CharSequence)commandOutput, (CharSequence)"No such file or directory", (boolean)false, (int)2, null);
        }

        @NotNull
        public final EnvType getType() {
            Lazy lazy = type$delegate;
            return (EnvType)((Object)lazy.getValue());
        }

        public final boolean isX11() {
            return isX11;
        }

        public final boolean isWayland() {
            return isWayland;
        }

        public final boolean isMATE() {
            Lazy lazy = isMATE$delegate;
            return (Boolean)lazy.getValue();
        }

        public final boolean isGnome() {
            Lazy lazy = isGnome$delegate;
            return (Boolean)lazy.getValue();
        }

        @Nullable
        public final String getGnomeVersion() {
            Lazy lazy = gnomeVersion$delegate;
            return (String)lazy.getValue();
        }

        public final boolean isKDE() {
            Lazy lazy = isKDE$delegate;
            return (Boolean)lazy.getValue();
        }

        @Nullable
        public final String getPlasmaVersionFull() {
            Lazy lazy = plasmaVersionFull$delegate;
            return (String)lazy.getValue();
        }

        public final double getPlasmaVersion() {
            Lazy lazy = plasmaVersion$delegate;
            return ((Number)lazy.getValue()).doubleValue();
        }

        public final boolean isXfce() {
            Lazy lazy = isXfce$delegate;
            return (Boolean)lazy.getValue();
        }

        public final boolean isNautilus() {
            Lazy lazy = isNautilus$delegate;
            return (Boolean)lazy.getValue();
        }

        public final boolean isChromeOS() {
            Lazy lazy = isChromeOS$delegate;
            return (Boolean)lazy.getValue();
        }

        @NotNull
        public final String queryXfce(@NotNull String channel, @Nullable String property) {
            Intrinsics.checkNotNullParameter((Object)channel, (String)"channel");
            if (!INSTANCE.isLinux() && !INSTANCE.isUnix()) {
                return "";
            }
            try {
                List commands = new ArrayList();
                commands.add("xfconf-query");
                commands.add("-c");
                commands.add(channel);
                if (property != null) {
                    commands.add("-p");
                    commands.add(property);
                } else {
                    commands.add("-l");
                }
                Collection $this$toTypedArray$iv = commands;
                boolean $i$f$toTypedArray = false;
                Collection thisCollection$iv = $this$toTypedArray$iv;
                String[] stringArray = thisCollection$iv.toArray(new String[0]);
                if (stringArray == null) {
                    throw new NullPointerException("null cannot be cast to non-null type kotlin.Array<T of kotlin.collections.ArraysKt__ArraysJVMKt.toTypedArray>");
                }
                String[] stringArray2 = stringArray;
                return OS.execute$default(INSTANCE, Arrays.copyOf(stringArray2, stringArray2.length), 0L, 2, null);
            }
            catch (Throwable ignored) {
                return "";
            }
        }

        @NotNull
        public final Env getEnv() {
            Lazy lazy = env$delegate;
            return (Env)((Object)lazy.getValue());
        }

        public final boolean isUnity() {
            return isUnity;
        }

        public final boolean isUnity(@NotNull Env env2) {
            Intrinsics.checkNotNullParameter((Object)((Object)env2), (String)"env");
            return env2 == Env.Unity || env2 == Env.Unity7;
        }

        public static final /* synthetic */ boolean access$isValidCommand(DesktopEnv $this, String partialExpectationInOutput, String commandOutput) {
            return $this.isValidCommand(partialExpectationInOutput, commandOutput);
        }

        @Metadata(mv={1, 6, 0}, k=1, xi=48, d1={"\u0000\f\n\u0002\u0018\u0002\n\u0002\u0010\u0010\n\u0002\b\f\b\u0086\u0001\u0018\u00002\b\u0012\u0004\u0012\u00020\u00000\u0001B\u0007\b\u0002\u00a2\u0006\u0002\u0010\u0002j\u0002\b\u0003j\u0002\b\u0004j\u0002\b\u0005j\u0002\b\u0006j\u0002\b\u0007j\u0002\b\bj\u0002\b\tj\u0002\b\nj\u0002\b\u000bj\u0002\b\f\u00a8\u0006\r"}, d2={"Ldorkbox/os/OS$DesktopEnv$Env;", "", "(Ljava/lang/String;I)V", "Gnome", "KDE", "Unity", "Unity7", "XFCE", "LXDE", "MATE", "Pantheon", "ChromeOS", "Unknown", "OS"})
        public static final class Env
        extends Enum<Env> {
            public static final /* enum */ Env Gnome = new Env();
            public static final /* enum */ Env KDE = new Env();
            public static final /* enum */ Env Unity = new Env();
            public static final /* enum */ Env Unity7 = new Env();
            public static final /* enum */ Env XFCE = new Env();
            public static final /* enum */ Env LXDE = new Env();
            public static final /* enum */ Env MATE = new Env();
            public static final /* enum */ Env Pantheon = new Env();
            public static final /* enum */ Env ChromeOS = new Env();
            public static final /* enum */ Env Unknown = new Env();
            private static final /* synthetic */ Env[] $VALUES;

            public static Env[] values() {
                return (Env[])$VALUES.clone();
            }

            public static Env valueOf(String value) {
                return Enum.valueOf(Env.class, value);
            }

            static {
                $VALUES = envArray = new Env[]{Env.Gnome, Env.KDE, Env.Unity, Env.Unity7, Env.XFCE, Env.LXDE, Env.MATE, Env.Pantheon, Env.ChromeOS, Env.Unknown};
            }
        }

        @Metadata(mv={1, 6, 0}, k=1, xi=48, d1={"\u0000\f\n\u0002\u0018\u0002\n\u0002\u0010\u0010\n\u0002\b\u0005\b\u0086\u0001\u0018\u00002\b\u0012\u0004\u0012\u00020\u00000\u0001B\u0007\b\u0002\u00a2\u0006\u0002\u0010\u0002j\u0002\b\u0003j\u0002\b\u0004j\u0002\b\u0005\u00a8\u0006\u0006"}, d2={"Ldorkbox/os/OS$DesktopEnv$EnvType;", "", "(Ljava/lang/String;I)V", "X11", "WAYLAND", "Unknown", "OS"})
        public static final class EnvType
        extends Enum<EnvType> {
            public static final /* enum */ EnvType X11 = new EnvType();
            public static final /* enum */ EnvType WAYLAND = new EnvType();
            public static final /* enum */ EnvType Unknown = new EnvType();
            private static final /* synthetic */ EnvType[] $VALUES;

            public static EnvType[] values() {
                return (EnvType[])$VALUES.clone();
            }

            public static EnvType valueOf(String value) {
                return Enum.valueOf(EnvType.class, value);
            }

            static {
                $VALUES = envTypeArray = new EnvType[]{EnvType.X11, EnvType.WAYLAND, EnvType.Unknown};
            }
        }
    }
}

