/*
 * Decompiled with CFR 0.152.
 */
package dorkbox.util;

public class MathUtil {
    public static boolean isInteger(String string) {
        return MathUtil.isNumber(string, 10L);
    }

    public static boolean isLong(String string) {
        return MathUtil.isNumber(string, 19L);
    }

    public static boolean isNumber(char character) {
        return character >= '0' && character <= '9';
    }

    public static boolean isNumber(String string, long sizeLimit) {
        if (string == null) {
            return false;
        }
        if (sizeLimit <= 0L) {
            return false;
        }
        int length = string.length();
        if (length == 0) {
            return false;
        }
        int i = 0;
        if (string.charAt(0) == '-') {
            if (length == 1) {
                return false;
            }
            i = 1;
        }
        if ((long)(length - i) > sizeLimit) {
            return false;
        }
        while (i < length) {
            char c = string.charAt(i);
            if (c < '0' || c > '9') {
                return false;
            }
            ++i;
        }
        return true;
    }

    public static int numberOfDigits(long number) {
        if (number < 0L) {
            number = -number;
        }
        if (number < 10000L) {
            if (number < 100L) {
                if (number < 10L) {
                    return 1;
                }
                return 2;
            }
            if (number < 1000L) {
                return 3;
            }
            return 4;
        }
        if (number < 1000000000000L) {
            if (number < 100000000L) {
                if (number < 1000000L) {
                    if (number < 100000L) {
                        return 5;
                    }
                    return 6;
                }
                if (number < 10000000L) {
                    return 7;
                }
                return 8;
            }
            if (number < 10000000000L) {
                if (number < 1000000000L) {
                    return 9;
                }
                return 10;
            }
            if (number < 100000000000L) {
                return 11;
            }
            return 12;
        }
        if (number < 10000000000000000L) {
            if (number < 100000000000000L) {
                if (number < 10000000000000L) {
                    return 13;
                }
                return 14;
            }
            if (number < 1000000000000000L) {
                return 15;
            }
            return 16;
        }
        if (number < 1000000000000000000L) {
            if (number < 100000000000000000L) {
                return 17;
            }
            return 18;
        }
        return 19;
    }

    public static int stripTrailingNonDigits(String text) {
        int numberIndex;
        if (text == null || text.isEmpty()) {
            return 0;
        }
        int length = text.length();
        for (numberIndex = 0; numberIndex < length && Character.isDigit(text.charAt(numberIndex)); ++numberIndex) {
        }
        String substring = text.substring(0, numberIndex);
        try {
            return Integer.parseInt(substring);
        }
        catch (Exception exception) {
            return 0;
        }
    }

    public static boolean isEven(int value) {
        return (value & 1) == 0;
    }

    public static int nextPowerOfTwo(int value) {
        return 1 << 32 - Integer.numberOfLeadingZeros(value - 1);
    }

    public static boolean isPowerOfTwo(int value) {
        return value != 0 && (value & value - 1) == 0;
    }

    public static boolean intersectRect(double x1, double y1, double w1, double h1, double x2, double y2, double w2, double h2) {
        return MathUtil.intersectRange(x1, x1 + w1, x2, x2 + w2) && MathUtil.intersectRange(y1, y1 + h1, y2, y2 + h2);
    }

    public static boolean intersectRange(double ax1, double ax2, double bx1, double bx2) {
        return Math.max(ax1, bx1) <= Math.min(ax2, bx2);
    }

    public static int clamp(int value, int min, int max) {
        return Math.max(min, Math.min(max, value));
    }

    public static long clamp(long value, long min, long max) {
        return Math.max(min, Math.min(max, value));
    }

    public static float clamp(float value, float min, float max) {
        return Math.max(min, Math.min(max, value));
    }

    public static double clamp(double value, double min, double max) {
        return Math.max(min, Math.min(max, value));
    }
}

