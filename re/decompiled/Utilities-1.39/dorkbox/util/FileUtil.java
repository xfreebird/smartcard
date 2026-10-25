/*
 * Decompiled with CFR 0.152.
 * 
 * Could not load the following classes:
 *  dorkbox.os.OS
 *  kotlin.Metadata
 *  kotlin.Unit
 *  kotlin.io.ByteStreamsKt
 *  kotlin.io.CloseableKt
 *  kotlin.io.FilesKt
 *  kotlin.io.TextStreamsKt
 *  kotlin.jvm.JvmStatic
 *  kotlin.jvm.functions.Function1
 *  kotlin.jvm.internal.Intrinsics
 *  kotlin.sequences.Sequence
 *  kotlin.sequences.SequencesKt
 *  kotlin.text.Charsets
 *  kotlin.text.StringsKt
 *  org.jetbrains.annotations.NotNull
 *  org.jetbrains.annotations.Nullable
 *  org.slf4j.Logger
 *  org.slf4j.LoggerFactory
 */
package dorkbox.util;

import dorkbox.os.OS;
import java.io.BufferedInputStream;
import java.io.BufferedReader;
import java.io.BufferedWriter;
import java.io.Closeable;
import java.io.File;
import java.io.FileInputStream;
import java.io.FileNotFoundException;
import java.io.FileOutputStream;
import java.io.FileReader;
import java.io.FileWriter;
import java.io.IOException;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.io.OutputStream;
import java.io.PrintWriter;
import java.io.RandomAccessFile;
import java.io.Reader;
import java.nio.charset.Charset;
import java.nio.file.DirectoryIteratorException;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.Collection;
import java.util.LinkedList;
import java.util.List;
import java.util.zip.ZipEntry;
import java.util.zip.ZipInputStream;
import kotlin.Metadata;
import kotlin.Unit;
import kotlin.io.ByteStreamsKt;
import kotlin.io.CloseableKt;
import kotlin.io.FilesKt;
import kotlin.io.TextStreamsKt;
import kotlin.jvm.JvmStatic;
import kotlin.jvm.functions.Function1;
import kotlin.jvm.internal.Intrinsics;
import kotlin.sequences.Sequence;
import kotlin.sequences.SequencesKt;
import kotlin.text.Charsets;
import kotlin.text.StringsKt;
import org.jetbrains.annotations.NotNull;
import org.jetbrains.annotations.Nullable;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

