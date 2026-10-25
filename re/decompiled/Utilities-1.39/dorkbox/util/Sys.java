/*
 * Decompiled with CFR 0.152.
 * 
 * Could not load the following classes:
 *  dorkbox.os.OS
 */
package dorkbox.util;

import dorkbox.os.OS;
import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.lang.reflect.Field;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;
import java.util.Map;
import java.util.concurrent.TimeUnit;

public final class Sys {
    public static final int KILOBYTE = 1024;
    public static final int MEGABYTE = 0x100000;
    public static final int GIGABYTE = 0x40000000;
    public static final long TERABYTE = 0x10000000000L;
    public static final char[] HEX_CHARS = new char[]{'0', '1', '2', '3', '4', '5', '6', '7', '8', '9', 'A', 'B', 'C', 'D', 'E', 'F'};

    public static char[] convertStringToChars(String string) {
        char[] charArray = string.toCharArray();
        Sys.eraseString(string);
        return charArray;
    }

    public static void eraseString(String string) {
        try {
            Field valueField = String.class.getDeclaredField("value");
            valueField.setAccessible(true);
            char[] chars = (char[])valueField.get(string);
            Arrays.fill(chars, '*');
            valueField.set(string, new char[0]);
            try {
                Field countField = String.class.getDeclaredField("count");
                countField.setAccessible(true);
                countField.set(string, 0);
            }
            catch (Exception countField) {
                // empty catch block
            }
            Field hashField = String.class.getDeclaredField("hash");
            hashField.setAccessible(true);
            hashField.set(string, 0);
        }
        catch (SecurityException e) {
            e.printStackTrace();
        }
        catch (NoSuchFieldException e) {
            e.printStackTrace();
        }
        catch (IllegalArgumentException e) {
            e.printStackTrace();
        }
        catch (IllegalAccessException e) {
            e.printStackTrace();
        }
    }

    public static String replaceStringFast(String string, Map<String, String> replacements) {
        StringBuilder sb = new StringBuilder(string);
        for (Map.Entry<String, String> entry : replacements.entrySet()) {
            String key = entry.getKey();
            String value = entry.getValue();
            int start = sb.indexOf(key, 0);
            while (start > -1) {
                int end = start + key.length();
                int nextSearchStart = start + value.length();
                sb.replace(start, end, value);
                start = sb.indexOf(key, nextSearchStart);
            }
        }
        return sb.toString();
    }

    public static int searchStringFast(String string, char c) {
        int length = string.length();
        for (int i = 0; i < length; ++i) {
            if (string.charAt(i) != c) continue;
            return i;
        }
        return -1;
    }

    public static String getSizePretty(long size) {
        if (size > 0x10000000000L) {
            return String.format("%2.2fTB", (double)size / 1.099511627776E12);
        }
        if (size > 0x40000000L) {
            return String.format("%2.2fGB", (double)size / 1.073741824E9);
        }
        if (size > 0x100000L) {
            return String.format("%2.2fMB", (double)size / 1048576.0);
        }
        if (size > 1024L) {
            return String.format("%2.2fKB", (double)size / 1024.0);
        }
        return String.valueOf(size) + "B";
    }

    public static String getTimePretty(long nanoSeconds) {
        String text;
        TimeUnit unit;
        if (TimeUnit.DAYS.convert(nanoSeconds, TimeUnit.NANOSECONDS) > 0L) {
            unit = TimeUnit.DAYS;
            text = "d";
        } else if (TimeUnit.HOURS.convert(nanoSeconds, TimeUnit.NANOSECONDS) > 0L) {
            unit = TimeUnit.HOURS;
            text = "h";
        } else if (TimeUnit.MINUTES.convert(nanoSeconds, TimeUnit.NANOSECONDS) > 0L) {
            unit = TimeUnit.MINUTES;
            text = "min";
        } else if (TimeUnit.SECONDS.convert(nanoSeconds, TimeUnit.NANOSECONDS) > 0L) {
            unit = TimeUnit.SECONDS;
            text = "s";
        } else if (TimeUnit.MILLISECONDS.convert(nanoSeconds, TimeUnit.NANOSECONDS) > 0L) {
            unit = TimeUnit.MILLISECONDS;
            text = "ms";
        } else if (TimeUnit.MICROSECONDS.convert(nanoSeconds, TimeUnit.NANOSECONDS) > 0L) {
            unit = TimeUnit.MICROSECONDS;
            text = "\u03bcs";
        } else {
            unit = TimeUnit.NANOSECONDS;
            text = "ns";
        }
        double value = (double)nanoSeconds / (double)TimeUnit.NANOSECONDS.convert(1L, unit);
        return String.format("%.4g" + text, value);
    }

