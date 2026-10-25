/*
 * Decompiled with CFR 0.152.
 * 
 * Could not load the following classes:
 *  iaik.asn1.structures.AlgorithmID
 *  iaik.x509.ocsp.OCSPResponse
 *  iaik.xml.crypto.XSecProvider
 *  iaik.xml.crypto.dsig.DigestMethodImpl
 *  iaik.xml.crypto.xades.CRLRef
 *  iaik.xml.crypto.xades.CertID
 *  iaik.xml.crypto.xades.CompleteCertificateRefs
 *  iaik.xml.crypto.xades.CompleteRevocationRefs
 *  iaik.xml.crypto.xades.CounterSignature
 *  iaik.xml.crypto.xades.DataObjectFormat
 *  iaik.xml.crypto.xades.OCSPRef
 *  iaik.xml.crypto.xades.QualifyingProperties
 *  iaik.xml.crypto.xades.QualifyingPropertiesFactory
 *  iaik.xml.crypto.xades.SignatureTimeStamp
 *  iaik.xml.crypto.xades.SignedDataObjectProperties
 *  iaik.xml.crypto.xades.SignedProperties
 *  iaik.xml.crypto.xades.SignedSignatureProperties
 *  iaik.xml.crypto.xades.SigningCertificate
 *  iaik.xml.crypto.xades.SigningTime
 *  iaik.xml.crypto.xades.UnsignedProperties
 *  iaik.xml.crypto.xades.UnsignedSignatureProperties
 *  iaik.xml.crypto.xades.XAdESSignature
 *  iaik.xml.crypto.xades.XMLExtendContext
 *  iaik.xml.crypto.xades.dom.DOMExtensionContext
 *  iaik.xml.crypto.xades.impl.dom.properties.CounterSignatureImpl$DOMCounterSignContext
 *  md.cts.moldsign.transferobjects.models.CertificateModel
 *  md.cts.moldsign.transferobjects.models.XAdES.SigningReferenceModel
 *  md.cts.moldsign.transferobjects.models.XAdES.TimeStampModel
 *  md.cts.moldsign.transferobjects.models.XAdES.XAdESSignatureModel
 *  org.slf4j.Logger
 *  org.slf4j.LoggerFactory
 */
package md.cts.pkcs11.providers.workers.signatures;

