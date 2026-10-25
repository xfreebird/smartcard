/*
 * Decompiled with CFR 0.152.
 * 
 * Could not load the following classes:
 *  iaik.asn1.DerInputException
 *  iaik.cms.CMSParsingException
 *  iaik.cms.EncryptedDataStream
 *  iaik.utils.Util
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

import iaik.asn1.DerInputException;
import iaik.cms.CMSParsingException;
import iaik.cms.EncryptedDataStream;
import iaik.utils.Util;
import java.io.BufferedInputStream;
import java.io.BufferedOutputStream;
import java.io.File;
import java.io.FileInputStream;
import java.io.FileNotFoundException;
import java.io.FileOutputStream;
import java.io.FilterOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;
import java.security.InvalidAlgorithmParameterException;
import java.security.InvalidKeyException;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.security.NoSuchProviderException;
import java.security.Provider;
import java.security.Security;
import java.security.spec.InvalidKeySpecException;
import java.security.spec.InvalidParameterSpecException;
import java.util.Arrays;
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

public final class DecryptCMSSymmetricWorker
extends AbstractWork<EncryptDecryptFileResponseModel> {
    private static final Logger logger = LoggerFactory.getLogger(DecryptCMSSymmetricWorker.class);
    private final String fileToDecrypt;
    private final char[] password;
    private String decryptedFile;

    public DecryptCMSSymmetricWorker(String fileName, String destinationFile, char[] password) {
        this.fileToDecrypt = fileName;
        this.password = password;
        this.decryptedFile = destinationFile;
    }

    private static PaddedBufferedBlockCipher getPaddedBufferedBlockCipher(SecretKeySpec secretKey, byte[] ivBytes) {
        byte[] key = secretKey.getEncoded();
        KeyParameter keyParam = new KeyParameter(key);
        ParametersWithIV parametersWithIV = new ParametersWithIV((CipherParameters)keyParam, ivBytes);
        PKCS7Padding pKCS7Padding = new PKCS7Padding();
        PaddedBufferedBlockCipher paddedBufferedBlockCipher = new PaddedBufferedBlockCipher((BlockCipher)new CBCBlockCipher((BlockCipher)new AESEngine()), (BlockCipherPadding)pKCS7Padding);
        paddedBufferedBlockCipher.reset();
        paddedBufferedBlockCipher.init(false, (CipherParameters)parametersWithIV);
        return paddedBufferedBlockCipher;
    }

    @Override
    public EncryptDecryptFileResponseModel call() throws OperationFailedException, InvalidPinException {
        FileInputStream dataInputStream;
        if (this.decryptedFile == null) {
            this.decryptedFile = this.fileToDecrypt;
        }
        if (this.decryptedFile.endsWith(".symmetric.p7m")) {
            this.decryptedFile = this.decryptedFile.substring(0, this.decryptedFile.lastIndexOf(".symmetric.p7m"));
        }
        try {
            dataInputStream = new FileInputStream(this.fileToDecrypt);
            logger.info("Reading the file encrypted with password...");
        }
        catch (FileNotFoundException ex) {
            logger.warn("", (Throwable)ex);
            throw new OperationFailedException("exception.general.file_not_found", ex);
        }
        EncryptedDataStream encryptedData = null;
        try {
            logger.info("Starting to decrypt the file...");
            encryptedData = new EncryptedDataStream((InputStream)dataInputStream);
            encryptedData.setupCipher(this.password);
        }
        catch (InvalidParameterSpecException ex) {
            logger.error("", (Throwable)ex);
            throw new OperationFailedException("exception.decryption.invalid_parameters", ex);
        }
        catch (InvalidAlgorithmParameterException | NoSuchAlgorithmException ex) {
            logger.error("", (Throwable)ex);
            throw new OperationFailedException("exception.general.no_such_algorithm", ex);
        }
        catch (CMSParsingException ex) {
            logger.error("", (Throwable)ex);
            throw new OperationFailedException("exception.decryption.invalid_file_format", ex);
        }
        catch (DerInputException die) {
            try {
                if (encryptedData != null) {
                    encryptedData.getInputStream().close();
                }
            }
            catch (IOException ioe) {
                logger.error("", (Throwable)ioe);
            }
            try {
                dataInputStream.close();
            }
            catch (IOException ex) {
                logger.error("", (Throwable)ex);
            }
            this.customBCDecipher();
            logger.info("File successfully decrypted.");
            return new EncryptDecryptFileResponseModel(this.decryptedFile);
        }
        catch (IOException ex) {
            logger.error("", (Throwable)ex);
            throw new OperationFailedException("exception.general.io_exception", ex);
        }
        catch (InvalidKeyException ex) {
            logger.error("", (Throwable)ex);
            throw new OperationFailedException("exception.decryption.invalid_key", ex);
        }
        InputStream decrypted = encryptedData.getInputStream();
        FileOutputStream decryptedFileStream = null;
        try {
            decryptedFileStream = new FileOutputStream(this.decryptedFile);
            Util.copyStream((InputStream)decrypted, (OutputStream)decryptedFileStream, null);
            logger.info("Destination file successfully created.");
        }
        catch (IOException ex) {
            File f;
            if (decryptedFileStream != null) {
                try {
                    decryptedFileStream.close();
                }
                catch (IOException ex1) {
                    logger.error("", (Throwable)ex);
                }
            }
            if ((f = new File(this.decryptedFile)).exists()) {
                f.delete();
            }
            logger.warn("", (Throwable)ex);
            throw new OperationFailedException("exception.general.io_exception_write", ex);
        }
        catch (Exception ex) {
            throw new InvalidPinException();
        }
        finally {
            if (decryptedFileStream != null) {
                try {
                    decryptedFileStream.close();
                }
                catch (IOException ex) {
                    logger.error("", (Throwable)ex);
                }
            }
            try {
                dataInputStream.close();
            }
            catch (IOException ex) {
                logger.error("", (Throwable)ex);
            }
        }
        return new EncryptDecryptFileResponseModel(this.decryptedFile);
    }

    private void customBCDecipher() throws OperationFailedException {
        BufferedInputStream is = null;
        FilterOutputStream os = null;
        try {
            int noBytesProcessed;
            int noBytesRead;
            String algorithmName;
            int passwordBits;
            is = new BufferedInputStream(new FileInputStream(this.fileToDecrypt));
            os = new BufferedOutputStream(new FileOutputStream(this.decryptedFile));
            byte[] passwordSalt = new byte[16];
            is.read(passwordSalt);
            byte[] ivBytes = new byte[16];
            is.read(ivBytes);
            byte[] encryptedAESType = new byte[64];
            is.read(encryptedAESType);
            MessageDigest md = MessageDigest.getInstance("SHA-512");
            if (Arrays.equals(md.digest("128".getBytes()), encryptedAESType)) {
                passwordBits = 128;
                algorithmName = "PBEWITHSHA256AND128BITAES-CBC-BC";
            } else if (Arrays.equals(md.digest("192".getBytes()), encryptedAESType)) {
                passwordBits = 192;
                algorithmName = "PBEWITHSHA256AND192BITAES-CBC-BC";
            } else {
                passwordBits = 256;
                algorithmName = "PBEWithSHA256And256BitAES-CBC-BC";
            }
            Security.addProvider((Provider)new BouncyCastleProvider());
            SecretKeyFactory keyFactory = SecretKeyFactory.getInstance(algorithmName, "BC");
            PBEKeySpec pbeKeySpec = new PBEKeySpec(this.password, passwordSalt, 65537, passwordBits);
            SecretKeySpec secretKey = new SecretKeySpec(keyFactory.generateSecret(pbeKeySpec).getEncoded(), "AES");
            PaddedBufferedBlockCipher paddedBufferedBlockCipher = DecryptCMSSymmetricWorker.getPaddedBufferedBlockCipher(secretKey, ivBytes);
            byte[] buf = new byte[16];
            byte[] obuf = new byte[512];
            while ((noBytesRead = is.read(buf)) >= 0) {
                noBytesProcessed = paddedBufferedBlockCipher.processBytes(buf, 0, noBytesRead, obuf, 0);
                ((BufferedOutputStream)os).write(obuf, 0, noBytesProcessed);
            }
            noBytesProcessed = paddedBufferedBlockCipher.doFinal(obuf, 0);
            ((BufferedOutputStream)os).write(obuf, 0, noBytesProcessed);
            ((BufferedOutputStream)os).flush();
        }
        catch (FileNotFoundException ex) {
            logger.warn("", (Throwable)ex);
            throw new OperationFailedException("exception.general.file_not_found", ex);
        }
        catch (IOException ex) {
            logger.error("", (Throwable)ex);
            throw new OperationFailedException("exception.general.io_exception", ex);
        }
        catch (NoSuchAlgorithmException ex) {
            logger.error("", (Throwable)ex);
            throw new OperationFailedException("exception.general.no_such_algorithm", ex);
        }
        catch (NoSuchProviderException ex) {
            logger.error("", (Throwable)ex);
            throw new OperationFailedException("exception.general.no_such_provider", ex);
        }
        catch (IllegalStateException | InvalidKeySpecException | DataLengthException | InvalidCipherTextException ex) {
            logger.error("", ex);
            throw new OperationFailedException(ex);
        }
        finally {
            if (os != null) {
                try {
                    os.close();
                }
                catch (IOException ex) {
                    logger.error("", (Throwable)ex);
                }
            }
            if (is != null) {
                try {
                    is.close();
                }
                catch (IOException ex) {
                    logger.error("", (Throwable)ex);
                }
            }
        }
    }
}

