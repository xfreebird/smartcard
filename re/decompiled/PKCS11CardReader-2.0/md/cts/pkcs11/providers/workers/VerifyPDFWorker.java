/*
 * Decompiled with CFR 0.152.
 * 
 * Could not load the following classes:
 *  com.itextpdf.kernel.pdf.PdfDocument
 *  com.itextpdf.kernel.pdf.PdfReader
 *  com.itextpdf.signatures.PdfPKCS7
 *  com.itextpdf.signatures.SignatureUtil
 *  iaik.pkcs.pkcs11.provider.IAIKPkcs11
 *  md.cts.moldsign.transferobjects.models.VerifyPdfInputModel
 *  md.cts.moldsign.transferobjects.models.VerifyPdfResponseModel
 *  org.bouncycastle.jce.provider.BouncyCastleProvider
 *  org.slf4j.Logger
 *  org.slf4j.LoggerFactory
 */
package md.cts.pkcs11.providers.workers;

import com.itextpdf.kernel.pdf.PdfDocument;
import com.itextpdf.kernel.pdf.PdfReader;
import com.itextpdf.signatures.PdfPKCS7;
import com.itextpdf.signatures.SignatureUtil;
import iaik.pkcs.pkcs11.provider.IAIKPkcs11;
import java.io.IOException;
import java.security.GeneralSecurityException;
import java.security.Provider;
import java.security.Security;
import java.util.List;
import md.cts.cryptography.providers.SecurityOperationProvider;
import md.cts.cryptography.providers.SecurityOperationsProviderManager;
import md.cts.moldsign.transferobjects.models.VerifyPdfInputModel;
import md.cts.moldsign.transferobjects.models.VerifyPdfResponseModel;
import md.cts.pkcs11.cards.exceptions.OperationFailedException;
import md.cts.pkcs11.providers.workers.AbstractWork;
import org.bouncycastle.jce.provider.BouncyCastleProvider;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

public final class VerifyPDFWorker
extends AbstractWork<VerifyPdfResponseModel> {
    private static final Logger logger = LoggerFactory.getLogger(VerifyPDFWorker.class);
    private final VerifyPdfInputModel input;
    private final SecurityOperationProvider secProvider = SecurityOperationsProviderManager.getDefault();

    public VerifyPDFWorker(VerifyPdfInputModel input) {
        this.input = input;
    }

    @Override
    public VerifyPdfResponseModel call() throws OperationFailedException {
        if (this.input.getSignedFile() == null || this.input.getSignedFile().trim().isEmpty()) {
            throw new OperationFailedException("exception.signatures.both_files_match", new Exception("The origin and destination file can not be the same"));
        }
        Provider p = this.secProvider.getProvider();
        try {
            this.verifyPdf(this.input.getSignedFile());
        }
        finally {
            try {
                if (p instanceof IAIKPkcs11) {
                    IAIKPkcs11 prov = (IAIKPkcs11)p;
                    prov.getTokenManager().clearSessionPool(true);
                }
            }
            catch (Exception ex) {
                logger.warn("VerifyPDFWorker", (Throwable)ex);
            }
        }
        return new VerifyPdfResponseModel(true);
    }

    private void verifyPdf(String filename) throws OperationFailedException {
        Security.addProvider((Provider)new BouncyCastleProvider());
        try (PdfReader pdfReader = new PdfReader(filename);
             PdfDocument pdfDoc = new PdfDocument(pdfReader);){
            SignatureUtil signUtil = new SignatureUtil(pdfDoc);
            List signatureNames = signUtil.getSignatureNames();
            if (signatureNames.isEmpty()) {
                throw new OperationFailedException("exception.signatures.verification.not_signed", new Exception("The signature file doesn't contain any signature"));
            }
            for (String signatureName : signatureNames) {
                boolean isValid;
                PdfPKCS7 pk = signUtil.readSignatureData(signatureName);
                try {
                    isValid = pk.verifySignatureIntegrityAndAuthenticity();
                }
                catch (GeneralSecurityException ex) {
                    logger.error("", (Throwable)ex);
                    throw new OperationFailedException("exception.general.unknown_problem", ex);
                }
                if (isValid) continue;
                throw new OperationFailedException("exception.signatures.verification.invalid_signature", new Exception("Signature is invalid, probably the document has been changed"));
            }
        }
        catch (IOException ex) {
            logger.error("", (Throwable)ex);
            throw new OperationFailedException("exception.general.unknown_problem", ex);
        }
    }
}

