/*
 * Decompiled with CFR 0.152.
 * 
 * Could not load the following classes:
 *  iaik.asn1.structures.DistributionPoint
 *  iaik.x509.X509CRL
 *  iaik.x509.X509Certificate
 *  iaik.x509.X509ExtensionInitException
 *  iaik.x509.extensions.CRLDistributionPoints
 *  md.cts.moldsign.transferobjects.models.CertificateModel
 *  org.slf4j.Logger
 *  org.slf4j.LoggerFactory
 */
package md.cts.cryptography.providers;

import iaik.asn1.structures.DistributionPoint;
import iaik.x509.X509CRL;
import iaik.x509.X509Certificate;
import iaik.x509.X509ExtensionInitException;
import iaik.x509.extensions.CRLDistributionPoints;
import java.io.IOException;
import java.security.cert.CRLException;
import java.security.cert.Certificate;
import java.security.cert.CertificateExpiredException;
import java.security.cert.CertificateNotYetValidException;
import java.util.ArrayList;
import java.util.Collection;
import java.util.Collections;
import java.util.Date;
import java.util.Enumeration;
import java.util.HashMap;
import java.util.HashSet;
import java.util.LinkedList;
import java.util.List;
import java.util.Map;
import md.cts.cryptography.certificates.OCSPChecker;
import md.cts.cryptography.certificates.wrappers.CRLWrapper;
import md.cts.cryptography.providers.CertificateProvider;
import md.cts.moldsign.transferobjects.models.CertificateModel;
import md.cts.pkcs11.cards.exceptions.OperationFailedException;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

public final class GlobalCertificateProvider {
    private static final Logger logger = LoggerFactory.getLogger(GlobalCertificateProvider.class);
    private static final List<String> validPolicyOidList = List.of("1.2.498.3.14.1.1", "1.2.498.3.14.1.2", "1.2.498.3.14.2.1", "1.2.498.3.14.2.2", "1.2.498.3.3.1", "1.2.498.3.3.2", "1.2.498.3.3.3", "1.2.498.3.3.4", "1.2.498.3.3.5", "1.2.498.3.14.4.1", "1.2.498.3.14.5.1", "1.2.498.3.14.4.2", "1.2.498.3.14.5.2", "1.2.498.3.15.1.1", "1.2.498.3.14.3.1", "1.2.498.3.10.2", "1.2.498.3.32.1.1");
    private static GlobalCertificateProvider instance;
    private final Map<String, CertificateProvider> providers = Collections.synchronizedMap(new HashMap());
    private final Map<String, CertificateProvider> trustedProviders = Collections.synchronizedMap(new HashMap());

    private GlobalCertificateProvider() {
    }

    public static GlobalCertificateProvider get() {
        if (instance == null) {
            instance = new GlobalCertificateProvider();
        }
        return instance;
    }

    private static boolean incorporate(List<String> list, String value) {
        for (String item : list) {
            if (value == null || !value.equals(item)) continue;
            return true;
        }
        return false;
    }

    private static boolean isOidValidForOperation(String oid, int operation) {
        if (oid != null && !oid.isEmpty()) {
            return operation == 1 || operation == 2;
        }
        return false;
    }

    public void refreshProviderCertificates() {
        for (String providerId : this.providers.keySet()) {
            try {
                this.providers.get(providerId).refreshCertificates();
            }
            catch (OperationFailedException ex) {
                logger.warn("The certificates from certificate provider with name {} could not be refreshed", (Object)providerId);
                logger.error("", (Throwable)ex);
            }
        }
    }

    public Collection<CertificateModel> getCertificateModels(boolean onlyCertsWithPrivateKeys, String providerId) {
        logger.info("getCertificateModels(providerId:{})", (Object)providerId);
        CertificateProvider provider = this.providers.get(providerId);
        if (provider == null) {
            logger.info("provider == null");
            return new HashSet<CertificateModel>();
        }
        return provider.getCertificates(onlyCertsWithPrivateKeys);
    }

    public CertificateModel getCertificate(String providerId, String certificateId) {
        CertificateProvider provider = this.providers.get(providerId);
        for (CertificateModel cert : provider.getCertificates(false)) {
            if (!certificateId.equals(cert.getCertificateId())) continue;
            return cert;
        }
        return null;
    }

