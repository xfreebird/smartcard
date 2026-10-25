/*
 * Decompiled with CFR 0.152.
 * 
 * Could not load the following classes:
 *  kotlin.Metadata
 *  kotlin.io.FilesKt
 *  kotlin.jvm.internal.Intrinsics
 *  kotlin.text.StringsKt
 *  org.jetbrains.annotations.NotNull
 *  org.slf4j.Logger
 *  org.slf4j.LoggerFactory
 */
package dorkbox.executor;

import java.io.File;
import java.io.IOException;
import kotlin.Metadata;
import kotlin.io.FilesKt;
import kotlin.jvm.internal.Intrinsics;
import kotlin.text.StringsKt;
import org.jetbrains.annotations.NotNull;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

/*
 * Multiple versions of this class in jar - see https://www.benf.org/other/cfr/multi-version-jar.html
 */
@Metadata(mv={1, 6, 0}, k=1, xi=48, d1={"\u0000(\n\u0002\u0018\u0002\n\u0002\u0010\u0000\n\u0002\b\u0002\n\u0002\u0018\u0002\n\u0002\b\u0002\n\u0002\u0018\u0002\n\u0000\n\u0002\u0010\u000e\n\u0000\n\u0002\u0010\u000b\n\u0002\b\u0003\b\u00c6\u0002\u0018\u00002\u00020\u0001B\u0007\b\u0002\u00a2\u0006\u0002\u0010\u0002J\u001a\u0010\u0006\u001a\u0004\u0018\u00010\u00072\u0006\u0010\b\u001a\u00020\t2\u0006\u0010\n\u001a\u00020\u000bH\u0002J\u0016\u0010\f\u001a\u00020\u00072\u0006\u0010\r\u001a\u00020\u000b2\u0006\u0010\n\u001a\u00020\u000bR\u0016\u0010\u0003\u001a\n \u0005*\u0004\u0018\u00010\u00040\u0004X\u0082\u0004\u00a2\u0006\u0002\n\u0000\u00a8\u0006\u000e"}, d2={"Ldorkbox/executor/JvmHelper;", "", "()V", "log", "Lorg/slf4j/Logger;", "kotlin.jvm.PlatformType", "getJvmExecutable", "Ljava/io/File;", "jvmLocation", "", "isWindows", "", "getJvmPath", "isMacOS", "Executor"})
public final class JvmHelper {
    @NotNull
    public static final JvmHelper INSTANCE = new JvmHelper();
    private static final Logger log = LoggerFactory.getLogger(JvmHelper.class);

    private JvmHelper() {
    }

    private final File getJvmExecutable(String jvmLocation, boolean isWindows) {
        File jvmBase = FilesKt.resolve((File)new File(jvmLocation), (String)"bin");
        File jvmExecutable = FilesKt.resolve((File)jvmBase, (String)"java");
        if (jvmExecutable.exists()) {
            return jvmExecutable.getAbsoluteFile().getCanonicalFile();
        }
        if (isWindows && (jvmExecutable = FilesKt.resolve((File)jvmBase, (String)"java.exe")).exists()) {
            return jvmExecutable.getAbsoluteFile().getCanonicalFile();
        }
        return null;
    }

    @NotNull
    public final File getJvmPath(boolean isMacOS, boolean isWindows) {
        String[] binDir2;
        File jvmExecutable = null;
        String string2 = System.getProperty("java.home");
        Intrinsics.checkNotNullExpressionValue((Object)string2, (String)"getProperty(\"java.home\")");
        jvmExecutable = this.getJvmExecutable(string2, isWindows);
        if (isMacOS) {
            try {
                File javaParentDir;
                File file;
                binDir2 = new File("/usr/bin");
                File file2 = jvmExecutable;
                if (file2 == null) {
                    file = null;
                } else {
                    File file3 = file2.getParentFile();
                    file = javaParentDir = file3 == null ? null : file3.getCanonicalFile();
                }
                if (Intrinsics.areEqual((Object)javaParentDir, (Object)binDir2)) {
                    jvmExecutable = new File("/usr/bin/java");
                }
            }
            catch (IOException binDir2) {
                // empty catch block
            }
        }
        if (jvmExecutable == null && isWindows) {
            binDir2 = System.getProperty("java.library.path");
            Intrinsics.checkNotNullExpressionValue((Object)binDir2, (String)"getProperty(\"java.library.path\")");
            CharSequence charSequence = (CharSequence)binDir2;
            binDir2 = new String[]{";"};
            Iterable $this$forEach$iv = StringsKt.split$default((CharSequence)charSequence, (String[])binDir2, (boolean)false, (int)0, (int)6, null);
            boolean $i$f$forEach = false;
            for (Object element$iv : $this$forEach$iv) {
                String it = (String)element$iv;
                boolean bl = false;
                File path = FilesKt.resolve((File)new File(it), (String)"java.exe");
                if (!path.exists()) continue;
                jvmExecutable = path;
            }
        }
        if (jvmExecutable == null) {
            jvmExecutable = isWindows ? new File("java.exe") : new File("java");
            log.error("Unable to find JVM executable [java.home=" + System.getProperty("java.home") + "]! Using '" + jvmExecutable + "' as the default");
        }
        return jvmExecutable;
    }
}

