/*
 * Decompiled with CFR 0.152.
 * 
 * Could not load the following classes:
 *  iaik.asn1.structures.AlgorithmID
 *  iaik.cms.DigestInfo
 *  iaik.cms.IaikProvider
 *  iaik.pkcs.pkcs11.provider.IAIKPkcs11
 *  iaik.pkcs.pkcs11.provider.keys.IAIKPKCS11Key
 *  iaik.pkcs.pkcs11.provider.keys.IAIKPKCS11PrivateKey
 *  iaik.security.cipher.SecretKey
 */
package md.cts.cryptography.providers;

import iaik.asn1.structures.AlgorithmID;
import iaik.cms.DigestInfo;
import iaik.cms.IaikProvider;
import iaik.pkcs.pkcs11.provider.IAIKPkcs11;
import iaik.pkcs.pkcs11.provider.keys.IAIKPKCS11Key;
import iaik.pkcs.pkcs11.provider.keys.IAIKPKCS11PrivateKey;
import iaik.security.cipher.SecretKey;
import java.security.InvalidAlgorithmParameterException;
import java.security.InvalidKeyException;
import java.security.Key;
import java.security.NoSuchAlgorithmException;
import java.security.NoSuchProviderException;
import java.security.PrivateKey;
import java.security.PublicKey;
import java.security.Signature;
import java.security.SignatureException;
import java.security.spec.AlgorithmParameterSpec;
import javax.crypto.BadPaddingException;
import javax.crypto.Cipher;
import javax.crypto.IllegalBlockSizeException;
import javax.crypto.NoSuchPaddingException;

public final class IaikPkcs11SecurityProvider
extends IaikProvider {
    private final IAIKPkcs11 iaikPkcs11Provider;

    public IaikPkcs11SecurityProvider(IAIKPkcs11 iaikPkcs11Provider) {
        this.iaikPkcs11Provider = iaikPkcs11Provider;
    }

    public byte[] calculateSignatureFromHash(AlgorithmID signatureAlgorithm, AlgorithmID digestAlgorithm, PrivateKey privateKey, byte[] digest) throws NoSuchAlgorithmException, InvalidKeyException, SignatureException {
        byte[] signatureValue;
        if (privateKey instanceof IAIKPKCS11PrivateKey) {
            Signature signatureEngine;
            byte[] dataToBeSigned;
            IAIKPkcs11 iaikPkcs11KeyProvider = ((IAIKPKCS11PrivateKey)privateKey).getTokenManager().getProvider();
            String algorithmImplementationName = signatureAlgorithm.getImplementationName();
            try {
                switch (algorithmImplementationName) {
                    case "RSA": {
                        DigestInfo digestInfo = new DigestInfo(digestAlgorithm, digest);
                        dataToBeSigned = digestInfo.toByteArray();
                        signatureEngine = Signature.getInstance("RawRSA/PKCS1", iaikPkcs11KeyProvider.getName());
                        break;
                    }
                    case "DSA": {
                        dataToBeSigned = digest;
                        signatureEngine = Signature.getInstance("RawDSA", iaikPkcs11KeyProvider.getName());
                        break;
                    }
                    case "ECDSA": {
                        dataToBeSigned = digest;
                        signatureEngine = Signature.getInstance("RawECDSA", iaikPkcs11KeyProvider.getName());
                        break;
                    }
                    default: {
                        throw new NoSuchAlgorithmException("Unable to calculate signature with signature algorithm: " + algorithmImplementationName);
                    }
                }
            }
            catch (NoSuchProviderException ex) {
                throw new NoSuchAlgorithmException("The PKCS#11 provider has not been installed corerctly: " + String.valueOf(ex));
            }
            signatureEngine.initSign(privateKey);
            signatureEngine.update(dataToBeSigned);
            signatureValue = signatureEngine.sign();
        } else {
            signatureValue = super.calculateSignatureFromHash(signatureAlgorithm, digestAlgorithm, privateKey, digest);
        }
        return signatureValue;
    }

    public Signature getSignature(String algorithm, int mode, Key key) throws InvalidKeyException, NoSuchAlgorithmException {
        Signature signature;
        if (key instanceof IAIKPKCS11Key) {
            try {
                signature = Signature.getInstance(algorithm, this.iaikPkcs11Provider.getName());
            }
            catch (NoSuchProviderException e) {
                throw new NoSuchAlgorithmException("PKCS#11 Provider has not been installed correctly " + String.valueOf(e));
            }
            if (mode == 1) {
                signature.initSign((PrivateKey)key);
            } else if (mode == 2) {
                signature.initVerify((PublicKey)key);
            }
        } else {
            signature = super.getSignature(algorithm, mode, key);
        }
        return signature;
    }

    public javax.crypto.SecretKey decryptKey(byte[] encryptedKey, AlgorithmID kea, PrivateKey recipientKey, String cekAlgorithmName) throws NoSuchAlgorithmException, InvalidKeyException, NoSuchPaddingException, BadPaddingException {
        javax.crypto.SecretKey decryptedSymmetricKey = null;
        if (recipientKey instanceof IAIKPKCS11PrivateKey) {
            IAIKPkcs11 iaikPkcs11KeyProvider = ((IAIKPKCS11PrivateKey)recipientKey).getTokenManager().getProvider();
            String algorithmImplementationName = kea.getImplementationName();
            try {
                Cipher cipher = Cipher.getInstance(algorithmImplementationName, iaikPkcs11KeyProvider.getName());
                cipher.init(2, (Key)recipientKey, (AlgorithmParameterSpec)null, null);
                byte[] cek = cipher.doFinal(encryptedKey);
                SecretKey secretKey = new SecretKey(cek, cekAlgorithmName);
            }
            catch (NoSuchProviderException ex) {
                throw new NoSuchAlgorithmException("The PKCS#11 provider has not been installed corerctly: " + String.valueOf(ex));
            }
            catch (InvalidAlgorithmParameterException ex) {
                throw new NoSuchAlgorithmException("Error initializing the cipher: " + String.valueOf(ex));
            }
            catch (IllegalBlockSizeException ex) {
                throw new NoSuchAlgorithmException("Error during cipher operation: " + String.valueOf(ex));
            }
        } else {
            decryptedSymmetricKey = super.decryptKey(encryptedKey, kea, recipientKey, cekAlgorithmName);
        }
        return decryptedSymmetricKey;
    }
}

