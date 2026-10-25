/*
 * Decompiled with CFR 0.152.
 */
package md.cts.pkcs11.providers.workers.safedeletealgorythms;

import md.cts.pkcs11.providers.workers.safedeletealgorythms.ShreadAlgorythm;

public final class PseudoRandomNumberAlgorithm
extends ShreadAlgorythm {
    public PseudoRandomNumberAlgorithm(int nbrRepeat) {
        for (int i = 0; i < nbrRepeat; ++i) {
            this.seqList.add(this.randomFill(3));
        }
    }
}

