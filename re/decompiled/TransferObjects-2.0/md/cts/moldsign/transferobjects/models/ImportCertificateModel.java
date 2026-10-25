/*
 * Decompiled with CFR 0.152.
 */
package md.cts.moldsign.transferobjects.models;

public final class ImportCertificateModel {
    private String certificateFile;

    public ImportCertificateModel(String certificateFile) {
        this.certificateFile = certificateFile;
    }

    public ImportCertificateModel() {
    }

    public String getCertificateFile() {
        return this.certificateFile;
    }

    public void setCertificateFile(String certificateFile) {
        this.certificateFile = certificateFile;
    }
}