@Metadata(mv={1, 7, 1}, k=1, xi=48, d1={"\u0000\u0094\u0001\n\u0002\u0018\u0002\n\u0002\u0010\u0000\n\u0002\b\u0002\n\u0002\u0010\u000b\n\u0000\n\u0002\u0010\f\n\u0002\b\u0004\n\u0002\u0010\u0012\n\u0002\b\u0005\n\u0002\u0018\u0002\n\u0000\n\u0002\u0010\u000e\n\u0002\b\u0003\n\u0002\u0010\u0002\n\u0000\n\u0002\u0018\u0002\n\u0000\n\u0002\u0010\u0011\n\u0000\n\u0002\u0010 \n\u0002\b%\n\u0002\u0010\b\n\u0002\b\u0004\n\u0002\u0018\u0002\n\u0002\b\u0010\n\u0002\u0018\u0002\n\u0002\b\u0002\n\u0002\u0018\u0002\n\u0002\u0018\u0002\n\u0002\b\u0005\n\u0002\u0018\u0002\n\u0000\n\u0002\u0018\u0002\n\u0002\b\u0002\n\u0002\u0010!\n\u0002\b\b\n\u0002\u0010\t\n\u0002\b\u0005\n\u0002\u0018\u0002\n\u0002\b\u0005\b\u00c6\u0002\u0018\u00002\u00020\u0001:\u0001{B\u0007\b\u0002\u00a2\u0006\u0002\u0010\u0002J'\u0010\u0016\u001a\u00020\u00172\u0006\u0010\u0018\u001a\u00020\u00192\u0012\u0010\u001a\u001a\n\u0012\u0006\b\u0001\u0012\u00020\u00130\u001b\"\u00020\u0013\u00a2\u0006\u0002\u0010\u001cJ\u001c\u0010\u0016\u001a\u00020\u00172\u0006\u0010\u0018\u001a\u00020\u00192\f\u0010\u001a\u001a\b\u0012\u0004\u0012\u00020\u00130\u001dJ\u0016\u0010\u001e\u001a\u00020\u00192\u0006\u0010\u001f\u001a\u00020\u00192\u0006\u0010 \u001a\u00020\u0019J/\u0010!\u001a\u00020\u00172\u0006\u0010\"\u001a\u00020\u00192\u0006\u0010#\u001a\u00020\u00192\u0012\u0010$\u001a\n\u0012\u0006\b\u0001\u0012\u00020\u00130\u001b\"\u00020\u0013\u00a2\u0006\u0002\u0010%J/\u0010!\u001a\u00020\u00172\u0006\u0010&\u001a\u00020\u00132\u0006\u0010'\u001a\u00020\u00132\u0012\u0010$\u001a\n\u0012\u0006\b\u0001\u0012\u00020\u00130\u001b\"\u00020\u0013\u00a2\u0006\u0002\u0010(J\u0018\u0010)\u001a\u00020\u00192\u0006\u0010*\u001a\u00020\u00192\u0006\u0010+\u001a\u00020\u0019H\u0007J\u0016\u0010)\u001a\u00020\u00192\u0006\u0010*\u001a\u00020\u00192\u0006\u0010+\u001a\u00020\u0013J\u0016\u0010)\u001a\u00020\u00192\u0006\u0010*\u001a\u00020\u00132\u0006\u0010+\u001a\u00020\u0019J\u0016\u0010)\u001a\u00020\u00192\u0006\u0010*\u001a\u00020\u00132\u0006\u0010+\u001a\u00020\u0013J\u0016\u0010,\u001a\u00020\u00192\u0006\u0010*\u001a\u00020\u00192\u0006\u0010+\u001a\u00020\u0019J\u0016\u0010,\u001a\u00020\u00192\u0006\u0010*\u001a\u00020\u00132\u0006\u0010+\u001a\u00020\u0013J)\u0010-\u001a\u00020\u00042\u0006\u0010\u0018\u001a\u00020\u00192\u0012\u0010$\u001a\n\u0012\u0006\b\u0001\u0012\u00020\u00130\u001b\"\u00020\u0013H\u0007\u00a2\u0006\u0002\u0010.J'\u0010-\u001a\u00020\u00042\u0006\u0010/\u001a\u00020\u00132\u0012\u00100\u001a\n\u0012\u0006\b\u0001\u0012\u00020\u00130\u001b\"\u00020\u0013\u00a2\u0006\u0002\u00101J\u000e\u00102\u001a\u00020\u00042\u0006\u00103\u001a\u00020\u0019J\"\u00104\u001a\u0004\u0018\u00010\u00132\u0006\u00105\u001a\u00020\u00132\u0006\u00106\u001a\u00020\u00062\u0006\u00107\u001a\u00020\u0004H\u0002J\u0018\u00108\u001a\u0004\u0018\u00010\u00132\u0006\u00109\u001a\u00020\u00132\u0006\u0010:\u001a\u00020\u0013J\u0018\u0010;\u001a\u0004\u0018\u00010\u00132\u0006\u0010\u0018\u001a\u00020\u00192\u0006\u0010<\u001a\u00020\u0013J\u0018\u0010;\u001a\u0004\u0018\u00010\u00132\u0006\u0010/\u001a\u00020\u00132\u0006\u0010<\u001a\u00020\u0013J\u000e\u0010=\u001a\u00020\u00132\u0006\u0010/\u001a\u00020\u0013J\u000e\u0010>\u001a\u00020\u00132\u0006\u0010/\u001a\u00020\u0013J\u0018\u0010?\u001a\u0004\u0018\u00010\u00132\u0006\u0010\u0018\u001a\u00020\u00192\u0006\u0010<\u001a\u00020\u0013J\u0018\u0010?\u001a\u0004\u0018\u00010\u00132\u0006\u0010/\u001a\u00020\u00132\u0006\u0010<\u001a\u00020\u0013J\u0010\u0010@\u001a\u0004\u0018\u00010\u00132\u0006\u0010A\u001a\u00020\u0013J\u000e\u0010B\u001a\u00020C2\u0006\u00105\u001a\u00020\u0013J\u0010\u0010D\u001a\u00020\u00042\u0006\u0010E\u001a\u00020\u0006H\u0002J\u000e\u0010F\u001a\u00020\u00042\u0006\u0010\u0018\u001a\u00020\u0019J\u000e\u0010F\u001a\u00020\u00042\u0006\u0010/\u001a\u00020\u0013J\u000e\u0010G\u001a\u00020\u00042\u0006\u0010*\u001a\u00020HJ\u000e\u0010I\u001a\u00020\u00132\u0006\u0010J\u001a\u00020\u0019J\u000e\u0010I\u001a\u00020\u00132\u0006\u0010J\u001a\u00020\u0013J/\u0010K\u001a\u00020\u00172\u0006\u0010&\u001a\u00020\u00192\u0006\u0010'\u001a\u00020\u00192\u0012\u00100\u001a\n\u0012\u0006\b\u0001\u0012\u00020\u00130\u001b\"\u00020\u0013\u00a2\u0006\u0002\u0010%J/\u0010K\u001a\u00020\u00172\u0006\u0010&\u001a\u00020\u00132\u0006\u0010'\u001a\u00020\u00132\u0012\u00100\u001a\n\u0012\u0006\b\u0001\u0012\u00020\u00130\u001b\"\u00020\u0013\u00a2\u0006\u0002\u0010(J\u0016\u0010L\u001a\u00020\u00192\u0006\u0010*\u001a\u00020\u00192\u0006\u0010+\u001a\u00020\u0019J\u0016\u0010L\u001a\u00020\u00192\u0006\u0010*\u001a\u00020\u00192\u0006\u0010+\u001a\u00020\u0013J\u0016\u0010L\u001a\u00020\u00192\u0006\u0010*\u001a\u00020\u00132\u0006\u0010+\u001a\u00020\u0019J\u0016\u0010L\u001a\u00020\u00192\u0006\u0010*\u001a\u00020\u00132\u0006\u0010+\u001a\u00020\u0013J\u0010\u0010M\u001a\u0004\u0018\u00010\u00192\u0006\u0010\u0018\u001a\u00020\u0019J\u0010\u0010M\u001a\u0004\u0018\u00010\u00192\u0006\u00105\u001a\u00020\u0013J\u0018\u0010M\u001a\u0004\u0018\u00010\u00132\u0006\u00105\u001a\u00020\u00132\u0006\u0010N\u001a\u00020\u0004J\u0010\u0010O\u001a\u0004\u0018\u00010\u00132\u0006\u00105\u001a\u00020\u0013J\u0018\u0010O\u001a\u0004\u0018\u00010\u00132\u0006\u00105\u001a\u00020\u00132\u0006\u0010N\u001a\u00020\u0004J\u0010\u0010P\u001a\u0004\u0018\u00010\u00132\u0006\u00105\u001a\u00020\u0013J\u0014\u0010Q\u001a\b\u0012\u0004\u0012\u00020\u00190\u001d2\u0006\u0010R\u001a\u00020\u0019J-\u0010Q\u001a\b\u0012\u0004\u0012\u00020\u00190\u001d2\u0006\u0010R\u001a\u00020\u00192\u0012\u0010S\u001a\n\u0012\u0006\b\u0001\u0012\u00020\u00130\u001b\"\u00020\u0013\u00a2\u0006\u0002\u0010TJ\u0014\u0010Q\u001a\b\u0012\u0004\u0012\u00020\u00190\u001d2\u0006\u0010R\u001a\u00020\u0013J'\u0010U\u001a\u00020\u00172\u0006\u0010\u0018\u001a\u00020\u00192\u0012\u0010V\u001a\n\u0012\u0006\b\u0001\u0012\u00020\u00130\u001b\"\u00020\u0013\u00a2\u0006\u0002\u0010\u001cJ\u0010\u0010W\u001a\u0004\u0018\u00010\u00132\u0006\u0010\u0018\u001a\u00020\u0019J\u0016\u0010W\u001a\u00020\u00042\u0006\u0010\u0018\u001a\u00020\u00192\u0006\u0010X\u001a\u00020YJ\u001c\u0010W\u001a\b\u0012\u0004\u0012\u00020\u00130\u001d2\u0006\u0010\u0018\u001a\u00020\u00192\u0006\u0010Z\u001a\u00020\u0004J\u001a\u0010W\u001a\u00020\u00172\u0006\u0010\u0018\u001a\u00020\u00192\n\u0010[\u001a\u00060\\j\u0002`]J$\u0010W\u001a\u00020\u00042\u0006\u0010\u0018\u001a\u00020\u00192\n\u0010^\u001a\u00060\\j\u0002`]2\b\u0010_\u001a\u0004\u0018\u00010\u0013J\u0010\u0010W\u001a\u0004\u0018\u00010\u00132\u0006\u0010\u0018\u001a\u00020\u0013J\u000e\u0010`\u001a\u00020\u00132\u0006\u0010\u0018\u001a\u00020\u0019J\u000e\u0010a\u001a\u00020\u00132\u0006\u0010\u0018\u001a\u00020\u0019J\u0014\u0010b\u001a\b\u0012\u0004\u0012\u00020\u00130\u001d2\u0006\u0010\u0018\u001a\u00020\u0019J\u0014\u0010b\u001a\b\u0012\u0004\u0012\u00020\u00130\u001d2\u0006\u0010*\u001a\u00020cJ\u0014\u0010d\u001a\b\u0012\u0004\u0012\u00020\u00130e2\u0006\u0010\u0018\u001a\u00020\u0019J\u001c\u0010d\u001a\b\u0012\u0004\u0012\u00020\u00130e2\u0006\u0010\u0018\u001a\u00020\u00192\u0006\u0010f\u001a\u00020\u0004J$\u0010d\u001a\u00020\u00172\u0006\u0010\u0018\u001a\u00020\u00192\f\u0010g\u001a\b\u0012\u0004\u0012\u00020\u00130h2\u0006\u0010f\u001a\u00020\u0004J\u0016\u0010i\u001a\u00020\u00042\u0006\u0010j\u001a\u00020\u00192\u0006\u0010'\u001a\u00020\u0019J\u000e\u0010k\u001a\u00020\u00132\u0006\u0010l\u001a\u00020\u0013J\u000e\u0010m\u001a\u00020\u00192\u0006\u0010/\u001a\u00020\u0013J\u0010\u0010n\u001a\u0004\u0018\u00010\u000b2\u0006\u0010\u0018\u001a\u00020\u0019J\u000e\u0010o\u001a\u00020\u00042\u0006\u0010\u0018\u001a\u00020\u0019J\u0016\u0010o\u001a\u00020\u00042\u0006\u0010\u0018\u001a\u00020\u00192\u0006\u0010p\u001a\u00020qJ\u000e\u0010o\u001a\u00020\u00042\u0006\u0010\u0018\u001a\u00020\u0013J \u0010r\u001a\u00020\u00172\u0006\u00109\u001a\u00020\u00192\u0006\u0010s\u001a\u00020\u00192\u0006\u0010t\u001a\u00020\u0004H\u0002J \u0010u\u001a\u00020\u00172\u0006\u0010v\u001a\u00020w2\u0006\u0010s\u001a\u00020\u00192\u0006\u0010t\u001a\u00020\u0004H\u0002J\u0016\u0010x\u001a\u00020\u00172\u0006\u00109\u001a\u00020\u00192\u0006\u0010s\u001a\u00020\u0019J\u0016\u0010x\u001a\u00020\u00172\u0006\u0010v\u001a\u00020w2\u0006\u0010s\u001a\u00020\u0019J\u0016\u0010x\u001a\u00020\u00172\u0006\u0010v\u001a\u00020w2\u0006\u0010s\u001a\u00020\u0013J\u0016\u0010x\u001a\u00020\u00172\u0006\u00109\u001a\u00020\u00132\u0006\u0010s\u001a\u00020\u0013J\u001e\u0010y\u001a\u00020\u00172\u0006\u00109\u001a\u00020\u00192\u0006\u0010s\u001a\u00020\u00192\u0006\u0010t\u001a\u00020\u0004J\u001e\u0010y\u001a\u00020\u00172\u0006\u0010v\u001a\u00020w2\u0006\u0010s\u001a\u00020\u00192\u0006\u0010t\u001a\u00020\u0004J\u001e\u0010y\u001a\u00020\u00172\u0006\u00109\u001a\u00020\u00132\u0006\u0010s\u001a\u00020\u00132\u0006\u0010t\u001a\u00020\u0004J'\u0010z\u001a\u00020\u00172\u0006\u0010\u0018\u001a\u00020\u00192\u0012\u0010\u001a\u001a\n\u0012\u0006\b\u0001\u0012\u00020\u00130\u001b\"\u00020\u0013\u00a2\u0006\u0002\u0010\u001cJ\u001c\u0010z\u001a\u00020\u00172\u0006\u0010\u0018\u001a\u00020\u00192\f\u0010\u001a\u001a\b\u0012\u0004\u0012\u00020\u00130\u001dR\u000e\u0010\u0003\u001a\u00020\u0004X\u0082T\u00a2\u0006\u0002\n\u0000R\u000e\u0010\u0005\u001a\u00020\u0006X\u0082\u0004\u00a2\u0006\u0002\n\u0000R\u000e\u0010\u0007\u001a\u00020\u0006X\u0082\u0004\u00a2\u0006\u0002\n\u0000R\u000e\u0010\b\u001a\u00020\u0006X\u0082T\u00a2\u0006\u0002\n\u0000R\u000e\u0010\t\u001a\u00020\u0006X\u0082T\u00a2\u0006\u0002\n\u0000R\u001a\u0010\n\u001a\u00020\u000bX\u0086\u000e\u00a2\u0006\u000e\n\u0000\u001a\u0004\b\f\u0010\r\"\u0004\b\u000e\u0010\u000fR\u000e\u0010\u0010\u001a\u00020\u0011X\u0082\u0004\u00a2\u0006\u0002\n\u0000R\u0014\u0010\u0012\u001a\u00020\u0013X\u0086D\u00a2\u0006\b\n\u0000\u001a\u0004\b\u0014\u0010\u0015\u00a8\u0006|"}, d2={"Ldorkbox/util/FileUtil;", "", "()V", "DEBUG", "", "OTHER_SEPARATOR", "", "SYSTEM_SEPARATOR", "UNIX_SEPARATOR", "WINDOWS_SEPARATOR", "ZIP_HEADER", "", "getZIP_HEADER", "()[B", "setZIP_HEADER", "([B)V", "log", "Lorg/slf4j/Logger;", "version", "", "getVersion", "()Ljava/lang/String;", "append", "", "file", "Ljava/io/File;", "text", "", "(Ljava/io/File;[Ljava/lang/String;)V", "", "concatFiles", "one", "two", "copyDirectory", "src_", "dest_", "namesToIgnore", "(Ljava/io/File;Ljava/io/File;[Ljava/lang/String;)V", "src", "dest", "(Ljava/lang/String;Ljava/lang/String;[Ljava/lang/String;)V", "copyFile", "in", "out", "copyFileToDir", "delete", "(Ljava/io/File;[Ljava/lang/String;)Z", "fileName", "fileNamesToIgnore", "(Ljava/lang/String;[Ljava/lang/String;)Z", "deleteDirectory", "dir", "doNormalize", "filename", "separator", "keepSeparator", "extractFromZip", "zipFile", "fileToExtract", "getChildRelativeToDir", "dirInHeirarchy", "getExtension", "getNameWithoutExtension", "getParentRelativeToDir", "getPid", "pidFileName", "getPrefixLength", "", "isSeparator", "ch", "isZipFile", "isZipStream", "Ljava/io/InputStream;", "mkdir", "location", "moveDirectory", "moveFile", "normalize", "unixSeparator", "normalizeNoEndSeparator", "normalizeRaw", "parseDir", "rootDirectory", "extensionsToMatch", "(Ljava/io/File;[Ljava/lang/String;)Ljava/util/List;", "prepend", "strings", "read", "action", "Ldorkbox/util/FileUtil$Action;", "includeEmptyLines", "stringBuilder", "Ljava/lang/StringBuilder;", "Lkotlin/text/StringBuilder;", "builder", "lineSeparator", "readAsString", "readFirstLine", "readLines", "Ljava/io/Reader;", "readOnePerLine", "Ljava/util/ArrayList;", "trimStrings", "list", "", "renameTo", "source", "tempDirectory", "directoryName", "tempFile", "toBytes", "touch", "timestamp", "", "unjarzip0", "outputDir", "extractManifest", "unjarzip1", "inputStream", "Ljava/util/zip/ZipInputStream;", "unzip", "unzipJar", "write", "Action", "Utilities"})
public final class FileUtil {
    @NotNull
    public static final FileUtil INSTANCE = new FileUtil();
    @NotNull
    private static final String version = "1.39";
    @NotNull
    private static final Logger log;
    private static final boolean DEBUG = false;
    private static final char UNIX_SEPARATOR = '/';
    private static final char WINDOWS_SEPARATOR = '\\';
    private static final char SYSTEM_SEPARATOR;
    private static final char OTHER_SEPARATOR;
    @NotNull
    private static byte[] ZIP_HEADER;

    private FileUtil() {
    }

    @NotNull
    public final String getVersion() {
        return version;
    }

    @NotNull
    public final byte[] getZIP_HEADER() {
        return ZIP_HEADER;
    }

    public final void setZIP_HEADER(@NotNull byte[] byArray) {
        Intrinsics.checkNotNullParameter((Object)byArray, (String)"<set-?>");
        ZIP_HEADER = byArray;
    }

