/*
 * Decompiled with CFR 0.152.
 * 
 * Could not load the following classes:
 *  com.fasterxml.jackson.annotation.JsonIgnore
 *  iaik.asn1.ObjectID
 *  iaik.asn1.structures.Name
 *  iaik.asn1.structures.PolicyInformation
 *  iaik.x509.V3Extension
 *  iaik.x509.X509Certificate
 *  iaik.x509.X509ExtensionInitException
 *  iaik.x509.extensions.CertificatePolicies
 *  org.slf4j.Logger
 *  org.slf4j.LoggerFactory
 */
package md.cts.moldsign.transferobjects.models;

import com.fasterxml.jackson.annotation.JsonIgnore;
import iaik.asn1.ObjectID;
import iaik.asn1.structures.Name;
import iaik.asn1.structures.PolicyInformation;
import iaik.x509.V3Extension;
import iaik.x509.X509Certificate;
import iaik.x509.X509ExtensionInitException;
import iaik.x509.extensions.CertificatePolicies;
import java.security.cert.CertificateEncodingException;
import java.security.cert.CertificateException;
import java.text.SimpleDateFormat;
import java.util.ArrayList;
import java.util.Base64;
import java.util.HexFormat;
import java.util.List;
import java.util.Objects;
import md.cts.moldsign.transferobjects.models.CertificateDetailsModel;
import md.cts.moldsign.transferobjects.models.WorkResult;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

