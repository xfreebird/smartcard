/*
 * Decompiled with CFR 0.152.
 * 
 * Could not load the following classes:
 *  iaik.xml.crypto.XSecProvider
 *  md.cts.moldsign.transferobjects.models.XAdES.XAdESSignatureModel
 *  md.cts.moldsign.transferobjects.models.XAdES.XadesSignatureModelContainer
 *  org.slf4j.Logger
 *  org.slf4j.LoggerFactory
 */
package md.cts.pkcs11.providers.workers;

import iaik.xml.crypto.XSecProvider;
import java.io.File;
import java.util.ArrayList;
import java.util.List;
import md.cts.cryptography.providers.SecurityOperationProvider;
import md.cts.moldsign.transferobjects.models.XAdES.XAdESSignatureModel;
import md.cts.moldsign.transferobjects.models.XAdES.XadesSignatureModelContainer;
import md.cts.pkcs11.cards.exceptions.InvalidPinException;
import md.cts.pkcs11.cards.exceptions.OperationFailedException;
import md.cts.pkcs11.providers.workers.AbstractWork;
import md.cts.pkcs11.providers.workers.signatures.SignatureFile;
import md.cts.pkcs11.providers.workers.signatures.SignatureInstance;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

public final class XAdESSignatureInfoWorker
extends AbstractWork<XadesSignatureModelContainer> {
    private static final Logger logger = LoggerFactory.getLogger(XAdESSignatureInfoWorker.class);
    private final String signatureFile;
    private final SecurityOperationProvider secProvider;

    public XAdESSignatureInfoWorker(SecurityOperationProvider secProvider, String signatureFile) {
        this.secProvider = secProvider;
        this.signatureFile = signatureFile;
    }

    @Override
    public XadesSignatureModelContainer call() throws OperationFailedException, InvalidPinException {
        logger.info("Get file info operation started.");
        XSecProvider xSecProvider = this.secProvider.configureXsecProvider(null);
        SignatureFile sf = new SignatureFile(new File(this.signatureFile));
        List<SignatureInstance> signatureInstances = sf.getTopLevelSignatures(xSecProvider);
        ArrayList<XAdESSignatureModel> signatureInfos = new ArrayList<XAdESSignatureModel>(signatureInstances.size());
        String fileObjectId = null;
        for (SignatureInstance sigInstance : signatureInstances) {
            signatureInfos.add(sigInstance.getSignatureInformation());
            if (fileObjectId != null) continue;
            fileObjectId = sigInstance.getObjectIDFromSignedFile();
        }
        XadesSignatureModelContainer xsmc = new XadesSignatureModelContainer(signatureInfos);
        if (fileObjectId != null) {
            xsmc.setEncodedData(sf.getDataForId(fileObjectId));
        }
        logger.info("Getting file info operation finished.");
        return xsmc;
    }
}

