/*
 * Decompiled with CFR 0.152.
 * 
 * Could not load the following classes:
 *  org.bouncycastle.crypto.AsymmetricCipherKeyPair
 *  org.bouncycastle.crypto.BasicAgreement
 *  org.bouncycastle.crypto.BufferedBlockCipher
 *  org.bouncycastle.crypto.CipherParameters
 *  org.bouncycastle.crypto.DerivationFunction
 *  org.bouncycastle.crypto.Digest
 *  org.bouncycastle.crypto.KeyGenerationParameters
 *  org.bouncycastle.crypto.Mac
 *  org.bouncycastle.crypto.agreement.ECDHCBasicAgreement
 *  org.bouncycastle.crypto.digests.SHA384Digest
 *  org.bouncycastle.crypto.digests.SHA512Digest
 *  org.bouncycastle.crypto.engines.IESEngine
 *  org.bouncycastle.crypto.generators.ECKeyPairGenerator
 *  org.bouncycastle.crypto.generators.KDF2BytesGenerator
 *  org.bouncycastle.crypto.macs.HMac
 *  org.bouncycastle.crypto.paddings.PaddedBufferedBlockCipher
 *  org.bouncycastle.crypto.params.ECDomainParameters
 *  org.bouncycastle.crypto.params.ECKeyGenerationParameters
 *  org.bouncycastle.crypto.params.ECPrivateKeyParameters
 *  org.bouncycastle.crypto.params.ECPublicKeyParameters
 *  org.bouncycastle.crypto.params.IESParameters
 *  org.bouncycastle.crypto.params.IESWithCipherParameters
 *  org.bouncycastle.crypto.params.ParametersWithRandom
 *  org.bouncycastle.crypto.signers.ECDSASigner
 *  org.bouncycastle.jcajce.provider.util.DigestFactory
 *  org.bouncycastle.jce.ECNamedCurveTable
 *  org.bouncycastle.jce.spec.ECNamedCurveParameterSpec
 *  org.bouncycastle.jce.spec.ECParameterSpec
 *  org.bouncycastle.math.ec.ECFieldElement
 *  org.bouncycastle.math.ec.ECPoint
 *  org.slf4j.Logger
 */
package dorkbox.util.crypto;

import java.math.BigInteger;
import java.security.SecureRandom;
import java.util.Arrays;
import org.bouncycastle.crypto.AsymmetricCipherKeyPair;
import org.bouncycastle.crypto.BasicAgreement;
import org.bouncycastle.crypto.BufferedBlockCipher;
import org.bouncycastle.crypto.CipherParameters;
import org.bouncycastle.crypto.DerivationFunction;
import org.bouncycastle.crypto.Digest;
import org.bouncycastle.crypto.KeyGenerationParameters;
import org.bouncycastle.crypto.Mac;
import org.bouncycastle.crypto.agreement.ECDHCBasicAgreement;
import org.bouncycastle.crypto.digests.SHA384Digest;
import org.bouncycastle.crypto.digests.SHA512Digest;
import org.bouncycastle.crypto.engines.IESEngine;
import org.bouncycastle.crypto.generators.ECKeyPairGenerator;
import org.bouncycastle.crypto.generators.KDF2BytesGenerator;
import org.bouncycastle.crypto.macs.HMac;
import org.bouncycastle.crypto.paddings.PaddedBufferedBlockCipher;
import org.bouncycastle.crypto.params.ECDomainParameters;
import org.bouncycastle.crypto.params.ECKeyGenerationParameters;
import org.bouncycastle.crypto.params.ECPrivateKeyParameters;
import org.bouncycastle.crypto.params.ECPublicKeyParameters;
import org.bouncycastle.crypto.params.IESParameters;
import org.bouncycastle.crypto.params.IESWithCipherParameters;
import org.bouncycastle.crypto.params.ParametersWithRandom;
import org.bouncycastle.crypto.signers.ECDSASigner;
import org.bouncycastle.jcajce.provider.util.DigestFactory;
import org.bouncycastle.jce.ECNamedCurveTable;
import org.bouncycastle.jce.spec.ECNamedCurveParameterSpec;
import org.bouncycastle.jce.spec.ECParameterSpec;
import org.bouncycastle.math.ec.ECFieldElement;
import org.bouncycastle.math.ec.ECPoint;
import org.slf4j.Logger;