    public final void prepend(@NotNull File file, String ... strings) {
        Intrinsics.checkNotNullParameter((Object)file, (String)"file");
        Intrinsics.checkNotNullParameter((Object)strings, (String)"strings");
        File file2 = file.getParentFile();
        if (file2 != null) {
            file2.mkdirs();
        }
        LinkedList<String> contents = new LinkedList<String>();
        for (String string : strings) {
            contents.add(string);
        }
        this.readOnePerLine(file, (List<String>)contents, false);
        this.write(file, (List<String>)contents);
    }

    /*
     * WARNING - Removed try catching itself - possible behaviour change.
     */
    public final void append(@NotNull File file, String ... text) {
        Intrinsics.checkNotNullParameter((Object)file, (String)"file");
        Intrinsics.checkNotNullParameter((Object)text, (String)"text");
        File file2 = file.getParentFile();
        if (file2 != null) {
            file2.mkdirs();
        }
        try {
            Closeable closeable = new FileWriter(file, true);
            Throwable throwable = null;
            try {
                FileWriter fw = (FileWriter)closeable;
                boolean bl = false;
                Closeable closeable2 = new BufferedWriter(fw);
                Throwable throwable2 = null;
                try {
                    BufferedWriter bw = (BufferedWriter)closeable2;
                    boolean bl2 = false;
                    Closeable closeable3 = new PrintWriter(bw);
                    Throwable throwable3 = null;
                    try {
                        PrintWriter out = (PrintWriter)closeable3;
                        boolean bl3 = false;
                        for (String s : text) {
                            out.println(s);
                        }
                        Unit unit = Unit.INSTANCE;
                    }
                    catch (Throwable throwable4) {
                        throwable3 = throwable4;
                        throw throwable4;
                    }
                    finally {
                        CloseableKt.closeFinally((Closeable)closeable3, (Throwable)throwable3);
                    }
                    Unit unit = Unit.INSTANCE;
                }
                catch (Throwable throwable5) {
                    throwable2 = throwable5;
                    throw throwable5;
                }
                finally {
                    CloseableKt.closeFinally((Closeable)closeable2, (Throwable)throwable2);
                }
                Unit unit = Unit.INSTANCE;
            }
            catch (Throwable throwable6) {
                throwable = throwable6;
                throw throwable6;
            }
            finally {
                CloseableKt.closeFinally((Closeable)closeable, (Throwable)throwable);
            }
        }
        catch (IOException e) {
            log.error("Error appending text", (Throwable)e);
        }
    }

    /*
     * WARNING - Removed try catching itself - possible behaviour change.
     */
    public final void write(@NotNull File file, String ... text) {
        Intrinsics.checkNotNullParameter((Object)file, (String)"file");
        Intrinsics.checkNotNullParameter((Object)text, (String)"text");
        File file2 = file.getParentFile();
        if (file2 != null) {
            file2.mkdirs();
        }
        try {
            Closeable closeable = new FileWriter(file, false);
            Throwable throwable = null;
            try {
                FileWriter fw = (FileWriter)closeable;
                boolean bl = false;
                Closeable closeable2 = new BufferedWriter(fw);
                Throwable throwable2 = null;
                try {
                    BufferedWriter bw = (BufferedWriter)closeable2;
                    boolean bl2 = false;
                    Closeable closeable3 = new PrintWriter(bw);
                    Throwable throwable3 = null;
                    try {
                        PrintWriter out = (PrintWriter)closeable3;
                        boolean bl3 = false;
                        for (String s : text) {
                            out.println(s);
                        }
                        Unit unit = Unit.INSTANCE;
                    }
                    catch (Throwable throwable4) {
                        throwable3 = throwable4;
                        throw throwable4;
                    }
                    finally {
                        CloseableKt.closeFinally((Closeable)closeable3, (Throwable)throwable3);
                    }
                    Unit unit = Unit.INSTANCE;
                }
                catch (Throwable throwable5) {
                    throwable2 = throwable5;
                    throw throwable5;
                }
                finally {
                    CloseableKt.closeFinally((Closeable)closeable2, (Throwable)throwable2);
                }
                Unit unit = Unit.INSTANCE;
            }
            catch (Throwable throwable6) {
                throwable = throwable6;
                throw throwable6;
            }
            finally {
                CloseableKt.closeFinally((Closeable)closeable, (Throwable)throwable);
            }
        }
        catch (IOException e) {
            log.error("Error appending text", (Throwable)e);
        }
    }

    /*
     * WARNING - Removed try catching itself - possible behaviour change.
     */
    public final void write(@NotNull File file, @NotNull List<String> text) {
        Intrinsics.checkNotNullParameter((Object)file, (String)"file");
        Intrinsics.checkNotNullParameter(text, (String)"text");
        File file2 = file.getParentFile();
        if (file2 != null) {
            file2.mkdirs();
        }
        try {
            Closeable closeable = new FileWriter(file, false);
            Throwable throwable = null;
            try {
                FileWriter fw = (FileWriter)closeable;
                boolean bl = false;
                Closeable closeable2 = new BufferedWriter(fw);
                Throwable throwable2 = null;
                try {
                    BufferedWriter bw = (BufferedWriter)closeable2;
                    boolean bl2 = false;
                    Closeable closeable3 = new PrintWriter(bw);
                    Throwable throwable3 = null;
                    try {
                        PrintWriter out = (PrintWriter)closeable3;
                        boolean bl3 = false;
                        for (String s : text) {
                            out.println(s);
                        }
                        Unit unit = Unit.INSTANCE;
                    }
                    catch (Throwable throwable4) {
                        throwable3 = throwable4;
                        throw throwable4;
                    }
                    finally {
                        CloseableKt.closeFinally((Closeable)closeable3, (Throwable)throwable3);
                    }
                    Unit unit = Unit.INSTANCE;
                }
                catch (Throwable throwable5) {
                    throwable2 = throwable5;
                    throw throwable5;
                }
                finally {
                    CloseableKt.closeFinally((Closeable)closeable2, (Throwable)throwable2);
                }
                Unit unit = Unit.INSTANCE;
            }
            catch (Throwable throwable6) {
                throwable = throwable6;
                throw throwable6;
            }
            finally {
                CloseableKt.closeFinally((Closeable)closeable, (Throwable)throwable);
            }
        }
        catch (IOException e) {
            log.error("Error appending text", (Throwable)e);
        }
    }

    /*
     * WARNING - Removed try catching itself - possible behaviour change.
     */
    public final void append(@NotNull File file, @NotNull List<String> text) {
        Intrinsics.checkNotNullParameter((Object)file, (String)"file");
        Intrinsics.checkNotNullParameter(text, (String)"text");
        File file2 = file.getParentFile();
        if (file2 != null) {
            file2.mkdirs();
        }
        try {
            Closeable closeable = new FileWriter(file, true);
            Throwable throwable = null;
            try {
                FileWriter fw = (FileWriter)closeable;
                boolean bl = false;
                Closeable closeable2 = new BufferedWriter(fw);
                Throwable throwable2 = null;
                try {
                    BufferedWriter bw = (BufferedWriter)closeable2;
                    boolean bl2 = false;
                    Closeable closeable3 = new PrintWriter(bw);
                    Throwable throwable3 = null;
                    try {
                        PrintWriter out = (PrintWriter)closeable3;
                        boolean bl3 = false;
                        for (String s : text) {
                            out.println(s);
                        }
                        Unit unit = Unit.INSTANCE;
                    }
                    catch (Throwable throwable4) {
                        throwable3 = throwable4;
                        throw throwable4;
                    }
                    finally {
                        CloseableKt.closeFinally((Closeable)closeable3, (Throwable)throwable3);
                    }
                    Unit unit = Unit.INSTANCE;
                }
                catch (Throwable throwable5) {
                    throwable2 = throwable5;
                    throw throwable5;
                }
                finally {
                    CloseableKt.closeFinally((Closeable)closeable2, (Throwable)throwable2);
                }
                Unit unit = Unit.INSTANCE;
            }
            catch (Throwable throwable6) {
                throwable = throwable6;
                throw throwable6;
            }
            finally {
                CloseableKt.closeFinally((Closeable)closeable, (Throwable)throwable);
            }
        }
        catch (IOException e) {
            log.error("Error appending text", (Throwable)e);
        }
    }

    /*
     * WARNING - Removed try catching itself - possible behaviour change.
     */
    @NotNull
    public final List<String> read(@NotNull File file, boolean includeEmptyLines) throws IOException {
        Intrinsics.checkNotNullParameter((Object)file, (String)"file");
        List lines = new ArrayList();
        if (includeEmptyLines) {
            Object object = file;
            Object object2 = Charsets.UTF_8;
            object = new InputStreamReader((InputStream)new FileInputStream((File)object), (Charset)object2);
            object2 = null;
            try {
                InputStreamReader it = (InputStreamReader)object;
                boolean bl = false;
                TextStreamsKt.forEachLine((Reader)it, (Function1)((Function1)new Function1<String, Unit>((List<String>)lines){
                    final /* synthetic */ List<String> $lines;
                    {
                        this.$lines = $lines;
                        super(1);
                    }

                    public final void invoke(@NotNull String line) {
                        Intrinsics.checkNotNullParameter((Object)line, (String)"line");
                        this.$lines.add(line);
                    }
                }));
                it = Unit.INSTANCE;
            }
            catch (Throwable it) {
                object2 = it;
                throw it;
            }
            finally {
                CloseableKt.closeFinally((Closeable)object, (Throwable)object2);
            }
        }
        Object object = file;
        Object object3 = Charsets.UTF_8;
        object = new InputStreamReader((InputStream)new FileInputStream((File)object), (Charset)object3);
        object3 = null;
        try {
            InputStreamReader it = (InputStreamReader)object;
            boolean bl = false;
            TextStreamsKt.forEachLine((Reader)it, (Function1)((Function1)new Function1<String, Unit>((List<String>)lines){
                final /* synthetic */ List<String> $lines;
                {
                    this.$lines = $lines;
                    super(1);
                }

                public final void invoke(@NotNull String line) {
                    Intrinsics.checkNotNullParameter((Object)line, (String)"line");
                    if (((CharSequence)line).length() > 0) {
                        this.$lines.add(line);
                    }
                }
            }));
            Unit unit = Unit.INSTANCE;
        }
        catch (Throwable throwable) {
            object3 = throwable;
            throw throwable;
        }
        finally {
            CloseableKt.closeFinally((Closeable)object, (Throwable)object3);
        }
        return lines;
    }

    @NotNull
    public final String readAsString(@NotNull File file) throws IOException {
        Intrinsics.checkNotNullParameter((Object)file, (String)"file");
        return FilesKt.readText$default((File)file, null, (int)1, null);
    }

    @Nullable
    public final String read(@NotNull String file) {
        Intrinsics.checkNotNullParameter((Object)file, (String)"file");
        return this.read(new File(file));
    }

