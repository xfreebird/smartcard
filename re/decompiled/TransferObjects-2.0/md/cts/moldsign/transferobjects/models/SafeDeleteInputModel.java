/*
 * Decompiled with CFR 0.152.
 */
package md.cts.moldsign.transferobjects.models;

import md.cts.moldsign.transferobjects.models.WorkResult;

public final class SafeDeleteInputModel
implements WorkResult {
    private String file;
    private String algorithm;
    private int nrRetries;

    public SafeDeleteInputModel(String file, String algorithm, int nrRetries) {
        this.file = file;
        this.algorithm = algorithm;
        this.nrRetries = nrRetries;
    }

    public SafeDeleteInputModel() {
    }

    public String getAlgorithm() {
        return this.algorithm;
    }

    public void setAlgorithm(String algorithm) {
        this.algorithm = algorithm;
    }

    public String getFile() {
        return this.file;
    }

    public void setFile(String file) {
        this.file = file;
    }

    public int getNrRetries() {
        return this.nrRetries;
    }

    public void setNrRetries(int nrRetries) {
        this.nrRetries = nrRetries;
    }
}

