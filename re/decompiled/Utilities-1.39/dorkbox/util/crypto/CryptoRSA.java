/*
 * Decompiled with CFR 0.152.
 * 
 * Could not load the following classes:
 *  org.bouncycastle.crypto.AsymmetricBlockCipher
 *  org.bouncycastle.crypto.AsymmetricCipherKeyPair
 *  org.bouncycastle.crypto.CipherParameters
 *  org.bouncycastle.crypto.Digest
 *  org.bouncycastle.crypto.KeyGenerationParameters
 *  org.bouncycastle.crypto.generators.RSAKeyPairGenerator
 *  org.bouncycastle.crypto.params.RSAKeyGenerationParameters
 *  org.bouncycastle.crypto.params.RSAKeyParameters
 *  org.bouncycastle.crypto.params.RSAPrivateCrtKeyParameters
 *  org.bouncycastle.crypto.signers.PSSSigner
 *  org.slf4j.Logger
 */
package dorkbox.util.crypto;

import java.io.ByteArrayOutputStream;
import java.math.BigInteger;
import java.nio.ByteBuffer;
import java.security.SecureRandom;
import org.bouncycastle.crypto.AsymmetricBlockCipher;
import org.bouncycastle.crypto.AsymmetricCipherKeyPair;
import org.bouncycastle.crypto.CipherParameters;
import org.bouncycastle.crypto.Digest;
import org.bouncycastle.crypto.KeyGenerationParameters;
import org.bouncycastle.crypto.generators.RSAKeyPairGenerator;
import org.bouncycastle.crypto.params.RSAKeyGenerationParameters;
import org.bouncycastle.crypto.params.RSAKeyParameters;
import org.bouncycastle.crypto.params.RSAPrivateCrtKeyParameters;
import org.bouncycastle.crypto.signers.PSSSigner;
import org.slf4j.Logger;

@Deprecated
public final class CryptoRSA {
    public static AsymmetricCipherKeyPair generateKeyPair(SecureRandom secureRandom, int keyLength) {
        RSAKeyPairGenerator keyGen = new RSAKeyPairGenerator();
        RSAKeyGenerationParameters params = new RSAKeyGenerationParameters(new BigInteger("65537"), secureRandom, keyLength, 8);
        keyGen.init((KeyGenerationParameters)params);
        return keyGen.generateKeyPair();
    }

    public static byte[][] encryptAndSign(AsymmetricBlockCipher rsaEngine, Digest digest, RSAKeyParameters rsaPublicKeyA, RSAPrivateCrtKeyParameters rsaPrivateKeyB, byte[] bytes, Logger logger) {
        if (bytes.length == 0) {
            return new byte[0][0];
        }
        byte[] encryptBytes = CryptoRSA.encrypt(rsaEngine, rsaPublicKeyA, bytes, logger);
        if (encryptBytes.length == 0) {
            return new byte[0][0];
        }
        PSSSigner signer = new PSSSigner(rsaEngine, digest, digest.getDigestSize());
        byte[] signatureRSA = CryptoRSA.sign(signer, rsaPrivateKeyB, encryptBytes, logger);
        if (signatureRSA.length == 0) {
            return new byte[0][0];
        }
        byte[][] total = new byte[][]{encryptBytes, signatureRSA};
        return total;
    }

    public static byte[] decryptAndVerify(AsymmetricBlockCipher rsaEngine, Digest digest, RSAKeyParameters rsaPublicKeyA, RSAPrivateCrtKeyParameters rsaPrivateKeyB, byte[] encryptedData, byte[] signature, Logger logger) {
        if (encryptedData.length == 0 || signature.length == 0) {
            return new byte[0];
        }
        PSSSigner signer = new PSSSigner(rsaEngine, digest, digest.getDigestSize());
        boolean verify = CryptoRSA.verify(signer, rsaPublicKeyA, signature, encryptedData);
        if (!verify) {
            return new byte[0];
        }
        return CryptoRSA.decrypt(rsaEngine, rsaPrivateKeyB, encryptedData, logger);
    }