    @Nullable
    public final String read(@NotNull File file) {
        Intrinsics.checkNotNullParameter((Object)file, (String)"file");
        String text = FilesKt.readText$default((File)file, null, (int)1, null);
        if (((CharSequence)text).length() == 0) {
            return null;
        }
        return text;
    }

    /*
     * WARNING - Removed try catching itself - possible behaviour change.
     */
    public final void read(@NotNull File file, @NotNull StringBuilder stringBuilder) throws IOException {
        Intrinsics.checkNotNullParameter((Object)file, (String)"file");
        Intrinsics.checkNotNullParameter((Object)stringBuilder, (String)"stringBuilder");
        Closeable closeable = new FileReader(file);
        Throwable throwable = null;
        try {
            FileReader it = (FileReader)closeable;
            boolean bl = false;
            BufferedReader bin = new BufferedReader(it);
            String line = null;
            while (true) {
                String string;
                String it2 = string = bin.readLine();
                boolean bl2 = false;
                line = it2;
                if (string == null) break;
                stringBuilder.append(line).append(OS.INSTANCE.getLINE_SEPARATOR());
            }
            Unit unit = Unit.INSTANCE;
        }
        catch (Throwable throwable2) {
            throwable = throwable2;
            throw throwable2;
        }
        finally {
            CloseableKt.closeFinally((Closeable)closeable, (Throwable)throwable);
        }
    }

    /*
     * WARNING - Removed try catching itself - possible behaviour change.
     */
    public final boolean read(@NotNull File file, @NotNull StringBuilder builder, @Nullable String lineSeparator) {
        Intrinsics.checkNotNullParameter((Object)file, (String)"file");
        Intrinsics.checkNotNullParameter((Object)builder, (String)"builder");
        if (!file.canRead()) {
            return false;
        }
        try {
            Object object = file;
            Object object2 = Charsets.UTF_8;
            object = new InputStreamReader((InputStream)new FileInputStream((File)object), (Charset)object2);
            object2 = null;
            try {
                InputStreamReader reader = (InputStreamReader)object;
                boolean bl = false;
                TextStreamsKt.forEachLine((Reader)reader, (Function1)((Function1)new Function1<String, Unit>(lineSeparator, builder){
                    final /* synthetic */ String $lineSeparator;
                    final /* synthetic */ StringBuilder $builder;
                    {
                        this.$lineSeparator = $lineSeparator;
                        this.$builder = $builder;
                        super(1);
                    }

                    public final void invoke(@NotNull String line) {
                        Intrinsics.checkNotNullParameter((Object)line, (String)"line");
                        if (this.$lineSeparator != null) {
                            this.$builder.append(line).append(this.$lineSeparator);
                        } else {
                            this.$builder.append(line);
                        }
                    }
                }));
                Unit unit = Unit.INSTANCE;
            }
            catch (Throwable throwable) {
                object2 = throwable;
                throw throwable;
            }
            finally {
                CloseableKt.closeFinally((Closeable)object, (Throwable)object2);
            }
        }
        catch (Exception ignored) {
            return false;
        }
        return true;
    }

    /*
     * WARNING - Removed try catching itself - possible behaviour change.
     */
    public final boolean read(@NotNull File file, @NotNull Action action) {
        Intrinsics.checkNotNullParameter((Object)file, (String)"file");
        Intrinsics.checkNotNullParameter((Object)action, (String)"action");
        if (!file.canRead()) {
            return false;
        }
        try {
            Object object = file;
            Object object2 = Charsets.UTF_8;
            object = new InputStreamReader((InputStream)new FileInputStream((File)object), (Charset)object2);
            object2 = null;
            try {
                InputStreamReader reader = (InputStreamReader)object;
                boolean bl = false;
                TextStreamsKt.forEachLine((Reader)reader, (Function1)((Function1)new Function1<String, Unit>(action){
                    final /* synthetic */ Action $action;
                    {
                        this.$action = $action;
                        super(1);
                    }

                    public final void invoke(@NotNull String line) {
                        Intrinsics.checkNotNullParameter((Object)line, (String)"line");
                        this.$action.onLineRead(line);
                    }
                }));
                Unit unit = Unit.INSTANCE;
            }
            catch (Throwable throwable) {
                object2 = throwable;
                throw throwable;
            }
            finally {
                CloseableKt.closeFinally((Closeable)object, (Throwable)object2);
            }
        }
        catch (Exception ignored) {
            return false;
        }
        action.finished();
        return true;
    }

    /*
     * WARNING - Removed try catching itself - possible behaviour change.
     */
    @NotNull
    public final String readFirstLine(@NotNull File file) {
        String string;
        Intrinsics.checkNotNullParameter((Object)file, (String)"file");
        if (!file.canRead()) {
            return "";
        }
        Object object = file;
        Object object2 = Charsets.UTF_8;
        object = new InputStreamReader((InputStream)new FileInputStream((File)object), (Charset)object2);
        object2 = null;
        try {
            InputStreamReader reader = (InputStreamReader)object;
            boolean bl = false;
            Reader reader2 = reader;
            int n = 8192;
            String string2 = (String)SequencesKt.firstOrNull((Sequence)TextStreamsKt.lineSequence((BufferedReader)(reader2 instanceof BufferedReader ? (BufferedReader)reader2 : new BufferedReader(reader2, n))));
            string = string2;
        }
        catch (Throwable throwable) {
            object2 = throwable;
            throw throwable;
        }
        finally {
            CloseableKt.closeFinally((Closeable)object, (Throwable)object2);
        }
        String string3 = string;
        if (string == null) {
            string3 = "";
        }
        return string3;
    }

    @Nullable
    public final String getPid(@NotNull String pidFileName) {
        Intrinsics.checkNotNullParameter((Object)pidFileName, (String)"pidFileName");
        StringBuilder stringBuilder = new StringBuilder();
        return this.read(new File(pidFileName), stringBuilder, null) ? stringBuilder.toString() : (String)null;
    }

    @NotNull
    public final List<String> readLines(@NotNull File file) {
        FileReader fileReader;
        Intrinsics.checkNotNullParameter((Object)file, (String)"file");
        try {
            fileReader = new FileReader(file);
        }
        catch (FileNotFoundException ignored) {
            return new ArrayList();
        }
        FileReader fileReader2 = fileReader;
        return this.readLines(fileReader2);
    }

    /*
     * WARNING - Removed try catching itself - possible behaviour change.
     */
    @NotNull
    public final List<String> readLines(@NotNull Reader in) {
        Intrinsics.checkNotNullParameter((Object)in, (String)"in");
        List lines = new ArrayList();
        Closeable closeable = new BufferedReader(in);
        Throwable throwable = null;
        try {
            BufferedReader it = (BufferedReader)closeable;
            boolean bl = false;
            BufferedReader bin = new BufferedReader(in);
            String line = null;
            try {
                while (true) {
                    String string;
                    String it2 = string = bin.readLine();
                    boolean bl2 = false;
                    Intrinsics.checkNotNullExpressionValue((Object)it2, (String)"it");
                    line = it2;
                    if (string != null) {
                        lines.add(line);
                        continue;
                    }
                    break;
                }
            }
            catch (IOException iOException) {
            }
            Unit unit = Unit.INSTANCE;
        }
        catch (Throwable throwable2) {
            throwable = throwable2;
            throw throwable2;
        }
        finally {
            CloseableKt.closeFinally((Closeable)closeable, (Throwable)throwable);
        }
        return lines;
    }

    @NotNull
    public final ArrayList<String> readOnePerLine(@NotNull File file) {
        Intrinsics.checkNotNullParameter((Object)file, (String)"file");
        ArrayList<String> list = new ArrayList<String>();
        this.readOnePerLine(file, (List<String>)list, true);
        return list;
    }

    @NotNull
    public final ArrayList<String> readOnePerLine(@NotNull File file, boolean trimStrings) {
        Intrinsics.checkNotNullParameter((Object)file, (String)"file");
        ArrayList<String> list = new ArrayList<String>();
        this.readOnePerLine(file, (List<String>)list, trimStrings);
        return list;
    }

    public final void readOnePerLine(@NotNull File file, @NotNull List<String> list, boolean trimStrings) {
        Intrinsics.checkNotNullParameter((Object)file, (String)"file");
        Intrinsics.checkNotNullParameter(list, (String)"list");
        if (trimStrings) {
            this.read(file, new Action(list){
                private int lineNumber;
                final /* synthetic */ List<String> $list;
                {
                    this.$list = $list;
                }

                public final int getLineNumber() {
                    return this.lineNumber;
                }

                public final void setLineNumber(int n) {
                    this.lineNumber = n;
                }

                public void onLineRead(@NotNull String line) {
                    String newLine;
                    Intrinsics.checkNotNullParameter((Object)line, (String)"line");
                    if (((CharSequence)line).length() > 0 && !StringsKt.startsWith$default((String)line, (String)"#", (boolean)false, (int)2, null) && ((CharSequence)(newLine = ((Object)StringsKt.trim((CharSequence)line)).toString())).length() > 0) {
                        this.$list.add(newLine);
                    }
                    int n = this.lineNumber;
                    this.lineNumber = n + 1;
                }

                public void finished() {
                }
            });
        } else {
            this.read(file, new Action(list){
                private int lineNumber;
                final /* synthetic */ List<String> $list;
                {
                    this.$list = $list;
                }

                public final int getLineNumber() {
                    return this.lineNumber;
                }

                public final void setLineNumber(int n) {
                    this.lineNumber = n;
                }

                public void onLineRead(@NotNull String line) {
                    Intrinsics.checkNotNullParameter((Object)line, (String)"line");
                    this.$list.add(line);
                    int n = this.lineNumber;
                    this.lineNumber = n + 1;
                }

                public void finished() {
                }
            });
        }
    }

    public final boolean deleteDirectory(@NotNull File dir) {
        Intrinsics.checkNotNullParameter((Object)dir, (String)"dir");
        try {
            return FilesKt.deleteRecursively((File)dir);
        }
        catch (IOException e) {
            log.error("Error deleting the contents of dir " + dir, (Throwable)e);
        }
        catch (DirectoryIteratorException e) {
            log.error("Error deleting the contents of dir " + dir, (Throwable)e);
        }
        return false;
    }

    public final boolean renameTo(@NotNull File source, @NotNull File dest) {
        boolean bl;
        Intrinsics.checkNotNullParameter((Object)source, (String)"source");
        Intrinsics.checkNotNullParameter((Object)dest, (String)"dest");
        if (source.renameTo(dest)) {
            return true;
        }
        if (dest.exists()) {
            File temp = new File(dest.getPath() + "_old");
            if (temp.exists() && !temp.delete()) {
            }
            if (dest.renameTo(temp) && source.renameTo(dest)) {
                if (temp.delete()) {
                }
                return true;
            }
        }
        try {
            FilesKt.copyTo$default((File)source, (File)dest, (boolean)false, (int)0, (int)6, null);
            if (!source.delete()) {
            }
            bl = true;
        }
        catch (IOException ioe) {
            bl = false;
        }
        return bl;
    }

