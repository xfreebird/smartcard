/*
 * Decompiled with CFR 0.152.
 * 
 * Could not load the following classes:
 *  com.fasterxml.jackson.annotation.JsonIgnoreProperties
 */
package md.cts.moldsign.transferobjects.models;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import md.cts.moldsign.transferobjects.models.CertificateModel;

@JsonIgnoreProperties(ignoreUnknown=true)
public final class SignDataInputModel {
    public static final String XADES = "XAdES";
    public static final String binary = "Binary";
    public static final String text = "\u0422ext";
    public static final String xml = "xml";
    public static final String pdf = "pdf";
    private String data;
    private String contentType;
    private String algorithm;
    private String signFormat;
    private String signatureReference;
    private String signatureType;
    private CertificateModel certificate;
    private String requester;
    private String httpCallBackURL;
    private String httpCallBackID;

    public SignDataInputModel() {
    }

    public SignDataInputModel(String data, String contentType, String algorithm, String signFormat, String signatureReference, String signatureType, CertificateModel certificate, String pin) {
        this.data = data;
        this.contentType = contentType;
        this.algorithm = algorithm;
        this.signFormat = signFormat;
        this.signatureReference = signatureReference;
        this.signatureType = signatureType;
        this.certificate = certificate;
    }

    public String getData() {
        return this.data;
    }

    public void setData(String data) {
        this.data = data;
    }

    public String getContentType() {
        return this.contentType;
    }

    public void setContentType(String contentType) {
        this.contentType = contentType;
    }

    public String getSignFormat() {
        return this.signFormat;
    }

    public void setSignFormat(String signFormat) {
        this.signFormat = signFormat;
    }

    public String getSignatureReference() {
        return this.signatureReference;
    }

    public void setSignatureReference(String signatureReference) {
        this.signatureReference = signatureReference;
    }

    public String getSignatureType() {
        return this.signatureType;
    }

    public void setSignatureType(String signatureType) {
        this.signatureType = signatureType;
    }

    public CertificateModel getCertificate() {
        return this.certificate;
    }

    public void setCertificate(CertificateModel certificate) {
        this.certificate = certificate;
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

    public void setRequester(String requester) {
        this.requester = requester;
    }

    public String getHttpCallBackURL() {
        return this.httpCallBackURL;
    }

    public void setHttpCallBackURL(String httpCallBackURL) {
        this.httpCallBackURL = httpCallBackURL;
    }

    public String getHttpCallBackID() {
        return this.httpCallBackID;
    }

    public void setHttpCallBackID(String httpCallBackID) {
        this.httpCallBackID = httpCallBackID;
    }
}