    public static String getTimePrettyFull(long nanoSeconds) {
        String text;
        TimeUnit unit;
        if (TimeUnit.DAYS.convert(nanoSeconds, TimeUnit.NANOSECONDS) > 0L) {
            unit = TimeUnit.DAYS;
            text = "day";
        } else if (TimeUnit.HOURS.convert(nanoSeconds, TimeUnit.NANOSECONDS) > 0L) {
            unit = TimeUnit.HOURS;
            text = "hour";
        } else if (TimeUnit.MINUTES.convert(nanoSeconds, TimeUnit.NANOSECONDS) > 0L) {
            unit = TimeUnit.MINUTES;
            text = "minute";
        } else if (TimeUnit.SECONDS.convert(nanoSeconds, TimeUnit.NANOSECONDS) > 0L) {
            unit = TimeUnit.SECONDS;
            text = "second";
        } else if (TimeUnit.MILLISECONDS.convert(nanoSeconds, TimeUnit.NANOSECONDS) > 0L) {
            unit = TimeUnit.MILLISECONDS;
            text = "milli-second";
        } else if (TimeUnit.MICROSECONDS.convert(nanoSeconds, TimeUnit.NANOSECONDS) > 0L) {
            unit = TimeUnit.MICROSECONDS;
            text = "micro-second";
        } else {
            unit = TimeUnit.NANOSECONDS;
            text = "nano-second";
        }
        double value = (double)nanoSeconds / (double)TimeUnit.NANOSECONDS.convert(1L, unit);
        if (value > 1.0) {
            text = text + "s";
        }
        return String.format("%.4g " + text, value);
    }

    public static byte[] getBytesFromStream(InputStream inputStream) throws IOException {
        int read2;
        ByteArrayOutputStream baos = new ByteArrayOutputStream(8192);
        byte[] buffer = new byte[4096];
        while ((read2 = inputStream.read(buffer)) > 0) {
            baos.write(buffer, 0, read2);
        }
        baos.flush();
        inputStream.close();
        return baos.toByteArray();
    }

    public static byte[] copyBytes(byte[] src) {
        return Sys.copyBytes(src, 0);
    }

    public static byte[] copyBytes(byte[] src, int position) {
        int length = src.length - position;
        byte[] b = new byte[length];
        System.arraycopy(src, position, b, 0, length);
        return b;
    }

    public static byte[] concatBytes(byte[] ... arrayBytes) {
        int length = 0;
        for (byte[] bytes : arrayBytes) {
            length += bytes.length;
        }
        byte[] concatBytes = new byte[length];
        length = 0;
        for (byte[] bytes : arrayBytes) {
            System.arraycopy(bytes, 0, concatBytes, length, bytes.length);
            length += bytes.length;
        }
        return concatBytes;
    }

    public static byte[] charToBytes16(char[] text) {
        byte[] bytes = new byte[text.length * 2];
        for (int i = 0; i < text.length; ++i) {
            bytes[2 * i] = (byte)(text[i] >> 8);
            bytes[2 * i + 1] = (byte)text[i];
        }
        return bytes;
    }

    public static byte[] intsToBytes(int[] ints) {
        int length = ints.length;
        byte[] bytes = new byte[length];
        for (int i = 0; i < length; ++i) {
            int intValue = ints[i];
            if (intValue < 0 || intValue > 255) {
                System.err.println("WARNING: int at index " + i + "(" + intValue + ") was not a valid byte value (0-255)");
                return new byte[length];
            }
            bytes[i] = (byte)intValue;
        }
        return bytes;
    }

    public static byte[] charToBytesRaw(char[] chars) {
        int length = chars.length;
        byte[] bytes = new byte[length];
        for (int i = 0; i < length; ++i) {
            char charValue = chars[i];
            bytes[i] = (byte)charValue;
        }
        return bytes;
    }

    public static int[] bytesToInts(byte[] bytes, int startPosition, int length) {
        int[] ints = new int[length];
        int endPosition = startPosition + length;
        for (int i = startPosition; i < endPosition; ++i) {
            ints[i] = bytes[i] & 0xFF;
        }
        return ints;
    }

    public static String bytesToHex(byte[] bytes) {
        return Sys.bytesToHex(bytes, 0, bytes.length, false);
    }