public final class CertificateModel
implements WorkResult {
    public static final int VERIFICATION_NOT_CHECKED = -1;
    public static final int VERIFICATION_OK = 0;
    public static final int VERIFICATION_EXPIRED = 1;
    public static final int VERIFICATION_REVOKED = 2;
    public static final int VERIFICATION_REVOKATION_NOT_AVAILABLE = 3;
    public static final int VERIFICATION_NOT_TRUSTED = 4;
    public static final int VALID_FOR_NONE = 0;
    public static final int VALID_FOR_SIGNING = 1;
    public static final int VALID_FOR_ENCRYPTION = 2;
    private static final Logger logger = LoggerFactory.getLogger(CertificateModel.class);
    private String certificateId;
    private String label;
    private String providerId;
    private String policy;
    private String certificateName;
    private String subjectDN;
    private String issuerDN;
    private boolean authority;
    private boolean trusted;
    private transient X509Certificate certificate;
    private int verified = -1;
    private boolean privateKeyPresent;

    public CertificateModel() {
    }

    public CertificateModel(X509Certificate certificate) {
        this.setCertificate(certificate);
    }

    public CertificateModel(java.security.cert.X509Certificate certificate) {
        X509Certificate cert = null;
        try {
            cert = new X509Certificate(certificate.getEncoded());
        }
        catch (CertificateException ex) {
            logger.error("CertificateModel", (Throwable)ex);
        }
        if (cert != null) {
            this.setCertificate(cert);
        }
    }

    public CertificateModel(String certificateId, String label, String providerId, X509Certificate certificate, boolean privateKeyPresent) {
        this.certificateId = certificateId;
        this.label = label;
        this.providerId = providerId;
        this.setCertificate(certificate);
        this.privateKeyPresent = privateKeyPresent;
    }

    public String getCertificateBase64() {
        String base64 = null;
        try {
            base64 = Base64.getEncoder().encodeToString(this.certificate.getEncoded());
        }
        catch (CertificateEncodingException ex) {
            logger.error("getCertificateBase64", (Throwable)ex);
        }
        return base64;
    }

    public void setCertificateBase64(String certificate) {
        byte[] data = Base64.getDecoder().decode(certificate);
        try {
            this.setCertificate(new X509Certificate(data));
        }
        catch (CertificateException ex) {
            logger.error("setCertificateBase64", (Throwable)ex);
        }
    }

    public X509Certificate getCertificate() {
        return this.certificate;
    }

    @JsonIgnore
    public void setCertificate(X509Certificate certificate) {
        this.certificate = certificate;
        this.subjectDN = certificate.getSubjectDN().getName();
        this.issuerDN = certificate.getIssuerDN().getName();
        this.policy = this.getPolicyOid();
        this.authority = certificate.getBasicConstraints() >= 0;
    }

    @JsonIgnore
    public List<CertificateDetailsModel> getCertificateDetails() {
        ArrayList<CertificateDetailsModel> cdm = new ArrayList<CertificateDetailsModel>();
        SimpleDateFormat df = new SimpleDateFormat("MM/dd/yyyy HH:mm:ss");
        cdm.add(new CertificateDetailsModel("Version", "cdm.version", "V" + this.certificate.getVersion(), "V" + this.certificate.getVersion()));
        cdm.add(new CertificateDetailsModel("Serial Number", "cdm.serialNumber", HexFormat.of().formatHex(this.certificate.getSerialNumber().toByteArray()), HexFormat.of().formatHex(this.certificate.getSerialNumber().toByteArray())));
        cdm.add(new CertificateDetailsModel("Valid from", "cdm.validFrom", df.format(this.certificate.getNotBefore()), df.format(this.certificate.getNotBefore())));
        return cdm;
    }

    public String getCertificateId() {
        return this.certificateId;
    }

    public void setCertificateId(String certificateId) {
        this.certificateId = certificateId;
    }

    public String getIssuerDN() {
        return this.issuerDN;
    }

    public void setIssuerDN(String issuerDN) {
        this.issuerDN = issuerDN;
    }

    public String getLabel() {
        return this.label;
    }

    public void setLabel(String label) {
        this.label = label;
    }

    public String getPolicy() {
        return this.policy;
    }

    public void setPolicy(String policy) {
        this.policy = policy;
    }

    public boolean isPrivateKeyPresent() {
        return this.privateKeyPresent;
    }

    public void setPrivateKeyPresent(boolean privateKeyPresent) {
        this.privateKeyPresent = privateKeyPresent;
    }

    public String getProviderId() {
        return this.providerId;
    }

    public void setProviderId(String providerId) {
        this.providerId = providerId;
    }

    public String getSubjectDN() {
        return this.subjectDN;
    }

    public void setSubjectDN(String subjectDN) {
        this.subjectDN = subjectDN;
    }

    public int getVerified() {
        return this.verified;
    }

    public void setVerified(int verified) {
        this.verified = verified;
    }

    public boolean isAuthority() {
        return this.authority;
    }

    @JsonIgnore
    public String getPolicyOid() {
        String policyId = null;
        try {
            CertificatePolicies policies;
            V3Extension policyExtension = this.certificate.getExtension(new ObjectID("2.5.29.32"));
            if (policyExtension instanceof CertificatePolicies && (policies = (CertificatePolicies)policyExtension).getPolicyInformation().length > 0) {
                PolicyInformation policyInformation = policies.getPolicyInformation()[0];
                policyId = policyInformation.getPolicyIdentifier().getName();
            }
        }
        catch (X509ExtensionInitException ex) {
            logger.error("getPolicyOid", (Throwable)ex);
        }
        return policyId;
    }

    public boolean equals(Object obj) {
        if (obj == null) {
            return false;
        }
        if (this.getClass() != obj.getClass()) {
            return false;
        }
        CertificateModel other = (CertificateModel)obj;
        if (!Objects.equals(this.providerId, other.providerId)) {
            return false;
        }
        return Objects.equals(this.certificate, other.certificate);
    }

    public int hashCode() {
        int hash = 5;
        hash = 47 * hash + (this.providerId != null ? this.providerId.hashCode() : 0);
        hash = 47 * hash + (this.certificate != null ? this.certificate.hashCode() : 0);
        return hash;
    }

    public String toString() {
        StringBuilder resultBuilder = new StringBuilder();
        Name n = (Name)this.certificate.getSubjectDN();
        Object name = n.getRDN(ObjectID.commonName);
        name = name == null || ((String)name).isEmpty() ? n.getRDN(ObjectID.organization) : (String)name + " (" + n.getRDN(ObjectID.organization) + ")";
        resultBuilder.append((String)name);
        if (this.getPolicy() != null) {
            resultBuilder.append(" (").append(this.getPolicy()).append(")");
        }
        return resultBuilder.toString();
    }

    public boolean isTrusted() {
        return this.trusted;
    }

    public void setTrusted(boolean trusted) {
        this.trusted = trusted;
    }

    public String getCertificateName() {
        return this.certificateName;
    }

    public void setCertificateName(String certificateName) {
        this.certificateName = certificateName;
    }
}

