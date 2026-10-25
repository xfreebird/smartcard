/*
 * Decompiled with CFR 0.152.
 */
package md.cts.pkcs11.providers.workers.safedeletealgorythms;

import md.cts.pkcs11.providers.workers.safedeletealgorythms.ShreadAlgorythm;

public final class PeterGutmannAlgorithm
extends ShreadAlgorythm {
    public PeterGutmannAlgorithm() {
        this.seqList.add(this.randomFill(3));
        this.seqList.add(this.randomFill(3));
        this.seqList.add(this.randomFill(3));
        this.seqList.add(this.randomFill(3));
        this.seqList.add(this.fill(85, 85, 85));
        this.seqList.add(this.fill(170, 170, 170));
        this.seqList.add(this.fill(146, 73, 36));
        this.seqList.add(this.fill(73, 36, 146));
        this.seqList.add(this.fill(36, 146, 73));
        this.seqList.add(this.fill(0, 0, 0));
        this.seqList.add(this.fill(17, 17, 17));
        this.seqList.add(this.fill(34, 34, 34));
        this.seqList.add(this.fill(51, 51, 51));
        this.seqList.add(this.fill(68, 68, 68));
        this.seqList.add(this.fill(85, 85, 85));
        this.seqList.add(this.fill(102, 102, 102));
        this.seqList.add(this.fill(119, 119, 119));
        this.seqList.add(this.fill(136, 136, 136));
        this.seqList.add(this.fill(153, 153, 153));
        this.seqList.add(this.fill(170, 170, 170));
        this.seqList.add(this.fill(187, 187, 187));
        this.seqList.add(this.fill(204, 204, 204));
        this.seqList.add(this.fill(221, 221, 221));
        this.seqList.add(this.fill(238, 238, 238));
        this.seqList.add(this.fill(255, 255, 255));
        this.seqList.add(this.fill(146, 73, 36));
        this.seqList.add(this.fill(73, 36, 146));
        this.seqList.add(this.fill(36, 146, 73));
        this.seqList.add(this.fill(109, 182, 219));
        this.seqList.add(this.fill(182, 219, 109));
        this.seqList.add(this.fill(219, 109, 182));
        this.seqList.add(this.randomFill(3));
        this.seqList.add(this.randomFill(3));
        this.seqList.add(this.randomFill(3));
        this.seqList.add(this.randomFill(3));
    }
}