    public CRLWrapper getCRLInfo(CertificateModel certificate) {
        CRLDistributionPoints distributions;
        try {
            distributions = (CRLDistributionPoints)certificate.getCertificate().getExtension(CRLDistributionPoints.oid);
        }
        catch (X509ExtensionInitException ex) {
            return null;
        }
        if (distributions != null) {
            Enumeration distPoint;
            Enumeration edp = distPoint = distributions.getDistributionPoints();
            while (edp.hasMoreElements()) {
                DistributionPoint dp = (DistributionPoint)edp.nextElement();
                if (dp.containsUriDpName()) {
                    try {
                        X509CRL crl = dp.loadCrl();
                        String[] uris = dp.getDistributionPointNameURIs();
                        if (uris != null && uris.length > 0) {
                            return new CRLWrapper(crl, uris[0]);
                        }
                    }
                    catch (IOException | CRLException ex) {
                        logger.warn("Cannot get CRL for entry: {}", (Object)dp);
                        logger.error("", (Throwable)ex);
                    }
                }
                logger.warn("CRL distribution points list is empty");
            }
        } else {
            logger.warn("No CRL distribution points defined for this certificate");
        }
        return null;
    }

    private boolean isCertificateValidForOID(CertificateModel certificate) {
        String policyId = certificate.getPolicyOid();
        logger.info("check for valid policyId={}", (Object)policyId);
        return GlobalCertificateProvider.incorporate(validPolicyOidList, policyId);
    }

    private int verifyCertificate(CertificateModel certificate, Date verificationTime) {
        int result = 3;
        try {
            certificate.getCertificate().checkValidity(verificationTime);
        }
        catch (CertificateExpiredException | CertificateNotYetValidException ex) {
            result = 1;
            certificate.setVerified(result);
            return result;
        }
        OCSPChecker ocsp = new OCSPChecker(certificate);
        Boolean ocspRevoked = ocsp.isRevoked(verificationTime);
        if (ocspRevoked != null) {
            result = ocspRevoked != false ? 2 : 0;
            certificate.setVerified(result);
            return result;
        }
        CRLWrapper crl = this.getCRLInfo(certificate);
        if (crl != null) {
            result = 0;
            boolean revoked = crl.getCrl().isRevoked((Certificate)certificate.getCertificate());
            if (revoked) {
                if (crl.getCrl().getRevokedCertificate((java.security.cert.X509Certificate)certificate.getCertificate()) != null) {
                    Date revocationDate = crl.getCrl().getRevokedCertificate((java.security.cert.X509Certificate)certificate.getCertificate()).getRevocationDate();
                    if (revocationDate != null && revocationDate.before(verificationTime)) {
                        result = 2;
                    }
                } else {
                    result = 2;
                }
            }
            certificate.setVerified(result);
            return result;
        }
        return result;
    }

    public void validateCertificate(CertificateModel certificate, int operation) throws OperationFailedException {
        this.validateCertificate(certificate, new Date(), operation);
    }

    public void validateCertificate(CertificateModel certificate, Date signingTime, int operation) throws OperationFailedException {
        logger.info("validate for operation {}", (Object)operation);
        if (operation != 3 && !GlobalCertificateProvider.isOidValidForOperation(certificate.getPolicyOid(), operation)) {
            throw new OperationFailedException("exception.certificate.not_valid_for_operation", new Exception("Certificate is not valid"));
        }
        if (!this.validateCertificateChain(certificate)) {
            throw new OperationFailedException("exception.certificate.not_trusted", new Exception("Certificate is not valid"));
        }
        int certificateStatus = this.verifyCertificate(certificate, signingTime);
        if (certificateStatus == 1) {
            throw new OperationFailedException("exception.certificate.not_valid", new Exception("Certificate is not valid"));
        }
        if (certificateStatus == 2) {
            throw new OperationFailedException("exception.certificate.revoked", new Exception("Certificate is not valid"));
        }
        if (certificateStatus == 3) {
            throw new OperationFailedException("exception.certificate.status_unavailable", new Exception("Certificate is not valid"));
        }
    }

    private boolean validateCertificateChain(CertificateModel certificate) {
        boolean trusted = false;
        List<CertificateModel> certificateChain = this.getCertificateChain(certificate);
        for (CertificateModel chainCert : certificateChain) {
            if (!chainCert.isTrusted()) continue;
            trusted = true;
            break;
        }
        if (!trusted) {
            certificate.setVerified(4);
        }
        return trusted;
    }

