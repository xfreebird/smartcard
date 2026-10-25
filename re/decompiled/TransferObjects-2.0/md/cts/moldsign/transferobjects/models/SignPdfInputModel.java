/*
 * Decompiled with CFR 0.152.
 */
package md.cts.moldsign.transferobjects.models;

import md.cts.moldsign.transferobjects.models.CertificateModel;
import md.cts.moldsign.transferobjects.models.SignDataInputModel;

public final class SignPdfInputModel {
    public static final String PADES = "PAdES";
    public static final String PADES_T = "PAdES-T";
    private String originalFile;
    private String signedFile;
    private String format;
    private String algorithm;
    private CertificateModel certificate;
    private String pin;
    private String requester;

    public SignPdfInputModel() {
    }

    public SignPdfInputModel(SignDataInputModel sdim, String originalFile, String destinationFile) {
        this.originalFile = originalFile;
        this.signedFile = destinationFile;
        this.certificate = sdim.getCertificate();
        this.format = sdim.getSignFormat();
        this.algorithm = sdim.getAlgorithm();
        this.requester = sdim.getRequester();
    }

    public CertificateModel getCertificate() {
        return this.certificate;
    }

    public void setCertificate(CertificateModel certificate) {
        this.certificate = certificate;
    }

    public String getOriginalFile() {
        return this.originalFile;
    }

    public void setOriginalFile(String originalFile) {
        this.originalFile = originalFile;
    }

    public String getPin() {
        return this.pin;
    }

    public void setPin(String pin) {
        this.pin = pin;
    }

    public String getSignedFile() {
        return this.signedFile;
    }

    public void setSignedFile(String signedFile) {
        this.signedFile = signedFile;
    }

    public String getFormat() {
        return this.format;
    }

    public void setFormat(String format) {
        this.format = format;
    }

    public String getAlgorithm() {
        return this.algorithm;
    }

    public void setAlgorithm(String algorithm) {
        this.algorithm = algorithm;
    }

    public String getRequester() {
        return this.requester;
    }
}

