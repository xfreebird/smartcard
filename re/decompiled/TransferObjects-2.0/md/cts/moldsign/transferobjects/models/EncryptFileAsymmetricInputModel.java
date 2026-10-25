/*
 * Decompiled with CFR 0.152.
 */
package md.cts.moldsign.transferobjects.models;

import md.cts.moldsign.transferobjects.models.CertificateModel;

public final class EncryptFileAsymmetricInputModel {
    private String filePath;
    private CertificateModel certificate;
    private String saveFileTo;

    public EncryptFileAsymmetricInputModel() {
    }

    public EncryptFileAsymmetricInputModel(String filePath, CertificateModel certificate, String saveFileTo) {
        this.filePath = filePath;
        this.saveFileTo = saveFileTo;
    }

    public CertificateModel getCertificate() {
        return this.certificate;
    }

    public void setCertificate(CertificateModel certificate) {
        this.certificate = certificate;
    }

    public String getFilePath() {
        return this.filePath;
    }

    public void setFilePath(String filePaht) {
        this.filePath = filePaht;
    }

    public String getSaveFileTo() {
        return this.saveFileTo;
    }

    public void setSaveFileTo(String saveFileTo) {
        this.saveFileTo = saveFileTo;
    }
}