    public List<CertificateModel> getCertificateChain(CertificateModel certificate) {
        LinkedList<CertificateModel> chain = new LinkedList<CertificateModel>();
        chain.add(certificate);
        CertificateModel issuer = this.findIssuer(certificate);
        while (issuer != null && !this.checkIfIssuer(issuer.getCertificate(), issuer.getCertificate())) {
            try {
                issuer.getCertificate().checkValidity();
            }
            catch (CertificateExpiredException | CertificateNotYetValidException ex) {
                issuer.setVerified(1);
            }
            chain.add(issuer);
            issuer = this.findIssuer(issuer);
        }
        if (issuer != null && !issuer.equals((Object)certificate)) {
            chain.add(issuer);
        }
        return chain;
    }

    public synchronized void registerProvider(CertificateProvider provider, boolean trusted) {
        if (provider == null) {
            logger.error("registerProvider(null)");
            return;
        }
        String providerId = provider.getId();
        logger.info("registerProvider(providerId:{} trusted:{})", (Object)providerId, (Object)trusted);
        try {
            provider.refreshCertificates();
        }
        catch (OperationFailedException ex) {
            logger.error("", (Throwable)ex);
        }
        if (trusted) {
            this.trustedProviders.put(providerId, provider);
        } else {
            this.providers.put(providerId, provider);
        }
    }

    public synchronized void removeProvider(String providerId) {
        this.providers.remove(providerId);
        this.trustedProviders.remove(providerId);
        logger.info("removeProvider(providerId:{})  {} {}", new Object[]{providerId, this.providers.size(), this.trustedProviders.size()});
    }

    public CertificateModel findIssuer(CertificateModel certificate) {
        X509Certificate searchingCertificate = certificate.getCertificate();
        for (CertificateProvider provider : this.trustedProviders.values()) {
            for (CertificateModel cert : provider.getCertificates(false)) {
                if (!this.checkIfIssuer(searchingCertificate, cert.getCertificate())) continue;
                cert.setTrusted(true);
                return cert;
            }
        }
        for (CertificateProvider provider : this.providers.values()) {
            for (CertificateModel cert : provider.getCertificates(false)) {
                if (!this.checkIfIssuer(searchingCertificate, cert.getCertificate())) continue;
                return cert;
            }
        }
        return null;
    }

    private boolean checkIfIssuer(X509Certificate cert, X509Certificate father) {
        if (cert.getIssuerDN().equals(father.getSubjectDN())) {
            try {
                cert.verify(father.getPublicKey());
                return true;
            }
            catch (Exception ex) {
                logger.error("", (Throwable)ex);
            }
        }
        return false;
    }

    public List<CertificateModel> getCertificates(boolean onlyCertsWithPrivateKeys) {
        ArrayList<CertificateModel> certificates = new ArrayList<CertificateModel>();
        logger.info("providers.size() = {}", (Object)this.providers.size());
        for (String providerId : this.providers.keySet()) {
            logger.info("providerId = {}", (Object)providerId);
            certificates.addAll(this.getCertificatesForProvider(providerId, onlyCertsWithPrivateKeys));
        }
        logger.info("certificates.size() = {}", (Object)certificates.size());
        return certificates;
    }

    public List<CertificateModel> getCertificatesForProvider(String providerId, boolean onlyCertsWithPrivateKeys) {
        ArrayList<CertificateModel> resultCerts = new ArrayList<CertificateModel>();
        Collection<CertificateModel> certs = this.getCertificateModels(onlyCertsWithPrivateKeys, providerId);
        logger.info("CertificateModel.size={}", (Object)certs.size());
        for (CertificateModel cm : certs) {
            logger.info("cm {} {}", (Object)cm.getProviderId(), (Object)cm.getCertificateId());
            logger.info("cm subject= {}", (Object)cm.getSubjectDN());
            boolean isValid = false;
            boolean noFilter = false;
            if (this.isCertificateValidForOID(cm) || noFilter) {
                logger.info("isCertificateValidForOID=true");
                if (cm.isTrusted() || noFilter) {
                    logger.info("cm.isTrusted()=true");
                    isValid = true;
                } else {
                    logger.info("cm.isTrusted()=false");
                    List<CertificateModel> chain = this.getCertificateChain(cm);
                    logger.info("getCertificateChain.size={}", (Object)chain.size());
                    for (CertificateModel model : chain) {
                        if (model.isTrusted()) {
                            logger.info("model.isTrusted()=true {}", (Object)model.getSubjectDN());
                            this.verifyCertificate(cm, new Date());
                            cm.setTrusted(true);
                            isValid = true;
                            continue;
                        }
                        logger.info("model.isTrusted()=false {}", (Object)model.getSubjectDN());
                    }
                }
            } else {
                logger.info("isCertificateValidForOID=false");
            }
            if (!isValid) continue;
            resultCerts.add(cm);
        }
        return resultCerts;
    }
}