    @NotNull
    public final File copyFile(@NotNull String in, @NotNull File out) throws IOException {
        Intrinsics.checkNotNullParameter((Object)in, (String)"in");
        Intrinsics.checkNotNullParameter((Object)out, (String)"out");
        return FileUtil.copyFile(new File(in), out);
    }

    @NotNull
    public final File copyFile(@NotNull File in, @NotNull String out) throws IOException {
        Intrinsics.checkNotNullParameter((Object)in, (String)"in");
        Intrinsics.checkNotNullParameter((Object)out, (String)"out");
        return FileUtil.copyFile(in, new File(out));
    }

    @NotNull
    public final File copyFile(@NotNull String in, @NotNull String out) throws IOException {
        Intrinsics.checkNotNullParameter((Object)in, (String)"in");
        Intrinsics.checkNotNullParameter((Object)out, (String)"out");
        return FileUtil.copyFile(new File(in), new File(out));
    }

    @NotNull
    public final File copyFileToDir(@NotNull String in, @NotNull String out) throws IOException {
        Intrinsics.checkNotNullParameter((Object)in, (String)"in");
        Intrinsics.checkNotNullParameter((Object)out, (String)"out");
        return this.copyFileToDir(new File(in), new File(out));
    }

    @NotNull
    public final File copyFileToDir(@NotNull File in, @NotNull File out) throws IOException {
        Intrinsics.checkNotNullParameter((Object)in, (String)"in");
        Intrinsics.checkNotNullParameter((Object)out, (String)"out");
        if (!out.isDirectory()) {
            throw new IOException("Out file is not a directory! '" + out.getAbsolutePath() + '\'');
        }
        return FileUtil.copyFile(in, new File(out, in.getName()));
    }

    @JvmStatic
    @NotNull
    public static final File copyFile(@NotNull File in, @NotNull File out) throws IOException {
        File parentOut;
        Intrinsics.checkNotNullParameter((Object)in, (String)"in");
        Intrinsics.checkNotNullParameter((Object)out, (String)"out");
        File file = INSTANCE.normalize(in);
        Intrinsics.checkNotNull((Object)file);
        String normalizedIn = file.getAbsolutePath();
        File file2 = INSTANCE.normalize(out);
        Intrinsics.checkNotNull((Object)file2);
        String normalizedout = file2.getAbsolutePath();
        if (StringsKt.equals((String)normalizedIn, (String)normalizedout, (boolean)true)) {
            return out;
        }
        File file3 = parentOut = out.getParentFile();
        boolean bl = file3 != null ? !file3.canWrite() : false;
        if (bl) {
            parentOut.mkdirs();
        }
        FilesKt.copyTo$default((File)in, (File)out, (boolean)false, (int)0, (int)6, null);
        out.setLastModified(in.lastModified());
        return out;
    }

    @NotNull
    public final File concatFiles(@NotNull File one, @NotNull File two) {
        Intrinsics.checkNotNullParameter((Object)one, (String)"one");
        Intrinsics.checkNotNullParameter((Object)two, (String)"two");
        FilesKt.appendBytes((File)one, (byte[])FilesKt.readBytes((File)two));
        one.setLastModified(System.currentTimeMillis());
        return one;
    }

    @NotNull
    public final File moveFile(@NotNull String in, @NotNull File out) throws IOException {
        Intrinsics.checkNotNullParameter((Object)in, (String)"in");
        Intrinsics.checkNotNullParameter((Object)out, (String)"out");
        return this.moveFile(new File(in), out);
    }

    @NotNull
    public final File moveFile(@NotNull File in, @NotNull String out) throws IOException {
        Intrinsics.checkNotNullParameter((Object)in, (String)"in");
        Intrinsics.checkNotNullParameter((Object)out, (String)"out");
        return this.moveFile(in, new File(out));
    }

    @NotNull
    public final File moveFile(@NotNull String in, @NotNull String out) throws IOException {
        Intrinsics.checkNotNullParameter((Object)in, (String)"in");
        Intrinsics.checkNotNullParameter((Object)out, (String)"out");
        return this.moveFile(new File(in), new File(out));
    }

    @NotNull
    public final File moveFile(@NotNull File in, @NotNull File out) throws IOException {
        boolean renameSuccess;
        Intrinsics.checkNotNullParameter((Object)in, (String)"in");
        Intrinsics.checkNotNullParameter((Object)out, (String)"out");
        if (out.canRead()) {
            out.delete();
        }
        if (!(renameSuccess = this.renameTo(in, out))) {
            throw new IOException("Unable to move file: '" + in.getAbsolutePath() + "' -> '" + out.getAbsolutePath() + '\'');
        }
        return out;
    }

    public final void copyDirectory(@NotNull String src, @NotNull String dest, String ... namesToIgnore) throws IOException {
        Intrinsics.checkNotNullParameter((Object)src, (String)"src");
        Intrinsics.checkNotNullParameter((Object)dest, (String)"dest");
        Intrinsics.checkNotNullParameter((Object)namesToIgnore, (String)"namesToIgnore");
        this.copyDirectory(new File(src), new File(dest), Arrays.copyOf(namesToIgnore, namesToIgnore.length));
    }

    public final void copyDirectory(@NotNull File src_, @NotNull File dest_, String ... namesToIgnore) throws IOException {
        Intrinsics.checkNotNullParameter((Object)src_, (String)"src_");
        Intrinsics.checkNotNullParameter((Object)dest_, (String)"dest_");
        Intrinsics.checkNotNullParameter((Object)namesToIgnore, (String)"namesToIgnore");
        File src = this.normalize(src_);
        File dest = this.normalize(dest_);
        if (src == null) {
            boolean $i$a$-requireNotNull-FileUtil$copyDirectory$32 = false;
            String $i$a$-requireNotNull-FileUtil$copyDirectory$32 = "Source must be valid";
            throw new IllegalArgumentException($i$a$-requireNotNull-FileUtil$copyDirectory$32.toString());
        }
        if (dest == null) {
            boolean $i$a$-requireNotNull-FileUtil$copyDirectory$42 = false;
            String $i$a$-requireNotNull-FileUtil$copyDirectory$42 = "Destination must be valid";
            throw new IllegalArgumentException($i$a$-requireNotNull-FileUtil$copyDirectory$42.toString());
        }
        if (!(namesToIgnore.length == 0)) {
            String name = src.getName();
            int n = namesToIgnore.length;
            for (int i = 0; i < n; ++i) {
                String ignore = namesToIgnore[i];
                if (!Intrinsics.areEqual((Object)name, (Object)ignore)) continue;
                return;
            }
        }
        if (src.isDirectory()) {
            String[] files;
            if (!dest.exists()) {
                dest.mkdir();
            }
            if ((files = src.list()) != null) {
                for (String file : files) {
                    File srcFile = new File(src, file);
                    File destFile = new File(dest, file);
                    this.copyDirectory(srcFile, destFile, Arrays.copyOf(namesToIgnore, namesToIgnore.length));
                }
            }
        } else {
            FileUtil.copyFile(src, dest);
        }
    }

    public final void moveDirectory(@NotNull String src, @NotNull String dest, String ... fileNamesToIgnore) throws IOException {
        Intrinsics.checkNotNullParameter((Object)src, (String)"src");
        Intrinsics.checkNotNullParameter((Object)dest, (String)"dest");
        Intrinsics.checkNotNullParameter((Object)fileNamesToIgnore, (String)"fileNamesToIgnore");
        this.moveDirectory(new File(src), new File(dest), Arrays.copyOf(fileNamesToIgnore, fileNamesToIgnore.length));
    }

    public final void moveDirectory(@NotNull File src, @NotNull File dest, String ... fileNamesToIgnore) throws IOException {
        Intrinsics.checkNotNullParameter((Object)src, (String)"src");
        Intrinsics.checkNotNullParameter((Object)dest, (String)"dest");
        Intrinsics.checkNotNullParameter((Object)fileNamesToIgnore, (String)"fileNamesToIgnore");
        if (fileNamesToIgnore.length > 0) {
            String name = src.getName();
            int n = fileNamesToIgnore.length;
            for (int i = 0; i < n; ++i) {
                String ignore = fileNamesToIgnore[i];
                if (!Intrinsics.areEqual((Object)name, (Object)ignore)) continue;
                return;
            }
        }
        if (src.isDirectory()) {
            String[] files;
            if (!dest.exists()) {
                dest.mkdir();
            }
            if ((files = src.list()) != null) {
                for (String file : files) {
                    File srcFile = new File(src, file);
                    File destFile = new File(dest, file);
                    this.moveDirectory(srcFile, destFile, Arrays.copyOf(fileNamesToIgnore, fileNamesToIgnore.length));
                }
            }
        } else {
            this.moveFile(src, dest);
        }
    }

    public final boolean delete(@NotNull String fileName, String ... fileNamesToIgnore) {
        Intrinsics.checkNotNullParameter((Object)fileName, (String)"fileName");
        Intrinsics.checkNotNullParameter((Object)fileNamesToIgnore, (String)"fileNamesToIgnore");
        return FileUtil.delete(new File(fileName), Arrays.copyOf(fileNamesToIgnore, fileNamesToIgnore.length));
    }

    @JvmStatic
    public static final boolean delete(@NotNull File file, String ... namesToIgnore) {
        File[] files;
        Intrinsics.checkNotNullParameter((Object)file, (String)"file");
        Intrinsics.checkNotNullParameter((Object)namesToIgnore, (String)"namesToIgnore");
        if (!file.exists()) {
            return true;
        }
        boolean thingsDeleted = false;
        boolean ignored = false;
        if (file.isDirectory() && (files = file.listFiles()) != null) {
            int n = files.length;
            for (int i = 0; i < n; ++i) {
                boolean delete = true;
                File file2 = files[i];
                String name2 = file2.getName();
                Intrinsics.checkNotNullExpressionValue((Object)file2, (String)"file2");
                File file3 = INSTANCE.normalize(file2);
                Intrinsics.checkNotNull((Object)file3);
                String name2Full = file3.getAbsolutePath();
                if (file2.isDirectory()) {
                    int n2 = namesToIgnore.length;
                    for (int j = 0; j < n2; ++j) {
                        String name = namesToIgnore[j];
                        if (name.charAt(0) == '/' && Intrinsics.areEqual((Object)name, (Object)name2)) {
                            ignored = true;
                            delete = false;
                            break;
                        }
                        if (!Intrinsics.areEqual((Object)name, (Object)name2Full)) continue;
                        ignored = true;
                        delete = false;
                        break;
                    }
                    if (!delete) continue;
                    FileUtil.delete(file2, Arrays.copyOf(namesToIgnore, namesToIgnore.length));
                    continue;
                }
                for (String name : namesToIgnore) {
                    if (name.charAt(0) != '/' && Intrinsics.areEqual((Object)name, (Object)name2)) {
                        ignored = true;
                        delete = false;
                        break;
                    }
                    if (!Intrinsics.areEqual((Object)name, (Object)name2Full)) continue;
                    ignored = true;
                    delete = false;
                    break;
                }
                if (!delete) continue;
                thingsDeleted |= file2.delete();
            }
        }
        if (ignored) {
            return false;
        }
        return thingsDeleted |= file.delete();
    }

