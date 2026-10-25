/*
 * Decompiled with CFR 0.152.
 */
package md.cts.moldsign.transferobjects.models;

import md.cts.moldsign.transferobjects.models.WorkResult;

public final class EncryptDecryptFileResponseModel
implements WorkResult {
    private String filePath;

    public EncryptDecryptFileResponseModel() {
    }

    public EncryptDecryptFileResponseModel(String filePath) {
        this.filePath = filePath;
    }

    public String getFilePath() {
        return this.filePath;
    }

    public void setFilePath(String filePath) {
        this.filePath = filePath;
    }
}

