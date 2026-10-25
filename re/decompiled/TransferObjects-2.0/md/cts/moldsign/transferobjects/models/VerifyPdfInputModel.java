/*
 * Decompiled with CFR 0.152.
 */
package md.cts.moldsign.transferobjects.models;

import md.cts.moldsign.transferobjects.models.WorkResult;

public final class VerifyPdfInputModel
implements WorkResult {
    private String signedFile;

    public VerifyPdfInputModel() {
    }

    public VerifyPdfInputModel(String signedFiles) {
        this.signedFile = signedFiles;
    }

    public String getSignedFile() {
        return this.signedFile;
    }

    public void setSignedFile(String signedFile) {
        this.signedFile = signedFile;
    }
}

