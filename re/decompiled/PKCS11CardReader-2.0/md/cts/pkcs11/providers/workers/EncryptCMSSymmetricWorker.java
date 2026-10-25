/*
 * Decompiled with CFR 0.152.
 * 
 * Could not load the following classes:
 *  iaik.asn1.structures.AlgorithmID
 *  iaik.cms.EncryptedDataStream
 *  md.cts.moldsign.transferobjects.models.EncryptDecryptFileResponseModel
 *  org.bouncycastle.crypto.BlockCipher
 *  org.bouncycastle.crypto.CipherParameters
 *  org.bouncycastle.crypto.DataLengthException
 *  org.bouncycastle.crypto.InvalidCipherTextException
 *  org.bouncycastle.crypto.engines.AESEngine
 *  org.bouncycastle.crypto.modes.CBCBlockCipher
 *  org.bouncycastle.crypto.paddings.BlockCipherPadding
 *  org.bouncycastle.crypto.paddings.PKCS7Padding
 *  org.bouncycastle.crypto.paddings.PaddedBufferedBlockCipher
 *  org.bouncycastle.crypto.params.KeyParameter
 *  org.bouncycastle.crypto.params.ParametersWithIV
 *  org.bouncycastle.jce.provider.BouncyCastleProvider
 *  org.slf4j.Logger
 *  org.slf4j.LoggerFactory
 */
package md.cts.pkcs11.providers.workers;

import iaik.asn1.structures.AlgorithmID;
import iaik.cms.EncryptedDataStream;
import java.io.BufferedInputStream;
import java.io.BufferedOutputStream;
import java.io.FileInputStream;
import java.io.FileNotFoundException;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;
import java.security.InvalidKeyException;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.security.NoSuchProviderException;
import java.security.Provider;
import java.security.SecureRandom;
import java.security.Security;
import java.security.spec.InvalidKeySpecException;
import javax.crypto.SecretKeyFactory;
import javax.crypto.spec.PBEKeySpec;
import javax.crypto.spec.SecretKeySpec;
import md.cts.moldsign.transferobjects.models.EncryptDecryptFileResponseModel;
import md.cts.pkcs11.cards.exceptions.InvalidPinException;
import md.cts.pkcs11.cards.exceptions.OperationFailedException;
import md.cts.pkcs11.providers.workers.AbstractWork;
import org.bouncycastle.crypto.BlockCipher;
import org.bouncycastle.crypto.CipherParameters;
import org.bouncycastle.crypto.DataLengthException;
import org.bouncycastle.crypto.InvalidCipherTextException;
import org.bouncycastle.crypto.engines.AESEngine;
import org.bouncycastle.crypto.modes.CBCBlockCipher;
import org.bouncycastle.crypto.paddings.BlockCipherPadding;
import org.bouncycastle.crypto.paddings.PKCS7Padding;
import org.bouncycastle.crypto.paddings.PaddedBufferedBlockCipher;
import org.bouncycastle.crypto.params.KeyParameter;
import org.bouncycastle.crypto.params.ParametersWithIV;
import org.bouncycastle.jce.provider.BouncyCastleProvider;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

