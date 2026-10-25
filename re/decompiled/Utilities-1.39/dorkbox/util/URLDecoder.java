/*
 * Decompiled with CFR 0.152.
 * 
 * Could not load the following classes:
 *  kotlin.Metadata
 *  kotlin.jvm.internal.Intrinsics
 *  kotlin.text.Charsets
 *  kotlin.text.StringsKt
 *  org.jetbrains.annotations.NotNull
 */
package dorkbox.util;

import java.io.UnsupportedEncodingException;
import java.net.URISyntaxException;
import java.nio.charset.Charset;
import kotlin.Metadata;
import kotlin.jvm.internal.Intrinsics;
import kotlin.text.Charsets;
import kotlin.text.StringsKt;
import org.jetbrains.annotations.NotNull;

@Metadata(mv={1, 7, 1}, k=1, xi=48, d1={"\u0000,\n\u0002\u0018\u0002\n\u0002\u0010\u0000\n\u0002\b\u0002\n\u0002\u0010\u0005\n\u0002\b\u0016\n\u0002\u0010\u000e\n\u0002\b\u0002\n\u0002\u0018\u0002\n\u0002\b\u0006\n\u0002\u0010\u000b\n\u0002\b\u0003\b\u00c6\u0002\u0018\u00002\u00020\u0001B\u0007\b\u0002\u00a2\u0006\u0002\u0010\u0002J\u0016\u0010\u001a\u001a\u00020\u001b2\u0006\u0010\u001c\u001a\u00020\u001b2\u0006\u0010\u001d\u001a\u00020\u001eJ\u0016\u0010\u001f\u001a\u00020\u001b2\u0006\u0010 \u001a\u00020\u001b2\u0006\u0010\u001d\u001a\u00020\u001eJ\u0016\u0010!\u001a\u00020\u001b2\u0006\u0010\"\u001a\u00020\u001b2\u0006\u0010\u001d\u001a\u00020\u001eJ\u001e\u0010#\u001a\u00020\u001b2\u0006\u0010$\u001a\u00020\u001b2\u0006\u0010 \u001a\u00020%2\u0006\u0010\u001d\u001a\u00020\u001eJ\u0010\u0010&\u001a\u00020\u00042\u0006\u0010'\u001a\u00020\u0004H\u0002R\u000e\u0010\u0003\u001a\u00020\u0004X\u0082T\u00a2\u0006\u0002\n\u0000R\u000e\u0010\u0005\u001a\u00020\u0004X\u0082T\u00a2\u0006\u0002\n\u0000R\u000e\u0010\u0006\u001a\u00020\u0004X\u0082T\u00a2\u0006\u0002\n\u0000R\u000e\u0010\u0007\u001a\u00020\u0004X\u0082T\u00a2\u0006\u0002\n\u0000R\u000e\u0010\b\u001a\u00020\u0004X\u0082T\u00a2\u0006\u0002\n\u0000R\u000e\u0010\t\u001a\u00020\u0004X\u0082T\u00a2\u0006\u0002\n\u0000R\u000e\u0010\n\u001a\u00020\u0004X\u0082T\u00a2\u0006\u0002\n\u0000R\u000e\u0010\u000b\u001a\u00020\u0004X\u0082T\u00a2\u0006\u0002\n\u0000R\u000e\u0010\f\u001a\u00020\u0004X\u0082T\u00a2\u0006\u0002\n\u0000R\u000e\u0010\r\u001a\u00020\u0004X\u0082T\u00a2\u0006\u0002\n\u0000R\u000e\u0010\u000e\u001a\u00020\u0004X\u0082T\u00a2\u0006\u0002\n\u0000R\u000e\u0010\u000f\u001a\u00020\u0004X\u0082T\u00a2\u0006\u0002\n\u0000R\u000e\u0010\u0010\u001a\u00020\u0004X\u0082T\u00a2\u0006\u0002\n\u0000R\u000e\u0010\u0011\u001a\u00020\u0004X\u0082T\u00a2\u0006\u0002\n\u0000R\u000e\u0010\u0012\u001a\u00020\u0004X\u0082T\u00a2\u0006\u0002\n\u0000R\u000e\u0010\u0013\u001a\u00020\u0004X\u0082T\u00a2\u0006\u0002\n\u0000R\u000e\u0010\u0014\u001a\u00020\u0004X\u0082T\u00a2\u0006\u0002\n\u0000R\u000e\u0010\u0015\u001a\u00020\u0004X\u0082T\u00a2\u0006\u0002\n\u0000R\u000e\u0010\u0016\u001a\u00020\u0004X\u0082T\u00a2\u0006\u0002\n\u0000R\u000e\u0010\u0017\u001a\u00020\u0004X\u0082T\u00a2\u0006\u0002\n\u0000R\u000e\u0010\u0018\u001a\u00020\u0004X\u0082T\u00a2\u0006\u0002\n\u0000R\u000e\u0010\u0019\u001a\u00020\u0004X\u0082T\u00a2\u0006\u0002\n\u0000\u00a8\u0006("}, d2={"Ldorkbox/util/URLDecoder;", "", "()V", "byteB", "", "byteC", "byte_0", "byte_1", "byte_2", "byte_3", "byte_4", "byte_5", "byte_6", "byte_7", "byte_8", "byte_9", "byte_A", "byte_D", "byte_E", "byte_F", "byte_a", "byte_b", "byte_c", "byte_d", "byte_e", "byte_f", "decodePath", "", "path", "charset", "Ljava/nio/charset/Charset;", "decodeQuery", "query", "decodeURL", "url", "decodeURLEncoded", "part", "", "hexToByte", "b", "Utilities"})
public final class URLDecoder {
    @NotNull
    public static final URLDecoder INSTANCE = new URLDecoder();
    private static final byte byte_0 = 48;
    private static final byte byte_1 = 49;
    private static final byte byte_2 = 50;
    private static final byte byte_3 = 51;
    private static final byte byte_4 = 52;
    private static final byte byte_5 = 53;
    private static final byte byte_6 = 54;
    private static final byte byte_7 = 55;
    private static final byte byte_8 = 56;
    private static final byte byte_9 = 57;
    private static final byte byte_a = 97;
    private static final byte byte_b = 98;
    private static final byte byte_c = 99;
    private static final byte byte_d = 100;
    private static final byte byte_e = 101;
    private static final byte byte_f = 102;
    private static final byte byte_A = 65;
    private static final byte byteB = 66;
    private static final byte byteC = 67;
    private static final byte byte_D = 68;
    private static final byte byte_E = 69;
    private static final byte byte_F = 70;