import iaik.asn1.structures.AlgorithmID;
import iaik.x509.ocsp.OCSPResponse;
import iaik.xml.crypto.XSecProvider;
import iaik.xml.crypto.dsig.DigestMethodImpl;
import iaik.xml.crypto.xades.CRLRef;
import iaik.xml.crypto.xades.CertID;
import iaik.xml.crypto.xades.CompleteCertificateRefs;
import iaik.xml.crypto.xades.CompleteRevocationRefs;
import iaik.xml.crypto.xades.CounterSignature;
import iaik.xml.crypto.xades.DataObjectFormat;
import iaik.xml.crypto.xades.OCSPRef;
import iaik.xml.crypto.xades.QualifyingProperties;
import iaik.xml.crypto.xades.QualifyingPropertiesFactory;
import iaik.xml.crypto.xades.SignatureTimeStamp;
import iaik.xml.crypto.xades.SignedDataObjectProperties;
import iaik.xml.crypto.xades.SignedProperties;
import iaik.xml.crypto.xades.SignedSignatureProperties;
import iaik.xml.crypto.xades.SigningCertificate;
import iaik.xml.crypto.xades.SigningTime;
import iaik.xml.crypto.xades.UnsignedProperties;
import iaik.xml.crypto.xades.UnsignedSignatureProperties;
import iaik.xml.crypto.xades.XAdESSignature;
import iaik.xml.crypto.xades.XMLExtendContext;
import iaik.xml.crypto.xades.dom.DOMExtensionContext;
import iaik.xml.crypto.xades.impl.dom.properties.CounterSignatureImpl;
import java.io.File;
import java.io.FileInputStream;
import java.io.IOException;
import java.net.MalformedURLException;
import java.security.InvalidAlgorithmParameterException;
import java.security.Key;
import java.security.NoSuchAlgorithmException;
import java.security.PrivateKey;
import java.security.Provider;
import java.security.cert.X509CRL;
import java.security.cert.X509Certificate;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.Collections;
import java.util.Date;
import java.util.Iterator;
import java.util.LinkedList;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import javax.xml.crypto.KeySelector;
import javax.xml.crypto.MarshalException;
import javax.xml.crypto.XMLStructure;
import javax.xml.crypto.dom.DOMCryptoContext;
import javax.xml.crypto.dom.DOMStructure;
import javax.xml.crypto.dsig.DigestMethod;
import javax.xml.crypto.dsig.Reference;
import javax.xml.crypto.dsig.SignedInfo;
import javax.xml.crypto.dsig.XMLObject;
import javax.xml.crypto.dsig.XMLSignContext;
import javax.xml.crypto.dsig.XMLSignature;
import javax.xml.crypto.dsig.XMLSignatureException;
import javax.xml.crypto.dsig.XMLSignatureFactory;
import javax.xml.crypto.dsig.dom.DOMSignContext;
import javax.xml.crypto.dsig.dom.DOMValidateContext;
import javax.xml.crypto.dsig.keyinfo.KeyInfo;
import javax.xml.crypto.dsig.keyinfo.KeyInfoFactory;
import javax.xml.crypto.dsig.keyinfo.X509Data;
import javax.xml.crypto.dsig.spec.C14NMethodParameterSpec;
import md.cts.cryptography.certificates.OCSPChecker;
import md.cts.cryptography.certificates.wrappers.CRLWrapper;
import md.cts.cryptography.providers.GlobalCertificateProvider;
import md.cts.moldsign.transferobjects.models.CertificateModel;
import md.cts.moldsign.transferobjects.models.XAdES.SigningReferenceModel;
import md.cts.moldsign.transferobjects.models.XAdES.TimeStampModel;
import md.cts.moldsign.transferobjects.models.XAdES.XAdESSignatureModel;
import md.cts.pkcs11.cards.exceptions.OperationFailedException;
import md.cts.pkcs11.providers.workers.signatures.KeyValueKeySelector;
import md.cts.pkcs11.providers.workers.signatures.SigWrapHack;
import md.cts.pkcs11.providers.workers.signatures.SignatureFile;
import md.cts.pkcs11.util.ByteArrayWrapper;
import md.cts.sim.HTTPTSPTimeStampProcessorSI;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.w3c.dom.Element;
import org.w3c.dom.Node;
import org.w3c.dom.Text;

public final class SignatureInstance {
    private static final Logger logger = LoggerFactory.getLogger(SignatureInstance.class);
    private final XSecProvider xsecProvider;
    private final SignatureFile sigFile;
    private final String BASIC_ID;
    private final XMLSignatureFactory sfac;
    private final QualifyingPropertiesFactory qfac;
    private final KeyInfoFactory kfac;
    private String signAlgorithmName;
    private XAdESSignature signature;
    private DOMValidateContext valContext;

    private SignatureInstance(XSecProvider xsecProvider, String BASIC_ID, SignatureFile sigFile) {
        logger.info("new SignatureInstance() XSecProvider={}", (Object)xsecProvider.getName());
        this.xsecProvider = xsecProvider;
        this.BASIC_ID = BASIC_ID;
        this.sigFile = sigFile;
        this.sfac = XMLSignatureFactory.getInstance("DOM", (Provider)xsecProvider);
        this.qfac = QualifyingPropertiesFactory.getInstance((String)"DOM", (Provider)xsecProvider);
        this.kfac = KeyInfoFactory.getInstance("DOM", (Provider)xsecProvider);
    }

    public SignatureInstance(XSecProvider xsecProvider, SignatureFile sigFile) {
        this(xsecProvider, UUID.randomUUID().toString(), sigFile);
    }

    public SignatureInstance(XSecProvider xsecProvider, Node node, SignatureFile sigFile) throws OperationFailedException {
        this(xsecProvider, node.getAttributes().getNamedItem("Id").getNodeValue(), sigFile);
        this.valContext = new DOMValidateContext(new KeyValueKeySelector(), node);
        Iterator<Map.Entry<String, Element>> it = this.valContext.iterator();
        while (it.hasNext()) {
            Map.Entry<String, Element> object = it.next();
            Element e = object.getValue();
            this.valContext.setIdAttributeNS(e, null, "Id");
        }
        try {
            this.signature = (XAdESSignature)this.sfac.unmarshalXMLSignature(this.valContext);
        }
        catch (MarshalException ex) {
            throw new OperationFailedException("exception.signatures.not_valid", ex);
        }
    }

