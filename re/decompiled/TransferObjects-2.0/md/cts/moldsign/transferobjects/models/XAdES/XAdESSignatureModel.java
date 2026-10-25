/*
 * Decompiled with CFR 0.152.
 */
package md.cts.moldsign.transferobjects.models.XAdES;

import java.util.ArrayList;
import java.util.Date;
import java.util.List;
import md.cts.moldsign.transferobjects.models.CertificateDetailsModel;
import md.cts.moldsign.transferobjects.models.CertificateModel;
import md.cts.moldsign.transferobjects.models.WorkResult;
import md.cts.moldsign.transferobjects.models.XAdES.SigningReferenceModel;
import md.cts.moldsign.transferobjects.models.XAdES.TimeStampModel;

public final class XAdESSignatureModel
implements WorkResult {
    private String id;
    private CertificateModel signer;
    private String type = "XAdES";
    private Date timeSigned;
    private TimeStampModel timestamp;
    private List<SigningReferenceModel> references;
    private List<XAdESSignatureModel> counterSignatures;
    private String signatureFormat;

    public String getSignatureFormat() {
        return this.signatureFormat;
    }

    public void setSignatureFormat(String signatureFormat) {
        this.signatureFormat = signatureFormat;
    }

    public String getType() {
        return this.type;
    }

    public void setType(String type) {
        this.type = type;
    }

    public List<XAdESSignatureModel> getCounterSignatures() {
        return this.counterSignatures;
    }

    public void setCounterSignatures(List<XAdESSignatureModel> counterSignatures) {
        this.counterSignatures = counterSignatures;
    }

    public String getId() {
        return this.id;
    }

    public void setId(String id) {
        this.id = id;
    }

    public List<SigningReferenceModel> getReferences() {
        return this.references;
    }

    public void setReferences(List<SigningReferenceModel> references) {
        this.references = references;
    }

    public CertificateModel getSigner() {
        return this.signer;
    }

    public void setSigner(CertificateModel signer) {
        this.signer = signer;
    }

    public Date getTimeSigned() {
        return this.timeSigned;
    }

    public void setTimeSigned(Date timeSigned) {
        this.timeSigned = timeSigned;
    }

    public TimeStampModel getTimestamp() {
        return this.timestamp;
    }

    public void setTimestamp(TimeStampModel timestamp) {
        this.timestamp = timestamp;
    }

    public String toString() {
        return this.signer.toString();
    }

    public List<CertificateDetailsModel> getSignatureDetails() {
        ArrayList<CertificateDetailsModel> cdml = new ArrayList<CertificateDetailsModel>();
        String signerDN = this.signer.getSubjectDN();
        StringBuilder sb = new StringBuilder();
        for (String dnEntry : signerDN.split(",")) {
            sb.append(dnEntry).append("\n");
        }
        cdml.add(new CertificateDetailsModel("Format", "sdm.time_signed", this.signatureFormat, this.signatureFormat));
        cdml.add(new CertificateDetailsModel("Type", "sdm.time_signed", this.type, this.type));
        cdml.add(new CertificateDetailsModel("Signer", "sdm.signer", this.signer.toString(), sb.toString()));
        cdml.add(new CertificateDetailsModel("id", "sdm.id", this.id, this.id));
        cdml.add(new CertificateDetailsModel("Time Signed", "sdm.time_signed", this.timeSigned.toString(), this.timeSigned.toString()));
        if (this.timestamp != null) {
            CertificateModel timestampAuthority = this.timestamp.getSigner();
            cdml.add(new CertificateDetailsModel("Time Stamp Authority", "sdm.time_signed", timestampAuthority.getSubjectDN(), timestampAuthority.getCertificate().toString(true)));
            cdml.add(new CertificateDetailsModel("Time Stamp Time", "sdm.time_signed", this.timestamp.getTime().toString(), this.timestamp.getTime().toString()));
        }
        return cdml;
    }
}