    public static String bytesToHex(byte[] bytes, int startPosition, int length) {
        return Sys.bytesToHex(bytes, startPosition, length, false);
    }

    public static String bytesToHex(byte[] bytes, int startPosition, int length, boolean padding) {
        int endPosition = startPosition + length;
        if (padding) {
            char[] hexString = new char[3 * length];
            int j = 0;
            for (int i = startPosition; i < endPosition; ++i) {
                hexString[j++] = HEX_CHARS[(bytes[i] & 0xF0) >> 4];
                hexString[j++] = HEX_CHARS[bytes[i] & 0xF];
                hexString[j++] = 32;
            }
            return new String(hexString);
        }
        char[] hexString = new char[2 * length];
        int j = 0;
        for (int i = startPosition; i < endPosition; ++i) {
            hexString[j++] = HEX_CHARS[(bytes[i] & 0xF0) >> 4];
            hexString[j++] = HEX_CHARS[bytes[i] & 0xF];
        }
        return new String(hexString);
    }

    public static int hexByteToInt(byte b) {
        switch (b) {
            case 48: {
                return 0;
            }
            case 49: {
                return 1;
            }
            case 50: {
                return 2;
            }
            case 51: {
                return 3;
            }
            case 52: {
                return 4;
            }
            case 53: {
                return 5;
            }
            case 54: {
                return 6;
            }
            case 55: {
                return 7;
            }
            case 56: {
                return 8;
            }
            case 57: {
                return 9;
            }
            case 65: 
            case 97: {
                return 10;
            }
            case 66: 
            case 98: {
                return 11;
            }
            case 67: 
            case 99: {
                return 12;
            }
            case 68: 
            case 100: {
                return 13;
            }
            case 69: 
            case 101: {
                return 14;
            }
            case 70: 
            case 102: {
                return 15;
            }
        }
        throw new IllegalArgumentException("Error decoding byte");
    }

    public static int hexCharToInt(char b) {
        switch (b) {
            case '0': {
                return 0;
            }
            case '1': {
                return 1;
            }
            case '2': {
                return 2;
            }
            case '3': {
                return 3;
            }
            case '4': {
                return 4;
            }
            case '5': {
                return 5;
            }
            case '6': {
                return 6;
            }
            case '7': {
                return 7;
            }
            case '8': {
                return 8;
            }
            case '9': {
                return 9;
            }
            case 'A': 
            case 'a': {
                return 10;
            }
            case 'B': 
            case 'b': {
                return 11;
            }
            case 'C': 
            case 'c': {
                return 12;
            }
            case 'D': 
            case 'd': {
                return 13;
            }
            case 'E': 
            case 'e': {
                return 14;
            }
            case 'F': 
            case 'f': {
                return 15;
            }
        }
        throw new IllegalArgumentException("Error decoding byte");
    }

    public static void hex4(char c, StringBuilder sb) {
        sb.append(HEX_CHARS[(c & 0xF000) >> 12]);
        sb.append(HEX_CHARS[(c & 0xF00) >> 8]);
        sb.append(HEX_CHARS[(c & 0xF0) >> 4]);
        sb.append(HEX_CHARS[c & 0xF]);
    }

    public static String toHexString(byte[] bytes) {
        char[] hexString = new char[2 * bytes.length];
        int j = 0;
        for (int i = 0; i < bytes.length; ++i) {
            hexString[j++] = HEX_CHARS[(bytes[i] & 0xF0) >> 4];
            hexString[j++] = HEX_CHARS[bytes[i] & 0xF];
        }
        return new String(hexString);
    }

    public static byte hexToByte(CharSequence s, int pos) {
        int hi = Sys.hexCharToInt(s.charAt(pos));
        int lo = Sys.hexCharToInt(s.charAt(pos + 1));
        if (hi == -1 || lo == -1) {
            throw new IllegalArgumentException(String.format("invalid hex byte '%s' at index %d of '%s'", s.subSequence(pos, pos + 2), pos, s));
        }
        return (byte)((hi << 4) + lo);
    }

    public static byte[] hexToBytes(CharSequence hex) {
        return Sys.hexToBytes(hex, 0, hex.length());
    }