    public void prepareSignature(QualifyingProperties qp, List<XMLStructure> content, SignedInfo si, KeyInfo ki) {
        XMLObject qpObj = this.sfac.newXMLObject(Collections.nCopies(1, qp), null, null, null);
        ArrayList<XMLObject> xmlObjects = new ArrayList<XMLObject>();
        xmlObjects.add(qpObj);
        for (XMLStructure structure : content) {
            xmlObjects.add((XMLObject)structure);
        }
        this.signature = (XAdESSignature)this.sfac.newXMLSignature(si, ki, xmlObjects, "Signature-" + this.BASIC_ID, "SignatureValue-" + this.BASIC_ID);
    }

    private X509Certificate getSigningCertificate() {
        X509Certificate cert = null;
        KeyInfo ki = this.signature.getKeyInfo();
        for (XMLStructure o : ki.getContent()) {
            if (!(o instanceof X509Data)) continue;
            for (Object co : ((X509Data)o).getContent()) {
                if (!(co instanceof X509Certificate)) continue;
                cert = (X509Certificate)co;
            }
        }
        return cert;
    }

    public DOMSignContext addCounterSignature(Key key, XMLSignature sig, Node parent) throws OperationFailedException {
        DOMExtensionContext extensionContext = new DOMExtensionContext((DOMCryptoContext)this.valContext);
        for (Map.Entry object : extensionContext) {
            Element e = (Element)object.getValue();
            extensionContext.setIdAttributeNS(e, null, "Id");
        }
        CounterSignature cs = this.qfac.newCounterSignature(sig);
        try {
            this.signature.appendCounterSignature(cs, (XMLExtendContext)extensionContext);
        }
        catch (MarshalException | XMLSignatureException ex) {
            logger.error("addCounterSignature", (Throwable)ex);
        }
        CounterSignatureImpl.DOMCounterSignContext dOMCounterSignContext = extensionContext.createCounterSignContext(KeySelector.singletonKeySelector(key), parent);
        try {
            sig.sign((XMLSignContext)dOMCounterSignContext);
        }
        catch (MarshalException | XMLSignatureException ex) {
            logger.error("call", (Throwable)ex);
            throw new OperationFailedException(ex);
        }
        return dOMCounterSignContext;
    }

    public void addCompleteReferences(DOMSignContext context, CertificateModel certificate) throws OperationFailedException {
        ArrayList<CertID> certRefs = new ArrayList<CertID>();
        ArrayList<CRLRef> crlRefs = new ArrayList<CRLRef>();
        ArrayList<OCSPRef> ocspRefs = new ArrayList<OCSPRef>();
        CertificateModel currentCertificate = certificate;
        CertificateModel parrent = GlobalCertificateProvider.get().findIssuer(certificate);
        while (parrent != null && !currentCertificate.equals((Object)parrent)) {
            try {
                OCSPChecker ocsp;
                OCSPResponse rsp;
                logger.info("prepare digest algo r");
                DigestMethod digest = this.sfac.newDigestMethod(this.getDigestMethodAlgorithmURI(), null);
                logger.info("prepare cert id r");
                CertID certReference = this.qfac.newCertID(null, (X509Certificate)currentCertificate.getCertificate(), digest);
                logger.info("ok cert id 2");
                certRefs.add(certReference);
                CRLWrapper crl = GlobalCertificateProvider.get().getCRLInfo(currentCertificate);
                if (crl != null) {
                    crlRefs.add(this.qfac.newCRLRef((X509CRL)crl.getCrl(), this.sfac.newDigestMethod(this.getDigestMethodAlgorithmURI(), null), crl.getUri()));
                }
                if ((rsp = (ocsp = new OCSPChecker(certificate)).getOCSPResponse()) != null) {
                    ocspRefs.add(this.qfac.newOCSPRef(rsp.getEncoded(), this.sfac.newDigestMethod(this.getDigestMethodAlgorithmURI(), null), ocsp.getOCSPUri()));
                }
            }
            catch (InvalidAlgorithmParameterException | NoSuchAlgorithmException ex) {
                logger.error("addCompleteReferences", (Throwable)ex);
                throw new OperationFailedException("exception.signatures.cannot_sign", ex);
            }
            currentCertificate = parrent;
            parrent = GlobalCertificateProvider.get().findIssuer(currentCertificate);
        }
        CompleteCertificateRefs compCertRefs = this.qfac.newCompleteCertificateRefs(certRefs, "CompleteCertificateRefs-" + this.BASIC_ID);
        CompleteRevocationRefs compRevRefs = this.qfac.newCompleteRevocationRefs(crlRefs, ocspRefs, null, "CompleteRevocationRefs-" + this.BASIC_ID);
        DOMExtensionContext extensionContext = new DOMExtensionContext((DOMCryptoContext)context);
        try {
            this.signature.appendValidationRefs(compCertRefs, compRevRefs, null, null, (XMLExtendContext)extensionContext);
        }
        catch (MarshalException | XMLSignatureException ex) {
            logger.error("call", (Throwable)ex);
            throw new OperationFailedException(ex);
        }
    }

