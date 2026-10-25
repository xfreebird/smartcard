/*
 * Decompiled with CFR 0.152.
 */
package md.cts.moldsign.transferobjects.models.XAdES;

public class GetSignatureFileInputModel {
    private String signatureFile;

    public GetSignatureFileInputModel() {
    }

    public GetSignatureFileInputModel(String signatureFile) {
        this.signatureFile = signatureFile;
    }

    public String getSignatureFile() {
        return this.signatureFile;
    }

    public void setSignatureFile(String signatureFile) {
        this.signatureFile = signatureFile;
    }
}