    @Nullable
    public final byte[] toBytes(@NotNull File file) {
        Intrinsics.checkNotNullParameter((Object)file, (String)"file");
        return FilesKt.readBytes((File)file);
    }

    @NotNull
    public final String mkdir(@NotNull File location) {
        Intrinsics.checkNotNullParameter((Object)location, (String)"location");
        File file = this.normalize(location);
        Intrinsics.checkNotNull((Object)file);
        File path = file.getAbsoluteFile();
        if (location.mkdirs()) {
        }
        String string = path.getPath();
        Intrinsics.checkNotNullExpressionValue((Object)string, (String)"path.path");
        return string;
    }

    @NotNull
    public final String mkdir(@NotNull String location) {
        Intrinsics.checkNotNullParameter((Object)location, (String)"location");
        return this.mkdir(new File(location));
    }

    @NotNull
    public final File tempFile(@NotNull String fileName) throws IOException {
        Intrinsics.checkNotNullParameter((Object)fileName, (String)"fileName");
        File file = File.createTempFile(fileName, null);
        Intrinsics.checkNotNullExpressionValue((Object)file, (String)"createTempFile(fileName, null)");
        File file2 = this.normalize(file);
        Intrinsics.checkNotNull((Object)file2);
        File file3 = file2.getAbsoluteFile();
        Intrinsics.checkNotNullExpressionValue((Object)file3, (String)"normalize(File.createTem\u2026me, null))!!.absoluteFile");
        return file3;
    }

    @NotNull
    public final String tempDirectory(@NotNull String directoryName) throws IOException {
        Intrinsics.checkNotNullParameter((Object)directoryName, (String)"directoryName");
        File file = File.createTempFile(directoryName, null);
        if (!file.delete()) {
            throw new IOException("Unable to delete temp file: " + file);
        }
        if (!file.mkdir()) {
            throw new IOException("Unable to create temp directory: " + file);
        }
        Intrinsics.checkNotNullExpressionValue((Object)file, (String)"file");
        File file2 = this.normalize(file);
        Intrinsics.checkNotNull((Object)file2);
        String string = file2.getAbsolutePath();
        Intrinsics.checkNotNullExpressionValue((Object)string, (String)"normalize(file)!!.absolutePath");
        return string;
    }

    public final boolean isZipStream(@NotNull InputStream in) {
        Intrinsics.checkNotNullParameter((Object)in, (String)"in");
        InputStream in2 = in;
        if (!in2.markSupported()) {
            in2 = new BufferedInputStream(in2);
        }
        boolean isZip = true;
        try {
            in2.mark(ZIP_HEADER.length);
            int n = ZIP_HEADER.length;
            for (int i = 0; i < n; ++i) {
                if (ZIP_HEADER[i] == (byte)in2.read()) continue;
                isZip = false;
                break;
            }
            in2.reset();
        }
        catch (Exception e) {
            isZip = false;
        }
        return isZip;
    }

    public final boolean isZipFile(@NotNull String fileName) {
        Intrinsics.checkNotNullParameter((Object)fileName, (String)"fileName");
        return this.isZipFile(new File(fileName));
    }