public final class CryptoECC {
    public static final String p521_curve = "secp521r1";
    public static final String curve25519 = "curve25519";
    public static final String default_curve = "curve25519";
    public static final int macSize = 512;

    public static IESEngine createEngine() {
        return new IESEngine((BasicAgreement)new ECDHCBasicAgreement(), (DerivationFunction)new KDF2BytesGenerator((Digest)new SHA384Digest()), (Mac)new HMac((Digest)new SHA512Digest()));
    }

    public static IESEngine createEngine(PaddedBufferedBlockCipher aesEngine) {
        return new IESEngine((BasicAgreement)new ECDHCBasicAgreement(), (DerivationFunction)new KDF2BytesGenerator((Digest)new SHA384Digest()), (Mac)new HMac((Digest)new SHA512Digest()), (BufferedBlockCipher)aesEngine);
    }

    public static IESParameters generateSharedParameters(SecureRandom secureRandom) {
        int macSize = 512;
        byte[] derivation = new byte[macSize / 8];
        byte[] encoding = new byte[macSize / 8];
        secureRandom.nextBytes(derivation);
        secureRandom.nextBytes(encoding);
        return new IESParameters(derivation, encoding, macSize);
    }

    public static IESWithCipherParameters generateSharedParametersWithCipher(SecureRandom secureRandom) {
        int macSize = 512;
        byte[] derivation = new byte[macSize / 8];
        byte[] encoding = new byte[macSize / 8];
        secureRandom.nextBytes(derivation);
        secureRandom.nextBytes(encoding);
        return new IESWithCipherParameters(derivation, encoding, macSize, 256);
    }

    public static AsymmetricCipherKeyPair generateKeyPair(String eccCurveName, SecureRandom secureRandom) {
        ECNamedCurveParameterSpec eccSpec = ECNamedCurveTable.getParameterSpec((String)eccCurveName);
        return CryptoECC.generateKeyPair((ECParameterSpec)eccSpec, secureRandom);
    }

    public static AsymmetricCipherKeyPair generateKeyPair(ECParameterSpec eccSpec, SecureRandom secureRandom) {
        ECKeyGenerationParameters ecParams = new ECKeyGenerationParameters(new ECDomainParameters(eccSpec.getCurve(), eccSpec.getG(), eccSpec.getN()), secureRandom);
        ECKeyPairGenerator ecKeyGen = new ECKeyPairGenerator();
        ecKeyGen.init((KeyGenerationParameters)ecParams);
        return ecKeyGen.generateKeyPair();
    }

    public static byte[] encrypt(IESEngine eccEngine, CipherParameters private1, CipherParameters public2, IESParameters cipherParams, byte[] message, Logger logger) {
        eccEngine.init(true, private1, public2, (CipherParameters)cipherParams);
        try {
            return eccEngine.processBlock(message, 0, message.length);
        }
        catch (Exception e) {
            if (logger != null) {
                logger.error("Unable to perform ECC cipher.", (Throwable)e);
            }
            return new byte[0];
        }
    }

    public static byte[] decrypt(IESEngine eccEngine, CipherParameters private2, CipherParameters public1, IESParameters cipherParams, byte[] encrypted, Logger logger) {
        eccEngine.init(false, private2, public1, (CipherParameters)cipherParams);
        try {
            return eccEngine.processBlock(encrypted, 0, encrypted.length);
        }
        catch (Exception e) {
            if (logger != null) {
                logger.error("Unable to perform ECC cipher.", (Throwable)e);
            }
            return new byte[0];
        }
    }

    public static boolean compare(ECPrivateKeyParameters privateA, ECPrivateKeyParameters privateB) {
        ECDomainParameters parametersA = privateA.getParameters();
        ECDomainParameters parametersB = privateB.getParameters();
        boolean equals = parametersA.getCurve().equals(parametersB.getCurve());
        if (!equals) {
            return false;
        }
        equals = parametersA.getG().equals(parametersB.getG());
        if (!equals) {
            return false;
        }
        equals = parametersA.getH().equals(parametersB.getH());
        if (!equals) {
            return false;
        }
        equals = parametersA.getN().equals(parametersB.getN());
        if (!equals) {
            return false;
        }
        equals = privateA.getD().equals(privateB.getD());
        return equals;
    }

