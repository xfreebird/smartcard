/*
 * Decompiled with CFR 0.152.
 */
package md.cts.moldsign.transferobjects.models;

import md.cts.moldsign.transferobjects.models.WorkResult;

public final class VerifySignedFileResponseModel
implements WorkResult {
    private boolean valid;

    public VerifySignedFileResponseModel() {
    }

    public VerifySignedFileResponseModel(boolean valid) {
        this.valid = valid;
    }

    public boolean isValid() {
        return this.valid;
    }

    public void setValid(boolean valid) {
        this.valid = valid;
    }
}