    private URLDecoder() {
    }

    @NotNull
    public final String decodeURL(@NotNull String url, @NotNull Charset charset) throws URISyntaxException {
        Intrinsics.checkNotNullParameter((Object)url, (String)"url");
        Intrinsics.checkNotNullParameter((Object)charset, (String)"charset");
        int queryPart = StringsKt.indexOf$default((CharSequence)url, (char)'?', (int)0, (boolean)false, (int)6, null);
        String query = null;
        String path = url;
        if (queryPart != -1) {
            String string = url.substring(queryPart + 1);
            Intrinsics.checkNotNullExpressionValue((Object)string, (String)"this as java.lang.String).substring(startIndex)");
            query = string;
            String string2 = url.substring(0, queryPart);
            Intrinsics.checkNotNullExpressionValue((Object)string2, (String)"this as java.lang.String\u2026ing(startIndex, endIndex)");
            path = string2;
        }
        String decodedPath = this.decodePath(path, charset);
        return query != null ? decodedPath + '?' + this.decodeQuery(query, charset) : decodedPath;
    }

    @NotNull
    public final String decodePath(@NotNull String path, @NotNull Charset charset) throws URISyntaxException {
        Intrinsics.checkNotNullParameter((Object)path, (String)"path");
        Intrinsics.checkNotNullParameter((Object)charset, (String)"charset");
        return this.decodeURLEncoded(path, false, charset);
    }

    @NotNull
    public final String decodeQuery(@NotNull String query, @NotNull Charset charset) throws URISyntaxException {
        Intrinsics.checkNotNullParameter((Object)query, (String)"query");
        Intrinsics.checkNotNullParameter((Object)charset, (String)"charset");
        return this.decodeURLEncoded(query, true, charset);
    }

    @NotNull
    public final String decodeURLEncoded(@NotNull String part, boolean query, @NotNull Charset charset) throws URISyntaxException {
        String string;
        Intrinsics.checkNotNullParameter((Object)part, (String)"part");
        Intrinsics.checkNotNullParameter((Object)charset, (String)"charset");
        try {
            byte[] byArray = part.getBytes(Charsets.US_ASCII);
            Intrinsics.checkNotNullExpressionValue((Object)byArray, (String)"this as java.lang.String).getBytes(charset)");
            byte[] ascii = byArray;
            byte[] decoded = new byte[ascii.length];
            int j = 0;
            int i = 0;
            while (i < ascii.length) {
                if (ascii[i] == 37) {
                    if (i + 2 >= ascii.length) {
                        throw new URISyntaxException(part, "Invalid URL-encoded string at char " + i);
                    }
                    byte first = ascii[++i];
                    byte second = ascii[++i];
                    decoded[j] = (byte)(this.hexToByte(first) * 16 + this.hexToByte(second));
                } else {
                    decoded[j] = query && ascii[i] == 43 ? 32 : ascii[i];
                }
                ++i;
                ++j;
            }
            string = new String(decoded, 0, j, charset);
        }
        catch (UnsupportedEncodingException x) {
            throw new URISyntaxException(part, "Invalid encoding: " + charset);
        }
        return string;
    }

    private final byte hexToByte(byte b) throws URISyntaxException {
        byte by = b;
        if (by == 48) {
            return 0;
        }
        if (by == 49) {
            return 1;
        }
        if (by == 50) {
            return 2;
        }
        if (by == 51) {
            return 3;
        }
        if (by == 52) {
            return 4;
        }
        if (by == 53) {
            return 5;
        }
        if (by == 54) {
            return 6;
        }
        if (by == 55) {
            return 7;
        }
        if (by == 56) {
            return 8;
        }
        if (by == 57) {
            return 9;
        }
        if (by == 97 ? true : by == 65) {
            return 10;
        }
        if (by == 98 ? true : by == 66) {
            return 11;
        }
        if (by == 99 ? true : by == 67) {
            return 12;
        }
        if (by == 100 ? true : by == 68) {
            return 13;
        }
        if (by == 101 ? true : by == 69) {
            return 14;
        }
        if (by == 102 ? true : by == 70) {
            return 15;
        }
        throw new URISyntaxException(String.valueOf(b), "Invalid URL-encoded string");
    }
}