    public static boolean compare(ECPublicKeyParameters publicA, ECPublicKeyParameters publicB) {
        ECFieldElement yCoordB;
        ECFieldElement xCoordB;
        if (publicA == null || publicB == null) {
            return false;
        }
        ECDomainParameters parametersA = publicA.getParameters();
        ECDomainParameters parametersB = publicB.getParameters();
        boolean equals = parametersA.getCurve().equals(parametersB.getCurve());
        if (!equals) {
            return false;
        }
        equals = parametersA.getG().equals(parametersB.getG());
        if (!equals) {
            return false;
        }
        equals = parametersA.getH().equals(parametersB.getH());
        if (!equals) {
            return false;
        }
        equals = parametersA.getN().equals(parametersB.getN());
        if (!equals) {
            return false;
        }
        ECPoint normalizeA = publicA.getQ().normalize();
        ECPoint normalizeB = publicB.getQ().normalize();
        ECFieldElement xCoordA = normalizeA.getXCoord();
        equals = xCoordA.equals(xCoordB = normalizeB.getXCoord());
        if (!equals) {
            return false;
        }
        ECFieldElement yCoordA = normalizeA.getYCoord();
        equals = yCoordA.equals(yCoordB = normalizeB.getYCoord());
        return equals;
    }

    public static boolean compare(IESParameters cipherAParams, IESParameters cipherBParams) {
        if (!Arrays.equals(cipherAParams.getDerivationV(), cipherBParams.getDerivationV())) {
            return false;
        }
        if (!Arrays.equals(cipherAParams.getEncodingV(), cipherBParams.getEncodingV())) {
            return false;
        }
        return cipherAParams.getMacKeySize() == cipherBParams.getMacKeySize();
    }

    public static boolean compare(IESWithCipherParameters cipherAParams, IESWithCipherParameters cipherBParams) {
        if (cipherAParams.getCipherKeySize() != cipherBParams.getCipherKeySize()) {
            return false;
        }
        return CryptoECC.compare((IESParameters)cipherAParams, (IESParameters)cipherBParams);
    }

    public static BigInteger[] generateSignature(String digestName, ECPrivateKeyParameters privateKey, SecureRandom secureRandom, byte[] bytes) {
        Digest digest = DigestFactory.getDigest((String)digestName);
        byte[] checksum = new byte[digest.getDigestSize()];
        digest.update(bytes, 0, bytes.length);
        digest.doFinal(checksum, 0);
        return CryptoECC.generateSignatureForHash(privateKey, secureRandom, checksum);
    }

    public static BigInteger[] generateSignatureForHash(ECPrivateKeyParameters privateKey, SecureRandom secureRandom, byte[] hashBytes) {
        ParametersWithRandom param = new ParametersWithRandom((CipherParameters)privateKey, secureRandom);
        ECDSASigner ecdsa = new ECDSASigner();
        ecdsa.init(true, (CipherParameters)param);
        return ecdsa.generateSignature(hashBytes);
    }

    public static boolean verifySignature(String digestName, ECPublicKeyParameters publicKey, byte[] message, BigInteger[] signature) {
        Digest digest = DigestFactory.getDigest((String)digestName);
        byte[] checksum = new byte[digest.getDigestSize()];
        digest.update(message, 0, message.length);
        digest.doFinal(checksum, 0);
        return CryptoECC.verifySignatureHash(publicKey, checksum, signature);
    }

    public static boolean verifySignatureHash(ECPublicKeyParameters publicKey, byte[] hash, BigInteger[] signature) {
        ECDSASigner ecdsa = new ECDSASigner();
        ecdsa.init(false, (CipherParameters)publicKey);
        return ecdsa.verifySignature(hash, signature[0], signature[1]);
    }

    private CryptoECC() {
    }
}

