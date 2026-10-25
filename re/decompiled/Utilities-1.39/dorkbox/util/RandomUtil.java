/*
 * Decompiled with CFR 0.152.
 */
package dorkbox.util;

import dorkbox.util.FastThreadLocal;
import dorkbox.util.MersenneTwisterFast;

public class RandomUtil {
    private static final FastThreadLocal<MersenneTwisterFast> random = new FastThreadLocal<MersenneTwisterFast>(){

        @Override
        public MersenneTwisterFast initialValue() {
            return new MersenneTwisterFast();
        }
    };

    public static MersenneTwisterFast get() {
        return random.get();
    }

    public static int int_() {
        return RandomUtil.get().nextInt();
    }

    public static int int_(int range) {
        return RandomUtil.get().nextInt(range + 1);
    }

    public static int int_(int start, int end) {
        return start + RandomUtil.get().nextInt(end - start + 1);
    }

    public static boolean bool() {
        return RandomUtil.get().nextBoolean();
    }

    public static float float_() {
        return RandomUtil.get().nextFloat();
    }

    public static float float_(float range) {
        return RandomUtil.get().nextFloat() * range;
    }

    public static float float_(float start, float end) {
        return start + RandomUtil.get().nextFloat() * (end - start);
    }

    public static void bytes_(byte[] bytes) {
        RandomUtil.get().nextBytes(bytes);
    }
}

