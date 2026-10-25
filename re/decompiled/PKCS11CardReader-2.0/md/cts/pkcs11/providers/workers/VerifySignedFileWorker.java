/*
 * Decompiled with CFR 0.152.
 * 
 * Could not load the following classes:
 *  iaik.xml.crypto.XSecProvider
 *  md.cts.moldsign.transferobjects.models.VerifySignedFileResponseModel
 *  org.slf4j.Logger
 *  org.slf4j.LoggerFactory
 */
package md.cts.pkcs11.providers.workers;

import iaik.xml.crypto.XSecProvider;
import java.io.File;
import java.util.HashMap;
import java.util.List;
import md.cts.cryptography.providers.SecurityOperationProvider;
import md.cts.moldsign.transferobjects.models.VerifySignedFileResponseModel;
import md.cts.pkcs11.cards.exceptions.InvalidPinException;
import md.cts.pkcs11.cards.exceptions.OperationFailedException;
import md.cts.pkcs11.providers.workers.AbstractWork;
import md.cts.pkcs11.providers.workers.signatures.SignatureFile;
import md.cts.pkcs11.providers.workers.signatures.SignatureInstance;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

public final class VerifySignedFileWorker
extends AbstractWork<VerifySignedFileResponseModel> {
    private static final Logger logger = LoggerFactory.getLogger(VerifySignedFileWorker.class);
    private final String signatureFile;
    private final List<String> files;
    private final String signatureId;
    private final SecurityOperationProvider secProvider;

    public VerifySignedFileWorker(SecurityOperationProvider secProvider, String signatureFile, List<String> files, String signatureId) {
        this.secProvider = secProvider;
        this.signatureFile = signatureFile;
        this.files = files;
        this.signatureId = signatureId;
    }

    @Override
    public VerifySignedFileResponseModel call() throws OperationFailedException, InvalidPinException {
        String hashAlgo;
        XSecProvider xSecProvider = this.secProvider.configureXsecProvider(null);
        HashMap<String, byte[]> hashes = new HashMap<String, byte[]>();
        logger.info("Verify file operation");
        SignatureFile sf = new SignatureFile(new File(this.signatureFile));
        SignatureInstance signature = sf.getSignatureByID(xSecProvider, this.signatureId);
        if (signature == null) {
            throw new OperationFailedException("signature not found", null);
        }
        String algorithm = signature.getDigestAlgorithmFromFile();
        if (algorithm.equalsIgnoreCase("SHA-256") || algorithm.equalsIgnoreCase("http://www.w3.org/2001/04/xmlenc#sha256")) {
            hashAlgo = "SHA-256";
            signature.setSignAlgorithmName("SHA-256");
            XSecProvider.setDelegationProvider((String)"Signature.SHA256withRSA", (String)this.secProvider.getProvider().getName());
        } else {
            hashAlgo = "SHA-1";
            signature.setSignAlgorithmName("SHA-1");
            XSecProvider.setDelegationProvider((String)"Signature.SHA1withRSA", (String)this.secProvider.getProvider().getName());
        }
        if (this.files != null) {
            for (String file : this.files) {
                hashes.put(file, this.secProvider.calculateDigest(file, hashAlgo));
            }
        }
        logger.info("Attempting to validate the signed file...");
        boolean valid = signature.validate(hashes);
        logger.info("Verify signed file operation finished successfully");
        return new VerifySignedFileResponseModel(valid);
    }
}