    public void addTimeStamp(DOMSignContext context, X509Certificate cert) throws OperationFailedException {
        SignatureTimeStamp st;
        ByteArrayWrapper bew = new ByteArrayWrapper(cert.getSerialNumber().toByteArray());
        bew.reverse();
        try {
            st = this.qfac.newSignatureTimeStamp(this.sfac.newCanonicalizationMethod("http://www.w3.org/TR/2001/REC-xml-c14n-20010315", (C14NMethodParameterSpec)null), "SignatureTimeStamp-" + this.BASIC_ID, null);
        }
        catch (NoSuchAlgorithmException ex) {
            logger.error("addTimeStamp", (Throwable)ex);
            throw new OperationFailedException("exception.general.no_such_algorithm", ex);
        }
        catch (InvalidAlgorithmParameterException ex) {
            logger.error("addTimeStamp", (Throwable)ex);
            throw new OperationFailedException("exception.general.invalid_algorithm_parameter", ex);
        }
        HTTPTSPTimeStampProcessorSI tsp = null;
        try {
            tsp = new HTTPTSPTimeStampProcessorSI("http://tsp.pki.gov.md/moldsign2/" + String.valueOf(bew), 1200, AlgorithmID.sha256);
        }
        catch (MalformedURLException ex) {
            logger.error("addTimeStamp", (Throwable)ex);
        }
        DOMExtensionContext extensionContext = new DOMExtensionContext((DOMCryptoContext)context);
        extensionContext.put((Object)"iaik.xml.crypto.xades.timestamp.TimeStampProcessor", (Object)tsp);
        try {
            this.signature.appendSignatureTimeStamp(st, (XMLExtendContext)extensionContext);
        }
        catch (MarshalException | XMLSignatureException ex) {
            logger.error("addTimeStamp", (Throwable)ex);
            throw new OperationFailedException(ex);
        }
    }

    public SignedInfo prepareSignInfo(XAdESSignature originalSignature, byte[] digest) throws OperationFailedException {
        ArrayList<Reference> refs = new ArrayList<Reference>(2);
        String originalSignatureId = originalSignature.getSignatureValue().getId();
        if (originalSignatureId == null || "".equalsIgnoreCase(originalSignatureId.trim())) {
            throw new OperationFailedException("exception.signatures.not_valid", new Exception("Cannot find Id of the signature value element"));
        }
        try {
            Reference spRef = this.sfac.newReference("#SignedProperties-" + this.BASIC_ID, this.sfac.newDigestMethod(this.getDigestMethodAlgorithmURI(), null), null, "http://uri.etsi.org/01903#SignedProperties", "SignedProperties-Reference-" + this.BASIC_ID);
            Reference csRef = this.sfac.newReference("#" + originalSignatureId, this.sfac.newDigestMethod(this.getDigestMethodAlgorithmURI(), null), null, "http://uri.etsi.org/01903#CountersignedSignature", "SignedSignature-Reference-" + this.BASIC_ID);
            refs.add(spRef);
            refs.add(csRef);
        }
        catch (InvalidAlgorithmParameterException | NoSuchAlgorithmException ex) {
            logger.error("prepareSignInfo", (Throwable)ex);
            throw new OperationFailedException("exception.signatures.cannot_sign", ex);
        }
        SignedInfo csSI = null;
        try {
            csSI = this.sfac.newSignedInfo(this.sfac.newCanonicalizationMethod("http://www.w3.org/2001/10/xml-exc-c14n#", (C14NMethodParameterSpec)null), this.sfac.newSignatureMethod(this.getSignatureMethodAlgorithmURI(), null), refs, "SignedInfo-" + this.BASIC_ID);
        }
        catch (InvalidAlgorithmParameterException | NoSuchAlgorithmException ex) {
            logger.error("prepareSignInfo", (Throwable)ex);
        }
        return csSI;
    }

