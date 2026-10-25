/*
 * Decompiled with CFR 0.152.
 * 
 * Could not load the following classes:
 *  iaik.asn1.ObjectID
 *  iaik.asn1.structures.Name
 *  iaik.asn1.structures.PolicyInformation
 *  iaik.pkcs.pkcs11.objects.Object
 *  iaik.pkcs.pkcs11.objects.PrivateKey
 *  iaik.pkcs.pkcs11.objects.PublicKey
 *  iaik.pkcs.pkcs11.objects.X509PublicKeyCertificate
 *  iaik.x509.V3Extension
 *  iaik.x509.X509Certificate
 *  iaik.x509.X509ExtensionInitException
 *  iaik.x509.extensions.CertificatePolicies
 *  org.bouncycastle.jce.provider.BouncyCastleProvider
 *  org.slf4j.Logger
 *  org.slf4j.LoggerFactory
 */
package md.cts.pkcs11.cards.certificates;

import iaik.asn1.ObjectID;
import iaik.asn1.structures.Name;
import iaik.asn1.structures.PolicyInformation;
import iaik.pkcs.pkcs11.objects.PrivateKey;
import iaik.pkcs.pkcs11.objects.PublicKey;
import iaik.pkcs.pkcs11.objects.X509PublicKeyCertificate;
import iaik.x509.V3Extension;
import iaik.x509.X509Certificate;
import iaik.x509.X509ExtensionInitException;
import iaik.x509.extensions.CertificatePolicies;
import java.io.ByteArrayInputStream;
import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;
import java.nio.file.Files;
import java.nio.file.OpenOption;
import java.nio.file.Paths;
import java.security.Provider;
import java.security.Security;
import java.security.cert.CertificateEncodingException;
import java.security.cert.CertificateException;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;
import java.util.Objects;
import md.cts.pkcs11.util.ByteArrayWrapper;
import org.bouncycastle.jce.provider.BouncyCastleProvider;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

public final class CertificateFull {
    private static final Logger logger = LoggerFactory.getLogger(CertificateFull.class);
    private byte[] id;
    private X509PublicKeyCertificate certificateObject = null;
    private PrivateKey privateKeyObject = null;
    private PublicKey publicKeyObject = null;
    private String label;
    private volatile X509Certificate certificate = null;

    public CertificateFull(iaik.pkcs.pkcs11.objects.Object object) {
        this.addObject(object);
    }

    public void addObject(iaik.pkcs.pkcs11.objects.Object object) {
        if (object == null) {
            return;
        }
        if (object instanceof X509PublicKeyCertificate) {
            X509PublicKeyCertificate certObj = (X509PublicKeyCertificate)object;
            this.setCertificateObject(certObj);
            this.label = certObj.getLabel() != null ? certObj.getLabel().toString() : "Unnamed";
            this.id = certObj.getId().getByteArrayValue();
        }
        if (object instanceof PublicKey) {
            PublicKey pubKeyObj = (PublicKey)object;
            this.setPublicKeyObject(pubKeyObj);
            this.id = pubKeyObj.getId().getByteArrayValue();
        }
        if (object instanceof PrivateKey) {
            PrivateKey privateKeyObj = (PrivateKey)object;
            this.setPrivateKeyObject(privateKeyObj);
            this.id = privateKeyObj.getId().getByteArrayValue();
        }
    }

    public String getLabel() {
        return this.label;
    }

    public String getName() {
        X509Certificate certificate = this.getCert();
        if (certificate == null) {
            return "";
        }
        Name n = (Name)certificate.getSubjectDN();
        String dn = n.getRDN(ObjectID.commonName);
        if (dn == null) {
            dn = n.getRDN(ObjectID.organizationalUnit);
        }
        if (dn == null) {
            dn = n.getRDN(ObjectID.organization);
        }
        StringBuilder name = new StringBuilder();
        name.append(dn);
        List<PolicyInformation> policyInfoList = this.getListOfPolicies();
        if (!policyInfoList.isEmpty()) {
            PolicyInformation policyInformation = policyInfoList.get(0);
            String oid = policyInformation.getPolicyIdentifier().getID();
            name.append(" (").append(oid).append(")");
        }
        return name.toString();
    }

    public byte[] getId() {
        return this.id;
    }