    public static byte[] hexToBytes(CharSequence hexDump, int fromIndex, int length) {
        if (length < 0 || (length & 1) != 0) {
            throw new IllegalArgumentException("length: " + length);
        }
        if (length == 0) {
            return new byte[0];
        }
        byte[] bytes = new byte[length >>> 1];
        for (int i = 0; i < length; i += 2) {
            bytes[i >>> 1] = Sys.hexToByte(hexDump, fromIndex + i);
        }
        return bytes;
    }

    public static void xorArrays(byte[] originalArray, byte[] keyArray) {
        int keyIndex = 0;
        int keyLength = keyArray.length;
        for (int i = 0; i < originalArray.length; ++i) {
            originalArray[i] = (byte)(originalArray[i] ^ keyArray[keyIndex++ % keyLength]);
        }
    }

    public static byte[] encodeStringArray(List<String> array) {
        int length = 0;
        for (String s : array) {
            byte[] bytes = s.getBytes();
            length += bytes.length;
        }
        if (length == 0) {
            return new byte[0];
        }
        byte[] bytes = new byte[length + array.size()];
        length = 0;
        for (String s : array) {
            byte[] sBytes = s.getBytes();
            System.arraycopy(sBytes, 0, bytes, length, sBytes.length);
            length += sBytes.length;
            bytes[length++] = 1;
        }
        return bytes;
    }

    public static ArrayList<String> decodeStringArray(byte[] bytes) {
        int length = bytes.length;
        int position = 0;
        byte token = 1;
        ArrayList<String> list = new ArrayList<String>(0);
        int last = 0;
        while (last + position < length) {
            byte b;
            if ((b = bytes[last + position++]) != token) continue;
            byte[] xx = new byte[position - 1];
            System.arraycopy(bytes, last, xx, 0, position - 1);
            list.add(new String(xx));
            last += position;
            position = 0;
        }
        return list;
    }

    public static String printArrayRaw(byte[] bytes) {
        return Sys.printArrayRaw(bytes, 0);
    }

    public static String printArrayRaw(byte[] bytes, int lineLength) {
        if (lineLength > 0) {
            int length = bytes.length;
            int comma = length - 1;
            StringBuilder builder = new StringBuilder(length + length / lineLength);
            for (int i = 0; i < length; ++i) {
                builder.append(bytes[i]);
                if (i < comma) {
                    builder.append(",");
                }
                if (i <= 0 || i % lineLength != 0) continue;
                builder.append(OS.INSTANCE.getLINE_SEPARATOR());
            }
            return builder.toString();
        }
        int length = bytes.length;
        int comma = length - 1;
        StringBuilder builder = new StringBuilder(length + length);
        for (int i = 0; i < length; ++i) {
            builder.append(bytes[i]);
            if (i >= comma) continue;
            builder.append(",");
        }
        return builder.toString();
    }

    public static void printArray(byte[] bytes) {
        Sys.printArray(bytes, bytes.length, true);
    }

    public static void printArray(byte[] bytes, int length, boolean includeByteCount) {
        Sys.printArray(bytes, 0, length, includeByteCount, 40, null);
    }

    public static void printArray(byte[] bytes, int inputOffset, int length, boolean includeByteCount) {
        Sys.printArray(bytes, inputOffset, length, includeByteCount, 40, null);
    }

    public static void printArray(byte[] bytes, int inputOffset, int length, boolean includeByteCount, int lineLength, String header) {
        int comma = length - 1;
        int builderLength = length + comma + 2;
        if (includeByteCount) {
            builderLength += 7 + Integer.toString(length).length();
        }
        if (lineLength > 0) {
            builderLength += length / lineLength;
        }
        if (header != null) {
            builderLength += header.length() + 2;
        }
        StringBuilder builder = new StringBuilder(builderLength);
        if (header != null) {
            builder.append(header).append(OS.INSTANCE.getLINE_SEPARATOR());
        }
        if (includeByteCount) {
            builder.append("Bytes: ").append(length).append(OS.INSTANCE.getLINE_SEPARATOR());
        }
        builder.append("{");
        for (int i = inputOffset; i < length; ++i) {
            builder.append(bytes[i]);
            if (i < comma) {
                builder.append(",");
            }
            if (i <= inputOffset || lineLength <= 0 || i % lineLength != 0) continue;
            builder.append(OS.INSTANCE.getLINE_SEPARATOR());
        }
        builder.append("}");
        System.err.println(builder.toString());
    }

    public static void throwException(Throwable t) {
        Sys.throwException0(t);
    }

    private static <E extends Throwable> void throwException0(Throwable t) throws E {
        throw t;
    }

    private Sys() {
    }
}

