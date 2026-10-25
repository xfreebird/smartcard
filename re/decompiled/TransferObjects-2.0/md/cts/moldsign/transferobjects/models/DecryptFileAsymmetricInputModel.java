/*
 * Decompiled with CFR 0.152.
 */
package md.cts.moldsign.transferobjects.models;

import md.cts.moldsign.transferobjects.models.CertificateModel;

public final class DecryptFileAsymmetricInputModel {
    private String filePath;
    private String saveFileTo;
    private CertificateModel certificate;
    private String pin;

    public DecryptFileAsymmetricInputModel() {
    }

    public DecryptFileAsymmetricInputModel(String filePath, CertificateModel certificate, String saveFileTo, String pin) {
        this.filePath = filePath;
        this.saveFileTo = saveFileTo;
        this.pin = pin;
        this.certificate = certificate;
    }

    public CertificateModel getCertificate() {
        return this.certificate;
    }

    public void setCertificate(CertificateModel certificate) {
        this.certificate = certificate;
    }

    public String getSaveFileTo() {
        return this.saveFileTo;
    }

    public void setSaveFileTo(String saveFileTo) {
        this.saveFileTo = saveFileTo;
    }

    public String getFilePath() {
        return this.filePath;
    }

    public void setFilePath(String filePath) {
        this.filePath = filePath;
    }

    public String getPin() {
        return this.pin;
    }

    public void setPin(String pin) {
        this.pin = pin;
    }
}

