/*
 * Decompiled with CFR 0.152.
 */
package md.cts.pkcs11.providers.workers.safedeletealgorythms;

import java.util.LinkedList;
import java.util.Random;

public abstract class ShreadAlgorythm {
    protected final LinkedList<byte[]> seqList = new LinkedList();

    protected byte[] fill(int ... bt) {
        byte[] result = new byte[bt.length];
        for (int i = 0; i < bt.length; ++i) {
            result[i] = (byte)bt[i];
        }
        return result;
    }

    protected byte[] randomFill(int length) {
        byte[] randomBytes = new byte[length];
        new Random().nextBytes(randomBytes);
        return randomBytes;
    }

    public LinkedList<byte[]> getSeqList() {
        return this.seqList;
    }

    public byte[] complementByteArray(byte[] originalArray) {
        byte[] tmpArr = new byte[originalArray.length];
        for (int i = 0; i < originalArray.length; ++i) {
            tmpArr[i] = ~originalArray[i];
        }
        return tmpArr;
    }
}