    private List<PolicyInformation> getListOfPolicies() {
        ArrayList<PolicyInformation> policyInfoList = new ArrayList<PolicyInformation>();
        if (!this.hasCert()) {
            return policyInfoList;
        }
        try {
            V3Extension policyExtension = this.getCert().getExtension(new ObjectID("2.5.29.32"));
            if (policyExtension instanceof CertificatePolicies) {
                CertificatePolicies policies = (CertificatePolicies)policyExtension;
                policyInfoList.addAll(Arrays.asList(policies.getPolicyInformation()).subList(0, policies.getPolicyInformation().length));
            }
            return policyInfoList;
        }
        catch (X509ExtensionInitException ex) {
            logger.error("", (Throwable)ex);
            return policyInfoList;
        }
    }

    public boolean checkCertOidMatch(ObjectID oid) {
        List<PolicyInformation> policyInfoList = this.getListOfPolicies();
        if (oid == null) {
            return false;
        }
        for (PolicyInformation policyInformation : policyInfoList) {
            if (!oid.equals((Object)policyInformation.getPolicyIdentifier())) continue;
            return true;
        }
        return false;
    }

    public boolean isPrivateKeyPresent() {
        return this.privateKeyObject != null;
    }

    public boolean hasCert() {
        return this.certificateObject != null;
    }

    private void parseCert() {
        byte[] certBytes;
        if (this.certificateObject != null && (certBytes = this.certificateObject.getValue().getByteArrayValue()) != null) {
            try {
                ByteArrayInputStream inStream = new ByteArrayInputStream(certBytes);
                Security.addProvider((Provider)new BouncyCastleProvider());
                this.certificate = new X509Certificate((InputStream)inStream);
            }
            catch (IOException | CertificateException ex) {
                logger.error("", (Throwable)ex);
            }
        }
    }

    /*
     * WARNING - Removed try catching itself - possible behaviour change.
     */
    public X509Certificate getCert() {
        if (this.certificate == null) {
            CertificateFull certificateFull = this;
            synchronized (certificateFull) {
                if (this.certificate == null) {
                    this.parseCert();
                }
            }
        }
        return this.certificate;
    }

    private void setCertificateObject(X509PublicKeyCertificate certificateObject) {
        this.certificateObject = certificateObject;
    }

    private void setPrivateKeyObject(PrivateKey privateKeyObject) {
        this.privateKeyObject = privateKeyObject;
    }

    private void setPublicKeyObject(PublicKey publicKeyObject) {
        this.publicKeyObject = publicKeyObject;
    }

    public boolean save(String path) {
        if (path.toLowerCase().endsWith(".pem")) {
            return this.save(path, true);
        }
        return this.save(path, false);
    }

    /*
     * WARNING - Removed try catching itself - possible behaviour change.
     */
    private boolean save(String path, boolean asPem) {
        ByteArrayWrapper baw;
        OutputStream fos = null;
        try {
            baw = new ByteArrayWrapper(this.getCert().getEncoded());
        }
        catch (CertificateEncodingException ex) {
            logger.error("", (Throwable)ex);
            return false;
        }
        try {
            fos = Files.newOutputStream(Paths.get(path, new String[0]), new OpenOption[0]);
            if (asPem) {
                fos.write("-----BEGIN CERTIFICATE-----\n".getBytes());
                baw.storeBase64(fos);
                fos.write("\n-----END CERTIFICATE-----".getBytes());
            } else {
                baw.store(fos);
            }
            boolean ex = true;
            return ex;
        }
        catch (IOException ex) {
            logger.error("", (Throwable)ex);
        }
        finally {
            if (fos != null) {
                try {
                    fos.close();
                }
                catch (IOException ex) {
                    logger.error("", (Throwable)ex);
                }
            }
        }
        return false;
    }

    public boolean equals(Object obj) {
        if (obj == null) {
            return false;
        }
        if (this.getClass() != obj.getClass()) {
            return false;
        }
        CertificateFull other = (CertificateFull)obj;
        if (!Arrays.equals(this.id, other.id)) {
            return false;
        }
        if (!Objects.equals(this.certificateObject, other.certificateObject)) {
            return false;
        }
        if (!Objects.equals(this.privateKeyObject, other.privateKeyObject)) {
            return false;
        }
        return Objects.equals(this.publicKeyObject, other.publicKeyObject);
    }

    public int hashCode() {
        int hash = 5;
        hash = 11 * hash + Arrays.hashCode(this.id);
        return hash;
    }
}

