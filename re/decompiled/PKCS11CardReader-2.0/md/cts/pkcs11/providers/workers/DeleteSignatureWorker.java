/*
 * Decompiled with CFR 0.152.
 * 
 * Could not load the following classes:
 *  iaik.xml.crypto.XSecProvider
 *  md.cts.moldsign.transferobjects.models.DeleteSignatureInputModel
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
import md.cts.moldsign.transferobjects.models.DeleteSignatureInputModel;
import md.cts.moldsign.transferobjects.models.XAdES.XAdESSignatureModel;
import md.cts.moldsign.transferobjects.models.XAdES.XadesSignatureModelContainer;
import md.cts.pkcs11.cards.exceptions.InvalidPinException;
import md.cts.pkcs11.cards.exceptions.OperationFailedException;
import md.cts.pkcs11.providers.workers.AbstractWork;
import md.cts.pkcs11.providers.workers.signatures.SignatureFile;
import md.cts.pkcs11.providers.workers.signatures.SignatureInstance;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

public final class DeleteSignatureWorker
extends AbstractWork<XadesSignatureModelContainer> {
    private static final Logger logger = LoggerFactory.getLogger(DeleteSignatureWorker.class);
    private final DeleteSignatureInputModel input;
    private final SecurityOperationProvider secProvider;

    public DeleteSignatureWorker(SecurityOperationProvider secProvider, DeleteSignatureInputModel input) {
        this.secProvider = secProvider;
        this.input = input;
    }

    @Override
    public XadesSignatureModelContainer call() throws OperationFailedException, InvalidPinException {
        XSecProvider xSecProvider = this.secProvider.configureXsecProvider(null);
        logger.info("Procedure for deleting the selected signature started");
        SignatureFile sf = new SignatureFile(new File(this.input.getSignatureFile()));
        sf.deleteSignature(this.input.getSignatureReference());
        logger.info("Signature deleted.");
        sf.writeToFile(new File(this.input.getDestinationFile()));
        List<SignatureInstance> sigInstances = sf.getTopLevelSignatures(xSecProvider);
        ArrayList<XAdESSignatureModel> sigModels = new ArrayList<XAdESSignatureModel>(sigInstances.size());
        for (SignatureInstance sigInstance : sigInstances) {
            sigModels.add(sigInstance.getSignatureInformation());
        }
        logger.info("Changes saved.");
        return new XadesSignatureModelContainer(sigModels);
    }
}

