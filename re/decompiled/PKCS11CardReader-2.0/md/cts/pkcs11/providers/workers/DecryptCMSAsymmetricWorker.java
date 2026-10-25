/*
 * Decompiled with CFR 0.152.
 * 
 * Could not load the following classes:
 *  iaik.cms.CMSException
 *  iaik.cms.CMSParsingException
 *  iaik.cms.EnvelopedDataStream
 *  iaik.cms.RecipientInfo
 *  iaik.cms.SecurityProvider
 *  iaik.pkcs.pkcs11.provider.IAIKPkcs11
 *  iaik.pkcs.pkcs11.provider.LoginManager
 *  iaik.utils.Util
 *  md.cts.moldsign.transferobjects.models.CertificateModel
 *  md.cts.moldsign.transferobjects.models.EncryptDecryptFileResponseModel
 *  org.slf4j.Logger
 *  org.slf4j.LoggerFactory
 */
package md.cts.pkcs11.providers.workers;

import iaik.cms.CMSException;
import iaik.cms.CMSParsingException;
import iaik.cms.EnvelopedDataStream;
import iaik.cms.RecipientInfo;
import iaik.cms.SecurityProvider;
import iaik.pkcs.pkcs11.provider.IAIKPkcs11;
import iaik.pkcs.pkcs11.provider.LoginManager;
import iaik.utils.Util;
import java.io.FileInputStream;
import java.io.FileNotFoundException;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;
import java.security.InvalidKeyException;
import java.security.Key;
import java.security.NoSuchAlgorithmException;
import java.security.PrivateKey;
import java.security.Provider;
import md.cts.cryptography.providers.GlobalCertificateProvider;
import md.cts.cryptography.providers.SecurityOperationProvider;
import md.cts.moldsign.transferobjects.models.CertificateModel;
import md.cts.moldsign.transferobjects.models.EncryptDecryptFileResponseModel;
import md.cts.pkcs11.cards.exceptions.InvalidPinException;
import md.cts.pkcs11.cards.exceptions.OperationFailedException;
import md.cts.pkcs11.providers.pin_providers.PKCS11PinProvider;
import md.cts.pkcs11.providers.workers.AbstractWork;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

public final class DecryptCMSAsymmetricWorker
extends AbstractWork<EncryptDecryptFileResponseModel> {
    private static final Logger logger = LoggerFactory.getLogger(DecryptCMSAsymmetricWorker.class);
    private final String fileToDecrypt;
    private final String destinationFile;
    private final CertificateModel certificate;
    private final char[] pin;
    private final SecurityOperationProvider secProvider;

    public DecryptCMSAsymmetricWorker(SecurityOperationProvider secProvider, String fileToEncrypt, String destinationFile, CertificateModel certificate, char[] pin) {
        this.secProvider = secProvider;
        this.fileToDecrypt = fileToEncrypt;
        this.destinationFile = destinationFile;
        this.certificate = certificate;
        this.pin = pin;
    }

    @Override
    public EncryptDecryptFileResponseModel call() throws OperationFailedException, InvalidPinException {
        EnvelopedDataStream envelopedData;
        FileInputStream dataInputStream;
        Provider p = this.secProvider.getProvider();
        SecurityProvider cmsSecurityProvider = this.secProvider.getSecurityProvider();
        SecurityProvider.setSecurityProvider((SecurityProvider)cmsSecurityProvider);
        GlobalCertificateProvider.get().validateCertificate(this.certificate, 2);
        if (p instanceof IAIKPkcs11) {
            IAIKPkcs11 prov = (IAIKPkcs11)p;
            PKCS11PinProvider loginManager = new PKCS11PinProvider(this.pin, this.getSessionId(), null);
            prov.setLoginManager((LoginManager)loginManager);
        }
        PrivateKey key = this.secProvider.getPrivateKey(this.certificate.getLabel());
        try {
            dataInputStream = new FileInputStream(this.fileToDecrypt);
            logger.info("Reading the file that should be decrypted...");
        }
        catch (FileNotFoundException ex) {
            logger.error("call", (Throwable)ex);
            throw new OperationFailedException("exception.general.file_not_found", ex);
        }
        try {
            envelopedData = new EnvelopedDataStream((InputStream)dataInputStream);
        }
        catch (IOException ex) {
            logger.error("call", (Throwable)ex);
            throw new OperationFailedException("exception.general.io_exception", ex);
        }
        catch (CMSParsingException ex) {
            logger.error("call", (Throwable)ex);
            throw new OperationFailedException("exception.decryption.invalid_file_format", ex);
        }
        RecipientInfo[] infos = envelopedData.getRecipientInfos();
        int recipientIndex = -1;
        for (int i = 0; i < infos.length; ++i) {
            RecipientInfo recipientInfo = infos[i];
            if (recipientInfo.isRecipientInfoFor(this.certificate.getCertificate()) == null) continue;
            recipientIndex = i;
            break;
        }
        if (recipientIndex == -1) {
            throw new OperationFailedException("exception.decryption.wrong_certificate", new Exception("The selected certificate was not used for encrypting of this file"));
        }
        FileOutputStream decryptedFileStream = null;
        try {
            logger.info("Starting to decrypt the file ...");
            envelopedData.setupCipher((Key)key, recipientIndex);
            InputStream decrypted = envelopedData.getInputStream();
            decryptedFileStream = new FileOutputStream(this.destinationFile);
            Util.copyStream((InputStream)decrypted, (OutputStream)decryptedFileStream, null);
        }
        catch (IOException ex) {
            logger.error("call", (Throwable)ex);
            throw new OperationFailedException("exception.general.io_exception", ex);
        }
        catch (InvalidKeyException ex) {
            logger.error("call", (Throwable)ex);
            throw new OperationFailedException("exception.decryption.invalid_key", ex);
        }
        catch (NoSuchAlgorithmException ex) {
            logger.error("call", (Throwable)ex);
            throw new OperationFailedException("exception.general.no_such_algorithm", ex);
        }
        catch (CMSException ex) {
            logger.error("call", (Throwable)ex);
            throw new OperationFailedException("exception.decryption.invalid_file_format", ex);
        }
        finally {
            if (decryptedFileStream != null) {
                try {
                    decryptedFileStream.close();
                    logger.info("File successfully decrypted.");
                }
                catch (IOException ex) {
                    logger.error("call", (Throwable)ex);
                }
            }
        }
        if (p instanceof IAIKPkcs11) {
            IAIKPkcs11 prov = (IAIKPkcs11)p;
            prov.getTokenManager().clearSessionPool(true);
        }
        return new EncryptDecryptFileResponseModel(this.destinationFile);
    }
}

