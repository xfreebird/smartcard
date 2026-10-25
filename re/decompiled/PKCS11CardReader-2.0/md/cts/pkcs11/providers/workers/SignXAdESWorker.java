/*
 * Decompiled with CFR 0.152.
 * 
 * Could not load the following classes:
 *  iaik.asn1.ObjectID
 *  iaik.pkcs.pkcs11.provider.IAIKPkcs11
 *  iaik.pkcs.pkcs11.provider.LoginManager
 *  iaik.utils.RFC2253NameParser
 *  iaik.x509.X509Certificate
 *  iaik.xml.crypto.XSecProvider
 *  iaik.xml.crypto.xades.DataObjectFormat
 *  iaik.xml.crypto.xades.QualifyingProperties
 *  md.cts.moldsign.transferobjects.models.SignFileInputModel
 *  md.cts.moldsign.transferobjects.models.XAdES.XAdESSignatureModel
 *  md.cts.moldsign.transferobjects.models.XAdES.XadesSignatureModelContainer
 *  org.slf4j.Logger
 *  org.slf4j.LoggerFactory
 */
package md.cts.pkcs11.providers.workers;

import iaik.asn1.ObjectID;
import iaik.pkcs.pkcs11.provider.IAIKPkcs11;
import iaik.pkcs.pkcs11.provider.LoginManager;
import iaik.utils.RFC2253NameParser;
import iaik.x509.X509Certificate;
import iaik.xml.crypto.XSecProvider;
import iaik.xml.crypto.xades.DataObjectFormat;
import iaik.xml.crypto.xades.QualifyingProperties;
import java.io.File;
import java.security.PrivateKey;
import java.security.Provider;
import java.util.ArrayList;
import java.util.Base64;
import java.util.HashMap;
import java.util.HexFormat;
import java.util.Iterator;
import java.util.List;
import javax.xml.crypto.XMLStructure;
import javax.xml.crypto.dsig.SignedInfo;
import javax.xml.crypto.dsig.XMLSignature;
import javax.xml.crypto.dsig.dom.DOMSignContext;
import javax.xml.crypto.dsig.keyinfo.KeyInfo;
import md.cts.cryptography.providers.GlobalCertificateProvider;
import md.cts.cryptography.providers.SecurityOperationProvider;
import md.cts.cryptography.providers.SecurityOperationsProviderManager;
import md.cts.moldsign.transferobjects.models.SignFileInputModel;
import md.cts.moldsign.transferobjects.models.XAdES.XAdESSignatureModel;
import md.cts.moldsign.transferobjects.models.XAdES.XadesSignatureModelContainer;
import md.cts.pkcs11.cards.exceptions.InvalidPinException;
import md.cts.pkcs11.cards.exceptions.OperationFailedException;
import md.cts.pkcs11.providers.pin_providers.PKCS11PinProvider;
import md.cts.pkcs11.providers.workers.AbstractWork;
import md.cts.pkcs11.providers.workers.signatures.SignatureFile;
import md.cts.pkcs11.providers.workers.signatures.SignatureInstance;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