    public String getSignatureMethodAlgorithmURI() {
        if ("SHA-1".equals(this.signAlgorithmName)) {
            return "http://www.w3.org/2000/09/xmldsig#rsa-sha1";
        }
        return "http://www.w3.org/2001/04/xmldsig-more#rsa-sha256";
    }

    public String getDigestMethodAlgorithmURI() {
        if ("SHA-1".equals(this.signAlgorithmName)) {
            return "http://www.w3.org/2000/09/xmldsig#sha1";
        }
        return "http://www.w3.org/2001/04/xmlenc#sha256";
    }

    public String getStandardEtsiDigestMethodAlgorithmURI() {
        return "http://www.w3.org/2000/09/xmldsig#" + this.getDigestMethodAlgorithmURI().toLowerCase();
    }

    public SignedInfo prepareSignInfoEnveloping(Map<File, byte[]> files) throws OperationFailedException {
        SignedInfo si;
        ArrayList<Reference> refs = new ArrayList<Reference>(2);
        try {
            Reference spRef = this.sfac.newReference("#SignedProperties-" + this.BASIC_ID, this.sfac.newDigestMethod(this.getDigestMethodAlgorithmURI(), null), null, "http://uri.etsi.org/01903#SignedProperties", "SignedProperties-Reference-" + this.BASIC_ID);
            refs.add(spRef);
            for (File inputFile : files.keySet()) {
                String fileName = inputFile.getName();
                Reference sdRef = this.sfac.newReference("#FileObject-" + this.BASIC_ID, this.sfac.newDigestMethod(this.getDigestMethodAlgorithmURI(), null), null, null, "SignedFile-Reference-" + this.BASIC_ID + "-" + fileName);
                refs.add(sdRef);
            }
            si = this.sfac.newSignedInfo(this.sfac.newCanonicalizationMethod("http://www.w3.org/TR/2001/REC-xml-c14n-20010315#WithComments", (C14NMethodParameterSpec)null), this.sfac.newSignatureMethod(this.getSignatureMethodAlgorithmURI(), null), refs, "SignedInfo-" + this.BASIC_ID);
        }
        catch (InvalidAlgorithmParameterException | NoSuchAlgorithmException ex) {
            logger.error("", (Throwable)ex);
            throw new OperationFailedException("exception.signatures.cannot_sign", ex);
        }
        return si;
    }

    public SignedInfo prepareSignInfo(Map<File, byte[]> files) throws OperationFailedException {
        SignedInfo si;
        ArrayList<Reference> refs = new ArrayList<Reference>(2);
        try {
            Reference spRef = this.sfac.newReference("#SignedProperties-" + this.BASIC_ID, this.sfac.newDigestMethod(this.getDigestMethodAlgorithmURI(), null), null, "http://uri.etsi.org/01903#SignedProperties", "SignedProperties-Reference-" + this.BASIC_ID);
            refs.add(spRef);
            for (File inputFile : files.keySet()) {
                String fileName = inputFile.getName();
                Reference sdRef = this.sfac.newReference("file:/" + fileName, this.sfac.newDigestMethod(this.getDigestMethodAlgorithmURI(), null), null, null, "SignedFile-Reference-" + this.BASIC_ID + "-" + fileName, files.get(inputFile));
                refs.add(sdRef);
            }
            si = this.sfac.newSignedInfo(this.sfac.newCanonicalizationMethod("http://www.w3.org/TR/2001/REC-xml-c14n-20010315", (C14NMethodParameterSpec)null), this.sfac.newSignatureMethod(this.getSignatureMethodAlgorithmURI(), null), refs, "SignedInfo-" + this.BASIC_ID);
        }
        catch (InvalidAlgorithmParameterException | NoSuchAlgorithmException ex) {
            logger.error("", (Throwable)ex);
            throw new OperationFailedException("exception.signatures.cannot_sign", ex);
        }
        return si;
    }