    public static byte[] encrypt(AsymmetricBlockCipher rsaEngine, RSAKeyParameters rsaPublicKey, byte[] bytes, Logger logger) {
        rsaEngine.init(true, (CipherParameters)rsaPublicKey);
        try {
            int inputBlockSize = rsaEngine.getInputBlockSize();
            if (inputBlockSize < bytes.length) {
                int size;
                int outSize = rsaEngine.getOutputBlockSize();
                int realsize = (int)Math.round((double)bytes.length / ((double)outSize * 1.0) + 0.5);
                ByteBuffer buffer = ByteBuffer.allocateDirect(outSize * realsize);
                for (int position = 0; position < bytes.length; position += size) {
                    size = Math.min(inputBlockSize, bytes.length - position);
                    byte[] block = rsaEngine.processBlock(bytes, position, size);
                    buffer.put(block, 0, block.length);
                }
                return buffer.array();
            }
            return rsaEngine.processBlock(bytes, 0, bytes.length);
        }
        catch (Exception e) {
            if (logger != null) {
                logger.error("Unable to perform RSA cipher.", (Throwable)e);
            }
            return new byte[0];
        }
    }

    public static byte[] decrypt(AsymmetricBlockCipher rsaEngine, RSAPrivateCrtKeyParameters rsaPrivateKey, byte[] bytes, Logger logger) {
        rsaEngine.init(false, (CipherParameters)rsaPrivateKey);
        try {
            int inputBlockSize = rsaEngine.getInputBlockSize();
            if (inputBlockSize < bytes.length) {
                int size;
                int outSize = rsaEngine.getOutputBlockSize();
                int realsize = (int)Math.round((double)bytes.length / ((double)outSize * 1.0) + 0.5);
                ByteArrayOutputStream buffer = new ByteArrayOutputStream(outSize * realsize);
                for (int position = 0; position < bytes.length; position += size) {
                    size = Math.min(inputBlockSize, bytes.length - position);
                    byte[] block = rsaEngine.processBlock(bytes, position, size);
                    buffer.write(block, 0, block.length);
                }
                return buffer.toByteArray();
            }
            return rsaEngine.processBlock(bytes, 0, bytes.length);
        }
        catch (Exception e) {
            if (logger != null) {
                logger.error("Unable to perform RSA cipher.", (Throwable)e);
            }
            return new byte[0];
        }
    }

    public static byte[] sign(PSSSigner signer, RSAPrivateCrtKeyParameters rsaPrivateKey, byte[] mesg, Logger logger) {
        signer.init(true, (CipherParameters)rsaPrivateKey);
        signer.update(mesg, 0, mesg.length);
        try {
            return signer.generateSignature();
        }
        catch (Exception e) {
            if (logger != null) {
                logger.error("Unable to perform RSA cipher.", (Throwable)e);
            }
            return new byte[0];
        }
    }

    public static boolean verify(PSSSigner signer, RSAKeyParameters rsaPublicKey, byte[] sig, byte[] mesg) {
        signer.init(false, (CipherParameters)rsaPublicKey);
        signer.update(mesg, 0, mesg.length);
        return signer.verifySignature(sig);
    }

    public static boolean compare(RSAKeyParameters publicA, RSAKeyParameters publicB) {
        if (!publicA.getExponent().equals(publicB.getExponent())) {
            return false;
        }
        return publicA.getModulus().equals(publicB.getModulus());
    }

    public static boolean compare(RSAPrivateCrtKeyParameters private1, RSAPrivateCrtKeyParameters private2) {
        if (!private1.getModulus().equals(private2.getModulus())) {
            return false;
        }
        if (!private1.getExponent().equals(private2.getExponent())) {
            return false;
        }
        if (!private1.getDP().equals(private2.getDP())) {
            return false;
        }
        if (!private1.getDQ().equals(private2.getDQ())) {
            return false;
        }
        if (!private1.getP().equals(private2.getP())) {
            return false;
        }
        if (!private1.getPublicExponent().equals(private2.getPublicExponent())) {
            return false;
        }
        if (!private1.getQ().equals(private2.getQ())) {
            return false;
        }
        return private1.getQInv().equals(private2.getQInv());
    }

    private CryptoRSA() {
    }
}

