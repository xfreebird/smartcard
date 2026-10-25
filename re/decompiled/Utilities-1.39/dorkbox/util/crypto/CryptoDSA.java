/*
 * Decompiled with CFR 0.152.
 * 
 * Could not load the following classes:
 *  org.bouncycastle.crypto.AsymmetricCipherKeyPair
 *  org.bouncycastle.crypto.CipherParameters
 *  org.bouncycastle.crypto.KeyGenerationParameters
 *  org.bouncycastle.crypto.digests.SHA1Digest
 *  org.bouncycastle.crypto.generators.DSAKeyPairGenerator
 *  org.bouncycastle.crypto.generators.DSAParametersGenerator
 *  org.bouncycastle.crypto.params.DSAKeyGenerationParameters
 *  org.bouncycastle.crypto.params.DSAParameters
 *  org.bouncycastle.crypto.params.DSAPrivateKeyParameters
 *  org.bouncycastle.crypto.params.DSAPublicKeyParameters
 *  org.bouncycastle.crypto.params.ParametersWithRandom
 *  org.bouncycastle.crypto.signers.DSASigner
 */
package dorkbox.util.crypto;

import java.math.BigInteger;
import java.security.SecureRandom;
import org.bouncycastle.crypto.AsymmetricCipherKeyPair;
import org.bouncycastle.crypto.CipherParameters;
import org.bouncycastle.crypto.KeyGenerationParameters;
import org.bouncycastle.crypto.digests.SHA1Digest;
import org.bouncycastle.crypto.generators.DSAKeyPairGenerator;
import org.bouncycastle.crypto.generators.DSAParametersGenerator;
import org.bouncycastle.crypto.params.DSAKeyGenerationParameters;
import org.bouncycastle.crypto.params.DSAParameters;
import org.bouncycastle.crypto.params.DSAPrivateKeyParameters;
import org.bouncycastle.crypto.params.DSAPublicKeyParameters;
import org.bouncycastle.crypto.params.ParametersWithRandom;
import org.bouncycastle.crypto.signers.DSASigner;

@Deprecated
public final class CryptoDSA {
    public static AsymmetricCipherKeyPair generateKeyPair(SecureRandom secureRandom, int keyLength) {
        DSAKeyPairGenerator keyGen = new DSAKeyPairGenerator();
        DSAParametersGenerator dsaParametersGenerator = new DSAParametersGenerator();
        dsaParametersGenerator.init(keyLength, 20, secureRandom);
        DSAParameters generateParameters = dsaParametersGenerator.generateParameters();
        DSAKeyGenerationParameters params = new DSAKeyGenerationParameters(secureRandom, generateParameters);
        keyGen.init((KeyGenerationParameters)params);
        return keyGen.generateKeyPair();
    }

    public static BigInteger[] generateSignature(DSAPrivateKeyParameters privateKey, SecureRandom secureRandom, byte[] message) {
        ParametersWithRandom param = new ParametersWithRandom((CipherParameters)privateKey, secureRandom);
        DSASigner dsa = new DSASigner();
        dsa.init(true, (CipherParameters)param);
        SHA1Digest sha1Digest = new SHA1Digest();
        byte[] checksum = new byte[sha1Digest.getDigestSize()];
        sha1Digest.update(message, 0, message.length);
        sha1Digest.doFinal(checksum, 0);
        return dsa.generateSignature(checksum);
    }

    public static boolean verifySignature(DSAPublicKeyParameters publicKey, byte[] message, BigInteger[] signature) {
        SHA1Digest sha1Digest = new SHA1Digest();
        byte[] checksum = new byte[sha1Digest.getDigestSize()];
        sha1Digest.update(message, 0, message.length);
        sha1Digest.doFinal(checksum, 0);
        DSASigner dsa = new DSASigner();
        dsa.init(false, (CipherParameters)publicKey);
        return dsa.verifySignature(checksum, signature[0], signature[1]);
    }

    private CryptoDSA() {
    }
}