    /*
     * WARNING - Removed try catching itself - possible behaviour change.
     * Unable to fully structure code
     */
    public final boolean isZipFile(@NotNull File file) {
        block14: {
            Intrinsics.checkNotNullParameter((Object)file, (String)"file");
            isZip = true;
            buffer = new byte[FileUtil.ZIP_HEADER.length];
            raf = null;
            try {
                raf = new RandomAccessFile(file, "r");
                raf.readFully(buffer);
                var6_10 = FileUtil.ZIP_HEADER.length;
                for (i = 0; i < var6_10; ++i) {
                    if (buffer[i] == FileUtil.ZIP_HEADER[i]) continue;
                    isZip = false;
                    break;
                }
                ** try [egrp 1[TRYBLOCK] [0 : 78->87)] { 
            }
            catch (Exception e) {
                isZip = false;
                v0 = e instanceof FileNotFoundException != false ? (FileNotFoundException)e : null;
                if (v0 != null) {
                    v0.printStackTrace();
                }
                break block14;
            }
            finally {
                if (raf != null) {
                    try {
                        raf.close();
                    }
                    catch (IOException e) {
                        e.printStackTrace();
                    }
                }
            }
lbl-1000:
            // 1 sources

            {
                raf.close();
            }
lbl18:
            // 1 sources

            catch (IOException e) {
                e.printStackTrace();
            }
            {
            }
        }
        return isZip;
    }

    public final void unzip(@NotNull String zipFile, @NotNull String outputDir) throws IOException {
        Intrinsics.checkNotNullParameter((Object)zipFile, (String)"zipFile");
        Intrinsics.checkNotNullParameter((Object)outputDir, (String)"outputDir");
        this.unzipJar(zipFile, outputDir, true);
    }

    public final void unzip(@NotNull File zipFile, @NotNull File outputDir) throws IOException {
        Intrinsics.checkNotNullParameter((Object)zipFile, (String)"zipFile");
        Intrinsics.checkNotNullParameter((Object)outputDir, (String)"outputDir");
        this.unzipJar(zipFile, outputDir, true);
    }

    public final void unzip(@NotNull ZipInputStream inputStream, @NotNull String outputDir) throws IOException {
        Intrinsics.checkNotNullParameter((Object)inputStream, (String)"inputStream");
        Intrinsics.checkNotNullParameter((Object)outputDir, (String)"outputDir");
        this.unzip(inputStream, new File(outputDir));
    }

    public final void unzip(@NotNull ZipInputStream inputStream, @NotNull File outputDir) throws IOException {
        Intrinsics.checkNotNullParameter((Object)inputStream, (String)"inputStream");
        Intrinsics.checkNotNullParameter((Object)outputDir, (String)"outputDir");
        this.unzipJar(inputStream, outputDir, true);
    }

    public final void unzipJar(@NotNull String zipFile, @NotNull String outputDir, boolean extractManifest) throws IOException {
        Intrinsics.checkNotNullParameter((Object)zipFile, (String)"zipFile");
        Intrinsics.checkNotNullParameter((Object)outputDir, (String)"outputDir");
        this.unjarzip0(new File(zipFile), new File(outputDir), extractManifest);
    }

    public final void unzipJar(@NotNull File zipFile, @NotNull File outputDir, boolean extractManifest) throws IOException {
        Intrinsics.checkNotNullParameter((Object)zipFile, (String)"zipFile");
        Intrinsics.checkNotNullParameter((Object)outputDir, (String)"outputDir");
        this.unjarzip0(zipFile, outputDir, extractManifest);
    }

    public final void unzipJar(@NotNull ZipInputStream inputStream, @NotNull File outputDir, boolean extractManifest) throws IOException {
        Intrinsics.checkNotNullParameter((Object)inputStream, (String)"inputStream");
        Intrinsics.checkNotNullParameter((Object)outputDir, (String)"outputDir");
        this.unjarzip1(inputStream, outputDir, extractManifest);
    }

    private final void unjarzip0(File zipFile, File outputDir, boolean extractManifest) throws IOException {
        long fileLength = zipFile.length();
        if (fileLength > 0x7FFFFFFEL) {
            throw new RuntimeException("Source filesize is too large!");
        }
        ZipInputStream inputStream = new ZipInputStream(new FileInputStream(zipFile));
        this.unjarzip1(inputStream, outputDir, extractManifest);
    }

    /*
     * WARNING - Removed try catching itself - possible behaviour change.
     */
    private final void unjarzip1(ZipInputStream inputStream, File outputDir, boolean extractManifest) throws IOException {
        Closeable closeable = inputStream;
        Throwable throwable = null;
        try {
            block13: {
                Throwable throwable2;
                Closeable closeable2;
                ZipInputStream it = (ZipInputStream)closeable;
                boolean bl = false;
                ZipEntry entry = null;
                while (true) {
                    ZipEntry zipEntry;
                    ZipEntry it2 = zipEntry = inputStream.getNextEntry();
                    boolean bl2 = false;
                    Intrinsics.checkNotNullExpressionValue((Object)it2, (String)"it");
                    entry = it2;
                    if (zipEntry == null) break block13;
                    String name = entry.getName();
                    if (!extractManifest) {
                        Intrinsics.checkNotNullExpressionValue((Object)name, (String)"name");
                        if (StringsKt.startsWith$default((String)name, (String)"META-INF/", (boolean)false, (int)2, null)) continue;
                    }
                    File file = new File(outputDir, name);
                    if (entry.isDirectory()) {
                        String string = file.getPath();
                        Intrinsics.checkNotNullExpressionValue((Object)string, (String)"file.path");
                        INSTANCE.mkdir(string);
                        continue;
                    }
                    String string = file.getParent();
                    Intrinsics.checkNotNullExpressionValue((Object)string, (String)"file.parent");
                    INSTANCE.mkdir(string);
                    closeable2 = new FileOutputStream(file);
                    throwable2 = null;
                    try {
                        FileOutputStream it3 = (FileOutputStream)closeable2;
                        boolean bl3 = false;
                        long l = ByteStreamsKt.copyTo$default((InputStream)inputStream, (OutputStream)it3, (int)0, (int)2, null);
                    }
                    catch (Throwable throwable3) {
                        throwable2 = throwable3;
                        throw throwable3;
                    }
                }
                finally {
                    CloseableKt.closeFinally((Closeable)closeable2, (Throwable)throwable2);
                }
            }
            Unit unit = Unit.INSTANCE;
        }
        catch (Throwable throwable4) {
            throwable = throwable4;
            throw throwable4;
        }
        finally {
            CloseableKt.closeFinally((Closeable)closeable, (Throwable)throwable);
        }
    }

    @NotNull
    public final List<File> parseDir(@NotNull String rootDirectory) throws IOException {
        Intrinsics.checkNotNullParameter((Object)rootDirectory, (String)"rootDirectory");
        return this.parseDir(new File(rootDirectory));
    }

    @NotNull
    public final List<File> parseDir(@NotNull File rootDirectory) throws IOException {
        Intrinsics.checkNotNullParameter((Object)rootDirectory, (String)"rootDirectory");
        return this.parseDir(rootDirectory);
    }

    @NotNull
    public final List<File> parseDir(@NotNull File rootDirectory, String ... extensionsToMatch) throws IOException {
        Intrinsics.checkNotNullParameter((Object)rootDirectory, (String)"rootDirectory");
        Intrinsics.checkNotNullParameter((Object)extensionsToMatch, (String)"extensionsToMatch");
        List jarList = new LinkedList();
        LinkedList<File> directories = new LinkedList<File>();
        File file = this.normalize(rootDirectory);
        if (file == null) {
            throw new IOException("Root directory was invalid!");
        }
        File rootDirectory2 = file;
        if (!rootDirectory2.exists()) {
            throw new IOException("Location does not exist: " + rootDirectory2.getAbsolutePath());
        }
        if (rootDirectory2.isDirectory()) {
            directories.add(rootDirectory2);
            while (directories.peek() != null) {
                File dir;
                File file2 = dir = (File)directories.poll();
                Intrinsics.checkNotNull((Object)file2);
                File[] listFiles = file2.listFiles();
                if (listFiles == null) continue;
                for (File file3 : listFiles) {
                    if (file3.isDirectory()) {
                        directories.add(file3);
                        continue;
                    }
                    if (extensionsToMatch.length == 0) {
                        Intrinsics.checkNotNullExpressionValue((Object)file3, (String)"file");
                        jarList.add(file3);
                        continue;
                    }
                    int n = extensionsToMatch.length;
                    for (int i = 0; i < n; ++i) {
                        String e = extensionsToMatch[i];
                        String string = file3.getAbsolutePath();
                        Intrinsics.checkNotNullExpressionValue((Object)string, (String)"file.absolutePath");
                        if (!StringsKt.endsWith$default((String)string, (String)e, (boolean)false, (int)2, null)) continue;
                        Intrinsics.checkNotNullExpressionValue((Object)file3, (String)"file");
                        jarList.add(file3);
                    }
                }
            }
        } else {
            throw new IOException("Cannot search directory children if the dir is a file name: " + rootDirectory2.getAbsolutePath());
        }
        return jarList;
    }

    @Nullable
    public final String getChildRelativeToDir(@NotNull String fileName, @NotNull String dirInHeirarchy) {
        Intrinsics.checkNotNullParameter((Object)fileName, (String)"fileName");
        Intrinsics.checkNotNullParameter((Object)dirInHeirarchy, (String)"dirInHeirarchy");
        if (!(((CharSequence)fileName).length() == 0)) {
            boolean bl = false;
            String string = "fileName cannot be empty.";
            throw new IllegalArgumentException(string.toString());
        }
        return this.getChildRelativeToDir(new File(fileName), dirInHeirarchy);
    }

    /*
     * Enabled force condition propagation
     * Lifted jumps to return sites
     */
    @Nullable
    public final String getChildRelativeToDir(@NotNull File file, @NotNull String dirInHeirarchy) {
        File parent;
        Intrinsics.checkNotNullParameter((Object)file, (String)"file");
        Intrinsics.checkNotNullParameter((Object)dirInHeirarchy, (String)"dirInHeirarchy");
        if (!(((CharSequence)dirInHeirarchy).length() == 0)) {
            boolean $i$a$-require-FileUtil$getChildRelativeToDir$32 = false;
            String $i$a$-require-FileUtil$getChildRelativeToDir$32 = "dirInHeirarchy cannot be empty.";
            throw new IllegalArgumentException($i$a$-require-FileUtil$getChildRelativeToDir$32.toString());
        }
        CharSequence charSequence = dirInHeirarchy;
        String[] $i$a$-require-FileUtil$getChildRelativeToDir$32 = new String[1];
        Intrinsics.checkNotNullExpressionValue((Object)File.separator, (String)"separator");
        Collection $this$toTypedArray$iv = StringsKt.split$default((CharSequence)charSequence, (String[])$i$a$-require-FileUtil$getChildRelativeToDir$32, (boolean)false, (int)0, (int)6, null);
        boolean $i$f$toTypedArray = false;
        Collection thisCollection$iv = $this$toTypedArray$iv;
        String[] stringArray = thisCollection$iv.toArray(new String[0]);
        Intrinsics.checkNotNull((Object)stringArray, (String)"null cannot be cast to non-null type kotlin.Array<T of kotlin.collections.ArraysKt__ArraysJVMKt.toTypedArray>");
        String[] split = stringArray;
        int splitIndex = split.length - 1;
        String absolutePath = file.getAbsolutePath();
        String parentName = null;
        if (splitIndex == 0) {
            for (parent = file; parent != null; parent = parent.getParentFile()) {
                Intrinsics.checkNotNullExpressionValue((Object)parent.getName(), (String)"parent.name");
                if (!Intrinsics.areEqual((Object)parentName, (Object)dirInHeirarchy)) continue;
                String string = parent.getAbsolutePath();
                Intrinsics.checkNotNullExpressionValue((Object)string, (String)"parent.absolutePath");
                parentName = string;
                Intrinsics.checkNotNullExpressionValue((Object)absolutePath, (String)"absolutePath");
                String string2 = absolutePath.substring(parentName.length() + 1);
                Intrinsics.checkNotNullExpressionValue((Object)string2, (String)"this as java.lang.String).substring(startIndex)");
                return string2;
            }
            return null;
        } else {
            boolean matched = false;
            while (parent != null) {
                Intrinsics.checkNotNullExpressionValue((Object)parent.getName(), (String)"parent.name");
                if (matched) {
                    if (!Intrinsics.areEqual((Object)parentName, (Object)split[splitIndex])) return null;
                    if (--splitIndex < 0) {
                        String string;
                        if (absolutePath.length() == dirInHeirarchy.length()) {
                            string = null;
                            return string;
                        } else {
                            Intrinsics.checkNotNullExpressionValue((Object)absolutePath, (String)"absolutePath");
                            String string3 = absolutePath.substring(dirInHeirarchy.length() + 1, absolutePath.length());
                            string = string3;
                            Intrinsics.checkNotNullExpressionValue((Object)string3, (String)"this as java.lang.String\u2026ing(startIndex, endIndex)");
                        }
                        return string;
                    }
                } else if (Intrinsics.areEqual((Object)parentName, (Object)split[splitIndex])) {
                    matched = true;
                    --splitIndex;
                }
                parent = parent.getParentFile();
            }
        }
        return null;
    }

    @Nullable
    public final String getParentRelativeToDir(@NotNull String fileName, @NotNull String dirInHeirarchy) {
        Intrinsics.checkNotNullParameter((Object)fileName, (String)"fileName");
        Intrinsics.checkNotNullParameter((Object)dirInHeirarchy, (String)"dirInHeirarchy");
        if (!(((CharSequence)fileName).length() == 0)) {
            boolean bl = false;
            String string = "fileName cannot be empty.";
            throw new IllegalArgumentException(string.toString());
        }
        return this.getParentRelativeToDir(new File(fileName), dirInHeirarchy);
    }

    /*
     * Enabled force condition propagation
     * Lifted jumps to return sites
     */
    @Nullable
    public final String getParentRelativeToDir(@NotNull File file, @NotNull String dirInHeirarchy) {
        Intrinsics.checkNotNullParameter((Object)file, (String)"file");
        Intrinsics.checkNotNullParameter((Object)dirInHeirarchy, (String)"dirInHeirarchy");
        if (!(((CharSequence)dirInHeirarchy).length() == 0)) {
            boolean $i$a$-require-FileUtil$getParentRelativeToDir$32 = false;
            String $i$a$-require-FileUtil$getParentRelativeToDir$32 = "dirInHeirarchy cannot be empty.";
            throw new IllegalArgumentException($i$a$-require-FileUtil$getParentRelativeToDir$32.toString());
        }
        CharSequence charSequence = dirInHeirarchy;
        String[] $i$a$-require-FileUtil$getParentRelativeToDir$32 = new String[1];
        Intrinsics.checkNotNullExpressionValue((Object)File.separator, (String)"separator");
        Collection $this$toTypedArray$iv = StringsKt.split$default((CharSequence)charSequence, (String[])$i$a$-require-FileUtil$getParentRelativeToDir$32, (boolean)false, (int)0, (int)6, null);
        boolean $i$f$toTypedArray = false;
        Collection thisCollection$iv = $this$toTypedArray$iv;
        String[] stringArray = thisCollection$iv.toArray(new String[0]);
        Intrinsics.checkNotNull((Object)stringArray, (String)"null cannot be cast to non-null type kotlin.Array<T of kotlin.collections.ArraysKt__ArraysJVMKt.toTypedArray>");
        String[] split = stringArray;
        int splitIndex = split.length - 1;
        File parent = file;
        String parentName = null;
        if (splitIndex == 0) {
            while (parent != null) {
                Intrinsics.checkNotNullExpressionValue((Object)parent.getName(), (String)"parent.name");
                if (Intrinsics.areEqual((Object)parentName, (Object)dirInHeirarchy)) {
                    parent = parent.getParentFile();
                    String string = parent.getAbsolutePath();
                    Intrinsics.checkNotNullExpressionValue((Object)string, (String)"parent.absolutePath");
                    return string;
                }
                parent = parent.getParentFile();
            }
            return null;
        }
        boolean matched = false;
        while (parent != null) {
            Intrinsics.checkNotNullExpressionValue((Object)parent.getName(), (String)"parent.name");
            if (matched) {
                if (!Intrinsics.areEqual((Object)parentName, (Object)split[splitIndex])) return null;
                if (--splitIndex < 0) {
                    parent = parent.getParentFile();
                    String string = parent.getAbsolutePath();
                    Intrinsics.checkNotNullExpressionValue((Object)string, (String)"parent.absolutePath");
                    return string;
                }
            } else if (Intrinsics.areEqual((Object)parentName, (Object)split[splitIndex])) {
                matched = true;
                --splitIndex;
            }
            parent = parent.getParentFile();
        }
        return null;
    }

    /*
     * WARNING - Removed try catching itself - possible behaviour change.
     */
    @Nullable
    public final String extractFromZip(@NotNull String zipFile, @NotNull String fileToExtract) throws IOException {
        Intrinsics.checkNotNullParameter((Object)zipFile, (String)"zipFile");
        Intrinsics.checkNotNullParameter((Object)fileToExtract, (String)"fileToExtract");
        Closeable closeable = new ZipInputStream(new FileInputStream(zipFile));
        Throwable throwable = null;
        try {
            block12: {
                String name;
                ZipEntry entry;
                ZipInputStream inputStream = (ZipInputStream)closeable;
                boolean bl = false;
                do {
                    ZipEntry zipEntry;
                    ZipEntry zipEntry2 = zipEntry = inputStream.getNextEntry();
                    if (zipEntry2 == null) break block12;
                    Intrinsics.checkNotNullExpressionValue((Object)zipEntry2, (String)"inputStream.nextEntry ?: break");
                    entry = zipEntry;
                    name = entry.getName();
                } while (entry.isDirectory() || !Intrinsics.areEqual((Object)name, (Object)fileToExtract));
                Intrinsics.checkNotNullExpressionValue((Object)name, (String)"name");
                File tempFile = INSTANCE.tempFile(name);
                tempFile.deleteOnExit();
                FileOutputStream tempOutput = new FileOutputStream(tempFile);
                Closeable closeable2 = tempOutput;
                Throwable throwable2 = null;
                try {
                    FileOutputStream it = (FileOutputStream)closeable2;
                    boolean bl2 = false;
                    long l = ByteStreamsKt.copyTo$default((InputStream)inputStream, (OutputStream)it, (int)0, (int)2, null);
                }
                catch (Throwable throwable3) {
                    throwable2 = throwable3;
                    throw throwable3;
                }
                finally {
                    CloseableKt.closeFinally((Closeable)closeable2, (Throwable)throwable2);
                }
                String string = tempFile.getAbsolutePath();
                return string;
            }
            Unit unit = Unit.INSTANCE;
        }
        catch (Throwable throwable4) {
            throwable = throwable4;
            throw throwable4;
        }
        finally {
            CloseableKt.closeFinally((Closeable)closeable, (Throwable)throwable);
        }
        return null;
    }

    public final boolean touch(@NotNull String file) {
        Intrinsics.checkNotNullParameter((Object)file, (String)"file");
        long timestamp = System.currentTimeMillis();
        File file2 = new File(file).getAbsoluteFile();
        Intrinsics.checkNotNullExpressionValue((Object)file2, (String)"File(file).absoluteFile");
        return this.touch(file2, timestamp);
    }

    public final boolean touch(@NotNull File file) {
        Intrinsics.checkNotNullParameter((Object)file, (String)"file");
        long timestamp = System.currentTimeMillis();
        return this.touch(file, timestamp);
    }

    public final boolean touch(@NotNull File file, long timestamp) {
        Intrinsics.checkNotNullParameter((Object)file, (String)"file");
        if (!file.exists()) {
            boolean mkdirs = file.getParentFile().mkdirs();
            if (!mkdirs) {
                return false;
            }
            try {
                new FileOutputStream(file).close();
            }
            catch (IOException ignored) {
                return false;
            }
        }
        return file.setLastModified(timestamp);
    }

    @Nullable
    public final String normalizeRaw(@NotNull String filename) {
        Intrinsics.checkNotNullParameter((Object)filename, (String)"filename");
        return this.doNormalize(filename, SYSTEM_SEPARATOR, true);
    }

    @Nullable
    public final File normalize(@NotNull String filename) {
        Intrinsics.checkNotNullParameter((Object)filename, (String)"filename");
        String string = new File(filename).getAbsolutePath();
        Intrinsics.checkNotNullExpressionValue((Object)string, (String)"File(filename).absolutePath");
        String string2 = this.doNormalize(string, SYSTEM_SEPARATOR, true);
        if (string2 == null) {
            return null;
        }
        String asString = string2;
        return new File(asString).getAbsoluteFile();
    }

    @Nullable
    public final File normalize(@NotNull File file) {
        Intrinsics.checkNotNullParameter((Object)file, (String)"file");
        String string = file.getAbsolutePath();
        Intrinsics.checkNotNullExpressionValue((Object)string, (String)"file.absolutePath");
        String string2 = this.doNormalize(string, SYSTEM_SEPARATOR, true);
        if (string2 == null) {
            return null;
        }
        String asString = string2;
        return new File(asString).getAbsoluteFile();
    }

    @Nullable
    public final String normalize(@NotNull String filename, boolean unixSeparator) {
        Intrinsics.checkNotNullParameter((Object)filename, (String)"filename");
        char separator = unixSeparator ? (char)'/' : '\\';
        return this.doNormalize(filename, separator, true);
    }

    @Nullable
    public final String normalizeNoEndSeparator(@NotNull String filename) {
        Intrinsics.checkNotNullParameter((Object)filename, (String)"filename");
        return this.doNormalize(filename, SYSTEM_SEPARATOR, false);
    }

    @Nullable
    public final String normalizeNoEndSeparator(@NotNull String filename, boolean unixSeparator) {
        Intrinsics.checkNotNullParameter((Object)filename, (String)"filename");
        char separator = unixSeparator ? (char)'/' : '\\';
        return this.doNormalize(filename, separator, false);
    }

    private final String doNormalize(String filename, char separator, boolean keepSeparator) {
        int i;
        int size = 0;
        size = filename.length();
        if (size == 0) {
            return filename;
        }
        int prefix = this.getPrefixLength(filename);
        if (prefix < 0) {
            return null;
        }
        char[] array = new char[size + 2];
        String string = filename;
        int n = 0;
        int n2 = 0;
        int n3 = filename.length();
        string.getChars(n2, n3, array, n);
        char otherSeparator = separator == SYSTEM_SEPARATOR ? OTHER_SEPARATOR : SYSTEM_SEPARATOR;
        n2 = array.length;
        for (int i2 = 0; i2 < n2; ++i2) {
            if (array[i2] != otherSeparator) continue;
            array[i2] = separator;
        }
        boolean lastIsDirectory = true;
        if (array[size - 1] != separator) {
            n2 = size;
            size = n2 + 1;
            array[n2] = separator;
            lastIsDirectory = false;
        }
        FileUtil $this$doNormalize_u24lambda_u2432 = this;
        boolean bl = false;
        for (int i3 = prefix + 1; i3 < size; ++i3) {
            if (array[i3] != separator || array[i3 - 1] != separator) continue;
            System.arraycopy(array, i3, array, i3 - 1, size - i3);
            size += -1;
            --i3;
        }
        for (i = prefix + 1; i < size; ++i) {
            if (array[i] != separator || array[i - 1] != '.' || i != prefix + 1 && array[i - 2] != separator) continue;
            if (i == size - 1) {
                lastIsDirectory = true;
            }
            System.arraycopy(array, i + 1, array, i - 1, size - i);
            size -= 2;
            --i;
        }
        i = prefix + 2;
        block3: while (i < size) {
            if (array[i] == separator && array[i - 1] == '.' && array[i - 2] == '.' && (i == prefix + 2 || array[i - 3] == separator)) {
                if (i == prefix + 2) {
                    return null;
                }
                if (i == size - 1) {
                    lastIsDirectory = true;
                }
                int j = 0;
                for (j = i - 4; j >= prefix; --j) {
                    if (array[j] != separator) continue;
                    System.arraycopy(array, i + 1, array, j + 1, size - i);
                    size -= i - j;
                    i = j + 1;
                    ++i;
                    continue block3;
                }
                System.arraycopy(array, i + 1, array, prefix, size - i);
                size -= i + 1 - prefix;
                i = prefix + 1;
            }
            ++i;
        }
        if (size <= 0) {
            return "";
        }
        if (size <= prefix) {
            return new String(array, 0, size);
        }
        return lastIsDirectory && keepSeparator ? new String(array, 0, size) : new String(array, 0, size - 1);
    }

    public final int getPrefixLength(@NotNull String filename) {
        int n;
        Intrinsics.checkNotNullParameter((Object)filename, (String)"filename");
        int len = filename.length();
        if (len == 0) {
            return 0;
        }
        char ch0 = filename.charAt(0);
        if (ch0 == ':') {
            return -1;
        }
        if (len == 1) {
            if (ch0 == '~') {
                return 2;
            }
            n = this.isSeparator(ch0) ? 1 : 0;
        } else {
            if (ch0 == '~') {
                int posUnix = StringsKt.indexOf$default((CharSequence)filename, (char)'/', (int)1, (boolean)false, (int)4, null);
                int posWin = StringsKt.indexOf$default((CharSequence)filename, (char)'\\', (int)1, (boolean)false, (int)4, null);
                if (posUnix == -1 && posWin == -1) {
                    return len + 1;
                }
                posUnix = posUnix == -1 ? posWin : posUnix;
                posWin = posWin == -1 ? posUnix : posWin;
                return Math.min(posUnix, posWin) + 1;
            }
            char ch1 = filename.charAt(1);
            if (ch1 == ':') {
                if (Intrinsics.compare((int)(ch0 = Character.toUpperCase(ch0)), (int)65) >= 0 && Intrinsics.compare((int)ch0, (int)90) <= 0) {
                    return len == 2 || !this.isSeparator(filename.charAt(2)) ? 2 : 3;
                }
                n = -1;
            } else if (this.isSeparator(ch0) && this.isSeparator(ch1)) {
                int posUnix = StringsKt.indexOf$default((CharSequence)filename, (char)'/', (int)2, (boolean)false, (int)4, null);
                int posWin = StringsKt.indexOf$default((CharSequence)filename, (char)'\\', (int)2, (boolean)false, (int)4, null);
                if (posUnix == -1 && posWin == -1 || posUnix == 2 || posWin == 2) {
                    return -1;
                }
                posUnix = posUnix == -1 ? posWin : posUnix;
                posWin = posWin == -1 ? posUnix : posWin;
                n = Math.min(posUnix, posWin) + 1;
            } else {
                n = this.isSeparator(ch0) ? 1 : 0;
            }
        }
        return n;
    }

    private final boolean isSeparator(char ch) {
        return ch == '/' || ch == '\\';
    }

    @NotNull
    public final String getExtension(@NotNull String fileName) {
        String string;
        Intrinsics.checkNotNullParameter((Object)fileName, (String)"fileName");
        int dot = StringsKt.lastIndexOf$default((CharSequence)fileName, (char)'.', (int)0, (boolean)false, (int)6, null);
        if (dot > -1) {
            String string2 = fileName.substring(dot + 1);
            string = string2;
            Intrinsics.checkNotNullExpressionValue((Object)string2, (String)"this as java.lang.String).substring(startIndex)");
        } else {
            string = "";
        }
        return string;
    }

    @NotNull
    public final String getNameWithoutExtension(@NotNull String fileName) {
        String string;
        Intrinsics.checkNotNullParameter((Object)fileName, (String)"fileName");
        int dot = StringsKt.lastIndexOf$default((CharSequence)fileName, (char)'.', (int)0, (boolean)false, (int)6, null);
        if (dot > -1) {
            String string2 = fileName.substring(0, dot);
            string = string2;
            Intrinsics.checkNotNullExpressionValue((Object)string2, (String)"this as java.lang.String\u2026ing(startIndex, endIndex)");
        } else {
            string = fileName;
        }
        return string;
    }

    static {
        Logger logger = LoggerFactory.getLogger(FileUtil.class);
        Intrinsics.checkNotNullExpressionValue((Object)logger, (String)"getLogger(FileUtil::class.java)");
        log = logger;
        SYSTEM_SEPARATOR = File.separatorChar;
        OTHER_SEPARATOR = (char)(OS.INSTANCE.isWindows() ? 47 : 92);
        byte[] byArray = new byte[]{80, 75, 3, 4};
        ZIP_HEADER = byArray;
    }

    @Metadata(mv={1, 7, 1}, k=1, xi=48, d1={"\u0000\u0018\n\u0002\u0018\u0002\n\u0002\u0010\u0000\n\u0000\n\u0002\u0010\u0002\n\u0002\b\u0002\n\u0002\u0010\u000e\n\u0000\bf\u0018\u00002\u00020\u0001J\b\u0010\u0002\u001a\u00020\u0003H&J\u0010\u0010\u0004\u001a\u00020\u00032\u0006\u0010\u0005\u001a\u00020\u0006H&\u00a8\u0006\u0007"}, d2={"Ldorkbox/util/FileUtil$Action;", "", "finished", "", "onLineRead", "line", "", "Utilities"})
    public static interface Action {
        public void onLineRead(@NotNull String var1);

        public void finished();
    }
}

