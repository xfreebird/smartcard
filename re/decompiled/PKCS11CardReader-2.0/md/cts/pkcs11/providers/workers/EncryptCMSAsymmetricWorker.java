/*
 * Decompiled with CFR 0.152.
 * 
 * Could not load the following classes:
 *  iaik.asn1.structures.AlgorithmID
 *  iaik.cms.EnvelopedDataStream
 *  iaik.cms.KeyTransRecipientInfo
 *  iaik.cms.RecipientInfo
 *  iaik.x509.X509ExtensionException
 *  md.cts.moldsign.transferobjects.models.CertificateModel
 *  md.cts.moldsign.transferobjects.models.EncryptDecryptFileResponseModel
 *  org.slf4j.Logger
 *  org.slf4j.LoggerFactory
 */
package md.cts.pkcs11.providers.workers;

import iaik.asn1.structures.AlgorithmID;
import iaik.cms.EnvelopedDataStream;
import iaik.cms.KeyTransRecipientInfo;
import iaik.cms.RecipientInfo;
import iaik.x509.X509ExtensionException;
import java.io.FileInputStream;
import java.io.FileNotFoundException;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;
import java.security.NoSuchAlgorithmException;
import md.cts.cryptography.providers.GlobalCertificateProvider;
import md.cts.moldsign.transferobjects.models.CertificateModel;
import md.cts.moldsign.transferobjects.models.EncryptDecryptFileResponseModel;
import md.cts.pkcs11.cards.exceptions.InvalidPinException;
import md.cts.pkcs11.cards.exceptions.OperationFailedException;
import md.cts.pkcs11.providers.workers.AbstractWork;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

public final class EncryptCMSAsymmetricWorker
extends AbstractWork<EncryptDecryptFileResponseModel> {
    private static final Logger logger = LoggerFactory.getLogger(EncryptCMSAsymmetricWorker.class);
    private final String fileToEncrypt;
    private final String destinationFile;
    private final CertificateModel certificate;

    public EncryptCMSAsymmetricWorker(String fileToEncrypt, String destinationFile, CertificateModel certificate) {
        this.fileToEncrypt = fileToEncrypt;
        this.destinationFile = destinationFile;
        this.certificate = certificate;
    }

    @Override
    public EncryptDecryptFileResponseModel call() throws OperationFailedException, InvalidPinException {
        KeyTransRecipientInfo keyTransRecipientInfo;
        EnvelopedDataStream envelopedData;
        FileInputStream dataInputStream;
        GlobalCertificateProvider.get().validateCertificate(this.certificate, 2);
        try {
            dataInputStream = new FileInputStream(this.fileToEncrypt);
            logger.info("Reading the file that needs to be encrypted with certificate");
        }
        catch (FileNotFoundException ex) {
            logger.warn("call", (Throwable)ex);
            throw new OperationFailedException("exception.general.file_not_found", ex);
        }
        try {
            envelopedData = new EnvelopedDataStream((InputStream)dataInputStream, (AlgorithmID)AlgorithmID.aes128_CBC.clone());
        }
        catch (NoSuchAlgorithmException ex) {
            logger.error("call", (Throwable)ex);
            throw new OperationFailedException("exception.general.no_such_algorithm", ex);
        }
        try {
            keyTransRecipientInfo = new KeyTransRecipientInfo(this.certificate.getCertificate(), 0, AlgorithmID.rsaEncryption);
        }
        catch (X509ExtensionException ex) {
            logger.warn("call", (Throwable)ex);
            throw new OperationFailedException("exception.general.certificate_exception", ex);
        }
        envelopedData.setRecipientInfos(new RecipientInfo[]{keyTransRecipientInfo});
        FileOutputStream envelopedDataOutputStream = null;
        try {
            envelopedDataOutputStream = new FileOutputStream(this.destinationFile);
            envelopedData.writeTo((OutputStream)envelopedDataOutputStream);
            logger.info("Encryption of the file started...");
        }
        catch (IOException ex) {
            logger.warn("call", (Throwable)ex);
            throw new OperationFailedException("exception.general.io_exception_write", ex);
        }
        finally {
            if (envelopedDataOutputStream != null) {
                try {
                    envelopedDataOutputStream.close();
                }
                catch (IOException ex) {
                    logger.error("call", (Throwable)ex);
                }
            }
        }
        logger.info("Encryption of the file with a certificate finished.");
        return new EncryptDecryptFileResponseModel(this.destinationFile);
    }
}