public final class SignXAdESWorker
extends AbstractWork<XadesSignatureModelContainer> {
    private static final Logger logger = LoggerFactory.getLogger(SignXAdESWorker.class);
    private final SignFileInputModel input;
    private final SecurityOperationProvider secProvider;

    public SignXAdESWorker(SignFileInputModel input) {
        this.secProvider = SecurityOperationsProviderManager.getProvider(input.getCertificate().getProviderId());
        this.input = input;
    }

    @Override
    public XadesSignatureModelContainer call() throws OperationFailedException, InvalidPinException {
        logger.info("Signing file operation started...");
        GlobalCertificateProvider.get().validateCertificate(this.input.getCertificate(), 1);
        logger.info("Certificate validated.");
        char[] pin = null;
        if (this.input.getPin() != null) {
            pin = this.input.getPin().toCharArray();
        }
        Provider provider = this.secProvider.getProvider();
        logger.info("providerName: {}", (Object)provider.getName());
        if (provider instanceof IAIKPkcs11) {
            IAIKPkcs11 prov = (IAIKPkcs11)provider;
            PKCS11PinProvider loginManager = new PKCS11PinProvider(pin, this.getSessionId(), this.input.getRequester());
            prov.setLoginManager((LoginManager)loginManager);
        }
        try {
            DOMSignContext signatureContext;
            SignedInfo si;
            File sigFile;
            try {
                sigFile = new File(this.input.getSignatureFile());
            }
            catch (Exception ex) {
                sigFile = null;
            }
            SignatureFile sf = sigFile != null && sigFile.exists() ? new SignatureFile(sigFile) : new SignatureFile();
            logger.info("SignAlgorithm={}", (Object)this.input.getSignAlgorithm());
            XSecProvider xsecProvider = this.secProvider.configureXsecProvider(this.input.getSignAlgorithm());
            if (xsecProvider == null) {
                throw new OperationFailedException("exception.general.provider_initialization_exception", new Exception("Cannot initialize provider"));
            }
            List<SignatureInstance> signatureInstances = sf.getTopLevelSignatures(xsecProvider);
            SignatureInstance signature = sf.createNewSignature(xsecProvider);
            signature.setSignAlgorithmName(this.input.getSignAlgorithm());
            ArrayList<XMLStructure> xmlObjects = new ArrayList<XMLStructure>();
            SignatureInstance originalSignature = null;
            ArrayList<DataObjectFormat> ldof = new ArrayList<DataObjectFormat>();
            if (this.input.getSignatureReference() != null && !this.input.getSignatureReference().trim().isEmpty()) {
                String hashAlgo;
                logger.info("form 1");
                originalSignature = sf.getSignatureByID(xsecProvider, this.input.getSignatureReference());
                if (originalSignature == null) {
                    throw new OperationFailedException("exception.signatures.not_valid", new Exception("Original signature could not be found"));
                }
                String digestAlgorithm = originalSignature.getDigestAlgorithmFromFile();
                if ("SHA-256".equalsIgnoreCase(digestAlgorithm) || "http://www.w3.org/2001/04/xmlenc#sha256".equalsIgnoreCase(digestAlgorithm)) {
                    hashAlgo = "SHA-256";
                    signature.setSignAlgorithmName("SHA-256");
                    XSecProvider.setDelegationProvider((String)"Signature.SHA256withRSA", (String)this.secProvider.getProvider().getName());
                } else {
                    hashAlgo = "SHA-1";
                    signature.setSignAlgorithmName("SHA-1");
                    XSecProvider.setDelegationProvider((String)"Signature.SHA1withRSA", (String)this.secProvider.getProvider().getName());
                }
                si = signature.prepareSignInfo(originalSignature.getSignature(), this.secProvider.calculateDigest(originalSignature.getSignature().getSignatureValue().getValue(), hashAlgo));
            } else if (!signatureInstances.isEmpty() && this.input.getFilesToSign().size() == 1 && this.input.getFilesToSign().contains(this.input.getSignatureFile())) {
                logger.info("form 2");
                String encodedData = null;
                Iterator fileObjectId = null;
                Iterator<SignatureInstance> iterator = signatureInstances.iterator();
                if (iterator.hasNext()) {
                    Iterator<Object> sigInstance = iterator.next();
                    fileObjectId = ((SignatureInstance)((Object)sigInstance)).getObjectIDFromSignedFile();
                }
                if (fileObjectId != null) {
                    encodedData = sf.getDataForId((String)((Object)fileObjectId));
                }
                if (encodedData == null) {
                    throw new OperationFailedException("exception.certificate.zerosizefile", new Exception("File with null data"));
                }
                HashMap<File, byte[]> filesAndHashes = new HashMap<File, byte[]>(this.input.getFilesToSign().size());
                for (String fileName : this.input.getFilesToSign()) {
                    if (fileName == null) {
                        throw new OperationFailedException("exception.certificate.nonamefile", new Exception("File with null name"));
                    }
                    File f = new File(fileName);
                    filesAndHashes.put(f, Base64.getDecoder().decode(encodedData));
                }
                si = signature.prepareSignInfoEnveloping(filesAndHashes);
                for (File file : filesAndHashes.keySet()) {
                    XMLStructure obj = signature.addFileObject(sf, file);
                    xmlObjects.add(obj);
                }
                for (String fileName : this.input.getFilesToSign()) {
                    DataObjectFormat dof = signature.prepareDataObjectProperties(fileName);
                    ldof.add(dof);
                }
            } else {
                logger.info("form 3");
                HashMap<File, byte[]> filesAndHashes = new HashMap<File, byte[]>(this.input.getFilesToSign().size());
                for (String fileName : this.input.getFilesToSign()) {
                    if (fileName == null) {
                        throw new OperationFailedException("exception.certificate.nonamefile", new Exception("File with null name"));
                    }
                    byte[] hash = this.secProvider.calculateDigest(fileName, this.input.getSignAlgorithm());
                    File f = new File(fileName);
                    filesAndHashes.put(f, hash);
                    logger.info("hash={}", (Object)HexFormat.of().formatHex(hash));
                }
                if (this.input.getType() == null || "Detached".equalsIgnoreCase(this.input.getType().toLowerCase())) {
                    si = signature.prepareSignInfo(filesAndHashes);
                } else {
                    si = signature.prepareSignInfoEnveloping(filesAndHashes);
                    for (File file : filesAndHashes.keySet()) {
                        XMLStructure obj = signature.addFileObject(sf, file);
                        xmlObjects.add(obj);
                    }
                }
                for (String fileName : this.input.getFilesToSign()) {
                    DataObjectFormat dof = signature.prepareDataObjectProperties(fileName);
                    ldof.add(dof);
                }
            }
            logger.info("register RFC");
            RFC2253NameParser.register((String)"organizationIdentifier", (ObjectID)ObjectID.organizationIdentifier);
            logger.info("prepareKeyInfo");
            X509Certificate x509Certificate = this.input.getCertificate().getCertificate();
            KeyInfo ki = signature.prepareKeyInfo((java.security.cert.X509Certificate)x509Certificate);
            logger.info("prepareQualifyingProperties");
            QualifyingProperties qp = signature.prepareQualifyingProperties((java.security.cert.X509Certificate)x509Certificate, ldof);
            logger.info("prepareSignature");
            signature.prepareSignature(qp, xmlObjects, si, ki);
            logger.info("Signing the data");
            PrivateKey key = this.secProvider.getPrivateKey(this.input.getCertificate().getLabel());
            logger.info("key algorithm={} format={}", (Object)key.getAlgorithm(), (Object)key.getFormat());
            if (this.input.getSignatureReference() != null && !this.input.getSignatureReference().trim().isEmpty()) {
                if (originalSignature == null) {
                    throw new Exception("originalSignature is null");
                }
                signatureContext = originalSignature.addCounterSignature(key, (XMLSignature)signature.getSignature(), sf.getSignatureContainingNode(this.input.getSignatureReference()));
            } else {
                signatureContext = signature.sign(key, sf.getContainerNode());
            }
            logger.info("Data successfully signed");
            if ("XAdES-T".equals(this.input.getSignFormat()) || "XAdES-C".equals(this.input.getSignFormat())) {
                logger.info("Attempting to contact time-stamp server");
                signature.addTimeStamp(signatureContext, (java.security.cert.X509Certificate)x509Certificate);
                logger.info("Time-stamp added to signature.");
            }
            if ("XAdES-C".equals(this.input.getSignFormat())) {
                signature.addCompleteReferences(signatureContext, this.input.getCertificate());
                logger.info("Added complete references to signature.(XAdES-C)");
            }
            logger.info("Saving the file to the destination file");
            File output = this.input.getDestinationFile() == null ? new File(this.input.getSignatureFile()) : new File(this.input.getDestinationFile());
            sf.writeToFile(output);
            logger.info("Destination file successfully saved");
            List<SignatureInstance> sigInstances = sf.getTopLevelSignatures(xsecProvider);
            ArrayList<XAdESSignatureModel> sigModels = new ArrayList<XAdESSignatureModel>(sigInstances.size());
            for (SignatureInstance sigInstance : sigInstances) {
                sigModels.add(sigInstance.getSignatureInformation());
            }
            XadesSignatureModelContainer mc = new XadesSignatureModelContainer(sigModels);
            mc.setFileLocation(this.input.getDestinationFile());
            XadesSignatureModelContainer xadesSignatureModelContainer = mc;
            return xadesSignatureModelContainer;
        }
        catch (OperationFailedException ofex) {
            throw ofex;
        }
        catch (Exception ex) {
            throw new OperationFailedException("exception.general.unknown_problem", ex);
        }
        finally {
            try {
                if (provider instanceof IAIKPkcs11) {
                    IAIKPkcs11 prov = (IAIKPkcs11)provider;
                    logger.info("drop session");
                    prov.getTokenManager().closeSessions();
                }
            }
            catch (Exception ex) {
                logger.warn("", (Throwable)ex);
            }
            logger.info("Signing operation finished.");
        }
    }
}

