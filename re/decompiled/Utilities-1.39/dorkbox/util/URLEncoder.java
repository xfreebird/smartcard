/*
 * Decompiled with CFR 0.152.
 * 
 * Could not load the following classes:
 *  kotlin.Metadata
 *  kotlin.jvm.internal.Intrinsics
 *  org.jetbrains.annotations.NotNull
 */
package dorkbox.util;

import java.io.UnsupportedEncodingException;
import java.nio.charset.Charset;
import java.util.BitSet;
import kotlin.Metadata;
import kotlin.jvm.internal.Intrinsics;
import org.jetbrains.annotations.NotNull;

@Metadata(mv={1, 7, 1}, k=1, xi=48, d1={"\u0000$\n\u0002\u0018\u0002\n\u0002\u0010\u0000\n\u0002\b\u0002\n\u0002\u0018\u0002\n\u0002\b\u0011\n\u0002\u0010\u000e\n\u0002\b\u0002\n\u0002\u0018\u0002\n\u0002\b\u0003\b\u00c6\u0002\u0018\u00002\u00020\u0001B\u0007\b\u0002\u00a2\u0006\u0002\u0010\u0002J\u0016\u0010\u0015\u001a\u00020\u00162\u0006\u0010\u0017\u001a\u00020\u00162\u0006\u0010\u0018\u001a\u00020\u0019J\u0016\u0010\u001a\u001a\u00020\u00162\u0006\u0010\u001b\u001a\u00020\u00162\u0006\u0010\u0018\u001a\u00020\u0019R\u0011\u0010\u0003\u001a\u00020\u0004\u00a2\u0006\b\n\u0000\u001a\u0004\b\u0005\u0010\u0006R\u0011\u0010\u0007\u001a\u00020\u0004\u00a2\u0006\b\n\u0000\u001a\u0004\b\b\u0010\u0006R\u0011\u0010\t\u001a\u00020\u0004\u00a2\u0006\b\n\u0000\u001a\u0004\b\n\u0010\u0006R\u0011\u0010\u000b\u001a\u00020\u0004\u00a2\u0006\b\n\u0000\u001a\u0004\b\f\u0010\u0006R\u0011\u0010\r\u001a\u00020\u0004\u00a2\u0006\b\n\u0000\u001a\u0004\b\u000e\u0010\u0006R\u0011\u0010\u000f\u001a\u00020\u0004\u00a2\u0006\b\n\u0000\u001a\u0004\b\u0010\u0010\u0006R\u0011\u0010\u0011\u001a\u00020\u0004\u00a2\u0006\b\n\u0000\u001a\u0004\b\u0012\u0010\u0006R\u0011\u0010\u0013\u001a\u00020\u0004\u00a2\u0006\b\n\u0000\u001a\u0004\b\u0014\u0010\u0006\u00a8\u0006\u001c"}, d2={"Ldorkbox/util/URLEncoder;", "", "()V", "ALPHA", "Ljava/util/BitSet;", "getALPHA", "()Ljava/util/BitSet;", "ALPHANUM", "getALPHANUM", "DIGIT", "getDIGIT", "LOW_ALPHA", "getLOW_ALPHA", "MARK", "getMARK", "PCHAR", "getPCHAR", "UNRESERVED", "getUNRESERVED", "UP_ALPHA", "getUP_ALPHA", "encodePathParam", "", "pathParam", "charset", "Ljava/nio/charset/Charset;", "encodePathSegment", "pathSegment", "Utilities"})
public final class URLEncoder {
    @NotNull
    public static final URLEncoder INSTANCE = new URLEncoder();
    @NotNull
    private static final BitSet MARK = new BitSet();
    @NotNull
    private static final BitSet LOW_ALPHA;
    @NotNull
    private static final BitSet UP_ALPHA;
    @NotNull
    private static final BitSet ALPHA;
    @NotNull
    private static final BitSet DIGIT;
    @NotNull
    private static final BitSet ALPHANUM;
    @NotNull
    private static final BitSet UNRESERVED;
    @NotNull
    private static final BitSet PCHAR;

    private URLEncoder() {
    }

    @NotNull
    public final BitSet getMARK() {
        return MARK;
    }

    @NotNull
    public final BitSet getLOW_ALPHA() {
        return LOW_ALPHA;
    }

    @NotNull
    public final BitSet getUP_ALPHA() {
        return UP_ALPHA;
    }

    @NotNull
    public final BitSet getALPHA() {
        return ALPHA;
    }

    @NotNull
    public final BitSet getDIGIT() {
        return DIGIT;
    }

    @NotNull
    public final BitSet getALPHANUM() {
        return ALPHANUM;
    }

    @NotNull
    public final BitSet getUNRESERVED() {
        return UNRESERVED;
    }

    @NotNull
    public final BitSet getPCHAR() {
        return PCHAR;
    }

