/*
 * Decompiled with CFR 0.152.
 */
package md.cts.pkcs11.providers.workers.safedeletealgorythms;

import md.cts.pkcs11.providers.workers.safedeletealgorythms.ShreadAlgorythm;

public final class DoD3Algorithm
extends ShreadAlgorythm {
    public DoD3Algorithm() {
        this.seqList.add(this.fill(0, 0, 0));
        this.seqList.add(this.fill(1, 1, 1));
        this.seqList.add(this.randomFill(3));
    }
}

