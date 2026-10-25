/*
 * Decompiled with CFR 0.152.
 */
package md.cts.moldsign.transferobjects.models;

public final class DeleteSignatureInputModel {
    private String signatureFile;
    private String destinationFile;
    private String signatureReference;

    public DeleteSignatureInputModel(String signatureFile, String destinationFile, String signatureReference) {
        this.signatureFile = signatureFile;
        this.destinationFile = destinationFile;
        this.signatureReference = signatureReference;
    }

    public DeleteSignatureInputModel() {
    }

    public String getDestinationFile() {
        return this.destinationFile;
    }

    public void setDestinationFile(String destinationFile) {
        this.destinationFile = destinationFile;
    }

    public String getSignatureFile() {
        return this.signatureFile;
    }

    public void setSignatureFile(String signatureFile) {
        this.signatureFile = signatureFile;
    }

    public String getSignatureReference() {
        return this.signatureReference;
    }

    public void setSignatureReference(String signatureReference) {
        this.signatureReference = signatureReference;
    }
}

