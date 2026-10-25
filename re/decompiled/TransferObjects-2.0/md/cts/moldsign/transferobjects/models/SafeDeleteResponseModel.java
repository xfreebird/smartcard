/*
 * Decompiled with CFR 0.152.
 */
package md.cts.moldsign.transferobjects.models;

import md.cts.moldsign.transferobjects.models.WorkResult;

public final class SafeDeleteResponseModel
implements WorkResult {
    private String file;

    public SafeDeleteResponseModel(String file) {
        this.file = file;
    }

    public SafeDeleteResponseModel() {
    }

    public String getFile() {
        return this.file;
    }

    public void setFile(String file) {
        this.file = file;
    }
}

