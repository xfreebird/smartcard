/*
 * Decompiled with CFR 0.152.
 * 
 * Could not load the following classes:
 *  iaik.cms.SecurityProvider
 *  iaik.xml.crypto.XSecProvider
 *  org.slf4j.Logger
 *  org.slf4j.LoggerFactory
 */
package md.cts.cryptography.providers;

import iaik.cms.SecurityProvider;
import iaik.xml.crypto.XSecProvider;
import java.io.ByteArrayInputStream;
import java.io.FileInputStream;
import java.io.IOException;
import java.io.InputStream;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.security.PrivateKey;
import java.security.Provider;
import java.security.Security;
import md.cts.pkcs11.cards.exceptions.OperationFailedException;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

public abstract class SecurityOperationProvider {
    public static final String SIGNATURE_SHA1 = "Signature.SHA1withRSA";
    public static final String SIGNATURE_SHA256 = "Signature.SHA256withRSA";
    private static final Logger logger = LoggerFactory.getLogger(SecurityOperationProvider.class);

    public abstract Provider getProvider();

    public abstract PrivateKey getPrivateKey(String var1) throws OperationFailedException;

    public XSecProvider configureXsecProvider(String algorithm) {
        Provider provider = Security.getProvider("XMLDSig");
        logger.info("XsecProvider= {}", (Object)provider);
        while (provider != null) {
            Security.removeProvider(provider.getName());
            provider = Security.getProvider("XMLDSig");
            logger.info("XsecProvider= {}", (Object)provider);
        }
        XSecProvider xsecProvider = new XSecProvider();
        Security.addProvider((Provider)xsecProvider);
        logger.info("new XsecProvider= {}", (Object)xsecProvider);
        String signatureAlgorithm = "SHA-1".equalsIgnoreCase(algorithm) ? SIGNATURE_SHA1 : SIGNATURE_SHA256;
        logger.info("signatureAlgorithm= {}", (Object)signatureAlgorithm);
        Provider certProvider = this.getProvider();
        logger.info("certProvider= {}", (Object)certProvider);
        XSecProvider.setDelegationProvider((String)signatureAlgorithm, (String)certProvider.getName());
        return xsecProvider;
    }

    public byte[] calculateDigest(String file, String algorithm) throws OperationFailedException {
        byte[] result;
        try (FileInputStream fis = new FileInputStream(file);){
            result = this.calculateDigest(fis, algorithm);
        }
        catch (Exception ex) {
            logger.error("", (Throwable)ex);
            throw new OperationFailedException("exception.general.file_not_found", ex);
        }
        return result;
    }

    public byte[] calculateDigest(byte[] bytes, String algorithm) throws OperationFailedException {
        ByteArrayInputStream bis = new ByteArrayInputStream(bytes);
        return this.calculateDigest(bis, algorithm);
    }

    private byte[] calculateDigest(InputStream is, String algorithm) throws OperationFailedException {
        String hashAlgo = "SHA-1".equals(algorithm) ? "SHA-1" : "SHA-256";
        MessageDigest md = null;
        try {
            int nread;
            md = MessageDigest.getInstance(hashAlgo);
            byte[] dataBytes = new byte[1024];
            while ((nread = is.read(dataBytes)) != -1) {
                md.update(dataBytes, 0, nread);
            }
        }
        catch (IOException ex) {
            logger.error("", (Throwable)ex);
        }
        catch (NoSuchAlgorithmException ex) {
            logger.error("", (Throwable)ex);
            throw new OperationFailedException("exception.general.no_such_algorithm", ex);
        }
        if (md == null) {
            return null;
        }
        return md.digest();
    }

    public abstract SecurityProvider getSecurityProvider();
}

