/*
 * Decompiled with CFR 0.152.
 */
package dorkbox.util;

import java.io.DataInputStream;
import java.io.DataOutputStream;
import java.io.IOException;
import java.io.Serializable;

public strictfp class MersenneTwisterFast
implements Serializable,
Cloneable {
    private static final long serialVersionUID = -8219700664442619525L;
    private static final int N = 624;
    private static final int M = 397;
    private static final int MATRIX_A = -1727483681;
    private static final int UPPER_MASK = Integer.MIN_VALUE;
    private static final int LOWER_MASK = Integer.MAX_VALUE;
    private static final int TEMPERING_MASK_B = -1658038656;
    private static final int TEMPERING_MASK_C = -272236544;
    private int[] mt;
    private int mti;
    private int[] mag01;
    private double __nextNextGaussian;
    private boolean __haveNextNextGaussian;

    public Object clone() {
        try {
            MersenneTwisterFast f = (MersenneTwisterFast)super.clone();
            f.mt = (int[])this.mt.clone();
            f.mag01 = (int[])this.mag01.clone();
            return f;
        }
        catch (CloneNotSupportedException e) {
            throw new InternalError();
        }
    }

    public boolean stateEquals(Object o) {
        int x;
        if (o == this) {
            return true;
        }
        if (o == null || !(o instanceof MersenneTwisterFast)) {
            return false;
        }
        MersenneTwisterFast other = (MersenneTwisterFast)o;
        if (this.mti != other.mti) {
            return false;
        }
        for (x = 0; x < this.mag01.length; ++x) {
            if (this.mag01[x] == other.mag01[x]) continue;
            return false;
        }
        for (x = 0; x < this.mt.length; ++x) {
            if (this.mt[x] == other.mt[x]) continue;
            return false;
        }
        return true;
    }

    public void readState(DataInputStream stream) throws IOException {
        int x;
        int len = this.mt.length;
        for (x = 0; x < len; ++x) {
            this.mt[x] = stream.readInt();
        }
        len = this.mag01.length;
        for (x = 0; x < len; ++x) {
            this.mag01[x] = stream.readInt();
        }
        this.mti = stream.readInt();
        this.__nextNextGaussian = stream.readDouble();
        this.__haveNextNextGaussian = stream.readBoolean();
    }

    public void writeState(DataOutputStream stream) throws IOException {
        int x;
        int len = this.mt.length;
        for (x = 0; x < len; ++x) {
            stream.writeInt(this.mt[x]);
        }
        len = this.mag01.length;
        for (x = 0; x < len; ++x) {
            stream.writeInt(this.mag01[x]);
        }
        stream.writeInt(this.mti);
        stream.writeDouble(this.__nextNextGaussian);
        stream.writeBoolean(this.__haveNextNextGaussian);
    }

    public MersenneTwisterFast() {
        this(System.currentTimeMillis());
    }

    public MersenneTwisterFast(long seed) {
        this.setSeed(seed);
    }

    public MersenneTwisterFast(int[] array) {
        this.setSeed(array);
    }

    public synchronized void setSeed(long seed) {
        this.__haveNextNextGaussian = false;
        this.mt = new int[624];
        this.mag01 = new int[2];
        this.mag01[0] = 0;
        this.mag01[1] = -1727483681;
        this.mt[0] = (int)(seed & 0xFFFFFFFFFFFFFFFFL);
        this.mti = 1;
        while (this.mti < 624) {
            this.mt[this.mti] = 1812433253 * (this.mt[this.mti - 1] ^ this.mt[this.mti - 1] >>> 30) + this.mti;
            ++this.mti;
        }
    }

    public synchronized void setSeed(int[] array) {
        int k;
        if (array.length == 0) {
            throw new IllegalArgumentException("Array length must be greater than zero");
        }
        this.setSeed(19650218L);
        int i = 1;
        int j = 0;
        int n = k = 624 > array.length ? 624 : array.length;
        while (k != 0) {
            this.mt[i] = (this.mt[i] ^ (this.mt[i - 1] ^ this.mt[i - 1] >>> 30) * 1664525) + array[j] + j;
            ++j;
            if (++i >= 624) {
                this.mt[0] = this.mt[623];
                i = 1;
            }
            if (j >= array.length) {
                j = 0;
            }
            --k;
        }
        for (k = 623; k != 0; --k) {
            this.mt[i] = (this.mt[i] ^ (this.mt[i - 1] ^ this.mt[i - 1] >>> 30) * 1566083941) - i;
            if (++i < 624) continue;
            this.mt[0] = this.mt[623];
            i = 1;
        }
        this.mt[0] = Integer.MIN_VALUE;
    }

    public int nextInt() {
        int y;
        if (this.mti >= 624) {
            int kk;
            int[] mt = this.mt;
            int[] mag01 = this.mag01;
            for (kk = 0; kk < 227; ++kk) {
                y = mt[kk] & Integer.MIN_VALUE | mt[kk + 1] & Integer.MAX_VALUE;
                mt[kk] = mt[kk + 397] ^ y >>> 1 ^ mag01[y & 1];
            }
            while (kk < 623) {
                y = mt[kk] & Integer.MIN_VALUE | mt[kk + 1] & Integer.MAX_VALUE;
                mt[kk] = mt[kk + 397 - 624] ^ y >>> 1 ^ mag01[y & 1];
                ++kk;
            }
            y = mt[623] & Integer.MIN_VALUE | mt[0] & Integer.MAX_VALUE;
            mt[623] = mt[396] ^ y >>> 1 ^ mag01[y & 1];
            this.mti = 0;
        }
        y = this.mt[this.mti++];
        y ^= y >>> 11;
        y ^= y << 7 & 0x9D2C5680;
        y ^= y << 15 & 0xEFC60000;
        y ^= y >>> 18;
        return y;
    }

    public short nextShort() {
        int y;
        if (this.mti >= 624) {
            int kk;
            int[] mt = this.mt;
            int[] mag01 = this.mag01;
            for (kk = 0; kk < 227; ++kk) {
                y = mt[kk] & Integer.MIN_VALUE | mt[kk + 1] & Integer.MAX_VALUE;
                mt[kk] = mt[kk + 397] ^ y >>> 1 ^ mag01[y & 1];
            }
            while (kk < 623) {
                y = mt[kk] & Integer.MIN_VALUE | mt[kk + 1] & Integer.MAX_VALUE;
                mt[kk] = mt[kk + 397 - 624] ^ y >>> 1 ^ mag01[y & 1];
                ++kk;
            }
            y = mt[623] & Integer.MIN_VALUE | mt[0] & Integer.MAX_VALUE;
            mt[623] = mt[396] ^ y >>> 1 ^ mag01[y & 1];
            this.mti = 0;
        }
        y = this.mt[this.mti++];
        y ^= y >>> 11;
        y ^= y << 7 & 0x9D2C5680;
        y ^= y << 15 & 0xEFC60000;
        y ^= y >>> 18;
        return (short)(y >>> 16);
    }

    public char nextChar() {
        int y;
        if (this.mti >= 624) {
            int kk;
            int[] mt = this.mt;
            int[] mag01 = this.mag01;
            for (kk = 0; kk < 227; ++kk) {
                y = mt[kk] & Integer.MIN_VALUE | mt[kk + 1] & Integer.MAX_VALUE;
                mt[kk] = mt[kk + 397] ^ y >>> 1 ^ mag01[y & 1];
            }
            while (kk < 623) {
                y = mt[kk] & Integer.MIN_VALUE | mt[kk + 1] & Integer.MAX_VALUE;
                mt[kk] = mt[kk + 397 - 624] ^ y >>> 1 ^ mag01[y & 1];
                ++kk;
            }
            y = mt[623] & Integer.MIN_VALUE | mt[0] & Integer.MAX_VALUE;
            mt[623] = mt[396] ^ y >>> 1 ^ mag01[y & 1];
            this.mti = 0;
        }
        y = this.mt[this.mti++];
        y ^= y >>> 11;
        y ^= y << 7 & 0x9D2C5680;
        y ^= y << 15 & 0xEFC60000;
        y ^= y >>> 18;
        return (char)(y >>> 16);
    }

    public boolean nextBoolean() {
        int y;
        if (this.mti >= 624) {
            int kk;
            int[] mt = this.mt;
            int[] mag01 = this.mag01;
            for (kk = 0; kk < 227; ++kk) {
                y = mt[kk] & Integer.MIN_VALUE | mt[kk + 1] & Integer.MAX_VALUE;
                mt[kk] = mt[kk + 397] ^ y >>> 1 ^ mag01[y & 1];
            }
            while (kk < 623) {
                y = mt[kk] & Integer.MIN_VALUE | mt[kk + 1] & Integer.MAX_VALUE;
                mt[kk] = mt[kk + 397 - 624] ^ y >>> 1 ^ mag01[y & 1];
                ++kk;
            }
            y = mt[623] & Integer.MIN_VALUE | mt[0] & Integer.MAX_VALUE;
            mt[623] = mt[396] ^ y >>> 1 ^ mag01[y & 1];
            this.mti = 0;
        }
        y = this.mt[this.mti++];
        y ^= y >>> 11;
        y ^= y << 7 & 0x9D2C5680;
        y ^= y << 15 & 0xEFC60000;
        return (y ^= y >>> 18) >>> 31 != 0;
    }

    public boolean nextBoolean(float probability) {
        int y;
        if (probability < 0.0f || probability > 1.0f) {
            throw new IllegalArgumentException("probability must be between 0.0 and 1.0 inclusive.");
        }
        if (probability == 0.0f) {
            return false;
        }
        if (probability == 1.0f) {
            return true;
        }
        if (this.mti >= 624) {
            int kk;
            int[] mt = this.mt;
            int[] mag01 = this.mag01;
            for (kk = 0; kk < 227; ++kk) {
                y = mt[kk] & Integer.MIN_VALUE | mt[kk + 1] & Integer.MAX_VALUE;
                mt[kk] = mt[kk + 397] ^ y >>> 1 ^ mag01[y & 1];
            }
            while (kk < 623) {
                y = mt[kk] & Integer.MIN_VALUE | mt[kk + 1] & Integer.MAX_VALUE;
                mt[kk] = mt[kk + 397 - 624] ^ y >>> 1 ^ mag01[y & 1];
                ++kk;
            }
            y = mt[623] & Integer.MIN_VALUE | mt[0] & Integer.MAX_VALUE;
            mt[623] = mt[396] ^ y >>> 1 ^ mag01[y & 1];
            this.mti = 0;
        }
        y = this.mt[this.mti++];
        y ^= y >>> 11;
        y ^= y << 7 & 0x9D2C5680;
        y ^= y << 15 & 0xEFC60000;
        return (float)((y ^= y >>> 18) >>> 8) / 1.6777216E7f < probability;
    }

    public boolean nextBoolean(double probability) {
        int z;
        int y;
        int kk;
        int[] mag01;
        int[] mt;
        if (probability < 0.0 || probability > 1.0) {
            throw new IllegalArgumentException("probability must be between 0.0 and 1.0 inclusive.");
        }
        if (probability == 0.0) {
            return false;
        }
        if (probability == 1.0) {
            return true;
        }
        if (this.mti >= 624) {
            mt = this.mt;
            mag01 = this.mag01;
            for (kk = 0; kk < 227; ++kk) {
                y = mt[kk] & Integer.MIN_VALUE | mt[kk + 1] & Integer.MAX_VALUE;
                mt[kk] = mt[kk + 397] ^ y >>> 1 ^ mag01[y & 1];
            }
            while (kk < 623) {
                y = mt[kk] & Integer.MIN_VALUE | mt[kk + 1] & Integer.MAX_VALUE;
                mt[kk] = mt[kk + 397 - 624] ^ y >>> 1 ^ mag01[y & 1];
                ++kk;
            }
            y = mt[623] & Integer.MIN_VALUE | mt[0] & Integer.MAX_VALUE;
            mt[623] = mt[396] ^ y >>> 1 ^ mag01[y & 1];
            this.mti = 0;
        }
        y = this.mt[this.mti++];
        y ^= y >>> 11;
        y ^= y << 7 & 0x9D2C5680;
        y ^= y << 15 & 0xEFC60000;
        y ^= y >>> 18;
        if (this.mti >= 624) {
            mt = this.mt;
            mag01 = this.mag01;
            for (kk = 0; kk < 227; ++kk) {
                z = mt[kk] & Integer.MIN_VALUE | mt[kk + 1] & Integer.MAX_VALUE;
                mt[kk] = mt[kk + 397] ^ z >>> 1 ^ mag01[z & 1];
            }
            while (kk < 623) {
                z = mt[kk] & Integer.MIN_VALUE | mt[kk + 1] & Integer.MAX_VALUE;
                mt[kk] = mt[kk + 397 - 624] ^ z >>> 1 ^ mag01[z & 1];
                ++kk;
            }
            z = mt[623] & Integer.MIN_VALUE | mt[0] & Integer.MAX_VALUE;
            mt[623] = mt[396] ^ z >>> 1 ^ mag01[z & 1];
            this.mti = 0;
        }
        z = this.mt[this.mti++];
        z ^= z >>> 11;
        z ^= z << 7 & 0x9D2C5680;
        z ^= z << 15 & 0xEFC60000;
        return (double)(((long)(y >>> 6) << 27) + (long)((z ^= z >>> 18) >>> 5)) / 9.007199254740992E15 < probability;
    }

    public byte nextByte() {
        int y;
        if (this.mti >= 624) {
            int kk;
            int[] mt = this.mt;
            int[] mag01 = this.mag01;
            for (kk = 0; kk < 227; ++kk) {
                y = mt[kk] & Integer.MIN_VALUE | mt[kk + 1] & Integer.MAX_VALUE;
                mt[kk] = mt[kk + 397] ^ y >>> 1 ^ mag01[y & 1];
            }
            while (kk < 623) {
                y = mt[kk] & Integer.MIN_VALUE | mt[kk + 1] & Integer.MAX_VALUE;
                mt[kk] = mt[kk + 397 - 624] ^ y >>> 1 ^ mag01[y & 1];
                ++kk;
            }
            y = mt[623] & Integer.MIN_VALUE | mt[0] & Integer.MAX_VALUE;
            mt[623] = mt[396] ^ y >>> 1 ^ mag01[y & 1];
            this.mti = 0;
        }
        y = this.mt[this.mti++];
        y ^= y >>> 11;
        y ^= y << 7 & 0x9D2C5680;
        y ^= y << 15 & 0xEFC60000;
        y ^= y >>> 18;
        return (byte)(y >>> 24);
    }

    public void nextBytes(byte[] bytes) {
        for (int x = 0; x < bytes.length; ++x) {
            int y;
            if (this.mti >= 624) {
                int kk;
                int[] mt = this.mt;
                int[] mag01 = this.mag01;
                for (kk = 0; kk < 227; ++kk) {
                    y = mt[kk] & Integer.MIN_VALUE | mt[kk + 1] & Integer.MAX_VALUE;
                    mt[kk] = mt[kk + 397] ^ y >>> 1 ^ mag01[y & 1];
                }
                while (kk < 623) {
                    y = mt[kk] & Integer.MIN_VALUE | mt[kk + 1] & Integer.MAX_VALUE;
                    mt[kk] = mt[kk + 397 - 624] ^ y >>> 1 ^ mag01[y & 1];
                    ++kk;
                }
                y = mt[623] & Integer.MIN_VALUE | mt[0] & Integer.MAX_VALUE;
                mt[623] = mt[396] ^ y >>> 1 ^ mag01[y & 1];
                this.mti = 0;
            }
            y = this.mt[this.mti++];
            y ^= y >>> 11;
            y ^= y << 7 & 0x9D2C5680;
            y ^= y << 15 & 0xEFC60000;
            y ^= y >>> 18;
            bytes[x] = (byte)(y >>> 24);
        }
    }

    public long nextLong() {
        int z;
        int y;
        int kk;
        int[] mag01;
        int[] mt;
        if (this.mti >= 624) {
            mt = this.mt;
            mag01 = this.mag01;
            for (kk = 0; kk < 227; ++kk) {
                y = mt[kk] & Integer.MIN_VALUE | mt[kk + 1] & Integer.MAX_VALUE;
                mt[kk] = mt[kk + 397] ^ y >>> 1 ^ mag01[y & 1];
            }
            while (kk < 623) {
                y = mt[kk] & Integer.MIN_VALUE | mt[kk + 1] & Integer.MAX_VALUE;
                mt[kk] = mt[kk + 397 - 624] ^ y >>> 1 ^ mag01[y & 1];
                ++kk;
            }
            y = mt[623] & Integer.MIN_VALUE | mt[0] & Integer.MAX_VALUE;
            mt[623] = mt[396] ^ y >>> 1 ^ mag01[y & 1];
            this.mti = 0;
        }
        y = this.mt[this.mti++];
        y ^= y >>> 11;
        y ^= y << 7 & 0x9D2C5680;
        y ^= y << 15 & 0xEFC60000;
        y ^= y >>> 18;
        if (this.mti >= 624) {
            mt = this.mt;
            mag01 = this.mag01;
            for (kk = 0; kk < 227; ++kk) {
                z = mt[kk] & Integer.MIN_VALUE | mt[kk + 1] & Integer.MAX_VALUE;
                mt[kk] = mt[kk + 397] ^ z >>> 1 ^ mag01[z & 1];
            }
            while (kk < 623) {
                z = mt[kk] & Integer.MIN_VALUE | mt[kk + 1] & Integer.MAX_VALUE;
                mt[kk] = mt[kk + 397 - 624] ^ z >>> 1 ^ mag01[z & 1];
                ++kk;
            }
            z = mt[623] & Integer.MIN_VALUE | mt[0] & Integer.MAX_VALUE;
            mt[623] = mt[396] ^ z >>> 1 ^ mag01[z & 1];
            this.mti = 0;
        }
        z = this.mt[this.mti++];
        z ^= z >>> 11;
        z ^= z << 7 & 0x9D2C5680;
        z ^= z << 15 & 0xEFC60000;
        z ^= z >>> 18;
        return ((long)y << 32) + (long)z;
    }

    public long nextLong(long n) {
        long val;
        int z;
        int y;
        long bits;
        if (n <= 0L) {
            throw new IllegalArgumentException("n must be positive, got: " + n);
        }
        do {
            int kk;
            int[] mag01;
            int[] mt;
            if (this.mti >= 624) {
                mt = this.mt;
                mag01 = this.mag01;
                for (kk = 0; kk < 227; ++kk) {
                    y = mt[kk] & Integer.MIN_VALUE | mt[kk + 1] & Integer.MAX_VALUE;
                    mt[kk] = mt[kk + 397] ^ y >>> 1 ^ mag01[y & 1];
                }
                while (kk < 623) {
                    y = mt[kk] & Integer.MIN_VALUE | mt[kk + 1] & Integer.MAX_VALUE;
                    mt[kk] = mt[kk + 397 - 624] ^ y >>> 1 ^ mag01[y & 1];
                    ++kk;
                }
                y = mt[623] & Integer.MIN_VALUE | mt[0] & Integer.MAX_VALUE;
                mt[623] = mt[396] ^ y >>> 1 ^ mag01[y & 1];
                this.mti = 0;
            }
            y = this.mt[this.mti++];
            y ^= y >>> 11;
            y ^= y << 7 & 0x9D2C5680;
            y ^= y << 15 & 0xEFC60000;
            y ^= y >>> 18;
            if (this.mti >= 624) {
                mt = this.mt;
                mag01 = this.mag01;
                for (kk = 0; kk < 227; ++kk) {
                    z = mt[kk] & Integer.MIN_VALUE | mt[kk + 1] & Integer.MAX_VALUE;
                    mt[kk] = mt[kk + 397] ^ z >>> 1 ^ mag01[z & 1];
                }
                while (kk < 623) {
                    z = mt[kk] & Integer.MIN_VALUE | mt[kk + 1] & Integer.MAX_VALUE;
                    mt[kk] = mt[kk + 397 - 624] ^ z >>> 1 ^ mag01[z & 1];
                    ++kk;
                }
                z = mt[623] & Integer.MIN_VALUE | mt[0] & Integer.MAX_VALUE;
                mt[623] = mt[396] ^ z >>> 1 ^ mag01[z & 1];
                this.mti = 0;
            }
            z = this.mt[this.mti++];
            z ^= z >>> 11;
            z ^= z << 7 & 0x9D2C5680;
            z ^= z << 15 & 0xEFC60000;
        } while ((bits = ((long)y << 32) + (long)(z ^= z >>> 18) >>> 1) - (val = bits % n) + n - 1L < 0L);
        return val;
    }

    public double nextDouble() {
        int z;
        int y;
        int kk;
        int[] mag01;
        int[] mt;
        if (this.mti >= 624) {
            mt = this.mt;
            mag01 = this.mag01;
            for (kk = 0; kk < 227; ++kk) {
                y = mt[kk] & Integer.MIN_VALUE | mt[kk + 1] & Integer.MAX_VALUE;
                mt[kk] = mt[kk + 397] ^ y >>> 1 ^ mag01[y & 1];
            }
            while (kk < 623) {
                y = mt[kk] & Integer.MIN_VALUE | mt[kk + 1] & Integer.MAX_VALUE;
                mt[kk] = mt[kk + 397 - 624] ^ y >>> 1 ^ mag01[y & 1];
                ++kk;
            }
            y = mt[623] & Integer.MIN_VALUE | mt[0] & Integer.MAX_VALUE;
            mt[623] = mt[396] ^ y >>> 1 ^ mag01[y & 1];
            this.mti = 0;
        }
        y = this.mt[this.mti++];
        y ^= y >>> 11;
        y ^= y << 7 & 0x9D2C5680;
        y ^= y << 15 & 0xEFC60000;
        y ^= y >>> 18;
        if (this.mti >= 624) {
            mt = this.mt;
            mag01 = this.mag01;
            for (kk = 0; kk < 227; ++kk) {
                z = mt[kk] & Integer.MIN_VALUE | mt[kk + 1] & Integer.MAX_VALUE;
                mt[kk] = mt[kk + 397] ^ z >>> 1 ^ mag01[z & 1];
            }
            while (kk < 623) {
                z = mt[kk] & Integer.MIN_VALUE | mt[kk + 1] & Integer.MAX_VALUE;
                mt[kk] = mt[kk + 397 - 624] ^ z >>> 1 ^ mag01[z & 1];
                ++kk;
            }
            z = mt[623] & Integer.MIN_VALUE | mt[0] & Integer.MAX_VALUE;
            mt[623] = mt[396] ^ z >>> 1 ^ mag01[z & 1];
            this.mti = 0;
        }
        z = this.mt[this.mti++];
        z ^= z >>> 11;
        z ^= z << 7 & 0x9D2C5680;
        z ^= z << 15 & 0xEFC60000;
        z ^= z >>> 18;
        return (double)(((long)(y >>> 6) << 27) + (long)(z >>> 5)) / 9.007199254740992E15;
    }

    public double nextDouble(boolean includeZero, boolean includeOne) {
        double d = 0.0;
        do {
            d = this.nextDouble();
            if (!includeOne || !this.nextBoolean()) continue;
            d += 1.0;
        } while (d > 1.0 || !includeZero && d == 0.0);
        return d;
    }

    public double nextGaussian() {
        int b;
        int a;
        double v2;
        int z;
        int y;
        double v1;
        double s;
        if (this.__haveNextNextGaussian) {
            this.__haveNextNextGaussian = false;
            return this.__nextNextGaussian;
        }
        do {
            int kk;
            int[] mag01;
            int[] mt;
            if (this.mti >= 624) {
                mt = this.mt;
                mag01 = this.mag01;
                for (kk = 0; kk < 227; ++kk) {
                    y = mt[kk] & Integer.MIN_VALUE | mt[kk + 1] & Integer.MAX_VALUE;
                    mt[kk] = mt[kk + 397] ^ y >>> 1 ^ mag01[y & 1];
                }
                while (kk < 623) {
                    y = mt[kk] & Integer.MIN_VALUE | mt[kk + 1] & Integer.MAX_VALUE;
                    mt[kk] = mt[kk + 397 - 624] ^ y >>> 1 ^ mag01[y & 1];
                    ++kk;
                }
                y = mt[623] & Integer.MIN_VALUE | mt[0] & Integer.MAX_VALUE;
                mt[623] = mt[396] ^ y >>> 1 ^ mag01[y & 1];
                this.mti = 0;
            }
            y = this.mt[this.mti++];
            y ^= y >>> 11;
            y ^= y << 7 & 0x9D2C5680;
            y ^= y << 15 & 0xEFC60000;
            y ^= y >>> 18;
            if (this.mti >= 624) {
                mt = this.mt;
                mag01 = this.mag01;
                for (kk = 0; kk < 227; ++kk) {
                    z = mt[kk] & Integer.MIN_VALUE | mt[kk + 1] & Integer.MAX_VALUE;
                    mt[kk] = mt[kk + 397] ^ z >>> 1 ^ mag01[z & 1];
                }
                while (kk < 623) {
                    z = mt[kk] & Integer.MIN_VALUE | mt[kk + 1] & Integer.MAX_VALUE;
                    mt[kk] = mt[kk + 397 - 624] ^ z >>> 1 ^ mag01[z & 1];
                    ++kk;
                }
                z = mt[623] & Integer.MIN_VALUE | mt[0] & Integer.MAX_VALUE;
                mt[623] = mt[396] ^ z >>> 1 ^ mag01[z & 1];
                this.mti = 0;
            }
            z = this.mt[this.mti++];
            z ^= z >>> 11;
            z ^= z << 7 & 0x9D2C5680;
            z ^= z << 15 & 0xEFC60000;
            z ^= z >>> 18;
            if (this.mti >= 624) {
                mt = this.mt;
                mag01 = this.mag01;
                for (kk = 0; kk < 227; ++kk) {
                    a = mt[kk] & Integer.MIN_VALUE | mt[kk + 1] & Integer.MAX_VALUE;
                    mt[kk] = mt[kk + 397] ^ a >>> 1 ^ mag01[a & 1];
                }
                while (kk < 623) {
                    a = mt[kk] & Integer.MIN_VALUE | mt[kk + 1] & Integer.MAX_VALUE;
                    mt[kk] = mt[kk + 397 - 624] ^ a >>> 1 ^ mag01[a & 1];
                    ++kk;
                }
                a = mt[623] & Integer.MIN_VALUE | mt[0] & Integer.MAX_VALUE;
                mt[623] = mt[396] ^ a >>> 1 ^ mag01[a & 1];
                this.mti = 0;
            }
            a = this.mt[this.mti++];
            a ^= a >>> 11;
            a ^= a << 7 & 0x9D2C5680;
            a ^= a << 15 & 0xEFC60000;
            a ^= a >>> 18;
            if (this.mti >= 624) {
                mt = this.mt;
                mag01 = this.mag01;
                for (kk = 0; kk < 227; ++kk) {
                    b = mt[kk] & Integer.MIN_VALUE | mt[kk + 1] & Integer.MAX_VALUE;
                    mt[kk] = mt[kk + 397] ^ b >>> 1 ^ mag01[b & 1];
                }
                while (kk < 623) {
                    b = mt[kk] & Integer.MIN_VALUE | mt[kk + 1] & Integer.MAX_VALUE;
                    mt[kk] = mt[kk + 397 - 624] ^ b >>> 1 ^ mag01[b & 1];
                    ++kk;
                }
                b = mt[623] & Integer.MIN_VALUE | mt[0] & Integer.MAX_VALUE;
                mt[623] = mt[396] ^ b >>> 1 ^ mag01[b & 1];
                this.mti = 0;
            }
            b = this.mt[this.mti++];
            b ^= b >>> 11;
            b ^= b << 7 & 0x9D2C5680;
            b ^= b << 15 & 0xEFC60000;
        } while ((s = (v1 = 2.0 * ((double)(((long)(y >>> 6) << 27) + (long)(z >>> 5)) / 9.007199254740992E15) - 1.0) * v1 + (v2 = 2.0 * ((double)(((long)(a >>> 6) << 27) + (long)((b ^= b >>> 18) >>> 5)) / 9.007199254740992E15) - 1.0) * v2) >= 1.0 || s == 0.0);
        double multiplier = StrictMath.sqrt(-2.0 * StrictMath.log(s) / s);
        this.__nextNextGaussian = v2 * multiplier;
        this.__haveNextNextGaussian = true;
        return v1 * multiplier;
    }

    public float nextFloat() {
        int y;
        if (this.mti >= 624) {
            int kk;
            int[] mt = this.mt;
            int[] mag01 = this.mag01;
            for (kk = 0; kk < 227; ++kk) {
                y = mt[kk] & Integer.MIN_VALUE | mt[kk + 1] & Integer.MAX_VALUE;
                mt[kk] = mt[kk + 397] ^ y >>> 1 ^ mag01[y & 1];
            }
            while (kk < 623) {
                y = mt[kk] & Integer.MIN_VALUE | mt[kk + 1] & Integer.MAX_VALUE;
                mt[kk] = mt[kk + 397 - 624] ^ y >>> 1 ^ mag01[y & 1];
                ++kk;
            }
            y = mt[623] & Integer.MIN_VALUE | mt[0] & Integer.MAX_VALUE;
            mt[623] = mt[396] ^ y >>> 1 ^ mag01[y & 1];
            this.mti = 0;
        }
        y = this.mt[this.mti++];
        y ^= y >>> 11;
        y ^= y << 7 & 0x9D2C5680;
        y ^= y << 15 & 0xEFC60000;
        y ^= y >>> 18;
        return (float)(y >>> 8) / 1.6777216E7f;
    }

    public float nextFloat(boolean includeZero, boolean includeOne) {
        float d = 0.0f;
        do {
            d = this.nextFloat();
            if (!includeOne || !this.nextBoolean()) continue;
            d += 1.0f;
        } while (d > 1.0f || !includeZero && d == 0.0f);
        return d;
    }

    public int nextInt(int n) {
        int val;
        int y;
        int bits;
        if (n <= 0) {
            throw new IllegalArgumentException("n must be positive, got: " + n);
        }
        if ((n & -n) == n) {
            int y2;
            if (this.mti >= 624) {
                int kk;
                int[] mt = this.mt;
                int[] mag01 = this.mag01;
                for (kk = 0; kk < 227; ++kk) {
                    y2 = mt[kk] & Integer.MIN_VALUE | mt[kk + 1] & Integer.MAX_VALUE;
                    mt[kk] = mt[kk + 397] ^ y2 >>> 1 ^ mag01[y2 & 1];
                }
                while (kk < 623) {
                    y2 = mt[kk] & Integer.MIN_VALUE | mt[kk + 1] & Integer.MAX_VALUE;
                    mt[kk] = mt[kk + 397 - 624] ^ y2 >>> 1 ^ mag01[y2 & 1];
                    ++kk;
                }
                y2 = mt[623] & Integer.MIN_VALUE | mt[0] & Integer.MAX_VALUE;
                mt[623] = mt[396] ^ y2 >>> 1 ^ mag01[y2 & 1];
                this.mti = 0;
            }
            y2 = this.mt[this.mti++];
            y2 ^= y2 >>> 11;
            y2 ^= y2 << 7 & 0x9D2C5680;
            y2 ^= y2 << 15 & 0xEFC60000;
            y2 ^= y2 >>> 18;
            return (int)((long)n * (long)(y2 >>> 1) >> 31);
        }
        do {
            if (this.mti >= 624) {
                int kk;
                int[] mt = this.mt;
                int[] mag01 = this.mag01;
                for (kk = 0; kk < 227; ++kk) {
                    y = mt[kk] & Integer.MIN_VALUE | mt[kk + 1] & Integer.MAX_VALUE;
                    mt[kk] = mt[kk + 397] ^ y >>> 1 ^ mag01[y & 1];
                }
                while (kk < 623) {
                    y = mt[kk] & Integer.MIN_VALUE | mt[kk + 1] & Integer.MAX_VALUE;
                    mt[kk] = mt[kk + 397 - 624] ^ y >>> 1 ^ mag01[y & 1];
                    ++kk;
                }
                y = mt[623] & Integer.MIN_VALUE | mt[0] & Integer.MAX_VALUE;
                mt[623] = mt[396] ^ y >>> 1 ^ mag01[y & 1];
                this.mti = 0;
            }
            y = this.mt[this.mti++];
            y ^= y >>> 11;
            y ^= y << 7 & 0x9D2C5680;
            y ^= y << 15 & 0xEFC60000;
        } while ((bits = (y ^= y >>> 18) >>> 1) - (val = bits % n) + n - 1 < 0);
        return val;
    }
}