public final class EncryptCMSSymmetricWorker
extends AbstractWork<EncryptDecryptFileResponseModel> {
    private static final Logger logger = LoggerFactory.getLogger(EncryptCMSSymmetricWorker.class);
    private final String fileToEncrypt;
    private final String encryptedFile;
    private final String algorithm;
    private final char[] password;

    public EncryptCMSSymmetricWorker(String fileName, String destinationFile, String algorithm, char[] password) {
        this.fileToEncrypt = fileName;
        this.password = password;
        this.encryptedFile = destinationFile;
        this.algorithm = algorithm;
    }

    @Override
    public EncryptDecryptFileResponseModel call() throws OperationFailedException, InvalidPinException {
        this.encryptWithSelectedAlgorithm();
        return new EncryptDecryptFileResponseModel(this.encryptedFile);
    }

    private void encryptWithSelectedAlgorithm() throws OperationFailedException {
        if ("3_KeyTripleDES_CBC".equalsIgnoreCase(this.algorithm)) {
            this.defaultPBEEncryption((AlgorithmID)AlgorithmID.pbeWithSHAAnd3_KeyTripleDES_CBC.clone());
        } else if ("DES_CBC".equals(this.algorithm)) {
            this.defaultPBEEncryption((AlgorithmID)AlgorithmID.pbeWithMD5AndDES_CBC.clone());
        } else if ("RC2_CBC".equals(this.algorithm)) {
            this.defaultPBEEncryption((AlgorithmID)AlgorithmID.pbeWithSHAAnd40BitRC2_CBC.clone());
        } else if ("128bit_AES".equals(this.algorithm)) {
            this.customBCEncryption(128);
        } else if ("192bit_AES".equals(this.algorithm)) {
            this.customBCEncryption(192);
        } else if ("256bit_AES".equals(this.algorithm)) {
            this.customBCEncryption(256);
        } else {
            this.defaultPBEEncryption((AlgorithmID)AlgorithmID.pbeWithSHAAnd3_KeyTripleDES_CBC.clone());
        }
    }

    private void customBCEncryption(Integer passwordBits) throws OperationFailedException {
        BufferedOutputStream os;
        BufferedInputStream is;
        try {
            is = new BufferedInputStream(new FileInputStream(this.fileToEncrypt));
            os = new BufferedOutputStream(new FileOutputStream(this.encryptedFile));
            logger.info("Reading the file that needs to be encrypted with password..");
        }
        catch (FileNotFoundException ex) {
            logger.warn("customBCEncryption", (Throwable)ex);
            throw new OperationFailedException("exception.general.file_not_found", ex);
        }
        try {
            int noBytesProcessed;
            int noBytesRead;
            SecureRandom r = new SecureRandom();
            byte[] passwordSalt = new byte[16];
            r.nextBytes(passwordSalt);
            os.write(passwordSalt);
            byte[] ivBytes = new byte[16];
            r.nextBytes(ivBytes);
            os.write(ivBytes);
            MessageDigest messageDigest = MessageDigest.getInstance("SHA-512");
            messageDigest.update(passwordBits.toString().getBytes());
            byte[] encryptedAESType = messageDigest.digest();
            os.write(encryptedAESType);
            logger.debug("encryptedAESType.length: {}", (Object)encryptedAESType.length);
            PBEKeySpec pbeKeySpec = new PBEKeySpec(this.password, passwordSalt, 65537, passwordBits);
            Security.addProvider((Provider)new BouncyCastleProvider());
            String algorithmName = passwordBits == 128 ? "PBEWITHSHA256AND128BITAES-CBC-BC" : (passwordBits == 192 ? "PBEWITHSHA256AND192BITAES-CBC-BC" : "PBEWithSHA256And256BitAES-CBC-BC");
            SecretKeyFactory keyFactory = SecretKeyFactory.getInstance(algorithmName, "BC");
            SecretKeySpec secretKey = new SecretKeySpec(keyFactory.generateSecret(pbeKeySpec).getEncoded(), "AES");
            byte[] key = secretKey.getEncoded();
            KeyParameter keyParam = new KeyParameter(key);
            ParametersWithIV parametersWithIV = new ParametersWithIV((CipherParameters)keyParam, ivBytes);
            PKCS7Padding pKCS7Padding = new PKCS7Padding();
            PaddedBufferedBlockCipher paddedBufferedBlockCipher = new PaddedBufferedBlockCipher((BlockCipher)new CBCBlockCipher((BlockCipher)new AESEngine()), (BlockCipherPadding)pKCS7Padding);
            paddedBufferedBlockCipher.reset();
            paddedBufferedBlockCipher.init(true, (CipherParameters)parametersWithIV);
            byte[] buf = new byte[16];
            byte[] obuf = new byte[512];
            logger.info("Encrypting the data...");
            while ((noBytesRead = is.read(buf)) >= 0) {
                noBytesProcessed = paddedBufferedBlockCipher.processBytes(buf, 0, noBytesRead, obuf, 0);
                os.write(obuf, 0, noBytesProcessed);
            }
            noBytesProcessed = paddedBufferedBlockCipher.doFinal(obuf, 0);
            logger.info("Saving the encrypted data in the destination file");
            os.write(obuf, 0, noBytesProcessed);
            os.flush();
        }
        catch (IOException ex) {
            logger.error("customBCEncryption", (Throwable)ex);
            throw new OperationFailedException("exception.general.io_exception", ex);
        }
        catch (NoSuchAlgorithmException ex) {
            logger.error("customBCEncryption", (Throwable)ex);
            throw new OperationFailedException("exception.general.no_such_algorithm", ex);
        }
        catch (NoSuchProviderException ex) {
            logger.error("customBCEncryption", (Throwable)ex);
            throw new OperationFailedException("exception.general.no_such_provider", ex);
        }
        catch (IllegalStateException | InvalidKeySpecException | DataLengthException | InvalidCipherTextException ex) {
            logger.error("customBCEncryption", ex);
            throw new OperationFailedException(ex);
        }
        finally {
            try {
                is.close();
            }
            catch (IOException ex) {
                logger.error("customBCEncryption", (Throwable)ex);
            }
            try {
                os.close();
            }
            catch (IOException ex) {
                logger.error("customBCEncryption", (Throwable)ex);
            }
        }
        logger.info("BCE Encryption operation finished successfully");
    }

    private void defaultPBEEncryption(AlgorithmID algorithm) throws OperationFailedException {
        FileInputStream dataInputStream;
        try {
            dataInputStream = new FileInputStream(this.fileToEncrypt);
            logger.info("Reading the file that needs to be encrypted..");
        }
        catch (FileNotFoundException ex) {
            logger.warn("defaultPBEEncryption", (Throwable)ex);
            throw new OperationFailedException("exception.general.file_not_found", ex);
        }
        EncryptedDataStream encryptedData = new EncryptedDataStream((InputStream)dataInputStream, 128);
        try {
            encryptedData.setupCipher(algorithm, this.password);
            logger.info("Encrypting the data...");
        }
        catch (InvalidKeyException ex) {
            logger.error("defaultPBEEncryption", (Throwable)ex);
            throw new OperationFailedException(ex);
        }
        catch (NoSuchAlgorithmException ex) {
            logger.error("defaultPBEEncryption", (Throwable)ex);
            throw new OperationFailedException("exception.general.no_such_algorithm", ex);
        }
        FileOutputStream encryptedFileStream = null;
        try {
            encryptedFileStream = new FileOutputStream(this.encryptedFile);
            logger.info("Saving the encrypted data in the destination file");
            encryptedData.writeTo((OutputStream)encryptedFileStream);
        }
        catch (IOException ex) {
            logger.warn("defaultPBEEncryption", (Throwable)ex);
            throw new OperationFailedException("exception.general.io_exception_write", ex);
        }
        finally {
            if (encryptedFileStream != null) {
                try {
                    encryptedFileStream.close();
                }
                catch (IOException ex) {
                    logger.error("defaultPBEEncryption", (Throwable)ex);
                }
            }
        }
        logger.info("PBE Encryption operation finished successfully");
    }
}