    public KeyInfo prepareKeyInfo(X509Certificate signerCert) {
        ArrayList<X509Certificate> x509DataContent = new ArrayList<X509Certificate>();
        x509DataContent.add(signerCert);
        X509Data x509Data = this.kfac.newX509Data(x509DataContent);
        ArrayList<X509Data> keyInfoContent = new ArrayList<X509Data>();
        keyInfoContent.add(x509Data);
        return this.kfac.newKeyInfo(keyInfoContent, "KeyInfo-" + this.BASIC_ID);
    }

    public QualifyingProperties prepareQualifyingProperties(X509Certificate signerCert, List<DataObjectFormat> ldof) throws OperationFailedException {
        SigWrapHack certID;
        try {
            logger.info("prepare digest algo");
            DigestMethod digest = this.sfac.newDigestMethod(this.getDigestMethodAlgorithmURI(), null);
            logger.info("prepare cert id");
            certID = new SigWrapHack(signerCert, (DigestMethodImpl)digest);
        }
        catch (InvalidAlgorithmParameterException | NoSuchAlgorithmException ex) {
            logger.error("", (Throwable)ex);
            throw new OperationFailedException("exception.signatures.cannot_sign", ex);
        }
        ArrayList<SigWrapHack> certIDs = new ArrayList<SigWrapHack>();
        certIDs.add(certID);
        SigningCertificate sc = this.qfac.newSigningCertificate(certIDs);
        SigningTime st = this.qfac.newSigningTime();
        SignedSignatureProperties ssp = this.qfac.newSignedSignatureProperties(st, sc, null, null, null, null);
        SignedDataObjectProperties sdop = this.qfac.newSignedDataObjectProperties(ldof, null, null, null, "SignedDataObjectProperties-" + this.BASIC_ID);
        SignedProperties sp = this.qfac.newSignedProperties(ssp, sdop, "SignedProperties-" + this.BASIC_ID);
        return this.qfac.newQualifyingProperties(sp, "#Signature-" + this.BASIC_ID, null);
    }

    public DataObjectFormat prepareDataObjectProperties(String file) {
        String mime = file != null && file.toLowerCase().trim().endsWith("txt") ? "text/plain" : "application/octet-stream";
        return this.qfac.newDataObjectFormat(file, null, mime, null, "SignedFile-Reference-" + this.BASIC_ID + "-" + file);
    }

    public CertificateModel getSigner() throws OperationFailedException {
        List<XMLStructure> keyInfoContent = this.signature.getKeyInfo().getContent();
        for (XMLStructure object : keyInfoContent) {
            if (!(object instanceof X509Data)) continue;
            List<?> x509DataContent = ((X509Data)object).getContent();
            for (Object object1 : x509DataContent) {
                if (!(object1 instanceof X509Certificate)) continue;
                CertificateModel result = new CertificateModel((X509Certificate)object1);
                return result;
            }
        }
        throw new OperationFailedException("exception.signatures.certificate_not_present", null);
    }

