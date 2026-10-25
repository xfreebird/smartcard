/*
 * Decompiled with CFR 0.152.
 */
package md.cts.pkcs11.providers.workers.safedeletealgorythms;

import md.cts.pkcs11.providers.workers.safedeletealgorythms.ShreadAlgorythm;

public final class DoD7Algorithm
extends ShreadAlgorythm {
    public DoD7Algorithm() {
        this.seqList.add(this.fill(20, 243, 185));
        this.seqList.add(this.complementByteArray(this.fill(20, 243, 185)));
        byte[] tmpRnd = this.randomFill(3);
        this.seqList.add(tmpRnd);
        this.seqList.add(this.complementByteArray(tmpRnd));
        this.seqList.add(this.fill(196, 196, 196));
        this.seqList.add(this.complementByteArray(this.fill(196, 196, 196)));
        this.seqList.add(this.randomFill(3));
    }
}

