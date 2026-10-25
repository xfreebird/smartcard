/*
 * Decompiled with CFR 0.152.
 * 
 * Could not load the following classes:
 *  iaik.asn1.ObjectID
 *  iaik.asn1.structures.AccessDescription
 *  iaik.asn1.structures.AlgorithmID
 *  iaik.x509.X509Certificate
 *  iaik.x509.X509ExtensionInitException
 *  iaik.x509.extensions.AuthorityInfoAccess
 *  iaik.x509.ocsp.BasicOCSPResponse
 *  iaik.x509.ocsp.CertID
 *  iaik.x509.ocsp.OCSPException
 *  iaik.x509.ocsp.OCSPRequest
 *  iaik.x509.ocsp.OCSPResponse
 *  iaik.x509.ocsp.ReqCert
 *  iaik.x509.ocsp.Request
 *  iaik.x509.ocsp.SingleResponse
 *  iaik.x509.ocsp.UnknownResponseException
 *  iaik.x509.ocsp.net.HttpOCSPRequest
 *  md.cts.moldsign.transferobjects.models.CertificateModel
 *  org.slf4j.Logger
 *  org.slf4j.LoggerFactory
 */
package md.cts.cryptography.certificates;

import iaik.asn1.ObjectID;
import iaik.asn1.structures.AccessDescription;
import iaik.asn1.structures.AlgorithmID;
import iaik.x509.X509Certificate;
import iaik.x509.X509ExtensionInitException;
import iaik.x509.extensions.AuthorityInfoAccess;
import iaik.x509.ocsp.BasicOCSPResponse;
import iaik.x509.ocsp.CertID;
import iaik.x509.ocsp.OCSPException;
import iaik.x509.ocsp.OCSPRequest;
import iaik.x509.ocsp.OCSPResponse;
import iaik.x509.ocsp.ReqCert;
import iaik.x509.ocsp.Request;
import iaik.x509.ocsp.SingleResponse;
import iaik.x509.ocsp.UnknownResponseException;
import iaik.x509.ocsp.net.HttpOCSPRequest;
import java.io.IOException;
import java.net.MalformedURLException;
import java.net.URL;
import java.security.InvalidKeyException;
import java.security.NoSuchAlgorithmException;
import java.security.SignatureException;
import java.util.Date;
import md.cts.cryptography.providers.GlobalCertificateProvider;
import md.cts.moldsign.transferobjects.models.CertificateModel;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

public final class OCSPChecker {
    private static final Logger logger = LoggerFactory.getLogger(OCSPChecker.class);
    private final CertificateModel certificate;
    private ReqCert reqCert;

    public OCSPChecker(CertificateModel certificate) {
        this.certificate = certificate;
    }

    public String getOCSPUri() {
        String ocspUri = null;
        logger.info("Getting OCSP from the certificate ...");
        try {
            logger.info("Get Authority Info Access (AIA)");
            AuthorityInfoAccess authorityInfoAccess = (AuthorityInfoAccess)this.certificate.getCertificate().getExtension(AuthorityInfoAccess.oid);
            if (authorityInfoAccess != null) {
                logger.info("Get OCSP entry from AIA");
                AccessDescription ad = authorityInfoAccess.getAccessDescription(ObjectID.ocsp);
                if (ad != null) {
                    ocspUri = ad.getUriAccessLocation();
                    logger.info("OCSP entry exists with URI:{}", (Object)ocspUri);
                }
            }
        }
        catch (X509ExtensionInitException ex) {
            logger.error("", (Throwable)ex);
        }
        return ocspUri;
    }

    public OCSPResponse getOCSPResponse() throws IllegalArgumentException {
        URL responderUrl;
        String url = this.getOCSPUri();
        if (url == null) {
            return null;
        }
        try {
            responderUrl = new URL(url);
        }
        catch (MalformedURLException ex) {
            logger.error("", (Throwable)ex);
            return null;
        }
        try {
            CertID certId;
            CertificateModel issuer = GlobalCertificateProvider.get().findIssuer(this.certificate);
            if (issuer == null) {
                return null;
            }
            try {
                certId = new CertID(AlgorithmID.sha1, issuer.getCertificate(), this.certificate.getCertificate());
            }
            catch (NoSuchAlgorithmException ex) {
                logger.error("", (Throwable)ex);
                return null;
            }
            this.reqCert = new ReqCert(0, (Object)certId);
            Request request = new Request(this.reqCert);
            OCSPRequest ocspRequest = new OCSPRequest();
            ocspRequest.setRequestList(new Request[]{request});
            logger.info("Connecting to {} for OCSP", (Object)responderUrl);
            HttpOCSPRequest httpOCSPRequest = new HttpOCSPRequest(responderUrl);
            int responseCode = httpOCSPRequest.postRequest(ocspRequest);
            if (responseCode < 400) {
                logger.info("Got response from {}:\nResponse code: {}\n Response message: {}", new Object[]{responderUrl, responseCode, httpOCSPRequest.getResponseMessage()});
                return httpOCSPRequest.getOCSPResponse();
            }
            logger.warn("Error connecting to {}:\nResponse code: {}\n Response message: {}", new Object[]{responderUrl, responseCode, httpOCSPRequest.getResponseMessage()});
        }
        catch (UnknownResponseException | IOException ex) {
            logger.error("", ex);
        }
        return null;
    }

    public Boolean isRevoked(Date checkingTime) {
        OCSPResponse ocspResponse = this.getOCSPResponse();
        if (ocspResponse != null) {
            int responseStatus = ocspResponse.getResponseStatus();
            if (responseStatus != 0) {
                logger.warn("Problem with the OCSP response: {}", (Object)ocspResponse.getResponseStatusName());
            } else {
                SingleResponse singleResponse;
                BasicOCSPResponse basicOCSPResponse = (BasicOCSPResponse)ocspResponse.getResponse();
                if (basicOCSPResponse.containsCertificates()) {
                    try {
                        X509Certificate x509Certificate = basicOCSPResponse.verify();
                    }
                    catch (OCSPException | InvalidKeyException | NoSuchAlgorithmException | SignatureException ex) {
                        logger.error("", ex);
                    }
                }
                try {
                    singleResponse = basicOCSPResponse.getSingleResponse(this.reqCert);
                }
                catch (OCSPException ex) {
                    return Boolean.FALSE;
                }
                if (singleResponse == null || singleResponse.getCertStatus() == null) {
                    return null;
                }
                int status = singleResponse.getCertStatus().getCertStatus();
                Date revocationTime = null;
                if (singleResponse.getCertStatus().getRevokedInfo() != null) {
                    try {
                        revocationTime = singleResponse.getCertStatus().getRevokedInfo().getRevocationTime();
                    }
                    catch (Exception ex) {
                        logger.error("", (Throwable)ex);
                    }
                }
                switch (status) {
                    case 0: {
                        return Boolean.FALSE;
                    }
                    case 1: {
                        if (revocationTime != null && checkingTime.after(revocationTime)) {
                            return Boolean.TRUE;
                        }
                        return Boolean.FALSE;
                    }
                    case 2: {
                        return null;
                    }
                }
            }
        } else {
            logger.info("Problem getting OCSP response from server");
        }
        return null;
    }
}

