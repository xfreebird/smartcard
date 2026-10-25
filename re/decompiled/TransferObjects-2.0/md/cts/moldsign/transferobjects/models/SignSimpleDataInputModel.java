/*
 * Decompiled with CFR 0.152.
 */
package md.cts.moldsign.transferobjects.models;

import md.cts.moldsign.transferobjects.models.CertificateModel;

public final class SignSimpleDataInputModel {
    private String data;
    private CertificateModel certificate;
    private String pin = null;

    public SignSimpleDataInputModel() {
    }

    public SignSimpleDataInputModel(String data, CertificateModel certificate, String pin) {
        this.data = data;
        this.certificate = certificate;
        this.pin = pin;
    }

    public String getData() {
        return this.data;
    }

    public void setData(String data) {
        this.data = data;
    }

    public String getPin() {
        return this.pin;
    }

    public void setPin(String pin) {
        this.pin = pin;
    }

    public CertificateModel getCertificate() {
        return this.certificate;
    }

    public void setCertificate(CertificateModel certificate) {
        this.certificate = certificate;
    }
}

