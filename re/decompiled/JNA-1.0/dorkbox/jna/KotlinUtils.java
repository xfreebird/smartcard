/*
 * Decompiled with CFR 0.152.
 * 
 * Could not load the following classes:
 *  kotlin.Metadata
 *  kotlin.collections.ArraysKt
 *  kotlin.io.FilesKt
 *  kotlin.io.TextStreamsKt
 *  kotlin.jvm.internal.Intrinsics
 *  kotlin.text.Charsets
 *  kotlin.text.StringsKt
 *  org.jetbrains.annotations.NotNull
 *  org.jetbrains.annotations.Nullable
 */
package dorkbox.jna;

import java.io.BufferedReader;
import java.io.File;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.io.Reader;
import java.nio.charset.Charset;
import java.util.List;
import java.util.concurrent.TimeUnit;
import kotlin.Metadata;
import kotlin.collections.ArraysKt;
import kotlin.io.FilesKt;
import kotlin.io.TextStreamsKt;
import kotlin.jvm.internal.Intrinsics;
import kotlin.text.Charsets;
import kotlin.text.StringsKt;
import org.jetbrains.annotations.NotNull;
import org.jetbrains.annotations.Nullable;

@Metadata(mv={1, 7, 1}, k=1, xi=48, d1={"\u0000.\n\u0002\u0018\u0002\n\u0002\u0010\u0000\n\u0002\b\u0002\n\u0002\u0010\u000e\n\u0000\n\u0002\u0010\u0011\n\u0002\b\u0002\n\u0002\u0010 \n\u0000\n\u0002\u0018\u0002\n\u0000\n\u0002\u0010\b\n\u0002\b\u0003\b\u00c0\u0002\u0018\u00002\u00020\u0001B\u0007\b\u0002\u00a2\u0006\u0002\u0010\u0002J\u001f\u0010\u0003\u001a\u00020\u00042\u0012\u0010\u0005\u001a\n\u0012\u0006\b\u0001\u0012\u00020\u00040\u0006\"\u00020\u0004\u00a2\u0006\u0002\u0010\u0007J\u0014\u0010\b\u001a\b\u0012\u0004\u0012\u00020\u00040\t2\u0006\u0010\n\u001a\u00020\u000bJ\u0017\u0010\f\u001a\u0004\u0018\u00010\r2\b\u0010\u000e\u001a\u0004\u0018\u00010\u0004\u00a2\u0006\u0002\u0010\u000f\u00a8\u0006\u0010"}, d2={"Ldorkbox/jna/KotlinUtils;", "", "()V", "execute", "", "args", "", "([Ljava/lang/String;)Ljava/lang/String;", "readLines", "", "file", "Ljava/io/File;", "toInteger", "", "string", "(Ljava/lang/String;)Ljava/lang/Integer;", "JNA"})
public final class KotlinUtils {
    @NotNull
    public static final KotlinUtils INSTANCE = new KotlinUtils();

    private KotlinUtils() {
    }

    @NotNull
    public final List<String> readLines(@NotNull File file) {
        Intrinsics.checkNotNullParameter((Object)file, (String)"file");
        return FilesKt.readLines$default((File)file, null, (int)1, null);
    }

    @Nullable
    public final Integer toInteger(@Nullable String string) {
        String string2 = string;
        return string2 != null ? StringsKt.toIntOrNull((String)string2) : null;
    }

    @NotNull
    public final String execute(String ... args) {
        Intrinsics.checkNotNullParameter((Object)args, (String)"args");
        Object object = new ProcessBuilder(ArraysKt.toList((Object[])args)).redirectOutput(ProcessBuilder.Redirect.PIPE).redirectError(ProcessBuilder.Redirect.PIPE).start();
        Process $this$execute_u24lambda_u240 = object;
        boolean bl = false;
        $this$execute_u24lambda_u240.waitFor(60L, TimeUnit.SECONDS);
        InputStream inputStream = ((Process)object).getInputStream();
        Intrinsics.checkNotNullExpressionValue((Object)inputStream, (String)"ProcessBuilder(args.toLi\u2026\n            .inputStream");
        InputStream inputStream2 = inputStream;
        object = Charsets.UTF_8;
        Reader reader = new InputStreamReader(inputStream2, (Charset)object);
        int n = 8192;
        return ((Object)StringsKt.trim((CharSequence)TextStreamsKt.readText((Reader)(reader instanceof BufferedReader ? (BufferedReader)reader : new BufferedReader(reader, n))))).toString();
    }
}