    public boolean validate(Map<String, byte[]> files) throws OperationFailedException {
        UnsignedSignatureProperties usp;
        CertificateModel signer = this.getSigner();
        Date signingTime = new Date();
        try {
            signingTime = this.signature.getQualifyingProperties().getSignedProperties().getSignedSignatureProperties().getSigningTime().getDate();
        }
        catch (Exception ex) {
            logger.error("Signing time not available", (Throwable)ex);
        }
        QualifyingProperties qp = this.signature.getQualifyingProperties();
        UnsignedProperties up = qp.getUnsignedProperties();
        if (up != null && (usp = up.getUnsignedSignatureProperties()) != null) {
            for (Object o : usp.getSignatureTimeStamps()) {
                if (!(o instanceof SignatureTimeStamp)) continue;
                SignatureTimeStamp sts = (SignatureTimeStamp)o;
                TimeStampModel tsm = new TimeStampModel();
                X509Certificate cert = sts.getTimeStampToken().getTSACertificate();
                signingTime = sts.getTimeStampToken().getTime();
                GlobalCertificateProvider.get().validateCertificate(new CertificateModel(cert), signingTime, 3);
            }
        }
        GlobalCertificateProvider.get().validateCertificate(signer, signingTime, 1);
        Iterator<Reference> i = this.signature.getSignedInfo().getReferences().iterator();
        int j = 0;
        while (i.hasNext()) {
            Reference ref = i.next();
            String id = ref.getURI();
            if (ref.getURI().startsWith("file")) {
                boolean hashFound = false;
                for (String f : files.keySet()) {
                    if (!Arrays.equals(ref.getDigestValue(), files.get(f))) continue;
                    hashFound = true;
                    break;
                }
                if (!hashFound) {
                    return false;
                }
            } else {
                try {
                    if (!ref.validate(this.valContext)) {
                        return false;
                    }
                }
                catch (XMLSignatureException ex) {
                    logger.error("", (Throwable)ex);
                }
            }
            ++j;
        }
        try {
            return this.signature.getSignatureValue().validate(this.valContext);
        }
        catch (XMLSignatureException ex) {
            logger.error("", (Throwable)ex);
            return false;
        }
    }

    public String getDigestAlgorithmFromFile() throws OperationFailedException {
        for (Reference o : this.signature.getSignedInfo().getReferences()) {
            if (!(o instanceof Reference)) continue;
            Reference ref = o;
            return ref.getDigestMethod().getAlgorithm();
        }
        throw new OperationFailedException("exception.signatures.certificate_not_present", null);
    }

    public String getObjectIDFromSignedFile() {
        String fileObjectUri = null;
        for (Reference o : this.signature.getSignedInfo().getReferences()) {
            Reference ref;
            String uri;
            if (!(o instanceof Reference) || !(uri = (ref = o).getURI()).startsWith("#FileObject-")) continue;
            fileObjectUri = uri;
        }
        if (fileObjectUri != null) {
            return fileObjectUri.substring(1);
        }
        return null;
    }

    public XAdESSignatureModel getSignatureInformation() throws OperationFailedException {
        UnsignedSignatureProperties usp;
        X509Certificate signingCertificate;
        XAdESSignatureModel model = new XAdESSignatureModel();
        model.setId(this.signature.getId());
        QualifyingProperties qp = this.signature.getQualifyingProperties();
        SignedProperties sp = qp.getSignedProperties();
        SignedSignatureProperties ssp = sp.getSignedSignatureProperties();
        if (ssp != null && ssp.getSigningTime() != null) {
            model.setTimeSigned(ssp.getSigningTime().getDate());
        }
        if ((signingCertificate = this.getSigningCertificate()) != null) {
            model.setSigner(new CertificateModel(signingCertificate));
        }
        LinkedList<SigningReferenceModel> references = new LinkedList<SigningReferenceModel>();
        model.setSignatureFormat("Embedded");
        for (Reference o : this.signature.getSignedInfo().getReferences()) {
            if (!(o instanceof Reference)) continue;
            Reference ref = o;
            Object uri = ref.getURI();
            if (!((String)uri).startsWith("#") && !((String)uri).startsWith("file:/")) {
                uri = "file:/" + (String)uri;
            }
            if (((String)uri).startsWith("file:/")) {
                model.setSignatureFormat("Detached");
            }
            references.add(new SigningReferenceModel((String)uri, new ByteArrayWrapper(ref.getDigestValue()).asBase64()));
        }
        model.setReferences(references);
        UnsignedProperties up = qp.getUnsignedProperties();
        if (up != null && (usp = up.getUnsignedSignatureProperties()) != null) {
            CompleteCertificateRefs ccr;
            for (Object o : usp.getSignatureTimeStamps()) {
                if (!(o instanceof SignatureTimeStamp)) continue;
                SignatureTimeStamp sts = (SignatureTimeStamp)o;
                TimeStampModel tsm = new TimeStampModel();
                tsm.setTime(sts.getTimeStampToken().getTime());
                X509Certificate cert = sts.getTimeStampToken().getTSACertificate();
                tsm.setSigner(new CertificateModel(cert));
                model.setTimestamp(tsm);
                model.setType("XAdES-T");
            }
            if (usp.getCounterSignatures() != null) {
                List counterSignatures = up.getUnsignedSignatureProperties().getCounterSignatures();
                ArrayList counterSignatureModels = new ArrayList(counterSignatures.size());
                for (Object o : counterSignatures) {
                    CounterSignature cs;
                    String id;
                    SignatureInstance sig;
                    if (!(o instanceof CounterSignature) || (sig = this.sigFile.getSignatureByID(this.xsecProvider, id = (cs = (CounterSignature)o).getSignature().getId())) == null) continue;
                    XAdESSignatureModel csModel = sig.getSignatureInformation();
                    counterSignatureModels.add(csModel);
                }
                model.setCounterSignatures((List)counterSignatureModels);
            }
            if ((ccr = usp.getCompleteCertificateRefs()) != null) {
                for (Object ccrObject : ccr.getCertRefs()) {
                    if (!(ccrObject instanceof CertID)) continue;
                    CertID certRef = (CertID)ccrObject;
                    certRef.getURI();
                    certRef.getIssuerSerial();
                    certRef.getCertDigest().getDigestMethod();
                    certRef.getCertDigest().getDigestValue();
                    model.setType("XAdES-C");
                }
            }
            CompleteRevocationRefs crr = usp.getCompleteRevocationRefs();
            if (ccr != null) {
                for (Object crrObject : crr.getCRLRefs()) {
                    if (!(crrObject instanceof CRLRef)) continue;
                    CRLRef crrRef = (CRLRef)crrObject;
                    crrRef.getCRLIdentifier();
                    model.setType("XAdES-C");
                }
                for (Object crrObject : crr.getOCSPRefs()) {
                    if (!(crrObject instanceof OCSPRef)) continue;
                    OCSPRef ocspRef = (OCSPRef)crrObject;
                    ocspRef.getOCSPIdentifier();
                    model.setType("XAdES-C");
                }
            }
        }
        return model;
    }

