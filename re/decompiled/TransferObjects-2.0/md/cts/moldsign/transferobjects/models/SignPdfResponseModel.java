/*
 * Decompiled with CFR 0.152.
 */
package md.cts.moldsign.transferobjects.models;

import md.cts.moldsign.transferobjects.models.WorkResult;

public final class SignPdfResponseModel
implements WorkResult {
    private String path;

    public SignPdfResponseModel() {
    }

    public SignPdfResponseModel(String saveToPath) {
        this.path = saveToPath;
    }

    public String getSaveToPath() {
        return this.path;
    }

    public void setSaveToPath(String saveToPath) {
        this.path = saveToPath;
    }
}

