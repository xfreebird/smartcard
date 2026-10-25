/*
 * Decompiled with CFR 0.152.
 */
package md.cts.moldsign.transferobjects.models;

import java.util.ArrayList;
import java.util.List;
import md.cts.moldsign.transferobjects.models.CertificateModel;
import md.cts.moldsign.transferobjects.models.SignDataInputModel;

public final class SignFileInputModel {
    public static final String XADES = "XAdES-BES";
    public static final String XADES_T = "XAdES-T";
    public static final String XADES_C = "XAdES-C";
    public static final String PADES = "PAdES";
    public static final String PADES_T = "PAdES-T";
    public static final String EMBEDDED = "Embedded";
    public static final String DETACHED = "Detached";
    public static final String SHA1 = "SHA-1";
    public static final String SHA256 = "SHA-256";
    private List<String> filesToSign;
    private String signatureFile;
    private String destinationFile;
    private String signatureReference;
    private CertificateModel certificate;
    private String signFormat;
    private String signAlgorithm;
    private String pin;
    private String type;
    private boolean eachFileSeparately;
    private String requester;

    public SignFileInputModel() {
    }

    public SignFileInputModel(List<String> filesToSign, String signatureFile, String destinationFile, String signatureReference, CertificateModel certificate, String signFormat, String pin, String type, String algorithm, boolean eachFileSeparately) {
        this.filesToSign = filesToSign;
        this.signatureFile = signatureFile;
        this.destinationFile = destinationFile;
        this.signatureReference = signatureReference;
        this.certificate = certificate;
        this.signFormat = signFormat;
        this.signAlgorithm = algorithm;
        this.pin = pin;
        this.type = type;
        this.eachFileSeparately = eachFileSeparately;
    }

    public SignFileInputModel(SignDataInputModel sdim, String originalFile, String destinationFile) {
        ArrayList<String> filesList = new ArrayList<String>();
        filesList.add(originalFile);
        this.filesToSign = filesList;
        this.destinationFile = destinationFile;
        this.signatureReference = sdim.getSignatureReference();
        this.certificate = sdim.getCertificate();
        this.signFormat = sdim.getSignFormat();
        this.signAlgorithm = sdim.getAlgorithm();
        this.type = sdim.getSignatureType();
        this.eachFileSeparately = true;
        this.requester = sdim.getRequester();
    }

    public String getDestinationFile() {
        return this.destinationFile;
    }

    public void setDestinationFile(String destinationFile) {
        this.destinationFile = destinationFile;
    }

    public List<String> getFilesToSign() {
        return this.filesToSign;
    }

    public void setFilesToSign(List<String> filesToSign) {
        this.filesToSign = filesToSign;
    }

    public String getSignatureFile() {
        return this.signatureFile;
    }

    public void setSignatureFile(String signatureFile) {
        this.signatureFile = signatureFile;
    }

    public String getSignFormat() {
        return this.signFormat;
    }

    public void setSignFormat(String signFormat) {
        this.signFormat = signFormat;
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

    public String getSignatureReference() {
        return this.signatureReference;
    }

    public void setSignatureReference(String signatureReference) {
        this.signatureReference = signatureReference;
    }

    public String getType() {
        return this.type;
    }

    public void setType(String type) {
        this.type = type;
    }

    public String getSignAlgorithm() {
        return this.signAlgorithm;
    }

    public void setSignAlgorithm(String signAlgorithm) {
        this.signAlgorithm = signAlgorithm;
    }

    public String getRequester() {
        return this.requester;
    }
}