    public DOMSignContext sign(PrivateKey key, Node parrentNode) throws OperationFailedException {
        DOMSignContext context = new DOMSignContext(key, parrentNode);
        context.setProperty("javax.xml.crypto.dsig.cacheReference", Boolean.TRUE);
        context.putNamespacePrefix("http://www.w3.org/2000/09/xmldsig#", "ds");
        context.putNamespacePrefix("http://uri.etsi.org/01903/v1.3.2#", "xades");
        Iterator<Map.Entry<String, Element>> it = context.iterator();
        while (it.hasNext()) {
            Map.Entry<String, Element> object = it.next();
            Element e = object.getValue();
            context.setIdAttributeNS(e, null, "Id");
        }
        try {
            this.signature.sign((XMLSignContext)context);
        }
        catch (MarshalException | XMLSignatureException ex) {
            logger.error("", (Throwable)ex);
            throw new OperationFailedException("exception.signatures.cannot_sign", ex);
        }
        return context;
    }

    public XAdESSignature getSignature() {
        return this.signature;
    }

    public void setSignature(XAdESSignature signature) {
        this.signature = signature;
    }

    /*
     * WARNING - Removed try catching itself - possible behaviour change.
     */
    public XMLStructure addFileObject(SignatureFile sf, File fileToSign) throws OperationFailedException {
        FileInputStream fis = null;
        byte[] buffer = new byte[102400];
        try {
            fis = new FileInputStream(fileToSign);
            logger.debug("Total file size to read (in bytes) {}", (Object)fis.available());
            int res = fis.read(buffer);
            buffer = Arrays.copyOfRange(buffer, 0, res);
        }
        catch (IOException ex) {
            logger.error("", (Throwable)ex);
        }
        finally {
            if (fis != null) {
                try {
                    fis.close();
                }
                catch (IOException ex) {
                    logger.error("Not able to close file {}", (Object)fileToSign, (Object)ex);
                }
            }
        }
        ByteArrayWrapper baw = new ByteArrayWrapper(buffer);
        Text text = sf.getDocument().createTextNode(baw.asBase64());
        DOMStructure content = new DOMStructure(text);
        return this.sfac.newXMLObject(Collections.nCopies(1, content), "FileObject-" + this.BASIC_ID, null, "UTF-8");
    }

    public void setSignAlgorithmName(String signAlgorithmName) {
        this.signAlgorithmName = signAlgorithmName;
    }
}

