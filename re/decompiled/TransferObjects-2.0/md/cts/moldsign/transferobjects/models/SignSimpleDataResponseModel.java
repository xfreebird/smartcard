/*
 * Decompiled with CFR 0.152.
 */
package md.cts.moldsign.transferobjects.models;

import md.cts.moldsign.transferobjects.models.WorkResult;

public final class SignSimpleDataResponseModel
implements WorkResult {
    private String signedData;
    private String certificate;

    public SignSimpleDataResponseModel() {
    }

    public SignSimpleDataResponseModel(String signedData, String certificate) {
        this.signedData = signedData;
        this.certificate = certificate;
    }

    public String getCertificate() {
        return this.certificate;
    }

    public void setCertificate(String certificate) {
        this.certificate = certificate;
    }

    public String getSignedData() {
        return this.signedData;
    }

    public void setSignedData(String signedData) {
        this.signedData = signedData;
    }
}

