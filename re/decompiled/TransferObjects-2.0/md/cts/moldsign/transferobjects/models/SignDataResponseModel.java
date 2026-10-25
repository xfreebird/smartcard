/*
 * Decompiled with CFR 0.152.
 */
package md.cts.moldsign.transferobjects.models;

public class SignDataResponseModel {
    private String base64File;

    public SignDataResponseModel() {
    }

    public SignDataResponseModel(String base64File) {
        this.base64File = base64File;
    }

    public String getBase64File() {
        return this.base64File;
    }

    public void setBase64File(String base64File) {
        this.base64File = base64File;
    }
}