    @NotNull
    public final String encodePathParam(@NotNull String pathParam, @NotNull Charset charset) throws UnsupportedEncodingException {
        Intrinsics.checkNotNullParameter((Object)pathParam, (String)"pathParam");
        Intrinsics.checkNotNullParameter((Object)charset, (String)"charset");
        return this.encodePathSegment(pathParam, charset);
    }

    @NotNull
    public final String encodePathSegment(@NotNull String pathSegment, @NotNull Charset charset) throws UnsupportedEncodingException {
        Intrinsics.checkNotNullParameter((Object)pathSegment, (String)"pathSegment");
        Intrinsics.checkNotNullParameter((Object)charset, (String)"charset");
        StringBuffer encoded = new StringBuffer(pathSegment.length() * 3);
        char[] cArray = pathSegment.toCharArray();
        Intrinsics.checkNotNullExpressionValue((Object)cArray, (String)"this as java.lang.String).toCharArray()");
        for (char c : cArray) {
            byte[] bytes;
            if (PCHAR.get(c)) {
                encoded.append(c);
                continue;
            }
            Intrinsics.checkNotNullExpressionValue((Object)String.valueOf(c).getBytes(charset), (String)"this as java.lang.String).getBytes(charset)");
            for (byte b : bytes) {
                int u8 = b & 0xFF;
                encoded.append("%");
                if (u8 < 16) {
                    encoded.append("0");
                }
                encoded.append(Integer.toHexString(u8));
            }
        }
        String string = encoded.toString();
        Intrinsics.checkNotNullExpressionValue((Object)string, (String)"encoded.toString()");
        return string;
    }

    static {
        MARK.set(45);
        MARK.set(95);
        MARK.set(46);
        MARK.set(33);
        MARK.set(126);
        MARK.set(42);
        MARK.set(39);
        MARK.set(40);
        MARK.set(41);
        LOW_ALPHA = new BitSet();
        LOW_ALPHA.set(97);
        LOW_ALPHA.set(98);
        LOW_ALPHA.set(99);
        LOW_ALPHA.set(100);
        LOW_ALPHA.set(101);
        LOW_ALPHA.set(102);
        LOW_ALPHA.set(103);
        LOW_ALPHA.set(104);
        LOW_ALPHA.set(105);
        LOW_ALPHA.set(106);
        LOW_ALPHA.set(107);
        LOW_ALPHA.set(108);
        LOW_ALPHA.set(109);
        LOW_ALPHA.set(110);
        LOW_ALPHA.set(111);
        LOW_ALPHA.set(112);
        LOW_ALPHA.set(113);
        LOW_ALPHA.set(114);
        LOW_ALPHA.set(115);
        LOW_ALPHA.set(116);
        LOW_ALPHA.set(117);
        LOW_ALPHA.set(118);
        LOW_ALPHA.set(119);
        LOW_ALPHA.set(120);
        LOW_ALPHA.set(121);
        LOW_ALPHA.set(122);
        UP_ALPHA = new BitSet();
        UP_ALPHA.set(65);
        UP_ALPHA.set(66);
        UP_ALPHA.set(67);
        UP_ALPHA.set(68);
        UP_ALPHA.set(69);
        UP_ALPHA.set(70);
        UP_ALPHA.set(71);
        UP_ALPHA.set(72);
        UP_ALPHA.set(73);
        UP_ALPHA.set(74);
        UP_ALPHA.set(75);
        UP_ALPHA.set(76);
        UP_ALPHA.set(77);
        UP_ALPHA.set(78);
        UP_ALPHA.set(79);
        UP_ALPHA.set(80);
        UP_ALPHA.set(81);
        UP_ALPHA.set(82);
        UP_ALPHA.set(83);
        UP_ALPHA.set(84);
        UP_ALPHA.set(85);
        UP_ALPHA.set(86);
        UP_ALPHA.set(87);
        UP_ALPHA.set(88);
        UP_ALPHA.set(89);
        UP_ALPHA.set(90);
        ALPHA = new BitSet();
        ALPHA.or(LOW_ALPHA);
        ALPHA.or(UP_ALPHA);
        DIGIT = new BitSet();
        DIGIT.set(48);
        DIGIT.set(49);
        DIGIT.set(50);
        DIGIT.set(51);
        DIGIT.set(52);
        DIGIT.set(53);
        DIGIT.set(54);
        DIGIT.set(55);
        DIGIT.set(56);
        DIGIT.set(57);
        ALPHANUM = new BitSet();
        ALPHANUM.or(ALPHA);
        ALPHANUM.or(DIGIT);
        UNRESERVED = new BitSet();
        UNRESERVED.or(ALPHANUM);
        UNRESERVED.or(MARK);
        PCHAR = new BitSet();
        PCHAR.or(UNRESERVED);
        PCHAR.set(58);
        PCHAR.set(64);
        PCHAR.set(38);
        PCHAR.set(61);
        PCHAR.set(43);
        PCHAR.set(36);
        PCHAR.set(44);
    }
}

